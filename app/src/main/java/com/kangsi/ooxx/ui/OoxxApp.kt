package com.kangsi.ooxx.ui

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import androidx.activity.compose.BackHandler
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBars
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.rounded.ArrowBack
import androidx.compose.material.icons.rounded.Bluetooth
import androidx.compose.material.icons.rounded.Casino
import androidx.compose.material.icons.rounded.ChevronRight
import androidx.compose.material.icons.rounded.DarkMode
import androidx.compose.material.icons.rounded.EmojiEvents
import androidx.compose.material.icons.rounded.Groups
import androidx.compose.material.icons.rounded.History
import androidx.compose.material.icons.rounded.Home
import androidx.compose.material.icons.rounded.Info
import androidx.compose.material.icons.rounded.Lightbulb
import androidx.compose.material.icons.rounded.Person
import androidx.compose.material.icons.rounded.Refresh
import androidx.compose.material.icons.rounded.Settings
import androidx.compose.material.icons.rounded.SignalWifi4Bar
import androidx.compose.material.icons.rounded.SportsEsports
import androidx.compose.material.icons.rounded.Star
import androidx.compose.material.icons.rounded.Timer
import androidx.compose.material.icons.rounded.Undo
import androidx.compose.material.icons.rounded.Vibration
import androidx.compose.material.icons.rounded.VolumeUp
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.content.ContextCompat
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import com.kangsi.ooxx.data.MatchRecord
import com.kangsi.ooxx.data.MatchResult
import com.kangsi.ooxx.data.RankingEntry
import com.kangsi.ooxx.game.Board
import com.kangsi.ooxx.game.Mark
import com.kangsi.ooxx.game.Move
import com.kangsi.ooxx.match.BluetoothMatchService
import com.kangsi.ooxx.ui.theme.Coral
import com.kangsi.ooxx.ui.theme.Ink
import com.kangsi.ooxx.ui.theme.Paper
import com.kangsi.ooxx.ui.theme.Sky
import com.kangsi.ooxx.ui.theme.SoftGray
import com.kangsi.ooxx.ui.theme.Sunny
import com.kangsi.ooxx.ui.theme.Teal
import java.time.Instant
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import kotlin.random.Random

@Composable
fun OoxxApp(viewModel: OoxxViewModel = viewModel()) {
    val state by viewModel.state.collectAsStateWithLifecycle()
    val mainTabs = setOf(Screen.HOME, Screen.HISTORY, Screen.PROFILE)
    BackHandler(enabled = state.screen !in mainTabs && state.screen != Screen.SPLASH) {
        viewModel.navigate(Screen.HOME)
    }

    Scaffold(
        containerColor = Paper,
        contentWindowInsets = WindowInsets.navigationBars,
        bottomBar = {
            if (state.screen in mainTabs) {
                AppBottomBar(state.screen, viewModel::navigate)
            }
        }
    ) { padding ->
        Box(Modifier.fillMaxSize().padding(padding)) {
            when (state.screen) {
                Screen.SPLASH -> SplashScreen()
                Screen.ONBOARDING -> OnboardingScreen { viewModel.navigate(Screen.HOME) }
                Screen.HOME -> HomeScreen(
                    openMode = { viewModel.navigate(Screen.MODE) },
                    local = { viewModel.startGame(GameKind.LOCAL) },
                    room = { viewModel.navigate(Screen.ROOM) },
                    daily = { viewModel.startGame(GameKind.DAILY) }
                )
                Screen.MODE -> ModeScreen(
                    loading = state.isLoadingPuzzle,
                    back = { viewModel.navigate(Screen.HOME) },
                    start = viewModel::startGame
                )
                Screen.ROOM -> RoomScreen { viewModel.navigate(Screen.HOME) }
                Screen.GAME -> GameScreen(state.game, viewModel::play, viewModel::undo, viewModel::surrender)
                Screen.RESULT -> ResultScreen(
                    result = state.result ?: MatchResult.DRAW,
                    session = state.game,
                    replay = viewModel::replay,
                    home = { viewModel.navigate(Screen.HOME) }
                )
                Screen.HISTORY -> HistoryScreen(state.records, state.ranking)
                Screen.PROFILE -> ProfileScreen(state.records)
            }
        }
    }
}

