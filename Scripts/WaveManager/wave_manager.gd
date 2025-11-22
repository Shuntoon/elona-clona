extends Node
class_name WaveManager

signal wave_started(wave_number: int)
signal wave_complete(wave_number: int)
signal all_waves_complete()

@export var waves: Array[WaveData]
@export var enemy_base_scene: PackedScene

var spawner: Spawner
var game_manager: GameManager

var current_wave_index: int = 0
var current_wave_data
var is_spawning: bool = false
var spawn_timer: Timer
var current_display_wave: int = 1  # The wave number to display in UI

var day_progress: float = 0.0
var current_difficulty_phase: String = "easy"

# Shared RNG for consistent randomization
var rng: RandomNumberGenerator

func _enter_tree():
	add_to_group("wave_manager")
	
	# Connect to GameManager signals early to avoid race condition
	var gm = get_tree().get_first_node_in_group("game_manager")
	if gm:
		gm.start_new_day.connect(_on_day_started)
		gm.day_timer_finished.connect(_on_day_finished)
		print("WaveManager connected to GameManager signals in _enter_tree()")

func _ready():
	spawner = get_tree().get_first_node_in_group("spawner")
	game_manager = get_tree().get_first_node_in_group("game_manager")
	
	enemy_base_scene = preload("uid://djs38cy8bwdv7")
	
	# Initialize RNG
	rng = RandomNumberGenerator.new()
	rng.randomize()
	
	spawn_timer = Timer.new()
	spawn_timer.timeout.connect(_spawn_next_enemy)
	add_child(spawn_timer)
	
	for wave in waves:
		if not wave.validate():
			push_error("Wave validation failed!")
	
	print("WaveManager initialized with ", waves.size(), " waves")

func _process(_delta):
	if is_spawning and game_manager and game_manager.day_timer:
		var time_left = game_manager.day_timer.time_left
		var total_time = game_manager.day_timer.wait_time
		day_progress = 1.0 - (time_left / total_time)
		day_progress = clamp(day_progress, 0.0, 1.0)
		
		var new_phase = _get_difficulty_phase(day_progress)
		if new_phase != current_difficulty_phase:
			current_difficulty_phase = new_phase
			_update_spawn_timing()
			print("Difficulty phase changed to: ", current_difficulty_phase)

func _get_difficulty_phase(progress: float) -> String:
	if progress < 0.33:
		return "easy"
	elif progress < 0.67:
		return "medium"
	else:
		return "hard"

func _update_spawn_timing():
	if not current_wave_data:
		return
	
	var new_interval = current_wave_data.get_spawn_interval(current_difficulty_phase)
	spawn_timer.wait_time = new_interval
	print("Spawn interval updated to: ", new_interval, " seconds")

func _on_day_started():
	if current_wave_index >= waves.size():
		all_waves_complete.emit()
		print("All waves complete!")
		return
	
	current_wave_data = waves[current_wave_index]
	current_difficulty_phase = "easy"
	day_progress = 0.0
	is_spawning = true
	current_display_wave = current_wave_index + 1  # Update display wave when day starts
	
	wave_started.emit(current_wave_index + 1)
	print("Wave ", current_wave_index + 1, " started")
	
	var spawn_interval = current_wave_data.get_spawn_interval(current_difficulty_phase)
	spawn_timer.wait_time = spawn_interval
	spawn_timer.start()

func _on_day_finished():
	print("Wave ", current_wave_index + 1, " complete!")
	is_spawning = false
	spawn_timer.stop()
	
	wave_complete.emit(current_wave_index + 1)
	# Increment AFTER emitting the complete signal, BEFORE next day starts
	current_wave_index += 1

func _spawn_next_enemy():
	if not is_spawning or not current_wave_data:
		return
	
	var enemy_pool = current_wave_data.get_enemy_pool(current_difficulty_phase)
	var weights = current_wave_data.get_weights(current_difficulty_phase)
	
	if enemy_pool.is_empty() or weights.is_empty():
		print("Warning: No enemies in ", current_difficulty_phase, " pool for wave ", current_wave_index + 1)
		return
	
	var selected_enemy_data = _select_weighted_enemy(enemy_pool, weights)
	if selected_enemy_data:
		_spawn_enemy_with_data(selected_enemy_data)

