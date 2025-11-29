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
var damaged_enemies: Array[Enemy] = []  # Track which enemies we've already hit

func _on_area_entered(area: Area2D) -> void:
	if area.owner.is_in_group("enemy"):
		var hurtbox : Hurtbox = area
		var enemy : Enemy = area.owner
		
		# Skip if we've already hit this enemy
		if damaged_enemies.has(enemy):
			return
		
		damaged_enemies.append(enemy)
		hit_enemy = true  # Mark that we hit an enemy
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
		
		# Check for execute chance on low health enemies
		var augment_manager = get_tree().get_first_node_in_group("augment_manager")
		var executed = false
		if augment_manager and augment_manager.execute_chance > 0.0:
			# Check if enemy would be below threshold after this hit
			var health_after_damage = enemy.current_health - final_damage
			var health_percent = float(health_after_damage) / float(enemy.max_health)
			
			if health_percent <= augment_manager.execute_health_threshold and health_after_damage > 0:
				if randf() < augment_manager.execute_chance:
					# Execute! Set damage to kill the enemy
					final_damage = enemy.current_health
					executed = true
					print("EXECUTED! Enemy health was ", enemy.current_health, "/", enemy.max_health)
		
		# Apply damage
		enemy.current_health -= final_damage
		
		# Check for bleed application
		if bleed_chance > 0.0 and randf() < bleed_chance:
			if enemy.bleed_effect:
				enemy.bleed_effect.apply_bleed_stack()
				print("Bleed applied! Chance: ", bleed_chance)
		
		# Check for slow on hit from augments
		if augment_manager:
			#print("Augment manager found. slow_on_hit_enabled: ", augment_manager.slow_on_hit_enabled)
			if augment_manager.slow_on_hit_enabled:
				print("Applying slow to enemy with multiplier: ", augment_manager.slow_on_hit_multiplier, " for duration: ", augment_manager.slow_on_hit_duration)
				enemy.apply_slow(augment_manager.slow_on_hit_multiplier, augment_manager.slow_on_hit_duration)
		else:
			print("No augment manager found!")
		
		# Spawn floating damage number (show execute as critical)
		_spawn_damage_number(final_damage, global_position, is_critical or executed)
		
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
