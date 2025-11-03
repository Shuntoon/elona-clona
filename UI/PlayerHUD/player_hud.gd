extends Control
class_name PlayerHUD

var game_manager : GameManager
var mouse_shooter : MouseShooter

@onready var hp_progress_bar: ProgressBar = %HPProgressBar
@onready var time_left_meter: ColorRect = %TimeLeftMeter
@onready var ammo_label: Label = %AmmoLabel
@onready var reload_bar: ProgressBar = %ReloadBar

func _ready() -> void:
	game_manager = get_tree().get_first_node_in_group("game_manager")
	mouse_shooter = get_tree().get_first_node_in_group("mouse_shooter")
	hp_progress_bar.max_value = game_manager.max_health
	reload_bar.visible = false
	
	
func _process(_delta: float) -> void:
	if game_manager != null:
		hp_progress_bar.value = game_manager.current_health
		time_left_meter.material.set_shader_parameter("value", game_manager.day_timer.time_left / (game_manager.day_time_length))
	
	if mouse_shooter != null:
		# Update ammo display
		ammo_label.text = str(mouse_shooter.current_ammo) + " / " + str(mouse_shooter.magazine_size)
		
		# Show/hide reload bar and update progress
		if mouse_shooter.is_reloading:
			reload_bar.visible = true
			reload_bar.value = mouse_shooter.reload_progress * 100
		else:
			reload_bar.visible = false
