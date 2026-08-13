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
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.AsyncImage
import com.example.data.model.DailyRecipe
import com.example.data.model.RecipeMeal
import com.example.ui.theme.*

@Composable
fun DailyRecipesScreen(
    recipes: List<DailyRecipe>,
    onRecipeClick: (RecipeMeal) -> Unit,
    onAddIngredientsToGrocery: (DailyRecipe) -> Unit,
    onStartChallengeForRecipe: (DailyRecipe) -> Unit
) {
    var selectedFilter by remember { mutableStateOf("Всі") }
    val filterOptions = listOf("Всі", "Літній сезон ☀️", "Фітнес 🏋️", "Швидкі ⚡", "Спортмастер 👟")

    val filteredRecipes = remember(selectedFilter, recipes) {
        when (selectedFilter) {
            "Літній сезон ☀️" -> recipes.filter { it.seasonTag.contains("Літній") || it.seasonTag.contains("Сезон") }
            "Фітнес 🏋️" -> recipes.filter { it.seasonTag.contains("Фітнес") || it.calories < 450 }
            "Швидкі ⚡" -> recipes.filter { it.prepTimeMinutes <= 25 }
            "Спортмастер 👟" -> recipes.filter { it.store == "Спортмастер" || it.seasonTag.contains("Спорт") }
            else -> recipes
        }
    }

    LazyColumn(
        modifier = Modifier
            .fillMaxSize()
            .testTag("daily_recipes_screen"),
        contentPadding = PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        // Banner Header
        item {
            Card(
                colors = CardDefaults.cardColors(containerColor = SleekPrimaryContainer),
                border = BorderStroke(1.dp, SleekPrimary.copy(alpha = 0.5f)),
                shape = RoundedCornerShape(20.dp),
                modifier = Modifier.fillMaxWidth()
            ) {
                Row(
                    modifier = Modifier.padding(18.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Column(modifier = Modifier.weight(1f)) {
                        Surface(
                            color = SleekPrimary,
                            shape = RoundedCornerShape(8.dp)
                        ) {
                            Text(
                                "Сьогоднішні Рецепти ☀️",
                                color = SleekOnPrimary,
                                fontWeight = FontWeight.Bold,
                                fontSize = 11.sp,
                                modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp)
                            )
                        }
                        Spacer(modifier = Modifier.height(6.dp))
                        Text(
                            "Рецепти Дня та Сезону",
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.ExtraBold,
                            color = SleekTextPrimary
                        )
                        Spacer(modifier = Modifier.height(4.dp))
                        Text(
                            "Добірка з урахуванням ваших уподобань, доступних акцій Сільпо та Спортмастер",
                            fontSize = 12.sp,
                            color = SleekTextSecondary
                        )
                    }

                    Icon(
                        Icons.Default.RestaurantMenu,
                        contentDescription = null,
                        tint = SleekPrimary,
                        modifier = Modifier.size(44.dp)
                    )
                }
            }
        }

        // Season & Category Filter Chips
        item {
            LazyRow(
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                modifier = Modifier.fillMaxWidth()
            ) {
                items(filterOptions) { opt ->
                    FilterChip(
                        selected = selectedFilter == opt,
                        onClick = { selectedFilter = opt },
                        label = { Text(opt, fontSize = 12.sp) },
                        colors = FilterChipDefaults.filterChipColors(
                            selectedContainerColor = SleekPrimary,
                            selectedLabelColor = SleekOnPrimary,
                            containerColor = SleekSurfaceVariant,
                            labelColor = SleekTextSecondary
                        ),
                        border = FilterChipDefaults.filterChipBorder(
                            enabled = true,
                            selected = selectedFilter == opt,
                            borderColor = SleekBorder
                        )
                    )
                }
            }
        }

        // Recipe Cards
        items(filteredRecipes) { recipe ->
            Card(
                colors = CardDefaults.cardColors(containerColor = SleekSurface),
                border = BorderStroke(1.dp, SleekBorder),
                shape = RoundedCornerShape(20.dp),
                elevation = CardDefaults.cardElevation(defaultElevation = 2.dp),
                modifier = Modifier
                    .fillMaxWidth()
                    .clickable {
                        // Convert to RecipeMeal for details dialog
                        val meal = RecipeMeal(
                            id = recipe.id,
                            title = recipe.title,
                            mealType = recipe.seasonTag,
                            prepTimeMinutes = recipe.prepTimeMinutes,
                            calories = recipe.calories,
                            imageUrl = recipe.imageUrl,
                            equipment = "Плита / Гриль",
                            totalCostUah = recipe.totalCostUah,
                            ingredients = recipe.ingredients,
                            instructions = recipe.instructions,
                            store = recipe.store
                        )
                        onRecipeClick(meal)
                    }
                    .testTag("daily_recipe_card_${recipe.id}")
            ) {
                Column {
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(180.dp)
                    ) {
                        AsyncImage(
                            model = recipe.imageUrl,
                            contentDescription = recipe.title,
                            contentScale = ContentScale.Crop,
                            modifier = Modifier
                                .fillMaxSize()
                                .background(SleekSurfaceVariant)
                        )

                        // Top Badges
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(12.dp),
                            horizontalArrangement = Arrangement.SpaceBetween
                        ) {
                            Surface(
                                color = SleekElevatedSurface.copy(alpha = 0.9f),
                                shape = RoundedCornerShape(10.dp)
                            ) {
                                Text(
                                    text = recipe.seasonTag,
                                    color = SleekTextPrimary,
                                    fontSize = 11.sp,
                                    fontWeight = FontWeight.Bold,
                                    modifier = Modifier.padding(horizontal = 10.dp, vertical = 4.dp)
                                )
                            }

                            Surface(
                                color = if (recipe.store == "Спортмастер") SleekAccentOrange else SleekPrimary,
                                shape = RoundedCornerShape(10.dp)
                            ) {
                                Text(
                                    text = recipe.store,
                                    color = SleekOnPrimary,
                                    fontSize = 11.sp,
                                    fontWeight = FontWeight.Bold,
                                    modifier = Modifier.padding(horizontal = 10.dp, vertical = 4.dp)
                                )
                            }
                        }

                        // Price Tag
                        Surface(
                            color = SleekSurface.copy(alpha = 0.95f),
                            shape = RoundedCornerShape(topStart = 12.dp),
                            border = BorderStroke(1.dp, SleekBorder),
                            modifier = Modifier.align(Alignment.BottomEnd)
                        ) {
                            Text(
                                text = "${recipe.totalCostUah.toInt()} ₴",
                                color = SleekPriceGreen,
                                fontSize = 16.sp,
                                fontWeight = FontWeight.ExtraBold,
                                modifier = Modifier.padding(horizontal = 12.dp, vertical = 6.dp)
                            )
                        }
                    }

                    Column(modifier = Modifier.padding(16.dp)) {
                        Text(
                            text = recipe.title,
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold,
                            color = SleekTextPrimary
                        )

                        Spacer(modifier = Modifier.height(4.dp))

                        Text(
                            text = recipe.description,
                            fontSize = 12.sp,
                            color = SleekTextSecondary,
                            maxLines = 2
                        )

                        Spacer(modifier = Modifier.height(12.dp))

                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(16.dp)
                        ) {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Icon(Icons.Default.Timer, contentDescription = null, tint = SleekTextSecondary, modifier = Modifier.size(16.dp))
                                Spacer(modifier = Modifier.width(4.dp))
                                Text("${recipe.prepTimeMinutes} хв", fontSize = 12.sp, color = SleekTextSecondary)
                            }

                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Icon(Icons.Default.LocalFireDepartment, contentDescription = null, tint = SleekAccentOrange, modifier = Modifier.size(16.dp))
                                Spacer(modifier = Modifier.width(4.dp))
                                Text("${recipe.calories} ккал", fontSize = 12.sp, color = SleekTextSecondary)
                            }

                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Icon(Icons.Default.ShoppingBasket, contentDescription = null, tint = SleekPrimary, modifier = Modifier.size(16.dp))
                                Spacer(modifier = Modifier.width(4.dp))
                                Text("${recipe.ingredients.size} інгр.", fontSize = 12.sp, color = SleekTextSecondary)
                            }
                        }

                        Spacer(modifier = Modifier.height(14.dp))

                        Divider(color = SleekBorder)

                        Spacer(modifier = Modifier.height(12.dp))

                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.spacedBy(8.dp)
                        ) {
                            OutlinedButton(
                                onClick = { onAddIngredientsToGrocery(recipe) },
                                shape = RoundedCornerShape(12.dp),
                                border = BorderStroke(1.dp, SleekPrimary),
                                modifier = Modifier.weight(1f)
                            ) {
                                Icon(Icons.Default.AddShoppingCart, contentDescription = null, tint = SleekPrimary, modifier = Modifier.size(16.dp))
                                Spacer(modifier = Modifier.width(6.dp))
                                Text("В кошик", fontSize = 12.sp, color = SleekPrimary, fontWeight = FontWeight.Bold)
                            }

                            Button(
                                onClick = { onStartChallengeForRecipe(recipe) },
                                shape = RoundedCornerShape(12.dp),
                                colors = ButtonDefaults.buttonColors(containerColor = SleekPrimary, contentColor = SleekOnPrimary),
                                modifier = Modifier.weight(1f)
                            ) {
                                Icon(Icons.Default.EmojiEvents, contentDescription = null, tint = SleekOnPrimary, modifier = Modifier.size(16.dp))
                                Spacer(modifier = Modifier.width(6.dp))
                                Text("Виклики +200", fontSize = 12.sp, color = SleekOnPrimary, fontWeight = FontWeight.Bold)
                            }
                        }
                    }
                }
            }
        }
    }
}
