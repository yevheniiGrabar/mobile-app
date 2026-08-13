package com.example.data.remote

import com.example.BuildConfig
import com.example.data.model.*
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONArray
import org.json.JSONObject
import java.util.concurrent.TimeUnit

class GeminiMealPlanner(private val silpoClient: SilpoMcpClient) {

    private val httpClient = OkHttpClient.Builder()
        .connectTimeout(30, TimeUnit.SECONDS)
        .readTimeout(30, TimeUnit.SECONDS)
        .build()

    suspend fun generateWeeklyMealPlan(userPrefs: UserPreferences): WeeklyMealPlan = withContext(Dispatchers.IO) {
        val apiKey = try { BuildConfig.GEMINI_API_KEY } catch (e: Exception) { "" }

        if (apiKey.isNotBlank() && apiKey != "MY_GEMINI_API_KEY") {
            try {
                val apiPlan = callGeminiApi(apiKey, userPrefs)
                if (apiPlan != null && apiPlan.days.isNotEmpty()) {
                    return@withContext apiPlan
                }
            } catch (e: Exception) {
                // Fallback on error
            }
        }

        // Return intelligent budget-tailored fallback plan in Ukrainian
        generateSmartFallbackPlan(userPrefs)
    }

    private fun callGeminiApi(apiKey: String, userPrefs: UserPreferences): WeeklyMealPlan? {
        val prompt = """
            Згенеруй план харчування на 7 днів для ${userPrefs.peopleCount} осіб з загальним бюджетом ${userPrefs.budgetUah} грн.
            Обмеження та вподобання: ${userPrefs.dietaryPreferences.joinToString()}
            Алергії: ${userPrefs.allergies.joinToString()}
            Наявне обладнання: ${userPrefs.kitchenEquipment.joinToString()}
            Макс час приготування: ${userPrefs.cookTimeLimit}
            
            Відповідь надай ЕКСКЛЮЗИВНО у форматі JSON без маркдауну:
            {
              "days": [
                {
                  "dayIndex": 1,
                  "dayName": "Понеділок",
                  "meals": [
                    {
                      "id": "m1_1",
                      "title": "Овсянка з яблуками та корицею",
                      "mealType": "Сніданок",
                      "prepTimeMinutes": 15,
                      "calories": 380,
                      "equipment": "Плита",
                      "totalCostUah": 45.0,
                      "ingredients": [
                        {
                          "id": "i1",
                          "name": "Вівсяні пластівці",
                          "quantity": 200.0,
                          "unit": "г",
                          "priceUah": 14.0,
                          "department": "Бакалія",
                          "silpoBrand": "Премія"
                        }
                      ],
                      "instructions": ["Закип'ятити воду", "Додати вівсянку"]
                    }
                  ]
                }
              ]
            }
        """.trimIndent()

        val jsonRequest = JSONObject().apply {
            put("contents", JSONArray().apply {
                put(JSONObject().apply {
                    put("parts", JSONArray().apply {
                        put(JSONObject().apply { put("text", prompt) })
                    })
                })
            })
        }

        val url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash:generateContent?key=$apiKey"
        val request = Request.Builder()
            .url(url)
            .post(jsonRequest.toString().toRequestBody("application/json".toMediaType()))
            .build()

        val response = httpClient.newCall(request).execute()
        if (!response.isSuccessful) {
            response.close()
            return null
        }

        val responseStr = response.body?.string() ?: ""
        response.close()

        val resJson = JSONObject(responseStr)
        val text = resJson.optJSONArray("candidates")
            ?.optJSONObject(0)
            ?.optJSONObject("content")
            ?.optJSONArray("parts")
            ?.optJSONObject(0)
            ?.optString("text") ?: return null

        val cleanJson = text.replace("```json", "").replace("```", "").trim()
        return parsePlanJson(cleanJson, userPrefs)
    }

