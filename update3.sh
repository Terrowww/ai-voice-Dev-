#!/data/data/com.termux/files/usr/bin/bash
# Запускать из ~/voicecall: bash update3.sh
set -e
D=app/src/main/java/com/example/voicecall

# иконки Material (Call, Person, Search и т.д.)
grep -q "material-icons-core" app/build.gradle.kts || \
  sed -i 's#implementation("androidx.compose.material3:material3")#&\n    implementation("androidx.compose.material:material-icons-core")#' app/build.gradle.kts

cat > $D/Icons.kt <<'EOF'
package com.example.voicecall

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.StrokeJoin
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp

@Composable
fun IconMic(color: Color, slash: Boolean = true, dp: Dp = 34.dp) {
    Canvas(Modifier.size(dp)) {
        val s = this.size.minDimension
        val w = s * 0.07f
        val st = Stroke(width = w, cap = StrokeCap.Round, join = StrokeJoin.Round)
        drawRoundRect(
            color, topLeft = Offset(s * 0.38f, s * 0.12f),
            size = Size(s * 0.24f, s * 0.44f), cornerRadius = CornerRadius(s * 0.12f), style = st
        )
        val p = Path().apply {
            moveTo(s * 0.26f, s * 0.46f)
            quadraticBezierTo(s * 0.26f, s * 0.72f, s * 0.5f, s * 0.72f)
            quadraticBezierTo(s * 0.74f, s * 0.72f, s * 0.74f, s * 0.46f)
        }
        drawPath(p, color, style = st)
        drawLine(color, Offset(s * 0.5f, s * 0.72f), Offset(s * 0.5f, s * 0.86f), strokeWidth = w, cap = StrokeCap.Round)
        drawLine(color, Offset(s * 0.38f, s * 0.86f), Offset(s * 0.62f, s * 0.86f), strokeWidth = w, cap = StrokeCap.Round)
        if (slash) {
            drawLine(color, Offset(s * 0.16f, s * 0.1f), Offset(s * 0.84f, s * 0.9f), strokeWidth = w, cap = StrokeCap.Round)
        }
    }
}

@Composable
fun IconBluetooth(color: Color, dp: Dp = 34.dp) {
    Canvas(Modifier.size(dp)) {
        val s = this.size.minDimension
        val st = Stroke(width = s * 0.07f, cap = StrokeCap.Round, join = StrokeJoin.Round)
        val p = Path().apply {
            moveTo(s * 0.28f, s * 0.32f)
            lineTo(s * 0.72f, s * 0.68f)
            lineTo(s * 0.5f, s * 0.88f)
            lineTo(s * 0.5f, s * 0.12f)
            lineTo(s * 0.72f, s * 0.32f)
            lineTo(s * 0.28f, s * 0.68f)
        }
        drawPath(p, color, style = st)
    }
}

@Composable
fun IconSpeaker(color: Color, dp: Dp = 34.dp) {
    Canvas(Modifier.size(dp)) {
        val s = this.size.minDimension
        val st = Stroke(width = s * 0.07f, cap = StrokeCap.Round, join = StrokeJoin.Round)
        val body = Path().apply {
            moveTo(s * 0.16f, s * 0.4f)
            lineTo(s * 0.32f, s * 0.4f)
            lineTo(s * 0.5f, s * 0.24f)
            lineTo(s * 0.5f, s * 0.76f)
            lineTo(s * 0.32f, s * 0.6f)
            lineTo(s * 0.16f, s * 0.6f)
            close()
        }
        drawPath(body, color, style = st)
        drawArc(
            color, startAngle = -45f, sweepAngle = 90f, useCenter = false,
            topLeft = Offset(s * 0.32f, s * 0.32f), size = Size(s * 0.36f, s * 0.36f), style = st
        )
        drawArc(
            color, startAngle = -45f, sweepAngle = 90f, useCenter = false,
            topLeft = Offset(s * 0.2f, s * 0.2f), size = Size(s * 0.6f, s * 0.6f), style = st
        )
    }
}

@Composable
fun IconKeypad(color: Color, dp: Dp = 34.dp) {
    Canvas(Modifier.size(dp)) {
        val s = this.size.minDimension
        val r = s * 0.055f
        val xs = listOf(0.3f, 0.5f, 0.7f)
        val ys = listOf(0.22f, 0.4f, 0.58f)
        for (y in ys) for (x in xs) drawCircle(color, r, Offset(s * x, s * y))
        drawCircle(color, r, Offset(s * 0.5f, s * 0.76f))
    }
}

