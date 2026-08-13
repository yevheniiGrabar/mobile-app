package com.example.ui.theme

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable

private val AppleLightColorScheme =
  lightColorScheme(
    primary = SleekPrimary,
    onPrimary = SleekOnPrimary,
    primaryContainer = SleekPrimaryContainer,
    onPrimaryContainer = SleekOnPrimaryContainer,
    secondary = SleekSecondary,
    onSecondary = SleekOnSecondary,
    tertiary = SleekPriceGreen,
    background = SleekBg,
    surface = SleekSurface,
    surfaceVariant = SleekSurfaceVariant,
    onBackground = SleekTextPrimary,
    onSurface = SleekTextPrimary,
    onSurfaceVariant = SleekTextSecondary,
    outline = SleekBorder
  )

@Composable
fun SilpoMenuTheme(
  darkTheme: Boolean = false,
  dynamicColor: Boolean = false,
  content: @Composable () -> Unit,
) {
  MaterialTheme(colorScheme = AppleLightColorScheme, typography = Typography, content = content)
}

