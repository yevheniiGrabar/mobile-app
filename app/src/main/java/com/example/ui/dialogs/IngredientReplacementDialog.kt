package com.example.ui.dialogs

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Savings
import androidx.compose.material.icons.filled.SwapHoriz
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.data.model.ReplacementOption
import com.example.ui.theme.*

@Composable
fun IngredientReplacementDialog(
    ingredientName: String,
    currentPriceUah: Float,
    options: List<ReplacementOption>,
    onSelectOption: (ReplacementOption) -> Unit,
    onDismiss: () -> Unit
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        containerColor = SleekSurface,
        shape = RoundedCornerShape(24.dp),
        title = {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(
                        Icons.Default.SwapHoriz,
                        contentDescription = null,
                        tint = SleekPrimary
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        text = "Заміна інгредієнта",
                        fontWeight = FontWeight.Bold,
                        fontSize = 18.sp,
                        color = SleekTextPrimary
                    )
                }
                IconButton(onClick = onDismiss) {
                    Icon(Icons.Default.Close, contentDescription = "Close", tint = SleekTextPrimary)
                }
            }
        },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                Surface(
                    color = SleekSurfaceVariant,
                    shape = RoundedCornerShape(12.dp),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Column(modifier = Modifier.padding(12.dp)) {
                        Text(
                            text = "Поточний продукт:",
                            fontSize = 12.sp,
                            color = SleekTextSecondary
                        )
                        Text(
                            text = ingredientName,
                            fontWeight = FontWeight.Bold,
                            fontSize = 15.sp,
                            color = SleekTextPrimary
                        )
                        Text(
                            text = "Ціна: ${currentPriceUah.toInt()} ₴",
                            fontWeight = FontWeight.Bold,
                            color = SleekPriceGreen,
                            fontSize = 14.sp
                        )
                    }
                }

                Text(
                    text = "Доступні варіанти економії Сільпо:",
                    fontWeight = FontWeight.Bold,
                    fontSize = 14.sp,
                    color = SleekTextPrimary
                )

                if (options.isEmpty()) {
                    Text(
                        text = "Альтернативні акційні товари додано в список.",
                        fontSize = 13.sp,
                        color = SleekTextSecondary
                    )
                } else {
                    LazyColumn(
                        verticalArrangement = Arrangement.spacedBy(8.dp),
                        modifier = Modifier.heightIn(max = 280.dp)
                    ) {
                        items(options) { opt ->
                            Card(
                                colors = CardDefaults.cardColors(
                                    containerColor = SleekSurfaceVariant
                                ),
                                border = BorderStroke(1.dp, SleekBorder),
                                shape = RoundedCornerShape(12.dp),
                                elevation = CardDefaults.cardElevation(defaultElevation = 2.dp),
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .clickable { onSelectOption(opt) }
                            ) {
                                Column(modifier = Modifier.padding(12.dp)) {
                                    Row(
                                        modifier = Modifier.fillMaxWidth(),
                                        horizontalArrangement = Arrangement.SpaceBetween,
                                        verticalAlignment = Alignment.CenterVertically
                                    ) {
                                        Column(modifier = Modifier.weight(1f)) {
                                            Text(
                                                text = opt.name,
                                                fontWeight = FontWeight.Bold,
                                                fontSize = 14.sp,
                                                color = SleekTextPrimary
                                            )
                                            Text(
                                                text = opt.reason,
                                                fontSize = 11.sp,
                                                color = SleekTextSecondary
                                            )
                                        }

                                        Column(horizontalAlignment = Alignment.End) {
                                            Text(
                                                text = "${opt.priceUah.toInt()} ₴",
                                                fontWeight = FontWeight.ExtraBold,
                                                color = SleekPriceGreen,
                                                fontSize = 15.sp
                                            )
                                            Surface(
                                                color = SleekPriceGreen.copy(alpha = 0.2f),
                                                shape = RoundedCornerShape(4.dp)
                                            ) {
                                                Row(
                                                    verticalAlignment = Alignment.CenterVertically,
                                                    modifier = Modifier.padding(horizontal = 4.dp, vertical = 2.dp)
                                                ) {
                                                    Icon(
                                                        Icons.Default.Savings,
                                                        contentDescription = null,
                                                        modifier = Modifier.size(12.dp),
                                                        tint = SleekPriceGreen
                                                    )
                                                    Spacer(modifier = Modifier.width(2.dp))
                                                    Text(
                                                        text = "${opt.priceDifferenceUah.toInt()} ₴",
                                                        fontSize = 11.sp,
                                                        color = SleekPriceGreen,
                                                        fontWeight = FontWeight.Bold
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
            }
        },
        confirmButton = {}
    )
}

