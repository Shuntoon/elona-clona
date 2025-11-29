extends Panel
class_name AllyFilledPanel

signal ally_sold

@onready var name_label: Label = %NameLabel
@onready var portrait_texture: TextureRect = %PortraitTexture
@onready var info_label_vbox_container: VBoxContainer = %InfoLabelVBoxContainer
@onready var sell_button: Button = %SellButton

@export var gunner_texture: Texture
@export var rocketeer_texture: Texture
@export var sniper_texture: Texture
@export var support_texture: Texture
@export var machine_gunner_texture: Texture

# Sell price is a percentage of the original buy price
const SELL_PRICE_MULTIPLIER: float = 0.5

var ally_data: AllyData
var ally_index: int = -1  # Index in PlayerData.ally_datas

func setup_with_ally_data(data: AllyData, index: int = -1) -> void:
	ally_data = data
	ally_index = index
	# Wait for ready if not already
	if not is_node_ready():
		await ready
	_update_display()

func _update_display() -> void:
	if not ally_data:
		return
	
	# Set the name
	name_label.text = ally_data.ally_name
	
	# Set the portrait based on ally type
	match ally_data.ally_type:
		Ally.AllyType.RIFLEMAN:
			portrait_texture.texture = gunner_texture
		Ally.AllyType.ROCKETEER:
			portrait_texture.texture = rocketeer_texture
		Ally.AllyType.SNIPER:
			portrait_texture.texture = sniper_texture
		Ally.AllyType.SUPPORT:
			portrait_texture.texture = support_texture
		Ally.AllyType.MACHINE_GUNNER:
			portrait_texture.texture = machine_gunner_texture
	
	# Get ally type as string
	var ally_type_text = _get_ally_type_string(ally_data.ally_type)
	
	# Update the info labels
	var labels = info_label_vbox_container.get_children()
	if labels.size() >= 4:
		labels[0].text = "Type: %s" % ally_type_text
		labels[1].text = "Firerate: %d" % int(ally_data.fire_rate)
		labels[2].text = "Damage: %d" % ally_data.bullet_damage
		labels[3].text = "Accuracy: %d%%" % int(ally_data.accuracy * 100)
	
	# Update sell button text with sell price
	if sell_button and ally_data:
		var sell_price = _get_sell_price()
		sell_button.text = "Sell [+%d Gold]" % sell_price

func _get_sell_price() -> int:
	if ally_data and ally_data.has_method("get") and ally_data.get("price"):
		return int(ally_data.price * SELL_PRICE_MULTIPLIER)
	# Default sell price based on ally type
	match ally_data.ally_type:
		Ally.AllyType.RIFLEMAN:
			return 25
		Ally.AllyType.ROCKETEER:
			return 50
		Ally.AllyType.SNIPER:
			return 40
		Ally.AllyType.SUPPORT:
			return 35
		Ally.AllyType.MACHINE_GUNNER:
			return 45
		_:
			return 25

func _on_sell_button_pressed() -> void:
	if ally_index < 0 or ally_index >= PlayerData.ally_datas.size():
		# Try to find the ally in the array
		ally_index = PlayerData.ally_datas.find(ally_data)
	
	if ally_index >= 0 and ally_index < PlayerData.ally_datas.size():
		# Add gold
		var sell_price = _get_sell_price()
		PlayerData.gold += sell_price
		
		# Remove ally from PlayerData
		PlayerData.ally_datas.remove_at(ally_index)
		
		print("Sold ally: ", ally_data.ally_name, " for ", sell_price, " gold")
		
		# Emit signal to refresh the allies page
		ally_sold.emit()
		
		# Refresh the allies page
		var allies_page = get_tree().get_first_node_in_group("allies_page")
		if allies_page:
			allies_page.populate_allies_hbox()

func _get_ally_type_string(ally_type: Ally.AllyType) -> String:
	match ally_type:
		Ally.AllyType.RIFLEMAN:
			return "Rifleman"
		Ally.AllyType.ROCKETEER:
			return "Rocketeer"
		Ally.AllyType.SUPPORT:
			return "Support"
		Ally.AllyType.MACHINE_GUNNER:
			return "Machine Gunner"
		Ally.AllyType.SNIPER:
			return "Sniper"
		_:
			return "Unknown"
