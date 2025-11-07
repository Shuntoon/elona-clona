extends Panel
class_name ArmoryWeaponSlot

@onready var weapon_name_label: Label = %WeaponNameLabel
@onready var weapon_icon: TextureRect = %WeaponIcon
@onready var locked_weapon_panel: Panel = %LockedWeaponPanel
@onready var buy_button: Button = %BuyButton
@onready var buy_label: Label = %BuyLabel
@onready var lock_texture_rect: TextureRect = %LockTextureRect

@export var weapon_data: WeaponData
@export var weapon_locked = true
@export var weapon_bought = false

func _process(delta: float) -> void:
	if weapon_locked:
		lock_weapon()
	else:
		unlock_weapon()
	
	if weapon_bought:
		buy_weapon()
	
func lock_weapon() -> void:
		weapon_name_label.hide()
		weapon_icon.hide()
		locked_weapon_panel.show()
		buy_button.disabled = true
		
func unlock_weapon() -> void:
		buy_button.disabled = false
		buy_label.show()
		lock_texture_rect.hide()
		
func buy_weapon() -> void:
	locked_weapon_panel.hide()
	weapon_icon.show()
	weapon_name_label.show()

func _get_drag_data(at_position: Vector2) -> Variant:
	var data = {
		"weapon_data": weapon_data
	}
	
	data["weapon_data"] = weapon_data

	var drag_preview = TextureRect.new()
	drag_preview.texture = weapon_data.icon
	drag_preview.size = Vector2(64, 64)
	
	set_drag_preview(drag_preview)
	return data

func _on_buy_button_pressed() -> void:
	weapon_bought = true
	pass # Replace with function body.
