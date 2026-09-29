package com.kangsi.ooxx.ui

import android.Manifest
import android.bluetooth.BluetoothDevice
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
import androidx.compose.foundation.Image
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.selection.selectable
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
import androidx.compose.material3.NavigationBarItemDefaults
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.SideEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.tooling.preview.Preview
import androidx.core.content.ContextCompat
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import com.kangsi.ooxx.data.MatchRecord
import com.kangsi.ooxx.data.MatchResult
import com.kangsi.ooxx.data.RankingEntry
import com.kangsi.ooxx.game.Board
import com.kangsi.ooxx.game.Mark
import com.kangsi.ooxx.game.Move
import com.kangsi.ooxx.game.LogicBoard
import com.kangsi.ooxx.game.LogicPuzzleEngine
import com.kangsi.ooxx.match.BluetoothMatchService
import com.kangsi.ooxx.R
import com.kangsi.ooxx.ui.theme.CardSurface
import com.kangsi.ooxx.ui.theme.Coral
import com.kangsi.ooxx.ui.theme.darkModeEnabled
import com.kangsi.ooxx.ui.theme.Ink
import com.kangsi.ooxx.ui.theme.OoxxTheme
import com.kangsi.ooxx.ui.theme.Paper
import com.kangsi.ooxx.ui.theme.Sky
import com.kangsi.ooxx.ui.theme.SoftGray
import com.kangsi.ooxx.ui.theme.TextSecondary
import com.kangsi.ooxx.ui.theme.Sunny
import com.kangsi.ooxx.ui.theme.Teal
import java.time.Instant
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import kotlin.random.Random

@Composable
fun OoxxApp(viewModel: OoxxViewModel = viewModel()) {
    val state by viewModel.state.collectAsStateWithLifecycle()
    SideEffect { darkModeEnabled = state.settings.darkMode }
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
                Screen.ROOM -> RoomScreen(
                    network = state.network,
                    back = { viewModel.navigate(Screen.HOME) },
                    onCreate = viewModel::createRoom,
                    onJoin = viewModel::joinRoom,
                    onBluetoothHost = viewModel::bluetoothHost,
                    onBluetoothJoin = viewModel::bluetoothJoin,
                    bluetoothAvailable = viewModel.bluetoothAvailable(),
                    onBluetoothDevices = viewModel::bluetoothDevices,
                    onBluetoothStatus = viewModel::btStatus
                )
                Screen.GAME -> GameScreen(state.game, viewModel::play, viewModel::undo, viewModel::replay, viewModel::surrender)
                Screen.RESULT -> ResultScreen(
                    result = state.result ?: MatchResult.DRAW,
                    session = state.game,
                    replay = viewModel::replay,
                    home = { viewModel.navigate(Screen.HOME) }
                )
                Screen.HISTORY -> HistoryScreen(state.records, state.ranking)
                Screen.PROFILE -> ProfileScreen(
                    settings = state.settings,
                    records = state.records,
                    onSound = viewModel::setSound,
                    onVibration = viewModel::setVibration,
                    onDarkMode = viewModel::setDarkMode
                )
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
        Row(horizontalArrangement = Arrangement.spacedBy(1.dp)) {
            Text("O", fontSize = 52.sp, fontWeight = FontWeight.Black, color = Coral)
            Text("O", fontSize = 52.sp, fontWeight = FontWeight.Black, color = Sky)
            Text("X", fontSize = 52.sp, fontWeight = FontWeight.Black, color = Ink)
            Text("X", fontSize = 52.sp, fontWeight = FontWeight.Black, color = Ink)
        }
        Text("康思小游戏", fontSize = 25.sp, fontWeight = FontWeight.Bold)
        Spacer(Modifier.height(32.dp))
        Row(horizontalArrangement = Arrangement.spacedBy(18.dp)) {
            Mascot("O", Coral)
            Mascot("X", Sky)
        }
        Spacer(Modifier.height(24.dp))
        Text("简单一局，快乐加倍！", color = TextSecondary)
    }
}

@Composable
private fun Mascot(text: String, color: Color) {
    Box(
        Modifier.size(82.dp).clip(CircleShape).background(color.copy(alpha = .17f))
            .border(4.dp, color, CircleShape),
        contentAlignment = Alignment.Center
    ) {
        Image(
            painter = painterResource(if (text == "O") R.drawable.mascot_o else R.drawable.mascot_x),
            contentDescription = if (text == "O") "O 吉祥物" else "X 吉祥物",
            modifier = Modifier.fillMaxSize().padding(2.dp),
            contentScale = ContentScale.Fit
        )
    }
}

