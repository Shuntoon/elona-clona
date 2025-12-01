extends Panel
class_name FoundationPage

var game_manager : GameManager

@onready var regain_health_button: Button = %RegainHealthButton
@onready var upgrade_base_health_button: Button = %UpgradeBaseHealthButton
@onready var upgrade_armory_selection_button: Button = %UpgradeArmorySelectionButton
@onready var upgrade_ally_slots_button: Button = %UpgradeAllySlotsButton
@onready var upgrade_ability_slots_button: Button = %UpgradeAbilitySlotsButton
@onready var upgrade_augment_rerolls_button: Button = $%UpgradeAugmentRerollsButton
@onready var button_sound: AudioStreamPlayer = $ButtonSound

# Base prices for each upgrade (adjustable in editor)
@export var regain_health_base_price: int = 25
@export var upgrade_base_health_base_price: int = 100
@export var upgrade_armory_base_price: int = 150
@export var upgrade_ally_slots_base_price: int = 200
@export var upgrade_ability_slots_base_price: int = 200
@export var upgrade_augment_rerolls_base_price: int = 75
@export var reroll_discount_per_level: float = 0.15  # 15% discount per upgrade
@export var base_reroll_cost: int = 250

# Price multiplier per level
@export var price_multiplier: float = 1.5

# Per-button price multipliers (override global `price_multiplier` for fine control)
@export var regain_health_price_multiplier: float = 1.5
@export var upgrade_base_health_price_multiplier: float = 1.5
@export var upgrade_armory_price_multiplier: float = 1.5
@export var upgrade_ally_slots_price_multiplier: float = 1.5
@export var upgrade_ability_slots_price_multiplier: float = 1.5
@export var upgrade_augment_rerolls_price_multiplier: float = 1.5

# Track purchase counts for repeatable upgrades
var regain_health_purchases: int = 0
var upgrade_base_health_purchases: int = 0

func _ready() -> void:
	game_manager = get_tree().get_first_node_in_group("game_manager")

func _process(_delta: float) -> void:
	update_regain_health_button_data()
	update_base_health_button_data()
	update_armory_selection_button_data()
	update_ally_slots_button_data()
	update_ability_slots_button_data()
	update_augment_rerolls_button_data()

func get_escalating_price(base_price: int, purchase_count: int, multiplier: float = -1.0) -> int:
	# If no multiplier passed, use global price_multiplier
	if multiplier <= 0.0:
		multiplier = price_multiplier
	return int(base_price * pow(multiplier, purchase_count))

func update_regain_health_button_data() -> void:
	var price = get_escalating_price(regain_health_base_price, regain_health_purchases, regain_health_price_multiplier)
	regain_health_button.text = "Regain 50 Health\n[%d Gold]" % price
	regain_health_button.disabled = PlayerData.gold < price

func update_base_health_button_data() -> void:
	var price = get_escalating_price(upgrade_base_health_base_price, upgrade_base_health_purchases, upgrade_base_health_price_multiplier)
	upgrade_base_health_button.text = "Upgrade Base Health (+50)\n[%d Gold]" % price
	upgrade_base_health_button.disabled = PlayerData.gold < price

func update_armory_selection_button_data() -> void:
	var price = get_escalating_price(upgrade_armory_base_price, PlayerData.armory_level - 1, upgrade_armory_price_multiplier)
	upgrade_armory_selection_button.text = "Upgrade Armory Selection (%s/4)\n[%d Gold]" % [PlayerData.armory_level, price]
	if PlayerData.armory_level >= 4:
		upgrade_armory_selection_button.text = "Upgrade Armory Selection (MAX)"
		upgrade_armory_selection_button.disabled = true
	else:
		upgrade_armory_selection_button.disabled = PlayerData.gold < price

func update_ally_slots_button_data() -> void:
	var price = get_escalating_price(upgrade_ally_slots_base_price, PlayerData.allies_level - 1, upgrade_ally_slots_price_multiplier)
	upgrade_ally_slots_button.text = "Upgrade Ally Slots (%s/4)\n[%d Gold]" % [PlayerData.allies_level, price]
	if PlayerData.allies_level >= 4:
		upgrade_ally_slots_button.text = "Upgrade Ally Slots (MAX)"
		upgrade_ally_slots_button.disabled = true
	else:
		upgrade_ally_slots_button.disabled = PlayerData.gold < price

