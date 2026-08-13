package com.example.data.remote

import com.example.data.model.ReplacementOption
import com.example.data.model.SilpoMcpStatus
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONObject
import java.util.concurrent.TimeUnit

data class SilpoProduct(
    val id: String,
    val name: String,
    val brand: String,
    val priceUah: Float,
    val unit: String,
    val department: String,
    val store: String = "Сільпо", // "Сільпо" or "Спортмастер"
    val isPrivateLabel: Boolean = false
)

class SilpoMcpClient {

    private val httpClient = OkHttpClient.Builder()
        .connectTimeout(10, TimeUnit.SECONDS)
        .readTimeout(10, TimeUnit.SECONDS)
        .build()

    var status = SilpoMcpStatus()
        private set

    fun updateToken(token: String?) {
        status = if (!token.isNull_or_empty()) {
            status.copy(
                isAuthorized = true,
                bearerToken = token,
                userAccount = "Власний Рахунок / Спортмастер Клуб: Активовано",
                statusMessage = "MSP Сервер: OAuth токен активовано"
            )
        } else {
            status.copy(
                isAuthorized = false,
                bearerToken = null,
                userAccount = "Власний Рахунок / Спортмастер Клуб: Гостьовий режим",
                statusMessage = "MSP Сервер: Гостьовий режим активний"
            )
        }
    }

    private fun String?.isNull_or_empty(): Boolean = this == null || this.trim().isEmpty()

    suspend fun pingMcpServer(): Boolean = withContext(Dispatchers.IO) {
        try {
            val jsonBody = JSONObject().apply {
                put("jsonrpc", "2.0")
                put("id", 1)
                put("method", "initialize")
                put("params", JSONObject().apply {
                    put("protocolVersion", "2024-11-05")
                    put("clientInfo", JSONObject().apply {
                        put("name", "SportmasterSilpoMcpApp")
                        put("version", "2.0")
                    })
                })
            }
            val requestBuilder = Request.Builder()
                .url("https://mcp.silpo.ua/mcp")
                .post(jsonBody.toString().toRequestBody("application/json".toMediaType()))

            if (!status.bearerToken.isNull_or_empty()) {
                requestBuilder.header("Authorization", "Bearer ${status.bearerToken}")
            }

            val response = httpClient.newCall(requestBuilder.build()).execute()
            val code = response.code
            response.close()

            code == 200 || code == 401
        } catch (e: Exception) {
            false
        }
    }

    // High quality product catalog featuring Silpo & Sportmaster
    val catalog: List<SilpoProduct> = listOf(
        // Silpo
        SilpoProduct("p1", "Філе куряче «Наша Ряба»", "Наша Ряба", 185.0f, "кг", "М'ясо та птиця", "Сільпо"),
        SilpoProduct("p2", "Філе індички охолоджене", "Премія", 215.0f, "кг", "М'ясо та птиця", "Сільпо", true),
        SilpoProduct("p3", "Фарш свинно-яловичий", "Повна Чаша", 155.0f, "кг", "М'ясо та птиця", "Сільпо", true),
        SilpoProduct("p4", "Яйця курячі С1 10 шт", "Квочка", 58.0f, "уп", "Молочні продукти та яйця", "Сільпо"),
        SilpoProduct("p5", "Яйця курячі С1 10 шт", "Повна Чаша", 48.0f, "уп", "Молочні продукти та яйця", "Сільпо", true),
        SilpoProduct("p6", "Гречана крупа 1 кг", "Премія", 38.0f, "кг", "Бакалія", "Сільпо", true),
        SilpoProduct("p7", "Гречана крупа 1 кг", "Повна Чаша", 32.0f, "кг", "Бакалія", "Сільпо", true),
        SilpoProduct("p8", "Молоко 2.5% 900 г", "Яготинське", 42.0f, "шт", "Молочні продукти та яйця", "Сільпо"),
        SilpoProduct("p9", "Молоко 2.5% 900 г", "Премія", 35.0f, "шт", "Молочні продукти та яйця", "Сільпо", true),
        SilpoProduct("p10", "Масло вершкове 82.5% 200 г", "Волошкове Поле", 74.0f, "шт", "Молочні продукти та яйця", "Сільпо"),
        SilpoProduct("p11", "Картопля свіжа", "Україна", 24.0f, "кг", "Овочі та фрукти", "Сільпо"),
        SilpoProduct("p12", "Морква свіжа", "Україна", 18.0f, "кг", "Овочі та фрукти", "Сільпо"),
        SilpoProduct("p13", "Томати червоні", "Сільпо Імпорт", 75.0f, "кг", "Овочі та фрукти", "Сільпо"),
        SilpoProduct("p14", "Огірки гладкі", "Україна", 65.0f, "кг", "Овочі та фрукти", "Сільпо"),
        SilpoProduct("p15", "Кисломолочний сир 5% 300 г", "Премія", 44.0f, "шт", "Молочні продукти та яйця", "Сільпо", true),
        SilpoProduct("p16", "Сир твердий Голландський 200 г", "Комо", 78.0f, "шт", "Молочні продукти та яйця", "Сільпо"),
        SilpoProduct("p17", "Олія соняшникова 850 мл", "Повна Чаша", 49.0f, "шт", "Бакалія", "Сільпо", true),
        SilpoProduct("p18", "Авокадо Хаас 1 шт", "Сільпо Імпорт", 45.0f, "шт", "Овочі та фрукти", "Сільпо"),

        // Sportmaster / Спортмастер (Фітнес-харчування та спортивні аксесуари)
        SilpoProduct("sp1", "Протеїновий батончик Whey Pro 60г", "Sportmaster Nutrition", 45.0f, "шт", "Фітнес-харчування", "Спортмастер"),
        SilpoProduct("sp2", "Протеїн Сироватковий Isolate 1кг", "BioTechUSA", 850.0f, "уп", "Фітнес-харчування", "Спортмастер"),
        SilpoProduct("sp3", "Ізотонічний напій Electrolyte 500мл", "Nutrend", 38.0f, "пляшка", "Фітнес-харчування", "Спортмастер"),
        SilpoProduct("sp4", "Вівсяний спортивний шейк з білком 400g", "PowerPro", 68.0f, "шт", "Фітнес-харчування", "Спортмастер"),
        SilpoProduct("sp5", "Омега-3 Риб'ячий жир 60 капсул", "Sportmaster Health", 190.0f, "уп", "Фітнес-харчування", "Спортмастер")
    )

