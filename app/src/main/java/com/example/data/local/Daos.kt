package com.example.data.local

import androidx.room.*
import com.example.data.model.CulinaryChallengeEntity
import com.example.data.model.GroceryItemEntity
import com.example.data.model.LoggedMealEntity
import com.example.data.model.RewardOfferEntity
import com.example.data.model.UserSettingsEntity
import kotlinx.coroutines.flow.Flow

@Dao
interface GroceryDao {
    @Query("SELECT * FROM grocery_items ORDER BY store ASC, department ASC, name ASC")
    fun getAllGroceryItems(): Flow<List<GroceryItemEntity>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAll(items: List<GroceryItemEntity>)

    @Query("UPDATE grocery_items SET isChecked = :isChecked WHERE id = :id")
    suspend fun updateCheckState(id: String, isChecked: Boolean)

    @Query("UPDATE grocery_items SET name = :newName, priceUah = :newPrice, isReplaced = 1, originalName = :originalName WHERE id = :id")
    suspend fun replaceItem(id: String, newName: String, newPrice: Float, originalName: String)

    @Query("DELETE FROM grocery_items")
    suspend fun clearAll()
}

@Dao
interface ChallengeDao {
    @Query("SELECT * FROM culinary_challenges")
    fun getAllChallenges(): Flow<List<CulinaryChallengeEntity>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAll(challenges: List<CulinaryChallengeEntity>)

    @Query("UPDATE culinary_challenges SET isAccepted = :isAccepted WHERE id = :id")
    suspend fun setAccepted(id: String, isAccepted: Boolean)

    @Query("UPDATE culinary_challenges SET isCompleted = 1 WHERE id = :id")
    suspend fun setCompleted(id: String)
}

@Dao
interface RewardDao {
    @Query("SELECT * FROM user_rewards")
    fun getAllRewards(): Flow<List<RewardOfferEntity>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAll(rewards: List<RewardOfferEntity>)

    @Query("UPDATE user_rewards SET isRedeemed = 1 WHERE id = :id")
    suspend fun setRedeemed(id: String)
}

@Dao
interface UserSettingsDao {
    @Query("SELECT * FROM user_settings WHERE id = 1")
    fun getUserSettings(): Flow<UserSettingsEntity?>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun saveUserSettings(settings: UserSettingsEntity)

    @Query("UPDATE user_settings SET rewardPoints = rewardPoints + :points WHERE id = 1")
    suspend fun addRewardPoints(points: Int)

    @Query("UPDATE user_settings SET rewardPoints = rewardPoints - :points WHERE id = 1")
    suspend fun deductRewardPoints(points: Int)
}

@Dao
interface NutritionDao {
    @Query("SELECT * FROM logged_meals WHERE dateString = :date ORDER BY timestamp DESC")
    fun getLoggedMealsForDate(date: String): Flow<List<LoggedMealEntity>>

    @Query("SELECT * FROM logged_meals ORDER BY timestamp DESC")
    fun getAllLoggedMeals(): Flow<List<LoggedMealEntity>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertLoggedMeal(meal: LoggedMealEntity)

    @Query("DELETE FROM logged_meals WHERE id = :id")
    suspend fun deleteLoggedMeal(id: String)

    @Query("DELETE FROM logged_meals WHERE dateString = :date")
    suspend fun clearLoggedMealsForDate(date: String)
}