@Composable
private fun OnboardingScreen(onStart: () -> Unit) {
    Column(
        Modifier.fillMaxSize().statusBarsPadding().padding(28.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Spacer(Modifier.height(28.dp))
        Text("三分钟，来一局", fontSize = 25.sp, fontWeight = FontWeight.Black)
        Spacer(Modifier.height(22.dp))
        DemoBoard()
        Spacer(Modifier.height(17.dp))
        Text("不复杂，但总有新乐趣 ❤", color = TextSecondary, fontSize = 14.sp)
        Spacer(Modifier.height(10.dp))
        Row(horizontalArrangement = Arrangement.spacedBy(18.dp), verticalAlignment = Alignment.CenterVertically) {
            Mascot("O", Coral)
            Mascot("X", Sky)
        }
        Spacer(Modifier.weight(1f))
        PrimaryButton("开始体验", onStart)
        Spacer(Modifier.height(14.dp))
    }
}

@Composable
private fun DemoBoard() {
    val marks = listOf("O", "", "X", "", "O", "", "X", "", "O")
    Column(Modifier.size(168.dp).border(2.dp, Ink, RoundedCornerShape(5.dp))) {
        repeat(3) { row ->
            Row(Modifier.weight(1f)) {
                repeat(3) { col ->
                    val value = marks[row * 3 + col]
                    Box(
                        Modifier.weight(1f).fillMaxHeight()
                            .border(1.5.dp, Ink.copy(alpha = .7f)),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(value, color = if (value == "O") Coral else Sky, fontSize = 37.sp, fontWeight = FontWeight.Black)
                    }
                }
            }
        }
    }
}

@Composable
private fun HomeScreen(openMode: () -> Unit, local: () -> Unit, room: () -> Unit, daily: () -> Unit) {
    LazyColumn(
        Modifier.fillMaxSize().statusBarsPadding().testTag("home_screen"),
        contentPadding = PaddingValues(horizontal = 18.dp, vertical = 14.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp)
    ) {
        item { ProfileHeader() }
        item {
            Text("今天想怎么玩？", fontSize = 21.sp, fontWeight = FontWeight.Black)
            Text("选择一种模式，马上开局", color = TextSecondary, fontSize = 13.sp)
        }
        item {
            Row(horizontalArrangement = Arrangement.spacedBy(14.dp)) {
                SmallModeCard("ϟ", "快速对战", "智能 AI", Sunny, Modifier.weight(1f), openMode)
                SmallModeCard("♙", "双人同屏", "面对面一局", Sky, Modifier.weight(1f), local)
            }
        }
        item {
            Row(horizontalArrangement = Arrangement.spacedBy(14.dp)) {
                SmallModeCard("♧", "好友房间", "网络 / 蓝牙", Coral, Modifier.weight(1f), room)
                SmallModeCard("♛", "每日挑战", "每题唯一解", Teal, Modifier.weight(1f), daily)
            }
        }
    }
}

@Composable
private fun ProfileHeader() {
    Row(verticalAlignment = Alignment.CenterVertically) {
        Box(Modifier.size(45.dp).clip(CircleShape).background(Sky.copy(.25f)), contentAlignment = Alignment.Center) {
            Image(painterResource(R.drawable.avatar_kangsi), "康思头像", Modifier.fillMaxSize().padding(2.dp), contentScale = ContentScale.Crop)
        }
        Spacer(Modifier.width(8.dp))
        Column(Modifier.weight(1f)) {
            Text("康思", fontSize = 16.sp, fontWeight = FontWeight.Bold)
            Text("120", color = Color(0xFFE5A900), fontSize = 13.sp)
        }
        Icon(Icons.Rounded.Settings, null, Modifier.size(22.dp))
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
        Row(Modifier.padding(17.dp), verticalAlignment = Alignment.CenterVertically) {
            Text(icon, fontSize = 31.sp)
            Spacer(Modifier.width(14.dp))
            Column(Modifier.weight(1f)) {
                Text(title, fontSize = 19.sp, fontWeight = FontWeight.Black)
                Text(subtitle, color = TextSecondary, fontSize = 13.sp)
            }
            Icon(Icons.Rounded.ChevronRight, null)
        }
    }
}

@Composable
private fun SmallModeCard(icon: String, title: String, subtitle: String, color: Color, modifier: Modifier, onClick: () -> Unit) {
    Card(
        onClick = onClick,
        modifier = modifier.height(114.dp).border(2.dp, color.copy(.7f), RoundedCornerShape(18.dp)),
        colors = CardDefaults.cardColors(containerColor = color.copy(.22f)),
        shape = RoundedCornerShape(18.dp)
    ) {
        Column(Modifier.fillMaxSize().padding(13.dp), verticalArrangement = Arrangement.SpaceBetween) {
            Text(icon, fontSize = 24.sp)
            Text(title, fontSize = 15.sp, fontWeight = FontWeight.Black)
            Text(subtitle, fontSize = 11.sp, color = TextSecondary)
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
    Column(Modifier.fillMaxSize().statusBarsPadding().padding(18.dp).testTag("mode_screen")) {
        PageTitle("选择模式", back)
        Spacer(Modifier.height(13.dp))
        ModeOption("▦", "经典 3×3", "和 AI 对战 · 三子连线获胜", GameKind.AI_3X3, selected) { selected = it }
        Spacer(Modifier.height(9.dp))
        ModeOption("▦", "进阶 5×5", "四子连线，更大的挑战", GameKind.AI_5X5, selected) { selected = it }
        Spacer(Modifier.height(9.dp))
        ModeOption("◫", "逻辑 OOXX 6×6", "等量、不三连、行列不重复", GameKind.LOGIC_6X6, selected) { selected = it }
        Spacer(Modifier.height(9.dp))
        ModeOption("⏱", "每日唯一解", "每天一题，全网相同", GameKind.DAILY, selected) { selected = it }
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
        colors = CardDefaults.cardColors(containerColor = if (active) Sky.copy(.17f) else CardSurface),
        modifier = Modifier.fillMaxWidth().border(if (active) 3.dp else 1.dp, if (active) Sky else Ink.copy(.25f), RoundedCornerShape(18.dp))
    ) {
        Row(Modifier.padding(13.dp), verticalAlignment = Alignment.CenterVertically) {
            Text(icon, fontSize = 26.sp, color = Sky)
            Column(Modifier.padding(horizontal = 12.dp).weight(1f)) {
                Text(title, fontSize = 17.sp, fontWeight = FontWeight.Bold)
                Text(subtitle, fontSize = 11.sp, color = TextSecondary)
            }
            Icon(Icons.Rounded.ChevronRight, contentDescription = "选择$title", tint = Ink.copy(alpha = .7f))
        }
    }
}

@Composable
private fun RoomScreen(
    network: NetworkRoom,
    back: () -> Unit,
    onCreate: () -> Unit,
    onJoin: (String) -> Unit,
    onBluetoothHost: () -> Unit,
    onBluetoothJoin: (BluetoothDevice) -> Unit,
    bluetoothAvailable: Boolean,
    onBluetoothDevices: () -> List<BluetoothDevice>,
    onBluetoothStatus: (String) -> Unit
) {
    val context = LocalContext.current
    var tab by remember { mutableIntStateOf(0) }
    var roomCode by remember { mutableStateOf("") }
    var status by remember { mutableStateOf("选择连接方式") }
    var paired by remember { mutableStateOf<List<BluetoothDevice>>(emptyList()) }
    var busy by remember { mutableStateOf(false) }
    val launcher = rememberLauncherForActivityResult(ActivityResultContracts.RequestMultiplePermissions()) { grants ->
        if (grants.values.all { it }) {
            paired = runCatching { onBluetoothDevices() }.getOrDefault(emptyList())
            status = if (paired.isEmpty()) "没有已配对设备，请先在系统设置中配对" else "请选择已配对设备，或让好友连你"
            onBluetoothStatus(status)
        } else {
            status = "需要蓝牙权限才能发现和连接设备"
            onBluetoothStatus(status)
        }
    }

    // 监听/连接失败后把主机按钮恢复可用，避免一直卡在「等待连接中」
    LaunchedEffect(network.statusMessage) {
        val message = network.statusMessage
        if (message.contains("失败") || message.contains("断开") || message.contains("不支持")) busy = false
    }

    fun requireBluetoothPermissions(): Boolean {
        val permissions = if (Build.VERSION.SDK_INT >= 31) {
            arrayOf(Manifest.permission.BLUETOOTH_SCAN, Manifest.permission.BLUETOOTH_CONNECT)
        } else {
            arrayOf(Manifest.permission.ACCESS_COARSE_LOCATION, Manifest.permission.ACCESS_FINE_LOCATION)
        }
        return if (permissions.all { ContextCompat.checkSelfPermission(context, it) == PackageManager.PERMISSION_GRANTED }) {
            true
        } else {
            launcher.launch(permissions)
            false
        }
    }

    LazyColumn(
        Modifier.fillMaxSize().statusBarsPadding(),
        contentPadding = PaddingValues(20.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        item { PageTitle("好友房间", back) }
        item {
            Row(
                Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.Center,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Image(
                    painterResource(R.drawable.avatar_kangsi),
                    "康思",
                    Modifier.size(58.dp).clip(CircleShape),
                    contentScale = ContentScale.Crop
                )
                Text("  ×  ", color = Ink.copy(alpha = .55f), fontSize = 20.sp, fontWeight = FontWeight.Bold)
                Image(
                    painterResource(R.drawable.avatar_xiaoming),
                    "好友",
                    Modifier.size(58.dp).clip(CircleShape),
                    contentScale = ContentScale.Crop
                )
            }
        }
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
                PrimaryButton("创建房间") { onCreate() }
            }
            item {
                SecondaryButton("加入房间") {
                    if (roomCode.length == 6) onJoin(roomCode) else status = "请输入正确的 6 位房间码"
                }
            }
            if (network.roomCode.isNotEmpty() && network.waiting) {
                item {
                    Text(
                        "房间码 ${network.roomCode}",
                        Modifier.fillMaxWidth().background(SoftGray, RoundedCornerShape(14.dp)).padding(vertical = 14.dp),
                        textAlign = TextAlign.Center,
                        fontSize = 24.sp,
                        fontWeight = FontWeight.Black,
                        color = Ink
                    )
                }
            }
            if (network.connecting) {
                item { CircularProgressIndicator(Modifier.padding(vertical = 4.dp)) }
            }
        } else {
            item {
                InfoStrip(if (bluetoothAvailable) "两机近距离离线对战：一台当主机，另一台连接" else "此设备不支持蓝牙")
            }
            item {
                PrimaryButton(if (busy) "等待连接中…" else "作为主机等待好友连接") {
                    if (!bluetoothAvailable || busy) return@PrimaryButton
                    if (!requireBluetoothPermissions()) return@PrimaryButton
                    busy = true
                    status = "正在等待好友连接…"
                    onBluetoothHost()
                }
            }
            item {
                SecondaryButton("刷新已配对设备") {
                    if (!requireBluetoothPermissions()) return@SecondaryButton
                    paired = runCatching { onBluetoothDevices() }.getOrDefault(emptyList())
                    status = if (paired.isEmpty()) "没有已配对设备，请先在系统设置中配对" else "点击设备连接对方（对方需先点「作为主机等待」）"
                }
            }
            items(paired, key = { it.address }) { device ->
                Card(
                    onClick = {
                        if (!requireBluetoothPermissions()) return@Card
                        status = "正在通过蓝牙连接 ${device.name ?: device.address}…"
                        onBluetoothJoin(device)
                    },
                    colors = CardDefaults.cardColors(containerColor = CardSurface),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Row(Modifier.padding(16.dp), verticalAlignment = Alignment.CenterVertically) {
                        Icon(Icons.Rounded.Bluetooth, null, tint = Teal)
                        Text(device.name ?: device.address, Modifier.padding(start = 12.dp).weight(1f), fontWeight = FontWeight.Bold)
                        Icon(Icons.Rounded.ChevronRight, null)
                    }
                }
            }
        }
        item { InfoStrip(if (tab == 0) network.error ?: network.statusMessage else status) }
    }
}

@Composable
private fun ConnectionTab(text: String, icon: ImageVector, selected: Boolean, modifier: Modifier, onClick: () -> Unit) {
    Row(
        modifier.clip(RoundedCornerShape(12.dp)).background(if (selected) CardSurface else Color.Transparent)
            .clickable(onClick = onClick).padding(12.dp),
        horizontalArrangement = Arrangement.Center,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(icon, null, Modifier.size(20.dp), tint = if (selected) Coral else TextSecondary)
        Text(text, Modifier.padding(start = 6.dp), fontWeight = if (selected) FontWeight.Bold else FontWeight.Normal)
    }
}

@Composable
private fun GameScreen(session: GameSession, play: (Move) -> Unit, undo: () -> Unit, reset: () -> Unit, surrender: () -> Unit) {
    Column(
        Modifier.fillMaxSize().statusBarsPadding().padding(horizontal = 18.dp).testTag("game_screen"),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        if (session.kind == GameKind.LOGIC_6X6) {
            Text("逻辑 OOXX", Modifier.fillMaxWidth().padding(top = 18.dp), fontSize = 24.sp, fontWeight = FontWeight.Black, textAlign = TextAlign.Center)
            Text("6×6 经典谜题", color = TextSecondary, fontSize = 13.sp)
        } else {
            Row(Modifier.fillMaxWidth().padding(vertical = 12.dp), verticalAlignment = Alignment.CenterVertically) {
                val myTurn = session.turn == session.playerMark
                PlayerBadge(
                    R.drawable.avatar_kangsi,
                    if (session.kind == GameKind.NETWORK || session.kind == GameKind.BLUETOOTH) "你" else "康思",
                    if (myTurn) Coral else TextSecondary
                )
                Text("VS", Modifier.weight(1f), textAlign = TextAlign.Center, color = Sky, fontWeight = FontWeight.Black)
                PlayerBadge(
                    R.drawable.avatar_xiaoming,
                    when (session.kind) {
                        GameKind.LOCAL -> "小明"
                        GameKind.NETWORK -> session.opponentName ?: "在线玩家"
                        GameKind.BLUETOOTH -> session.opponentName ?: "蓝牙好友"
                        else -> "AI"
                    },
                    if (!myTurn) Sky else TextSecondary
                )
            }
        }
        Spacer(Modifier.height(8.dp))
        Text(session.message, Modifier.background(Sunny.copy(.35f), RoundedCornerShape(12.dp)).padding(horizontal = 18.dp, vertical = 7.dp), fontSize = 18.sp, fontWeight = FontWeight.Black)
        Spacer(Modifier.height(12.dp))
        if (session.kind == GameKind.LOGIC_6X6) {
            session.logicBoard?.let { LogicGameBoard(it, play) }
        } else {
            GameBoard(
                session.board,
                enabled = !session.isAiThinking && session.puzzleSolved == null &&
                    (session.turn == session.playerMark ||
                        (session.kind != GameKind.NETWORK && session.kind != GameKind.BLUETOOTH)),
                onMove = play
            )
        }
        Spacer(Modifier.height(12.dp))
        Text(
            when (session.kind) {
                GameKind.DAILY -> "本题已通过算法验证，存在且仅存在一个最优解"
                GameKind.AI_3X3 -> "经典 3×3 · 三子连线获胜"
                GameKind.AI_5X5 -> "进阶 5×5 · 四子连线获胜"
                GameKind.LOGIC_6X6 -> "每行每列 X/O 等量 · 不三连 · 行列不重复"
                GameKind.LOCAL -> "双人同屏 · 轮流落子"
                GameKind.NETWORK -> "网络对战 · 三子连线获胜"
                GameKind.BLUETOOTH -> "蓝牙对战 · 三子连线获胜"
            },
            color = TextSecondary,
            fontSize = 13.sp,
            textAlign = TextAlign.Center
        )
        // 原型中的操作区紧随棋盘，而不是吸附到系统底部。
        Spacer(Modifier.height(24.dp))
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            if (session.kind == GameKind.NETWORK || session.kind == GameKind.BLUETOOTH) {
                GameAction(Icons.Rounded.SportsEsports, "认输", Modifier.weight(1f), surrender)
            } else {
                GameAction(Icons.Rounded.Undo, "悔棋", Modifier.weight(1f), undo)
                if (session.kind == GameKind.LOGIC_6X6) {
                    GameAction(Icons.Rounded.Refresh, "重置", Modifier.weight(1f), reset)
                    GameAction(Icons.AutoMirrored.Rounded.ArrowBack, "放弃", Modifier.weight(1f), surrender)
                } else {
                    GameAction(Icons.Rounded.Casino, "表情", Modifier.weight(1f)) { }
                    GameAction(Icons.Rounded.SportsEsports, "认输", Modifier.weight(1f), surrender)
                }
            }
        }
        Spacer(Modifier.height(18.dp))
    }
}

@Composable
private fun LogicGameBoard(board: LogicBoard, onMove: (Move) -> Unit) {
    val invalid = remember(board.cells) { LogicPuzzleEngine.invalidCells(board) }
    val boardSize = 294.dp
    Column(Modifier.size(boardSize).border(3.dp, Ink, RoundedCornerShape(8.dp)).background(CardSurface)) {
        repeat(board.size) { row ->
            Row(Modifier.weight(1f)) {
                repeat(board.size) { col ->
                    val index = row * board.size + col
                    val mark = board[row, col]
                    val given = index in board.givens
                    val conflict = index in invalid
                    Box(
                        Modifier.weight(1f).fillMaxHeight()
                            .background(when {
                                conflict -> Coral.copy(alpha = .2f)
                                given -> SoftGray
                                else -> CardSurface
                            })
                            .border(if (conflict) 2.dp else 1.dp, if (conflict) Coral else Ink.copy(.55f))
                            .clickable(enabled = !given) { onMove(Move(row, col)) },
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            when (mark) { Mark.X -> "X"; Mark.O -> "O"; Mark.EMPTY -> "" },
                            color = if (mark == Mark.X) Sky else Coral,
                            fontSize = 27.sp,
                            fontWeight = if (given) FontWeight.Black else FontWeight.Bold
                        )
                        if (given) Box(Modifier.align(Alignment.TopEnd).padding(4.dp).size(4.dp).clip(CircleShape).background(Ink.copy(.45f)))
                    }
                }
            }
        }
    }
}

