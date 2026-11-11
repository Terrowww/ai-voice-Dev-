package com.example.voicecall

import android.Manifest
import android.content.pm.PackageManager
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.SystemBarStyle
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.delay

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge(
            statusBarStyle = SystemBarStyle.dark(android.graphics.Color.TRANSPARENT),
            navigationBarStyle = SystemBarStyle.dark(android.graphics.Color.TRANSPARENT)
        )
        setContent { CallScreen() }
    }
}

data class Btn(val icon: String, val label: String, val active: Boolean, val onClick: () -> Unit)

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CallScreen() {
    val context = LocalContext.current
    val engine = remember { AudioEngine() }

    var seconds by remember { mutableIntStateOf(0) }
    var showMore by remember { mutableStateOf(false) }
    var voiceOn by remember { mutableStateOf(false) }
    var listening by remember { mutableStateOf(false) }
    var preset by remember { mutableFloatStateOf(0.84f) }
    var latency by remember { mutableIntStateOf(0) }
    var muted by remember { mutableStateOf(false) }
    var speaker by remember { mutableStateOf(false) }

    val launcher = rememberLauncherForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { ok ->
        if (ok) { engine.start(); listening = true }
    }

    fun toggleListen(on: Boolean) {
        if (!on) { engine.stop(); listening = false; return }
        val granted = context.checkSelfPermission(Manifest.permission.RECORD_AUDIO) ==
            PackageManager.PERMISSION_GRANTED
        if (granted) { engine.start(); listening = true }
        else launcher.launch(Manifest.permission.RECORD_AUDIO)
    }

    DisposableEffect(Unit) { onDispose { engine.stop() } }
    LaunchedEffect(voiceOn, preset) { engine.ratio = if (voiceOn) preset else 1f }
    LaunchedEffect(muted) { engine.muted = muted }
    LaunchedEffect(listening) {
        if (listening) { delay(400); latency = engine.latencyMs }
    }
    LaunchedEffect(Unit) { while (true) { delay(1000); seconds++ } }

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
            Text("HD  $time", color = Color.White, fontSize = 22.sp)
            Spacer(Modifier.height(80.dp))
            Text("Контакт", color = Color.White, fontSize = 44.sp, fontWeight = FontWeight.Medium)
            Text("Мобильный телефон", color = Color.White, fontSize = 18.sp)
            Spacer(Modifier.weight(1f))

            val rows = listOf(
                listOf(
                    Btn("●", "Записать", false) {},
                    Btn("🎙", "Выключить\nмикрофон", muted) { muted = !muted },
                    Btn("🎧", "Bluetooth", false) {}
                ),
                listOf(
                    Btn("🔊", "Динамик", speaker) { speaker = !speaker },
                    Btn("⠿", "Клавиатура", false) {},
                    Btn("⋮", "Еще", false) { showMore = true }
                )
            )
            rows.forEach { row ->
                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceEvenly) {
                    row.forEach { CallButton(it) }
                }
                Spacer(Modifier.height(20.dp))
            }

            Spacer(Modifier.height(12.dp))
            Box(
                Modifier.size(80.dp).clip(CircleShape).background(Color(0xFFDB3A34))
                    .clickable { /* TODO: завершить звонок */ },
                contentAlignment = Alignment.Center
            ) { Text("✕", color = Color.White, fontSize = 30.sp) }
            Spacer(Modifier.height(24.dp))
        }
    }

    if (showMore) {
        ModalBottomSheet(onDismissRequest = { showMore = false }) {
            Column(Modifier.padding(24.dp).padding(bottom = 24.dp)) {
                Text("Смена голоса", fontSize = 20.sp, fontWeight = FontWeight.Medium)
                Spacer(Modifier.height(12.dp))

                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text("Слушать себя (тест)", Modifier.weight(1f))
                    Switch(checked = listening, onCheckedChange = { toggleListen(it) })
                }
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text("Смена голоса", Modifier.weight(1f))
                    Switch(checked = voiceOn, onCheckedChange = { voiceOn = it })
                }
                Spacer(Modifier.height(8.dp))

                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    listOf("Низкий" to 0.84f, "Ниже" to 0.75f, "Выше" to 1.15f).forEach { (name, v) ->
                        FilterChip(
                            selected = preset == v,
                            onClick = { preset = v },
                            label = { Text(name) }
                        )
                    }
                }
                Spacer(Modifier.height(12.dp))
                Text(
                    if (listening) "Задержка: ≈ $latency мс (оценка)" else "Включи тест и надень наушники",
                    color = Color.Gray
                )
            }
        }
    }
}

@Composable
fun CallButton(b: Btn) {
    Column(Modifier.width(100.dp), horizontalAlignment = Alignment.CenterHorizontally) {
        Box(
            Modifier.size(72.dp).clip(RoundedCornerShape(26.dp))
                .background(if (b.active) Color(0xFFE4E4EA) else Color(0x44FFFFFF))
                .clickable { b.onClick() },
            contentAlignment = Alignment.Center
        ) {
            Text(b.icon, color = if (b.active) Color.Black else Color.White, fontSize = 26.sp)
        }
        Spacer(Modifier.height(6.dp))
        Text(b.label, color = Color.White, fontSize = 13.sp, textAlign = TextAlign.Center)
    }
}
