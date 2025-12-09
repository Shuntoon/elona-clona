extends Control
class_name PlayerHUD

var game_manager : GameManager
var mouse_shooter : MouseShooter
var ability_manager : AbilityManager
var allies_node: Node2D
var wave_manager

@onready var hp_progress_bar: ProgressBar = %HPProgressBar
@onready var time_left_meter: ColorRect = %TimeLeftMeter
@onready var ammo_label: Label = %AmmoLabel
@onready var reload_bar: ProgressBar = %ReloadBar
@onready var abilities_container: HBoxContainer = $MarginContainer/AbilitiesHBoxContainer
@onready var ally_controls_container: VBoxContainer = %AllyControlsContainer
@onready var weapon_label: Label = %WeaponLabel
@onready var day_label: Label = %DayLabel
@onready var gold_label: Label = %GoldLabel
@onready var ally_controls_panel: PanelContainer = %AllyControlsPanel
@onready var ally_controls_toggle: Button = %AllyControlsToggle
@onready var ally_controls_content: VBoxContainer = %AllyControlsContent

# Dynamic ability slots
var ability_vboxes: Array[VBoxContainer] = []
var ability_labels: Array[Label] = []
var ability_bars: Array[ProgressBar] = []
var ally_controls_visible: bool = true

func _ready() -> void:
	game_manager = get_tree().get_first_node_in_group("game_manager")
	mouse_shooter = get_tree().get_first_node_in_group("mouse_shooter")
	ability_manager = get_tree().get_first_node_in_group("ability_manager")
	allies_node = get_tree().get_first_node_in_group("allies")
	wave_manager = get_tree().get_first_node_in_group("wave_manager")
	
	if game_manager:
		hp_progress_bar.max_value = game_manager.max_health
		# Connect to start_new_day signal to refresh ally controls
		game_manager.start_new_day.connect(_on_start_new_day)
	
	reload_bar.visible = false
	
	# Setup ability slots based on ability level
	_setup_ability_slots()
	
	# Setup ally controls
	_setup_ally_controls()
	
	# Connect ally controls toggle button
	if ally_controls_toggle:
		ally_controls_toggle.pressed.connect(_on_ally_controls_toggle_pressed)
	
	
func _process(_delta: float) -> void:
	if game_manager != null:
		# Ensure max_value is set correctly (important for web builds)
		if hp_progress_bar.max_value != game_manager.max_health:
			hp_progress_bar.max_value = game_manager.max_health
		hp_progress_bar.value = game_manager.current_health
		time_left_meter.material.set_shader_parameter("value", game_manager.day_timer.time_left / (game_manager.day_time_length))
	
	# Update day/wave display
	if wave_manager:
		var wave_info = wave_manager.get_wave_info()
		day_label.text = "Day " + str(wave_info.current_wave) + " / " + str(wave_info.total_waves)
	else:
		day_label.text = "Day 1 / 10"
	
	# Update gold display
	gold_label.text = str(PlayerData.gold)

	if PlayerData.ally_datas.size() <= 0:
		ally_controls_panel.hide()
	else:
		ally_controls_panel.show()
	
	if mouse_shooter != null:
		# Update ammo display
		ammo_label.text = str(mouse_shooter.current_ammo) + " / " + str(mouse_shooter.magazine_size)
		
		# Update weapon display
		if mouse_shooter.weapon_data:
			weapon_label.text = mouse_shooter.weapon_data.weapon_name
		else:
			weapon_label.text = "No Weapon"
		
		# Show/hide reload bar and update progress
		if mouse_shooter.is_reloading:
			reload_bar.visible = true
			reload_bar.value = mouse_shooter.reload_progress * 100
		else:
			reload_bar.visible = false
	
	# Update ability cooldowns
	if ability_manager:
		for i in range(ability_vboxes.size()):
			_update_ability(i, ability_labels[i], ability_bars[i], ability_vboxes[i])

func _setup_ally_controls() -> void:
	print("=== Ally Controls Debug ===")
	print("Allies node found: ", allies_node != null)
	print("Ally controls content found: ", ally_controls_content != null)
	print("PlayerData.ally_datas size: ", PlayerData.ally_datas.size())
	
	if not ally_controls_content:
		print("ERROR: ally_controls_content is null!")
		return
	
	# Wait multiple frames to ensure all allies are loaded
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Clear existing controls
	for child in ally_controls_content.get_children():
		child.queue_free()
	
	# Get all allies
	var all_allies = get_tree().get_nodes_in_group("allies")
	print("Total nodes in 'allies' group: ", all_allies.size())
	
	# If no spawned allies but we have ally data, show empty panel
	if all_allies.size() == 0 and PlayerData.ally_datas.size() > 0:
		print("Allies not spawned yet - panel will update on day start")
		return
	
	# Create control for each combat ally
	var combat_allies_count = 0
	for ally in all_allies:
		print("Found node: ", ally.name, " - Is Ally class: ", ally is Ally)
		if ally is Ally:
			print("  Ally type: ", ally.ally_type, " (Support = ", Ally.AllyType.SUPPORT, ")")
			if ally.ally_type != Ally.AllyType.SUPPORT:
				print("  Creating control for: ", ally.ally_name)
				_create_ally_control(ally)
				combat_allies_count += 1
	
	print("Created controls for ", combat_allies_count, " combat allies")