@Composable
private fun PlayerBadge(avatarRes: Int, name: String, color: Color) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Box(Modifier.size(34.dp).border(2.dp, color, CircleShape), contentAlignment = Alignment.Center) {
            Image(painterResource(avatarRes), "$name 头像", Modifier.fillMaxSize().clip(CircleShape).padding(2.dp), contentScale = ContentScale.Crop)
        }
        Text(name, fontSize = 11.sp, fontWeight = FontWeight.Bold)
    }
}

@Composable
private fun GameBoard(board: Board, enabled: Boolean, onMove: (Move) -> Unit) {
    val boardSize = if (board.size == 3) 250.dp else 282.dp
    Column(Modifier.size(boardSize).border(3.dp, Ink, RoundedCornerShape(8.dp)).background(CardSurface)) {
        repeat(board.size) { row ->
            Row(Modifier.weight(1f)) {
                repeat(board.size) { col ->
                    val mark = board[row, col]
                    Box(
                        Modifier.weight(1f).fillMaxHeight().border(1.dp, Ink.copy(.62f))
                            .testTag("board_${row}_${col}")
                            .clickable(enabled = enabled && mark == Mark.EMPTY) { onMove(Move(row, col)) },
                        contentAlignment = Alignment.Center
                    ) {
                        val text = when (mark) { Mark.X -> "X"; Mark.O -> "O"; else -> "" }
                        Text(text, color = if (mark == Mark.X) Sky else Coral, fontSize = if (board.size == 3) 43.sp else 30.sp, fontWeight = FontWeight.Black)
                    }
                }
            }
        }
    }
}

