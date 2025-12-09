extends Node2D
class_name Enemy

signal died

const EXPLOSION_SCENE = preload("res://Objects/Explosion/explosion.tscn")
const DAMAGE_NUMBER = preload("res://Objects/DamageNumber/damage_number.tscn")

@export_category("Generics")
@export var enemy_name : String
@export var speed : float = 2
@export var max_health : int = 5
@export var range : float = 30
@export var damage : int = 1
@export var attack_speed : float = 1
@export var gold_reward : int = 5
@export var gold_reward_variance : int = 2
@export var animated_sprite_frames : SpriteFrames
@export var animated_sprite_2d_scale : Vector2

enum TERRAIN_TYPE {
	GROUND,
	AIR
}
var current_terrain_type : TERRAIN_TYPE = TERRAIN_TYPE.GROUND

# Hitbox configuration (set by WaveManager before adding to scene)
var body_hitbox_size: Vector2 = Vector2.ZERO
var body_pos: Vector2 = Vector2.ZERO
var head_hitbox_size: Vector2 = Vector2.ZERO
var head_pos: Vector2 = Vector2.ZERO

@onready var sprite: Sprite2D = $Sprite2D
@onready var state_chart: StateChart = $StateChart
@onready var attack_speed_timer: Timer = $AttackSpeedTimer
@onready var wall_detector: Area2D = $WallDetector
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

var game_manager : GameManager
var bleed_effect: BleedEffect

var current_health : int :
	set(value) :
		current_health = value
		if current_health <= 0:
			died.emit()

## Slow effect variables
var is_slowed: bool = false
var base_speed: float = 0.0
var slow_timer: Timer
var slow_stacks: int = 0
var slow_per_stack_value: float = 0.1
const MAX_SLOW_STACKS: int = 10 # 10 stacks = 100% slow cap (can adjust)
			

func _ready() -> void:
	animated_sprite_2d.sprite_frames = animated_sprite_frames
	animated_sprite_2d.play("movement")
	
	wall_detector.position.x = range
	game_manager = get_tree().get_first_node_in_group("game_manager")
	
	attack_speed_timer.wait_time = attack_speed
	current_health = max_health
	base_speed = speed  # Store original speed
	
	# Setup slow timer
	slow_timer = Timer.new()
	slow_timer.one_shot = true
	slow_timer.timeout.connect(_on_slow_timer_timeout)
	add_child(slow_timer)
	
	# Create and add bleed effect component
	bleed_effect = BleedEffect.new()
	add_child(bleed_effect)
	bleed_effect.bleed_tick.connect(_on_bleed_tick)
	
	animated_sprite_2d.scale = animated_sprite_2d_scale
	
	# Apply hitbox sizes if they were set
	_apply_hitbox_configuration()

func _on_running_state_physics_processing(delta: float) -> void:
	var new_global_pos = Vector2(global_position.x + speed, global_position.y)
	global_position = global_position.move_toward(new_global_pos, 25)

func _on_wall_detector_area_entered(area: Area2D) -> void:
	if area.is_in_group("wall"):
		state_chart.send_event("to_attacking")
		
	if area.is_in_group("air_impact"):
		print("enemy broke through!")
		game_manager.current_health -= damage
		
		await get_tree().create_timer(.1).timeout
		queue_free()
	pass # Replace with function body.

func _on_attacking_state_entered() -> void:
	attack_speed_timer.start()
	animated_sprite_2d.play("attack")

func _on_attacking_state_physics_processing(delta: float) -> void:
	global_position = global_position.move_toward(global_position, 25)
	pass # Replace with function body.

func _on_attack_speed_timer_timeout() -> void:
	game_manager.current_health -= damage
	pass # Replace with function body.

