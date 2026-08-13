package com.example.ui.screens

import androidx.compose.animation.*
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
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
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.AsyncImage
import com.example.data.model.DayPlan
import com.example.data.model.Ingredient
import com.example.data.model.RecipeMeal
import com.example.data.model.WeeklyMealPlan
import com.example.ui.theme.*

@Composable
fun WeeklyMenuScreen(
    weeklyMealPlan: WeeklyMealPlan?,
    selectedDayIndex: Int,
    onSelectDay: (Int) -> Unit,
    onMealClick: (RecipeMeal) -> Unit,
    onReplaceIngredientClick: (RecipeMeal, Ingredient) -> Unit,
    onGoToShoppingList: () -> Unit
) {
    if (weeklyMealPlan == null) {
        Box(
            modifier = Modifier.fillMaxSize(),
            contentAlignment = Alignment.Center
        ) {
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Icon(
                    Icons.Default.RestaurantMenu,
                    contentDescription = null,
                    modifier = Modifier.size(64.dp),
                    tint = SilpoOrangePrimary
                )
                Spacer(modifier = Modifier.height(16.dp))
                Text("Меню ще не згенеровано.", fontWeight = FontWeight.Bold)
            }
        }
        return
    }

    val selectedDayPlan = weeklyMealPlan.days.find { it.dayIndex == selectedDayIndex } ?: weeklyMealPlan.days.firstOrNull()
    val savingsUah = (weeklyMealPlan.budgetUah - weeklyMealPlan.totalPlanCostUah).coerceAtLeast(0f)

    LazyColumn(
        modifier = Modifier
            .fillMaxSize()
            .padding(horizontal = 16.dp),
        contentPadding = PaddingValues(top = 16.dp, bottom = 100.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        // Summary Card
        item {
            Card(
                colors = CardDefaults.cardColors(
                    containerColor = SleekSurface
                ),
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
                        Column {
                            Text(
                                "Разом за 7 днів",
                                color = SleekTextSecondary,
                                fontSize = 12.sp
                            )
                            Text(
                                "${weeklyMealPlan.totalPlanCostUah.toInt()} ₴",
                                color = SleekPriceGreen,
                                fontWeight = FontWeight.ExtraBold,
                                fontSize = 26.sp
                            )
                        }

                        Surface(
                            color = SleekPrimaryContainer,
                            shape = RoundedCornerShape(12.dp)
                        ) {
                            Text(
                                text = "Бюджет: ${weeklyMealPlan.budgetUah.toInt()} ₴",
                                color = SleekPrimary,
                                fontWeight = FontWeight.Bold,
                                fontSize = 13.sp,
                                modifier = Modifier.padding(horizontal = 12.dp, vertical = 6.dp)
                            )
                        }
                    }

                    Spacer(modifier = Modifier.height(12.dp))

                    val progress = (weeklyMealPlan.totalPlanCostUah / weeklyMealPlan.budgetUah).coerceIn(0f, 1f)
                    LinearProgressIndicator(
                        progress = { progress },
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(8.dp)
                            .clip(RoundedCornerShape(4.dp)),
                        color = if (weeklyMealPlan.totalPlanCostUah <= weeklyMealPlan.budgetUah) SleekPriceGreen else Color(0xFFEF5350),
                        trackColor = SleekBorder
                    )

                    Spacer(modifier = Modifier.height(8.dp))

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            text = "Заощаджено на акціях Сільпо: ${savingsUah.toInt()} ₴",
                            color = SleekAccentOrange,
                            fontSize = 12.sp,
                            fontWeight = FontWeight.Medium
                        )

                        TextButton(
                            onClick = onGoToShoppingList,
                            contentPadding = PaddingValues(0.dp)
                        ) {
                            Icon(
                                Icons.Default.ShoppingCart,
                                contentDescription = null,
                                tint = SleekPrimary,
                                modifier = Modifier.size(16.dp)
                            )
                            Spacer(modifier = Modifier.width(4.dp))
                            Text("Список покупок >", color = SleekPrimary, fontSize = 13.sp)
                        }
                    }
                }
            }
        }

        // Days Horizontal Bar
        item {
            LazyRow(
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                modifier = Modifier.fillMaxWidth()
            ) {
                items(weeklyMealPlan.days) { day ->
                    val isSelected = day.dayIndex == selectedDayIndex
                    Surface(
                        onClick = { onSelectDay(day.dayIndex) },
                        shape = RoundedCornerShape(16.dp),
                        color = if (isSelected) SleekPrimary else SleekSurface,
                        border = BorderStroke(1.dp, if (isSelected) SleekPrimary else SleekBorder),
                        shadowElevation = if (isSelected) 4.dp else 0.dp,
                        modifier = Modifier.testTag("day_tab_${day.dayIndex}")
                    ) {
                        Column(
                            horizontalAlignment = Alignment.CenterHorizontally,
                            modifier = Modifier.padding(horizontal = 14.dp, vertical = 10.dp)
                        ) {
                            Text(
                                text = day.dayName.take(3),
                                fontWeight = FontWeight.Bold,
                                color = if (isSelected) SleekOnPrimary else SleekTextPrimary,
                                fontSize = 14.sp
                            )
                            Spacer(modifier = Modifier.height(2.dp))
                            Text(
                                text = "${day.totalDayCostUah.toInt()} ₴",
                                fontSize = 11.sp,
                                color = if (isSelected) SleekOnPrimary.copy(0.8f) else SleekTextSecondary
                            )
                        }
                    }
                }
            }
        }

        // Selected Day Meals Header
        item {
            if (selectedDayPlan != null) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = "Страви на ${selectedDayPlan.dayName}",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold,
                        color = SleekTextPrimary
                    )
                    Text(
                        text = "За день: ${selectedDayPlan.totalDayCostUah.toInt()} ₴",
                        color = SleekPriceGreen,
                        fontWeight = FontWeight.Bold,
                        fontSize = 14.sp
                    )
                }
            }
        }

        // Meals List
        if (selectedDayPlan != null) {
            items(selectedDayPlan.meals) { meal ->
                Card(
                    colors = CardDefaults.cardColors(
                        containerColor = SleekSurface
                    ),
                    border = BorderStroke(1.dp, SleekBorder),
                    shape = RoundedCornerShape(18.dp),
                    elevation = CardDefaults.cardElevation(defaultElevation = 2.dp),
                    modifier = Modifier
                        .fillMaxWidth()
                        .clickable { onMealClick(meal) }
                        .testTag("meal_card_${meal.id}")
                ) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(12.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        // Image Thumbnail
                        Box(
                            modifier = Modifier
                                .size(90.dp)
                                .clip(RoundedCornerShape(14.dp))
                                .background(SleekSurfaceVariant)
                        ) {
                            AsyncImage(
                                model = meal.imageUrl,
                                contentDescription = meal.title,
                                contentScale = ContentScale.Crop,
                                modifier = Modifier.fillMaxSize()
                            )

                            // Meal type badge
                            Surface(
                                color = SleekElevatedSurface.copy(alpha = 0.9f),
                                shape = RoundedCornerShape(bottomEnd = 8.dp),
                                modifier = Modifier.align(Alignment.TopStart)
                            ) {
                                Text(
                                    text = meal.mealType,
                                    color = SleekTextPrimary,
                                    fontSize = 10.sp,
                                    fontWeight = FontWeight.Bold,
                                    modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp)
                                )
                            }
                        }

                        Spacer(modifier = Modifier.width(12.dp))

                        Column(modifier = Modifier.weight(1f)) {
                            Text(
                                text = meal.title,
                                fontWeight = FontWeight.Bold,
                                fontSize = 15.sp,
                                color = SleekTextPrimary,
                                maxLines = 2,
                                overflow = TextOverflow.Ellipsis
                            )

                            Spacer(modifier = Modifier.height(4.dp))

                            Row(
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.spacedBy(8.dp)
                            ) {
                                Surface(
                                    color = SleekSurfaceVariant,
                                    shape = RoundedCornerShape(6.dp)
                                ) {
                                    Row(
                                        verticalAlignment = Alignment.CenterVertically,
                                        modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp)
                                    ) {
                                        Icon(
                                            Icons.Default.Kitchen,
                                            contentDescription = null,
                                            modifier = Modifier.size(12.dp),
                                            tint = SleekPriceGreen
                                        )
                                        Spacer(modifier = Modifier.width(4.dp))
                                        Text(
                                            text = meal.equipment,
                                            fontSize = 11.sp,
                                            fontWeight = FontWeight.Medium,
                                            color = SleekTextSecondary
                                        )
                                    }
                                }

                                Row(verticalAlignment = Alignment.CenterVertically) {
                                    Icon(
                                        Icons.Default.Timer,
                                        contentDescription = null,
                                        modifier = Modifier.size(12.dp),
                                        tint = SleekTextMuted
                                    )
                                    Spacer(modifier = Modifier.width(2.dp))
                                    Text(
                                        text = "${meal.prepTimeMinutes} хв",
                                        fontSize = 11.sp,
                                        color = SleekTextMuted
                                    )
                                }
                            }

                            Spacer(modifier = Modifier.height(6.dp))

                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Text(
                                    text = "${meal.totalCostUah.toInt()} ₴",
                                    color = SleekPriceGreen,
                                    fontWeight = FontWeight.ExtraBold,
                                    fontSize = 16.sp
                                )

                                OutlinedButton(
                                    onClick = {
                                        val targetIng = meal.ingredients.firstOrNull { it.alternatives.isNotEmpty() } ?: meal.ingredients.firstOrNull()
                                        if (targetIng != null) {
                                            onReplaceIngredientClick(meal, targetIng)
                                        }
                                    },
                                    border = BorderStroke(1.dp, SleekPrimary),
                                    colors = ButtonDefaults.outlinedButtonColors(contentColor = SleekPrimary),
                                    shape = RoundedCornerShape(10.dp),
                                    contentPadding = PaddingValues(horizontal = 10.dp, vertical = 4.dp),
                                    modifier = Modifier.height(32.dp)
                                ) {
                                    Icon(
                                        Icons.Default.SwapHoriz,
                                        contentDescription = "Replace",
                                        modifier = Modifier.size(14.dp)
                                    )
                                    Spacer(modifier = Modifier.width(4.dp))
                                    Text("Замінити ₴", fontSize = 11.sp)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