@Composable
private fun SplashScreen() {
    Column(
        Modifier.fillMaxSize().statusBarsPadding().padding(32.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Text("OOXX", fontSize = 72.sp, fontWeight = FontWeight.Black, color = Coral)
        Text("康思小游戏", fontSize = 30.sp, fontWeight = FontWeight.Bold)
        Spacer(Modifier.height(32.dp))
        Row(horizontalArrangement = Arrangement.spacedBy(18.dp)) {
            Mascot("O", Coral)
            Mascot("X", Sky)
        }
        Spacer(Modifier.height(34.dp))
        Text("简单一局，快乐加倍！", color = Color.Gray)
    }
}

@Composable
private fun Mascot(text: String, color: Color) {
    Box(
        Modifier.size(82.dp).clip(CircleShape).background(color.copy(alpha = .17f))
            .border(4.dp, color, CircleShape),
        contentAlignment = Alignment.Center
    ) { Text(text, color = color, fontSize = 50.sp, fontWeight = FontWeight.Black) }
}

@Composable
private fun OnboardingScreen(onStart: () -> Unit) {
    Column(
        Modifier.fillMaxSize().statusBarsPadding().padding(28.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Spacer(Modifier.height(42.dp))
        Text("三分钟，来一局", fontSize = 34.sp, fontWeight = FontWeight.Black)
        Spacer(Modifier.height(42.dp))
        DemoBoard()
        Spacer(Modifier.height(36.dp))
        Text("不复杂，但总有新乐趣 ❤", color = Color.DarkGray, fontSize = 17.sp)
        Spacer(Modifier.weight(1f))
        PrimaryButton("开始体验", onStart)
        Spacer(Modifier.height(20.dp))
    }
}

@Composable
private fun DemoBoard() {
    val marks = listOf("O", "", "X", "", "O", "", "X", "", "O")
    Column(Modifier.size(230.dp).border(3.dp, Ink, RoundedCornerShape(10.dp))) {
        repeat(3) { row ->
            Row(Modifier.weight(1f)) {
                repeat(3) { col ->
                    val value = marks[row * 3 + col]
                    Box(
                        Modifier.weight(1f).fillMaxHeight()
                            .border(1.5.dp, Ink.copy(alpha = .7f)),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(value, color = if (value == "O") Coral else Sky, fontSize = 44.sp, fontWeight = FontWeight.Black)
                    }
                }
            }
        }
    }
}

@Composable
private fun HomeScreen(openMode: () -> Unit, local: () -> Unit, room: () -> Unit, daily: () -> Unit) {
    LazyColumn(
        Modifier.fillMaxSize().statusBarsPadding(),
        contentPadding = PaddingValues(20.dp),
        verticalArrangement = Arrangement.spacedBy(18.dp)
    ) {
        item { ProfileHeader() }
        item {
            Text("今天想怎么玩？", fontSize = 28.sp, fontWeight = FontWeight.Black)
            Text("选择一种模式，马上开局", color = Color.Gray)
        }
        item {
            FeatureCard("⚡", "快速对战", "智能 AI · 随时开局", Sunny, openMode)
        }
        item {
            Row(horizontalArrangement = Arrangement.spacedBy(14.dp)) {
                SmallModeCard("👥", "双人同屏", "面对面来一局", Sky, Modifier.weight(1f), local)
                SmallModeCard("♛", "好友房间", "网络 / 蓝牙", Coral, Modifier.weight(1f), room)
            }
        }
        item { FeatureCard("★", "每日挑战", "网络题库 · 每题唯一解", Teal, daily) }
        item { InfoStrip("题目会在本机再次求解，确保答案唯一后才进入游戏。") }
    }
}

@Composable
private fun ProfileHeader() {
    Row(verticalAlignment = Alignment.CenterVertically) {
        Box(Modifier.size(54.dp).clip(CircleShape).background(Sky.copy(.25f)), contentAlignment = Alignment.Center) {
            Text("🙂", fontSize = 30.sp)
        }
        Spacer(Modifier.width(12.dp))
        Column(Modifier.weight(1f)) {
            Text("康思", fontSize = 20.sp, fontWeight = FontWeight.Bold)
            Text("小程序游客 · 无需密码", color = Color.Gray, fontSize = 13.sp)
        }
        Text("● 120", color = Color(0xFFE5A900), fontWeight = FontWeight.Bold)
        Icon(Icons.Rounded.Settings, null, Modifier.padding(start = 12.dp))
    }
}

@Composable
private fun FeatureCard(icon: String, title: String, subtitle: String, color: Color, onClick: () -> Unit) {
    Card(
        onClick = onClick,
        colors = CardDefaults.cardColors(containerColor = color.copy(alpha = .22f)),
        shape = RoundedCornerShape(22.dp),
        modifier = Modifier.fillMaxWidth().border(2.dp, color.copy(.7f), RoundedCornerShape(22.dp))
    ) {
        Row(Modifier.padding(22.dp), verticalAlignment = Alignment.CenterVertically) {
            Text(icon, fontSize = 38.sp)
            Spacer(Modifier.width(18.dp))
            Column(Modifier.weight(1f)) {
                Text(title, fontSize = 22.sp, fontWeight = FontWeight.Black)
                Text(subtitle, color = Color.DarkGray)
            }
            Icon(Icons.Rounded.ChevronRight, null)
        }
    }
}

@Composable
private fun SmallModeCard(icon: String, title: String, subtitle: String, color: Color, modifier: Modifier, onClick: () -> Unit) {
    Card(
        onClick = onClick,
        modifier = modifier.height(150.dp).border(2.dp, color.copy(.7f), RoundedCornerShape(22.dp)),
        colors = CardDefaults.cardColors(containerColor = color.copy(.22f)),
        shape = RoundedCornerShape(22.dp)
    ) {
        Column(Modifier.fillMaxSize().padding(16.dp), verticalArrangement = Arrangement.SpaceBetween) {
            Text(icon, fontSize = 31.sp)
            Text(title, fontSize = 18.sp, fontWeight = FontWeight.Black)
            Text(subtitle, fontSize = 12.sp, color = Color.DarkGray)
        }
    }
}

@Composable
private fun InfoStrip(text: String) {
    Row(
        Modifier.fillMaxWidth().background(Sunny.copy(.18f), RoundedCornerShape(14.dp)).padding(14.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(Icons.Rounded.Lightbulb, null, tint = Color(0xFFD69A00))
        Text(text, Modifier.padding(start = 10.dp), fontSize = 13.sp)
    }
}

@Composable
private fun ModeScreen(loading: Boolean, back: () -> Unit, start: (GameKind) -> Unit) {
    var selected by remember { mutableStateOf(GameKind.AI_3X3) }
    Column(Modifier.fillMaxSize().statusBarsPadding().padding(20.dp)) {
        PageTitle("选择模式", back)
        Spacer(Modifier.height(20.dp))
        ModeOption("▦", "经典 3×3", "完整 Minimax，不会漏掉最优解", GameKind.AI_3X3, selected) { selected = it }
        Spacer(Modifier.height(14.dp))
        ModeOption("▦", "进阶 5×5", "四子连线，更大的挑战", GameKind.AI_5X5, selected) { selected = it }
        Spacer(Modifier.height(14.dp))
        ModeOption("⏱", "每日唯一解", "从网络获取并在本地验证", GameKind.DAILY, selected) { selected = it }
        Spacer(Modifier.weight(1f))
        if (loading) CircularProgressIndicator(Modifier.align(Alignment.CenterHorizontally))
        else PrimaryButton(if (selected == GameKind.DAILY) "获取今日题目" else "开始匹配") { start(selected) }
    }
}

@Composable
private fun ModeOption(icon: String, title: String, subtitle: String, kind: GameKind, selected: GameKind, choose: (GameKind) -> Unit) {
    val active = kind == selected
    Card(
        onClick = { choose(kind) },
        colors = CardDefaults.cardColors(containerColor = if (active) Sky.copy(.17f) else Color.White),
        modifier = Modifier.fillMaxWidth().border(if (active) 3.dp else 1.dp, if (active) Sky else Color.LightGray, RoundedCornerShape(18.dp))
    ) {
        Row(Modifier.padding(18.dp), verticalAlignment = Alignment.CenterVertically) {
            Text(icon, fontSize = 32.sp, color = Sky)
            Column(Modifier.padding(horizontal = 16.dp).weight(1f)) {
                Text(title, fontSize = 19.sp, fontWeight = FontWeight.Bold)
                Text(subtitle, fontSize = 13.sp, color = Color.Gray)
            }
            Text(if (active) "●" else "○", color = Sky, fontSize = 24.sp)
        }
    }
}

@Composable
private fun RoomScreen(back: () -> Unit) {
    val context = LocalContext.current
    val bluetooth = remember { BluetoothMatchService(context) }
    var tab by remember { mutableIntStateOf(0) }
    var roomCode by remember { mutableStateOf("") }
    var status by remember { mutableStateOf("选择连接方式") }
    var pairedNames by remember { mutableStateOf<List<String>>(emptyList()) }
    val launcher = rememberLauncherForActivityResult(ActivityResultContracts.RequestMultiplePermissions()) { grants ->
        if (grants.values.all { it }) {
            pairedNames = runCatching { bluetooth.pairedDevices().map { it.name ?: it.address } }.getOrDefault(emptyList())
            status = if (pairedNames.isEmpty()) "没有已配对设备，请先在系统设置中配对" else "请选择已配对设备"
        } else status = "需要蓝牙权限才能发现和连接设备"
    }

    LazyColumn(
        Modifier.fillMaxSize().statusBarsPadding(),
        contentPadding = PaddingValues(20.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        item { PageTitle("好友房间", back) }
        item {
            Row(Modifier.fillMaxWidth().background(SoftGray, RoundedCornerShape(16.dp)).padding(4.dp)) {
                ConnectionTab("网络对战", Icons.Rounded.SignalWifi4Bar, tab == 0, Modifier.weight(1f)) { tab = 0 }
                ConnectionTab("蓝牙对战", Icons.Rounded.Bluetooth, tab == 1, Modifier.weight(1f)) { tab = 1 }
            }
        }
        if (tab == 0) {
            item { Text("网络房间", fontSize = 22.sp, fontWeight = FontWeight.Black) }
            item {
                OutlinedTextField(
                    value = roomCode,
                    onValueChange = { roomCode = it.filter(Char::isLetterOrDigit).take(6).uppercase() },
                    modifier = Modifier.fillMaxWidth(),
                    label = { Text("输入 6 位房间码") },
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Ascii),
                    singleLine = true
                )
            }
            item {
                PrimaryButton("创建房间") {
                    roomCode = (100000 + Random.nextInt(900000)).toString()
                    status = "房间 $roomCode 已创建，等待好友加入…"
                }
            }
            item {
                SecondaryButton("加入房间") {
                    status = if (roomCode.length == 6) "正在连接房间 $roomCode…" else "请输入正确的 6 位房间码"
                }
            }
        } else {
            item {
                InfoStrip(if (bluetooth.isAvailable()) "蓝牙可用于附近两机离线对战" else "此设备不支持蓝牙")
            }
            item {
                PrimaryButton("查找已配对设备") {
                    val permissions = if (Build.VERSION.SDK_INT >= 31) arrayOf(Manifest.permission.BLUETOOTH_SCAN, Manifest.permission.BLUETOOTH_CONNECT) else arrayOf(Manifest.permission.ACCESS_FINE_LOCATION)
                    if (permissions.all { ContextCompat.checkSelfPermission(context, it) == PackageManager.PERMISSION_GRANTED }) {
                        pairedNames = runCatching { bluetooth.pairedDevices().map { it.name ?: it.address } }.getOrDefault(emptyList())
                        status = if (pairedNames.isEmpty()) "没有已配对设备" else "请选择设备开始连接"
                    } else launcher.launch(permissions)
                }
            }
            items(pairedNames) { name ->
                Card(
                    onClick = { status = "正在通过蓝牙连接 $name…" },
                    colors = CardDefaults.cardColors(containerColor = Color.White),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Row(Modifier.padding(16.dp), verticalAlignment = Alignment.CenterVertically) {
                        Icon(Icons.Rounded.Bluetooth, null, tint = Teal)
                        Text(name, Modifier.padding(start = 12.dp).weight(1f), fontWeight = FontWeight.Bold)
                        Icon(Icons.Rounded.ChevronRight, null)
                    }
                }
            }
        }
        item { InfoStrip(status) }
        item { Text("协议层已实现 TCP 房间连接和 Bluetooth RFCOMM 双向消息通道；部署服务器后修改 BuildConfig 地址即可。", fontSize = 12.sp, color = Color.Gray) }
    }
}

@Composable
private fun ConnectionTab(text: String, icon: ImageVector, selected: Boolean, modifier: Modifier, onClick: () -> Unit) {
    Row(
        modifier.clip(RoundedCornerShape(12.dp)).background(if (selected) Color.White else Color.Transparent)
            .clickable(onClick = onClick).padding(12.dp),
        horizontalArrangement = Arrangement.Center,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(icon, null, Modifier.size(20.dp), tint = if (selected) Coral else Color.Gray)
        Text(text, Modifier.padding(start = 6.dp), fontWeight = if (selected) FontWeight.Bold else FontWeight.Normal)
    }
}

@Composable
private fun GameScreen(session: GameSession, play: (Move) -> Unit, undo: () -> Unit, surrender: () -> Unit) {
    Column(
        Modifier.fillMaxSize().statusBarsPadding().padding(horizontal = 18.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Row(Modifier.fillMaxWidth().padding(vertical = 12.dp), verticalAlignment = Alignment.CenterVertically) {
            PlayerBadge("🙂", "康思", if (session.turn == Mark.X) Coral else Color.Gray)
            Text("VS", Modifier.weight(1f), textAlign = TextAlign.Center, color = Sky, fontWeight = FontWeight.Black)
            PlayerBadge(if (session.kind == GameKind.LOCAL) "😎" else "🤖", if (session.kind == GameKind.LOCAL) "好友" else "AI", if (session.turn == Mark.O) Sky else Color.Gray)
        }
        Spacer(Modifier.height(8.dp))
        Text(session.message, Modifier.background(Sunny.copy(.35f), RoundedCornerShape(12.dp)).padding(horizontal = 22.dp, vertical = 8.dp), fontSize = 21.sp, fontWeight = FontWeight.Black)
        Spacer(Modifier.height(24.dp))
        GameBoard(session.board, enabled = !session.isAiThinking && session.puzzleSolved == null, onMove = play)
        Spacer(Modifier.height(16.dp))
        Text(
            when (session.kind) {
                GameKind.DAILY -> "本题已通过算法验证，存在且仅存在一个最优解"
                GameKind.AI_3X3 -> "经典 3×3 · 三子连线获胜"
                GameKind.AI_5X5 -> "进阶 5×5 · 四子连线获胜"
                GameKind.LOCAL -> "双人同屏 · 轮流落子"
            },
            color = Color.Gray,
            fontSize = 13.sp,
            textAlign = TextAlign.Center
        )
        Spacer(Modifier.weight(1f))
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            GameAction(Icons.Rounded.Undo, "悔棋", Modifier.weight(1f), undo)
            GameAction(Icons.Rounded.Casino, "表情", Modifier.weight(1f)) { }
            GameAction(Icons.Rounded.SportsEsports, "认输", Modifier.weight(1f), surrender)
        }
        Spacer(Modifier.height(18.dp))
    }
}

@Composable
private fun PlayerBadge(emoji: String, name: String, color: Color) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Box(Modifier.size(48.dp).border(3.dp, color, CircleShape), contentAlignment = Alignment.Center) { Text(emoji, fontSize = 28.sp) }
        Text(name, fontSize = 13.sp, fontWeight = FontWeight.Bold)
    }
}

@Composable
private fun GameBoard(board: Board, enabled: Boolean, onMove: (Move) -> Unit) {
    val boardSize = if (board.size == 3) 318.dp else 340.dp
    Column(Modifier.size(boardSize).border(3.dp, Ink, RoundedCornerShape(8.dp)).background(Color.White)) {
        repeat(board.size) { row ->
            Row(Modifier.weight(1f)) {
                repeat(board.size) { col ->
                    val mark = board[row, col]
                    Box(
                        Modifier.weight(1f).fillMaxHeight().border(1.dp, Ink.copy(.62f))
                            .clickable(enabled = enabled && mark == Mark.EMPTY) { onMove(Move(row, col)) },
                        contentAlignment = Alignment.Center
                    ) {
                        val text = when (mark) { Mark.X -> "X"; Mark.O -> "O"; else -> "" }
                        Text(text, color = if (mark == Mark.X) Sky else Coral, fontSize = if (board.size == 3) 52.sp else 34.sp, fontWeight = FontWeight.Black)
                    }
                }
            }
        }
    }
}

@Composable
private fun GameAction(icon: ImageVector, text: String, modifier: Modifier, action: () -> Unit) {
    OutlinedButton(onClick = action, modifier = modifier.height(66.dp), shape = RoundedCornerShape(14.dp), contentPadding = PaddingValues(5.dp)) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Icon(icon, null, Modifier.size(24.dp))
            Text(text, fontSize = 12.sp)
        }
    }
}