func _on_died() -> void:
	animated_sprite_2d.play("death")
	state_chart.send_event("to_dead")
	
	# Disable hurtboxes to prevent further damage
	if has_node("HurtboxBody"):
		var body_hurtbox = get_node("HurtboxBody")
		body_hurtbox.set_deferred("monitoring", false)
		body_hurtbox.set_deferred("monitorable", false)
	if has_node("HurtboxHead"):
		var head_hurtbox = get_node("HurtboxHead")
		head_hurtbox.set_deferred("monitoring", false)
		head_hurtbox.set_deferred("monitorable", false)
	
	PlayerData.gold += randi_range(gold_reward - gold_reward_variance, gold_reward + gold_reward_variance)

	# Chance to explode on death from augments
	var augment_manager = get_tree().get_first_node_in_group("augment_manager")
	if augment_manager:
		# Cooldown reduction on kill
		if augment_manager.has_method("trigger_cooldown_reduction_on_kill"):
			augment_manager.trigger_cooldown_reduction_on_kill()
		
		# Coin drop on death
		if augment_manager.has_method("try_spawn_coin_on_enemy_death"):
			augment_manager.try_spawn_coin_on_enemy_death(global_position)
		
		# Explosion on death
		if augment_manager.has_method("get_enemy_death_explosion_chance"):
			var chance: float = augment_manager.get_enemy_death_explosion_chance()
			if chance > 0.0 and randf() < chance:
				print("Enemy death explosion triggered! Damage: ", int(12 * augment_manager.explosion_damage_multiplier), ", Radius: ", 110.0 * augment_manager.explosion_radius_multiplier)
				# Spawn explosion at enemy position
				var explosion = EXPLOSION_SCENE.instantiate()
				explosion.global_position = global_position
				# Apply explosion damage and radius from augment manager multipliers
				var base_damage: int = 12
				var base_radius: float = 110.0
				if "damage" in explosion:
					explosion.damage = int(base_damage * augment_manager.explosion_damage_multiplier)
				if "explosion_radius" in explosion:
					explosion.explosion_radius = base_radius * augment_manager.explosion_radius_multiplier
				var vfx_parent = get_tree().get_first_node_in_group("neutral_entities")
				if vfx_parent:
					vfx_parent.add_child(explosion)
				else:
					get_tree().current_scene.add_child(explosion)
					
	await animated_sprite_2d.animation_finished
	queue_free()
	print("enemy died!")
	pass # Replace with function body.

func _on_bleed_tick(bleed_damage: int) -> void:
	current_health -= bleed_damage
	print("Bleed tick! Damage: ", bleed_damage)
	
	# Spawn red damage number for bleed
	_spawn_bleed_damage_number(bleed_damage)

func _spawn_bleed_damage_number(bleed_damage: int) -> void:
	if DAMAGE_NUMBER == null:
		return
	
	var vfx_parent = get_tree().get_first_node_in_group("neutral_entities")
	if vfx_parent == null:
		return
	
	var damage_number_inst = DAMAGE_NUMBER.instantiate()
	damage_number_inst.global_position = global_position
	damage_number_inst.set_bleed_damage(bleed_damage)
	
	vfx_parent.add_child(damage_number_inst)

func apply_slow(per_stack: float, duration: float) -> void:
	# per_stack: fraction per stack (e.g., 0.1 for 10% per stack)
	if per_stack > 0.0:
		slow_per_stack_value = per_stack

	if not is_slowed:
		is_slowed = true
		slow_stacks = 1
		_recalculate_slow_speed()
		slow_timer.start(duration)
		print("Enemy slowed! New speed: ", speed, " (was ", base_speed, "), stacks: ", slow_stacks, " per_stack: ", slow_per_stack_value)
	else:
		# Add a stack, up to max
		slow_stacks = min(slow_stacks + 1, MAX_SLOW_STACKS)
		_recalculate_slow_speed()
		slow_timer.start(duration)
		print("Slow stack added! Stacks: ", slow_stacks, ", speed: ", speed, " per_stack: ", slow_per_stack_value)

# Helper to recalculate speed based on stacks
func _recalculate_slow_speed() -> void:
	var slow_factor = max(0.01, 1.0 - slow_per_stack_value * slow_stacks)
	speed = base_speed * slow_factor

func _on_slow_timer_timeout() -> void:
	is_slowed = false
	slow_stacks = 0
	speed = base_speed
	print("Enemy slow expired. Speed restored to: ", speed)

func _apply_hitbox_configuration() -> void:
	# Apply body hitbox if size was set
	if body_hitbox_size != Vector2.ZERO and has_node("HurtboxBody"):
		var body_hurtbox: Hurtbox = get_node("HurtboxBody")
		body_hurtbox.size = body_hitbox_size
		body_hurtbox.pos = body_pos
		# Update collision shape - create new shape to avoid shared resource issues
		var body_collision = body_hurtbox.get_node_or_null("CollisionShape2D")
		if body_collision:
			var new_shape = RectangleShape2D.new()
			new_shape.size = body_hitbox_size
			body_collision.shape = new_shape
			body_collision.position = body_pos
	
	# Apply head hitbox if size was set
	if head_hitbox_size != Vector2.ZERO and has_node("HurtboxHead"):
		var head_hurtbox: Hurtbox = get_node("HurtboxHead")
		head_hurtbox.size = head_hitbox_size
		head_hurtbox.pos = head_pos
		# Update collision shape - create new shape to avoid shared resource issues
		var head_collision = head_hurtbox.get_node_or_null("CollisionShape2D")
		if head_collision:
			var new_shape = RectangleShape2D.new()
			new_shape.size = head_hitbox_size
			head_collision.shape = new_shape
			head_collision.position = head_pos


func _on_dead_state_entered() -> void:
	pass # Replace with function body.