    private fun parsePlanJson(jsonStr: String, userPrefs: UserPreferences): WeeklyMealPlan? {
        return try {
            val root = JSONObject(jsonStr)
            val daysArray = root.getJSONArray("days")
            val dayPlans = mutableListOf<DayPlan>()
            var grandTotal = 0f

            for (i in 0 until daysArray.length()) {
                val dayObj = daysArray.getJSONObject(i)
                val dayIndex = dayObj.getInt("dayIndex")
                val dayName = dayObj.getString("dayName")
                val mealsArray = dayObj.getJSONArray("meals")
                val meals = mutableListOf<RecipeMeal>()
                var dayTotal = 0f

                for (j in 0 until mealsArray.length()) {
                    val mealObj = mealsArray.getJSONObject(j)
                    val ingredientsArray = mealObj.getJSONArray("ingredients")
                    val ingredients = mutableListOf<Ingredient>()
                    var mealTotal = 0f

                    for (k in 0 until ingredientsArray.length()) {
                        val ingObj = ingredientsArray.getJSONObject(k)
                        val name = ingObj.getString("name")
                        val price = ingObj.getDouble("priceUah").toFloat()
                        mealTotal += price

                        val alternatives = silpoClient.findCheaperAlternatives(name, price)

                        ingredients.add(
                            Ingredient(
                                id = ingObj.optString("id", "ing_${i}_${j}_$k"),
                                name = name,
                                quantity = ingObj.optDouble("quantity", 1.0).toFloat(),
                                unit = ingObj.optString("unit", "шт"),
                                priceUah = price,
                                department = ingObj.optString("department", "Бакалія"),
                                silpoBrand = ingObj.optString("silpoBrand", "Премія"),
                                alternatives = alternatives
                            )
                        )
                    }

                    val title = mealObj.getString("title")
                    val equipment = mealObj.optString("equipment", userPrefs.kitchenEquipment.firstOrNull() ?: "Плита")
                    val imgUrl = getFoodImageUrl(title)

                    val instructionsArray = mealObj.optJSONArray("instructions")
                    val instructions = mutableListOf<String>()
                    if (instructionsArray != null) {
                        for (x in 0 until instructionsArray.length()) {
                            instructions.add(instructionsArray.getString(x))
                        }
                    } else {
                        instructions.add("Підготувати інгредієнти відповідно до рецепту.")
                        instructions.add("Приготувати страву на приладі: $equipment.")
                        instructions.add("Подати гарячою до столу.")
                    }

                    val meal = RecipeMeal(
                        id = mealObj.optString("id", "meal_${i}_$j"),
                        title = title,
                        mealType = mealObj.optString("mealType", "Обід"),
                        prepTimeMinutes = mealObj.optInt("prepTimeMinutes", 25),
                        calories = mealObj.optInt("calories", 420),
                        imageUrl = imgUrl,
                        equipment = equipment,
                        totalCostUah = if (mealTotal > 0) mealTotal else mealObj.optDouble("totalCostUah", 65.0).toFloat(),
                        ingredients = ingredients,
                        instructions = instructions
                    )
                    meals.add(meal)
                    dayTotal += meal.totalCostUah
                }

                dayPlans.add(DayPlan(dayIndex, dayName, meals, dayTotal))
                grandTotal += dayTotal
            }

            WeeklyMealPlan(dayPlans, grandTotal, userPrefs.budgetUah, userPrefs.peopleCount)
        } catch (e: Exception) {
            null
        }
    }