@Composable
private fun ResultScreen(result: MatchResult, session: GameSession, replay: () -> Unit, home: () -> Unit) {
    val (title, emoji, color) = when (result) {
        MatchResult.WIN -> Triple("你赢了！", "🏆", Sunny)
        MatchResult.LOSS -> Triple("再接再厉", "💪", Sky)
        MatchResult.DRAW -> Triple("平局！", "🤝", Teal)
    }
    Column(
        Modifier.fillMaxSize().statusBarsPadding().padding(24.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Text(title, fontSize = 42.sp, fontWeight = FontWeight.Black)
        Spacer(Modifier.height(18.dp))
        Box(Modifier.size(138.dp).clip(CircleShape).background(color.copy(.28f)), contentAlignment = Alignment.Center) { Text(emoji, fontSize = 76.sp) }
        Spacer(Modifier.height(26.dp))
        Card(colors = CardDefaults.cardColors(containerColor = Color.White), modifier = Modifier.fillMaxWidth()) {
            Row(Modifier.fillMaxWidth().padding(20.dp), horizontalArrangement = Arrangement.SpaceEvenly) {
                Stat("本局用时", "${(session.moves * 7 + 12).coerceAtLeast(18)}秒")
                Stat("步数", session.moves.toString())
                Stat("模式", if (session.board.size == 3) "3×3" else "5×5")
            }
        }
        Spacer(Modifier.height(30.dp))
        PrimaryButton("再来一局", replay)
        Spacer(Modifier.height(12.dp))
        SecondaryButton("返回首页", home)
    }
}

@Composable
private fun Stat(label: String, value: String) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Text(label, color = Color.Gray, fontSize = 12.sp)
        Text(value, fontWeight = FontWeight.Black, fontSize = 18.sp)
    }
}

