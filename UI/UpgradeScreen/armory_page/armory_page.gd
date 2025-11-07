extends Panel
class_name ArmoryPage

signal equipped_weapons_updated

@onready var weapon_1_panel: Panel = %Weapon1Panel
@onready var weapon_1_name_label: Label = %Weapon1NameLabel
@onready var weapon_1_image: TextureRect = %Weapon1Image

@onready var weapon_2_panel: Panel = %Weapon2Panel
@onready var weapon_2_name_label: Label = %Weapon2NameLabel
@onready var weapon_2_image: TextureRect = %Weapon2Image

@onready var weapons_row_1: VBoxContainer = %WeaponsRow1
@onready var weapons_row_2: VBoxContainer = %WeaponsRow2
@onready var weapons_row_3: VBoxContainer = %WeaponsRow3

var weapon_1_data: WeaponData
var weapon_2_data: WeaponData

func _ready() -> void:
	for armory_weapon_slot : ArmoryWeaponSlot in weapons_row_1.get_children():
		armory_weapon_slot.weapon_locked = false
		
	equipped_weapons_updated.connect(update_equipped_weapons)

	weapon_1_data = PlayerData.weapon_1_data
	weapon_2_data = PlayerData.weapon_2_data

	if weapon_1_data != null or weapon_2_data != null:
		print("Equipping weapons")
		update_equipped_weapons()


func update_equipped_weapons() -> void:
	weapon_1_data = PlayerData.weapon_1_data
	weapon_2_data = PlayerData.weapon_2_data
	
	if weapon_1_data != null:
		weapon_1_name_label.text = weapon_1_data.weapon_name
		weapon_1_image.texture = weapon_1_data.icon

	if weapon_2_data != null:
		weapon_2_name_label.text = weapon_2_data.weapon_name
		weapon_2_image.texture = weapon_2_data.icon
