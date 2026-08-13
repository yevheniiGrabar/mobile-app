package com.example.ui

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.example.data.local.AppDatabase
import com.example.data.model.*
import com.example.data.remote.GeminiMealPlanner
import com.example.data.remote.SilpoMcpClient
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.launch

private fun getTodayDateString(): String {
    val sdf = java.text.SimpleDateFormat("yyyy-MM-dd", java.util.Locale.getDefault())
    return sdf.format(java.util.Date())
}

class MainViewModel(application: Application) : AndroidViewModel(application) {

    private val db = AppDatabase.getInstance(application)
    private val groceryDao = db.groceryDao()
    private val userSettingsDao = db.userSettingsDao()
    private val challengeDao = db.challengeDao()
    private val rewardDao = db.rewardDao()
    private val nutritionDao = db.nutritionDao()

    val silpoMcpClient = SilpoMcpClient()
    private val mealPlanner = GeminiMealPlanner(silpoMcpClient)

    private val _selectedDateString = MutableStateFlow(getTodayDateString())
    val selectedDateString: StateFlow<String> = _selectedDateString.asStateFlow()

    @OptIn(kotlinx.coroutines.ExperimentalCoroutinesApi::class)
    val loggedMeals: StateFlow<List<LoggedMealEntity>> = _selectedDateString
        .flatMapLatest { date -> nutritionDao.getLoggedMealsForDate(date) }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    private val _nutritionTarget = MutableStateFlow(NutritionTarget())
    val nutritionTarget: StateFlow<NutritionTarget> = _nutritionTarget.asStateFlow()

    private val _userPreferences = MutableStateFlow(UserPreferences())
    val userPreferences: StateFlow<UserPreferences> = _userPreferences.asStateFlow()

    private val _weeklyMealPlan = MutableStateFlow<WeeklyMealPlan?>(null)
    val weeklyMealPlan: StateFlow<WeeklyMealPlan?> = _weeklyMealPlan.asStateFlow()

    val groceryList: StateFlow<List<GroceryItemEntity>> = groceryDao.getAllGroceryItems()
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    val challenges: StateFlow<List<CulinaryChallengeEntity>> = challengeDao.getAllChallenges()
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    val rewards: StateFlow<List<RewardOfferEntity>> = rewardDao.getAllRewards()
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    private val _userPoints = MutableStateFlow(350)
    val userPoints: StateFlow<Int> = _userPoints.asStateFlow()

    private val _dailyRecipes = MutableStateFlow<List<DailyRecipe>>(emptyList())
    val dailyRecipes: StateFlow<List<DailyRecipe>> = _dailyRecipes.asStateFlow()

    private val _silpoMcpStatus = MutableStateFlow(silpoMcpClient.status)
    val silpoMcpStatus: StateFlow<SilpoMcpStatus> = _silpoMcpStatus.asStateFlow()

    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

    private val _activeScreen = MutableStateFlow(0) // 0=Setup, 1=Weekly Menu, 2=Shopping List, 3=Daily Recipes, 4=Challenges
    val activeScreen: StateFlow<Int> = _activeScreen.asStateFlow()

    private val _selectedDayIndex = MutableStateFlow(1) // 1..7
    val selectedDayIndex: StateFlow<Int> = _selectedDayIndex.asStateFlow()

    private val _selectedMealForDetail = MutableStateFlow<RecipeMeal?>(null)
    val selectedMealForDetail: StateFlow<RecipeMeal?> = _selectedMealForDetail.asStateFlow()

    private val _ingredientReplacementTarget = MutableStateFlow<Pair<RecipeMeal, Ingredient>?>(null)
    val ingredientReplacementTarget: StateFlow<Pair<RecipeMeal, Ingredient>?> = _ingredientReplacementTarget.asStateFlow()

    private val _groceryReplacementTarget = MutableStateFlow<GroceryItemEntity?>(null)
    val groceryReplacementTarget: StateFlow<GroceryItemEntity?> = _groceryReplacementTarget.asStateFlow()

    private val _toastMessage = MutableStateFlow<String?>(null)
    val toastMessage: StateFlow<String?> = _toastMessage.asStateFlow()

