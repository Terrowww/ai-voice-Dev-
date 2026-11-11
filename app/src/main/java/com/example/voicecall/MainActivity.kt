package com.example.voicecall

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
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
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.delay

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent { CallScreen() }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CallScreen() {
    var seconds by remember { mutableIntStateOf(0) }
    var showMore by remember { mutableStateOf(false) }
    var voiceOn by remember { mutableStateOf(false) }
    var muted by remember { mutableStateOf(false) }
    var speaker by remember { mutableStateOf(false) }

    LaunchedEffect(Unit) {
        while (true) { delay(1000); seconds++ }
    }
    val time = "%02d:%02d".format(seconds / 60, seconds % 60)

    Box(
        Modifier.fillMaxSize().background(
            Brush.verticalGradient(listOf(Color(0xFF0B0B14), Color(0xFF3A1A30), Color(0xFF7A7F9A)))
        )
    ) {
        Column(
            Modifier.fillMaxSize().padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Spacer(Modifier.height(48.dp))
            Text("HD  $time", color = Color.White, fontSize = 22.sp)
            Spacer(Modifier.height(80.dp))
            Text("Контакт", color = Color.White, fontSize = 44.sp, fontWeight = FontWeight.Medium)
            Text("Мобильный телефон", color = Color.White, fontSize = 18.sp)
            Spacer(Modifier.weight(1f))

            val rows = listOf(
                listOf(
                    Triple(time, false) {},
                    Triple("Выключить\nмикрофон", muted) { muted = !muted },
                    Triple("Bluetooth", false) {}
                ),
                listOf(
                    Triple("Динамик", speaker) { speaker = !speaker },
                    Triple("Клавиатура", false) {},
                    Triple("Еще", false) { showMore = true }
                )
            )
            rows.forEach { row ->
                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceEvenly) {
                    row.forEach { (label, active, onClick) ->
                        CallButton(label, active, onClick)
                    }
                }
                Spacer(Modifier.height(20.dp))
            }

            Spacer(Modifier.height(12.dp))
            Box(
                Modifier.size(80.dp).clip(CircleShape).background(Color(0xFFDB3A34))
                    .clickable { /* TODO: завершить звонок */ },
                contentAlignment = Alignment.Center
            ) { Text("✕", color = Color.White, fontSize = 30.sp) }
            Spacer(Modifier.height(40.dp))
        }
    }

    if (showMore) {
        ModalBottomSheet(onDismissRequest = { showMore = false }) {
            Column(Modifier.padding(24.dp).padding(bottom = 24.dp)) {
                Text("Смена голоса", fontSize = 20.sp, fontWeight = FontWeight.Medium)
                Spacer(Modifier.height(12.dp))
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text("Включить", Modifier.weight(1f))
                    Switch(checked = voiceOn, onCheckedChange = { voiceOn = it })
                }
                Spacer(Modifier.height(8.dp))
                Text("Голос, режим и питч добавим на следующем шаге", color = Color.Gray)
            }
        }
    }
}

@Composable
fun CallButton(label: String, active: Boolean, onClick: () -> Unit) {
    Column(Modifier.width(100.dp), horizontalAlignment = Alignment.CenterHorizontally) {
        Box(
            Modifier.size(72.dp).clip(RoundedCornerShape(26.dp))
                .background(if (active) Color(0xFFE4E4EA) else Color(0x44FFFFFF))
                .clickable { onClick() },
            contentAlignment = Alignment.Center
        ) {
            Text(
                label.take(2),
                color = if (active) Color.Black else Color.White,
                fontSize = 18.sp
            )
        }
        Spacer(Modifier.height(6.dp))
        Text(label, color = Color.White, fontSize = 13.sp, textAlign = TextAlign.Center)
    }
}
