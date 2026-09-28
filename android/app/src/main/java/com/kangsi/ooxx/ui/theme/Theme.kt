package com.kangsi.ooxx.ui.theme

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Typography
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.graphics.Color

/** 由「我的」页的深色模式开关驱动；各颜色 getter 读取它，界面会自动重组。 */
var darkModeEnabled by mutableStateOf(false)

val Paper get() = if (darkModeEnabled) Color(0xFF201F1C) else Color(0xFFFFFCF3)
val Ink get() = if (darkModeEnabled) Color(0xFFECE8DF) else Color(0xFF292827)
val Coral = Color(0xFFFF765E)
val Teal = Color(0xFF45BFC2)
val Sunny = Color(0xFFFFD657)
val Sky = Color(0xFF66BDF1)
val SoftGray get() = if (darkModeEnabled) Color(0xFF2C2B27) else Color(0xFFF0EEE8)
val CardSurface get() = if (darkModeEnabled) Color(0xFF2A2925) else Color.White
val TextSecondary get() = if (darkModeEnabled) Color(0xFFA8A39A) else Color.Gray

@Composable
fun OoxxTheme(content: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = lightColorScheme(
            primary = Coral,
            onPrimary = Color.White,
            secondary = Teal,
            onSecondary = Color.White,
            tertiary = Sunny,
            background = Paper,
            onBackground = Ink,
            surface = Paper,
            onSurface = Ink,
            outline = Color(0xFFB9B5AB)
        ),
        typography = Typography(),
        content = content
    )
}
