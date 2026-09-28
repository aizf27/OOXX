package com.kangsi.ooxx.ui.theme

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Typography
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

val Paper = Color(0xFFFFFCF3)
val Ink = Color(0xFF292827)
val Coral = Color(0xFFFF765E)
val Teal = Color(0xFF45BFC2)
val Sunny = Color(0xFFFFD657)
val Sky = Color(0xFF66BDF1)
val SoftGray = Color(0xFFF0EEE8)

private val Colors = lightColorScheme(
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
)

@Composable
fun OoxxTheme(content: @Composable () -> Unit) {
    MaterialTheme(colorScheme = Colors, typography = Typography(), content = content)
}
