#!/data/data/com.termux/files/usr/bin/bash
# Запускать в пустой папке будущего репозитория: bash setup.sh
set -e
mkdir -p .github/workflows app/src/main/java/com/example/voicecall

cat > settings.gradle.kts <<'EOF'
pluginManagement {
    repositories { google(); mavenCentral(); gradlePluginPortal() }
}
dependencyResolutionManagement {
    repositories { google(); mavenCentral() }
}
rootProject.name = "VoiceCall"
include(":app")
EOF

cat > build.gradle.kts <<'EOF'
plugins {
    id("com.android.application") version "8.5.2" apply false
    id("org.jetbrains.kotlin.android") version "2.0.20" apply false
    id("org.jetbrains.kotlin.plugin.compose") version "2.0.20" apply false
}
EOF

cat > gradle.properties <<'EOF'
android.useAndroidX=true
org.gradle.jvmargs=-Xmx3g
EOF

cat > app/build.gradle.kts <<'EOF'
plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("org.jetbrains.kotlin.plugin.compose")
}
android {
    namespace = "com.example.voicecall"
    compileSdk = 34
    defaultConfig {
        applicationId = "com.example.voicecall"
        minSdk = 26
        targetSdk = 34
        versionCode = 1
        versionName = "0.1"
    }
    buildFeatures { compose = true }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions { jvmTarget = "17" }
}
dependencies {
    implementation(platform("androidx.compose:compose-bom:2024.09.00"))
    implementation("androidx.activity:activity-compose:1.9.2")
    implementation("androidx.compose.material3:material3")
    implementation("androidx.compose.ui:ui")
}
EOF

cat > app/src/main/AndroidManifest.xml <<'EOF'
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.RECORD_AUDIO" />
    <uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />
    <uses-permission android:name="android.permission.INTERNET" />
    <application
        android:label="VoiceCall"
        android:theme="@android:style/Theme.Material.NoActionBar">
        <activity android:name=".MainActivity" android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>
</manifest>
EOF

cat > app/src/main/java/com/example/voicecall/MainActivity.kt <<'EOF'
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
EOF

cat > .github/workflows/build.yml <<'EOF'
name: build
on:
  push:
    branches: [main]
  workflow_dispatch:
permissions:
  contents: write
jobs:
  apk:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-java@v4
        with: { distribution: temurin, java-version: 17 }
      - uses: android-actions/setup-android@v3
      - uses: gradle/actions/setup-gradle@v4
        with: { gradle-version: "8.9" }
      - run: gradle assembleDebug --no-daemon
      - uses: softprops/action-gh-release@v2
        with:
          tag_name: latest
          files: app/build/outputs/apk/debug/app-debug.apk
EOF

cat > .gitignore <<'EOF'
build/
.gradle/
local.properties
EOF

echo "Готово. Дальше: git init, git add ., git commit, git push"