@Composable
private fun GameAction(icon: ImageVector, text: String, modifier: Modifier, action: () -> Unit) {
    OutlinedButton(onClick = action, modifier = modifier.height(55.dp), shape = RoundedCornerShape(12.dp), contentPadding = PaddingValues(5.dp)) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Icon(icon, null, Modifier.size(24.dp))
            Text(text, fontSize = 12.sp)
        }
    }
}

@Composable
private fun ResultScreen(result: MatchResult, session: GameSession, replay: () -> Unit, home: () -> Unit) {
    val (title, color) = when (result) {
        MatchResult.WIN -> "你赢了！" to Sunny
        MatchResult.LOSS -> "再接再厉" to Sky
        MatchResult.DRAW -> "平局！" to Teal
    }
    Column(
        Modifier.fillMaxSize().statusBarsPadding().padding(24.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Text(title, fontSize = 31.sp, fontWeight = FontWeight.Black)
        Spacer(Modifier.height(12.dp))
        Box(Modifier.size(110.dp).clip(CircleShape).background(color.copy(.28f)), contentAlignment = Alignment.Center) {
            Image(
                painterResource(if (result == MatchResult.WIN) R.drawable.mascot_victory else R.drawable.mascot_o),
                "对局结果插图",
                Modifier.fillMaxSize().padding(6.dp),
                contentScale = ContentScale.Fit
            )
        }
        Spacer(Modifier.height(16.dp))
        Card(colors = CardDefaults.cardColors(containerColor = CardSurface), modifier = Modifier.fillMaxWidth()) {
            Row(Modifier.fillMaxWidth().padding(14.dp), horizontalArrangement = Arrangement.SpaceEvenly) {
                Stat("本局用时", "${(session.moves * 7 + 12).coerceAtLeast(18)}秒")
                Stat("步数", session.moves.toString())
                Stat("模式", when (session.kind) {
                    GameKind.LOGIC_6X6 -> "逻辑 6×6"
                    GameKind.AI_5X5 -> "5×5"
                    else -> "3×3"
                })
            }
        }
        Spacer(Modifier.height(20.dp))
        PrimaryButton("再来一局", replay)
        Spacer(Modifier.height(12.dp))
        SecondaryButton("返回首页", home)
    }
}

@Composable
private fun Stat(label: String, value: String) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Text(label, color = TextSecondary, fontSize = 12.sp)
        Text(value, fontWeight = FontWeight.Black, fontSize = 18.sp)
    }
}

