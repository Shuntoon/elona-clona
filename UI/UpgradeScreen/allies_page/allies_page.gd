extends Panel
class_name AlliesPage

@onready var allies_hbox_container: HBoxContainer = %AlliesHBoxContainer

const ALLY_FILLED_PANEL_SCENE = preload("uid://w7gefcihbnk1")
const ALLY_UNFILLLED_PLANEL_SCNE = preload("uid://ufhh6su3k4gn")

func _ready() -> void:
	populate_allies_hbox()

func populate_allies_hbox() -> void:
	# Clear existing children
	for child in allies_hbox_container.get_children():
		child.queue_free()
	
	# Add filled panels for each ally data
	for ally_data in PlayerData.ally_datas:
		var ally_filled_panel = ALLY_FILLED_PANEL_SCENE.instantiate()
		#ally_filled_panel.setup_with_ally_data(ally_data)
		allies_hbox_container.add_child(ally_filled_panel)

	# Add empty slots to fill up to 3 total (based on actual ally count, not child count)
	var current_ally_count = PlayerData.ally_datas.size()
	if current_ally_count < 3:
		var empty_slots = 3 - current_ally_count
		for i in range(empty_slots):
			var ally_unfilled_panel = ALLY_UNFILLLED_PLANEL_SCNE.instantiate()
			allies_hbox_container.add_child(ally_unfilled_panel)
