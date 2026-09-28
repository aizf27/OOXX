package com.kangsi.ooxx.ui

import android.app.Application
import android.bluetooth.BluetoothDevice
import android.content.Context
import android.media.AudioManager
import android.media.ToneGenerator
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.kangsi.ooxx.data.LocalGameRepository
import com.kangsi.ooxx.data.MatchRecord
import com.kangsi.ooxx.data.MatchResult
import com.kangsi.ooxx.data.NetworkGameRepository
import com.kangsi.ooxx.data.RankingEntry
import com.kangsi.ooxx.game.Board
import com.kangsi.ooxx.game.GameEngine
import com.kangsi.ooxx.game.LogicBoard
import com.kangsi.ooxx.game.LogicPuzzleEngine
import com.kangsi.ooxx.game.Mark
import com.kangsi.ooxx.game.Move
import com.kangsi.ooxx.game.Puzzle
import com.kangsi.ooxx.match.BluetoothMatchService
import com.kangsi.ooxx.match.ClientEvent
import com.kangsi.ooxx.match.MatchConnection
import com.kangsi.ooxx.match.RoomAuthority
import com.kangsi.ooxx.match.RoomEvent
import com.kangsi.ooxx.match.RoomProtocol
import com.kangsi.ooxx.match.RoomSnapshot
import com.kangsi.ooxx.match.WebSocketMatchClient
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

enum class Screen { SPLASH, ONBOARDING, HOME, MODE, ROOM, GAME, RESULT, HISTORY, PROFILE }
enum class GameKind { AI_3X3, AI_5X5, LOGIC_6X6, LOCAL, DAILY, NETWORK, BLUETOOTH }

data class GameSession(
    val board: Board = Board(),
    val turn: Mark = Mark.X,
    val playerMark: Mark = Mark.X,
    val kind: GameKind = GameKind.AI_3X3,
    val moves: Int = 0,
    val message: String = "轮到你了",
    val puzzleAnswer: Move? = null,
    val puzzleSolved: Boolean? = null,
    val isAiThinking: Boolean = false,
    val logicBoard: LogicBoard? = null,
    val logicHistory: List<LogicBoard> = emptyList(),
    val opponentName: String? = null
)

/** 好友房间页的网络对战状态。 */
data class NetworkRoom(
    val connecting: Boolean = false,
    val roomCode: String = "",
    val waiting: Boolean = false,
    val statusMessage: String = "选择连接方式",
    val error: String? = null
)

data class AppState(
    val screen: Screen = Screen.SPLASH,
    val game: GameSession = GameSession(),
    val result: MatchResult? = null,
    val records: List<MatchRecord> = emptyList(),
    val ranking: List<RankingEntry> = emptyList(),
    val networkMessage: String = "",
    val isLoadingPuzzle: Boolean = false,
    val settings: Settings = Settings(),
    val network: NetworkRoom = NetworkRoom()
)

data class Settings(
    val sound: Boolean = true,
    val vibration: Boolean = true,
    val darkMode: Boolean = false
)

class OoxxViewModel(application: Application) : AndroidViewModel(application) {
    private val local = LocalGameRepository(application)
    private val network = NetworkGameRepository()
    private val prefs = application.getSharedPreferences("ooxx_settings", Context.MODE_PRIVATE)
    private val tone by lazy {
        runCatching { ToneGenerator(AudioManager.STREAM_MUSIC, 80) }.getOrNull()
    }
    private val _state = MutableStateFlow(
        AppState(
            records = local.records(),
            ranking = local.ranking(),
            settings = Settings(
                sound = prefs.getBoolean("sound", true),
                vibration = prefs.getBoolean("vibration", true),
                darkMode = prefs.getBoolean("darkMode", false)
            )
        )
    )
    val state: StateFlow<AppState> = _state.asStateFlow()

    init {
        viewModelScope.launch {
            delay(900)
            if (_state.value.screen == Screen.SPLASH) navigate(Screen.ONBOARDING)
        }
    }

