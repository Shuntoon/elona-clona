extends Node2D
class_name MouseShooter

const HITBOX = preload("uid://bg6uxodad3g5f")
@export var BULLET_BASE : PackedScene
const HIT_ENEMY_VFX = preload("uid://cubkpuvcxnh63")
const HIT_GROUND_VFX = preload("uid://doaytv1th1j3v")
const EXPLOSION = preload("uid://cp6c33t2cjpx5")


# Add to group so HUD can find it
func _enter_tree() -> void:
	add_to_group("mouse_shooter")

@export var weapon_data : WeaponData

@export_range(0.0, 1.0) var accuracy: float = 1.0
@export var max_spread: float = 50.0
@export var bullet_type : BULLET_TYPE
@export var fire_mode : FIRE_MODE
@export var fire_rate: float = 600.0
@export var burst_count: int = 3
@export var burst_delay: float = 0.1
@export var magazine_size: int = 30
@export var reload_time: float = 2.0
@export var projectile_piercing: bool = false
@export var explosive_rockets: bool = false
@export var bullet_damage: int = 1
@export var explosion_damage: int = 10
@export var explosion_radius: float = 100.0
@export_range(0.0, 1.0) var crit_chance: float = 0.1
@export var crit_multiplier: float = 2.0

var bullet_spawn_point : Vector2 = Vector2(1035, 508)

enum BULLET_TYPE {
	HITSCAN,
	PROJECTILE
}

enum FIRE_MODE {
	SEMI_AUTO,
	BURST,
	AUTOMATIC
}

# Internal state
var can_shoot: bool = true
var is_shooting: bool = false
var time_between_shots: float
var current_ammo: int
var is_reloading: bool = false
var reload_progress: float = 0.0  # 0.0 to 1.0

var neutral_entities : Node2D
var game_manager: GameManager
var current_weapon_slot: int = 1  # 1 or 2

# Saved ammo for each weapon slot
var weapon_1_ammo: int = -1  # -1 means not yet initialized
var weapon_2_ammo: int = -1

func _ready() -> void:
	game_manager = get_tree().get_first_node_in_group("game_manager")
	
	# Connect to start_new_day signal to re-equip weapons
	if game_manager:
		game_manager.start_new_day.connect(_on_start_new_day)
	
	# Load weapon 1 by default
	_equip_weapon(1)

	neutral_entities = get_tree().get_first_node_in_group("neutral_entities")
	time_between_shots = 60.0 / fire_rate  # Convert RPM to seconds
	current_ammo = magazine_size

func _process(_delta: float) -> void:
	# Handle automatic fire
	if fire_mode == FIRE_MODE.AUTOMATIC and is_shooting and can_shoot and not is_reloading:
		_fire_bullet()
		can_shoot = false
		await get_tree().create_timer(time_between_shots).timeout
		can_shoot = true

func _unhandled_input(event: InputEvent) -> void:
	# Weapon switching
	if event.is_action_pressed("weapon_1"):
		if is_reloading:
			is_reloading = false
		_equip_weapon(1)
	elif event.is_action_pressed("weapon_2"):
		if is_reloading:
			is_reloading = false
		_equip_weapon(2)
	
	# Manual reload
	if event.is_action_pressed("reload") and not is_reloading and current_ammo < magazine_size:
		_start_reload()
	
	if event.is_action_pressed("shoot"):
		# Auto reload if empty
		if current_ammo <= 0 and not is_reloading:
			_start_reload()
			return
		
		if not is_reloading:
			is_shooting = true
			match fire_mode:
				FIRE_MODE.SEMI_AUTO:
					if can_shoot:
						_fire_bullet()
						can_shoot = false
						await get_tree().create_timer(time_between_shots).timeout
						can_shoot = true
				
				FIRE_MODE.BURST:
					if can_shoot:
						_fire_burst()
				
				FIRE_MODE.AUTOMATIC:
					# Handled in _process
					pass
	
	if event.is_action_released("shoot"):
		is_shooting = false

func _equip_weapon(slot: int) -> void:
	# Save current ammo before switching (skip if that weapon is in reset state)
	if current_weapon_slot == 1 and weapon_1_ammo >= 0:
		weapon_1_ammo = current_ammo
	elif current_weapon_slot == 2 and weapon_2_ammo >= 0:
		weapon_2_ammo = current_ammo
	
	var weapon_to_equip: WeaponData = null
	
	if slot == 1:
		weapon_to_equip = PlayerData.weapon_1_data
	elif slot == 2:
		weapon_to_equip = PlayerData.weapon_2_data
	
	if not weapon_to_equip:
		print("No weapon data in slot ", slot)
		return
	
	# Cancel reload if switching
	is_reloading = false
	is_shooting = false
	
	# Apply weapon data to shooter properties
	weapon_data = weapon_to_equip
	accuracy = weapon_to_equip.accuracy
	max_spread = weapon_to_equip.max_spread
	bullet_type = weapon_to_equip.bullet_type
	fire_mode = weapon_to_equip.fire_mode
	fire_rate = weapon_to_equip.fire_rate
	burst_count = weapon_to_equip.burst_count
	burst_delay = weapon_to_equip.burst_delay
	magazine_size = weapon_to_equip.magazine_size
	reload_time = weapon_to_equip.reload_time
	projectile_piercing = weapon_to_equip.projectile_piercing
	explosive_rockets = weapon_to_equip.explosive_rockets
	bullet_damage = weapon_to_equip.bullet_damage
	explosion_damage = weapon_to_equip.explosion_damage
	explosion_radius = weapon_to_equip.explosion_radius
	crit_chance = weapon_to_equip.crit_chance
	crit_multiplier = weapon_to_equip.crit_multiplier
	
	# Update internal state
	time_between_shots = 60.0 / fire_rate
	
	# Restore saved ammo for this weapon, or set to full magazine if first time
	if slot == 1:
		current_ammo = weapon_1_ammo if weapon_1_ammo >= 0 else magazine_size
		weapon_1_ammo = current_ammo  # Update in case it was -1
	elif slot == 2:
		current_ammo = weapon_2_ammo if weapon_2_ammo >= 0 else magazine_size
		weapon_2_ammo = current_ammo  # Update in case it was -1
	
	current_weapon_slot = slot
	
	print("Equipped weapon: ", weapon_to_equip.weapon_name, " (Slot ", slot, ") - Ammo: ", current_ammo, "/", magazine_size)

