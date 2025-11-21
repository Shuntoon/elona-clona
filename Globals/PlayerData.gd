extends Node

@export var ally_datas : Array[AllyData]

@export var weapon_1_data : WeaponData
@export var weapon_2_data : WeaponData

@export var gold : int = 0

@export var armory_level : int = 1

@export var allies_level : int = 1
@export var ability_slots_level : int = 1

@export var augments : Array[AugmentData] = []
@export var ability_augments : Array[AugmentData] = []  # Max 3 ability augments

func add_ally_data(ally_data: AllyData) -> void:
	ally_datas.append(ally_data)

func can_purchase_ability() -> bool:
	return ability_augments.size() < 3

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("give_me_money"):
			gold += 1000
			print("Cheat activated: Added 1000 gold. New total: ", gold)