    fun navigate(screen: Screen) {
        _state.update { it.copy(screen = screen, records = local.records(), ranking = local.ranking()) }
    }

    // ---- 网络对战（WebSocket 房间） ----

    private var matchConnection: MatchConnection? = null
    private var receiveJob: Job? = null

    /** 服务器按回合广播 room.state；在两次广播之间挡住重复落子。 */
    @Volatile
    private var awaitingRoomState = false

    private val playerId: String by lazy {
        prefs.getString("playerId", null) ?: java.util.UUID.randomUUID().toString().also {
            prefs.edit().putString("playerId", it).apply()
        }
    }

    fun createRoom() = matchAction { it.send(RoomProtocol.createRoom(size = 3)) }

    fun joinRoom(code: String) = matchAction { it.send(RoomProtocol.joinRoom(code)) }

    fun netSurrender() = matchAction { it.send(RoomProtocol.surrender()) }

    fun netPlay(move: Move) {
        if (awaitingRoomState) return
        val session = _state.value.game
        if (session.kind != GameKind.NETWORK || session.turn != session.playerMark) return
        awaitingRoomState = true
        matchAction { it.send(RoomProtocol.move(move.row, move.col)) }
    }

    private fun matchAction(action: suspend (MatchConnection) -> Unit) {
        viewModelScope.launch {
            val connection = ensureConnection() ?: return@launch
            runCatching { action(connection) }.onFailure {
                _state.update { state ->
                    state.copy(network = state.network.copy(error = "连接已断开，请重新创建或加入房间"))
                }
                closeMatch()
            }
        }
    }

    private suspend fun ensureConnection(): MatchConnection? {
        if (btRole != null) closeMatch()
        matchConnection?.let { return it }
        _state.update { it.copy(network = it.network.copy(connecting = true, error = null)) }
        val connection = runCatching { WebSocketMatchClient().connect() }.getOrElse {
            _state.update { state ->
                state.copy(network = state.network.copy(connecting = false, error = "无法连接对战服务器，请稍后再试"))
            }
            return null
        }
        matchConnection = connection
        _state.update { it.copy(network = it.network.copy(connecting = false, statusMessage = "已连接服务器")) }
        runCatching { connection.send(RoomProtocol.hello(playerId, "康思")) }
            .onFailure { closeMatch() }
        startReceiveLoop(connection)
        return if (matchConnection != null) connection else null
    }

    private fun startReceiveLoop(connection: MatchConnection) {
        receiveJob?.cancel()
        receiveJob = viewModelScope.launch {
            while (true) {
                // 连接被对端关闭或读写失败时不能让异常冲出协程，否则整应用崩溃
                val text = runCatching { connection.receive() }.getOrNull() ?: break
                val event = runCatching { RoomProtocol.decode(text) }.getOrNull() ?: continue
                runCatching { handleRoomEvent(event) }
            }
            onDisconnected(connection)
        }
    }

    private fun handleRoomEvent(event: RoomEvent) {
        when (event) {
            is RoomEvent.Connected, is RoomEvent.HelloOk -> Unit
            is RoomEvent.RoomCreated -> {
                awaitingRoomState = false
                _state.update { state ->
                    state.copy(network = state.network.copy(
                        roomCode = event.room.code,
                        waiting = !event.room.isPlaying,
                        statusMessage = if (event.room.isPlaying) "对手已加入，开始对局" else "房间已创建，等待好友加入…",
                        error = null
                    ))
                }
                applyRoomSnapshot(event.room)
            }
            is RoomEvent.RoomState -> applyRoomSnapshot(event.room)
            is RoomEvent.Failure -> {
                awaitingRoomState = false
                _state.update { state ->
                    state.copy(network = state.network.copy(error = when (event.code) {
                        "ROOM_NOT_FOUND" -> "房间不存在或已结束"
                        "ROOM_FULL" -> "房间已满员"
                        "NOT_YOUR_TURN" -> "还没有轮到你"
                        "CELL_OCCUPIED" -> "该位置已有棋子"
                        "GAME_NOT_READY" -> "等待另一位玩家加入"
                        else -> event.message
                    }))
                }
            }
        }
    }

