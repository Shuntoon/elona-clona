extends Node2D
class_name Enemy

signal died

@export_category("Generics")
@export var enemy_name : String
@export var speed : float = 2
@export var max_health : int = 5
@export var range : float = 30
@export var damage : int = 1
@export var sprite : Sprite2D
@export var attack_speed : float = 1
@export var gold_reward : int = 5
@export var gold_reward_variance : int = 2

@onready var state_chart: StateChart = $StateChart
@onready var attack_speed_timer: Timer = $AttackSpeedTimer
@onready var wall_detector: Area2D = $WallDetector

var game_manager : GameManager

var current_health : int :
	set(value) :
		current_health = value
		if current_health <= 0:
			died.emit()
			

func _ready() -> void:
	wall_detector.position.x = range
	game_manager = get_tree().get_first_node_in_group("game_manager")
	
	attack_speed_timer.wait_time = attack_speed
	current_health = max_health

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
	queue_free()
	print("enemy died!")
	pass # Replace with function body.