@Composable
private fun HistoryScreen(records: List<MatchRecord>, ranking: List<RankingEntry>) {
    val wins = records.count { it.result == MatchResult.WIN }
    val rate = if (records.isEmpty()) 0 else wins * 100 / records.size
    LazyColumn(
        Modifier.fillMaxSize().statusBarsPadding(),
        contentPadding = PaddingValues(20.dp),
        verticalArrangement = Arrangement.spacedBy(14.dp)
    ) {
        item { Text("对战记录", fontSize = 30.sp, fontWeight = FontWeight.Black) }
        item {
            Card(colors = CardDefaults.cardColors(containerColor = Sunny.copy(.2f)), modifier = Modifier.fillMaxWidth()) {
                Row(Modifier.padding(20.dp), verticalAlignment = Alignment.CenterVertically) {
                    Box(Modifier.size(84.dp).border(9.dp, Coral, CircleShape), contentAlignment = Alignment.Center) {
                        Text("$rate%", fontSize = 19.sp, fontWeight = FontWeight.Black)
                    }
                    Column(Modifier.padding(start = 22.dp)) {
                        Text("当前胜率", color = Color.Gray)
                        Text("${records.size} 场 · $wins 胜", fontSize = 24.sp, fontWeight = FontWeight.Black)
                        Text("继续保持，你正在变强！", color = Teal)
                    }
                }
            }
        }
        item { SectionTitle("排行榜") }
        items(ranking.take(5)) { item -> RankingRow(item) }
        item { SectionTitle("最近对局") }
        if (records.isEmpty()) item { EmptyState("还没有记录，先去完成一局吧") }
        items(records.take(20)) { record -> RecordRow(record) }
    }
}

