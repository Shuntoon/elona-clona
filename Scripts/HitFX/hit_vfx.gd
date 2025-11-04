extends Node2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

var is_critical: bool = false

func _ready():
	if is_critical:
		# Make it red and bigger for critical hits
		animated_sprite_2d.modulate = Color(1.0, 0.2, 0.2, 1.0)  # Red
		animated_sprite_2d.scale = Vector2(1.5, 1.5)  # 50% bigger
	
	await animated_sprite_2d.animation_finished
	queue_free()