func _on_start_new_day() -> void:
	# Reset ammo for both weapons when a new day starts
	weapon_1_ammo = -1
	weapon_2_ammo = -1
	
	# Re-equip the current weapon to refresh stats from PlayerData
	_equip_weapon(current_weapon_slot)
	print("Re-equipped weapon for new day with full ammo")

func _set_shooter_properties() -> void:
	pass


func _fire_burst() -> void:
	can_shoot = false
	for i in burst_count:
		if current_ammo <= 0:
			_start_reload()
			break
		_fire_bullet()
		if i < burst_count - 1:  # Don't wait after last shot
			await get_tree().create_timer(burst_delay).timeout
	
	await get_tree().create_timer(time_between_shots).timeout
	can_shoot = true

func _start_reload() -> void:
	if is_reloading:
		return
	
	is_reloading = true
	is_shooting = false
	reload_progress = 0.0
	
	var elapsed = 0.0
	while elapsed < reload_time and is_reloading:  # Check is_reloading in loop condition
		await get_tree().process_frame
		var delta = get_process_delta_time()
		elapsed += delta
		reload_progress = elapsed / reload_time
	
	# Only complete reload if we weren't interrupted
	if is_reloading:
		current_ammo = magazine_size
	
	is_reloading = false
	reload_progress = 0.0

func _fire_bullet() -> void:
	if current_ammo <= 0:
		return
	
	current_ammo -= 1
	
	if bullet_type == BULLET_TYPE.HITSCAN:
		if not HITBOX:
			print("ERROR: HITBOX scene is null!")
			return
		
		var hitbox_inst : Hitbox = HITBOX.instantiate()
		if not hitbox_inst:
			print("ERROR: Failed to instantiate HITBOX!")
			return
		
		hitbox_inst.destroy_instantly = true
		hitbox_inst.damage = bullet_damage
		hitbox_inst.crit_chance = crit_chance
		hitbox_inst.crit_multiplier = crit_multiplier
		hitbox_inst.hit_enemy_vfx = HIT_ENEMY_VFX
		hitbox_inst.hit_ground_vfx = HIT_GROUND_VFX
		hitbox_inst.global_position = get_global_mouse_position() + _calculate_accuracy_offset()
		if neutral_entities != null:
			neutral_entities.add_child(hitbox_inst)
		else:
			print("no entities")
	
	if bullet_type == BULLET_TYPE.PROJECTILE:
		if not BULLET_BASE:
			print("ERROR: BULLET_BASE scene is null!")
			return
		
		var bullet_base_inst : Bullet = BULLET_BASE.instantiate()
		if not bullet_base_inst:
			print("ERROR: Failed to instantiate BULLET_BASE!")
			return
		
		bullet_base_inst.global_position = bullet_spawn_point
		bullet_base_inst.target = get_global_mouse_position() + _calculate_accuracy_offset()
		bullet_base_inst.piercing = projectile_piercing  # Set piercing based on export variable
		bullet_base_inst.explosive = explosive_rockets
		bullet_base_inst.explosion_damage = explosion_damage
		bullet_base_inst.explosion_radius = explosion_radius
		bullet_base_inst.explosion_scene = EXPLOSION
		bullet_base_inst.hit_enemy_vfx = HIT_ENEMY_VFX
		bullet_base_inst.hit_ground_vfx = HIT_GROUND_VFX
		
		# Set bullet damage and crit via hitbox
		var hitbox = bullet_base_inst.get_node_or_null("Hitbox")
		if hitbox:
			hitbox.damage = bullet_damage
			hitbox.crit_chance = crit_chance
			hitbox.crit_multiplier = crit_multiplier
		if neutral_entities != null:
			neutral_entities.add_child(bullet_base_inst)
		else:
			print("no entites") 

## Calculates a random offset based on accuracy value
func _calculate_accuracy_offset() -> Vector2:
	# Invert accuracy so 0 accuracy = max spread, 1 accuracy = no spread
	var spread = (1.0 - accuracy) * max_spread
	
	# Generate random offset within a circle
	var random_angle = randf() * TAU  # TAU = 2 * PI
	var random_distance = randf() * spread
	
	return Vector2(
		cos(random_angle) * random_distance,
		sin(random_angle) * random_distance
	)
