extends Node2D
class_name Bullet

@export var speed : float = 200
@export var piercing : bool = false
@export var explosive : bool = false
@export var explosion_damage : int = 10
@export var explosion_radius : float = 100.0

var target : Vector2
var direction : Vector2

# VFX references to pass to hitbox
var hit_enemy_vfx: PackedScene
var hit_ground_vfx: PackedScene
var explosion_scene: PackedScene

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
		# Spawn explosion if explosive
		if explosive:
			_spawn_explosion()
			# Only destroy if not piercing
			if not piercing:
				queue_free()
		# Only destroy bullet if not piercing
		elif not piercing:
			queue_free()
	else:
		# Hit something that's not an enemy (ground/wall)
		# Spawn explosion if explosive
		if explosive:
			_spawn_explosion()
		else:
			# Spawn ground hit VFX for non-explosive bullets
			if hit_ground_vfx:
				var vfx_parent = get_tree().get_first_node_in_group("neutral_entities")
				if vfx_parent:
					var vfx_inst = hit_ground_vfx.instantiate()
					vfx_inst.global_position = global_position
					vfx_parent.add_child(vfx_inst)
		
		# Always destroy bullet when hitting ground/wall
		queue_free()

func _spawn_explosion() -> void:
	if explosion_scene == null:
		return
	
	var vfx_parent = get_tree().get_first_node_in_group("neutral_entities")
	if vfx_parent:
		var explosion_inst = explosion_scene.instantiate()
		explosion_inst.global_position = global_position
		explosion_inst.damage = explosion_damage
		explosion_inst.explosion_radius = explosion_radius
		vfx_parent.add_child(explosion_inst)