    fun generateSmartFallbackPlan(userPrefs: UserPreferences): WeeklyMealPlan {
        val days = listOf("Понеділок", "Вівторок", "Середа", "Четвер", "П'ятниця", "Субота", "Неділя")
        val isVeg = userPrefs.dietaryPreferences.contains("Вегетаріанське")
        val eq = userPrefs.kitchenEquipment.ifEmpty { listOf("Плита", "Духовка", "Мікрохвильовка") }

        val dayPlans = days.mapIndexed { index, dayName ->
            val dayIndex = index + 1
            val meals = when (index % 4) {
                0 -> listOf(
                    createMeal("s1", "Вівсяна каша з бананом та медом", "Сніданок", 15, 360, "Плита",
                        listOf(
                            createIng("i1", "Вівсяні пластівці «Премія»", 200f, "г", 28f, "Бакалія", "Премія"),
                            createIng("i2", "Молоко 2.5% «Яготинське»", 300f, "мл", 15f, "Молочні продукти та яйця", "Яготинське"),
                            createIng("i3", "Банан", 1f, "шт", 12f, "Овочі та фрукти")
                        ),
                        listOf("Варити вівсянку на молоці 10 хв.", "Нарізати банан кружечками та прикрасити перед подачею.")
                    ),
                    createMeal("s2", if (isVeg) "Суп-пюре з сочевиці та гарбуза" else "Курячий бульйон з гречаною локшиною", "Обід", 30, 480, if (eq.contains("Духовка")) "Духовка" else "Плита",
                        listOf(
                            if (isVeg) createIng("i4", "Сочевиця червона «Премія»", 250f, "г", 38f, "Бакалія", "Премія")
                            else createIng("i5", "Філе куряче «Наша Ряба»", 350f, "г", 65f, "М'ясо та птиця", "Наша Ряба"),
                            createIng("i6", "Морква свіжа", 1f, "шт", 5f, "Овочі та фрукти"),
                            createIng("i7", "Цибуля ріпчаста", 1f, "шт", 4f, "Овочі та фрукти"),
                            createIng("i8", "Хліб тостовий", 2f, "скибочки", 8f, "Хліб та випічка")
                        ),
                        listOf("Обсмажити овочі з курятиною або сочевицею.", "Залити водою, запекти або проварити 20 хв до готовності.")
                    ),
                    createMeal("s3", if (isVeg) "Запечена картопля з сиром та салатом" else "Запечене куряче філе з картоплею", "Вечеря", 35, 520, if (eq.contains("Духовка")) "Духовка" else "Мікрохвильовка",
                        listOf(
                            createIng("i9", "Картопля свіжа", 500f, "г", 12f, "Овочі та фрукти"),
                            if (isVeg) createIng("i10", "Сир Голландський «Комо»", 100f, "г", 39f, "Молочні продукти та яйця")
                            else createIng("i11", "Філе куряче «Наша Ряба»", 300f, "г", 55f, "М'ясо та птиця"),
                            createIng("i12", "Сметана 15% «Премія»", 100f, "г", 12f, "Молочні продукти та яйця", "Премія")
                        ),
                        listOf("Нарізати картоплю дольками.", "Додати спеції, запекти в духовці або мікрохвильовці за 25 хв.", "Подати зі сметаною.")
                    )
                )
                1 -> listOf(
                    createMeal("s4", "Омлет із зеленню та томатами", "Сніданок", 10, 320, "Плита",
                        listOf(
                            createIng("i13", "Яйця курячі С1 «Квочка»", 3f, "шт", 18f, "Молочні продукти та яйця"),
                            createIng("i14", "Томати червоні", 1f, "шт", 12f, "Овочі та фрукти"),
                            createIng("i15", "Масло вершкове «Премія»", 20f, "г", 8f, "Молочні продукти та яйця", "Премія")
                        ),
                        listOf("Збити яйця з дрібкою солі.", "Обсмажити на вершковому маслі разом із томатами 5 хвилин.")
                    ),
                    createMeal("s5", "Гречка з тушкованими овочами та котлетою", "Обід", 25, 540, if (eq.contains("Мультиварка")) "Мультиварка" else "Плита",
                        listOf(
                            createIng("i16", "Гречана крупа «Премія»", 200f, "г", 16f, "Бакалія", "Премія"),
                            createIng("i17", "Фарш свинно-яловичий «Повна Чаша»", 250f, "г", 38f, "М'ясо та птиця", "Повна Чаша"),
                            createIng("i18", "Олія соняшникова «Щедрий ДАР»", 30f, "мл", 5f, "Бакалія")
                        ),
                        listOf("Зварити гречку 15 хв.", "Сформувати котлети та обсмажити з двох боків до золотистої скоринки.")
                    ),
                    createMeal("s6", "Сирники запечені з родзинками", "Вечеря", 20, 410, if (eq.contains("Духовка")) "Духовка" else "Плита",
                        listOf(
                            createIng("i19", "Кисломолочний сир 5% «Премія»", 300f, "г", 44f, "Молочні продукти та яйця", "Премія"),
                            createIng("i20", "Яйце куряче", 1f, "шт", 6f, "Молочні продукти та яйця"),
                            createIng("i21", "Борошно пшеничне", 50f, "г", 4f, "Бакалія")
                        ),
                        listOf("Змішати сир, яйце та борошно.", "Сформувати сирники та запекти 15 хв.")
                    )
                )
                2 -> listOf(
                    createMeal("s7", "Синiй йогурт з гранолою та яблуком", "Сніданок", 10, 290, "Без термообробки",
                        listOf(
                            createIng("i22", "Кисломолочний сир «Премія»", 200f, "г", 29f, "Молочні продукти та яйця", "Премія"),
                            createIng("i23", "Яблуко Симиренко", 1f, "шт", 8f, "Овочі та фрукти")
                        ),
                        listOf("Змішати сир з нарізаним яблуком та медом.")
                    ),
                    createMeal("s8", "Паста з томатним соусом та базиліком", "Обід", 20, 510, "Плита",
                        listOf(
                            createIng("i24", "Макарони «Чумак»", 250f, "г", 22f, "Бакалія"),
                            createIng("i25", "Томати червоні", 200f, "г", 15f, "Овочі та фрукти"),
                            createIng("i26", "Сир твердий «Повна Чаша»", 50f, "г", 15f, "Молочні продукти та яйця", "Повна Чаша")
                        ),
                        listOf("Відварити макарони у підсоленій воді 8 хв.", "Приготувати соус із томатів та посипати тертим сиром.")
                    ),
                    createMeal("s9", "Печена риба або тушковані квасолеві котлети", "Вечеря", 30, 460, if (eq.contains("Духовка")) "Духовка" else "Плита",
                        listOf(
                            createIng("i27", "Філе хека «Премія»", 300f, "г", 66f, "Риба та морепродукти", "Премія"),
                            createIng("i28", "Морква та цибуля", 150f, "г", 8f, "Овочі та фрукти")
                        ),
                        listOf("Запекти рибу з овочами у фользі при 180°C 20 хв.")
                    )
                )
                else -> listOf(
                    createMeal("s10", "Гарячі тости із сиром та овочами", "Сніданок", 10, 340, "Мікрохвильовка",
                        listOf(
                            createIng("i29", "Хліб тостовий", 4f, "скибочки", 14f, "Хліб та випічка"),
                            createIng("i30", "Сир «Комо»", 80f, "г", 31f, "Молочні продукти та яйця")
                        ),
                        listOf("Викласти сир на тости.", "Розігріти в мікрохвильовці 1.5 хв до розплавлення сиру.")
                    ),
                    createMeal("s11", "Рис із овочами та індичкою/квасолею", "Обід", 25, 490, "Плита",
                        listOf(
                            createIng("i31", "Рис довгозернистий «Премія»", 200f, "г", 12f, "Бакалія", "Премія"),
                            createIng("i32", "Філе індички охолоджене", 250f, "г", 54f, "М'ясо та птиця"),
                            createIng("i33", "Огірки свіжі", 1f, "шт", 10f, "Овочі та фрукти")
                        ),
                        listOf("Відварити рис.", "Обсмажити індичку з овочами та змішати з рисом.")
                    ),
                    createMeal("s12", "Деруни картопляні зі сметаною", "Вечеря", 25, 450, "Плита",
                        listOf(
                            createIng("i34", "Картопля свіжа", 600f, "г", 14f, "Овочі та фрукти"),
                            createIng("i35", "Сметана 15% «Премія»", 100f, "г", 11f, "Молочні продукти та яйця", "Премія")
                        ),
                        listOf("Натерти картоплю, віджати сік, додати яйце.", "Обсмажити на пательні до золотистої скоринки.")
                    )
                )
            }

            val dayTotal = meals.sumOf { it.totalCostUah.toDouble() }.toFloat()
            DayPlan(dayIndex, dayName, meals, dayTotal)
        }

        val totalCost = dayPlans.sumOf { it.totalDayCostUah.toDouble() }.toFloat()
        return WeeklyMealPlan(dayPlans, totalCost, userPrefs.budgetUah, userPrefs.peopleCount)
    }