@Composable
fun IconMore(color: Color, dp: Dp = 34.dp) {
    Canvas(Modifier.size(dp)) {
        val s = this.size.minDimension
        val r = s * 0.07f
        for (y in listOf(0.25f, 0.5f, 0.75f)) drawCircle(color, r, Offset(s * 0.5f, s * y))
    }
}

@Composable
fun IconVoicemail(color: Color, dp: Dp = 34.dp) {
    Canvas(Modifier.size(dp)) {
        val s = this.size.minDimension
        val st = Stroke(width = s * 0.07f, cap = StrokeCap.Round, join = StrokeJoin.Round)
        drawRoundRect(
            color, topLeft = Offset(s * 0.12f, s * 0.28f),
            size = Size(s * 0.76f, s * 0.44f), cornerRadius = CornerRadius(s * 0.12f), style = st
        )
        drawCircle(color, s * 0.07f, Offset(s * 0.34f, s * 0.5f), style = st)
        drawCircle(color, s * 0.07f, Offset(s * 0.66f, s * 0.5f), style = st)
    }
}
EOF

cat > $D/MainActivity.kt <<'EOF'
package com.example.voicecall

import android.app.Activity
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.SystemBarStyle
import androidx.activity.compose.BackHandler
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.runtime.*
import androidx.compose.ui.platform.LocalView
import androidx.core.view.WindowCompat

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge(
            statusBarStyle = SystemBarStyle.dark(android.graphics.Color.TRANSPARENT),
            navigationBarStyle = SystemBarStyle.dark(android.graphics.Color.TRANSPARENT)
        )
        setContent { AppRoot() }
    }
}

sealed class Screen {
    data object Main : Screen()
    data object Voice : Screen()
    data class Call(val name: String, val number: String) : Screen()
}

class VoiceState {
    val engine = AudioEngine()
    var voiceOn by mutableStateOf(false)
    var preset by mutableFloatStateOf(0.84f)
    var listening by mutableStateOf(false)
    var latency by mutableIntStateOf(0)
    fun apply() { engine.ratio = if (voiceOn) preset else 1f }
}

@Composable
fun AppRoot() {
    val vs = remember { VoiceState() }
    var screen by remember { mutableStateOf<Screen>(Screen.Main) }
    val view = LocalView.current
    val inCall = screen is Screen.Call

    SideEffect {
        val window = (view.context as Activity).window
        val c = WindowCompat.getInsetsController(window, view)
        c.isAppearanceLightStatusBars = !inCall
        c.isAppearanceLightNavigationBars = !inCall
    }
    DisposableEffect(Unit) { onDispose { vs.engine.stop() } }
    BackHandler(enabled = screen !is Screen.Main) { screen = Screen.Main }

    when (val s = screen) {
        is Screen.Main -> PhoneScreen(
            onCall = { n, num -> screen = Screen.Call(n, num) },
            onVoice = { screen = Screen.Voice }
        )
        is Screen.Voice -> VoiceSettingsScreen(vs) { screen = Screen.Main }
        is Screen.Call -> CallScreen(s.name, s.number, vs) { screen = Screen.Main }
    }
}
EOF

cat > $D/PhoneScreen.kt <<'EOF'
package com.example.voicecall

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Call
import androidx.compose.material.icons.filled.List
import androidx.compose.material.icons.filled.MoreVert
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

data class LogItem(
    val name: String, val number: String, val time: String,
    val outgoing: Boolean, val count: Int = 1
)
data class LogGroup(val date: String, val items: List<LogItem>)

// Демо-данные. Настоящие контакты добавим вместе со звонками между телефонами.
val demoContacts = listOf(
    "Второй телефон" to "+7 000 000 00 01",
    "Контакт 2" to "+7 000 000 00 02",
    "Контакт 3" to "+7 000 000 00 03"
)
val demoLog = listOf(
    LogGroup("сегодня", listOf(
        LogItem("Второй телефон", "+7 000 000 00 01", "10:46", true)
    )),
    LogGroup("вчера", listOf(
        LogItem("Второй телефон", "+7 000 000 00 01", "20:26", true, 3),
        LogItem("Контакт 2", "+7 000 000 00 02", "11:25", false, 2)
    )),
    LogGroup("пятница", listOf(
        LogItem("Контакт 3", "+7 000 000 00 03", "21:02", false),
        LogItem("Контакт 2", "+7 000 000 00 02", "21:01", true)
    ))
)

private val Gray = Color(0xFF6B6B75)
private val CardBg = Color(0xFFFAFAFD)
private val Green = Color(0xFF1FA463)

