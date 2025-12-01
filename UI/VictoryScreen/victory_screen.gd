extends Control
class_name VictoryScreen

signal main_menu_pressed
signal play_again_pressed

@onready var title_label: Label = $CenterContainer/PanelContainer/VBoxContainer/TitleLabel
@onready var message_label: Label = $CenterContainer/PanelContainer/VBoxContainer/MessageLabel
@onready var stats_label: Label = $CenterContainer/PanelContainer/VBoxContainer/StatsLabel
@onready var main_menu_button: Button = $CenterContainer/PanelContainer/VBoxContainer/ButtonContainer/MainMenuButton
@onready var play_again_button: Button = $CenterContainer/PanelContainer/VBoxContainer/ButtonContainer/PlayAgainButton
@onready var victory_sound: AudioStreamPlayer = $VictorySound

var player_data: PlayerData = null

func _ready() -> void:
	# Show mouse cursor
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# Get player data for stats
	player_data = get_tree().get_first_node_in_group("player_data")
	
	# Update stats display
	_update_stats()
	
	# Play victory sound
	if victory_sound and victory_sound.stream:
		victory_sound.play()
	
	# Animate the screen appearing (must ignore pause since we pause the game)
	modulate.a = 0.0
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(self, "modulate:a", 1.0, 0.5)

func _update_stats() -> void:
	if not stats_label:
		return
	
	var stats_text = ""
	if player_data:
		stats_text = "Gold Collected: %d\nWaves Survived: 10" % player_data.gold
	else:
		stats_text = "Waves Survived: 10"
	
	stats_label.text = stats_text

func show_screen() -> void:
	show()
	# Pause the game tree except for this UI
	get_tree().paused = true

func hide_screen() -> void:
	hide()
	get_tree().paused = false

func _on_main_menu_button_pressed() -> void:
	main_menu_pressed.emit()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://UI/MainMenu/main_menu.tscn")

func _on_play_again_button_pressed() -> void:
	play_again_pressed.emit()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://game.tscn")
