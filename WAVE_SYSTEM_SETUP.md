# Wave System Setup Guide

## ✅ Implementation Complete

The wave system has been successfully implemented with the following features:

### Features
- **10 Waves** - Each wave lasts exactly as long as GameManager's day timer
- **3 Difficulty Phases per Wave** - Easy (0-33%), Medium (33-67%), Hard (67-100%)
- **Manual Configuration** - Full control over enemy pools and weights for each phase
- **Weighted Random Spawning** - Enemies spawn based on configurable weights
- **EnemyData Injection** - Enemy stats injected from EnemyData resources
- **Terrain-Based Spawning** - Ground enemies spawn at ground markers, air at air markers

## Setup Instructions

### 1. Add WaveManager to Scene
1. Open your main game scene (where GameManager exists)
2. Add a new **Node** as a child
3. Attach the script: `Scripts/WaveManager/wave_manager.gd`
4. Rename the node to "WaveManager"

### 2. Configure Waves in Inspector
Select the WaveManager node and configure the waves:

1. Set **Waves** array size to **10**
2. For each wave (0-9), create a **new WaveData resource**:
   - Right-click → New Resource → WaveData
   - Save each as `wave_1.tres`, `wave_2.tres`, etc. in `Scripts/Resources/`

### 3. Configure Each WaveData

For each wave, set the following in the Inspector:

#### Wave 1 (Tutorial Wave)
```
Wave Number: 1
Base Spawn Interval: 2.5

Easy Enemies: [BasicEnemyData]
Easy Weights: [1.0]

Medium Enemies: [BasicEnemyData]
Medium Weights: [1.0]

Hard Enemies: [BasicEnemyData, FastEnemyData]
Hard Weights: [0.7, 0.3]

Easy Spawn Multiplier: 1.5
Medium Spawn Multiplier: 1.0
Hard Spawn Multiplier: 0.7
```

#### Wave 5 (Mid-Game)
```
Wave Number: 5
Base Spawn Interval: 1.8

Easy Enemies: [BasicEnemyData, FastEnemyData]
Easy Weights: [0.7, 0.3]

Medium Enemies: [BasicEnemyData, FastEnemyData, TankEnemyData]
Medium Weights: [0.5, 0.3, 0.2]

Hard Enemies: [FastEnemyData, TankEnemyData, FlyingEnemyData]
Hard Weights: [0.4, 0.4, 0.2]

Easy Spawn Multiplier: 1.3
Medium Spawn Multiplier: 1.0
Hard Spawn Multiplier: 0.6
```

#### Wave 10 (Final Wave)
```
Wave Number: 10
Base Spawn Interval: 1.0

Easy Enemies: [FastEnemyData, TankEnemyData]
Easy Weights: [0.6, 0.4]

Medium Enemies: [TankEnemyData, FlyingEnemyData, EliteEnemyData]
Medium Weights: [0.5, 0.3, 0.2]

Hard Enemies: [FlyingEnemyData, EliteEnemyData, BossEnemyData]
Hard Weights: [0.3, 0.4, 0.3]

Easy Spawn Multiplier: 1.2
Medium Spawn Multiplier: 0.9
Hard Spawn Multiplier: 0.5
```

## Creating Enemy Data Resources

1. Create new **EnemyData** resources in `Data/EnemyData/`
2. Configure stats for each enemy type:

Example: `basic_enemy.tres`
```
Enemy Name: "Basic Enemy"
Speed: 2.0
Max Health: 5
Range: 30
Damage: 1
Attack Speed: 1.0
Gold Reward: 5
Gold Reward Variance: 2
Terrain Type: GROUND
```

Example: `flying_enemy.tres`
```
Enemy Name: "Flying Enemy"
Speed: 3.0
Max Health: 3
Range: 40
Damage: 2
Attack Speed: 1.2
Gold Reward: 8
Gold Reward Variance: 3
Terrain Type: AIR
```

## How It Works

1. **Wave Start**: When `start_new_day` signal fires, WaveManager starts the current wave
2. **Day Progress Tracking**: WaveManager monitors GameManager's day_timer
3. **Phase Transitions**:
   - 0-33% → Easy enemies spawn from easy_enemies pool
   - 33-67% → Medium enemies spawn from medium_enemies pool
   - 67-100% → Hard enemies spawn from hard_enemies pool
4. **Spawn Rate Changes**: Spawn interval adjusts based on current phase multiplier
5. **Weighted Selection**: Random enemy chosen using weights (higher = more common)
6. **Enemy Injection**: Selected EnemyData stats injected into enemy_base instance
7. **Terrain Spawning**: Ground/Air terrain type determines spawn location
8. **Wave End**: When day_timer expires, wave completes and index advances

## UI Integration

The PlayerHUD already has wave info display support. Access wave info via:

```gdscript
var wave_info = game_manager.get_wave_info()
# Returns:
# {
#   "current_wave": 5,
#   "total_waves": 10,
#   "day_progress": 0.45,
#   "current_difficulty": "medium",
#   "is_spawning": true
# }
```

## Testing

1. Run the game
2. Watch console for wave start messages
3. Observe difficulty phase transitions at 33% and 67% of day timer
4. Notice spawn rate changes between phases
5. Complete a wave to advance to the next

## Troubleshooting

**No enemies spawning?**
- Check WaveManager node exists in scene
- Verify waves array is configured
- Check enemy_enemies/medium_enemies/hard_enemies are not empty
- Ensure weights arrays match enemy arrays in size

**Wrong spawn locations?**
- Verify EnemyData terrain_type is set correctly
- Check Spawner has Ground and Air marker children

**Waves not advancing?**
- Ensure GameManager signals are connected
- Check day_timer_finished signal is firing
- Verify WaveManager is in "wave_manager" group

## Tips

- **Balance Early Waves**: Start with fewer enemy types and simple pools
- **Scale Difficulty**: Gradually introduce tougher enemies in later waves
- **Test Weights**: Higher weights = more common spawns (1.0 vs 0.3 = 3x more likely)
- **Spawn Timing**: Lower multipliers = faster spawning (0.5 = twice as fast)
- **Phase Variety**: Mix enemy types differently across phases for dynamic gameplay

Enjoy your 10-wave progression system! ���
