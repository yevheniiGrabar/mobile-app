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
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.data.model.GroceryItemEntity
import com.example.ui.theme.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun GroceryListScreen(
    groceryList: List<GroceryItemEntity>,
    onToggleCheck: (String, Boolean) -> Unit,
    onReplaceClick: (GroceryItemEntity) -> Unit,
    onCheckoutClick: () -> Unit
) {
    var searchQuery by remember { mutableStateOf("") }
    var selectedStoreFilter by remember { mutableStateOf("Всі") } // "Всі", "Сільпо", "Спортмастер"
    var selectedSortMode by remember { mutableStateOf("Категорії") } // "Категорії", "Магазини", "Ціна ⬆️", "Ціна ⬇️", "Некуплені"
    var showSortMenu by remember { mutableStateOf(false) }

    val storeOptions = listOf("Всі", "Сільпо", "Спортмастер")

    // Filter by store & search query
    val filteredList = remember(groceryList, searchQuery, selectedStoreFilter) {
        groceryList.filter { item ->
            val matchesStore = when (selectedStoreFilter) {
                "Сільпо" -> item.store == "Сільпо"
                "Спортмастер" -> item.store == "Спортмастер"
                else -> true
            }
            val matchesSearch = searchQuery.isBlank() ||
                    item.name.contains(searchQuery, ignoreCase = true) ||
                    item.department.contains(searchQuery, ignoreCase = true)
            matchesStore && matchesSearch
        }
    }

    // Sort items
    val sortedList = remember(filteredList, selectedSortMode) {
        when (selectedSortMode) {
            "Магазини" -> filteredList.sortedWith(compareBy({ it.store }, { it.department }, { it.name }))
            "Ціна ⬆️" -> filteredList.sortedBy { it.priceUah }
            "Ціна ⬇️" -> filteredList.sortedByDescending { it.priceUah }
            "Некуплені" -> filteredList.sortedWith(compareBy({ it.isChecked }, { it.department }))
            else -> filteredList.sortedWith(compareBy({ it.department }, { it.name }))
        }
    }

    // Grouping depending on sort mode
    val groupedMap = remember(sortedList, selectedSortMode) {
        when (selectedSortMode) {
            "Магазини" -> sortedList.groupBy { "Магазин: ${it.store}" }
            "Некуплені" -> sortedList.groupBy { if (it.isChecked) "Куплені товари ✓" else "Необхідно купити 🛒" }
            else -> sortedList.groupBy { it.department.ifEmpty { "Бакалія" } }
        }
    }

    val totalCost = groceryList.sumOf { it.priceUah.toDouble() }.toFloat()
    val checkedCount = groceryList.count { it.isChecked }
    val totalCount = groceryList.size

    if (groceryList.isEmpty()) {
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(24.dp),
            contentAlignment = Alignment.Center
        ) {
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Icon(
                    Icons.Default.ShoppingBag,
                    contentDescription = null,
                    modifier = Modifier.size(64.dp),
                    tint = SleekPrimary
                )
                Spacer(modifier = Modifier.height(16.dp))
                Text("Список покупок порожній.", fontWeight = FontWeight.Bold, color = SleekTextPrimary)
                Spacer(modifier = Modifier.height(6.dp))
                Text("Згенеруйте меню на тиждень або додайте рецепти дня.", fontSize = 13.sp, color = SleekTextSecondary)
            }
        }
        return
    }

    LazyColumn(
        modifier = Modifier
            .fillMaxSize()
            .padding(horizontal = 16.dp),
        contentPadding = PaddingValues(top = 16.dp, bottom = 120.dp),
        verticalArrangement = Arrangement.spacedBy(14.dp)
    ) {
        // Shopping Header Summary Card
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
                        Column {
                            Text(
                                "Загальна вартість кошика",
                                color = SleekTextSecondary,
                                fontSize = 12.sp
                            )
                            Text(
                                "${totalCost.toInt()} ₴",
                                color = SleekPriceGreen,
                                fontWeight = FontWeight.ExtraBold,
                                fontSize = 28.sp
                            )
                        }

                        Surface(
                            color = SleekPrimaryContainer,
                            shape = RoundedCornerShape(12.dp)
                        ) {
                            Text(
                                text = "Куплено $checkedCount / $totalCount",
                                color = SleekPrimary,
                                fontWeight = FontWeight.Bold,
                                fontSize = 13.sp,
                                modifier = Modifier.padding(horizontal = 12.dp, vertical = 6.dp)
                            )
                        }
                    }

                    Spacer(modifier = Modifier.height(12.dp))

                    val progress = if (totalCount > 0) checkedCount.toFloat() / totalCount.toFloat() else 0f
                    LinearProgressIndicator(
                        progress = { progress },
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(8.dp)
                            .clip(RoundedCornerShape(4.dp)),
                        color = SleekPriceGreen,
                        trackColor = SleekBorder
                    )

                    Spacer(modifier = Modifier.height(14.dp))

                    Button(
                        onClick = onCheckoutClick,
                        colors = ButtonDefaults.buttonColors(
                            containerColor = SleekPrimary,
                            contentColor = SleekOnPrimary
                        ),
                        shape = RoundedCornerShape(12.dp),
                        modifier = Modifier
                            .fillMaxWidth()
                            .testTag("checkout_silpo_button")
                    ) {
                        Icon(Icons.Default.LocalShipping, contentDescription = null, tint = SleekOnPrimary)
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(
                            "Замовити в Сільпо & Спортмастер / MSP",
                            fontWeight = FontWeight.Bold,
                            fontSize = 14.sp,
                            color = SleekOnPrimary
                        )
                    }
                }
            }
        }

        // Search Bar & Sort Menu Controls
        item {
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                OutlinedTextField(
                    value = searchQuery,
                    onValueChange = { searchQuery = it },
                    placeholder = { Text("Пошук продукту...", fontSize = 13.sp, color = SleekTextMuted) },
                    leadingIcon = { Icon(Icons.Default.Search, contentDescription = null, tint = SleekTextSecondary) },
                    trailingIcon = {
                        if (searchQuery.isNotEmpty()) {
                            IconButton(onClick = { searchQuery = "" }) {
                                Icon(Icons.Default.Close, contentDescription = "Clear", tint = SleekTextSecondary)
                            }
                        }
                    },
                    shape = RoundedCornerShape(14.dp),
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedBorderColor = SleekPrimary,
                        unfocusedBorderColor = SleekBorder,
                        focusedContainerColor = SleekSurfaceVariant,
                        unfocusedContainerColor = SleekSurfaceVariant,
                        focusedTextColor = SleekTextPrimary,
                        unfocusedTextColor = SleekTextPrimary
                    ),
                    singleLine = true,
                    modifier = Modifier.weight(1f)
                )

                Box {
                    IconButton(
                        onClick = { showSortMenu = true },
                        modifier = Modifier
                            .background(SleekSurfaceVariant, RoundedCornerShape(14.dp))
                            .border(1.dp, SleekBorder, RoundedCornerShape(14.dp))
                    ) {
                        Icon(Icons.Default.Sort, contentDescription = "Сортування", tint = SleekPrimary)
                    }

                    DropdownMenu(
                        expanded = showSortMenu,
                        onDismissRequest = { showSortMenu = false },
                        modifier = Modifier.background(SleekSurface)
                    ) {
                        listOf("Категорії", "Магазини", "Ціна ⬆️", "Ціна ⬇️", "Некуплені").forEach { option ->
                            DropdownMenuItem(
                                text = { Text(option, color = SleekTextPrimary, fontSize = 13.sp) },
                                onClick = {
                                    selectedSortMode = option
                                    showSortMenu = false
                                }
                            )
                        }
                    }
                }
            }
        }

        // Store Filter Chips
        item {
            Row(
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text("Магазин:", fontSize = 12.sp, fontWeight = FontWeight.Bold, color = SleekTextSecondary)

                storeOptions.forEach { storeName ->
                    FilterChip(
                        selected = selectedStoreFilter == storeName,
                        onClick = { selectedStoreFilter = storeName },
                        label = { Text(storeName, fontSize = 12.sp) },
                        colors = FilterChipDefaults.filterChipColors(
                            selectedContainerColor = SleekPrimary,
                            selectedLabelColor = SleekOnPrimary,
                            containerColor = SleekSurfaceVariant,
                            labelColor = SleekTextSecondary
                        ),
                        border = FilterChipDefaults.filterChipBorder(
                            enabled = true,
                            selected = selectedStoreFilter == storeName,
                            borderColor = SleekBorder
                        )
                    )
                }
            }
        }

        // Items Grouped by Active Sort Category/Store
        groupedMap.forEach { (groupTitle, items) ->
            item {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    modifier = Modifier.padding(top = 8.dp)
                ) {
                    Icon(
                        if (groupTitle.contains("Магазин")) Icons.Default.Storefront else Icons.Default.Category,
                        contentDescription = null,
                        tint = SleekPrimary,
                        modifier = Modifier.size(18.dp)
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        text = groupTitle,
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold,
                        color = SleekTextPrimary
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        text = "(${items.size})",
                        fontSize = 13.sp,
                        color = SleekTextSecondary
                    )
                }
            }

            items(items) { grocery ->
                Card(
                    colors = CardDefaults.cardColors(
                        containerColor = if (grocery.isChecked) SleekSurfaceVariant.copy(alpha = 0.4f)
                        else SleekSurface
                    ),
                    border = BorderStroke(1.dp, SleekBorder),
                    shape = RoundedCornerShape(14.dp),
                    elevation = CardDefaults.cardElevation(defaultElevation = 1.dp),
                    modifier = Modifier
                        .fillMaxWidth()
                        .testTag("grocery_item_${grocery.id}")
                ) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(12.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Checkbox(
                            checked = grocery.isChecked,
                            onCheckedChange = { isChecked -> onToggleCheck(grocery.id, isChecked) },
                            colors = CheckboxDefaults.colors(
                                checkedColor = SleekPrimary,
                                checkmarkColor = SleekOnPrimary,
                                uncheckedColor = SleekTextMuted
                            )
                        )

                        Spacer(modifier = Modifier.width(8.dp))

                        Column(modifier = Modifier.weight(1f)) {
                            Text(
                                text = grocery.name,
                                fontWeight = FontWeight.Bold,
                                fontSize = 15.sp,
                                textDecoration = if (grocery.isChecked) TextDecoration.LineThrough else TextDecoration.None,
                                color = if (grocery.isChecked) SleekTextMuted else SleekTextPrimary,
                                maxLines = 1,
                                overflow = TextOverflow.Ellipsis
                            )

                            Row(
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.spacedBy(8.dp)
                            ) {
                                Text(
                                    text = grocery.quantity,
                                    fontSize = 12.sp,
                                    color = SleekTextSecondary
                                )

                                Surface(
                                    color = if (grocery.store == "Спортмастер") SleekAccentOrange.copy(alpha = 0.2f) else SleekPrimaryContainer,
                                    shape = RoundedCornerShape(4.dp)
                                ) {
                                    Text(
                                        text = grocery.store,
                                        fontSize = 10.sp,
                                        color = if (grocery.store == "Спортмастер") SleekAccentOrange else SleekPrimary,
                                        fontWeight = FontWeight.Bold,
                                        modifier = Modifier.padding(horizontal = 4.dp, vertical = 2.dp)
                                    )
                                }

                                if (grocery.isReplaced) {
                                    Surface(
                                        color = SleekPriceGreen.copy(alpha = 0.2f),
                                        shape = RoundedCornerShape(4.dp)
                                    ) {
                                        Text(
                                            text = "Замінено на дешевше",
                                            fontSize = 10.sp,
                                            color = SleekPriceGreen,
                                            fontWeight = FontWeight.Bold,
                                            modifier = Modifier.padding(horizontal = 4.dp, vertical = 2.dp)
                                        )
                                    }
                                }
                            }
                        }

                        Spacer(modifier = Modifier.width(8.dp))

                        Column(horizontalAlignment = Alignment.End) {
                            Text(
                                text = "${grocery.priceUah.toInt()} ₴",
                                fontWeight = FontWeight.Bold,
                                fontSize = 15.sp,
                                color = SleekPriceGreen
                            )

                            TextButton(
                                onClick = { onReplaceClick(grocery) },
                                contentPadding = PaddingValues(0.dp),
                                modifier = Modifier.height(28.dp)
                            ) {
                                Text(
                                    text = "Замінити ₴",
                                    fontSize = 11.sp,
                                    color = SleekPrimary,
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

