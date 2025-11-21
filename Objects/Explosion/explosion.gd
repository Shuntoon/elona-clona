extends Node2D
class_name Explosion

## Damage dealt to enemies in explosion radius
@export var damage: int = 10
## Radius of the explosion
@export var explosion_radius: float = 100.0
## Visual scale multiplier for the explosion animation
@export var visual_scale: float = 1.0

var vfx_parent: Node

func _ready() -> void:
	vfx_parent = get_tree().get_first_node_in_group("neutral_entities")
	
	# Defer damage area creation to avoid physics callback issues
	call_deferred("_create_damage_area")
	
	# Scale and play animation
	var anim_sprite = get_node_or_null("AnimatedSprite2D")
	if anim_sprite:
		# Apply visual scale
		if visual_scale != 1.0:
			anim_sprite.scale = Vector2(visual_scale, visual_scale)
		anim_sprite.play("default")
		# Wait for animation to finish then destroy
		await anim_sprite.animation_finished
		queue_free()
	else:
		# Fallback if no animation
		await get_tree().create_timer(0.5).timeout
		queue_free()

func _create_damage_area() -> void:
	# Create an Area2D to detect enemies
	var area = Area2D.new()
	area.collision_layer = 0
	area.collision_mask = 2  # Should match enemy hurtbox layer
	
	# Create collision shape
	var collision = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = explosion_radius
	collision.shape = circle
	
	area.add_child(collision)
	add_child(area)
	
	# Wait for physics to update
	await get_tree().physics_frame
	await get_tree().physics_frame  # Wait an extra frame to be safe
	
	# Get all overlapping areas (enemy hurtboxes)
	var overlapping_areas = area.get_overlapping_areas()
	
	# Track which enemies we've already damaged to prevent double-hits
	var damaged_enemies: Array[Enemy] = []
	
	for hurtbox_area in overlapping_areas:
		if hurtbox_area is Hurtbox and hurtbox_area.owner.is_in_group("enemy"):
			var enemy: Enemy = hurtbox_area.owner
			if enemy and not damaged_enemies.has(enemy):
				# Apply flat damage regardless of hurtbox type (no crits)
				enemy.current_health -= damage
				damaged_enemies.append(enemy)
	
	# Remove area after damage is dealt
	area.queue_free()
