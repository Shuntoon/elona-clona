extends Panel
class_name FoundationPage

var game_manager : GameManager

func _ready() -> void:
	game_manager = get_tree().get_first_node_in_group("game_manager")


func _on_regain_health_button_pressed() -> void:
	game_manager.current_health += 50
	pass # Replace with function body.



func _on_upgrade_base_health_button_pressed() -> void:
	game_manager.max_health += 50
	game_manager.current_health += 50
	pass # Replace with function body.
