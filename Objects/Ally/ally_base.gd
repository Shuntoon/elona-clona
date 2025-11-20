extends Node2D
class_name Ally

const BULLET_BASE = preload("uid://bljxubxu5eg3j")
const HITBOX = preload("uid://bg6uxodad3g5f")
const HIT_ENEMY_VFX = preload("uid://cubkpuvcxnh63")
const HIT_GROUND_VFX = preload("uid://doaytv1th1j3v")
const EXPLOSION = preload("uid://cp6c33t2cjpx5")

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

@export var ally_data : AllyData

@export var ally_type: AllyType = AllyType.RIFLEMAN
@export var ally_name: String = "Ally"
@export var targeting_mode: TargetingMode = TargetingMode.CLOSEST

## Detection range for finding enemies
@export var detection_range: float = 500.0
## Fire rate in rounds per minute
@export var fire_rate: float = 300.0
## Bullet damage
@export var bullet_damage: int = 1
## Accuracy (0.0 = max spread, 1.0 = perfect)
@export_range(0.0, 1.0) var accuracy: float = 0.8
@export var max_spread: float = 30.0

# Rocket-specific properties
@export var explosion_damage: int = 15
@export var explosion_radius: float = 120.0

# Support-specific properties
@export var heal_amount: int = 1
@export var heal_interval: float = 2.0

# Internal state
var current_target: Enemy = null
var can_shoot: bool = true
var time_between_shots: float
var neutral_entities: Node
var enemies_node: Node2D
var game_manager: GameManager

func _ready() -> void:
	add_to_group("allies")
	neutral_entities = get_tree().get_first_node_in_group("neutral_entities")
	enemies_node = get_tree().get_first_node_in_group("enemies")
	game_manager = get_tree().get_first_node_in_group("game_manager")
	
	if ally_data:
		init_ally_data()
	
	time_between_shots = 60.0 / fire_rate
	
	# Start type-specific behavior
	match ally_type:
		AllyType.RIFLEMAN, AllyType.ROCKETEER:
			_start_combat_loop()
		AllyType.SUPPORT:
			_start_healing_loop()

func _process(_delta: float) -> void:
	# Update target for combat allies
	if ally_type != AllyType.SUPPORT:
		_update_target()
		
func init_ally_data() -> void:
	ally_type = ally_data.ally_type
	ally_name = ally_data.ally_name
	fire_rate = ally_data.fire_rate
	bullet_damage = ally_data.bullet_damage
	explosion_damage = ally_data.explosion_damage
	explosion_radius  = ally_data.explosion_radius
	max_spread = ally_data.max_spread
	accuracy = ally_data.accuracy
	heal_amount = ally_data.heal_amount
	heal_interval = ally_data.heal_interval
	detection_range = ally_data.detection_range
	

func _update_target() -> void:
	# Clear target if it's dead or out of range
	if current_target and (not is_instance_valid(current_target) or 
		global_position.distance_to(current_target.global_position) > detection_range):
		current_target = null
	
	# Find new target if we don't have one
	if current_target == null:
		current_target = _find_nearest_enemy()

func _find_nearest_enemy() -> Enemy:
	if not enemies_node:
		return null
	
	var valid_enemies: Array[Enemy] = []
	
	# Collect all enemies within detection range
	for enemy in enemies_node.get_children():
		if enemy is Enemy:
			var distance = global_position.distance_to(enemy.global_position)
			if distance <= detection_range:
				valid_enemies.append(enemy)
	
	if valid_enemies.is_empty():
		return null
	
	# Select target based on targeting mode
	match targeting_mode:
		TargetingMode.CLOSEST:
			return _find_closest_enemy(valid_enemies)
		TargetingMode.FARTHEST:
			return _find_farthest_enemy(valid_enemies)
		TargetingMode.STRONGEST:
			return _find_strongest_enemy(valid_enemies)
		TargetingMode.WEAKEST:
			return _find_weakest_enemy(valid_enemies)
	
	return valid_enemies[0]

