extends Resource
class_name AllyData

enum AllyType {
	RIFLEMAN,
	ROCKETEER,
	SUPPORT,
	MACHINE_GUNNER,
	SNIPER
}

enum TargetingMode {
	CLOSEST,
	FARTHEST,
	STRONGEST,
	WEAKEST,
}

@export var ally_type: Ally.AllyType
@export var ally_name: String = "Ally"
@export var targeting_mode: TargetingMode = TargetingMode.CLOSEST
@export var sprite_frames: SpriteFrames
@export var portrait: Texture2D

## Detection range for finding enemies
@export var detection_range: float = 500.0
## Fire rate in rounds per minute
@export var fire_rate: float = 300.0
## Bullet damage
@export var bullet_damage: int = 1
## Accuracy (0.0 = max spread, 1.0 = perfect)
@export_range(0.0, 1.0) var accuracy: float = 0.8
@export var max_spread: float = 30.0

# Sound effect
@export var sound_effect: AudioStream

# Rocket-specific properties
@export var explosion_damage: int = 18
@export var explosion_radius: float = 132.0

# Support-specific properties
@export var heal_amount: int = 1
@export var heal_interval: float = 2.0
