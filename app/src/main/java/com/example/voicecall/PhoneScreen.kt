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