func _select_weighted_enemy(enemy_pool: Array, weights: Array[float]):
	if enemy_pool.is_empty() or weights.is_empty():
		return null
	
	# Ensure weights array matches enemy pool size
	var actual_weights = PackedFloat32Array()
	for i in range(enemy_pool.size()):
		if i < weights.size():
			actual_weights.append(weights[i])
		else:
			# Default weight if not provided
			actual_weights.append(1.0)
	
	var selected_index = rng.rand_weighted(actual_weights)
	return enemy_pool[selected_index]

func _spawn_enemy_with_data(enemy_data: EnemyData):
	if not enemy_base_scene or not spawner:
		return
	
	var enemy_inst: Enemy = enemy_base_scene.instantiate()
	
	# Inject enemy data properties
	enemy_inst.enemy_name = enemy_data.enemy_name
	enemy_inst.speed = enemy_data.speed
	enemy_inst.max_health = enemy_data.max_health
	enemy_inst.range = enemy_data.range
	enemy_inst.damage = enemy_data.damage
	enemy_inst.attack_speed = enemy_data.attack_speed
	enemy_inst.gold_reward = enemy_data.gold_reward
	enemy_inst.gold_reward_variance = enemy_data.gold_reward_variance
	enemy_inst.current_terrain_type = enemy_data.terrain_type
	enemy_inst.animated_sprite_2d_scale = enemy_data.animated_sprite_2d_scale
	
	# Set hurtbox configuration (will be applied in enemy's _ready)
	enemy_inst.body_hitbox_size = enemy_data.body_hitbox_size
	enemy_inst.body_pos = enemy_data.body_pos
	enemy_inst.head_hitbox_size = enemy_data.head_hitbox_size
	enemy_inst.head_pos = enemy_data.head_pos
	
	var spawn_terrain: Spawner.TERRAIN
	if enemy_data.terrain_type == Enemy.TERRAIN_TYPE.GROUND:
		spawn_terrain = Spawner.TERRAIN.GROUND
	else:
		spawn_terrain = Spawner.TERRAIN.AIR
	
	_spawn_at_position(enemy_inst, spawn_terrain)

func _spawn_at_position(enemy_inst: Enemy, terrain: Spawner.TERRAIN):
	var random_pos: Vector2
	
	match terrain:
		Spawner.TERRAIN.GROUND:
			var ground_children = spawner.ground.get_children()
			if ground_children.is_empty():
				push_error("No ground spawn points!")
				enemy_inst.queue_free()
				return
			var random_ground: Marker2D = ground_children.pick_random()
			random_pos = random_ground.global_position
		Spawner.TERRAIN.AIR:
			var air_children = spawner.air.get_children()
			if air_children.is_empty():
				push_error("No air spawn points!")
				enemy_inst.queue_free()
				return
			var random_air: Marker2D = air_children.pick_random()
			random_pos = random_air.global_position
	
	enemy_inst.global_position = random_pos
	
	var enemies = get_tree().get_first_node_in_group("enemies")
	if enemies:
		enemies.add_child(enemy_inst)
	else:
		push_error("No enemies node found!")
		enemy_inst.queue_free()

func get_wave_info() -> Dictionary:
	return {
		"current_wave": current_display_wave,
		"total_waves": waves.size(),
		"day_progress": day_progress,
		"current_difficulty": current_difficulty_phase,
		"is_spawning": is_spawning
	}

func pause_spawning():
	spawn_timer.paused = true

func resume_spawning():
	spawn_timer.paused = false

func reset_waves():
	spawn_timer.stop()
	current_wave_index = 0
	current_wave_data = null
	is_spawning = false
	day_progress = 0.0
	current_difficulty_phase = "easy"
	current_display_wave = 1
	print("Wave system reset")
