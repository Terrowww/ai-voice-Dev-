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