func _find_closest_enemy(enemies: Array[Enemy]) -> Enemy:
	var closest: Enemy = null
	var closest_distance: float = INF
	
	for enemy in enemies:
		var distance = global_position.distance_to(enemy.global_position)
		if distance < closest_distance:
			closest_distance = distance
			closest = enemy
	
	return closest

func _find_farthest_enemy(enemies: Array[Enemy]) -> Enemy:
	var farthest: Enemy = null
	var farthest_distance: float = -INF
	
	for enemy in enemies:
		var distance = global_position.distance_to(enemy.global_position)
		if distance > farthest_distance:
			farthest_distance = distance
			farthest = enemy
	
	return farthest

func _find_strongest_enemy(enemies: Array[Enemy]) -> Enemy:
	var strongest: Enemy = null
	var highest_health: int = -1
	
	for enemy in enemies:
		if enemy.current_health > highest_health:
			highest_health = enemy.current_health
			strongest = enemy
	
	return strongest

func _find_weakest_enemy(enemies: Array[Enemy]) -> Enemy:
	var weakest: Enemy = null
	var lowest_health: int = 999999
	
	for enemy in enemies:
		if enemy.current_health < lowest_health:
			lowest_health = enemy.current_health
			weakest = enemy
	
	return weakest

func _start_combat_loop() -> void:
	# Add random initial delay to stagger shots from multiple allies
	var initial_delay = randf_range(0.0, 0.3)
	await get_tree().create_timer(initial_delay).timeout
	
	while true:
		if can_shoot and current_target and is_instance_valid(current_target):
			_fire_at_target()
			can_shoot = false
			await get_tree().create_timer(time_between_shots).timeout
			can_shoot = true
		else:
			await get_tree().create_timer(0.1).timeout

func _fire_at_target() -> void:
	if not current_target or not is_instance_valid(current_target):
		return
	
	var target_position = current_target.global_position
	
	match ally_type:
		AllyType.RIFLEMAN:
			_fire_bullet(target_position, false)
		AllyType.ROCKETEER:
			_fire_bullet(target_position, true)

func _fire_bullet(target_pos: Vector2, is_rocket: bool) -> void:
	if not neutral_entities:
		return
	
	var bullet_inst: Bullet = BULLET_BASE.instantiate()
	bullet_inst.global_position = global_position
	bullet_inst.target = target_pos + _calculate_accuracy_offset()
	
	if is_rocket:
		# Rocket configuration
		bullet_inst.explosive = true
		bullet_inst.explosion_damage = explosion_damage
		bullet_inst.explosion_radius = explosion_radius
		bullet_inst.explosion_scene = EXPLOSION
		bullet_inst.speed = 150  # Slower rockets
	else:
		# Rifle configuration
		bullet_inst.explosive = false
		bullet_inst.speed = 800  # Fast rifle bullets
	
	bullet_inst.hit_enemy_vfx = HIT_ENEMY_VFX
	bullet_inst.hit_ground_vfx = HIT_GROUND_VFX
	
	# Set damage via hitbox
	var hitbox = bullet_inst.get_node_or_null("Hitbox")
	if hitbox:
		hitbox.damage = bullet_damage
	
	neutral_entities.add_child(bullet_inst)

func _start_healing_loop() -> void:
	while true:
		await get_tree().create_timer(heal_interval).timeout
		_heal_base()

func _heal_base() -> void:
	if game_manager and game_manager.current_health < game_manager.max_health:
		game_manager.current_health += heal_amount
		print(ally_name, " healed base for ", heal_amount)

func _calculate_accuracy_offset() -> Vector2:
	var spread = (1.0 - accuracy) * max_spread
	var random_angle = randf() * TAU
	var random_distance = randf() * spread
	
	return Vector2(
		cos(random_angle) * random_distance,
		sin(random_angle) * random_distance
	)

func get_target() -> Enemy:
	return current_target
