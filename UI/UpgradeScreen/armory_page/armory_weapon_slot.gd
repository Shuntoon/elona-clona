extends Panel
class_name ArmoryWeaponSlot

@onready var weapon_name_label: Label = %WeaponNameLabel
@onready var weapon_icon: TextureRect = %WeaponIcon
@onready var locked_weapon_panel: Panel = %LockedWeaponPanel
@onready var buy_button: Button = %BuyButton
@onready var buy_label: Label = %BuyLabel
@onready var lock_texture_rect: TextureRect = %LockTextureRect
@onready var name_label: Label = %NameLabel
@onready var price_label: Label = %PriceLabel

@export var weapon_data: WeaponData
@export var weapon_locked = true
@export var weapon_bought = false

func _ready() -> void:
	if weapon_data:
		_update_weapon_display()

func _process(_delta: float) -> void:
	if weapon_locked:
		lock_weapon()
	else:
		unlock_weapon()
	
	if weapon_bought:
		buy_weapon()

func _update_weapon_display() -> void:
	if not weapon_data:
		return
	
	# Update the visible weapon name and icon
	weapon_name_label.text = weapon_data.weapon_name
	if weapon_data.icon:
		weapon_icon.texture = weapon_data.icon
	
	# Update the locked panel labels
	name_label.text = weapon_data.weapon_name
	price_label.text = "$%d" % weapon_data.price

func lock_weapon() -> void:
	weapon_name_label.hide()
	weapon_icon.hide()
	locked_weapon_panel.show()
	buy_button.disabled = true
	
func unlock_weapon() -> void:
	if weapon_data.price > PlayerData.gold:
		buy_button.disabled = true
		buy_label.text = "Need $$$"
	else:
		buy_label.text = "Buy" 
		buy_button.disabled = false

	buy_label.show()
	lock_texture_rect.hide()
	
	
func buy_weapon() -> void:
	locked_weapon_panel.hide()
	weapon_icon.show()
	weapon_name_label.show()

func _get_drag_data(_at_position: Vector2) -> Variant:
	if not weapon_bought or not weapon_data:
		return null
	
	var data = {
		"weapon_data": weapon_data
	}

	var drag_preview = TextureRect.new()
	if weapon_data.icon:
		drag_preview.texture = weapon_data.icon
	drag_preview.size = Vector2(64, 64)
	
	set_drag_preview(drag_preview)
	return data

func _on_buy_button_pressed() -> void:
	if weapon_data and PlayerData.gold >= weapon_data.price:
		PlayerData.gold -= weapon_data.price
		weapon_bought = true
