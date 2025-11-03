extends Node2D
class_name Bullet

@export var speed : float = 200
@export var piercing : bool = false

var target : Vector2
var direction : Vector2

func _ready() -> void:
	# Calculate direction once and keep flying in that direction
	direction = global_position.direction_to(target)
	
	# Pass piercing value to the hitbox child
	var hitbox = get_node_or_null("Hitbox")
	if hitbox:
		hitbox.piercing = piercing

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta


func _on_hitbox_area_entered(area: Area2D) -> void:
	if area.owner.is_in_group("enemy"):
		# Only destroy bullet if not piercing
		if not piercing:
			queue_free()
	pass # Replace with function body.
