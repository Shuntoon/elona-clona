extends Node2D
class_name MouseShooter

const HITBOX = preload("uid://bg6uxodad3g5f")

var neutral_entities

func _ready() -> void:
	neutral_entities = get_tree().get_first_node_in_group("neutral_entities")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("shoot"):
		var hitbox_inst : Hitbox = HITBOX.instantiate()
		hitbox_inst.global_position = get_global_mouse_position()
		if neutral_entities != null:
			neutral_entities.add_child(hitbox_inst)
		else:
			print("no entities")
