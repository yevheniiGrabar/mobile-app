package com.example.ui.screens

import androidx.compose.animation.*
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.outlined.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.data.model.SilpoMcpStatus
import com.example.data.model.UserPreferences
import com.example.ui.theme.*

@OptIn(ExperimentalLayoutApi::class)
@Composable
fun SetupScreen(
    userPrefs: UserPreferences,
    mcpStatus: SilpoMcpStatus,
    isLoading: Boolean,
    onBudgetChange: (Float) -> Unit,
    onPeopleCountChange: (Int) -> Unit,
    onTogglePreference: (String) -> Unit,
    onToggleAllergy: (String) -> Unit,
    onToggleEquipment: (String) -> Unit,
    onUpdateToken: (String?) -> Unit,
    onGenerateClick: () -> Unit
) {
    var showTokenDialog by remember { mutableStateOf(false) }

    LazyColumn(
        modifier = Modifier
            .fillMaxSize()
            .padding(horizontal = 16.dp),
        contentPadding = PaddingValues(top = 16.dp, bottom = 100.dp),
        verticalArrangement = Arrangement.spacedBy(20.dp)
    ) {
        // Silpo MCP Status Header Banner
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
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Column(modifier = Modifier.weight(1f)) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Box(
                                modifier = Modifier
                                    .size(10.dp)
                                    .clip(CircleShape)
                                    .background(if (mcpStatus.isConnected) SleekPriceGreen else SleekAccentOrange)
                            )
                            Spacer(modifier = Modifier.width(8.dp))
                            Text(
                                text = "Сільпо MCP Сервер",
                                color = SleekTextPrimary,
                                fontWeight = FontWeight.Bold,
                                fontSize = 16.sp
                            )
                        }
                        Spacer(modifier = Modifier.height(4.dp))
                        Text(
                            text = mcpStatus.userAccount,
                            color = SleekPrimary,
                            fontSize = 13.sp
                        )
                        Text(
                            text = "Бали «Власний Рахунок»: ${mcpStatus.bonusPoints} б",
                            color = SleekTextSecondary,
                            fontSize = 12.sp
                        )
                    }

                    OutlinedButton(
                        onClick = { showTokenDialog = true },
                        colors = ButtonDefaults.outlinedButtonColors(
                            contentColor = SleekPrimary
                        ),
                        border = BorderStroke(1.dp, SleekPrimary),
                        shape = RoundedCornerShape(12.dp),
                        contentPadding = PaddingValues(horizontal = 12.dp, vertical = 6.dp)
                    ) {
                        Icon(
                            Icons.Default.Key,
                            contentDescription = "Token",
                            modifier = Modifier.size(16.dp)
                        )
                        Spacer(modifier = Modifier.width(4.dp))
                        Text("OAuth Token", fontSize = 12.sp)
                    }
                }
            }
        }

        // Budget Slider Card
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
                Column(
                    modifier = Modifier.padding(20.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Icon(
                                Icons.Default.AccountBalanceWallet,
                                contentDescription = "Budget",
                                tint = SleekPrimary
                            )
                            Spacer(modifier = Modifier.width(8.dp))
                            Text(
                                text = "Бюджет на тиждень",
                                style = MaterialTheme.typography.titleMedium,
                                fontWeight = FontWeight.Bold,
                                color = SleekTextPrimary
                            )
                        }

                        Surface(
                            color = SleekPrimaryContainer,
                            shape = RoundedCornerShape(12.dp)
                        ) {
                            Text(
                                text = "${userPrefs.budgetUah.toInt()} ₴",
                                color = SleekPrimary,
                                fontWeight = FontWeight.ExtraBold,
                                fontSize = 20.sp,
                                modifier = Modifier.padding(horizontal = 12.dp, vertical = 6.dp)
                            )
                        }
                    }

                    Slider(
                        value = userPrefs.budgetUah,
                        onValueChange = onBudgetChange,
                        valueRange = 800f..10000f,
                        steps = 91,
                        colors = SliderDefaults.colors(
                            thumbColor = SleekPrimary,
                            activeTrackColor = SleekPrimary,
                            inactiveTrackColor = SleekBorder
                        ),
                        modifier = Modifier.testTag("budget_slider")
                    )

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Text("800 ₴ (Економ)", fontSize = 12.sp, color = SleekTextSecondary)
                        Text("5 000 ₴ (Оптимальний)", fontSize = 12.sp, color = SleekTextSecondary)
                        Text("10 000 ₴ (Преміум)", fontSize = 12.sp, color = SleekTextSecondary)
                    }
                }
            }
        }

        // People Count Card
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
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(20.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Column {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Icon(
                                Icons.Default.Group,
                                contentDescription = "People",
                                tint = SleekPriceGreen
                            )
                            Spacer(modifier = Modifier.width(8.dp))
                            Text(
                                text = "Кількість осіб",
                                style = MaterialTheme.typography.titleMedium,
                                fontWeight = FontWeight.Bold,
                                color = SleekTextPrimary
                            )
                        }
                        Text(
                            text = "Розрахунок порцій та кількості покупок",
                            fontSize = 12.sp,
                            color = SleekTextSecondary
                        )
                    }

                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        IconButton(
                            onClick = { onPeopleCountChange(userPrefs.peopleCount - 1) },
                            modifier = Modifier
                                .size(40.dp)
                                .clip(CircleShape)
                                .background(SleekSurfaceVariant),
                            enabled = userPrefs.peopleCount > 1
                        ) {
                            Icon(
                                Icons.Default.Remove,
                                contentDescription = "Decrease",
                                tint = SleekTextPrimary
                            )
                        }

                        Text(
                            text = "${userPrefs.peopleCount}",
                            fontWeight = FontWeight.Bold,
                            fontSize = 20.sp,
                            color = SleekTextPrimary
                        )

                        IconButton(
                            onClick = { onPeopleCountChange(userPrefs.peopleCount + 1) },
                            modifier = Modifier
                                .size(40.dp)
                                .clip(CircleShape)
                                .background(SleekPrimary)
                        ) {
                            Icon(
                                Icons.Default.Add,
                                contentDescription = "Increase",
                                tint = SleekOnPrimary
                            )
                        }
                    }
                }
            }
        }

        // Dietary Preferences
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
                Column(
                    modifier = Modifier.padding(20.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(
                            Icons.Default.Restaurant,
                            contentDescription = "Preferences",
                            tint = SleekPrimary
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(
                            text = "Харчові вподобання",
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold,
                            color = SleekTextPrimary
                        )
                    }

                    val prefsList = listOf(
                        "Вегетаріанське", "Дієтичне", "Високобілкове", "Кето / Низьковуглеводне", "Для всієї родини", "Пісне"
                    )

                    FlowRow(
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                        verticalArrangement = Arrangement.spacedBy(8.dp),
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        prefsList.forEach { pref ->
                            val isSelected = userPrefs.dietaryPreferences.contains(pref)
                            FilterChip(
                                selected = isSelected,
                                onClick = { onTogglePreference(pref) },
                                label = { Text(pref) },
                                leadingIcon = if (isSelected) {
                                    { Icon(Icons.Default.Check, contentDescription = null, modifier = Modifier.size(16.dp)) }
                                } else null,
                                colors = FilterChipDefaults.filterChipColors(
                                    selectedContainerColor = SleekPrimary,
                                    selectedLabelColor = SleekOnPrimary,
                                    selectedLeadingIconColor = SleekOnPrimary,
                                    containerColor = SleekSurfaceVariant,
                                    labelColor = SleekTextPrimary
                                ),
                                border = FilterChipDefaults.filterChipBorder(
                                    borderColor = SleekBorder,
                                    selectedBorderColor = SleekPrimary,
                                    enabled = true,
                                    selected = isSelected
                                )
                            )
                        }
                    }
                }
            }
        }

        // Allergies Card
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
                Column(
                    modifier = Modifier.padding(20.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(
                            Icons.Default.Block,
                            contentDescription = "Allergies",
                            tint = Color(0xFFEF5350)
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(
                            text = "Алергії та виключення",
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold,
                            color = SleekTextPrimary
                        )
                    }

                    val allergiesList = listOf(
                        "Горіхи", "Лактоза / Молоко", "Глютен", "Морепродукти", "Яйця", "Соя", "Цитрусові"
                    )

                    FlowRow(
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                        verticalArrangement = Arrangement.spacedBy(8.dp),
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        allergiesList.forEach { allergy ->
                            val isSelected = userPrefs.allergies.contains(allergy)
                            FilterChip(
                                selected = isSelected,
                                onClick = { onToggleAllergy(allergy) },
                                label = { Text(allergy) },
                                leadingIcon = if (isSelected) {
                                    { Icon(Icons.Default.Warning, contentDescription = null, modifier = Modifier.size(16.dp)) }
                                } else null,
                                colors = FilterChipDefaults.filterChipColors(
                                    selectedContainerColor = Color(0xFFE53935),
                                    selectedLabelColor = Color.White,
                                    selectedLeadingIconColor = Color.White,
                                    containerColor = SleekSurfaceVariant,
                                    labelColor = SleekTextPrimary
                                ),
                                border = FilterChipDefaults.filterChipBorder(
                                    borderColor = SleekBorder,
                                    selectedBorderColor = Color(0xFFE53935),
                                    enabled = true,
                                    selected = isSelected
                                )
                            )
                        }
                    }
                }
            }
        }

        // Kitchen Equipment
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
                Column(
                    modifier = Modifier.padding(20.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(
                            Icons.Default.Kitchen,
                            contentDescription = "Equipment",
                            tint = SleekPriceGreen
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(
                            text = "Кухонне обладнання",
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold,
                            color = SleekTextPrimary
                        )
                    }

                    val equipmentList = listOf(
                        "Плита", "Духовка", "Мікрохвильовка", "Мультиварка", "Аерогриль", "Блендер"
                    )

                    FlowRow(
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                        verticalArrangement = Arrangement.spacedBy(8.dp),
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        equipmentList.forEach { eq ->
                            val isSelected = userPrefs.kitchenEquipment.contains(eq)
                            FilterChip(
                                selected = isSelected,
                                onClick = { onToggleEquipment(eq) },
                                label = { Text(eq) },
                                leadingIcon = if (isSelected) {
                                    { Icon(Icons.Default.CheckCircle, contentDescription = null, modifier = Modifier.size(16.dp)) }
                                } else null,
                                colors = FilterChipDefaults.filterChipColors(
                                    selectedContainerColor = SleekPriceGreen,
                                    selectedLabelColor = Color(0xFF1B381E),
                                    selectedLeadingIconColor = Color(0xFF1B381E),
                                    containerColor = SleekSurfaceVariant,
                                    labelColor = SleekTextPrimary
                                ),
                                border = FilterChipDefaults.filterChipBorder(
                                    borderColor = SleekBorder,
                                    selectedBorderColor = SleekPriceGreen,
                                    enabled = true,
                                    selected = isSelected
                                )
                            )
                        }
                    }
                }
            }
        }

        // Generate Action Button
        item {
            Button(
                onClick = onGenerateClick,
                enabled = !isLoading,
                modifier = Modifier
                    .fillMaxWidth()
                    .height(56.dp)
                    .testTag("generate_menu_button"),
                shape = RoundedCornerShape(16.dp),
                colors = ButtonDefaults.buttonColors(
                    containerColor = SleekPrimary,
                    contentColor = SleekOnPrimary
                ),
                elevation = ButtonDefaults.buttonElevation(defaultElevation = 4.dp)
            ) {
                if (isLoading) {
                    CircularProgressIndicator(
                        color = SleekOnPrimary,
                        modifier = Modifier.size(24.dp)
                    )
                    Spacer(modifier = Modifier.width(12.dp))
                    Text(
                        "Складання меню та розрахунок цін Сільпо...",
                        fontWeight = FontWeight.Bold,
                        fontSize = 15.sp,
                        color = SleekOnPrimary
                    )
                } else {
                    Icon(Icons.Default.AutoAwesome, contentDescription = null, tint = SleekOnPrimary)
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        "Сгенерировать меню на неделю",
                        fontWeight = FontWeight.Bold,
                        fontSize = 17.sp,
                        color = SleekOnPrimary
                    )
                }
            }
        }
    }

    // Token Modal Dialog
    if (showTokenDialog) {
        var tokenInput by remember { mutableStateOf(mcpStatus.bearerToken ?: "") }

        AlertDialog(
            onDismissRequest = { showTokenDialog = false },
            title = {
                Text(
                    "Сільпо MCP OAuth Token",
                    fontWeight = FontWeight.Bold
                )
            },
            text = {
                Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    Text(
                        "Введіть Bearer token для підключення до https://mcp.silpo.ua/mcp або залишіть порожнім для гостьового режиму:",
                        fontSize = 13.sp
                    )
                    OutlinedTextField(
                        value = tokenInput,
                        onValueChange = { tokenInput = it },
                        placeholder = { Text("eyJhbGciOiJSUzI1NiI...") },
                        modifier = Modifier.fillMaxWidth(),
                        singleLine = true
                    )
                }
            },
            confirmButton = {
                Button(
                    onClick = {
                        onUpdateToken(if (tokenInput.isBlank()) null else tokenInput)
                        showTokenDialog = false
                    },
                    colors = ButtonDefaults.buttonColors(containerColor = SilpoOrangePrimary)
                ) {
                    Text("Зберегти")
                }
            },
            dismissButton = {
                TextButton(onClick = { showTokenDialog = false }) {
                    Text("Скасувати")
                }
            }
        )
    }
}
