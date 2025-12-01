extends Node
class_name MainMenu

const ALLY_SCENE = preload("res://Objects/Ally/ally_base.tscn")
const OPTIONS_PANEL_SCENE = preload("res://UI/Menus/options_panel.tscn")
const HOW_TO_PLAY_PANEL_SCENE = preload("res://UI/Menus/how_to_play_panel.tscn")
const CREDITS_PANEL_SCENE = preload("res://UI/Menus/credits_panel.tscn")

@onready var ally_spawns = [
	%Ally1Spawn,
	%Ally2Spawn,
	%Ally3Spawn,
	%Ally4Spawn
]

@onready var main_menu_control: Control = $CanvasLayer/MainMenuControl
@onready var title_label: Label = $CanvasLayer/MainMenuControl/TitleLabel
@onready var buttons_container: VBoxContainer = $CanvasLayer/MainMenuControl/ButtonsVBoxContainer
@onready var menu_sound_1 : AudioStreamPlayer = %MenuSound1
@onready var menu_sound_2 : AudioStreamPlayer = %MenuSound2
@onready var bg_music: AudioStreamPlayer = $BGMusic

# Popup panel instances
var how_to_play_panel: Panel = null
var options_panel: Panel = null
var credits_panel: Panel = null

var menu_allies: Array[Ally] = []
var max_shooting_allies: int = 2
var currently_shooting: Array[Ally] = []

# Title hover animation
var title_base_position: Vector2 = Vector2(214,168)
var title_hover_time: float = 0.0
var title_hover_amplitude: float = 8.0  # Pixels to move up/down
var title_hover_speed: float = 1.5  # Speed of hover cycle
var title_intro_complete: bool = false  # Wait for intro before hovering

func _ready() -> void:
	# Always show normal cursor in main menu
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# Hide and destroy any crosshair spawned by GameManager
	await get_tree().create_timer(0.1).timeout
	_hide_crosshair()
	# Start BG music faded in
	_fade_in_bg_music()
	
	# Store title base position for hover effect
	title_base_position = title_label.position
	
	# Play intro animation
	_play_intro_animation()

	_spawn_menu_allies()
	_start_shooting_rotation()

func _process(delta: float) -> void:
	# Title hovering effect - only after intro is complete
	if not title_intro_complete:
		return
	
	title_hover_time += delta * title_hover_speed
	var hover_offset = sin(title_hover_time) * title_hover_amplitude
	title_label.position.y = title_base_position.y + hover_offset

func _play_intro_animation() -> void:
	# Set initial states - everything starts invisible and offset
	title_label.modulate.a = 0.0
	title_label.position.y = title_base_position.y - 50.0
	
	buttons_container.modulate.a = 0.0
	var buttons_base_pos = buttons_container.position
	buttons_container.position.y = buttons_base_pos.y + 80.0
	
	# Animate title dropping in and fading
	var title_tween = create_tween()
	title_tween.set_ease(Tween.EASE_OUT)
	title_tween.set_trans(Tween.TRANS_BACK)
	title_tween.set_parallel(true)
	title_tween.tween_property(title_label, "modulate:a", 1.0, 0.6)
	title_tween.tween_property(title_label, "position:y", title_base_position.y, 0.8)
	
	# When title tween finishes, start hover animation smoothly
	title_tween.chain().tween_callback(_start_title_hover)
	
	# Animate buttons sliding up with a delay
	await get_tree().create_timer(0.3).timeout
	
	var buttons_tween = create_tween()
	buttons_tween.set_ease(Tween.EASE_OUT)
	buttons_tween.set_trans(Tween.TRANS_QUINT)  # Smoother deceleration
	buttons_tween.set_parallel(true)
	buttons_tween.tween_property(buttons_container, "modulate:a", 1.0, 0.6)
	buttons_tween.tween_property(buttons_container, "position:y", buttons_base_pos.y, 0.7)
	
	# Animate each button individually with stagger - smoother animation
	var buttons = buttons_container.get_children()
	for i in range(buttons.size()):
		var button = buttons[i]
		if button is Button:
			# Store original scale and set slightly smaller
			var original_scale = button.scale
			button.scale = Vector2(0.7, 0.7)  # Less dramatic scale change
			button.modulate.a = 0.0
			button.pivot_offset = button.size / 2  # Scale from center
			
			await get_tree().create_timer(0.1).timeout  # Slightly faster stagger
			
			var btn_tween = create_tween()
			btn_tween.set_ease(Tween.EASE_OUT)
			btn_tween.set_trans(Tween.TRANS_QUINT)  # Smooth quintic easing
			btn_tween.set_parallel(true)
			btn_tween.tween_property(button, "scale", original_scale, 0.4)  # Longer duration
			btn_tween.tween_property(button, "modulate:a", 1.0, 0.35)

func _start_title_hover() -> void:
	# Start hover animation from rest position (sin(0) = 0, so no jump)
	title_hover_time = 0.0
	title_intro_complete = true

func _fade_in_bg_music(duration: float = 1.5, target_db: float = 0.0) -> void:
	if not bg_music:
		return
	# Start from silence
	var start_db: float = -40.0  # Start quieter but not completely silent
	bg_music.volume_db = start_db
	if not bg_music.playing:
		bg_music.play()
	
	# Use a tween with ease-in curve for more natural audio fade
	# Human hearing is logarithmic, so ease-in sounds more natural
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_SINE)  # Sine curve sounds most natural for audio
	tween.tween_property(bg_music, "volume_db", target_db, duration)

func _hide_crosshair() -> void:
	# Find and destroy the crosshair if it exists
	var game_manager = get_tree().get_first_node_in_group("game_manager")
	if game_manager and game_manager.crosshair:
		game_manager.crosshair.queue_free()
		game_manager.crosshair = null
	# Ensure cursor is visible
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

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
			ally.fire_rate = 50.0   # Fast fire rate
			ally.accuracy = 0.95     # High accuracy
			ally.detection_range = randf_range(700.0, 900.0)
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
	menu_sound_1.play()
	get_tree().change_scene_to_file("res://game.tscn")

func _on_how_to_play_button_pressed() -> void:
	menu_sound_2.play()
	_hide_all_popups()
	if not how_to_play_panel:
		how_to_play_panel = HOW_TO_PLAY_PANEL_SCENE.instantiate()
		how_to_play_panel.back_pressed.connect(_hide_all_popups)
		main_menu_control.add_child(how_to_play_panel)
	how_to_play_panel.show_panel()

func _on_options_button_pressed() -> void:
	menu_sound_2.play()
	_hide_all_popups()
	if not options_panel:
		options_panel = OPTIONS_PANEL_SCENE.instantiate()
		options_panel.back_pressed.connect(_hide_all_popups)
		main_menu_control.add_child(options_panel)
	options_panel.show_panel()

func _on_credits_button_pressed() -> void:
	menu_sound_2.play()
	_hide_all_popups()
	if not credits_panel:
		credits_panel = CREDITS_PANEL_SCENE.instantiate()
		credits_panel.back_pressed.connect(_hide_all_popups)
		main_menu_control.add_child(credits_panel)
	credits_panel.show_panel()

func _on_quit_button_pressed() -> void:
	menu_sound_1.play()	
	get_tree().quit()

func _on_popup_back_button_pressed() -> void:
	menu_sound_2.play()
	_hide_all_popups()

func _hide_all_popups() -> void:
	if how_to_play_panel:
		how_to_play_panel.hide_panel()
	if options_panel:
		options_panel.hide_panel()
	if credits_panel:
		credits_panel.hide_panel()
