extends Area2D
class_name Hitbox

@export var destroy_instantly : bool = true
@export var piercing : bool = false
@export var damage : int = 1
@export var crit_chance: float = 0.0
@export var crit_multiplier: float = 2.0
@export var bleed_chance: float = 0.0

# VFX scenes to spawn
var hit_enemy_vfx: PackedScene
var hit_ground_vfx: PackedScene

const DAMAGE_NUMBER = preload("res://Objects/DamageNumber/damage_number.tscn")

var vfx_parent: Node
var hit_enemy: bool = false  # Track if we hit an enemy

func _on_area_entered(area: Area2D) -> void:
	if area.owner.is_in_group("enemy"):
		hit_enemy = true  # Mark that we hit an enemy
		var hurtbox : Hurtbox = area
		var enemy : Enemy = area.owner
		var is_critical = false
		var final_damage = damage
		
		# Check if it's a headshot
		if hurtbox.hurtbox_type == Hurtbox.HURTBOX_TYPE.HEAD:
			# Headshot: check for crit chance
			if randf() < crit_chance:
				final_damage = int(damage * crit_multiplier)
				is_critical = true
				print("CRITICAL HEADSHOT! Damage: ", final_damage)
			else:
				# Headshot but no crit
				final_damage = damage
				print("HEADSHOT! Damage: ", final_damage)
		else:
			# Body shot: just base damage
			final_damage = damage
		
		# Apply damage
		enemy.current_health -= final_damage
		
		# Check for bleed application
		if bleed_chance > 0.0 and randf() < bleed_chance:
			if enemy.bleed_effect:
				enemy.bleed_effect.apply_bleed_stack()
				print("Bleed applied! Chance: ", bleed_chance)
		
		# Spawn floating damage number
		_spawn_damage_number(final_damage, global_position, is_critical)
		
		# Spawn enemy hit VFX (red and bigger for headshots)
		_spawn_vfx(hit_enemy_vfx, global_position, is_critical)
		
		# Only destroy if not piercing
		if not piercing:
			await get_tree().create_timer(.1).timeout #despawn after 
			queue_free()

func _ready() -> void:
	# Get VFX parent node
	vfx_parent = get_tree().get_first_node_in_group("neutral_entities")
	
	if destroy_instantly:
		await get_tree().create_timer(.1).timeout #wait to check if we hit enemy
		# Only spawn ground VFX if we didn't hit an enemy
		if not hit_enemy:
			_spawn_vfx(hit_ground_vfx, global_position)
		queue_free()

func _spawn_vfx(vfx_scene: PackedScene, spawn_position: Vector2, is_critical: bool = false) -> void:
	if vfx_scene == null or vfx_parent == null:
		return
	
	var vfx_inst = vfx_scene.instantiate()
	vfx_inst.global_position = spawn_position
	
	# Set critical flag if the VFX has this property
	if "is_critical" in vfx_inst:
		vfx_inst.is_critical = is_critical
	
	vfx_parent.add_child(vfx_inst)

func _spawn_damage_number(damage_value: int, spawn_position: Vector2, is_critical: bool = false) -> void:
	if DAMAGE_NUMBER == null or vfx_parent == null:
		return
	
	var damage_number_inst = DAMAGE_NUMBER.instantiate()
	damage_number_inst.global_position = spawn_position + Vector2(randi_range(-20,20), randi_range(-20,-30))  # Slightly above hit position
	damage_number_inst.set_damage(damage_value, is_critical)
	vfx_parent.add_child(damage_number_inst)