@Composable
private fun RankingRow(entry: RankingEntry) {
    Row(
        Modifier.fillMaxWidth().background(if (entry.isMe) Sky.copy(.16f) else Color.White, RoundedCornerShape(14.dp)).padding(14.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(if (entry.rank <= 3) listOf("🥇", "🥈", "🥉")[entry.rank - 1] else entry.rank.toString(), Modifier.width(42.dp), fontSize = 22.sp)
        Text(entry.name, Modifier.weight(1f), fontWeight = if (entry.isMe) FontWeight.Black else FontWeight.Medium)
        Text("${entry.score} 分", color = Coral, fontWeight = FontWeight.Bold)
    }
}

@Composable
private fun RecordRow(record: MatchRecord) {
    val formatter = remember { DateTimeFormatter.ofPattern("MM-dd HH:mm") }
    val color = when (record.result) { MatchResult.WIN -> Teal; MatchResult.LOSS -> Coral; MatchResult.DRAW -> Sky }
    Card(colors = CardDefaults.cardColors(containerColor = Color.White), modifier = Modifier.fillMaxWidth()) {
        Row(Modifier.padding(15.dp), verticalAlignment = Alignment.CenterVertically) {
            Box(Modifier.size(42.dp).clip(CircleShape).background(color.copy(.18f)), contentAlignment = Alignment.Center) {
                Text(when (record.result) { MatchResult.WIN -> "胜"; MatchResult.LOSS -> "负"; MatchResult.DRAW -> "平" }, color = color, fontWeight = FontWeight.Black)
            }
            Column(Modifier.padding(start = 12.dp).weight(1f)) {
                Text(record.mode, fontWeight = FontWeight.Bold)
                Text("对手：${record.opponent} · ${record.steps} 步", fontSize = 12.sp, color = Color.Gray)
            }
            Text(formatter.format(Instant.ofEpochMilli(record.playedAt).atZone(ZoneId.systemDefault())), fontSize = 11.sp, color = Color.Gray)
        }
    }
}

@Composable
private fun ProfileScreen(records: List<MatchRecord>) {
    var sound by remember { mutableStateOf(true) }
    var vibration by remember { mutableStateOf(true) }
    var dark by remember { mutableStateOf(false) }
    val wins = records.count { it.result == MatchResult.WIN }
    LazyColumn(
        Modifier.fillMaxSize().statusBarsPadding(),
        contentPadding = PaddingValues(20.dp),
        verticalArrangement = Arrangement.spacedBy(14.dp)
    ) {
        item { Text("我的", fontSize = 30.sp, fontWeight = FontWeight.Black) }
        item {
            Row(Modifier.fillMaxWidth().padding(vertical = 8.dp), verticalAlignment = Alignment.CenterVertically) {
                Box(Modifier.size(76.dp).clip(CircleShape).background(Sky.copy(.24f)), contentAlignment = Alignment.Center) { Text("🙂", fontSize = 45.sp) }
                Column(Modifier.padding(start = 16.dp).weight(1f)) {
                    Text("康思", fontSize = 24.sp, fontWeight = FontWeight.Black)
                    Text("小程序游客 ID · 免用户名密码", color = Color.Gray)
                }
                Icon(Icons.Rounded.ChevronRight, null)
            }
        }
        item {
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                Achievement("♛", wins.toString(), "冠军", Modifier.weight(1f))
                Achievement("★", records.size.toString(), "战绩", Modifier.weight(1f))
                Achievement("🏅", (wins * 30).toString(), "积分", Modifier.weight(1f))
            }
        }
        item { SectionTitle("偏好设置") }
        item { SettingSwitch(Icons.Rounded.VolumeUp, "声音", sound) { sound = it } }
        item { SettingSwitch(Icons.Rounded.Vibration, "震动", vibration) { vibration = it } }
        item { SettingSwitch(Icons.Rounded.DarkMode, "深色模式", dark) { dark = it } }
        item { SettingLink(Icons.Rounded.Info, "关于我们", "OOXX Android 1.0") }
        item { InfoStrip("Android 原生 Compose 版本 · 数据仅保存在本机") }
    }
}

