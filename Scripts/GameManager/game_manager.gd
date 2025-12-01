extends Node
class_name GameManager

signal day_timer_finished
signal all_enemies_killed
signal start_new_day

const ENEMY_BASE = preload("uid://djs38cy8bwdv7")
const ALLY_BASE = preload("uid://shs4qcsi72hc")
const CROSSHAIR_SCENE = preload("res://UI/Crosshair/crosshair.tscn")
const VICTORY_SCREEN_SCENE = preload("res://UI/VictoryScreen/victory_screen.tscn")
const GAME_OVER_SCREEN_SCENE = preload("res://UI/GameOverScreen/game_over_screen.tscn")

var sudden_death : bool = false
var crosshair: Crosshair = null
var victory_screen: VictoryScreen = null
var game_over_screen: GameOverScreen = null
var max_health : int = 50
var current_health : int : 
	set(value):
		current_health = value
		if current_health <= 0:
			current_health = 0  # Clamp to 0
			call_deferred("_show_game_over_screen")
			return

		if current_health > max_health:
			current_health = max_health
		
@export var bg_start_color: Color = Color(0.8530103, 0.7348689, 0.6901674, 1.0)  # Original daytime color
@export var bg_end_color: Color = Color(0.6, 0.5, 0.7, 1.0)  # Lavender/dusk color
@export var day_time_length : float = 10

# Ambiance audio
@export var bird_ambiance: AudioStream
@export var shop_music: AudioStream
@export var new_wave_sound: AudioStream

@onready var spawner: Spawner = %Spawner
@onready var spawn_timer: Timer = $SpawnTimer
@onready var day_timer: Timer = $DayTimer
@onready var enemies: Node2D = $"../Entities/Enemies"
@onready var upgrade_screen: UpgradeScreen = %UpgradeScreen
@onready var mouse_shooter: MouseShooter = $'../MouseShooter'

@onready var ally_1_spawn: Marker2D = %Ally1Spawn
@onready var ally_2_spawn: Marker2D = %Ally2Spawn
@onready var ally_3_spawn: Marker2D = %Ally3Spawn
@onready var ally_4_spawn: Marker2D = %Ally4Spawn
@onready var allies_node: Node2D = $"../Entities/Allies"

# Background modulation for day/night cycle
@onready var background: TextureRect = $"../BG2"

# Wave system reference
var wave_manager

# Audio players
var ambiance_player: AudioStreamPlayer = null
var shop_music_player: AudioStreamPlayer = null
var new_wave_sound_player: AudioStreamPlayer = null

# Audio fade settings
const AUDIO_FADE_DURATION: float = 1.0
const AUDIO_TARGET_VOLUME: float = -5.0
const AUDIO_SILENT_VOLUME: float = -40.0

func _ready() -> void:
	current_health = max_health
	
	# Create ambiance audio player
	ambiance_player = AudioStreamPlayer.new()
	ambiance_player.bus = "Music"
	add_child(ambiance_player)
	if bird_ambiance:
		ambiance_player.stream = bird_ambiance
		ambiance_player.volume_db = -5.0  # Slightly quieter
		# Loop the ambiance when it finishes
		ambiance_player.finished.connect(_on_ambiance_finished)
		print("Bird ambiance loaded: ", bird_ambiance)

	# Create new wave sound player
	new_wave_sound_player = AudioStreamPlayer.new()
	new_wave_sound_player.bus = "SFX"
	add_child(new_wave_sound_player)
	if new_wave_sound:
		new_wave_sound_player.stream = new_wave_sound
		new_wave_sound_player.volume_db = -3.0
		print("New wave sound loaded: ", new_wave_sound)
	
	# Create shop music player
	shop_music_player = AudioStreamPlayer.new()
	shop_music_player.bus = "Music"
	add_child(shop_music_player)
	if shop_music:
		shop_music_player.stream = shop_music
		shop_music_player.volume_db = -5.0
		# Loop the shop music when it finishes
		shop_music_player.finished.connect(_on_shop_music_finished)
		print("Shop music loaded: ", shop_music)
	else:
		print("Warning: No shop music audio set!")
	
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