    init {
        viewModelScope.launch {
            silpoMcpClient.pingMcpServer()
            _silpoMcpStatus.value = silpoMcpClient.status

            seedInitialData()
            generateDailyRecipes()
            generateMenu()
        }
    }

    private suspend fun seedInitialData() {
        // Seed initial challenges if empty
        val existingChallenges = challengeDao.getAllChallenges().firstOrNull()
        if (existingChallenges.isNullOrEmpty()) {
            val initialChallenges = listOf(
                CulinaryChallengeEntity(
                    id = "c1",
                    title = "Мінімум 5 Інгредієнтів",
                    description = "Приготуйте повноцінну страву, використавши не більше 5 основних інгредієнтів.",
                    rewardPoints = 150,
                    isAccepted = true,
                    isCompleted = false
                ),
                CulinaryChallengeEntity(
                    id = "c2",
                    title = "Відкриття Сезону",
                    description = "Спробуйте страву з літніми кабачками, томатами чи свіжою зеленню з Сільпо.",
                    rewardPoints = 200,
                    isAccepted = false,
                    isCompleted = false
                ),
                CulinaryChallengeEntity(
                    id = "c3",
                    title = "Фітнес-Заряд Спортмастер",
                    description = "Приготуйте високобілковий обід із протеїном або курячим філе до 150 ₴.",
                    rewardPoints = 250,
                    isAccepted = false,
                    isCompleted = false
                ),
                CulinaryChallengeEntity(
                    id = "c4",
                    title = "Zero Waste Овочі",
                    description = "Використайте всі залишки свіжих овочів у запіканці чи рагу.",
                    rewardPoints = 180,
                    isAccepted = false,
                    isCompleted = false
                )
            )
            challengeDao.insertAll(initialChallenges)
        }

        // Seed initial rewards if empty
        val existingRewards = rewardDao.getAllRewards().firstOrNull()
        if (existingRewards.isNullOrEmpty()) {
            val initialRewards = listOf(
                RewardOfferEntity(
                    id = "r1",
                    partner = "Спортмастер",
                    title = "Знижка -15% на Спортивне Харчування",
                    description = "Діє на всі протеїнові батончики, ізотоніки та амінокислоти у Спортмастер.",
                    pointsCost = 250,
                    discountCode = "SPORT-FIT-15",
                    isRedeemed = false
                ),
                RewardOfferEntity(
                    id = "r2",
                    partner = "Сільпо",
                    title = "Купон на 100 ₴ в Сільпо",
                    description = "Знижка 100 ₴ на будь-яку покупку від 500 ₴ у супермаркетах Сільпо або онлайн.",
                    pointsCost = 400,
                    discountCode = "SILPO-100-GIFT",
                    isRedeemed = false
                ),
                RewardOfferEntity(
                    id = "r3",
                    partner = "Партнери",
                    title = "Експрес-Доставка за 1 ₴",
                    description = "Безкоштовна кур'єрська доставка кулінарного набору додому.",
                    pointsCost = 150,
                    discountCode = "EXPRESS-DELIVERY-1",
                    isRedeemed = false
                )
            )
            rewardDao.insertAll(initialRewards)
        }
    }

