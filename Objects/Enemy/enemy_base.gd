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

enum TERRAIN_TYPE {
	GROUND,
	AIR
}
var current_terrain_type : TERRAIN_TYPE = TERRAIN_TYPE.GROUND

@onready var sprite: Sprite2D = $Sprite2D
@onready var state_chart: StateChart = $StateChart
@onready var attack_speed_timer: Timer = $AttackSpeedTimer
@onready var wall_detector: Area2D = $WallDetector

var game_manager : GameManager
var bleed_effect: BleedEffect

var current_health : int :
	set(value) :
		current_health = value
		if current_health <= 0:
			died.emit()

# Slow effect variables
var is_slowed: bool = false
var base_speed: float = 0.0
var slow_timer: Timer
			

func _ready() -> void:
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

func _on_running_state_physics_processing(delta: float) -> void:
	var new_global_pos = Vector2(global_position.x + speed, global_position.y)
	global_position = global_position.move_toward(new_global_pos, 25)

func _on_wall_detector_area_entered(area: Area2D) -> void:
	if area.is_in_group("wall"):
		state_chart.send_event("to_attacking")
	pass # Replace with function body.

func _on_attacking_state_entered() -> void:
	attack_speed_timer.start()

func _on_attacking_state_physics_processing(delta: float) -> void:
	global_position = global_position.move_toward(global_position, 25)
	pass # Replace with function body.

func _on_attack_speed_timer_timeout() -> void:
	game_manager.current_health -= damage
	pass # Replace with function body.

func _on_died() -> void:
	PlayerData.gold += randi_range(gold_reward - gold_reward_variance, gold_reward + gold_reward_variance)

	# Chance to explode on death from augments
	var augment_manager = get_tree().get_first_node_in_group("augment_manager")
	if augment_manager and augment_manager.has_method("get_enemy_death_explosion_chance"):
		var chance: float = augment_manager.get_enemy_death_explosion_chance()
		if chance > 0.0 and randf() < chance:
			# Spawn explosion at enemy position
			var explosion = EXPLOSION_SCENE.instantiate()
			explosion.global_position = global_position
			# Set base damage to 10 as specified
			if "damage" in explosion:
				explosion.damage = 10
			# Optional: can tweak radius or visual scale if desired
			var vfx_parent = get_tree().get_first_node_in_group("neutral_entities")
			if vfx_parent:
				vfx_parent.add_child(explosion)
			else:
				get_tree().current_scene.add_child(explosion)
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

func apply_slow(slow_multiplier: float, duration: float) -> void:
	print("apply_slow called! is_slowed: ", is_slowed, ", base_speed: ", base_speed, ", multiplier: ", slow_multiplier)
	if not is_slowed:
		is_slowed = true
		speed = base_speed * slow_multiplier
		slow_timer.start(duration)
		print("Enemy slowed! New speed: ", speed, " (was ", base_speed, ")")
	else:
		# Refresh slow duration
		slow_timer.start(duration)
		print("Slow duration refreshed")

func _on_slow_timer_timeout() -> void:
	is_slowed = false
	speed = base_speed
	print("Enemy slow expired. Speed restored to: ", speed)