func _setup_ability_slots() -> void:
	# Clear existing ability slots
	for child in abilities_container.get_children():
		child.queue_free()
	
	ability_vboxes.clear()
	ability_labels.clear()
	ability_bars.clear()
	
	# Create ability slots based on ability_slots_level
	var ability_slots = PlayerData.ability_slots_level
	
	for i in range(ability_slots):
		# Create VBoxContainer for this ability
		var vbox = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 2)
		
		# Create label
		var label = Label.new()
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		
		# Create StyleBox for label
		var label_settings = LabelSettings.new()
		label_settings.shadow_color = Color(0, 0, 0, 0.6)
		label.label_settings = label_settings
		
		# Create progress bar
		var progress_bar = ProgressBar.new()
		progress_bar.custom_minimum_size = Vector2(140, 18)
		progress_bar.show_percentage = false
		
		# Create StyleBoxes for progress bar
		var bg_style = StyleBoxFlat.new()
		bg_style.bg_color = Color(0.15, 0.15, 0.15, 0.8)
		bg_style.corner_radius_top_left = 4
		bg_style.corner_radius_top_right = 4
		bg_style.corner_radius_bottom_right = 4
		bg_style.corner_radius_bottom_left = 4
		
		var fill_style = StyleBoxFlat.new()
		fill_style.bg_color = Color(0.3, 1, 0.3, 1)
		fill_style.corner_radius_top_left = 4
		fill_style.corner_radius_top_right = 4
		fill_style.corner_radius_bottom_right = 4
		fill_style.corner_radius_bottom_left = 4
		
		progress_bar.add_theme_stylebox_override("background", bg_style)
		progress_bar.add_theme_stylebox_override("fill", fill_style)
		progress_bar.value = 100.0
		
		# Add to VBox
		vbox.add_child(label)
		vbox.add_child(progress_bar)
		
		# Add to container
		abilities_container.add_child(vbox)
		
		# Store references
		ability_vboxes.append(vbox)
		ability_labels.append(label)
		ability_bars.append(progress_bar)

func _create_ally_control(ally: Ally) -> void:
	# Container for this ally
	var ally_hbox = HBoxContainer.new()
	ally_hbox.add_theme_constant_override("separation", 8)
	
	# Ally name label
	var name_label = Label.new()
	name_label.text = ally.ally_name + ":"
	name_label.custom_minimum_size = Vector2(100, 0)
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ally_hbox.add_child(name_label)
	
	# Targeting mode dropdown
	var dropdown = OptionButton.new()
	dropdown.custom_minimum_size = Vector2(120, 28)
	dropdown.add_theme_font_size_override("font_size", 14)
	
	# Add options
	dropdown.add_item("Closest", 0)
	dropdown.add_item("Farthest", 1)
	dropdown.add_item("Strongest", 2)
	dropdown.add_item("Weakest", 3)
	
	# Set current selection
	dropdown.selected = ally.targeting_mode
	
	# Connect signal
	dropdown.item_selected.connect(_on_targeting_dropdown_changed.bind(ally))
	
	ally_hbox.add_child(dropdown)
	ally_controls_content.add_child(ally_hbox)

func _on_targeting_dropdown_changed(index: int, ally: Ally) -> void:
	if ally and is_instance_valid(ally):
		ally.targeting_mode = index as Ally.TargetingMode
		print(ally.ally_name, " targeting mode changed to: ", ["Closest", "Farthest", "Strongest", "Weakest"][index])

func _update_ability(index: int, label: Label, progress_bar: ProgressBar, container: VBoxContainer) -> void:
	if not label or not progress_bar or not container:
		return
	
	var ability = ability_manager.get_ability(index)
	if ability:
		container.visible = true
		# Get the input key for this ability (Q=1, W=2, E=3, etc.)
		var key_names = ["Q", "W", "E", "R", "T"]
		var key_display = key_names[index] if index < key_names.size() else str(index + 1)
		label.text = ability.ability_name + " (" + key_display + ")"
		
		if ability.is_on_cooldown:
			progress_bar.value = ability.get_cooldown_progress() * 100.0
			progress_bar.modulate = Color(0.7, 0.7, 0.7, 1.0)  # Gray when on cooldown
		else:
			progress_bar.value = 100.0
			progress_bar.modulate = Color(0.3, 1.0, 0.3, 1.0)  # Green when ready
	else:
		# No ability assigned to this slot yet
		container.visible = true
		var key_names = ["Q", "W", "E", "R", "T"]
		var key_display = key_names[index] if index < key_names.size() else str(index + 1)
		label.text = "Empty (" + key_display + ")"
		progress_bar.value = 0.0
		progress_bar.modulate = Color(0.5, 0.5, 0.5, 0.5)  # Dim gray for empty

func _on_start_new_day() -> void:
	print("HUD: Refreshing ally controls and ability slots for new day")
	# Refresh ability slots in case level changed
	_setup_ability_slots()
	# Wait multiple frames to ensure allies are spawned
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	_setup_ally_controls()

func _on_ally_controls_toggle_pressed() -> void:
	ally_controls_visible = !ally_controls_visible
	if ally_controls_content:
		ally_controls_content.visible = ally_controls_visible
		# Update button text
		if ally_controls_toggle:
			ally_controls_toggle.text = "▼" if ally_controls_visible else "▶"
