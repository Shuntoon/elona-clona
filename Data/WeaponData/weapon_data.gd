extends Resource
class_name WeaponData

@export_category("General")
@export var weapon_name : String = "New Weapon"
@export_multiline var description : String = "A description of the weapon."
@export var icon : Texture2D
@export var price : int = 100
@export var sound_effect : AudioStream
@export var reload_sound_effect : AudioStream

@export_category("Shooting Properties")
@export var bullet_type : MouseShooter.BULLET_TYPE
@export var fire_mode : MouseShooter.FIRE_MODE
@export_range(0.0, 1.0) var accuracy: float = 1.0
@export var max_spread: float = 50.0
@export var fire_rate: float = 600.0
@export var magazine_size: int = 30
@export var reload_time: float = 2.0
@export var projectile_piercing: bool = false
@export_range(0.0, 1.0) var crit_chance: float = 0.1
@export var crit_multiplier: float = 2.0
@export var bullet_damage: int = 1
@export_range(0.0, 1.0) var bleed_chance: float = 0.0

@export_category("Burst Properties")
@export var burst_count: int = 3
@export var burst_delay: float = 0.1

@export_category("Projectile Properties")
@export var bullet_speed: float = 500.0

@export_category("Rocket Properties")
@export var explosive_rockets: bool = false
@export var explosion_damage: int = 10
@export var explosion_radius: float = 100.0
@export var explosion_visual_scale: float = 1.0
