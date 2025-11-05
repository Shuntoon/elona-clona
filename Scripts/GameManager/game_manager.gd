extends Node
class_name GameManager

signal finish_day
signal all_enemies_killed

const ENEMY_BASE = preload("uid://djs38cy8bwdv7")

var sudden_death : bool = false
var max_health : int = 50
var current_health : int : 
	set(value):
		current_health = value
		if current_health <= 0:
			get_tree().quit()
		
@export var day_time_length : float = 10

@onready var spawner: Spawner = %Spawner
@onready var spawn_timer: Timer = $SpawnTimer
@onready var day_timer: Timer = $DayTimer
@onready var enemies: Node2D = $"../Entities/Enemies"
@onready var shop: Control = %Shop

func _ready() -> void:
	current_health = max_health - 25
	spawn_timer.start()

func _on_spawn_timer_timeout() -> void:
	spawner.spawn_enemy(ENEMY_BASE, Spawner.TERRAIN.GROUND)

func _on_day_timer_timeout() -> void:
	finish_day.emit()
	pass # Replace with function body.

func _on_finish_day() -> void:
	spawn_timer.stop()
	sudden_death = true
	pass # Replace with function body.

func _on_enemies_child_exiting_tree(node: Node) -> void:
	if sudden_death:
		if enemies.get_child_count() <= 1:
			all_enemies_killed.emit()
	pass # Replace with function body.

func _on_all_enemies_killed() -> void:
	shop.visible = true
	pass # Replace with function body.
