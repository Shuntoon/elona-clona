extends Node
class_name GameManager

signal day_timer_finished
signal all_enemies_killed
signal start_new_day

const ENEMY_BASE = preload("uid://djs38cy8bwdv7")
const ALLY_BASE = preload("uid://shs4qcsi72hc")
const CROSSHAIR_SCENE = preload("res://UI/Crosshair/crosshair.tscn")

var sudden_death : bool = false
var crosshair: Crosshair = null
var max_health : int = 50
var current_health : int : 
	set(value):
		current_health = value
		if current_health <= 0:
			get_tree().quit()

		if current_health > max_health:
			current_health = max_health
		
@export var bg_start_color: Color = Color(0.8530103, 0.7348689, 0.6901674, 1.0)  # Original daytime color
@export var bg_end_color: Color = Color(0.6, 0.5, 0.7, 1.0)  # Lavender/dusk color
@export var day_time_length : float = 10

@onready var spawner: Spawner = %Spawner
@onready var spawn_timer: Timer = $SpawnTimer
@onready var day_timer: Timer = $DayTimer
@onready var enemies: Node2D = $"../Entities/Enemies"
@onready var upgrade_screen: UpgradeScreen = %UpgradeScreen
@onready var mouse_shooter: MouseShooter = $'../MouseShooter'

@onready var ally_1_spawn: Marker2D = %Ally1Spawn
@onready var ally_2_spawn: Marker2D = %Ally2Spawn
@onready var ally_3_spawn: Marker2D = %Ally3Spawn
@onready var allies_node: Node2D = $"../Entities/Allies"

# Background modulation for day/night cycle
@onready var background: TextureRect = $"../BG2"

# Wave system reference
var wave_manager

func _ready() -> void:
	current_health = max_health
	
	# Get wave manager reference
	wave_manager = get_tree().get_first_node_in_group("wave_manager")
	if wave_manager:
		wave_manager.wave_complete.connect(_on_wave_complete)
		wave_manager.all_waves_complete.connect(_on_all_waves_complete)
		print("WaveManager connected to GameManager")
	else:
		print("Warning: WaveManager not found! Add WaveManager node to scene.")
	
	# Defer signal to ensure all nodes are ready
	call_deferred("emit_signal", "start_new_day")
	print("GameManager: Deferred start_new_day signal")

func _process(_delta: float) -> void:
	# Update background color based on day progress (only in second half of day)
	if background and day_timer and not day_timer.is_stopped():
		var progress = 1.0 - (day_timer.time_left / day_time_length)
		# Only start transitioning after 50% of the day
		if progress > 0.5:
			# Remap 0.5-1.0 to 0.0-1.0 for the transition
			var transition_progress = (progress - 0.5) * 2.0
			background.modulate = bg_start_color.lerp(bg_end_color, transition_progress)
		else:
			background.modulate = bg_start_color

# Debug: Finish day input to clear enemies
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("finish_day"):
		print("=== FINISH DAY DEBUG ===")
		print("Finishing day manually...")
		
		# Stop spawning and enable sudden death
		spawn_timer.stop()
		sudden_death = true
		print("Spawn timer stopped, sudden_death = true")
		
		# Clear all enemies
		var enemy_count = enemies.get_child_count()
		print("Clearing ", enemy_count, " enemies")
		for enemy in enemies.get_children():
			enemy.queue_free()
		
		# Wait a frame for enemies to be cleared
		await get_tree().process_frame
		
		print("Enemies cleared, showing upgrade screen")
		print("Upgrade screen exists: ", upgrade_screen != null)
		
		# Show upgrade screen directly
		if upgrade_screen:
			# Reset position in case it's off-screen
			upgrade_screen.position = Vector2.ZERO
			upgrade_screen.show()
			upgrade_screen._bounce_in()
			print("Upgrade screen shown!")
		else:
			print("ERROR: Upgrade screen is null!")
		
		# Also emit signals for other systems
		day_timer_finished.emit()
		all_enemies_killed.emit()

