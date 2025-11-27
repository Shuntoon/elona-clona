extends Panel
class_name AllyFilledPanel

@onready var name_label: Label = %NameLabel
@onready var portrait_texture: TextureRect = %PortraitTexture
@onready var info_label_vbox_container: VBoxContainer = %InfoLabelVBoxContainer

var ally_data: AllyData

func setup_with_ally_data(data: AllyData) -> void:
	ally_data = data
	# Wait for ready if not already
	if not is_node_ready():
		await ready
	_update_display()

func _update_display() -> void:
	if not ally_data:
		return
	
	# Set the name
	name_label.text = ally_data.ally_name
	
	# Get ally type as string
	var ally_type_text = _get_ally_type_string(ally_data.ally_type)
	
	# Update the info labels
	var labels = info_label_vbox_container.get_children()
	if labels.size() >= 4:
		labels[0].text = "Type: %s" % ally_type_text
		labels[1].text = "Firerate: %d" % int(ally_data.fire_rate)
		labels[2].text = "Damage: %d" % ally_data.bullet_damage
		labels[3].text = "Accuracy: %d%%" % int(ally_data.accuracy * 100)

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
