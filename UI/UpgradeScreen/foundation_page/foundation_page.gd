extends Panel
class_name FoundationPage

var game_manager : GameManager

@onready var upgrade_armory_selection_button: Button = %UpgradeArmorySelectionButton
@onready var upgrade_ally_slots_button: Button = %UpgradeAllySlotsButton
@onready var upgrade_ability_slots_button: Button = %UpgradeAbilitySlotsButton

func _ready() -> void:
	game_manager = get_tree().get_first_node_in_group("game_manager")

func _process(delta: float) -> void:
	update_armory_selection_button_data()
	update_ally_slots_button_data()
	update_ability_slots_button_data()
		
func update_armory_selection_button_data() -> void:
	upgrade_armory_selection_button.text = "Uprgade Armory Selection (%s/3)" % [PlayerData.armory_level]
	if PlayerData.armory_level >= 3:
		upgrade_armory_selection_button.disabled = true

func update_ally_slots_button_data() -> void:
	upgrade_ally_slots_button.text = "Upgrade Ally Slots (%s/4)" % [PlayerData.allies_level]
	if PlayerData.allies_level >= 4:
		upgrade_ally_slots_button.disabled = true

func update_ability_slots_button_data() -> void:
	upgrade_ability_slots_button.text = "Upgrade Ability Slots (%s/3)" % [PlayerData.ability_slots_level]
	if PlayerData.ability_slots_level >= 3:
		upgrade_ability_slots_button.disabled = true

func _on_regain_health_button_pressed() -> void:
	game_manager.current_health += 50
	pass # Replace with function body.


func _on_upgrade_base_health_button_pressed() -> void:
	game_manager.max_health += 50
	game_manager.current_health += 50
	pass # Replace with function body.


func _on_upgrade_armory_selection_button_pressed() -> void:
	PlayerData.armory_level += 1
	var armory_page : ArmoryPage = get_tree().get_first_node_in_group("armory_page")
	
	match PlayerData.armory_level:
		2:
			for weapon_slot : ArmoryWeaponSlot in armory_page.weapons_row_2.get_children():
				weapon_slot.weapon_locked = false
		3:
			for weapon_slot : ArmoryWeaponSlot in armory_page.weapons_row_3.get_children():
				weapon_slot.weapon_locked = false


func _on_upgrade_ally_slots_button_pressed() -> void:
	PlayerData.allies_level += 1



func _on_upgrade_ability_slots_button_pressed() -> void:
	PlayerData.ability_slots_level += 1
