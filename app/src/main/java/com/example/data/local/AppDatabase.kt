package com.example.data.local

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase
import com.example.data.model.CulinaryChallengeEntity
import com.example.data.model.GroceryItemEntity
import com.example.data.model.LoggedMealEntity
import com.example.data.model.RewardOfferEntity
import com.example.data.model.UserSettingsEntity

@Database(
    entities = [
        GroceryItemEntity::class,
        UserSettingsEntity::class,
        CulinaryChallengeEntity::class,
        RewardOfferEntity::class,
        LoggedMealEntity::class
    ],
    version = 3,
    exportSchema = false
)
abstract class AppDatabase : RoomDatabase() {
    abstract fun groceryDao(): GroceryDao
    abstract fun userSettingsDao(): UserSettingsDao
    abstract fun challengeDao(): ChallengeDao
    abstract fun rewardDao(): RewardDao
    abstract fun nutritionDao(): NutritionDao

    companion object {
        @Volatile
        private var INSTANCE: AppDatabase? = null

        fun getInstance(context: Context): AppDatabase {
            return INSTANCE ?: synchronized(this) {
                val instance = Room.databaseBuilder(
                    context.applicationContext,
                    AppDatabase::class.java,
                    "silpo_menu_db"
                ).fallbackToDestructiveMigration().build()
                INSTANCE = instance
                instance
            }
        }
    }
}

