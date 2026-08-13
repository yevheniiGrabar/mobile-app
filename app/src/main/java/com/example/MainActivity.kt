package com.example

import android.os.Bundle
import android.widget.Toast
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.viewModels
import androidx.compose.animation.*
import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalClipboardManager
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.example.ui.MainViewModel
import com.example.ui.dialogs.IngredientReplacementDialog
import com.example.ui.dialogs.RecipeDetailDialog
import com.example.ui.screens.ChallengesScreen
import com.example.ui.screens.DailyRecipesScreen
import com.example.ui.screens.GroceryListScreen
import com.example.ui.screens.NutritionScreen
import com.example.ui.screens.SetupScreen
import com.example.ui.screens.WeeklyMenuScreen
import com.example.ui.theme.*

class MainActivity : ComponentActivity() {

    private val viewModel: MainViewModel by viewModels()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()

        setContent {
            SilpoMenuTheme {
                MainAppScreen(viewModel = viewModel)
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MainAppScreen(viewModel: MainViewModel) {
    val context = LocalContext.current
    val clipboardManager = LocalClipboardManager.current

    val userPrefs by viewModel.userPreferences.collectAsStateWithLifecycle()
    val weeklyMealPlan by viewModel.weeklyMealPlan.collectAsStateWithLifecycle()
    val groceryList by viewModel.groceryList.collectAsStateWithLifecycle()
    val dailyRecipes by viewModel.dailyRecipes.collectAsStateWithLifecycle()
    val challenges by viewModel.challenges.collectAsStateWithLifecycle()
    val rewards by viewModel.rewards.collectAsStateWithLifecycle()
    val userPoints by viewModel.userPoints.collectAsStateWithLifecycle()
    val selectedDateString by viewModel.selectedDateString.collectAsStateWithLifecycle()
    val loggedMeals by viewModel.loggedMeals.collectAsStateWithLifecycle()
    val nutritionTarget by viewModel.nutritionTarget.collectAsStateWithLifecycle()
    val mcpStatus by viewModel.silpoMcpStatus.collectAsStateWithLifecycle()
    val isLoading by viewModel.isLoading.collectAsStateWithLifecycle()
    val activeScreen by viewModel.activeScreen.collectAsStateWithLifecycle()
    val selectedDayIndex by viewModel.selectedDayIndex.collectAsStateWithLifecycle()
    val mealDetailTarget by viewModel.selectedMealForDetail.collectAsStateWithLifecycle()
    val ingredientReplacementTarget by viewModel.ingredientReplacementTarget.collectAsStateWithLifecycle()
    val groceryReplacementTarget by viewModel.groceryReplacementTarget.collectAsStateWithLifecycle()
    val toastMessage by viewModel.toastMessage.collectAsStateWithLifecycle()

    LaunchedEffect(toastMessage) {
        toastMessage?.let { msg ->
            Toast.makeText(context, msg, Toast.LENGTH_SHORT).show()
            viewModel.clearToast()
        }
    }

    Scaffold(
        modifier = Modifier.fillMaxSize(),
        topBar = {
            TopAppBar(
                title = {
                    Column {
                        Text(
                            text = when (activeScreen) {
                                0 -> "Сільпо & Спортмастер: Бюджет"
                                1 -> "Тижневе Меню"
                                2 -> "Розумний Список Покупок"
                                3 -> "Рецепти Дня"
                                4 -> "Виклики та Нагороди"
                                5 -> "Трекер Ккал & Нутрієнтів"
                                else -> "Сільпо Меню"
                            },
                            fontWeight = FontWeight.Bold,
                            fontSize = 17.sp,
                            color = SleekTextPrimary
                        )
                        Text(
                            text = "MSP Сервер: Сільпо + Спортмастер",
                            fontSize = 11.sp,
                            color = SleekTextSecondary
                        )
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = SleekBg
                ),
                actions = {
                    Surface(
                        color = SleekAccentOrange.copy(alpha = 0.15f),
                        shape = MaterialTheme.shapes.small,
                        modifier = Modifier.padding(end = 6.dp)
                    ) {
                        Row(
                            verticalAlignment = androidx.compose.ui.Alignment.CenterVertically,
                            modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp)
                        ) {
                            Icon(Icons.Default.Stars, contentDescription = null, tint = SleekAccentOrange, modifier = Modifier.size(14.dp))
                            Spacer(modifier = Modifier.width(4.dp))
                            Text(
                                text = "$userPoints б",
                                color = SleekAccentOrange,
                                fontWeight = FontWeight.Bold,
                                fontSize = 12.sp
                            )
                        }
                    }

                    Surface(
                        color = SleekPrimaryContainer,
                        shape = MaterialTheme.shapes.small,
                        modifier = Modifier.padding(end = 12.dp)
                    ) {
                        Text(
                            text = "${userPrefs.budgetUah.toInt()} ₴",
                            color = SleekPrimary,
                            fontWeight = FontWeight.Bold,
                            fontSize = 12.sp,
                            modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp)
                        )
                    }
                }
            )
        },
        bottomBar = {
            NavigationBar(
                containerColor = SleekSurface,
                modifier = Modifier.windowInsetsPadding(WindowInsets.navigationBars)
            ) {
                NavigationBarItem(
                    selected = activeScreen == 0,
                    onClick = { viewModel.setScreen(0) },
                    icon = { Icon(Icons.Default.Tune, contentDescription = "Setup") },
                    label = { Text("Налаштування", fontSize = 10.sp) },
                    colors = NavigationBarItemDefaults.colors(
                        selectedIconColor = SleekOnPrimary,
                        selectedTextColor = SleekPrimary,
                        indicatorColor = SleekPrimary,
                        unselectedIconColor = SleekTextMuted,
                        unselectedTextColor = SleekTextMuted
                    ),
                    modifier = Modifier.testTag("nav_setup")
                )
                NavigationBarItem(
                    selected = activeScreen == 1,
                    onClick = { viewModel.setScreen(1) },
                    icon = { Icon(Icons.Default.MenuBook, contentDescription = "Weekly Menu") },
                    label = { Text("Меню", fontSize = 10.sp) },
                    colors = NavigationBarItemDefaults.colors(
                        selectedIconColor = SleekOnPrimary,
                        selectedTextColor = SleekPrimary,
                        indicatorColor = SleekPrimary,
                        unselectedIconColor = SleekTextMuted,
                        unselectedTextColor = SleekTextMuted
                    ),
                    modifier = Modifier.testTag("nav_menu")
                )
                NavigationBarItem(
                    selected = activeScreen == 2,
                    onClick = { viewModel.setScreen(2) },
                    icon = {
                        BadgedBox(
                            badge = {
                                val unchecked = groceryList.count { !it.isChecked }
                                if (unchecked > 0) {
                                    Badge(containerColor = SleekAccentOrange, contentColor = SleekOnPrimary) { Text("$unchecked") }
                                }
                            }
                        ) {
                            Icon(Icons.Default.ShoppingCart, contentDescription = "Shopping Checklist")
                        }
                    },
                    label = { Text("Покупки", fontSize = 10.sp) },
                    colors = NavigationBarItemDefaults.colors(
                        selectedIconColor = SleekOnPrimary,
                        selectedTextColor = SleekPrimary,
                        indicatorColor = SleekPrimary,
                        unselectedIconColor = SleekTextMuted,
                        unselectedTextColor = SleekTextMuted
                    ),
                    modifier = Modifier.testTag("nav_shopping")
                )
                NavigationBarItem(
                    selected = activeScreen == 3,
                    onClick = { viewModel.setScreen(3) },
                    icon = { Icon(Icons.Default.WbSunny, contentDescription = "Recipes of the Day") },
                    label = { Text("Рецепти дня", fontSize = 10.sp) },
                    colors = NavigationBarItemDefaults.colors(
                        selectedIconColor = SleekOnPrimary,
                        selectedTextColor = SleekPrimary,
                        indicatorColor = SleekPrimary,
                        unselectedIconColor = SleekTextMuted,
                        unselectedTextColor = SleekTextMuted
                    ),
                    modifier = Modifier.testTag("nav_daily_recipes")
                )
                NavigationBarItem(
                    selected = activeScreen == 4,
                    onClick = { viewModel.setScreen(4) },
                    icon = { Icon(Icons.Default.EmojiEvents, contentDescription = "Culinary Challenges") },
                    label = { Text("Виклики", fontSize = 10.sp) },
                    colors = NavigationBarItemDefaults.colors(
                        selectedIconColor = SleekOnPrimary,
                        selectedTextColor = SleekPrimary,
                        indicatorColor = SleekPrimary,
                        unselectedIconColor = SleekTextMuted,
                        unselectedTextColor = SleekTextMuted
                    ),
                    modifier = Modifier.testTag("nav_challenges")
                )
                NavigationBarItem(
                    selected = activeScreen == 5,
                    onClick = { viewModel.setScreen(5) },
                    icon = { Icon(Icons.Default.LocalFireDepartment, contentDescription = "Calorie & Nutrient Tracker") },
                    label = { Text("Трекер", fontSize = 10.sp) },
                    colors = NavigationBarItemDefaults.colors(
                        selectedIconColor = SleekOnPrimary,
                        selectedTextColor = SleekPrimary,
                        indicatorColor = SleekPrimary,
                        unselectedIconColor = SleekTextMuted,
                        unselectedTextColor = SleekTextMuted
                    ),
                    modifier = Modifier.testTag("nav_nutrition")
                )
            }
        }
    ) { innerPadding ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
        ) {
            AnimatedContent(
                targetState = activeScreen,
                transitionSpec = {
                    if (targetState > initialState) {
                        (slideInHorizontally { width -> width / 4 } + fadeIn(animationSpec = androidx.compose.animation.core.tween(280))).togetherWith(
                            slideOutHorizontally { width -> -width / 4 } + fadeOut(animationSpec = androidx.compose.animation.core.tween(280))
                        )
                    } else {
                        (slideInHorizontally { width -> -width / 4 } + fadeIn(animationSpec = androidx.compose.animation.core.tween(280))).togetherWith(
                            slideOutHorizontally { width -> width / 4 } + fadeOut(animationSpec = androidx.compose.animation.core.tween(280))
                        )
                    }
                },
                label = "screen_transition"
            ) { target ->
                when (target) {
                    0 -> SetupScreen(
                        userPrefs = userPrefs,
                        mcpStatus = mcpStatus,
                        isLoading = isLoading,
                        onBudgetChange = viewModel::updateBudget,
                        onPeopleCountChange = viewModel::updatePeopleCount,
                        onTogglePreference = viewModel::toggleDietaryPreference,
                        onToggleAllergy = viewModel::toggleAllergy,
                        onToggleEquipment = viewModel::toggleEquipment,
                        onUpdateToken = viewModel::updateSilpoToken,
                        onGenerateClick = viewModel::generateMenu
                    )

                    1 -> WeeklyMenuScreen(
                        weeklyMealPlan = weeklyMealPlan,
                        selectedDayIndex = selectedDayIndex,
                        onSelectDay = viewModel::setSelectedDay,
                        onMealClick = viewModel::setMealDetail,
                        onReplaceIngredientClick = { meal, ing ->
                            viewModel.setIngredientReplacementTarget(meal, ing)
                        },
                        onGoToShoppingList = { viewModel.setScreen(2) }
                    )

                    2 -> GroceryListScreen(
                        groceryList = groceryList,
                        onToggleCheck = viewModel::toggleGroceryCheck,
                        onReplaceClick = viewModel::setGroceryReplacementTarget,
                        onCheckoutClick = viewModel::checkoutSilpoCart
                    )

                    3 -> DailyRecipesScreen(
                        recipes = dailyRecipes,
                        onRecipeClick = viewModel::setMealDetail,
                        onAddIngredientsToGrocery = viewModel::addDailyRecipeToGrocery,
                        onStartChallengeForRecipe = {
                            viewModel.setScreen(4)
                        }
                    )

                    4 -> ChallengesScreen(
                        userPoints = userPoints,
                        challenges = challenges,
                        rewards = rewards,
                        onAcceptChallenge = viewModel::acceptChallenge,
                        onCompleteChallenge = viewModel::completeChallenge,
                        onRedeemReward = viewModel::redeemReward,
                        onCopyCode = { code ->
                            clipboardManager.setText(AnnotatedString(code))
                            Toast.makeText(context, "Промокод $code скопійовано!", Toast.LENGTH_SHORT).show()
                        }
                    )

                    5 -> NutritionScreen(
                        selectedDateString = selectedDateString,
                        loggedMeals = loggedMeals,
                        nutritionTarget = nutritionTarget,
                        weeklyMealPlan = weeklyMealPlan,
                        dailyRecipes = dailyRecipes,
                        onSelectPreviousDate = viewModel::selectPreviousDate,
                        onSelectNextDate = viewModel::selectNextDate,
                        onSelectToday = viewModel::selectToday,
                        onLogMealFromRecipeMeal = viewModel::logMealFromRecipe,
                        onLogMealFromDailyRecipe = viewModel::logMealFromDailyRecipe,
                        onLogCustomMeal = viewModel::logCustomMeal,
                        onDeleteLoggedMeal = viewModel::deleteLoggedMeal,
                        onUpdateNutritionTarget = viewModel::updateNutritionTarget
                    )
                }
            }
        }
    }

    // Modal: Meal Detail Dialog
    mealDetailTarget?.let { meal ->
        RecipeDetailDialog(
            meal = meal,
            onReplaceIngredientClick = { ing ->
                viewModel.setIngredientReplacementTarget(meal, ing)
            },
            onDismiss = { viewModel.setMealDetail(null) },
            onLogToNutritionTracker = viewModel::logMealFromRecipe
        )
    }

    // Modal: Ingredient Replacement Dialog from Meal
    ingredientReplacementTarget?.let { (meal, ing) ->
        IngredientReplacementDialog(
            ingredientName = ing.name,
            currentPriceUah = ing.priceUah,
            options = ing.alternatives,
            onSelectOption = { option ->
                viewModel.replaceIngredientInMeal(meal.id, ing.id, option)
            },
            onDismiss = { viewModel.setIngredientReplacementTarget(null, null) }
        )
    }

    // Modal: Grocery Replacement Dialog from Shopping List
    groceryReplacementTarget?.let { grocery ->
        val alternatives = viewModel.silpoMcpClient.findCheaperAlternatives(grocery.name, grocery.priceUah)
        IngredientReplacementDialog(
            ingredientName = grocery.name,
            currentPriceUah = grocery.priceUah,
            options = alternatives,
            onSelectOption = { option ->
                viewModel.replaceGroceryItem(grocery.id, option)
            },
            onDismiss = { viewModel.setGroceryReplacementTarget(null) }
        )
    }
}


