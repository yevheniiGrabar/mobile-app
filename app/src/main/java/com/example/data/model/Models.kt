package com.example.data.model

import androidx.room.Entity
import androidx.room.PrimaryKey

data class UserPreferences(
    val budgetUah: Float = 2500f,
    val peopleCount: Int = 2,
    val dietaryPreferences: List<String> = emptyList(),
    val allergies: List<String> = emptyList(),
    val kitchenEquipment: List<String> = listOf("Плита", "Духовка", "Мікрохвильовка"),
    val cookTimeLimit: String = "Будь-який"
)

data class ReplacementOption(
    val id: String,
    val name: String,
    val priceUah: Float,
    val brand: String,
    val priceDifferenceUah: Float,
    val reason: String,
    val store: String = "Сільпо"
)

data class Ingredient(
    val id: String,
    val name: String,
    val quantity: Float,
    val unit: String,
    val priceUah: Float,
    val department: String,
    val store: String = "Сільпо", // "Сільпо", "Спортмастер", "Партнери"
    val silpoBrand: String? = null,
    val alternatives: List<ReplacementOption> = emptyList()
)

data class RecipeMeal(
    val id: String,
    val title: String,
    val mealType: String, // "Сніданок", "Обід", "Вечеря", "Перекус"
    val prepTimeMinutes: Int,
    val calories: Int,
    val imageUrl: String,
    val equipment: String, // "Духовка", "Мікрохвильовка", "Плита", "Мультиварка"
    val totalCostUah: Float,
    val ingredients: List<Ingredient>,
    val instructions: List<String>,
    val store: String = "Сільпо",
    val proteinsGrams: Int = (calories * 0.25f / 4f).toInt().coerceAtLeast(8),
    val fatsGrams: Int = (calories * 0.30f / 9f).toInt().coerceAtLeast(5),
    val carbsGrams: Int = (calories * 0.45f / 4f).toInt().coerceAtLeast(15)
)

data class DayPlan(
    val dayIndex: Int, // 1..7
    val dayName: String, // "Понеділок", etc.
    val meals: List<RecipeMeal>,
    val totalDayCostUah: Float
)

data class WeeklyMealPlan(
    val days: List<DayPlan>,
    val totalPlanCostUah: Float,
    val budgetUah: Float,
    val peopleCount: Int
)

data class DailyRecipe(
    val id: String,
    val title: String,
    val description: String,
    val seasonTag: String, // "Літній сезон ☀️", "Фітнес 🏋️", "Швидка вечеря ⚡"
    val prepTimeMinutes: Int,
    val calories: Int,
    val totalCostUah: Float,
    val imageUrl: String,
    val ingredients: List<Ingredient>,
    val instructions: List<String>,
    val store: String = "Сільпо",
    val proteinsGrams: Int = (calories * 0.25f / 4f).toInt().coerceAtLeast(8),
    val fatsGrams: Int = (calories * 0.30f / 9f).toInt().coerceAtLeast(5),
    val carbsGrams: Int = (calories * 0.45f / 4f).toInt().coerceAtLeast(15)
)

@Entity(tableName = "logged_meals")
data class LoggedMealEntity(
    @PrimaryKey val id: String,
    val dateString: String, // YYYY-MM-DD
    val mealTitle: String,
    val mealType: String, // "Сніданок", "Обід", "Вечеря", "Перекус"
    val calories: Int,
    val proteinsGrams: Int,
    val fatsGrams: Int,
    val carbsGrams: Int,
    val recipeId: String? = null,
    val timestamp: Long = System.currentTimeMillis()
)

data class NutritionTarget(
    val dailyCalories: Int = 2000,
    val dailyProteinsGrams: Int = 110,
    val dailyFatsGrams: Int = 65,
    val dailyCarbsGrams: Int = 240
)

@Entity(tableName = "grocery_items")
data class GroceryItemEntity(
    @PrimaryKey val id: String,
    val name: String,
    val quantity: String,
    val priceUah: Float,
    val department: String,
    val store: String = "Сільпо", // "Сільпо", "Спортмастер", "Партнери"
    val isChecked: Boolean = false,
    val isReplaced: Boolean = false,
    val originalName: String? = null,
    val silpoCode: String? = null
)

@Entity(tableName = "culinary_challenges")
data class CulinaryChallengeEntity(
    @PrimaryKey val id: String,
    val title: String,
    val description: String,
    val rewardPoints: Int,
    val badgeIconName: String = "ic_challenge",
    val requirementType: String = "general", // "5_ingredients", "new_vegetable", "protein_30g", "budget_150"
    val isAccepted: Boolean = false,
    val isCompleted: Boolean = false
)


@Entity(tableName = "user_rewards")
data class RewardOfferEntity(
    @PrimaryKey val id: String,
    val title: String,
    val partner: String, // "Спортмастер", "Сільпо", "Шеф-Повар"
    val pointsCost: Int,
    val discountCode: String,
    val description: String,
    val isRedeemed: Boolean = false
)

@Entity(tableName = "user_settings")
data class UserSettingsEntity(
    @PrimaryKey val id: Int = 1,
    val budgetUah: Float,
    val peopleCount: Int,
    val preferencesJson: String,
    val allergiesJson: String,
    val equipmentJson: String,
    val rewardPoints: Int = 250
)

data class SilpoMcpStatus(
    val serverUrl: String = "https://mcp.sportmaster.ua / mcp.silpo.ua",
    val isConnected: Boolean = true,
    val isAuthorized: Boolean = false,
    val bearerToken: String? = null,
    val userAccount: String = "Власний Рахунок / Спортмастер Клуб",
    val bonusPoints: Int = 1240,
    val statusMessage: String = "Сільпо & Спортмастер MSP: Активні та синхронізовані"
)

