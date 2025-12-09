extends Node2D
class_name Bullet

@export var speed : float = 200
@export var bullet_texture : Texture2D
@export var rocket_texture : Texture2D
@export var piercing : bool = false
@export var explosive : bool = false
@export var explosion_damage : int = 12
@export var explosion_radius : float = 110.0
@export var explosion_visual_scale : float = 1.0
@export var bullet_visual_scale: Vector2 = Vector2(1, 1)
@export var rocket_visual_scale: Vector2 = Vector2(1, 1)

var target : Vector2
var direction : Vector2

# VFX references to pass to hitbox
var hit_enemy_vfx: PackedScene
var hit_ground_vfx: PackedScene
var explosion_scene: PackedScene

func _ready() -> void:
	# Calculate direction once and keep flying in that direction
	direction = global_position.direction_to(target)

	if explosive:
		# Rotate rocket to face target
		scale = Vector2(1.75, 1.75)
		rotation = direction.angle() + deg_to_rad(90)
	else:
		rotation = direction.angle()
	
	# Set the appropriate texture based on projectile type
	var sprite = get_node_or_null("BulletSprite")
	if sprite:
		if explosive and rocket_texture:
			sprite.texture = rocket_texture
		elif bullet_texture:
			sprite.texture = bullet_texture

		# Apply visual scale provided by the instanced bullet (from WeaponData)
		if explosive:
			sprite.scale = rocket_visual_scale
		else:
			sprite.scale = bullet_visual_scale
	
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
		explosion_inst.visual_scale = explosion_visual_scale
		vfx_parent.add_child(explosion_inst)