@Composable
fun PhoneScreen(onCall: (String, String) -> Unit, onVoice: () -> Unit) {
    var tab by rememberSaveable { mutableStateOf(1) }
    var menu by remember { mutableStateOf(false) }

    Box(Modifier.fillMaxSize().background(Color(0xFFF1F1F6))) {
        Column(Modifier.fillMaxSize().statusBarsPadding()) {
            Spacer(Modifier.height(80.dp))
            Text(
                "Телефон", Modifier.fillMaxWidth(), textAlign = TextAlign.Center,
                fontSize = 34.sp, fontWeight = FontWeight.Medium, color = Color.Black
            )
            Spacer(Modifier.height(40.dp))
            Row(
                Modifier.fillMaxWidth().padding(horizontal = 16.dp),
                horizontalArrangement = Arrangement.End
            ) {
                IconButton(onClick = {}) { Icon(Icons.Default.List, null, tint = Color.Black) }
                IconButton(onClick = {}) { Icon(Icons.Default.Search, null, tint = Color.Black) }
                Box {
                    IconButton(onClick = { menu = true }) {
                        Icon(Icons.Default.MoreVert, null, tint = Color.Black)
                    }
                    DropdownMenu(expanded = menu, onDismissRequest = { menu = false }) {
                        DropdownMenuItem(
                            text = { Text("Настройки голоса") },
                            onClick = { menu = false; onVoice() }
                        )
                    }
                }
            }
            Box(Modifier.weight(1f)) {
                when (tab) {
                    0 -> DialTab(onCall)
                    1 -> LogTab(onCall)
                    else -> ContactsTab(onCall)
                }
            }
        }
        BottomBar(
            tab, { tab = it },
            Modifier.align(Alignment.BottomCenter).navigationBarsPadding().padding(bottom = 12.dp)
        )
    }
}