    private fun applyRoomSnapshot(room: RoomSnapshot) {
        awaitingRoomState = false
        if (room.isFinished) {
            val result = room.toMatchResult()
            if (result != null) {
                _state.update { state ->
                    state.copy(game = state.game.copy(
                        board = room.board,
                        turn = room.turn,
                        opponentName = room.opponentName
                    ))
                }
                finish(result)
                return
            }
        }
        val isBluetooth = btRole != null
        val session = GameSession(
            board = room.board,
            turn = room.turn,
            playerMark = room.yourMark ?: Mark.X,
            kind = if (isBluetooth) GameKind.BLUETOOTH else GameKind.NETWORK,
            opponentName = room.opponentName,
            message = when {
                room.isWaiting -> "等待对手加入…"
                room.yourMark == null -> "观战中"
                room.turn == room.yourMark -> "轮到你了"
                else -> "等待对方落子…"
            }
        )
        _state.update { state ->
            state.copy(
                network = state.network.copy(
                    roomCode = if (isBluetooth) state.network.roomCode else room.code,
                    waiting = if (isBluetooth) false else room.isWaiting,
                    statusMessage = when {
                        room.isPlaying -> "对局中 · 你执${if (room.yourMark == Mark.X) "X" else "O"}"
                        room.isWaiting && !isBluetooth -> "等待对手加入…"
                        else -> state.network.statusMessage
                    }
                ),
                game = session,
                screen = if (room.isPlaying) Screen.GAME else state.screen
            )
        }
    }

    /** 被取消的旧接收循环也会走到这里，只处理当前连接，免得把新连接置空。 */
    private fun onDisconnected(connection: MatchConnection) {
        if (matchConnection !== connection) return
        matchConnection = null
        btRole = null
        btAuthority = null
        _state.update { state ->
            state.copy(network = state.network.copy(
                statusMessage = "与服务器断开连接",
                error = if (state.screen == Screen.ROOM) state.network.error else null
            ))
        }
    }

    // ---- 蓝牙对战（一台当主机跑 RoomAuthority，另一台连接） ----

    private val bluetooth by lazy { BluetoothMatchService(getApplication()) }
    private var btRole: BtRole? = null
    private var btAuthority: RoomAuthority? = null

    enum class BtRole { HOST, GUEST }

    fun bluetoothAvailable(): Boolean = bluetooth.isAvailable()

    fun bluetoothDevices(): List<BluetoothDevice> = runCatching { bluetooth.pairedDevices() }.getOrDefault(emptyList())

    fun btStatus(text: String) = _state.update {
        it.copy(network = it.network.copy(statusMessage = text, error = null))
    }

    /** 作为主机等待好友连接：本机同时承担服务端（RoomAuthority）。 */
    fun bluetoothHost(name: String = "康思") {
        viewModelScope.launch {
            btStatus("正在等待好友连接…")
            val connection = runCatching { bluetooth.host() }.getOrElse {
                btStatus("蓝牙监听失败：${it.message ?: "请确认蓝牙已开启"}")
                return@launch
            }
            closeMatch()
            btRole = BtRole.HOST
            btAuthority = RoomAuthority(hostName = name)
            matchConnection = connection
            btStatus("好友已连接，你执 X 先手")
            startBtHostLoop(connection)
        }
    }

    /** 作为客户端连接已配对设备。 */
    fun bluetoothJoin(device: BluetoothDevice) {
        viewModelScope.launch {
            btStatus("正在连接 ${device.name ?: device.address}…")
            val connection = runCatching { bluetooth.connect(device) }.getOrElse {
                btStatus("连接失败：${it.message ?: "请确认对方已进入等待连接状态"}")
                return@launch
            }
            closeMatch()
            btRole = BtRole.GUEST
            btAuthority = null
            matchConnection = connection
            val sent = runCatching { connection.send(RoomProtocol.hello(playerId, "康思")) }
            if (sent.isFailure) { btStatus("蓝牙连接已断开"); return@launch }
            btStatus("已连接，等待主机开局…")
            startReceiveLoop(connection)
        }
    }

