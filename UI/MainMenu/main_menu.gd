extends Node
class_name MainMenu

const ALLY_SCENE = preload("res://Objects/Ally/ally_base.tscn")

@onready var ally_spawns = [
	%Ally1Spawn,
	%Ally2Spawn,
	%Ally3Spawn,
	%Ally4Spawn
]

var menu_allies: Array[Ally] = []
var max_shooting_allies: int = 2
var currently_shooting: Array[Ally] = []

func _ready() -> void:
	await get_tree().create_timer(0.1).timeout
	
	_spawn_menu_allies()
	_start_shooting_rotation()

func _spawn_menu_allies() -> void:
	# Shuffle spawn positions and pick 3 random ones
	var shuffled_spawns = ally_spawns.duplicate()
	shuffled_spawns.shuffle()
	
	# Spawn 3 powerful allies at random positions
	for i in range(3):
		var spawn_marker = shuffled_spawns[i]
		if spawn_marker:
			var ally: Ally = ALLY_SCENE.instantiate()
			
			# Configure ally with high damage but disabled shooting
			ally.ally_type = Ally.AllyType.RIFLEMAN
			ally.bullet_damage = 50  # High damage to 1-2 shot enemies
			ally.fire_rate = 100.0   # Fast fire rate
			ally.accuracy = 0.95     # High accuracy
			ally.detection_range = 800.0
			ally.can_shoot = false   # Start disabled
			
			ally.global_position = spawn_marker.global_position
			
			# Add to allies node
			var allies_node = get_tree().get_first_node_in_group("allies")
			if allies_node:
				allies_node.add_child(ally)
				menu_allies.append(ally)

func _start_shooting_rotation() -> void:
	# Enable shooting for the first 2 allies
	for i in range(min(max_shooting_allies, menu_allies.size())):
		if menu_allies[i]:
			menu_allies[i].can_shoot = true
			currently_shooting.append(menu_allies[i])
	
	# Periodically rotate which allies can shoot
	while true:
		await get_tree().create_timer(randf_range(3.0, 6.0)).timeout
		_rotate_shooters()

func _rotate_shooters() -> void:
	# Remove an ally from shooting
	if not currently_shooting.is_empty():
		var random_active = currently_shooting.pick_random()
		random_active.can_shoot = false
		currently_shooting.erase(random_active)
	
	# Add a different ally to shooting
	var available_allies = menu_allies.filter(func(ally): return not currently_shooting.has(ally))
	if not available_allies.is_empty():
		var new_shooter = available_allies.pick_random()
		new_shooter.can_shoot = true
		currently_shooting.append(new_shooter)

func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file("res://game.tscn")
	pass # Replace with function body.
