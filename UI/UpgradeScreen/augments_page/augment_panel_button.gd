extends Panel
class_name AugmentPanelButton

@export var augment_data : AugmentData

@onready var icon_texture: TextureRect = %IconTexture
@onready var name_label: Label = %NameLabel
@onready var decription_label: Label = %DecriptionLabel
@onready var purchased_panel: Panel = $PurchasedPanel

func _ready():
	init_panel(augment_data) 

func init_panel(augment_data_inst: AugmentData) -> void:
	augment_data = augment_data_inst
	icon_texture.texture = augment_data.icon
	name_label.text = augment_data.name
	decription_label.text = augment_data.description


func _on_buy_button_pressed() -> void:
	purchased_panel.show()
	
	# Check if this is an ability augment
	if augment_data.augment_type == AugmentData.AugmentType.ABILITY:
		PlayerData.ability_augments.append(augment_data)
		print("Purchased ability augment: ", augment_data.name)
	else:
		PlayerData.augments.append(augment_data)
		print("Purchased stat augment: ", augment_data.name)
	
	# Apply the augment immediately
	var augment_manager = get_tree().get_first_node_in_group("augment_manager")
	if augment_manager:
		augment_manager.apply_augment(augment_data)
		print("Applied augment immediately: ", augment_data.name)