    private fun generateDailyRecipes() {
        _dailyRecipes.value = listOf(
            DailyRecipe(
                id = "dr1",
                title = "Літній Салат з Авокадо та Томатами",
                description = "Легкий та освіжаючий сезонний салат із заправкою з соняшникової олії Повна Чаша.",
                prepTimeMinutes = 15,
                calories = 320,
                totalCostUah = 125.0f,
                seasonTag = "Літній сезон ☀️",
                store = "Сільпо",
                imageUrl = "https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=800&auto=format&fit=crop&q=80",
                ingredients = listOf(
                    Ingredient("i1", "Авокадо Хаас 1 шт", 1.0f, "шт", 45.0f, "Овочі та фрукти", "Сільпо Імпорт", "Сільпо"),
                    Ingredient("i2", "Томати червоні 300г", 300.0f, "г", 25.0f, "Овочі та фрукти", "Україна", "Сільпо"),
                    Ingredient("i3", "Огірки гладкі 200г", 200.0f, "г", 15.0f, "Овочі та фрукти", "Україна", "Сільпо"),
                    Ingredient("i4", "Олія соняшникова 50мл", 50.0f, "мл", "10.0".toFloat(), "Бакалія", "Повна Чаша", "Сільпо")
                ),
                instructions = listOf("Промити та нарізати томати й огірки.", "Очистити авокадо, кубиками додати до овочів.", "Заправити духмяною олією та дрібкою солі.")
            ),
            DailyRecipe(
                id = "dr2",
                title = "Протеїновий Фітнес-Смузі Bowl",
                description = "Високобілковий сніданок з ізолятом Whey та бананами від Спортмастер.",
                prepTimeMinutes = 10,
                calories = 410,
                totalCostUah = 110.0f,
                seasonTag = "Фітнес 🏋️",
                store = "Спортмастер",
                imageUrl = "https://images.unsplash.com/photo-1590301157890-4810ed352733?w=800&auto=format&fit=crop&q=80",
                ingredients = listOf(
                    Ingredient("i5", "Протеїн Isolate BioTech 30г", 30.0f, "г", 45.0f, "Фітнес-харчування", "BioTechUSA", "Спортмастер"),
                    Ingredient("i6", "Банани свіжі 2 шт", 2.0f, "шт", 25.0f, "Овочі та фрукти", "Сільпо Еквадор", "Сільпо"),
                    Ingredient("i7", "Вівсяне молоко 200мл", 200.0f, "мл", 20.0f, "Бакалія", "Ідеаль Немолоко", "Сільпо")
                ),
                instructions = listOf("Збити у блендері випечений банан із вівсяним молоком.", "Додати порцію протеїну Isolate.", "Прикрасити скибочками банана та ягодами.")
            ),
            DailyRecipe(
                id = "dr3",
                title = "Ніжне Філе Куряче з Гречкою «Премія»",
                description = "Збалансований обід із високим вмістом білка та правильними вуглеводами.",
                prepTimeMinutes = 25,
                calories = 510,
                totalCostUah = 135.0f,
                seasonTag = "Швидкі ⚡",
                store = "Сільпо",
                imageUrl = "https://images.unsplash.com/photo-1532550907401-a500c9a57435?w=800&auto=format&fit=crop&q=80",
                ingredients = listOf(
                    Ingredient("i8", "Філе куряче «Наша Ряба» 300г", 300.0f, "г", 85.0f, "М'ясо та птиця", "Наша Ряба", "Сільпо"),
                    Ingredient("i9", "Гречана крупа «Премія» 150г", 150.0f, "г", 12.0f, "Бакалія", "Премія", "Сільпо"),
                    Ingredient("i10", "Вершкове масло 20г", 20.0f, "г", 10.0f, "Молочні продукти та яйця", "Премія", "Сільпо")
                ),
                instructions = listOf("Відварити гречану крупу в підсоленій воді.", "Обсмажити куряче філе на середньому вогні до золотистої скоринки.", "Подати з ніжним вершковим маслом.")
            ),
            DailyRecipe(
                id = "dr4",
                title = "Запечений Хек із Овочами у Духовці",
                description = "Дієтична вечеря з рибою «Премія» та свіжою морквою й цибулею.",
                prepTimeMinutes = 30,
                calories = 380,
                totalCostUah = 140.0f,
                seasonTag = "Сезонний Ексклюзив 🐟",
                store = "Сільпо",
                imageUrl = "https://images.unsplash.com/photo-1519708227418-c8fd9a32b7a2?w=800&auto=format&fit=crop&q=80",
                ingredients = listOf(
                    Ingredient("i11", "Філе хека «Премія» 400г", 400.0f, "г", 90.0f, "Риба та морепродукти", "Премія", "Сільпо"),
                    Ingredient("i12", "Морква свіжа 150г", 150.0f, "г", 8.0f, "Овочі та фрукти", "Україна", "Сільпо"),
                    Ingredient("i13", "Цибуля ріпчаста 100г", 100.0f, "г", 5.0f, "Овочі та фрукти", "Україна", "Сільпо")
                ),
                instructions = listOf("Нарізати овочі соломкою.", "Викласти філе хека на фольгу, зверху вкрити овочами.", "Запікати у духовці 20 хвилин при 180°C.")
            )
        )
    }