    private fun startBtHostLoop(connection: MatchConnection) {
        receiveJob?.cancel()
        receiveJob = viewModelScope.launch {
            while (true) {
                val text = runCatching { connection.receive() }.getOrNull() ?: break
                val authority = btAuthority ?: break
                when (val event = RoomProtocol.decodeClient(text)) {
                    is ClientEvent.Hello -> {
                        authority.joinGuest(event.playerId, event.name)
                        broadcastHostState()
                    }
                    is ClientEvent.Move -> {
                        val guest = authority.guestId ?: continue
                        if (authority.move(guest, event.row, event.col)) broadcastHostState()
                    }
                    is ClientEvent.Surrender -> {
                        val guest = authority.guestId ?: continue
                        authority.surrender(guest)
                        broadcastHostState()
                    }
                    null -> Unit
                }
            }
            onDisconnected(connection)
        }
    }

    /** 主机把权威快照发给对端，并让自己走与网络模式相同的 applyRoomSnapshot 流程。 */
    private fun broadcastHostState() {
        val authority = btAuthority ?: return
        val connection = matchConnection
        val guestId = authority.guestId
        if (connection != null && guestId != null) {
            viewModelScope.launch { runCatching { connection.send(authority.snapshotFor(guestId)) } }
        }
        runCatching { handleRoomEvent(RoomProtocol.decode(authority.snapshotFor(authority.hostId))) }
    }

    private fun btPlay(move: Move) {
        when (btRole) {
            BtRole.HOST -> {
                val authority = btAuthority ?: return
                if (authority.move(authority.hostId, move.row, move.col)) broadcastHostState()
            }
            BtRole.GUEST -> {
                val connection = matchConnection ?: return
                viewModelScope.launch {
                    runCatching { connection.send(RoomProtocol.move(move.row, move.col)) }
                        .onFailure { btStatus("蓝牙连接已断开") }
                }
            }
            null -> Unit
        }
    }

    private fun btSurrender() {
        when (btRole) {
            BtRole.HOST -> {
                val authority = btAuthority ?: return
                authority.surrender(authority.hostId)
                broadcastHostState()
            }
            BtRole.GUEST -> {
                val connection = matchConnection ?: return
                viewModelScope.launch {
                    runCatching { connection.send(RoomProtocol.surrender()) }
                        .onFailure { btStatus("蓝牙连接已断开") }
                }
            }
            null -> Unit
        }
    }

    private fun closeMatch() {
        receiveJob?.cancel()
        receiveJob = null
        runCatching { matchConnection?.close() }
        matchConnection = null
        awaitingRoomState = false
        btRole = null
        btAuthority = null
    }

    override fun onCleared() {
        closeMatch()
        runCatching { tone?.release() }
        super.onCleared()
    }

    fun setSound(enabled: Boolean) = updateSettings { it.copy(sound = enabled) }

    fun setVibration(enabled: Boolean) = updateSettings { it.copy(vibration = enabled) }

    fun setDarkMode(enabled: Boolean) = updateSettings { it.copy(darkMode = enabled) }

    private fun updateSettings(transform: (Settings) -> Settings) {
        val next = transform(_state.value.settings)
        prefs.edit()
            .putBoolean("sound", next.sound)
            .putBoolean("vibration", next.vibration)
            .putBoolean("darkMode", next.darkMode)
            .apply()
        _state.update { it.copy(settings = next) }
    }

    /** 落子/悔棋等操作的声光反馈，受「我的」页开关控制。 */
    private fun tapFeedback() {
        val settings = _state.value.settings
        if (settings.sound) runCatching { tone?.startTone(ToneGenerator.TONE_PROP_BEEP, 120) }
        if (settings.vibration) vibrate(30)
    }

