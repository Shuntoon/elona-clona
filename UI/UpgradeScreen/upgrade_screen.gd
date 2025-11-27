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

func _show_page_animated(page: Control) -> void:
	hide_pages()
	page.show()
	# Slide in from left with fade
	page.modulate.a = 0.0
	page.position.x = -30
	var tween = create_tween().set_parallel(true)
	tween.tween_property(page, "modulate:a", 1.0, 0.2).set_ease(Tween.EASE_OUT)
	tween.tween_property(page, "position:x", 0.0, 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func _on_foundation_button_pressed() -> void:
	_show_page_animated(foundation_page)

func _on_augments_button_pressed() -> void:
	_show_page_animated(augments_page)

func _on_armory_button_pressed() -> void:
	_show_page_animated(armory_page)

func _on_allies_button_pressed() -> void:
	_show_page_animated(allies_page)

func update_stats() -> void:
	gold_label.text = "Gold: " + str(PlayerData.gold)
	base_health_label.text = "Base Health: %s / %s" % [str(game_mananger.current_health), str(game_mananger.max_health)]

func _on_wave_complete(wave_number: int) -> void:
	print("Rerolling augments for wave ", wave_number + 1)
	if augments_page:
		augments_page.populate_augment_hbox()	
