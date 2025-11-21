extends Area2D
class_name Hurtbox

enum HURTBOX_TYPE {
	BODY,
	HEAD
}

@export var hurtbox_type : HURTBOX_TYPE

@export var size : Vector2 = Vector2(16, 16)
@export var pos : Vector2 = Vector2(0, 0)