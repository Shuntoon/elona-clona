extends Panel
class_name AlliesPage

@onready var allies_hbox_container: HBoxContainer = %AlliesHBoxContainer
@onready var button_sound: AudioStreamPlayer = $ButtonSound

const ALLY_FILLED_PANEL_SCENE = preload("uid://w7gefcihbnk1")
const ALLY_UNFILLLED_PLANEL_SCNE = preload("uid://ufhh6su3k4gn")

func _ready() -> void:
	add_to_group("allies_page")

func play_button_sound() -> void:
	if button_sound:
		button_sound.play()

func _on_visibility_changed() -> void:
	if allies_hbox_container != null:
		populate_allies_hbox()

func populate_allies_hbox() -> void:
	# Clear existing children
	for child in allies_hbox_container.get_children():
		child.queue_free()
	
	# Add filled panels for each ally data
	for i in range(PlayerData.ally_datas.size()):
		var ally_data = PlayerData.ally_datas[i]
		var ally_filled_panel = ALLY_FILLED_PANEL_SCENE.instantiate()
		ally_filled_panel.setup_with_ally_data(ally_data, i)
		allies_hbox_container.add_child(ally_filled_panel)

	# Add empty slots to fill up to 4 total (based on actual ally count, not child count)
	var current_ally_count = PlayerData.ally_datas.size()
	if current_ally_count < 4:
		var empty_slots = 4 - current_ally_count
		for i in range(empty_slots):
			var ally_unfilled_panel = ALLY_UNFILLLED_PLANEL_SCNE.instantiate()
			
			# Calculate the slot index (0-based)
			var slot_index = current_ally_count + i
			
			# Lock the panel if slot index is >= allies_level
			if slot_index >= PlayerData.allies_level:
				ally_unfilled_panel.locked = true
			else:
				ally_unfilled_panel.locked = false

			allies_hbox_container.add_child(ally_unfilled_panel)
