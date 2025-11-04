extends Node2D
class_name MouseShooter

const HITBOX = preload("uid://bg6uxodad3g5f")
const BULLET_BASE = preload("uid://bljxubxu5eg3j")
const HIT_ENEMY_VFX = preload("uid://cubkpuvcxnh63")
const HIT_GROUND_VFX = preload("uid://doaytv1th1j3v")


# Add to group so HUD can find it
func _enter_tree() -> void:
	add_to_group("mouse_shooter")

@export_range(0.0, 1.0) var accuracy: float = 1.0
@export var max_spread: float = 50.0
@export var bullet_type : BULLET_TYPE
@export var fire_mode : FIRE_MODE

## Fire rate in rounds per minute (for automatic)
@export var fire_rate: float = 600.0
## Number of bullets in a burst
@export var burst_count: int = 3
## Delay between burst shots in seconds
@export var burst_delay: float = 0.1
## Magazine capacity
@export var magazine_size: int = 30
## Reload time in seconds
@export var reload_time: float = 2.0
## Enable piercing for projectile bullets
@export var projectile_piercing: bool = false

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

var neutral_entities

func _ready() -> void:
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
	while elapsed < reload_time:
		await get_tree().process_frame
		var delta = get_process_delta_time()
		elapsed += delta
		reload_progress = elapsed / reload_time
	
	current_ammo = magazine_size
	is_reloading = false
	reload_progress = 0.0

func _fire_bullet() -> void:
	if current_ammo <= 0:
		return
	
	current_ammo -= 1
	
	if bullet_type == BULLET_TYPE.HITSCAN:
		var hitbox_inst : Hitbox = HITBOX.instantiate()
		hitbox_inst.destroy_instantly = true
		hitbox_inst.hit_enemy_vfx = HIT_ENEMY_VFX
		hitbox_inst.hit_ground_vfx = HIT_GROUND_VFX
		hitbox_inst.global_position = get_global_mouse_position() + _calculate_accuracy_offset()
		if neutral_entities != null:
			neutral_entities.add_child(hitbox_inst)
		else:
			print("no entities")
	
	if bullet_type == BULLET_TYPE.PROJECTILE:
		var bullet_base_inst : Bullet = BULLET_BASE.instantiate()
		bullet_base_inst.global_position = bullet_spawn_point
		bullet_base_inst.target = get_global_mouse_position() + _calculate_accuracy_offset()
		bullet_base_inst.piercing = projectile_piercing  # Set piercing based on export variable
		bullet_base_inst.hit_enemy_vfx = HIT_ENEMY_VFX
		bullet_base_inst.hit_ground_vfx = HIT_GROUND_VFX
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
