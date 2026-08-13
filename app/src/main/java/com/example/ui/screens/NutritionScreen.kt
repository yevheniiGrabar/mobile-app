package com.example.ui.screens

import androidx.compose.animation.*
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.data.model.DailyRecipe
import com.example.data.model.LoggedMealEntity
import com.example.data.model.NutritionTarget
import com.example.data.model.RecipeMeal
import com.example.data.model.WeeklyMealPlan
import com.example.ui.theme.*

@Composable
fun NutritionScreen(
    selectedDateString: String,
    loggedMeals: List<LoggedMealEntity>,
    nutritionTarget: NutritionTarget,
    weeklyMealPlan: WeeklyMealPlan?,
    dailyRecipes: List<DailyRecipe>,
    onSelectPreviousDate: () -> Unit,
    onSelectNextDate: () -> Unit,
    onSelectToday: () -> Unit,
    onLogMealFromRecipeMeal: (RecipeMeal) -> Unit,
    onLogMealFromDailyRecipe: (DailyRecipe) -> Unit,
    onLogCustomMeal: (title: String, type: String, cals: Int, prot: Int, fats: Int, carbs: Int) -> Unit,
    onDeleteLoggedMeal: (String) -> Unit,
    onUpdateNutritionTarget: (cals: Int, prot: Int, fats: Int, carbs: Int) -> Unit
) {
    var showAddDialog by remember { mutableStateOf(false) }
    var showEditTargetDialog by remember { mutableStateOf(false) }

    val totalCaloriesConsumed = loggedMeals.sumOf { it.calories }
    val totalProteinsConsumed = loggedMeals.sumOf { it.proteinsGrams }
    val totalFatsConsumed = loggedMeals.sumOf { it.fatsGrams }
    val totalCarbsConsumed = loggedMeals.sumOf { it.carbsGrams }

    val caloriesProgress = (totalCaloriesConsumed.toFloat() / nutritionTarget.dailyCalories).coerceIn(0f, 1f)
    val remainingCalories = (nutritionTarget.dailyCalories - totalCaloriesConsumed).coerceAtLeast(0)

    LazyColumn(
        modifier = Modifier
            .fillMaxSize()
            .padding(horizontal = 16.dp),
        contentPadding = PaddingValues(top = 16.dp, bottom = 100.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        // Date Selector Bar
        item {
            Card(
                colors = CardDefaults.cardColors(containerColor = SleekSurface),
                border = BorderStroke(1.dp, SleekBorder),
                shape = RoundedCornerShape(16.dp),
                modifier = Modifier.fillMaxWidth()
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 12.dp, vertical = 8.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    IconButton(
                        onClick = onSelectPreviousDate,
                        modifier = Modifier.size(36.dp)
                    ) {
                        Icon(Icons.Default.ChevronLeft, contentDescription = "Prev Day", tint = SleekPrimary)
                    }

                    Column(
                        horizontalAlignment = Alignment.CenterHorizontally,
                        modifier = Modifier.clickable { onSelectToday() }
                    ) {
                        Text(
                            text = if (selectedDateString == getTodayDateString()) "Сьогодні" else selectedDateString,
                            fontWeight = FontWeight.ExtraBold,
                            fontSize = 15.sp,
                            color = SleekTextPrimary
                        )
                        Text(
                            text = if (selectedDateString == getTodayDateString()) selectedDateString else "Натисніть для 'Сьогодні'",
                            fontSize = 11.sp,
                            color = SleekTextSecondary
                        )
                    }

                    IconButton(
                        onClick = onSelectNextDate,
                        modifier = Modifier.size(36.dp)
                    ) {
                        Icon(Icons.Default.ChevronRight, contentDescription = "Next Day", tint = SleekPrimary)
                    }
                }
            }
        }

        // Daily Calories & Macros Overview Card
        item {
            Card(
                colors = CardDefaults.cardColors(containerColor = SleekSurface),
                border = BorderStroke(1.dp, SleekBorder),
                shape = RoundedCornerShape(20.dp),
                elevation = CardDefaults.cardElevation(defaultElevation = 2.dp),
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(modifier = Modifier.padding(18.dp)) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Icon(
                                Icons.Default.LocalFireDepartment,
                                contentDescription = null,
                                tint = SleekAccentOrange,
                                modifier = Modifier.size(24.dp)
                            )
                            Spacer(modifier = Modifier.width(6.dp))
                            Text(
                                text = "Денний Баланс Ккал",
                                fontWeight = FontWeight.Bold,
                                fontSize = 16.sp,
                                color = SleekTextPrimary
                            )
                        }

                        IconButton(
                            onClick = { showEditTargetDialog = true },
                            modifier = Modifier.size(32.dp)
                        ) {
                            Icon(Icons.Default.Tune, contentDescription = "Edit Goals", tint = SleekPrimary, modifier = Modifier.size(18.dp))
                        }
                    }

                    Spacer(modifier = Modifier.height(12.dp))

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.Bottom
                    ) {
                        Column {
                            Text(
                                text = "$totalCaloriesConsumed",
                                fontSize = 32.sp,
                                fontWeight = FontWeight.ExtraBold,
                                color = SleekTextPrimary
                            )
                            Text(
                                text = "з ${nutritionTarget.dailyCalories} ккал цілі",
                                fontSize = 12.sp,
                                color = SleekTextSecondary
                            )
                        }

                        Surface(
                            color = if (totalCaloriesConsumed <= nutritionTarget.dailyCalories) SleekPrimaryContainer else Color(0xFFFFEBEE),
                            shape = RoundedCornerShape(12.dp)
                        ) {
                            Text(
                                text = if (totalCaloriesConsumed <= nutritionTarget.dailyCalories)
                                    "Залишилось $remainingCalories ккал"
                                else
                                    "Перевищено на ${totalCaloriesConsumed - nutritionTarget.dailyCalories} ккал",
                                color = if (totalCaloriesConsumed <= nutritionTarget.dailyCalories) SleekPrimary else Color(0xFFD32F2F),
                                fontWeight = FontWeight.Bold,
                                fontSize = 12.sp,
                                modifier = Modifier.padding(horizontal = 10.dp, vertical = 6.dp)
                            )
                        }
                    }

                    Spacer(modifier = Modifier.height(10.dp))

                    LinearProgressIndicator(
                        progress = { caloriesProgress },
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(10.dp)
                            .clip(RoundedCornerShape(5.dp)),
                        color = if (totalCaloriesConsumed <= nutritionTarget.dailyCalories) SleekPrimary else Color(0xFFE53935),
                        trackColor = SleekBorder
                    )

                    Spacer(modifier = Modifier.height(16.dp))

                    // Macros Row
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        MacroCard(
                            label = "Білки",
                            consumed = totalProteinsConsumed,
                            target = nutritionTarget.dailyProteinsGrams,
                            unit = "г",
                            color = SleekPrimary,
                            modifier = Modifier.weight(1f)
                        )
                        MacroCard(
                            label = "Жири",
                            consumed = totalFatsConsumed,
                            target = nutritionTarget.dailyFatsGrams,
                            unit = "г",
                            color = SleekAccentOrange,
                            modifier = Modifier.weight(1f)
                        )
                        MacroCard(
                            label = "Вуглеводи",
                            consumed = totalCarbsConsumed,
                            target = nutritionTarget.dailyCarbsGrams,
                            unit = "г",
                            color = SleekPriceGreen,
                            modifier = Modifier.weight(1f)
                        )
                    }
                }
            }
        }

        // Action Buttons Row: Add Custom Meal
        item {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "Записана їжа (${loggedMeals.size})",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    color = SleekTextPrimary
                )

                Button(
                    onClick = { showAddDialog = true },
                    colors = ButtonDefaults.buttonColors(containerColor = SleekPrimary),
                    shape = RoundedCornerShape(12.dp),
                    contentPadding = PaddingValues(horizontal = 12.dp, vertical = 6.dp),
                    modifier = Modifier.height(36.dp).testTag("btn_add_custom_meal")
                ) {
                    Icon(Icons.Default.Add, contentDescription = null, modifier = Modifier.size(16.dp))
                    Spacer(modifier = Modifier.width(4.dp))
                    Text("Своя страва", fontSize = 12.sp, fontWeight = FontWeight.Bold)
                }
            }
        }

        // Logged Meals List
        if (loggedMeals.isEmpty()) {
            item {
                Card(
                    colors = CardDefaults.cardColors(containerColor = SleekSurface),
                    border = BorderStroke(1.dp, SleekBorder),
                    shape = RoundedCornerShape(16.dp),
                    modifier = Modifier.fillMaxWidth().padding(vertical = 8.dp)
                ) {
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(24.dp),
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Icon(
                            Icons.Default.Restaurant,
                            contentDescription = null,
                            tint = SleekTextMuted,
                            modifier = Modifier.size(48.dp)
                        )
                        Spacer(modifier = Modifier.height(12.dp))
                        Text(
                            text = "Ще немає записів про їжу за цей день",
                            fontWeight = FontWeight.Bold,
                            color = SleekTextPrimary,
                            fontSize = 14.sp
                        )
                        Spacer(modifier = Modifier.height(4.dp))
                        Text(
                            text = "Натисніть «+ З'їдено» у меню або додайте свою страву нижче",
                            fontSize = 12.sp,
                            color = SleekTextSecondary
                        )
                    }
                }
            }
        } else {
            items(loggedMeals, key = { it.id }) { meal ->
                Card(
                    colors = CardDefaults.cardColors(containerColor = SleekSurface),
                    border = BorderStroke(1.dp, SleekBorder),
                    shape = RoundedCornerShape(16.dp),
                    elevation = CardDefaults.cardElevation(defaultElevation = 1.dp),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(14.dp),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Column(modifier = Modifier.weight(1f)) {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Surface(
                                    color = SleekPrimaryContainer,
                                    shape = RoundedCornerShape(6.dp)
                                ) {
                                    Text(
                                        text = meal.mealType,
                                        color = SleekPrimary,
                                        fontSize = 10.sp,
                                        fontWeight = FontWeight.Bold,
                                        modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp)
                                    )
                                }
                                Spacer(modifier = Modifier.width(8.dp))
                                Text(
                                    text = meal.mealTitle,
                                    fontWeight = FontWeight.Bold,
                                    fontSize = 15.sp,
                                    color = SleekTextPrimary
                                )
                            }

                            Spacer(modifier = Modifier.height(6.dp))

                            Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                                Text("${meal.calories} ккал", fontWeight = FontWeight.Bold, color = SleekAccentOrange, fontSize = 12.sp)
                                Text("Б: ${meal.proteinsGrams}г", color = SleekPrimary, fontSize = 12.sp)
                                Text("Ж: ${meal.fatsGrams}г", color = SleekTextSecondary, fontSize = 12.sp)
                                Text("В: ${meal.carbsGrams}г", color = SleekPriceGreen, fontSize = 12.sp)
                            }
                        }

                        IconButton(
                            onClick = { onDeleteLoggedMeal(meal.id) },
                            modifier = Modifier.size(32.dp)
                        ) {
                            Icon(Icons.Default.DeleteOutline, contentDescription = "Delete", tint = Color(0xFFE53935), modifier = Modifier.size(18.dp))
                        }
                    }
                }
            }
        }

        // Quick Log Section from Planned Menu & Daily Recipes
        item {
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = "⚡ Швидкий запис з рецептів додатка",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
                color = SleekTextPrimary
            )
            Text(
                text = "Натисніть «+ З'їдено» щоб миттєво зарахувати ккал та нутрієнти",
                fontSize = 12.sp,
                color = SleekTextSecondary
            )
        }

        // Planned Menu Items Quick Adding
        val currentDayMeals = weeklyMealPlan?.days?.firstOrNull()?.meals ?: emptyList()
        if (currentDayMeals.isNotEmpty()) {
            item {
                Text(
                    text = "З вашого плану харчування:",
                    fontWeight = FontWeight.Bold,
                    fontSize = 13.sp,
                    color = SleekPrimary
                )
            }

            items(currentDayMeals) { meal ->
                Card(
                    colors = CardDefaults.cardColors(containerColor = SleekSurfaceVariant),
                    border = BorderStroke(1.dp, SleekBorder),
                    shape = RoundedCornerShape(14.dp),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(12.dp),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Column(modifier = Modifier.weight(1f)) {
                            Text(meal.title, fontWeight = FontWeight.Bold, fontSize = 14.sp, color = SleekTextPrimary)
                            Text(
                                "${meal.mealType} • ${meal.calories} ккал • Б:${meal.proteinsGrams}г Ж:${meal.fatsGrams}г В:${meal.carbsGrams}г",
                                fontSize = 11.sp,
                                color = SleekTextSecondary
                            )
                        }

                        Button(
                            onClick = { onLogMealFromRecipeMeal(meal) },
                            colors = ButtonDefaults.buttonColors(containerColor = SleekPriceGreen),
                            shape = RoundedCornerShape(10.dp),
                            contentPadding = PaddingValues(horizontal = 10.dp, vertical = 4.dp),
                            modifier = Modifier.height(32.dp)
                        ) {
                            Icon(Icons.Default.Check, contentDescription = null, modifier = Modifier.size(14.dp))
                            Spacer(modifier = Modifier.width(4.dp))
                            Text("+ З'їдено", fontSize = 11.sp, fontWeight = FontWeight.Bold)
                        }
                    }
                }
            }
        }

        // Daily Recipes Quick Adding
        if (dailyRecipes.isNotEmpty()) {
            item {
                Spacer(modifier = Modifier.height(4.dp))
                Text(
                    text = "Із Рецептів Дня Сільпо:",
                    fontWeight = FontWeight.Bold,
                    fontSize = 13.sp,
                    color = SleekAccentOrange
                )
            }

            items(dailyRecipes) { recipe ->
                Card(
                    colors = CardDefaults.cardColors(containerColor = SleekSurfaceVariant),
                    border = BorderStroke(1.dp, SleekBorder),
                    shape = RoundedCornerShape(14.dp),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(12.dp),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Column(modifier = Modifier.weight(1f)) {
                            Text(recipe.title, fontWeight = FontWeight.Bold, fontSize = 14.sp, color = SleekTextPrimary)
                            Text(
                                "${recipe.seasonTag} • ${recipe.calories} ккал • Б:${recipe.proteinsGrams}г Ж:${recipe.fatsGrams}г В:${recipe.carbsGrams}г",
                                fontSize = 11.sp,
                                color = SleekTextSecondary
                            )
                        }

                        Button(
                            onClick = { onLogMealFromDailyRecipe(recipe) },
                            colors = ButtonDefaults.buttonColors(containerColor = SleekAccentOrange),
                            shape = RoundedCornerShape(10.dp),
                            contentPadding = PaddingValues(horizontal = 10.dp, vertical = 4.dp),
                            modifier = Modifier.height(32.dp)
                        ) {
                            Icon(Icons.Default.Check, contentDescription = null, modifier = Modifier.size(14.dp))
                            Spacer(modifier = Modifier.width(4.dp))
                            Text("+ З'їдено", fontSize = 11.sp, fontWeight = FontWeight.Bold)
                        }
                    }
                }
            }
        }
    }

    // Dialog: Add Custom Meal
    if (showAddDialog) {
        AddCustomMealDialog(
            onDismiss = { showAddDialog = false },
            onConfirm = { title, type, cals, prot, fats, carbs ->
                onLogCustomMeal(title, type, cals, prot, fats, carbs)
                showAddDialog = false
            }
        )
    }

    // Dialog: Edit Targets
    if (showEditTargetDialog) {
        EditNutritionTargetDialog(
            currentTarget = nutritionTarget,
            onDismiss = { showEditTargetDialog = false },
            onConfirm = { cals, prot, fats, carbs ->
                onUpdateNutritionTarget(cals, prot, fats, carbs)
                showEditTargetDialog = false
            }
        )
    }
}

