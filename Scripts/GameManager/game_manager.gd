extends Node
class_name GameManager

@onready var spawner: Spawner = %Spawner
@onready var spawn_timer: Timer = $SpawnTimer

var max_health : int = 50
var current_health : int : 
	set(value):
		current_health = value
		if current_health <= 0:
			get_tree().quit()
		

const ENEMY_BASE = preload("uid://djs38cy8bwdv7")

func _ready() -> void:
	current_health = max_health
	spawn_timer.start()

func _on_spawn_timer_timeout() -> void:
	spawner.spawn_enemy(ENEMY_BASE, Spawner.TERRAIN.GROUND)