@Composable
fun LogTab(onCall: (String, String) -> Unit) {
    LazyColumn(contentPadding = PaddingValues(start = 12.dp, end = 12.dp, bottom = 130.dp)) {
        demoLog.forEach { g ->
            item {
                Text(
                    g.date, Modifier.padding(start = 12.dp, top = 16.dp, bottom = 8.dp),
                    color = Gray, fontSize = 15.sp, fontWeight = FontWeight.Medium
                )
                Surface(shape = RoundedCornerShape(28.dp), color = CardBg) {
                    Column {
                        g.items.forEachIndexed { i, e ->
                            Row(
                                Modifier.fillMaxWidth().clickable { onCall(e.name, e.number) }
                                    .padding(horizontal = 20.dp, vertical = 20.dp),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Text(
                                    if (e.outgoing) "↗" else "↙",
                                    color = if (e.outgoing) Green else Gray, fontSize = 22.sp
                                )
                                Spacer(Modifier.width(16.dp))
                                Text(
                                    e.name + if (e.count > 1) " (${e.count})" else "",
                                    Modifier.weight(1f), fontSize = 24.sp, color = Color.Black
                                )
                                Text(e.time, color = Gray, fontSize = 16.sp)
                            }
                            if (i < g.items.size - 1) {
                                HorizontalDivider(Modifier.padding(horizontal = 20.dp), color = Color(0x14000000))
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun ContactsTab(onCall: (String, String) -> Unit) {
    LazyColumn(contentPadding = PaddingValues(start = 12.dp, end = 12.dp, top = 8.dp, bottom = 130.dp)) {
        item {
            Surface(shape = RoundedCornerShape(28.dp), color = CardBg) {
                Column {
                    demoContacts.forEachIndexed { i, c ->
                        Row(
                            Modifier.fillMaxWidth().clickable { onCall(c.first, c.second) }
                                .padding(horizontal = 20.dp, vertical = 20.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text(c.first, Modifier.weight(1f), fontSize = 24.sp, color = Color.Black)
                            Text(c.second, color = Gray, fontSize = 15.sp)
                        }
                        if (i < demoContacts.size - 1) {
                            HorizontalDivider(Modifier.padding(horizontal = 20.dp), color = Color(0x14000000))
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun DialTab(onCall: (String, String) -> Unit) {
    var num by remember { mutableStateOf("") }
    Column(
        Modifier.fillMaxSize().padding(bottom = 110.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Text(num.ifEmpty { " " }, fontSize = 34.sp, color = Color.Black)
        Spacer(Modifier.height(16.dp))
        listOf(
            listOf("1", "2", "3"), listOf("4", "5", "6"),
            listOf("7", "8", "9"), listOf("*", "0", "#")
        ).forEach { r ->
            Row(horizontalArrangement = Arrangement.spacedBy(20.dp)) {
                r.forEach { k ->
                    Box(
                        Modifier.size(64.dp).clip(CircleShape).background(CardBg)
                            .clickable { num += k },
                        contentAlignment = Alignment.Center
                    ) { Text(k, fontSize = 26.sp, color = Color.Black) }
                }
            }
            Spacer(Modifier.height(14.dp))
        }
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(20.dp)) {
            Spacer(Modifier.size(64.dp))
            Box(
                Modifier.size(64.dp).clip(CircleShape).background(Green).clickable {
                    if (num.isNotEmpty()) {
                        val digits = num.filter { it.isDigit() }
                        val c = demoContacts.firstOrNull { it.second.filter { ch -> ch.isDigit() } == digits }
                        onCall(c?.first ?: num, c?.second ?: num)
                    }
                },
                contentAlignment = Alignment.Center
            ) { Icon(Icons.Default.Call, null, tint = Color.White) }
            Box(
                Modifier.size(64.dp).clip(CircleShape).clickable { num = num.dropLast(1) },
                contentAlignment = Alignment.Center
            ) { Text("⌫", fontSize = 24.sp, color = Color.Black) }
        }
    }
}

@Composable
fun BottomBar(tab: Int, onTab: (Int) -> Unit, modifier: Modifier) {
    Surface(modifier, shape = RoundedCornerShape(40.dp), color = Color(0xFFF7F7FA), shadowElevation = 6.dp) {
        Row(Modifier.padding(6.dp)) {
            listOf("Набор", "Последние", "Контакты").forEachIndexed { i, label ->
                Column(
                    Modifier.clip(RoundedCornerShape(34.dp))
                        .background(if (tab == i) Color(0xFFDDDDE2) else Color.Transparent)
                        .clickable { onTab(i) }
                        .padding(horizontal = 20.dp, vertical = 10.dp),
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    when (i) {
                        0 -> IconKeypad(Color.Black, 28.dp)
                        1 -> Icon(Icons.Default.Call, null, tint = Color.Black, modifier = Modifier.size(28.dp))
                        else -> Icon(Icons.Default.Person, null, tint = Color.Black, modifier = Modifier.size(28.dp))
                    }
                    Text(
                        label, fontSize = 14.sp, color = Color.Black,
                        fontWeight = if (tab == i) FontWeight.Bold else FontWeight.Normal
                    )
                }
            }
        }
    }
}
EOF

cat > $D/CallScreen.kt <<'EOF'
package com.example.voicecall

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Call
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.delay

@Composable
fun CallScreen(name: String, number: String, vs: VoiceState, onEnd: () -> Unit) {
    var connected by remember { mutableStateOf(false) }
    var seconds by remember { mutableIntStateOf(0) }
    var muted by remember { mutableStateOf(false) }
    var speaker by remember { mutableStateOf(false) }

    LaunchedEffect(Unit) {
        delay(2000)
        connected = true
        while (true) { delay(1000); seconds++ }
    }
    val time = "%02d:%02d".format(seconds / 60, seconds % 60)

    Box(
        Modifier.fillMaxSize().background(
            Brush.verticalGradient(listOf(Color(0xFF0B0B14), Color(0xFF3A1A30), Color(0xFF7A7F9A)))
        )
    ) {
        Column(
            Modifier.fillMaxSize().statusBarsPadding().navigationBarsPadding().padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Spacer(Modifier.height(40.dp))
            Text(
                if (connected) "HD  $time" else "Вызов...",
                color = Color.White, fontSize = 22.sp
            )
            Spacer(Modifier.height(80.dp))
            Text(name, color = Color.White, fontSize = 44.sp, fontWeight = FontWeight.Medium)
            Text("Мобильный телефон  $number", color = Color.White, fontSize = 18.sp)
            Spacer(Modifier.weight(1f))

            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceEvenly) {
                CallButton(if (connected) time else "Записать", connected, onClick = {}) {
                    IconVoicemail(if (connected) Color(0xFF1FA463) else Color.White)
                }
                CallButton("Выключить\nмикрофон", muted, onClick = {
                    muted = !muted
                    vs.engine.muted = muted
                }) { IconMic(if (muted) Color.Black else Color.White) }
                CallButton("Bluetooth", false, onClick = {}) { IconBluetooth(Color.White) }
            }
            Spacer(Modifier.height(20.dp))
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceEvenly) {
                CallButton("Динамик", speaker, onClick = { speaker = !speaker }) {
                    IconSpeaker(if (speaker) Color.Black else Color.White)
                }
                CallButton("Клавиатура", false, onClick = {}) { IconKeypad(Color.White) }
                CallButton("Еще", false, onClick = {}) { IconMore(Color.White) }
            }

            Spacer(Modifier.height(32.dp))
            Box(
                Modifier.size(80.dp).clip(CircleShape).background(Color(0xFFDB3A34)).clickable { onEnd() },
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    Icons.Default.Call, null, tint = Color.White,
                    modifier = Modifier.size(34.dp).rotate(135f)
                )
            }
            Spacer(Modifier.height(24.dp))
        }
    }
}

@Composable
fun CallButton(label: String, active: Boolean, onClick: () -> Unit, icon: @Composable () -> Unit) {
    Column(Modifier.width(100.dp), horizontalAlignment = Alignment.CenterHorizontally) {
        Box(
            Modifier.size(72.dp).clip(RoundedCornerShape(26.dp))
                .background(if (active) Color(0xFFE4E4EA) else Color(0x44FFFFFF))
                .clickable { onClick() },
            contentAlignment = Alignment.Center
        ) { icon() }
        Spacer(Modifier.height(6.dp))
        Text(label, color = Color.White, fontSize = 13.sp, textAlign = TextAlign.Center)
    }
}
EOF

cat > $D/VoiceSettingsScreen.kt <<'EOF'
package com.example.voicecall

import android.Manifest
import android.content.pm.PackageManager
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.delay

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun VoiceSettingsScreen(vs: VoiceState, onBack: () -> Unit) {
    val context = LocalContext.current
    val launcher = rememberLauncherForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { ok ->
        if (ok) { vs.engine.start(); vs.listening = true }
    }

    fun toggleListen(on: Boolean) {
        if (!on) { vs.engine.stop(); vs.listening = false; return }
        val granted = context.checkSelfPermission(Manifest.permission.RECORD_AUDIO) ==
            PackageManager.PERMISSION_GRANTED
        if (granted) { vs.engine.start(); vs.listening = true }
        else launcher.launch(Manifest.permission.RECORD_AUDIO)
    }

    LaunchedEffect(vs.listening) {
        if (vs.listening) { delay(400); vs.latency = vs.engine.latencyMs }
    }
    DisposableEffect(Unit) {
        onDispose {
            if (vs.listening) { vs.engine.stop(); vs.listening = false }
        }
    }

    Column(
        Modifier.fillMaxSize().background(Color(0xFFF1F1F6))
            .statusBarsPadding().navigationBarsPadding()
    ) {
        Row(Modifier.padding(8.dp), verticalAlignment = Alignment.CenterVertically) {
            IconButton(onClick = onBack) { Icon(Icons.Default.ArrowBack, "Назад", tint = Color.Black) }
            Text("Настройки голоса", fontSize = 22.sp, fontWeight = FontWeight.Medium, color = Color.Black)
        }
        Column(Modifier.padding(16.dp)) {
            Surface(shape = RoundedCornerShape(28.dp), color = Color(0xFFFAFAFD)) {
                Column(Modifier.padding(20.dp)) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text("Смена голоса", Modifier.weight(1f), fontSize = 18.sp, color = Color.Black)
                        Switch(
                            checked = vs.voiceOn,
                            onCheckedChange = { vs.voiceOn = it; vs.apply() }
                        )
                    }
                    Spacer(Modifier.height(16.dp))
                    Text("Голос", fontSize = 14.sp, color = Color(0xFF6B6B75))
                    Spacer(Modifier.height(8.dp))
                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        listOf("Низкий" to 0.84f, "Ниже" to 0.75f, "Выше" to 1.15f).forEach { (n, v) ->
                            FilterChip(
                                selected = vs.preset == v,
                                onClick = { vs.preset = v; vs.apply() },
                                label = { Text(n) }
                            )
                        }
                    }
                }
            }
            Spacer(Modifier.height(16.dp))
            Surface(shape = RoundedCornerShape(28.dp), color = Color(0xFFFAFAFD)) {
                Column(Modifier.padding(20.dp)) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text("Слушать себя (тест)", Modifier.weight(1f), fontSize = 18.sp, color = Color.Black)
                        Switch(checked = vs.listening, onCheckedChange = { toggleListen(it) })
                    }
                    Spacer(Modifier.height(8.dp))
                    Text(
                        if (vs.listening) "Задержка: ≈ ${vs.latency} мс (оценка)"
                        else "Включи и надень наушники, иначе будет свист",
                        color = Color(0xFF6B6B75), fontSize = 14.sp
                    )
                }
            }
            Spacer(Modifier.height(16.dp))
            Text(
                "Голос меняется на твоём телефоне. Собеседник слышит уже изменённый голос, ты его обычный.",
                color = Color(0xFF6B6B75), fontSize = 14.sp
            )
        }
    }
}
EOF

echo "Готово. Дальше: git add . && git commit -m step3 && git push"
