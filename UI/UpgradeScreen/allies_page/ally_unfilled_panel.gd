extends Panel

const RIFLEMAN = preload("uid://boxv5rlsd54ii")
const SUPPORT = preload("uid://b7bpl2wwldbpr")
const MACHINE_GUNNER = preload("uid://8jm6oxcstidi")
const ROCKETEER = preload("uid://c2ad8fid6x5tb")
const SNIPER = preload("uid://brbmo3pqv8hne")

var allies_page: AlliesPage

@export var locked : bool = true

# Prices for each ally option
@export var rifleman_price: int = 200
@export var support_price: int = 300
@export var machine_gunner_price: int = 400
@export var sniper_price: int = 500
@export var rocketeer_price: int = 750

@onready var rifleman_button: Button = %RiflemanButton
@onready var support_button: Button = %SupportButton
@onready var machine_gunner_button: Button = %MachineGunnerButton
@onready var sniper_button: Button = %SniperButton
@onready var machine_gunner_button_2: Button = %MachineGunnerButton2

@onready var locked_panel: Panel = %LockedPanel

func _ready() -> void:
	if locked:
		locked_panel.show()
	else:
		locked_panel.hide()

	# Get reference to the AlliesPage parent
	allies_page = get_tree().get_first_node_in_group("allies_page") as AlliesPage
	if allies_page == null:
		print("Error: AlliesPage not found in the scene tree.")

	# Initial UI update
	_update_buttons()
	set_process(true)

func _process(_delta: float) -> void:
	_update_buttons()

func _update_buttons() -> void:
	# Update button text and disabled state based on PlayerData.gold and locked
	if rifleman_button:
		rifleman_button.text = "Gunner ($%d)" % rifleman_price
		rifleman_button.disabled = locked or PlayerData.gold < rifleman_price
	else:
		print("Warning: rifleman_button is null in AllyUnfilledPanel")

	if support_button:
		support_button.text = "Support ($%d)" % support_price
		support_button.disabled = locked or PlayerData.gold < support_price
	else:
		print("Warning: support_button is null in AllyUnfilledPanel")

	if machine_gunner_button:
		machine_gunner_button.text = "Machine Gunner ($%d)" % machine_gunner_price
		machine_gunner_button.disabled = locked or PlayerData.gold < machine_gunner_price
	else:
		print("Warning: machine_gunner_button is null in AllyUnfilledPanel")

	if sniper_button:
		sniper_button.text = "Sniper ($%d)" % sniper_price
		sniper_button.disabled = locked or PlayerData.gold < sniper_price
	else:
		print("Warning: sniper_button is null in AllyUnfilledPanel")

	if machine_gunner_button_2:
		machine_gunner_button_2.text = "Rocketeer ($%d)" % rocketeer_price
		machine_gunner_button_2.disabled = locked or PlayerData.gold < rocketeer_price
	else:
		print("Warning: machine_gunner_button_2 is null in AllyUnfilledPanel")

func _on_rifleman_button_pressed() -> void:
	if allies_page:
		allies_page.play_button_sound()
	# Purchase if enough gold
	if PlayerData.gold >= rifleman_price:
		PlayerData.gold -= rifleman_price
		var rifleman_data_inst = RIFLEMAN.duplicate()
		PlayerData.add_ally_data(rifleman_data_inst)
		_refresh_allies_display()

func _on_support_button_pressed() -> void:
	if allies_page:
		allies_page.play_button_sound()
	if PlayerData.gold >= support_price:
		PlayerData.gold -= support_price
		var support_data_inst = SUPPORT.duplicate()
		PlayerData.add_ally_data(support_data_inst)
		_refresh_allies_display()

func _on_sniper_button_pressed() -> void:
	if allies_page:
		allies_page.play_button_sound()
	if PlayerData.gold >= sniper_price:
		PlayerData.gold -= sniper_price
		var sniper_data_inst = SNIPER.duplicate()
		PlayerData.add_ally_data(sniper_data_inst)
		_refresh_allies_display()

func _on_machine_gunner_button_pressed() -> void:
	if allies_page:
		allies_page.play_button_sound()
	if PlayerData.gold >= machine_gunner_price:
		PlayerData.gold -= machine_gunner_price
		var machine_gunner_data_inst = MACHINE_GUNNER.duplicate()
		PlayerData.add_ally_data(machine_gunner_data_inst)
		_refresh_allies_display()

func _on_machine_gunner_button_2_pressed() -> void:
	if allies_page:
		allies_page.play_button_sound()
	if PlayerData.gold >= rocketeer_price:
		PlayerData.gold -= rocketeer_price
		var rocketeer_data_inst = ROCKETEER.duplicate()
		PlayerData.add_ally_data(rocketeer_data_inst)
		_refresh_allies_display()

func _refresh_allies_display() -> void:
	if allies_page:
		allies_page.populate_allies_hbox()