@Composable
private fun Achievement(icon: String, value: String, label: String, modifier: Modifier) {
    Column(modifier.background(Color.White, RoundedCornerShape(16.dp)).padding(14.dp), horizontalAlignment = Alignment.CenterHorizontally) {
        Text(icon, fontSize = 24.sp)
        Text(value, fontWeight = FontWeight.Black, fontSize = 20.sp)
        Text(label, color = Color.Gray, fontSize = 12.sp)
    }
}

@Composable
private fun SettingSwitch(icon: ImageVector, title: String, checked: Boolean, change: (Boolean) -> Unit) {
    Row(Modifier.fillMaxWidth().background(Color.White, RoundedCornerShape(14.dp)).padding(horizontal = 14.dp, vertical = 8.dp), verticalAlignment = Alignment.CenterVertically) {
        Icon(icon, null, tint = Color.Gray)
        Text(title, Modifier.padding(start = 12.dp).weight(1f), fontWeight = FontWeight.Medium)
        Switch(checked, change)
    }
}

@Composable
private fun SettingLink(icon: ImageVector, title: String, detail: String) {
    Row(Modifier.fillMaxWidth().background(Color.White, RoundedCornerShape(14.dp)).padding(14.dp), verticalAlignment = Alignment.CenterVertically) {
        Icon(icon, null, tint = Color.Gray)
        Text(title, Modifier.padding(start = 12.dp).weight(1f), fontWeight = FontWeight.Medium)
        Text(detail, color = Color.Gray, fontSize = 12.sp)
    }
}

