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
	
	# Set color based on rarity
	_set_rarity_color()

func _set_rarity_color() -> void:
	var color: Color
	
	match augment_data.rarity:
		AugmentData.Rarity.COMMON:
			color = Color(0.5, 0.5, 0.5)  # Grey
		AugmentData.Rarity.UNCOMMON:
			color = Color(0.2, 0.8, 0.2)  # Green
		AugmentData.Rarity.RARE:
			color = Color(0.6, 0.2, 0.8)  # Purple
		AugmentData.Rarity.ABILITY:
			color = Color(0.4, 0.8, 1.0)  # Light Blue
		AugmentData.Rarity.LEGENDARY:
			color = Color(1.0, 0.4, 0.1)  # Orange-Red
		_:
			color = Color.WHITE  # Default
	
	# Get or create a StyleBox and apply the color
	var stylebox = get_theme_stylebox("panel")
	if stylebox:
		# Duplicate to avoid modifying the original theme
		stylebox = stylebox.duplicate()
		if stylebox is StyleBoxFlat:
			stylebox.bg_color = color
		add_theme_stylebox_override("panel", stylebox)


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