internal enum class HistoryFilter(val label: String, val result: MatchResult?) {
    ALL("全部", null),
    WIN("胜利", MatchResult.WIN),
    LOSS("失败", MatchResult.LOSS),
    DRAW("平局", MatchResult.DRAW)
}

internal fun filterMatchRecords(records: List<MatchRecord>, filter: HistoryFilter): List<MatchRecord> =
    filter.result?.let { result -> records.filter { it.result == result } } ?: records

@Composable
private fun HistoryScreen(records: List<MatchRecord>, ranking: List<RankingEntry>) {
    var selectedFilter by rememberSaveable { mutableStateOf(HistoryFilter.ALL) }
    val filteredRecords = filterMatchRecords(records, selectedFilter)
    val wins = records.count { it.result == MatchResult.WIN }
    val rate = if (records.isEmpty()) 0 else wins * 100 / records.size
    LazyColumn(
        Modifier.fillMaxSize().statusBarsPadding().testTag("history_screen"),
        contentPadding = PaddingValues(20.dp),
        verticalArrangement = Arrangement.spacedBy(14.dp)
    ) {
        item { Text("对战记录", fontSize = 23.sp, fontWeight = FontWeight.Black) }
        item {
            Card(colors = CardDefaults.cardColors(containerColor = CardSurface), modifier = Modifier.fillMaxWidth()) {
                Row(Modifier.padding(12.dp), verticalAlignment = Alignment.CenterVertically) {
                    Box(Modifier.size(58.dp).border(7.dp, Sky, CircleShape), contentAlignment = Alignment.Center) {
                        Text("$rate%", fontSize = 17.sp, fontWeight = FontWeight.Black)
                    }
                    Column(Modifier.padding(start = 12.dp).weight(1f)) {
                        Text("胜率", color = TextSecondary, fontSize = 12.sp)
                        Text("${records.size} 场 · $wins 胜", fontSize = 18.sp, fontWeight = FontWeight.Black)
                    }
                    Text("连胜 3 场", fontSize = 12.sp, color = Ink)
                }
            }
        }
        item {
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                HistoryFilter.entries.forEach { filter ->
                    val selected = filter == selectedFilter
                    Text(
                        filter.label,
                        Modifier
                            .selectable(
                                selected = selected,
                                role = Role.Tab,
                                onClick = { selectedFilter = filter }
                            )
                            .background(if (selected) Teal.copy(.22f) else SoftGray, RoundedCornerShape(12.dp))
                            .padding(horizontal = 10.dp, vertical = 5.dp),
                        fontSize = 11.sp,
                        color = if (selected) Teal else TextSecondary,
                        fontWeight = if (selected) FontWeight.Bold else FontWeight.Normal
                    )
                }
            }
        }
        if (filteredRecords.isEmpty()) {
            item {
                EmptyState(
                    if (records.isEmpty()) "还没有记录，先去完成一局吧"
                    else "暂无${selectedFilter.label}战绩"
                )
            }
        }
        items(filteredRecords.take(20)) { record -> RecordRow(record) }
    }
}