@Composable
fun MacroCard(
    label: String,
    consumed: Int,
    target: Int,
    unit: String,
    color: Color,
    modifier: Modifier = Modifier
) {
    val progress = (consumed.toFloat() / target).coerceIn(0f, 1f)

    Card(
        colors = CardDefaults.cardColors(containerColor = SleekSurfaceVariant),
        border = BorderStroke(1.dp, SleekBorder),
        shape = RoundedCornerShape(12.dp),
        modifier = modifier
    ) {
        Column(
            modifier = Modifier.padding(10.dp),
            horizontalAlignment = Alignment.Start
        ) {
            Text(label, fontSize = 11.sp, fontWeight = FontWeight.Bold, color = SleekTextSecondary)
            Spacer(modifier = Modifier.height(4.dp))
            Text(
                text = "$consumed / $target $unit",
                fontSize = 12.sp,
                fontWeight = FontWeight.ExtraBold,
                color = SleekTextPrimary
            )
            Spacer(modifier = Modifier.height(6.dp))
            LinearProgressIndicator(
                progress = { progress },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(4.dp)
                    .clip(CircleShape),
                color = color,
                trackColor = SleekBorder
            )
        }
    }
}

@Composable
fun AddCustomMealDialog(
    onDismiss: () -> Unit,
    onConfirm: (title: String, type: String, cals: Int, prot: Int, fats: Int, carbs: Int) -> Unit
) {
    var title by remember { mutableStateOf("") }
    var selectedType by remember { mutableStateOf("Обід") }
    var caloriesStr by remember { mutableStateOf("350") }
    var proteinsStr by remember { mutableStateOf("20") }
    var fatsStr by remember { mutableStateOf("10") }
    var carbsStr by remember { mutableStateOf("40") }

    val mealTypes = listOf("Сніданок", "Обід", "Вечеря", "Перекус")

    AlertDialog(
        onDismissRequest = onDismiss,
        containerColor = SleekSurface,
        title = { Text("Записати страву", fontWeight = FontWeight.Bold, color = SleekTextPrimary) },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                OutlinedTextField(
                    value = title,
                    onValueChange = { title = it },
                    label = { Text("Назва страви / перекусу") },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth()
                )

                Text("Тип прийому їжі:", fontSize = 12.sp, fontWeight = FontWeight.Bold, color = SleekTextSecondary)
                LazyRow(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                    items(mealTypes) { type ->
                        FilterChip(
                            selected = selectedType == type,
                            onClick = { selectedType = type },
                            label = { Text(type, fontSize = 12.sp) },
                            colors = FilterChipDefaults.filterChipColors(
                                selectedContainerColor = SleekPrimary,
                                selectedLabelColor = SleekOnPrimary
                            )
                        )
                    }
                }

                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    OutlinedTextField(
                        value = caloriesStr,
                        onValueChange = { caloriesStr = it },
                        label = { Text("Калорії (ккал)") },
                        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                        modifier = Modifier.weight(1f)
                    )
                    OutlinedTextField(
                        value = proteinsStr,
                        onValueChange = { proteinsStr = it },
                        label = { Text("Білки (г)") },
                        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                        modifier = Modifier.weight(1f)
                    )
                }

                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    OutlinedTextField(
                        value = fatsStr,
                        onValueChange = { fatsStr = it },
                        label = { Text("Жири (г)") },
                        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                        modifier = Modifier.weight(1f)
                    )
                    OutlinedTextField(
                        value = carbsStr,
                        onValueChange = { carbsStr = it },
                        label = { Text("Вуглеводи (г)") },
                        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                        modifier = Modifier.weight(1f)
                    )
                }
            }
        },
        confirmButton = {
            Button(
                onClick = {
                    if (title.isNotBlank()) {
                        onConfirm(
                            title,
                            selectedType,
                            caloriesStr.toIntOrNull() ?: 0,
                            proteinsStr.toIntOrNull() ?: 0,
                            fatsStr.toIntOrNull() ?: 0,
                            carbsStr.toIntOrNull() ?: 0
                        )
                    }
                },
                colors = ButtonDefaults.buttonColors(containerColor = SleekPrimary)
            ) {
                Text("Зберегти")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("Скасувати")
            }
        }
    )
}

