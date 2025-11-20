extends Resource
class_name AugmentData

@export var name: String = ""
@export var description: String = ""
@export var icon: Texture2D
@export var rarity: Rarity
@export var price: int = 100

# Primary effect
@export var augment_type: AugmentType
@export var value: float = 0.0  # Amount to modify (can be flat value or percentage)
@export var ability_script: Script  # For ABILITY type augments

# Secondary effect (optional penalty/bonus)
@export var has_secondary_effect: bool = false
@export var secondary_augment_type: AugmentType
@export var secondary_value: float = 0.0

# Tertiary effect (optional third effect)
@export var has_tertiary_effect: bool = false
@export var tertiary_augment_type: AugmentType
@export var tertiary_value: float = 0.0

enum Rarity {
	COMMON,
	UNCOMMON,
	RARE,
	ABILITY,
	LEGENDARY
}

enum AugmentType {
	MAX_HEALTH,           # +50 max health (flat)
	DAMAGE_MULTIPLIER,    # +0.1 = +10% damage (multiplier)
	FIRE_RATE,            # +0.15 = +15% fire rate (multiplier)
	CRIT_CHANCE,          # +0.05 = +5% crit chance (flat)
	CRIT_MULTIPLIER,      # +0.5 = +50% crit damage (flat)
	MOVEMENT_SPEED,       # +0.2 = +20% movement speed (multiplier)
	RELOAD_SPEED,         # -0.2 = -20% reload time (multiplier)
	MAGAZINE_SIZE,        # +10 magazine size (flat)
	ACCURACY,             # +0.1 = +10% accuracy (flat)
	PROJECTILE_PIERCING,  # value = 1 to enable (boolean)
	EXPLOSIVE_ROCKETS,    # value = 1 to enable (boolean)
	BLEED_CHANCE,         # +0.1 = +10% bleed chance (flat)
	ENEMY_DEATH_EXPLOSION_CHANCE, # +0.1 = +10% per stack enemy death explosion chance
	EXPLOSION_DAMAGE_MULTIPLIER,  # +0.5 = +50% explosion damage (multiplier)
	EXPLOSION_RADIUS_MULTIPLIER,  # +0.5 = +50% explosion radius (multiplier)
	ALLY_DAMAGE_MULTIPLIER, # Allies deal more damage (multiplier)
	ALLY_FIRE_RATE,         # Allies fire faster (multiplier)
	LASER_OF_DEATH,         # Enables/upgrades laser of death
	GOLD_GAIN_MULTIPLIER,   # +0.1 = +10% gold gain (multiplier)
	ABILITY,              # Grants an ability (uses ability_scene)
}
