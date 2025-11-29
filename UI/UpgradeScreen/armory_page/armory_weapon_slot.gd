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

# Tooltip popup
var tooltip_popup: PanelContainer = null
var hover_timer: Timer = null
var is_hovering: bool = false
const TOOLTIP_DELAY: float = 0.5  # seconds before showing tooltip

func _ready() -> void:
	if weapon_data:
		_update_weapon_display()
	
	# Ensure this panel can receive mouse events
	mouse_filter = Control.MOUSE_FILTER_PASS
	
	# Make all children pass mouse events through to parent
	_set_mouse_filter_recursive(self, Control.MOUSE_FILTER_PASS)
	
	# Create hover timer
	hover_timer = Timer.new()
	hover_timer.one_shot = true
	hover_timer.timeout.connect(_on_hover_timer_timeout)
	add_child(hover_timer)
	# Connect mouse signals for hover
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _set_mouse_filter_recursive(node: Node, filter: Control.MouseFilter) -> void:
	if node is Control:
		# Keep buttons clickable, but everything else should pass through
		if node is Button:
			pass  # Don't change button filter
		else:
			node.mouse_filter = filter
	
	for child in node.get_children():
		_set_mouse_filter_recursive(child, filter)

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

func _on_mouse_entered() -> void:
	if not weapon_data:
		return
	is_hovering = true
	# Start timer to show tooltip after delay
	if hover_timer:
		hover_timer.start(TOOLTIP_DELAY)

func _on_mouse_exited() -> void:
	is_hovering = false
	# Stop the timer if still waiting
	if hover_timer:
		hover_timer.stop()
	_hide_tooltip()

func _on_hover_timer_timeout() -> void:
	# Only show tooltip if still hovering
	if is_hovering and weapon_data:
		_show_tooltip()

func _show_tooltip() -> void:
	if tooltip_popup:
		return
	
	# Create tooltip container
	tooltip_popup = PanelContainer.new()
	tooltip_popup.z_index = 100
	tooltip_popup.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Don't intercept mouse events
	
	# Style the panel
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.12, 0.08, 0.95)
	style.border_color = Color(0.6, 0.5, 0.3, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(12)
	tooltip_popup.add_theme_stylebox_override("panel", style)
	
	# Create content container
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	tooltip_popup.add_child(vbox)
	
	# Weapon name (header)
	var name_lbl = Label.new()
	name_lbl.text = weapon_data.weapon_name
	name_lbl.add_theme_font_size_override("font_size", 20)
	name_lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.6))
	vbox.add_child(name_lbl)
	
	# Description
	if weapon_data.description and weapon_data.description != "":
		var desc_lbl = Label.new()
		desc_lbl.text = weapon_data.description
		desc_lbl.add_theme_font_size_override("font_size", 14)
		desc_lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_lbl.custom_minimum_size.x = 250
		vbox.add_child(desc_lbl)
	
	# Separator
	var sep = HSeparator.new()
	vbox.add_child(sep)
	
	# Stats
	_add_stat_line(vbox, "Damage", str(weapon_data.bullet_damage))
	_add_stat_line(vbox, "Fire Rate", "%d RPM" % int(weapon_data.fire_rate))
	_add_stat_line(vbox, "Magazine", str(weapon_data.magazine_size))
	_add_stat_line(vbox, "Reload Time", "%.1fs" % weapon_data.reload_time)
	_add_stat_line(vbox, "Accuracy", "%d%%" % int(weapon_data.accuracy * 100))
	_add_stat_line(vbox, "Crit Chance", "%d%%" % int(weapon_data.crit_chance * 100))
	_add_stat_line(vbox, "Crit Multiplier", "x%.1f" % weapon_data.crit_multiplier)
	
	if weapon_data.projectile_piercing:
		_add_stat_line(vbox, "Piercing", "Yes", Color(0.4, 1.0, 0.4))
	
	if weapon_data.bleed_chance > 0:
		_add_stat_line(vbox, "Bleed Chance", "%d%%" % int(weapon_data.bleed_chance * 100), Color(1.0, 0.4, 0.4))
	
	if weapon_data.explosive_rockets:
		_add_stat_line(vbox, "Explosive", "Yes", Color(1.0, 0.6, 0.2))
		_add_stat_line(vbox, "Explosion Damage", str(weapon_data.explosion_damage), Color(1.0, 0.6, 0.2))
		_add_stat_line(vbox, "Explosion Radius", str(int(weapon_data.explosion_radius)), Color(1.0, 0.6, 0.2))
	
	# Add to a CanvasLayer so it renders on top and uses screen coordinates
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 100
	get_tree().root.add_child(canvas_layer)
	canvas_layer.add_child(tooltip_popup)
	
	# Store reference to canvas layer for cleanup
	tooltip_popup.set_meta("canvas_layer", canvas_layer)
	
	# Position near mouse - use screen position
	var mouse_pos = get_viewport().get_mouse_position()
	tooltip_popup.position = mouse_pos + Vector2(15, -135)

func _add_stat_line(parent: VBoxContainer, stat_name: String, stat_value: String, color: Color = Color(1, 1, 1)) -> void:
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	
	var name_lbl = Label.new()
	name_lbl.text = stat_name + ":"
	name_lbl.add_theme_font_size_override("font_size", 14)
	name_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(name_lbl)
	
	var value_lbl = Label.new()
	value_lbl.text = stat_value
	value_lbl.add_theme_font_size_override("font_size", 14)
	value_lbl.add_theme_color_override("font_color", color)
	value_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hbox.add_child(value_lbl)
	
	parent.add_child(hbox)

func _hide_tooltip() -> void:
	if tooltip_popup:
		# Also cleanup the canvas layer we created
		if tooltip_popup.has_meta("canvas_layer"):
			var canvas_layer = tooltip_popup.get_meta("canvas_layer")
			if canvas_layer:
				canvas_layer.queue_free()
		else:
			tooltip_popup.queue_free()
		tooltip_popup = null

func _exit_tree() -> void:
	_hide_tooltip()
