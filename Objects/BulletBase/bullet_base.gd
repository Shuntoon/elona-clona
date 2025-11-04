extends Node2D
class_name Bullet

@export var speed : float = 200
@export var piercing : bool = false

var target : Vector2
var direction : Vector2

# VFX references to pass to hitbox
var hit_enemy_vfx: PackedScene
var hit_ground_vfx: PackedScene

func _ready() -> void:
	# Calculate direction once and keep flying in that direction
	direction = global_position.direction_to(target)
	rotation = direction.angle()
	
	# Pass piercing value and VFX to the hitbox child
	var hitbox = get_node_or_null("Hitbox")
	if hitbox:
		hitbox.piercing = piercing
		hitbox.hit_enemy_vfx = hit_enemy_vfx
		hitbox.hit_ground_vfx = hit_ground_vfx

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta


func _on_hitbox_area_entered(area: Area2D) -> void:
	if area.owner.is_in_group("enemy"):
		# Only destroy bullet if not piercing
		if not piercing:
			queue_free()
	else:
		# Hit something that's not an enemy (ground/wall)
		# Spawn ground hit VFX
		if hit_ground_vfx:
			var vfx_parent = get_tree().get_first_node_in_group("neutral_entities")
			if vfx_parent:
				var vfx_inst = hit_ground_vfx.instantiate()
				vfx_inst.global_position = global_position
				vfx_parent.add_child(vfx_inst)
		
		# Always destroy bullet when hitting ground/wall
		queue_free()
