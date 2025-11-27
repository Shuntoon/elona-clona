extends Control
class_name PauseMenu

signal resumed
signal restarted
signal quit_to_menu

const OPTIONS_PANEL_SCENE = preload("res://UI/Menus/options_panel.tscn")

@onready var pause_panel: Panel = $PausePanel
@onready var dim_overlay: ColorRect = $DimOverlay

var options_panel: OptionsPanel = null
var is_showing_options: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):  # Escape key
		if is_showing_options:
			_hide_options()
		elif visible:
			_on_resume_button_pressed()
		else:
			show_pause_menu()

func show_pause_menu() -> void:
	# Don't pause if we're already in the shop/upgrade screen
	var upgrade_screen = get_tree().get_first_node_in_group("upgrade_screen")
	if upgrade_screen and upgrade_screen.visible:
		return
	
	get_tree().paused = true
	show()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# Animate in
	dim_overlay.modulate.a = 0.0
	pause_panel.modulate.a = 0.0
	pause_panel.scale = Vector2(0.9, 0.9)
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(dim_overlay, "modulate:a", 1.0, 0.2)
	tween.tween_property(pause_panel, "modulate:a", 1.0, 0.2).set_ease(Tween.EASE_OUT)
	tween.tween_property(pause_panel, "scale", Vector2.ONE, 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func hide_pause_menu() -> void:
	get_tree().paused = false
	hide()
	
	# Restore crosshair if in gameplay
	var game_manager = get_tree().get_first_node_in_group("game_manager")
	if game_manager and game_manager.crosshair:
		game_manager.crosshair.show_crosshair()

func _on_resume_button_pressed() -> void:
	resumed.emit()
	hide_pause_menu()

func _on_options_button_pressed() -> void:
	is_showing_options = true
	pause_panel.hide()
	
	if not options_panel:
		options_panel = OPTIONS_PANEL_SCENE.instantiate()
		options_panel.back_pressed.connect(_hide_options)
		add_child(options_panel)
	
	options_panel.show_panel()

func _hide_options() -> void:
	is_showing_options = false
	if options_panel:
		options_panel.hide_panel()
	pause_panel.show()

func _on_restart_button_pressed() -> void:
	restarted.emit()
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_quit_to_menu_button_pressed() -> void:
	quit_to_menu.emit()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://UI/MainMenu/main_menu.tscn")
