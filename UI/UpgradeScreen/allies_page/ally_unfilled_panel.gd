extends Panel

const RIFLEMAN = preload("uid://boxv5rlsd54ii")
const SUPPORT = preload("uid://b7bpl2wwldbpr")
const MACHINE_GUNNER = preload("uid://8jm6oxcstidi")
const ROCKETEER = preload("uid://c2ad8fid6x5tb")
const SNIPER = preload("uid://brbmo3pqv8hne")

var allies_page: AlliesPage

func _ready() -> void:
	# Get reference to the AlliesPage parent
	allies_page = get_tree().get_first_node_in_group("allies_page") as AlliesPage
	if allies_page == null:
		print("Error: AlliesPage not found in the scene tree.")

func _on_rifleman_button_pressed() -> void:
	var rifleman_data_inst = RIFLEMAN.duplicate()
	PlayerData.add_ally_data(rifleman_data_inst)
	_refresh_allies_display()

func _on_support_button_pressed() -> void:
	var support_data_inst = SUPPORT.duplicate()
	PlayerData.add_ally_data(support_data_inst)
	_refresh_allies_display()

func _on_sniper_button_pressed() -> void:
	var sniper_data_inst = SNIPER.duplicate()
	PlayerData.add_ally_data(sniper_data_inst)
	_refresh_allies_display()

func _on_machine_gunner_button_pressed() -> void:
	var machine_gunner_data_inst = MACHINE_GUNNER.duplicate()
	PlayerData.add_ally_data(machine_gunner_data_inst)
	_refresh_allies_display()

func _on_machine_gunner_button_2_pressed() -> void:
	var rocketeer_data_inst = ROCKETEER.duplicate()
	PlayerData.add_ally_data(rocketeer_data_inst)
	_refresh_allies_display()

func _refresh_allies_display() -> void:
	if allies_page:
		allies_page.populate_allies_hbox()