    private fun vibrate(millis: Long) {
        val app = getApplication<Application>()
        val vibrator = if (Build.VERSION.SDK_INT >= 31) {
            (app.getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager).defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            app.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        }
        // 设备可能无马达或缺少权限，震动失败不能影响对局结算
        runCatching { vibrator.vibrate(VibrationEffect.createOneShot(millis, VibrationEffect.DEFAULT_AMPLITUDE)) }
    }

    fun startGame(kind: GameKind) {
        when (kind) {
            GameKind.DAILY -> loadDailyPuzzle()
            GameKind.AI_5X5 -> begin(GameSession(board = Board(size = 5, winLength = 4), kind = kind))
            GameKind.LOGIC_6X6 -> {
                val puzzle = LogicPuzzleEngine.classic6x6()
                begin(GameSession(kind = kind, logicBoard = puzzle, message = LogicPuzzleEngine.status(puzzle)))
            }
            else -> begin(GameSession(kind = kind))
        }
    }

    private fun begin(game: GameSession) {
        _state.update { it.copy(screen = Screen.GAME, game = game, result = null, networkMessage = "") }
    }

    fun play(move: Move) {
        val session = _state.value.game
        if (session.kind == GameKind.NETWORK) {
            netPlay(move)
            return
        }
        if (session.kind == GameKind.BLUETOOTH) {
            if (session.turn == session.playerMark) btPlay(move)
            return
        }
        if (session.kind == GameKind.LOGIC_6X6) {
            val current = session.logicBoard ?: return
            val next = current.cycle(move)
            if (next == current) return
            tapFeedback()
            val updated = session.copy(
                logicBoard = next,
                logicHistory = session.logicHistory + current,
                moves = session.moves + 1,
                message = LogicPuzzleEngine.status(next)
            )
            _state.update { it.copy(game = updated) }
            if (LogicPuzzleEngine.isSolved(next)) finish(MatchResult.WIN)
            return
        }
        if (session.isAiThinking || session.board.winner() != null || session.board.isDraw()) return
        if (move !in session.board.availableMoves()) return
        tapFeedback()

        if (session.kind == GameKind.DAILY) {
            val solved = move == session.puzzleAnswer
            val board = session.board.place(move, session.turn)
            _state.update {
                it.copy(game = session.copy(
                    board = board,
                    moves = 1,
                    puzzleSolved = solved,
                    message = if (solved) "唯一解正确！" else "这一步不是唯一最优解"
                ))
            }
            viewModelScope.launch { delay(650); finish(if (solved) MatchResult.WIN else MatchResult.LOSS) }
            return
        }

        val nextBoard = session.board.place(move, session.turn)
        val nextTurn = session.turn.other()
        val updated = session.copy(
            board = nextBoard,
            turn = nextTurn,
            moves = session.moves + 1,
            message = if (session.kind == GameKind.LOCAL) "轮到 ${nextTurn.name}" else "对手思考中…"
        )
        _state.update { it.copy(game = updated) }
        if (completeIfNeeded(updated)) return

        if (session.kind == GameKind.AI_3X3 || session.kind == GameKind.AI_5X5) {
            _state.update { it.copy(game = updated.copy(isAiThinking = true)) }
            viewModelScope.launch {
                delay(350)
                val latest = _state.value.game
                val aiMove = GameEngine.bestMove(latest.board, latest.turn) ?: return@launch
                val aiBoard = latest.board.place(aiMove, latest.turn)
                val afterAi = latest.copy(
                    board = aiBoard,
                    turn = latest.turn.other(),
                    moves = latest.moves + 1,
                    isAiThinking = false,
                    message = "轮到你了"
                )
                _state.update { it.copy(game = afterAi) }
                completeIfNeeded(afterAi)
            }
        }
    }

