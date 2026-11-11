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

// "Почта" между телефонами: вход в Firebase, свой код, записка о звонке
class Signaling(ctx: Context) {
    private val prefs = ctx.getSharedPreferences("vc", Context.MODE_PRIVATE)
    private val db = FirebaseDatabase
        .getInstance("https://voicecall-62a00-default-rtdb.europe-west1.firebasedatabase.app")
        .reference

    // свой код: 4 цифры, создаётся один раз и запоминается
    val myCode: String = prefs.getString("code", null)
        ?: (1000 + java.util.Random().nextInt(9000)).toString()
            .also { prefs.edit().putString("code", it).apply() }

    var status by mutableStateOf("подключение...")
    var incomingFrom by mutableStateOf<String?>(null)

    fun start() {
        FirebaseAuth.getInstance().signInAnonymously()
            .addOnSuccessListener {
                status = "онлайн"
                db.child("users").child(myCode).setValue(it.user?.uid)
                listen()
            }
            .addOnFailureListener { status = "ошибка: ${it.message}" }
    }

    // слушаем записки, адресованные нам
    private fun listen() {
        db.child("calls").child(myCode).addValueEventListener(object : ValueEventListener {
            override fun onDataChange(s: DataSnapshot) {
                incomingFrom = s.child("from").getValue(String::class.java)
            }
            override fun onCancelled(e: DatabaseError) {
                status = "ошибка: ${e.message}"
            }
        })
    }

    // кладём записку "звонит такой-то" на код второго телефона
    fun call(to: String) {
        if (to.isEmpty()) return
        db.child("calls").child(to).setValue(
            mapOf("from" to myCode, "ts" to ServerValue.TIMESTAMP)
        )
    }

    fun clearIncoming() {
        db.child("calls").child(myCode).removeValue()
    }
}