# Debug: Finish day input to clear enemies (DISABLED)
#func _unhandled_input(event: InputEvent) -> void:
	#if event.is_action_pressed("finish_day"):
		#print("=== FINISH DAY DEBUG ===")
		#print("Finishing day manually...")
		#
		## Stop spawning and enable sudden death
		#spawn_timer.stop()
		#sudden_death = true
		#print("Spawn timer stopped, sudden_death = true")
		#
		## Clear all enemies
		#var enemy_count = enemies.get_child_count()
		#print("Clearing ", enemy_count, " enemies")
		#for enemy in enemies.get_children():
			#enemy.queue_free()
		#
		## Wait a frame for enemies to be cleared
		#await get_tree().process_frame
		#
		#print("Enemies cleared, showing upgrade screen")
		#print("Upgrade screen exists: ", upgrade_screen != null)
		#
		## Show upgrade screen directly
		#if upgrade_screen:
			## Reset position in case it's off-screen
			#upgrade_screen.position = Vector2.ZERO
			#upgrade_screen.show()
			#upgrade_screen._bounce_in()
			#print("Upgrade screen shown!")
		#else:
			#print("ERROR: Upgrade screen is null!")
		#
		## Also emit signals for other systems
		#day_timer_finished.emit()
		#all_enemies_killed.emit()

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
	# Fade out bird ambiance and fade in shop music
	_fade_out_audio(ambiance_player)
	_fade_in_audio(shop_music_player)
	
func _init_allies() -> void:
	_clear_allies()
	
	var ally_spawns = [ally_1_spawn, ally_2_spawn, ally_3_spawn, ally_4_spawn]
	
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
	
	# Fade out shop music and fade in bird ambiance
	_fade_out_audio(shop_music_player)
	_fade_in_audio(ambiance_player)
	_fade_in_audio(new_wave_sound_player)
	
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
	# Show victory screen
	_show_victory_screen()

func _show_victory_screen() -> void:
	if victory_screen:
		return  # Already showing
	
	# Stop ambiance and shop music
	if ambiance_player and ambiance_player.playing:
		ambiance_player.stop()
	if shop_music_player and shop_music_player.playing:
		shop_music_player.stop()
	
	# Hide crosshair
	if crosshair:
		crosshair.hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# Create and show victory screen
	victory_screen = VICTORY_SCREEN_SCENE.instantiate()
	add_child(victory_screen)
	victory_screen.show_screen()

func _show_game_over_screen() -> void:
	if game_over_screen:
		return  # Already showing
	
	# Stop ambiance and shop music
	if ambiance_player and ambiance_player.playing:
		ambiance_player.stop()
	if shop_music_player and shop_music_player.playing:
		shop_music_player.stop()
	
	# Hide crosshair
	if crosshair:
		crosshair.hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# Get current wave number
	var current_wave = 1
	if wave_manager:
		var wave_info = wave_manager.get_wave_info()
		current_wave = wave_info.get("current_wave", 1)
	
	# Create and show game over screen - add to root so it's above everything
	game_over_screen = GAME_OVER_SCREEN_SCENE.instantiate()
	get_tree().root.add_child(game_over_screen)
	game_over_screen.set_wave_reached(current_wave)
	game_over_screen.show_screen()

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

func _on_ambiance_finished() -> void:
	# Loop the ambiance if we're still in gameplay (not in shop)
	if ambiance_player and not get_tree().paused:
		ambiance_player.play()

func _on_shop_music_finished() -> void:
	# Loop the shop music if we're still in the shop (game is paused)
	if shop_music_player and get_tree().paused:
		shop_music_player.play()

func _fade_in_audio(player: AudioStreamPlayer) -> void:
	if not player or not player.stream:
		return
	
	# Start at silent volume and play
	player.volume_db = AUDIO_SILENT_VOLUME
	if not player.playing:
		player.play()
	
	# Create tween to fade in (process_always so it works while paused)
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(player, "volume_db", AUDIO_TARGET_VOLUME, AUDIO_FADE_DURATION)

func _fade_out_audio(player: AudioStreamPlayer) -> void:
	if not player or not player.playing:
		return
	
	# Create tween to fade out (process_always so it works while paused)
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(player, "volume_db", AUDIO_SILENT_VOLUME, AUDIO_FADE_DURATION)
	tween.tween_callback(player.stop)