    private fun createMeal(
        id: String,
        title: String,
        type: String,
        prepMin: Int,
        cals: Int,
        equipment: String,
        ingredients: List<Ingredient>,
        instructions: List<String>
    ): RecipeMeal {
        val cost = ingredients.sumOf { it.priceUah.toDouble() }.toFloat()
        return RecipeMeal(
            id = id,
            title = title,
            mealType = type,
            prepTimeMinutes = prepMin,
            calories = cals,
            imageUrl = getFoodImageUrl(title),
            equipment = equipment,
            totalCostUah = cost,
            ingredients = ingredients,
            instructions = instructions
        )
    }

    private fun createIng(
        id: String,
        name: String,
        qty: Float,
        unit: String,
        price: Float,
        department: String,
        brand: String? = null
    ): Ingredient {
        val alternatives = silpoClient.findCheaperAlternatives(name, price)
        return Ingredient(
            id = id,
            name = name,
            quantity = qty,
            unit = unit,
            priceUah = price,
            department = department,
            silpoBrand = brand,
            alternatives = alternatives
        )
    }

    private fun getFoodImageUrl(title: String): String {
        val t = title.lowercase()
        return when {
            t.contains("вівсян") || t.contains("каш") -> "https://images.unsplash.com/photo-1517673132405-a56a62b18caf?w=600&auto=format&fit=crop&q=80"
            t.contains("суп") || t.contains("бульйон") -> "https://images.unsplash.com/photo-1547592166-23ac45744acd?w=600&auto=format&fit=crop&q=80"
            t.contains("картопл") || t.contains("дерун") -> "https://images.unsplash.com/photo-1518013431117-eb1465fa5752?w=600&auto=format&fit=crop&q=80"
            t.contains("омлет") || t.contains("яйц") -> "https://images.unsplash.com/photo-1525351484163-7529414344d8?w=600&auto=format&fit=crop&q=80"
            t.contains("гречк") || t.contains("котлет") -> "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=600&auto=format&fit=crop&q=80"
            t.contains("сирник") -> "https://images.unsplash.com/photo-1588195538326-c5b1e9f80a1b?w=600&auto=format&fit=crop&q=80"
            t.contains("паст") || t.contains("макарон") -> "https://images.unsplash.com/photo-1621996346565-e3d5d6281320?w=600&auto=format&fit=crop&q=80"
            t.contains("риб") || t.contains("лосось") -> "https://images.unsplash.com/photo-1519708227418-c8fd9a32b7a2?w=600&auto=format&fit=crop&q=80"
            t.contains("тост") -> "https://images.unsplash.com/photo-1525351484163-7529414344d8?w=600&auto=format&fit=crop&q=80"
            t.contains("рис") -> "https://images.unsplash.com/photo-1536304993881-ff6e9eefa2a6?w=600&auto=format&fit=crop&q=80"
            else -> "https://images.unsplash.com/photo-1498837167922-ddd27525d352?w=600&auto=format&fit=crop&q=80"
        }
    }
}
