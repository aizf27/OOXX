package com.kangsi.ooxx.ui

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.kangsi.ooxx.data.LocalGameRepository
import com.kangsi.ooxx.data.MatchRecord
import com.kangsi.ooxx.data.MatchResult
import com.kangsi.ooxx.data.NetworkGameRepository
import com.kangsi.ooxx.data.RankingEntry
import com.kangsi.ooxx.game.Board
import com.kangsi.ooxx.game.GameEngine
import com.kangsi.ooxx.game.Mark
import com.kangsi.ooxx.game.Move
import com.kangsi.ooxx.game.Puzzle
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

enum class Screen { SPLASH, ONBOARDING, HOME, MODE, ROOM, GAME, RESULT, HISTORY, PROFILE }
enum class GameKind { AI_3X3, AI_5X5, LOCAL, DAILY }

data class GameSession(
    val board: Board = Board(),
    val turn: Mark = Mark.X,
    val playerMark: Mark = Mark.X,
    val kind: GameKind = GameKind.AI_3X3,
    val moves: Int = 0,
    val message: String = "轮到你了",
    val puzzleAnswer: Move? = null,
    val puzzleSolved: Boolean? = null,
    val isAiThinking: Boolean = false
)

data class AppState(
    val screen: Screen = Screen.SPLASH,
    val game: GameSession = GameSession(),
    val result: MatchResult? = null,
    val records: List<MatchRecord> = emptyList(),
    val ranking: List<RankingEntry> = emptyList(),
    val networkMessage: String = "",
    val isLoadingPuzzle: Boolean = false
)

class OoxxViewModel(application: Application) : AndroidViewModel(application) {
    private val local = LocalGameRepository(application)
    private val network = NetworkGameRepository()
    private val _state = MutableStateFlow(
        AppState(records = local.records(), ranking = local.ranking())
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

    fun startGame(kind: GameKind) {
        when (kind) {
            GameKind.DAILY -> loadDailyPuzzle()
            GameKind.AI_5X5 -> begin(GameSession(board = Board(size = 5, winLength = 4), kind = kind))
            else -> begin(GameSession(kind = kind))
        }
    }

    private fun begin(game: GameSession) {
        _state.update { it.copy(screen = Screen.GAME, game = game, result = null, networkMessage = "") }
    }

    fun play(move: Move) {
        val session = _state.value.game
        if (session.isAiThinking || session.board.winner() != null || session.board.isDraw()) return
        if (move !in session.board.availableMoves()) return

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
        if (session.kind == GameKind.DAILY || session.moves == 0 || session.isAiThinking) return
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

    fun surrender() = finish(MatchResult.LOSS)

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
        val session = _state.value.game
        local.save(MatchRecord(
            result = result,
            mode = when (session.kind) {
                GameKind.AI_3X3 -> "经典 3×3"
                GameKind.AI_5X5 -> "进阶 5×5"
                GameKind.LOCAL -> "双人同屏"
                GameKind.DAILY -> "每日挑战"
            },
            opponent = if (session.kind == GameKind.LOCAL) "本地玩家" else "AI 棋手",
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