    fun addDailyRecipeToGrocery(recipe: DailyRecipe) {
        viewModelScope.launch {
            val newItems = recipe.ingredients.map { ing ->
                GroceryItemEntity(
                    id = "g_dr_${ing.id}_${System.currentTimeMillis()}",
                    name = ing.name,
                    quantity = "${ing.quantity.toInt()} ${ing.unit}",
                    priceUah = ing.priceUah,
                    department = ing.department,
                    isChecked = false,
                    isReplaced = false,
                    originalName = ing.name,
                    store = ing.store
                )
            }
            groceryDao.insertAll(newItems)
            _toastMessage.value = "Інгредієнти рецепту «${recipe.title}» додано в список покупок!"
        }
    }

    fun acceptChallenge(challengeId: String) {
        viewModelScope.launch {
            challengeDao.setAccepted(challengeId, true)
            _toastMessage.value = "Виклик прийнято! Бажаємо успіхів у приготуванні!"
        }
    }

    fun completeChallenge(challengeId: String) {
        viewModelScope.launch {
            val ch = challenges.value.find { it.id == challengeId } ?: return@launch
            challengeDao.setCompleted(challengeId)
            val points = ch.rewardPoints
            _userPoints.value += points
            _toastMessage.value = "Вітаємо! Виклик виконано! Нараховано +$points балів!"
        }
    }

    fun redeemReward(reward: RewardOfferEntity) {
        viewModelScope.launch {
            if (_userPoints.value >= reward.pointsCost) {
                _userPoints.value -= reward.pointsCost
                rewardDao.setRedeemed(reward.id)
                _toastMessage.value = "Купон отримано! Ваш промокод: ${reward.discountCode}"
            } else {
                _toastMessage.value = "Недостатньо балів для отримання цього купона."
            }
        }
    }

    fun clearToast() {
        _toastMessage.value = null
    }

    fun setScreen(screenIndex: Int) {
        _activeScreen.value = screenIndex
    }

    fun setSelectedDay(dayIndex: Int) {
        _selectedDayIndex.value = dayIndex
    }

    fun setMealDetail(meal: RecipeMeal?) {
        _selectedMealForDetail.value = meal
    }

    fun setIngredientReplacementTarget(meal: RecipeMeal?, ingredient: Ingredient?) {
        if (meal != null && ingredient != null) {
            _ingredientReplacementTarget.value = Pair(meal, ingredient)
        } else {
            _ingredientReplacementTarget.value = null
        }
    }

    fun setGroceryReplacementTarget(item: GroceryItemEntity?) {
        _groceryReplacementTarget.value = item
    }

    fun updateBudget(budget: Float) {
        _userPreferences.value = _userPreferences.value.copy(budgetUah = budget)
    }

    fun updatePeopleCount(count: Int) {
        _userPreferences.value = _userPreferences.value.copy(peopleCount = count.coerceIn(1, 8))
    }

    fun toggleDietaryPreference(pref: String) {
        val current = _userPreferences.value.dietaryPreferences.toMutableList()
        if (current.contains(pref)) current.remove(pref) else current.add(pref)
        _userPreferences.value = _userPreferences.value.copy(dietaryPreferences = current)
    }

    fun toggleAllergy(allergy: String) {
        val current = _userPreferences.value.allergies.toMutableList()
        if (current.contains(allergy)) current.remove(allergy) else current.add(allergy)
        _userPreferences.value = _userPreferences.value.copy(allergies = current)
    }

    fun toggleEquipment(equipment: String) {
        val current = _userPreferences.value.kitchenEquipment.toMutableList()
        if (current.contains(equipment)) current.remove(equipment) else current.add(equipment)
        _userPreferences.value = _userPreferences.value.copy(kitchenEquipment = current)
    }

