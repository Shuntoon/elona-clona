extends Node2D
class_name MouseShooter

const HITBOX = preload("uid://bg6uxodad3g5f")

## Accuracy value (0-1). Higher values = more accurate. 1 = perfect accuracy, 0 = maximum spread
@export_range(0.0, 1.0) var accuracy: float = 1.0
## Maximum offset distance in pixels when accuracy is 0
@export var max_spread: float = 50.0

var neutral_entities

func _ready() -> void:
	neutral_entities = get_tree().get_first_node_in_group("neutral_entities")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("shoot"):
		var hitbox_inst : Hitbox = HITBOX.instantiate()
		hitbox_inst.global_position = get_global_mouse_position() + _calculate_accuracy_offset()
		if neutral_entities != null:
			neutral_entities.add_child(hitbox_inst)
		else:
			print("no entities")

## Calculates a random offset based on accuracy value
func _calculate_accuracy_offset() -> Vector2:
	# Invert accuracy so 0 accuracy = max spread, 1 accuracy = no spread
	var spread = (1.0 - accuracy) * max_spread
	
	# Generate random offset within a circle
	var random_angle = randf() * TAU  # TAU = 2 * PI
	var random_distance = randf() * spread
	
	return Vector2(
		cos(random_angle) * random_distance,
		sin(random_angle) * random_distance
	)