func update_ability_slots_button_data() -> void:
	var price = get_escalating_price(upgrade_ability_slots_base_price, PlayerData.ability_slots_level - 1, upgrade_ability_slots_price_multiplier)
	upgrade_ability_slots_button.text = "Upgrade Ability Slots (%s/3)\n[%d Gold]" % [PlayerData.ability_slots_level, price]
	if PlayerData.ability_slots_level >= 3:
		upgrade_ability_slots_button.text = "Upgrade Ability Slots (MAX)"
		upgrade_ability_slots_button.disabled = true
	else:
		upgrade_ability_slots_button.disabled = PlayerData.gold < price

func update_augment_rerolls_button_data() -> void:
	var price = get_escalating_price(upgrade_augment_rerolls_base_price, PlayerData.reroll_discount_level, upgrade_augment_rerolls_price_multiplier)
	var current_reroll_cost = get_current_reroll_cost()
	upgrade_augment_rerolls_button.text = "Reduce Reroll Cost (-15%%)\nCurrent: %d Gold | [%d Gold]" % [current_reroll_cost, price]
	upgrade_augment_rerolls_button.disabled = PlayerData.gold < price

func get_current_reroll_cost() -> int:
	var discount = PlayerData.reroll_discount_level * reroll_discount_per_level
	return int(base_reroll_cost * (1.0 - discount))

func _on_regain_health_button_pressed() -> void:
	button_sound.play()
	var price = get_escalating_price(regain_health_base_price, regain_health_purchases, regain_health_price_multiplier)
	if PlayerData.gold >= price:
		PlayerData.gold -= price
		game_manager.current_health += 50
		#regain_health_purchases += 1


func _on_upgrade_base_health_button_pressed() -> void:
	button_sound.play()
	var price = get_escalating_price(upgrade_base_health_base_price, upgrade_base_health_purchases, upgrade_base_health_price_multiplier)
	if PlayerData.gold >= price:
		PlayerData.gold -= price
		game_manager.max_health += 50
		game_manager.current_health += 50
		upgrade_base_health_purchases += 1


func _on_upgrade_armory_selection_button_pressed() -> void:
	button_sound.play()
	var price = get_escalating_price(upgrade_armory_base_price, PlayerData.armory_level - 1, upgrade_armory_price_multiplier)
	if PlayerData.gold >= price and PlayerData.armory_level < 4:
		PlayerData.gold -= price
		PlayerData.armory_level += 1
		var armory_page : ArmoryPage = get_tree().get_first_node_in_group("armory_page")
		
		match PlayerData.armory_level:
			2:
				for weapon_slot : ArmoryWeaponSlot in armory_page.weapons_row_2.get_children():
					weapon_slot.weapon_locked = false
			3:
				for weapon_slot : ArmoryWeaponSlot in armory_page.weapons_row_3.get_children():
					weapon_slot.weapon_locked = false
			4:
				for weapon_slot : ArmoryWeaponSlot in armory_page.weapons_row_4.get_children():
					weapon_slot.weapon_locked = false


func _on_upgrade_ally_slots_button_pressed() -> void:
	button_sound.play()
	var price = get_escalating_price(upgrade_ally_slots_base_price, PlayerData.allies_level - 1, upgrade_ally_slots_price_multiplier)
	if PlayerData.gold >= price and PlayerData.allies_level < 4:
		PlayerData.gold -= price
		PlayerData.allies_level += 1


func _on_upgrade_ability_slots_button_pressed() -> void:
	button_sound.play()
	var price = get_escalating_price(upgrade_ability_slots_base_price, PlayerData.ability_slots_level - 1, upgrade_ability_slots_price_multiplier)
	if PlayerData.gold >= price and PlayerData.ability_slots_level < 3:
		PlayerData.gold -= price
		PlayerData.ability_slots_level += 1


func _on_upgrade_augment_rerolls_button_pressed() -> void:
	button_sound.play()
	var price = get_escalating_price(upgrade_augment_rerolls_base_price, PlayerData.reroll_discount_level, upgrade_augment_rerolls_price_multiplier)
	if PlayerData.gold >= price:
		PlayerData.gold -= price
		PlayerData.reroll_discount_level += 1