@Preview(showBackground = true)
@Composable
private fun HistoryScreenPreview() {
    OoxxTheme {
        HistoryScreen(
            records = listOf(
                MatchRecord(MatchResult.WIN, "在线对战", "圈圈达人", steps = 5),
                MatchRecord(MatchResult.LOSS, "本地双人", "好友", steps = 6),
                MatchRecord(MatchResult.DRAW, "在线对战", "叉叉队长", steps = 9)
            ),
            ranking = emptyList()
        )
    }
}

@Composable
private fun RankingRow(entry: RankingEntry) {
    Row(
        Modifier.fillMaxWidth().background(if (entry.isMe) Sky.copy(.16f) else CardSurface, RoundedCornerShape(14.dp)).padding(14.dp),
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
    Card(colors = CardDefaults.cardColors(containerColor = CardSurface), modifier = Modifier.fillMaxWidth()) {
        Row(Modifier.padding(15.dp), verticalAlignment = Alignment.CenterVertically) {
            Box(Modifier.size(42.dp).clip(CircleShape).background(color.copy(.18f)), contentAlignment = Alignment.Center) {
                Text(when (record.result) { MatchResult.WIN -> "胜"; MatchResult.LOSS -> "负"; MatchResult.DRAW -> "平" }, color = color, fontWeight = FontWeight.Black)
            }
            Column(Modifier.padding(start = 12.dp).weight(1f)) {
                Text(record.mode, fontWeight = FontWeight.Bold)
                Text("对手：${record.opponent} · ${record.steps} 步", fontSize = 12.sp, color = TextSecondary)
            }
            Text(formatter.format(Instant.ofEpochMilli(record.playedAt).atZone(ZoneId.systemDefault())), fontSize = 11.sp, color = TextSecondary)
        }
    }
}

@Composable
private fun ProfileScreen(
    settings: Settings,
    records: List<MatchRecord>,
    onSound: (Boolean) -> Unit,
    onVibration: (Boolean) -> Unit,
    onDarkMode: (Boolean) -> Unit
) {
    val wins = records.count { it.result == MatchResult.WIN }
    LazyColumn(
        Modifier.fillMaxSize().statusBarsPadding().testTag("profile_screen"),
        contentPadding = PaddingValues(20.dp),
        verticalArrangement = Arrangement.spacedBy(14.dp)
    ) {
        item { Text("我的", fontSize = 23.sp, fontWeight = FontWeight.Black) }
        item {
            Row(Modifier.fillMaxWidth().padding(vertical = 8.dp), verticalAlignment = Alignment.CenterVertically) {
                Box(Modifier.size(58.dp).clip(CircleShape).background(Sky.copy(.24f)), contentAlignment = Alignment.Center) {
                    Image(painterResource(R.drawable.avatar_kangsi), "康思头像", Modifier.fillMaxSize().padding(3.dp), contentScale = ContentScale.Crop)
                }
                Column(Modifier.padding(start = 16.dp).weight(1f)) {
                    Text("康思", fontSize = 19.sp, fontWeight = FontWeight.Black)
                    Text("小程序游客 ID · 免用户名密码", color = TextSecondary)
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
        item { SettingSwitch(Icons.Rounded.VolumeUp, "声音", settings.sound, onSound) }
        item { SettingSwitch(Icons.Rounded.Vibration, "震动", settings.vibration, onVibration) }
        item { SettingSwitch(Icons.Rounded.DarkMode, "深色模式", settings.darkMode, onDarkMode) }
        item { SettingLink(Icons.Rounded.Info, "关于我们", "OOXX Android 1.0") }
        item { InfoStrip("对战数据仅保存在本机") }
    }
}

@Composable
private fun Achievement(icon: String, value: String, label: String, modifier: Modifier) {
    Column(
        modifier.background(CardSurface, RoundedCornerShape(12.dp)).padding(horizontal = 7.dp, vertical = 10.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(icon, fontSize = 18.sp)
        Spacer(Modifier.height(3.dp))
        Text(value, fontWeight = FontWeight.Black, fontSize = 16.sp, maxLines = 1)
        Spacer(Modifier.height(2.dp))
        Text(label, color = TextSecondary, fontSize = 10.sp, maxLines = 1)
    }
}

@Composable
private fun SettingSwitch(icon: ImageVector, title: String, checked: Boolean, change: (Boolean) -> Unit) {
    Row(Modifier.fillMaxWidth().background(CardSurface, RoundedCornerShape(12.dp)).padding(horizontal = 12.dp, vertical = 4.dp), verticalAlignment = Alignment.CenterVertically) {
        Icon(icon, null, tint = TextSecondary)
        Text(title, Modifier.padding(start = 12.dp).weight(1f), fontWeight = FontWeight.Medium)
        Switch(checked, change)
    }
}

@Composable
private fun SettingLink(icon: ImageVector, title: String, detail: String) {
    Row(Modifier.fillMaxWidth().background(CardSurface, RoundedCornerShape(12.dp)).padding(12.dp), verticalAlignment = Alignment.CenterVertically) {
        Icon(icon, null, tint = TextSecondary)
        Text(title, Modifier.padding(start = 12.dp).weight(1f), fontWeight = FontWeight.Medium)
        Text(detail, color = TextSecondary, fontSize = 12.sp)
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
                label = { Text(label) },
                colors = NavigationBarItemDefaults.colors(
                    selectedIconColor = Coral,
                    selectedTextColor = Coral,
                    indicatorColor = Color.Transparent,
                    unselectedIconColor = Ink.copy(alpha = .62f),
                    unselectedTextColor = Ink.copy(alpha = .62f)
                )
            )
        }
    }
}

@Composable
private fun PageTitle(title: String, back: () -> Unit) {
    Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
        IconButton(back) { Icon(Icons.AutoMirrored.Rounded.ArrowBack, "返回") }
        Text(title, Modifier.weight(1f), textAlign = TextAlign.Center, fontSize = 22.sp, fontWeight = FontWeight.Black)
        Spacer(Modifier.size(48.dp))
    }
}

@Composable
private fun SectionTitle(text: String) { Text(text, fontSize = 18.sp, fontWeight = FontWeight.Black) }

@Composable
private fun EmptyState(text: String) {
    Text(text, Modifier.fillMaxWidth().padding(30.dp), textAlign = TextAlign.Center, color = TextSecondary)
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
