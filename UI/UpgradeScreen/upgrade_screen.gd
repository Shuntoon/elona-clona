extends Control
class_name UpgradeScreen

var game_mananger : GameManager

@onready var foundation_page: Panel = %FoundationPage
@onready var augments_page: AugmentsPage = %AugmentsPage
@onready var armory_page: Panel = %ArmoryPage
@onready var allies_page: Panel = %AlliesPage
@onready var foundation_button: Button = %FoundationButton

@onready var base_health_label: Label = %BaseHealthLabel
@onready var gold_label: Label = %GoldLabel

func _ready() -> void:
	game_mananger = get_tree().get_first_node_in_group("game_manager")
	
	if game_mananger:
		var wave_manager = get_tree().get_first_node_in_group("wave_manager")
		if wave_manager:
			wave_manager.wave_complete.connect(_on_wave_complete)
			print("UpgradeScreen connected to wave_complete signal")

func _process(delta: float) -> void:
	update_stats()

func _on_next_wave_button_pressed() -> void:
	_swipe_out()
	game_mananger.start_new_day.emit()
	pass # Replace with function body.

func _bounce_in() -> void:
	position.y = position.y - 1000
	var tween := create_tween()
	tween.tween_property(self, "position:y", position.y + 1000, 1).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	
	foundation_button.grab_focus()

func _swipe_out() -> void:
	var tween := create_tween()
	tween.tween_property(self, "position:y", position.y - 1000, 1).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func hide_pages() -> void:
	foundation_page.hide()
	augments_page.hide()
	armory_page.hide()
	allies_page.hide()

func _on_foundation_button_pressed() -> void:
	hide_pages()
	foundation_page.show()
	pass # Replace with function body.

func _on_augments_button_pressed() -> void:
	hide_pages()
	augments_page.show()
	pass # Replace with function body.

func _on_armory_button_pressed() -> void:
	hide_pages()
	armory_page.show()
	pass # Replace with function body.

func _on_allies_button_pressed() -> void:
	hide_pages()
	allies_page.show()
	pass # Replace with function body.

func update_stats() -> void:
	gold_label.text = "Gold: " + str(PlayerData.gold)
	base_health_label.text = "Base Health: %s / %s" % [str(game_mananger.current_health), str(game_mananger.max_health)]

func _on_wave_complete(wave_number: int) -> void:
	print("Rerolling augments for wave ", wave_number + 1)
	if augments_page:
		augments_page.populate_augment_hbox()	