func _on_spawn_timer_timeout() -> void:
	# Old spawning system - now handled by WaveManager
	pass

func _on_day_timer_timeout() -> void:
	day_timer_finished.emit()
	pass # Replace with function body.

func _on_day_timer_finished() -> void:
	spawn_timer.stop()
	sudden_death = true
	pass # Replace with function body.

func _on_enemies_child_exiting_tree(_node: Node) -> void:
	if sudden_death:
		if enemies.get_child_count() <= 1:
			all_enemies_killed.emit()
	pass # Replace with function body.

func _on_all_enemies_killed() -> void:
	# Reset position in case it's off-screen
	upgrade_screen.position = Vector2.ZERO
	upgrade_screen.show()
	upgrade_screen._bounce_in()
	# Pause the game while in shop
	get_tree().paused = true
	# Hide crosshair for shop
	if crosshair:
		crosshair.hide_crosshair()
	
func _init_allies() -> void:
	_clear_allies()
	
	var ally_spawns = [ally_1_spawn, ally_2_spawn, ally_3_spawn]
	
	print("Initializing allies. PlayerData has ", PlayerData.ally_datas.size(), " allies")
	
	# Iterate through PlayerData.ally_datas and spawn each ally
	for i in range(min(PlayerData.ally_datas.size(), ally_spawns.size())):
		var ally_data = PlayerData.ally_datas[i]
		var spawn_marker = ally_spawns[i]
		
		if ally_data and spawn_marker:
			print("Spawning ally ", i, ": ", ally_data.ally_name)
			_spawn_ally(ally_data, spawn_marker.global_position)
		else:
			if not ally_data:
				print("Warning: ally_data is null at index ", i)
			if not spawn_marker:
				print("Warning: spawn_marker is null at index ", i)

func _spawn_ally(ally_data: AllyData, spawn_position: Vector2) -> void:
	if not allies_node:
		print("Error: Allies node not found!")
		return
	
	# Instantiate ally base
	var ally_inst: Ally = ALLY_BASE.instantiate()
	
	# Inject ally data
	ally_inst.ally_data = ally_data
	
	# Set position
	ally_inst.global_position = spawn_position
	
	# Add to scene
	allies_node.add_child(ally_inst)
	
	print("Spawned ally: ", ally_data.ally_name, " at ", spawn_position)
	
	
func _on_start_new_day() -> void:
	_init_allies()

	# Apply augments at the start of each day
	var augment_manager = get_tree().get_first_node_in_group("augment_manager")
	if augment_manager:
		augment_manager.apply_all_augments()

	sudden_death = false
	# Unpause game when starting new day
	get_tree().paused = false
	
	# Reset background to daytime color
	if background:
		background.modulate = bg_start_color
	
	# Show crosshair for gameplay
	if not crosshair and CROSSHAIR_SCENE:
		crosshair = CROSSHAIR_SCENE.instantiate()
		add_child(crosshair)
	if crosshair:
		crosshair.show_crosshair()
	
	# Don't start spawn_timer - WaveManager handles spawning now
	day_timer.start(day_time_length)

func _clear_allies() -> void:
	if not allies_node:
		return
	
	# Remove all existing allies (but keep Player and spawn markers)
	for child in allies_node.get_children():
		# Don't remove the spawn markers or the Player node
		if not child is Marker2D and child.name != "Player":
			child.queue_free()
			print("Clearing ally: ", child.name)
	
	print("Cleared all allies")

## Wave completion handlers
func _on_wave_complete(_wave_number: int):
	# Wave complete handling is done by WaveManager
	pass

func _on_all_waves_complete():
	print("All 10 waves completed! Victory!")
	# Handle game completion - could show victory screen, credits, etc.

## Get current wave info for UI updates
func get_wave_info() -> Dictionary:
	if wave_manager:
		return wave_manager.get_wave_info()
	return {
		"current_wave": 1,
		"total_waves": 10,
		"day_progress": 0.0,
		"current_difficulty": "easy",
		"is_spawning": false
	}
