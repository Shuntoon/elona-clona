extends Control
class_name PlayerHUD

var game_manager : GameManager
var mouse_shooter : MouseShooter
var ability_manager : AbilityManager

@onready var hp_progress_bar: ProgressBar = %HPProgressBar
@onready var time_left_meter: ColorRect = %TimeLeftMeter
@onready var ammo_label: Label = %AmmoLabel
@onready var reload_bar: ProgressBar = %ReloadBar
@onready var abilities_container: HBoxContainer = $MarginContainer/AbilitiesHBoxContainer
@onready var ability_1_label: Label = %Ability1Label
@onready var ability_2_label: Label = %Ability2Label
@onready var ability_3_label: Label = %Ability3Label
@onready var ability_1_bar: ProgressBar = %Ability1Bar
@onready var ability_2_bar: ProgressBar = %Ability2Bar
@onready var ability_3_bar: ProgressBar = %Ability3Bar
@onready var ability_1_vbox: VBoxContainer = %Ability1VBox
@onready var ability_2_vbox: VBoxContainer = %Ability2VBox
@onready var ability_3_vbox: VBoxContainer = %Ability3VBox

func _ready() -> void:
	game_manager = get_tree().get_first_node_in_group("game_manager")
	mouse_shooter = get_tree().get_first_node_in_group("mouse_shooter")
	ability_manager = get_tree().get_first_node_in_group("ability_manager")
	
	if game_manager:
		hp_progress_bar.max_value = game_manager.max_health
	
	reload_bar.visible = false
	
	print("=== Ability System Debug ===")
	print("Ability Manager found: ", ability_manager != null)
	if ability_manager:
		print("Number of abilities: ", ability_manager.abilities.size())
	print("Abilities Container found: ", abilities_container != null)
	print("Ability 1 Label found: ", ability_1_label != null)
	print("Ability 1 VBox found: ", ability_1_vbox != null)
	
	
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
	
	# Update ability cooldowns
	if ability_manager:
		_update_ability(0, ability_1_label, ability_1_bar, ability_1_vbox)
		_update_ability(1, ability_2_label, ability_2_bar, ability_2_vbox)
		_update_ability(2, ability_3_label, ability_3_bar, ability_3_vbox)

func _update_ability(index: int, label: Label, progress_bar: ProgressBar, container: VBoxContainer) -> void:
	if not label or not progress_bar or not container:
		return
	
	var ability = ability_manager.get_ability(index)
	if ability:
		container.visible = true
		label.text = ability.ability_name + " (" + str(index + 1) + ")"
		
		if ability.is_on_cooldown:
			progress_bar.value = ability.get_cooldown_progress() * 100.0
			progress_bar.modulate = Color(0.7, 0.7, 0.7, 1.0)  # Gray when on cooldown
		else:
			progress_bar.value = 100.0
			progress_bar.modulate = Color(0.3, 1.0, 0.3, 1.0)  # Green when ready
	else:
		container.visible = false