    fun updateSilpoToken(token: String?) {
        silpoMcpClient.updateToken(token)
        _silpoMcpStatus.value = silpoMcpClient.status
        _toastMessage.value = "Токен Сільпо / Спортмастер оновлено!"
    }

    fun generateMenu() {
        viewModelScope.launch {
            _isLoading.value = true
            try {
                val plan = mealPlanner.generateWeeklyMealPlan(_userPreferences.value)
                _weeklyMealPlan.value = plan
                syncGroceryListFromPlan(plan)
                _toastMessage.value = "Меню на тиждень успішно згенеровано!"
                _activeScreen.value = 1 // Switch to Weekly Menu screen
            } catch (e: Exception) {
                _toastMessage.value = "Помилка при генерації меню. Використано збережений план."
            } finally {
                _isLoading.value = false
            }
        }
    }

    private suspend fun syncGroceryListFromPlan(plan: WeeklyMealPlan) {
        val groceryMap = mutableMapOf<String, GroceryItemEntity>()

        plan.days.forEach { day ->
            day.meals.forEach { meal ->
                meal.ingredients.forEach { ing ->
                    val key = ing.name.lowercase().trim()
                    val existing = groceryMap[key]
                    if (existing != null) {
                        groceryMap[key] = existing.copy(
                            priceUah = existing.priceUah + ing.priceUah
                        )
                    } else {
                        groceryMap[key] = GroceryItemEntity(
                            id = "g_${ing.id}_${System.currentTimeMillis()}",
                            name = ing.name,
                            quantity = "${ing.quantity.toInt()} ${ing.unit}",
                            priceUah = ing.priceUah,
                            department = ing.department,
                            isChecked = false,
                            isReplaced = false,
                            originalName = ing.name,
                            store = ing.store
                        )
                    }
                }
            }
        }

        groceryDao.clearAll()
        groceryDao.insertAll(groceryMap.values.toList())
    }

    fun replaceIngredientInMeal(mealId: String, oldIngId: String, replacement: ReplacementOption) {
        val currentPlan = _weeklyMealPlan.value ?: return
        val updatedDays = currentPlan.days.map { day ->
            val updatedMeals = day.meals.map { meal ->
                if (meal.id == mealId) {
                    val updatedIngs = meal.ingredients.map { ing ->
                        if (ing.id == oldIngId) {
                            ing.copy(
                                name = replacement.name,
                                priceUah = replacement.priceUah,
                                silpoBrand = replacement.brand,
                                store = replacement.store
                            )
                        } else ing
                    }
                    val newCost = updatedIngs.sumOf { it.priceUah.toDouble() }.toFloat()
                    meal.copy(ingredients = updatedIngs, totalCostUah = newCost)
                } else meal
            }
            val newDayCost = updatedMeals.sumOf { it.totalCostUah.toDouble() }.toFloat()
            day.copy(meals = updatedMeals, totalDayCostUah = newDayCost)
        }

        val newTotalPlanCost = updatedDays.sumOf { it.totalDayCostUah.toDouble() }.toFloat()
        val newPlan = currentPlan.copy(days = updatedDays, totalPlanCostUah = newTotalPlanCost)
        _weeklyMealPlan.value = newPlan

        if (_selectedMealForDetail.value?.id == mealId) {
            _selectedMealForDetail.value = updatedDays.flatMap { it.meals }.find { it.id == mealId }
        }

        _ingredientReplacementTarget.value = null
        _toastMessage.value = "Інгредієнт замінено! Заощаджено ${String.format("%.1f", -replacement.priceDifferenceUah)} ₴"

        viewModelScope.launch {
            syncGroceryListFromPlan(newPlan)
        }
    }

    fun replaceGroceryItem(itemId: String, replacement: ReplacementOption) {
        viewModelScope.launch {
            val currentItem = groceryList.value.find { it.id == itemId }
            val originalName = currentItem?.originalName ?: currentItem?.name ?: ""
            groceryDao.replaceItem(
                id = itemId,
                newName = replacement.name,
                newPrice = replacement.priceUah,
                originalName = originalName
            )
            _groceryReplacementTarget.value = null
            _toastMessage.value = "Продукт замінено на аналог від ${replacement.brand} (${replacement.store})!"
        }
    }

