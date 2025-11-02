extends Control
class_name PlayerHUD

var game_manager : GameManager

@onready var hp_progress_bar: ProgressBar = %HPProgressBar

func _ready() -> void:
	game_manager = get_tree().get_first_node_in_group("game_manager")
	hp_progress_bar.max_value = game_manager.max_health
	
	
func _process(delta: float) -> void:
	if game_manager != null:
		hp_progress_bar.value = game_manager.current_health