@Composable
fun EditNutritionTargetDialog(
    currentTarget: NutritionTarget,
    onDismiss: () -> Unit,
    onConfirm: (cals: Int, prot: Int, fats: Int, carbs: Int) -> Unit
) {
    var caloriesStr by remember { mutableStateOf(currentTarget.dailyCalories.toString()) }
    var proteinsStr by remember { mutableStateOf(currentTarget.dailyProteinsGrams.toString()) }
    var fatsStr by remember { mutableStateOf(currentTarget.dailyFatsGrams.toString()) }
    var carbsStr by remember { mutableStateOf(currentTarget.dailyCarbsGrams.toString()) }

    AlertDialog(
        onDismissRequest = onDismiss,
        containerColor = SleekSurface,
        title = { Text("Налаштування денних цілей", fontWeight = FontWeight.Bold, color = SleekTextPrimary) },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                OutlinedTextField(
                    value = caloriesStr,
                    onValueChange = { caloriesStr = it },
                    label = { Text("Цільові калорії (ккал)") },
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                    modifier = Modifier.fillMaxWidth()
                )

                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    OutlinedTextField(
                        value = proteinsStr,
                        onValueChange = { proteinsStr = it },
                        label = { Text("Білки (г)") },
                        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                        modifier = Modifier.weight(1f)
                    )
                    OutlinedTextField(
                        value = fatsStr,
                        onValueChange = { fatsStr = it },
                        label = { Text("Жири (г)") },
                        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                        modifier = Modifier.weight(1f)
                    )
                }

                OutlinedTextField(
                    value = carbsStr,
                    onValueChange = { carbsStr = it },
                    label = { Text("Вуглеводи (г)") },
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                    modifier = Modifier.fillMaxWidth()
                )
            }
        },
        confirmButton = {
            Button(
                onClick = {
                    onConfirm(
                        caloriesStr.toIntOrNull() ?: 2000,
                        proteinsStr.toIntOrNull() ?: 110,
                        fatsStr.toIntOrNull() ?: 65,
                        carbsStr.toIntOrNull() ?: 240
                    )
                },
                colors = ButtonDefaults.buttonColors(containerColor = SleekPrimary)
            ) {
                Text("Зберегти цілі")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("Скасувати")
            }
        }
    )
}

fun getTodayDateString(): String {
    val sdf = java.text.SimpleDateFormat("yyyy-MM-dd", java.util.Locale.getDefault())
    return sdf.format(java.util.Date())
}