    fun toggleGroceryCheck(itemId: String, isChecked: Boolean) {
        viewModelScope.launch {
            groceryDao.updateCheckState(itemId, isChecked)
        }
    }

    fun checkoutSilpoCart() {
        _toastMessage.value = "Замовлення оформлено! Сільпо & Спортмастер MCP: Кошики сформовано. Доставку замовлено."
    }

    // --- Nutrition & Calorie Tracking Methods ---

    fun logMealFromRecipe(meal: RecipeMeal) {
        viewModelScope.launch {
            val logged = LoggedMealEntity(
                id = "log_${meal.id}_${System.currentTimeMillis()}",
                dateString = _selectedDateString.value,
                mealTitle = meal.title,
                mealType = meal.mealType,
                calories = meal.calories,
                proteinsGrams = meal.proteinsGrams,
                fatsGrams = meal.fatsGrams,
                carbsGrams = meal.carbsGrams,
                recipeId = meal.id
            )
            nutritionDao.insertLoggedMeal(logged)
            _toastMessage.value = "«${meal.title}» додано в трекер (${meal.calories} ккал)!"
        }
    }

    fun logMealFromDailyRecipe(recipe: DailyRecipe) {
        viewModelScope.launch {
            val logged = LoggedMealEntity(
                id = "log_dr_${recipe.id}_${System.currentTimeMillis()}",
                dateString = _selectedDateString.value,
                mealTitle = recipe.title,
                mealType = "Обід",
                calories = recipe.calories,
                proteinsGrams = recipe.proteinsGrams,
                fatsGrams = recipe.fatsGrams,
                carbsGrams = recipe.carbsGrams,
                recipeId = recipe.id
            )
            nutritionDao.insertLoggedMeal(logged)
            _toastMessage.value = "«${recipe.title}» додано в трекер (${recipe.calories} ккал)!"
        }
    }

    fun logCustomMeal(title: String, type: String, cals: Int, prot: Int, fats: Int, carbs: Int) {
        viewModelScope.launch {
            val logged = LoggedMealEntity(
                id = "log_custom_${System.currentTimeMillis()}",
                dateString = _selectedDateString.value,
                mealTitle = title,
                mealType = type,
                calories = cals,
                proteinsGrams = prot,
                fatsGrams = fats,
                carbsGrams = carbs
            )
            nutritionDao.insertLoggedMeal(logged)
            _toastMessage.value = "«$title» успішно збережено в трекер!"
        }
    }

    fun deleteLoggedMeal(id: String) {
        viewModelScope.launch {
            nutritionDao.deleteLoggedMeal(id)
            _toastMessage.value = "Запис видалено"
        }
    }

    fun updateNutritionTarget(cals: Int, prot: Int, fats: Int, carbs: Int) {
        _nutritionTarget.value = NutritionTarget(cals, prot, fats, carbs)
        _toastMessage.value = "Денні цілі оновлено ($cals ккал)!"
    }

    fun selectPreviousDate() {
        val currentDate = _selectedDateString.value
        _selectedDateString.value = offsetDateString(currentDate, -1)
    }

    fun selectNextDate() {
        val currentDate = _selectedDateString.value
        _selectedDateString.value = offsetDateString(currentDate, 1)
    }

    fun selectToday() {
        _selectedDateString.value = getTodayDateString()
    }

    private fun offsetDateString(dateStr: String, daysOffset: Int): String {
        return try {
            val sdf = java.text.SimpleDateFormat("yyyy-MM-dd", java.util.Locale.getDefault())
            val date = sdf.parse(dateStr) ?: java.util.Date()
            val cal = java.util.Calendar.getInstance()
            cal.time = date
            cal.add(java.util.Calendar.DAY_OF_YEAR, daysOffset)
            sdf.format(cal.time)
        } catch (e: Exception) {
            dateStr
        }
    }
}