    fun undo() {
        val session = _state.value.game
        if (session.kind == GameKind.LOGIC_6X6) {
            val previous = session.logicHistory.lastOrNull() ?: return
            tapFeedback()
            _state.update {
                it.copy(game = session.copy(
                    logicBoard = previous,
                    logicHistory = session.logicHistory.dropLast(1),
                    moves = (session.moves - 1).coerceAtLeast(0),
                    message = LogicPuzzleEngine.status(previous)
                ))
            }
            return
        }
        if (session.kind == GameKind.DAILY || session.moves == 0 || session.isAiThinking) return
        tapFeedback()
        val occupied = session.board.cells.indices.filter { session.board.cells[it] != Mark.EMPTY }
        val removeCount = if (session.kind == GameKind.LOCAL) 1 else 2
        val remove = occupied.takeLast(removeCount).toSet()
        val restored = session.board.copy(cells = session.board.cells.mapIndexed { index, mark ->
            if (index in remove) Mark.EMPTY else mark
        })
        val restoredMoves = (session.moves - remove.size).coerceAtLeast(0)
        _state.update {
            it.copy(game = session.copy(
                board = restored,
                turn = if (restoredMoves % 2 == 0) Mark.X else Mark.O,
                moves = restoredMoves,
                message = "已悔棋，轮到你了"
            ))
        }
    }

    fun surrender() {
        when (_state.value.game.kind) {
            GameKind.NETWORK -> netSurrender()
            GameKind.BLUETOOTH -> btSurrender()
            else -> finish(MatchResult.LOSS)
        }
    }

    fun replay() = startGame(_state.value.game.kind)

    private fun completeIfNeeded(session: GameSession): Boolean {
        val winner = session.board.winner()
        if (winner != null) {
            val result = if (session.kind == GameKind.LOCAL || winner == session.playerMark) MatchResult.WIN else MatchResult.LOSS
            finish(result)
            return true
        }
        if (session.board.isDraw()) {
            finish(MatchResult.DRAW)
            return true
        }
        return false
    }

    private fun finish(result: MatchResult) {
        val settings = _state.value.settings
        if (settings.sound) {
            val toneId = if (result == MatchResult.WIN) ToneGenerator.TONE_PROP_ACK else ToneGenerator.TONE_PROP_NACK
            runCatching { tone?.startTone(toneId, 350) }
        }
        if (settings.vibration) vibrate(if (result == MatchResult.WIN) 120 else 60)
        val session = _state.value.game
        local.save(MatchRecord(
            result = result,
            mode = when (session.kind) {
                GameKind.AI_3X3 -> "经典 3×3"
                GameKind.AI_5X5 -> "进阶 5×5"
                GameKind.LOGIC_6X6 -> "逻辑 OOXX 6×6"
                GameKind.LOCAL -> "双人同屏"
                GameKind.DAILY -> "每日挑战"
                GameKind.NETWORK -> "网络对战"
                GameKind.BLUETOOTH -> "蓝牙对战"
            },
            opponent = when (session.kind) {
                GameKind.LOCAL -> "本地玩家"
                GameKind.LOGIC_6X6 -> "逻辑谜题"
                GameKind.NETWORK, GameKind.BLUETOOTH -> session.opponentName ?: "在线玩家"
                else -> "AI 棋手"
            },
            steps = session.moves
        ))
        _state.update {
            it.copy(
                screen = Screen.RESULT,
                result = result,
                records = local.records(),
                ranking = local.ranking()
            )
        }
    }

    private fun loadDailyPuzzle() {
        _state.update { it.copy(isLoadingPuzzle = true, networkMessage = "正在从网络获取今日题目…") }
        viewModelScope.launch {
            val remote = network.fetchDailyPuzzle()
            val puzzle: Puzzle = remote.getOrElse { network.fallbackPuzzle() }
            val message = if (remote.isSuccess) "题目已从服务器获取并校验唯一解" else "服务器暂不可用，已生成本地唯一解题目"
            _state.update { it.copy(isLoadingPuzzle = false, networkMessage = message) }
            begin(GameSession(
                board = puzzle.board,
                turn = puzzle.player,
                playerMark = puzzle.player,
                kind = GameKind.DAILY,
                message = "请选择唯一最优的一步",
                puzzleAnswer = puzzle.answer
            ))
        }
    }
}
