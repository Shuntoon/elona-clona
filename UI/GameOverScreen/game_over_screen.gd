extends Control
class_name GameOverScreen

signal main_menu_pressed
signal try_again_pressed

@onready var title_label: Label = $CenterContainer/PanelContainer/VBoxContainer/TitleLabel
@onready var message_label: Label = $CenterContainer/PanelContainer/VBoxContainer/MessageLabel
@onready var stats_label: Label = $CenterContainer/PanelContainer/VBoxContainer/StatsLabel
@onready var main_menu_button: Button = $CenterContainer/PanelContainer/VBoxContainer/ButtonContainer/MainMenuButton
@onready var try_again_button: Button = $CenterContainer/PanelContainer/VBoxContainer/ButtonContainer/TryAgainButton
@onready var game_over_sound: AudioStreamPlayer = $GameOverSound

var player_data: PlayerData = null
var wave_reached: int = 1

func _ready() -> void:
	# Show mouse cursor
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# Get player data for stats
	player_data = get_tree().get_first_node_in_group("player_data")
	
	# Update stats display
	_update_stats()
	
	# Play game over sound
	if game_over_sound and game_over_sound.stream:
		game_over_sound.play()
	
	# Animate the screen appearing (must ignore pause since we pause the game)
	modulate.a = 0.0
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(self, "modulate:a", 1.0, 0.5)

func set_wave_reached(wave: int) -> void:
	wave_reached = wave
	_update_stats()

func _update_stats() -> void:
	if not stats_label:
		return
	
	var stats_text = ""
	if player_data:
		stats_text = "Gold Collected: %d\nWaves Survived: %d" % [player_data.gold, wave_reached]
	else:
		stats_text = "Waves Survived: %d" % wave_reached
	
	stats_label.text = stats_text

func show_screen() -> void:
	show()
	# Don't pause - game is over, just show the screen

func hide_screen() -> void:
	hide()

func _on_main_menu_button_pressed() -> void:
	main_menu_pressed.emit()
	get_tree().change_scene_to_file("res://UI/MainMenu/main_menu.tscn")

func _on_try_again_button_pressed() -> void:
	try_again_pressed.emit()
	
	# Reset player data before restarting
	PlayerData.reset_player_data()
	
	get_tree().change_scene_to_file("res://game.tscn")
