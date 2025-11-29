extends Panel
class_name AugmentPanelButton

@export var augment_data : AugmentData

@onready var icon_texture: TextureRect = %IconTexture
@onready var name_label: Label = %NameLabel
@onready var decription_label: Label = %DecriptionLabel
@onready var purchased_panel: Panel = $PurchasedPanel
@onready var price_label: Label = %Label
@onready var buy_button: Button = $BuyButton
@onready var button_sound: AudioStreamPlayer = $ButtonSound

var base_scale := Vector2.ONE
var hover_tween: Tween
var is_purchased := false

func _ready():
	base_scale = scale
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	init_panel(augment_data)

func _process(delta):
	_update_buy_button()
	

func animate_entrance(delay: float = 0.0) -> void:
	# Start off-screen and transparent
	modulate.a = 0.0
	scale = Vector2(0.8, 0.8)
	position.y += 50
	
	# Animate in with delay
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "modulate:a", 1.0, 0.3).set_delay(delay).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", base_scale, 0.35).set_delay(delay).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "position:y", position.y - 50, 0.3).set_delay(delay).set_ease(Tween.EASE_OUT)

func _on_mouse_entered() -> void:
	if is_purchased:
		return
	if hover_tween and hover_tween.is_valid():
		hover_tween.kill()
	hover_tween = create_tween().set_parallel(true)
	hover_tween.tween_property(self, "scale", base_scale * 1.05, 0.15).set_ease(Tween.EASE_OUT)
	# Slight glow effect via modulate
	hover_tween.tween_property(self, "modulate", Color(1.2, 1.2, 1.2, 1.0), 0.15)

func _on_mouse_exited() -> void:
	if is_purchased:
		return
	if hover_tween and hover_tween.is_valid():
		hover_tween.kill()
	hover_tween = create_tween().set_parallel(true)
	hover_tween.tween_property(self, "scale", base_scale, 0.15).set_ease(Tween.EASE_OUT)
	hover_tween.tween_property(self, "modulate", Color.WHITE, 0.15) 

func init_panel(augment_data_inst: AugmentData) -> void:
	augment_data = augment_data_inst
	icon_texture.texture = augment_data.icon
	name_label.text = augment_data.name
	decription_label.text = augment_data.description
	price_label.text = "%d$" % augment_data.price
	
	# Update buy button state based on player gold
	
	# Set color based on rarity
	_set_rarity_color()

func _update_buy_button() -> void:
	if PlayerData.gold < augment_data.price:
		buy_button.disabled = true
		buy_button.text = "Can't Afford"
	else:
		buy_button.disabled = false
		buy_button.text = "Buy"

func _set_rarity_color() -> void:
	var color: Color
	
	match augment_data.rarity:
		AugmentData.Rarity.COMMON:
			color = Color(0.622, 0.622, 0.622, 1.0)  # Grey
		AugmentData.Rarity.UNCOMMON:
			color = Color(0.112, 1.0, 0.112, 1.0)  # Green
		AugmentData.Rarity.RARE:
			color = Color(0.605, 0.079, 1.0, 1.0)  # Purple
		AugmentData.Rarity.ABILITY:
			color = Color(0.5, 0.9, 1.0)  # Light Blue
		AugmentData.Rarity.LEGENDARY:
			color = Color(1.0, 0.408, 0.053, 1.0)  # Orange-Red
		_:
			color = Color.WHITE  # Default
	
	# Apply color modulation directly to the panel
	self_modulate = color
	
	# Add a pronounced border with the rarity color
	var stylebox = get_theme_stylebox("panel")
	if stylebox:
		stylebox = stylebox.duplicate()
		if stylebox is StyleBoxFlat:
			stylebox.border_width_left = 3
			stylebox.border_width_top = 3
			stylebox.border_width_right = 3
			stylebox.border_width_bottom = 3
			stylebox.border_color = color
		add_theme_stylebox_override("panel", stylebox)


func _on_buy_button_pressed() -> void:
	button_sound.play()
	
	# Double-check player has enough gold
	if PlayerData.gold < augment_data.price:
		print("Not enough gold to buy augment!")
		return
	
	# Deduct gold
	PlayerData.gold -= augment_data.price
	
	# Play purchase animation
	is_purchased = true
	_play_purchase_animation()
	
	purchased_panel.show()

func _play_purchase_animation() -> void:
	var tween = create_tween()
	# Quick scale pop then settle
	tween.tween_property(self, "scale", base_scale * 1.15, 0.1).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", base_scale * 0.95, 0.15).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "scale", base_scale, 0.1).set_ease(Tween.EASE_OUT)
	# Fade to purchased state
	tween.parallel().tween_property(self, "modulate", Color(0.6, 0.6, 0.6, 1.0), 0.3)
	
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

	# Refresh the owned augments grid if the page is open
	var page = get_tree().get_first_node_in_group("augments_page")
	if page and page.has_method("_populate_owned_augments_grid"):
		page._populate_owned_augments_grid()
