package com.example.voicecall

import android.content.Context
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.database.DataSnapshot
import com.google.firebase.database.DatabaseError
import com.google.firebase.database.FirebaseDatabase
import com.google.firebase.database.ServerValue
import com.google.firebase.database.ValueEventListener

// 10 цифр -> "123 456 78 90", чтобы выглядело как номер
fun fmtNumber(d: String): String =
    if (d.length == 10) "${d.substring(0, 3)} ${d.substring(3, 6)} ${d.substring(6, 8)} ${d.substring(8)}" else d

// "Почта" между телефонами: вход в Firebase, свой номер, записка о звонке
class Signaling(ctx: Context) {
    private val prefs = ctx.getSharedPreferences("vc", Context.MODE_PRIVATE)
    private val db = FirebaseDatabase
        .getInstance("https://voicecall-62a00-default-rtdb.europe-west1.firebasedatabase.app")
        .reference

    // свой номер: 10 цифр, создаётся один раз и запоминается (это внутренний номер приложения)
    val myNumber: String = prefs.getString("num", null)
        ?: (1000000000L + (java.util.Random().nextDouble() * 8999999999L).toLong()).toString()
            .also { prefs.edit().putString("num", it).apply() }

    var status by mutableStateOf("подключение...")
    var incomingFrom by mutableStateOf<String?>(null)

    fun start() {
        FirebaseAuth.getInstance().signInAnonymously()
            .addOnSuccessListener {
                status = "онлайн"
                db.child("users").child(myNumber).setValue(it.user?.uid)
                listen()
            }
            .addOnFailureListener { status = "ошибка: ${it.message}" }
    }

    private fun listen() {
        db.child("calls").child(myNumber).addValueEventListener(object : ValueEventListener {
            override fun onDataChange(s: DataSnapshot) {
                incomingFrom = s.child("from").getValue(String::class.java)
            }
            override fun onCancelled(e: DatabaseError) {
                status = "ошибка: ${e.message}"
            }
        })
    }

    fun call(to: String) {
        if (to.isEmpty()) return
        db.child("calls").child(to).setValue(
            mapOf("from" to myNumber, "ts" to ServerValue.TIMESTAMP)
        )
    }

    // звонящий положил трубку: убираем записку у второго
    fun cancel(to: String) {
        if (to.isNotEmpty()) db.child("calls").child(to).removeValue()
    }

    fun clearIncoming() {
        db.child("calls").child(myNumber).removeValue()
    }
}