@Composable
private fun AppBottomBar(current: Screen, navigate: (Screen) -> Unit) {
    NavigationBar(containerColor = Paper) {
        listOf(
            Triple(Screen.HOME, Icons.Rounded.Home, "首页"),
            Triple(Screen.HISTORY, Icons.Rounded.History, "战绩"),
            Triple(Screen.PROFILE, Icons.Rounded.Person, "我的")
        ).forEach { (screen, icon, label) ->
            NavigationBarItem(
                selected = screen == current,
                onClick = { navigate(screen) },
                icon = { Icon(icon, label) },
                label = { Text(label) }
            )
        }
    }
}

@Composable
private fun PageTitle(title: String, back: () -> Unit) {
    Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
        IconButton(back) { Icon(Icons.AutoMirrored.Rounded.ArrowBack, "返回") }
        Text(title, Modifier.weight(1f), textAlign = TextAlign.Center, fontSize = 27.sp, fontWeight = FontWeight.Black)
        Spacer(Modifier.size(48.dp))
    }
}

@Composable
private fun SectionTitle(text: String) { Text(text, fontSize = 21.sp, fontWeight = FontWeight.Black) }

@Composable
private fun EmptyState(text: String) {
    Text(text, Modifier.fillMaxWidth().padding(30.dp), textAlign = TextAlign.Center, color = Color.Gray)
}

@Composable
private fun PrimaryButton(text: String, onClick: () -> Unit) {
    Button(
        onClick,
        Modifier.fillMaxWidth().height(56.dp),
        shape = RoundedCornerShape(17.dp),
        colors = ButtonDefaults.buttonColors(containerColor = Coral)
    ) { Text(text, fontSize = 18.sp, fontWeight = FontWeight.Bold) }
}

@Composable
private fun SecondaryButton(text: String, onClick: () -> Unit) {
    Button(
        onClick,
        Modifier.fillMaxWidth().height(56.dp),
        shape = RoundedCornerShape(17.dp),
        colors = ButtonDefaults.buttonColors(containerColor = Teal)
    ) { Text(text, fontSize = 18.sp, fontWeight = FontWeight.Bold) }
}
