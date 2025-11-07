extends Control
class_name UpgradeScreen

var game_mananger : GameManager

@onready var foundation_page: Panel = %FoundationPage
@onready var augments_page: Panel = %AugmentsPage
@onready var armory_page: Panel = %ArmoryPage
@onready var allies_page: Panel = %AlliesPage
@onready var foundation_button: Button = %FoundationButton

func _ready() -> void:
	game_mananger = get_tree().get_first_node_in_group("game_manager")

func _on_next_wave_button_pressed() -> void:
	_swipe_out()
	pass # Replace with function body.

func _bounce_in() -> void:
	position.y = position.y - 1000
	var tween := create_tween()
	tween.tween_property(self, "position:y", position.y + 1000, 1).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

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