    fun findCheaperAlternatives(ingredientName: String, currentPrice: Float): List<ReplacementOption> {
        val nameLower = ingredientName.lowercase()
        val options = mutableListOf<ReplacementOption>()

        if (nameLower.contains("куряче") || nameLower.contains("курк") || nameLower.contains("птиц") || nameLower.contains("м'яс")) {
            options.add(ReplacementOption("r1", "Фарш свинно-яловичий «Повна Чаша»", 155.0f, "Повна Чаша", -30.0f, "Економний фарш замість цілого філе", "Сільпо"))
            options.add(ReplacementOption("r2", "Протеїновий шейк з білком PowerPro", 68.0f, "PowerPro", -117.0f, "Фітнес-заміна білка зі Спортмастер", "Спортмастер"))
            options.add(ReplacementOption("r3", "Філе хека «Премія» 500г", 110.0f, "Премія", -75.0f, "Дешевша рибна альтернатива білка", "Сільпо"))
        } else if (nameLower.contains("молок") || nameLower.contains("протеїн")) {
            options.add(ReplacementOption("r4", "Молоко 2.5% «Премія» 900г", 35.0f, "Премія", -7.0f, "Власна марка Сільпо «Премія»", "Сільпо"))
            options.add(ReplacementOption("r5", "Ізотонічний напій Electrolyte", 38.0f, "Nutrend", -12.0f, "Спортивний напій зі Спортмастер", "Спортмастер"))
        } else if (nameLower.contains("перекус") || nameLower.contains("батончик") || nameLower.contains("горіх")) {
            options.add(ReplacementOption("r6", "Протеїновий батончик Whey Pro 60г", 45.0f, "Sportmaster Nutrition", -15.0f, "Енергетична акція від Спортмастер", "Спортмастер"))
        } else if (nameLower.contains("яйц")) {
            options.add(ReplacementOption("r7", "Яйця курячі С1 «Повна Чаша»", 48.0f, "Повна Чаша", -10.0f, "Власна марка «Повна Чаша»", "Сільпо"))
        } else if (nameLower.contains("гречк") || nameLower.contains("рис") || nameLower.contains("макарон") || nameLower.contains("вівсян")) {
            options.add(ReplacementOption("r8", "Крупа гречана «Повна Чаша» 1кг", 32.0f, "Повна Чаша", -6.0f, "Супер-ціна від Сільпо", "Сільпо"))
            options.add(ReplacementOption("r9", "Вівсяний спортивний шейк з білком", 68.0f, "PowerPro", -20.0f, "Спортивна каша зі Спортмастер", "Спортмастер"))
        } else if (nameLower.contains("сир") || nameLower.contains("масло")) {
            options.add(ReplacementOption("r10", "Сир твердий «Повна Чаша» 200г", 59.0f, "Повна Чаша", -19.0f, "Якісний сир власної марки", "Сільпо"))
            options.add(ReplacementOption("r11", "Кисломолочний сир 5% «Премія»", 44.0f, "Премія", -10.0f, "Свіжий творог за оптовою ціною", "Сільпо"))
        } else {
            val targetPrice = (currentPrice * 0.75f).coerceAtLeast(15.0f)
            options.add(
                ReplacementOption(
                    "rg_${ingredientName.hashCode()}",
                    "$ingredientName (акційна марка «Повна Чаша»)",
                    targetPrice,
                    "Повна Чаша",
                    -(currentPrice - targetPrice),
                    "Акція в Сільпо: дешевше на 25%",
                    "Сільпо"
                )
            )
            options.add(
                ReplacementOption(
                    "sp_rg_${ingredientName.hashCode()}",
                    "Протеїновий замінник від Спортмастер",
                    45.0f,
                    "Sportmaster",
                    -(currentPrice - 45.0f).coerceAtLeast(-50.0f),
                    "Спортивна фітнес-альтернатива",
                    "Спортмастер"
                )
            )
        }
        return options
    }
}

