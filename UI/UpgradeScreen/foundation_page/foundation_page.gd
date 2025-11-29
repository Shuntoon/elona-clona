extends Panel
class_name FoundationPage

var game_manager : GameManager

@onready var regain_health_button: Button = $MarginContainer/GridContainer/RegainHealthButton
@onready var upgrade_base_health_button: Button = $MarginContainer/GridContainer/UpgradeBaseHealthButton
@onready var upgrade_armory_selection_button: Button = %UpgradeArmorySelectionButton
@onready var upgrade_ally_slots_button: Button = %UpgradeAllySlotsButton
@onready var upgrade_ability_slots_button: Button = %UpgradeAbilitySlotsButton
@onready var upgrade_augment_rerolls_button: Button = $MarginContainer/GridContainer/UpgradeAugmentRerollsButton

# Base prices for each upgrade
const REGAIN_HEALTH_BASE_PRICE: int = 25
const UPGRADE_BASE_HEALTH_BASE_PRICE: int = 100
const UPGRADE_ARMORY_BASE_PRICE: int = 150
const UPGRADE_ALLY_SLOTS_BASE_PRICE: int = 200
const UPGRADE_ABILITY_SLOTS_BASE_PRICE: int = 200
const UPGRADE_AUGMENT_REROLLS_BASE_PRICE: int = 75
const REROLL_DISCOUNT_PER_LEVEL: float = 0.15  # 15% discount per upgrade
const BASE_REROLL_COST: int = 150

# Price multiplier per level
const PRICE_MULTIPLIER: float = 1.5

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

func get_escalating_price(base_price: int, purchase_count: int) -> int:
	return int(base_price * pow(PRICE_MULTIPLIER, purchase_count))

func update_regain_health_button_data() -> void:
	var price = get_escalating_price(REGAIN_HEALTH_BASE_PRICE, regain_health_purchases)
	regain_health_button.text = "Regain 50 Health\n[%d Gold]" % price
	regain_health_button.disabled = PlayerData.gold < price

func update_base_health_button_data() -> void:
	var price = get_escalating_price(UPGRADE_BASE_HEALTH_BASE_PRICE, upgrade_base_health_purchases)
	upgrade_base_health_button.text = "Upgrade Base Health (+50)\n[%d Gold]" % price
	upgrade_base_health_button.disabled = PlayerData.gold < price

func update_armory_selection_button_data() -> void:
	var price = get_escalating_price(UPGRADE_ARMORY_BASE_PRICE, PlayerData.armory_level - 1)
	upgrade_armory_selection_button.text = "Upgrade Armory Selection (%s/4)\n[%d Gold]" % [PlayerData.armory_level, price]
	if PlayerData.armory_level >= 4:
		upgrade_armory_selection_button.text = "Upgrade Armory Selection (MAX)"
		upgrade_armory_selection_button.disabled = true
	else:
		upgrade_armory_selection_button.disabled = PlayerData.gold < price

func update_ally_slots_button_data() -> void:
	var price = get_escalating_price(UPGRADE_ALLY_SLOTS_BASE_PRICE, PlayerData.allies_level - 1)
	upgrade_ally_slots_button.text = "Upgrade Ally Slots (%s/4)\n[%d Gold]" % [PlayerData.allies_level, price]
	if PlayerData.allies_level >= 4:
		upgrade_ally_slots_button.text = "Upgrade Ally Slots (MAX)"
		upgrade_ally_slots_button.disabled = true
	else:
		upgrade_ally_slots_button.disabled = PlayerData.gold < price

func update_ability_slots_button_data() -> void:
	var price = get_escalating_price(UPGRADE_ABILITY_SLOTS_BASE_PRICE, PlayerData.ability_slots_level - 1)
	upgrade_ability_slots_button.text = "Upgrade Ability Slots (%s/3)\n[%d Gold]" % [PlayerData.ability_slots_level, price]
	if PlayerData.ability_slots_level >= 3:
		upgrade_ability_slots_button.text = "Upgrade Ability Slots (MAX)"
		upgrade_ability_slots_button.disabled = true
	else:
		upgrade_ability_slots_button.disabled = PlayerData.gold < price

func update_augment_rerolls_button_data() -> void:
	var price = get_escalating_price(UPGRADE_AUGMENT_REROLLS_BASE_PRICE, PlayerData.reroll_discount_level)
	var current_reroll_cost = get_current_reroll_cost()
	upgrade_augment_rerolls_button.text = "Reduce Reroll Cost (-15%%)\nCurrent: %d Gold | [%d Gold]" % [current_reroll_cost, price]
	upgrade_augment_rerolls_button.disabled = PlayerData.gold < price

func get_current_reroll_cost() -> int:
	var discount = PlayerData.reroll_discount_level * REROLL_DISCOUNT_PER_LEVEL
	return int(BASE_REROLL_COST * (1.0 - discount))

func _on_regain_health_button_pressed() -> void:
	var price = get_escalating_price(REGAIN_HEALTH_BASE_PRICE, regain_health_purchases)
	if PlayerData.gold >= price:
		PlayerData.gold -= price
		game_manager.current_health += 50
		regain_health_purchases += 1


func _on_upgrade_base_health_button_pressed() -> void:
	var price = get_escalating_price(UPGRADE_BASE_HEALTH_BASE_PRICE, upgrade_base_health_purchases)
	if PlayerData.gold >= price:
		PlayerData.gold -= price
		game_manager.max_health += 50
		game_manager.current_health += 50
		upgrade_base_health_purchases += 1


func _on_upgrade_armory_selection_button_pressed() -> void:
	var price = get_escalating_price(UPGRADE_ARMORY_BASE_PRICE, PlayerData.armory_level - 1)
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
	var price = get_escalating_price(UPGRADE_ALLY_SLOTS_BASE_PRICE, PlayerData.allies_level - 1)
	if PlayerData.gold >= price and PlayerData.allies_level < 4:
		PlayerData.gold -= price
		PlayerData.allies_level += 1


func _on_upgrade_ability_slots_button_pressed() -> void:
	var price = get_escalating_price(UPGRADE_ABILITY_SLOTS_BASE_PRICE, PlayerData.ability_slots_level - 1)
	if PlayerData.gold >= price and PlayerData.ability_slots_level < 3:
		PlayerData.gold -= price
		PlayerData.ability_slots_level += 1


func _on_upgrade_augment_rerolls_button_pressed() -> void:
	var price = get_escalating_price(UPGRADE_AUGMENT_REROLLS_BASE_PRICE, PlayerData.reroll_discount_level)
	if PlayerData.gold >= price:
		PlayerData.gold -= price
		PlayerData.reroll_discount_level += 1
