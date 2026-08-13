package com.example.ui.dialogs

import android.widget.Toast
import androidx.compose.animation.*
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.AsyncImage
import com.example.data.model.Ingredient
import com.example.data.model.RecipeMeal
import com.example.ui.theme.*
import kotlinx.coroutines.delay

@Composable
fun RecipeDetailDialog(
    meal: RecipeMeal,
    onReplaceIngredientClick: (Ingredient) -> Unit,
    onDismiss: () -> Unit,
    onLogToNutritionTracker: ((RecipeMeal) -> Unit)? = null
) {
    val context = LocalContext.current

    // Embedded Kitchen Timer States
    var activeTimerStepIndex by remember { mutableStateOf<Int?>(null) }
    var activeTimerTotalSeconds by remember { mutableStateOf(0) }
    var activeTimerRemainingSeconds by remember { mutableStateOf(0) }
    var isTimerRunning by remember { mutableStateOf(false) }
    var isTimerFinished by remember { mutableStateOf(false) }

    var stepCustomPresetOpen by remember { mutableStateOf<Int?>(null) }

    // Countdown Coroutine Effect
    LaunchedEffect(isTimerRunning, activeTimerRemainingSeconds) {
        if (isTimerRunning && activeTimerRemainingSeconds > 0) {
            delay(1000L)
            activeTimerRemainingSeconds -= 1
            if (activeTimerRemainingSeconds == 0) {
                isTimerRunning = false
                isTimerFinished = true
                val stepLabel = activeTimerStepIndex?.let { "Крок ${it + 1}" } ?: "Страва"
                Toast.makeText(context, "🔔 Кухонний таймер: $stepLabel готовий!", Toast.LENGTH_LONG).show()
            }
        }
    }

    fun startTimerForStep(stepIndex: Int, minutes: Int) {
        activeTimerStepIndex = stepIndex
        activeTimerTotalSeconds = minutes * 60
        activeTimerRemainingSeconds = minutes * 60
        isTimerRunning = true
        isTimerFinished = false
        stepCustomPresetOpen = null
        Toast.makeText(context, "⏱️ Таймер запущено на $minutes хв (Крок ${stepIndex + 1})", Toast.LENGTH_SHORT).show()
    }

    fun formatTimeMMSS(seconds: Int): String {
        val mins = seconds / 60
        val secs = seconds % 60
        return String.format(java.util.Locale.US, "%02d:%02d", mins, secs)
    }

    fun extractMinutesFromStep(stepText: String): Int? {
        val regex = Regex("""(\d+)(?:\s*-\s*\d+)?\s*(?:хв|хвилин|мінут|min)""", RegexOption.IGNORE_CASE)
        val match = regex.find(stepText)
        return match?.groupValues?.get(1)?.toIntOrNull()
    }

    AlertDialog(
        onDismissRequest = onDismiss,
        containerColor = SleekSurface,
        shape = RoundedCornerShape(24.dp),
        title = null,
        text = {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .heightIn(max = 560.dp)
            ) {
                // Image Banner
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(180.dp)
                        .clip(RoundedCornerShape(16.dp))
                        .background(SleekSurfaceVariant)
                ) {
                    AsyncImage(
                        model = meal.imageUrl,
                        contentDescription = meal.title,
                        contentScale = ContentScale.Crop,
                        modifier = Modifier.fillMaxSize()
                    )

                    IconButton(
                        onClick = onDismiss,
                        modifier = Modifier
                            .align(Alignment.TopEnd)
                            .padding(8.dp)
                            .background(Color.Black.copy(alpha = 0.5f), shape = RoundedCornerShape(20.dp))
                    ) {
                        Icon(Icons.Default.Close, contentDescription = "Close", tint = Color.White)
                    }

                    Surface(
                        color = SleekElevatedSurface.copy(alpha = 0.9f),
                        shape = RoundedCornerShape(bottomEnd = 12.dp),
                        modifier = Modifier.align(Alignment.TopStart)
                    ) {
                        Text(
                            text = meal.mealType,
                            color = SleekTextPrimary,
                            fontWeight = FontWeight.Bold,
                            fontSize = 12.sp,
                            modifier = Modifier.padding(horizontal = 10.dp, vertical = 4.dp)
                        )
                    }
                }

                Spacer(modifier = Modifier.height(12.dp))

                Text(
                    text = meal.title,
                    fontWeight = FontWeight.Bold,
                    fontSize = 20.sp,
                    color = SleekTextPrimary
                )

                Spacer(modifier = Modifier.height(6.dp))

                Row(
                    horizontalArrangement = Arrangement.spacedBy(12.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Surface(
                        color = SleekSurfaceVariant,
                        shape = RoundedCornerShape(8.dp)
                    ) {
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp)
                        ) {
                            Icon(Icons.Default.Kitchen, contentDescription = null, modifier = Modifier.size(14.dp), tint = SleekPriceGreen)
                            Spacer(modifier = Modifier.width(4.dp))
                            Text(meal.equipment, fontSize = 12.sp, fontWeight = FontWeight.Bold, color = SleekTextPrimary)
                        }
                    }

                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(Icons.Default.Timer, contentDescription = null, modifier = Modifier.size(14.dp), tint = SleekTextSecondary)
                        Spacer(modifier = Modifier.width(4.dp))
                        Text("${meal.prepTimeMinutes} хв", fontSize = 12.sp, color = SleekTextSecondary)
                    }

                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(Icons.Default.LocalFireDepartment, contentDescription = null, modifier = Modifier.size(14.dp), tint = SleekAccentOrange)
                        Spacer(modifier = Modifier.width(4.dp))
                        Text("${meal.calories} ккал", fontSize = 12.sp, color = SleekTextSecondary)
                    }
                }

                Spacer(modifier = Modifier.height(6.dp))

                // Macros row in dialog
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Surface(color = SleekSurfaceVariant, shape = RoundedCornerShape(6.dp)) {
                        Text("Б: ${meal.proteinsGrams}г", fontSize = 11.sp, color = SleekPrimary, fontWeight = FontWeight.Bold, modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp))
                    }
                    Surface(color = SleekSurfaceVariant, shape = RoundedCornerShape(6.dp)) {
                        Text("Ж: ${meal.fatsGrams}г", fontSize = 11.sp, color = SleekTextSecondary, fontWeight = FontWeight.Bold, modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp))
                    }
                    Surface(color = SleekSurfaceVariant, shape = RoundedCornerShape(6.dp)) {
                        Text("В: ${meal.carbsGrams}г", fontSize = 11.sp, color = SleekPriceGreen, fontWeight = FontWeight.Bold, modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp))
                    }
                }

                Spacer(modifier = Modifier.height(10.dp))

                // Embedded Active Timer Card
                if (activeTimerTotalSeconds > 0) {
                    Card(
                        colors = CardDefaults.cardColors(
                            containerColor = if (isTimerFinished) Color(0xFFFFEBEE) else SleekPrimaryContainer
                        ),
                        border = BorderStroke(
                            1.dp,
                            if (isTimerFinished) Color(0xFFE53935) else SleekPrimary.copy(alpha = 0.5f)
                        ),
                        shape = RoundedCornerShape(16.dp),
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(bottom = 8.dp)
                    ) {
                        Column(modifier = Modifier.padding(12.dp)) {
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Row(verticalAlignment = Alignment.CenterVertically) {
                                    Icon(
                                        if (isTimerFinished) Icons.Default.NotificationsActive else Icons.Default.Timer,
                                        contentDescription = null,
                                        tint = if (isTimerFinished) Color(0xFFD32F2F) else SleekPrimary,
                                        modifier = Modifier.size(20.dp)
                                    )
                                    Spacer(modifier = Modifier.width(6.dp))
                                    Text(
                                        text = if (isTimerFinished) "🔔 ЧАС ВИЙШОВ! (Крок ${activeTimerStepIndex?.plus(1)})" else "⏱️ Кухонний таймер (Крок ${activeTimerStepIndex?.plus(1)})",
                                        fontWeight = FontWeight.Bold,
                                        fontSize = 13.sp,
                                        color = if (isTimerFinished) Color(0xFFD32F2F) else SleekPrimary
                                    )
                                }

                                IconButton(
                                    onClick = {
                                        isTimerRunning = false
                                        activeTimerTotalSeconds = 0
                                        activeTimerRemainingSeconds = 0
                                        isTimerFinished = false
                                        activeTimerStepIndex = null
                                    },
                                    modifier = Modifier.size(28.dp)
                                ) {
                                    Icon(Icons.Default.Close, contentDescription = "Cancel timer", tint = SleekTextSecondary, modifier = Modifier.size(16.dp))
                                }
                            }

                            Spacer(modifier = Modifier.height(6.dp))

                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Text(
                                    text = formatTimeMMSS(activeTimerRemainingSeconds),
                                    fontSize = 28.sp,
                                    fontWeight = FontWeight.ExtraBold,
                                    color = if (isTimerFinished) Color(0xFFD32F2F) else SleekTextPrimary
                                )

                                Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                                    if (!isTimerFinished) {
                                        IconButton(
                                            onClick = { isTimerRunning = !isTimerRunning },
                                            modifier = Modifier
                                                .size(36.dp)
                                                .background(SleekPrimary, CircleShape)
                                        ) {
                                            Icon(
                                                if (isTimerRunning) Icons.Default.Pause else Icons.Default.PlayArrow,
                                                contentDescription = if (isTimerRunning) "Pause" else "Play",
                                                tint = SleekOnPrimary,
                                                modifier = Modifier.size(20.dp)
                                            )
                                        }

                                        OutlinedButton(
                                            onClick = {
                                                activeTimerRemainingSeconds += 60
                                                activeTimerTotalSeconds += 60
                                            },
                                            contentPadding = PaddingValues(horizontal = 8.dp, vertical = 2.dp),
                                            modifier = Modifier.height(36.dp),
                                            shape = RoundedCornerShape(10.dp)
                                        ) {
                                            Text("+1 хв", fontSize = 11.sp, fontWeight = FontWeight.Bold, color = SleekPrimary)
                                        }
                                    } else {
                                        Button(
                                            onClick = {
                                                isTimerFinished = false
                                                activeTimerRemainingSeconds = activeTimerTotalSeconds
                                                isTimerRunning = true
                                            },
                                            colors = ButtonDefaults.buttonColors(containerColor = SleekPrimary),
                                            contentPadding = PaddingValues(horizontal = 12.dp, vertical = 4.dp),
                                            modifier = Modifier.height(36.dp),
                                            shape = RoundedCornerShape(10.dp)
                                        ) {
                                            Icon(Icons.Default.Refresh, contentDescription = null, modifier = Modifier.size(16.dp))
                                            Spacer(modifier = Modifier.width(4.dp))
                                            Text("Повторити", fontSize = 12.sp, fontWeight = FontWeight.Bold)
                                        }
                                    }
                                }
                            }

                            if (activeTimerTotalSeconds > 0) {
                                Spacer(modifier = Modifier.height(8.dp))
                                LinearProgressIndicator(
                                    progress = {
                                        if (isTimerFinished) 1f
                                        else (1f - (activeTimerRemainingSeconds.toFloat() / activeTimerTotalSeconds)).coerceIn(0f, 1f)
                                    },
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .height(6.dp)
                                        .clip(RoundedCornerShape(3.dp)),
                                    color = if (isTimerFinished) Color(0xFFD32F2F) else SleekPrimary,
                                    trackColor = SleekBorder
                                )
                            }
                        }
                    }
                }

                LazyColumn(
                    verticalArrangement = Arrangement.spacedBy(12.dp),
                    modifier = Modifier.weight(1f)
                ) {
                    item {
                        Text(
                            text = "Інгредієнти та ціни Сільпо:",
                            fontWeight = FontWeight.Bold,
                            fontSize = 15.sp,
                            color = SleekTextPrimary
                        )
                    }

                    itemsIndexed(meal.ingredients) { _, ing ->
                        Card(
                            colors = CardDefaults.cardColors(containerColor = SleekSurfaceVariant),
                            border = BorderStroke(1.dp, SleekBorder),
                            shape = RoundedCornerShape(10.dp),
                            elevation = CardDefaults.cardElevation(defaultElevation = 1.dp)
                        ) {
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(10.dp),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Column(modifier = Modifier.weight(1f)) {
                                    Text(ing.name, fontWeight = FontWeight.Bold, fontSize = 14.sp, color = SleekTextPrimary)
                                    Text("${ing.quantity} ${ing.unit} | ${ing.department}", fontSize = 11.sp, color = SleekTextSecondary)
                                }

                                Column(horizontalAlignment = Alignment.End) {
                                    Text("${ing.priceUah.toInt()} ₴", fontWeight = FontWeight.Bold, color = SleekPriceGreen, fontSize = 14.sp)
                                    TextButton(
                                        onClick = { onReplaceIngredientClick(ing) },
                                        contentPadding = PaddingValues(0.dp),
                                        modifier = Modifier.height(24.dp)
                                    ) {
                                        Text("Замінити ₴", fontSize = 11.sp, color = SleekPrimary, fontWeight = FontWeight.Bold)
                                    }
                                }
                            }
                        }
                    }

                    item {
                        Spacer(modifier = Modifier.height(8.dp))
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text(
                                text = "Кроки приготування:",
                                fontWeight = FontWeight.Bold,
                                fontSize = 15.sp,
                                color = SleekTextPrimary
                            )

                            Text(
                                text = "⏱️ Натисніть крок для таймера",
                                fontSize = 11.sp,
                                color = SleekTextSecondary
                            )
                        }
                    }

                    itemsIndexed(meal.instructions) { index, step ->
                        val detectedMins = remember(step) { extractMinutesFromStep(step) }
                        val isStepTimerActive = (activeTimerStepIndex == index && activeTimerTotalSeconds > 0)

                        Card(
                            colors = CardDefaults.cardColors(
                                containerColor = if (isStepTimerActive) SleekPrimaryContainer.copy(alpha = 0.5f) else SleekSurfaceVariant
                            ),
                            border = BorderStroke(
                                1.dp,
                                if (isStepTimerActive) SleekPrimary else SleekBorder
                            ),
                            shape = RoundedCornerShape(12.dp),
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Column(modifier = Modifier.padding(10.dp)) {
                                Row(
                                    verticalAlignment = Alignment.Top,
                                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                                ) {
                                    Surface(
                                        color = if (isStepTimerActive) SleekPrimary else SleekPrimary.copy(alpha = 0.85f),
                                        shape = RoundedCornerShape(12.dp),
                                        modifier = Modifier.size(22.dp)
                                    ) {
                                        Box(contentAlignment = Alignment.Center) {
                                            Text("${index + 1}", color = SleekOnPrimary, fontWeight = FontWeight.Bold, fontSize = 12.sp)
                                        }
                                    }
                                    Text(step, fontSize = 13.sp, color = SleekTextPrimary, modifier = Modifier.weight(1f))
                                }

                                Spacer(modifier = Modifier.height(8.dp))

                                // Timer Launch Controls
                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    horizontalArrangement = Arrangement.SpaceBetween,
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    if (detectedMins != null) {
                                        Button(
                                            onClick = { startTimerForStep(index, detectedMins) },
                                            colors = ButtonDefaults.buttonColors(
                                                containerColor = if (isStepTimerActive) SleekAccentOrange else SleekPrimary
                                            ),
                                            shape = RoundedCornerShape(10.dp),
                                            contentPadding = PaddingValues(horizontal = 10.dp, vertical = 4.dp),
                                            modifier = Modifier
                                                .height(32.dp)
                                                .testTag("btn_step_timer_$index")
                                        ) {
                                            Icon(Icons.Default.Timer, contentDescription = null, modifier = Modifier.size(14.dp))
                                            Spacer(modifier = Modifier.width(6.dp))
                                            Text(
                                                text = if (isStepTimerActive) "Таймер активний ($detectedMins хв)" else "Запустити таймер ($detectedMins хв)",
                                                fontSize = 11.sp,
                                                fontWeight = FontWeight.Bold
                                            )
                                        }
                                    } else {
                                        OutlinedButton(
                                            onClick = {
                                                stepCustomPresetOpen = if (stepCustomPresetOpen == index) null else index
                                            },
                                            shape = RoundedCornerShape(10.dp),
                                            border = BorderStroke(1.dp, SleekPrimary),
                                            contentPadding = PaddingValues(horizontal = 10.dp, vertical = 4.dp),
                                            modifier = Modifier
                                                .height(32.dp)
                                                .testTag("btn_step_timer_preset_$index")
                                        ) {
                                            Icon(Icons.Default.Timer, contentDescription = null, tint = SleekPrimary, modifier = Modifier.size(14.dp))
                                            Spacer(modifier = Modifier.width(6.dp))
                                            Text(
                                                text = if (isStepTimerActive) "Таймер активний" else "⏱️ Кухонний таймер",
                                                fontSize = 11.sp,
                                                color = SleekPrimary,
                                                fontWeight = FontWeight.Bold
                                            )
                                        }
                                    }

                                    if (isStepTimerActive) {
                                        Surface(
                                            color = SleekPrimary,
                                            shape = RoundedCornerShape(8.dp)
                                        ) {
                                            Text(
                                                text = formatTimeMMSS(activeTimerRemainingSeconds),
                                                color = SleekOnPrimary,
                                                fontSize = 12.sp,
                                                fontWeight = FontWeight.ExtraBold,
                                                modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp)
                                            )
                                        }
                                    }
                                }

                                // Quick Presets Selector
                                AnimatedVisibility(visible = stepCustomPresetOpen == index) {
                                    Column(modifier = Modifier.padding(top = 8.dp)) {
                                        Text("Виберіть час для кроку ${index + 1}:", fontSize = 11.sp, fontWeight = FontWeight.Bold, color = SleekTextSecondary)
                                        Spacer(modifier = Modifier.height(4.dp))
                                        LazyRow(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                                            val presets = listOf(1, 3, 5, 10, 15, 20, 30)
                                            items(presets) { pMins ->
                                                FilterChip(
                                                    selected = false,
                                                    onClick = { startTimerForStep(index, pMins) },
                                                    label = { Text("$pMins хв", fontSize = 11.sp, fontWeight = FontWeight.Bold) },
                                                    colors = FilterChipDefaults.filterChipColors(
                                                        containerColor = SleekSurface,
                                                        labelColor = SleekPrimary
                                                    ),
                                                    border = FilterChipDefaults.filterChipBorder(
                                                        enabled = true,
                                                        selected = false,
                                                        borderColor = SleekPrimary
                                                    )
                                                )
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        },
        confirmButton = {
            if (onLogToNutritionTracker != null) {
                Button(
                    onClick = {
                        onLogToNutritionTracker(meal)
                        onDismiss()
                    },
                    colors = ButtonDefaults.buttonColors(containerColor = SleekPriceGreen),
                    shape = RoundedCornerShape(12.dp)
                ) {
                    Icon(Icons.Default.Check, contentDescription = null, modifier = Modifier.size(16.dp))
                    Spacer(modifier = Modifier.width(4.dp))
                    Text("З'їдено! В трекер", fontSize = 13.sp, fontWeight = FontWeight.Bold)
                }
            }
        }
    )
}


