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
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.data.model.CulinaryChallengeEntity
import com.example.data.model.RewardOfferEntity
import com.example.ui.theme.*

@Composable
fun ChallengesScreen(
    userPoints: Int,
    challenges: List<CulinaryChallengeEntity>,
    rewards: List<RewardOfferEntity>,
    onAcceptChallenge: (String) -> Unit,
    onCompleteChallenge: (String) -> Unit,
    onRedeemReward: (RewardOfferEntity) -> Unit,
    onCopyCode: (String) -> Unit
) {
    var selectedTab by remember { mutableStateOf(0) } // 0 = Challenges, 1 = Rewards Store

    LazyColumn(
        modifier = Modifier
            .fillMaxSize()
            .testTag("challenges_screen"),
        contentPadding = PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        // User Balance & Status Card
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
                                "Ваш баланс балів Сільпо & Спортмастер",
                                color = SleekTextSecondary,
                                fontSize = 12.sp
                            )
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Icon(Icons.Default.Stars, contentDescription = null, tint = SleekAccentOrange, modifier = Modifier.size(28.dp))
                                Spacer(modifier = Modifier.width(6.dp))
                                Text(
                                    "$userPoints балів",
                                    color = SleekPriceGreen,
                                    fontWeight = FontWeight.ExtraBold,
                                    fontSize = 26.sp
                                )
                            }
                        }

                        Surface(
                            color = SleekPrimaryContainer,
                            shape = RoundedCornerShape(12.dp)
                        ) {
                            Row(
                                modifier = Modifier.padding(horizontal = 12.dp, vertical = 6.dp),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Icon(Icons.Default.EmojiEvents, contentDescription = null, tint = SleekPrimary, modifier = Modifier.size(16.dp))
                                Spacer(modifier = Modifier.width(4.dp))
                                Text(
                                    "Рівень: Кулінар-Про",
                                    color = SleekPrimary,
                                    fontWeight = FontWeight.Bold,
                                    fontSize = 12.sp
                                )
                            }
                        }
                    }

                    Spacer(modifier = Modifier.height(14.dp))

                    Text(
                        "Виконуйте завдання та обмінюйте бали на ексклюзивні знижки у Партнерів!",
                        fontSize = 12.sp,
                        color = SleekTextSecondary
                    )
                }
            }
        }

        // Tab Selector (Challenges vs Rewards Store)
        item {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Button(
                    onClick = { selectedTab = 0 },
                    colors = ButtonDefaults.buttonColors(
                        containerColor = if (selectedTab == 0) SleekPrimary else SleekSurfaceVariant,
                        contentColor = if (selectedTab == 0) SleekOnPrimary else SleekTextSecondary
                    ),
                    shape = RoundedCornerShape(12.dp),
                    modifier = Modifier.weight(1f)
                ) {
                    Icon(Icons.Default.EmojiEvents, contentDescription = null, modifier = Modifier.size(18.dp))
                    Spacer(modifier = Modifier.width(6.dp))
                    Text("Кулінарні Виклики", fontSize = 13.sp, fontWeight = FontWeight.Bold)
                }

                Button(
                    onClick = { selectedTab = 1 },
                    colors = ButtonDefaults.buttonColors(
                        containerColor = if (selectedTab == 1) SleekPrimary else SleekSurfaceVariant,
                        contentColor = if (selectedTab == 1) SleekOnPrimary else SleekTextSecondary
                    ),
                    shape = RoundedCornerShape(12.dp),
                    modifier = Modifier.weight(1f)
                ) {
                    Icon(Icons.Default.ConfirmationNumber, contentDescription = null, modifier = Modifier.size(18.dp))
                    Spacer(modifier = Modifier.width(6.dp))
                    Text("Магазин Знижок", fontSize = 13.sp, fontWeight = FontWeight.Bold)
                }
            }
        }

        if (selectedTab == 0) {
            // Challenges Tab
            items(challenges) { ch ->
                Card(
                    colors = CardDefaults.cardColors(
                        containerColor = if (ch.isCompleted) SleekSurfaceVariant.copy(alpha = 0.5f) else SleekSurface
                    ),
                    border = BorderStroke(1.dp, if (ch.isCompleted) SleekPriceGreen else SleekBorder),
                    shape = RoundedCornerShape(16.dp),
                    elevation = CardDefaults.cardElevation(defaultElevation = 1.dp),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Row(
                        modifier = Modifier.padding(16.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Surface(
                            color = if (ch.isCompleted) SleekPriceGreen.copy(alpha = 0.2f) else SleekPrimaryContainer,
                            shape = CircleShape,
                            modifier = Modifier.size(48.dp)
                        ) {
                            Box(contentAlignment = Alignment.Center) {
                                Icon(
                                    if (ch.isCompleted) Icons.Default.CheckCircle else Icons.Default.EmojiEvents,
                                    contentDescription = null,
                                    tint = if (ch.isCompleted) SleekPriceGreen else SleekPrimary,
                                    modifier = Modifier.size(24.dp)
                                )
                            }
                        }

                        Spacer(modifier = Modifier.width(14.dp))

                        Column(modifier = Modifier.weight(1f)) {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Text(
                                    text = ch.title,
                                    fontWeight = FontWeight.Bold,
                                    fontSize = 15.sp,
                                    color = SleekTextPrimary
                                )
                            }

                            Spacer(modifier = Modifier.height(4.dp))

                            Text(
                                text = ch.description,
                                fontSize = 12.sp,
                                color = SleekTextSecondary
                            )

                            Spacer(modifier = Modifier.height(8.dp))

                            Surface(
                                color = SleekAccentOrange.copy(alpha = 0.15f),
                                shape = RoundedCornerShape(6.dp)
                            ) {
                                Text(
                                    text = "+${ch.rewardPoints} балів",
                                    color = SleekAccentOrange,
                                    fontWeight = FontWeight.Bold,
                                    fontSize = 11.sp,
                                    modifier = Modifier.padding(horizontal = 8.dp, vertical = 2.dp)
                                )
                            }
                        }

                        Spacer(modifier = Modifier.width(8.dp))

                        if (ch.isCompleted) {
                            Surface(
                                color = SleekPriceGreen,
                                shape = RoundedCornerShape(8.dp)
                            ) {
                                Text(
                                    "Виконано ✓",
                                    color = SleekOnPrimary,
                                    fontSize = 11.sp,
                                    fontWeight = FontWeight.Bold,
                                    modifier = Modifier.padding(horizontal = 8.dp, vertical = 6.dp)
                                )
                            }
                        } else if (!ch.isAccepted) {
                            OutlinedButton(
                                onClick = { onAcceptChallenge(ch.id) },
                                shape = RoundedCornerShape(10.dp),
                                border = BorderStroke(1.dp, SleekPrimary),
                                contentPadding = PaddingValues(horizontal = 10.dp, vertical = 4.dp)
                            ) {
                                Text("Прийняти", fontSize = 11.sp, color = SleekPrimary, fontWeight = FontWeight.Bold)
                            }
                        } else {
                            Button(
                                onClick = { onCompleteChallenge(ch.id) },
                                shape = RoundedCornerShape(10.dp),
                                colors = ButtonDefaults.buttonColors(containerColor = SleekPriceGreen, contentColor = SleekOnPrimary),
                                contentPadding = PaddingValues(horizontal = 10.dp, vertical = 4.dp)
                            ) {
                                Text("Зарахувати!", fontSize = 11.sp, fontWeight = FontWeight.Bold)
                            }
                        }
                    }
                }
            }
        } else {
            // Partner Rewards Store Tab
            items(rewards) { reward ->
                Card(
                    colors = CardDefaults.cardColors(containerColor = SleekSurface),
                    border = BorderStroke(1.dp, SleekBorder),
                    shape = RoundedCornerShape(16.dp),
                    elevation = CardDefaults.cardElevation(defaultElevation = 1.dp),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Column(modifier = Modifier.padding(16.dp)) {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Surface(
                                color = if (reward.partner == "Спортмастер") SleekAccentOrange else SleekPrimary,
                                shape = RoundedCornerShape(8.dp)
                            ) {
                                Text(
                                    reward.partner,
                                    color = SleekOnPrimary,
                                    fontWeight = FontWeight.Bold,
                                    fontSize = 11.sp,
                                    modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp)
                                )
                            }

                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Icon(Icons.Default.Stars, contentDescription = null, tint = SleekAccentOrange, modifier = Modifier.size(16.dp))
                                Spacer(modifier = Modifier.width(4.dp))
                                Text(
                                    "${reward.pointsCost} балів",
                                    fontWeight = FontWeight.Bold,
                                    fontSize = 13.sp,
                                    color = SleekTextPrimary
                                )
                            }
                        }

                        Spacer(modifier = Modifier.height(10.dp))

                        Text(
                            text = reward.title,
                            fontWeight = FontWeight.Bold,
                            fontSize = 16.sp,
                            color = SleekTextPrimary
                        )

                        Spacer(modifier = Modifier.height(4.dp))

                        Text(
                            text = reward.description,
                            fontSize = 12.sp,
                            color = SleekTextSecondary
                        )

                        Spacer(modifier = Modifier.height(14.dp))

                        if (reward.isRedeemed) {
                            Surface(
                                color = SleekSurfaceVariant,
                                shape = RoundedCornerShape(10.dp),
                                border = BorderStroke(1.dp, SleekPriceGreen),
                                modifier = Modifier.fillMaxWidth()
                            ) {
                                Row(
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .padding(10.dp),
                                    horizontalArrangement = Arrangement.SpaceBetween,
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Column {
                                        Text("Ваш промокод:", fontSize = 10.sp, color = SleekTextSecondary)
                                        Text(
                                            reward.discountCode,
                                            fontWeight = FontWeight.ExtraBold,
                                            fontSize = 16.sp,
                                            color = SleekPriceGreen
                                        )
                                    }

                                    IconButton(onClick = { onCopyCode(reward.discountCode) }) {
                                        Icon(Icons.Default.ContentCopy, contentDescription = "Скопіювати", tint = SleekPrimary)
                                    }
                                }
                            }
                        } else {
                            val canAfford = userPoints >= reward.pointsCost
                            Button(
                                onClick = { onRedeemReward(reward) },
                                enabled = canAfford,
                                shape = RoundedCornerShape(12.dp),
                                colors = ButtonDefaults.buttonColors(
                                    containerColor = SleekPrimary,
                                    contentColor = SleekOnPrimary,
                                    disabledContainerColor = SleekSurfaceVariant,
                                    disabledContentColor = SleekTextMuted
                                ),
                                modifier = Modifier.fillMaxWidth()
                            ) {
                                Text(
                                    if (canAfford) "Отримати купон" else "Недостатньо балів (${reward.pointsCost - userPoints} не вистачає)",
                                    fontSize = 13.sp,
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
