extends Panel
class_name EquippedWeaponPanel

@export_enum("Weapon Slot 1", "Weapon Slot 2") var weapon_slot

var armory_page: ArmoryPage

func _ready() -> void:
	armory_page = get_tree().get_first_node_in_group("armory_page")

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if data.has("weapon_data"):
		print("Can drop weapon data")
		return true

	return false

func _drop_data(at_position: Vector2, data: Variant) -> void:
	if data.has("weapon_data"):
		print("Dropping weapon data")
		var weapon_data: WeaponData = data["weapon_data"]

		if weapon_slot == 0: #Weapon Slot 1
			PlayerData.weapon_1_data = weapon_data
		elif weapon_slot == 1: #Weapon Slot 2
			PlayerData.weapon_2_data = weapon_data

		await get_tree().create_timer(.1).timeout
		armory_page.equipped_weapons_updated.emit()
