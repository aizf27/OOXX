package com.kangsi.ooxx

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import com.kangsi.ooxx.ui.OoxxApp
import com.kangsi.ooxx.ui.theme.OoxxTheme

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            OoxxTheme {
                OoxxApp()
            }
        }
    }
}
