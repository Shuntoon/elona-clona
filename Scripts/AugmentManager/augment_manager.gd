extends Node
class_name AugmentManager

var game_manager: GameManager
var mouse_shooter: MouseShooter

# Add to group in _enter_tree so other nodes can find it
func _enter_tree() -> void:
	add_to_group("augment_manager")

func _ready() -> void:
	game_manager = get_tree().get_first_node_in_group("game_manager")
	mouse_shooter = get_tree().get_first_node_in_group("mouse_shooter")

# Store base values to calculate modifiers properly
var base_max_health: int = 50
var base_damage_multiplier: float = 1.0
var base_fire_rate_multiplier: float = 1.0
var base_movement_speed_multiplier: float = 1.0
var base_reload_speed_multiplier: float = 1.0
var ally_damage_multiplier: float = 1.0
var ally_fire_rate_multiplier: float = 1.0
var enemy_death_explosion_chance: float = 0.0
var explosion_damage_multiplier: float = 1.0
var explosion_radius_multiplier: float = 1.0
var laser_of_death_stacks: int = 0
var laser_of_death_instance: LaserOfDeath = null
var gold_gain_multiplier: float = 1.0
var slow_on_hit_enabled: bool = false
var slow_on_hit_multiplier: float = 0.5  # 50% speed by default
var slow_on_hit_duration: float = 3.0
var ammo_refund_chance: float = 0.0
var cooldown_reduction_on_kill_chance: float = 0.0
var cooldown_reduction_on_kill_amount: float = 0.0
var first_shot_damage_multiplier: float = 0.0

## Apply all augments from PlayerData
## Call this at the start of a new day to recalculate all bonuses
func apply_all_augments() -> void:
	print("=== Applying Augments ===")
	
	# Reset multipliers to base values
	base_damage_multiplier = 1.0
	base_fire_rate_multiplier = 1.0
	base_movement_speed_multiplier = 1.0
	base_reload_speed_multiplier = 1.0
	ally_damage_multiplier = 1.0
	ally_fire_rate_multiplier = 1.0
	enemy_death_explosion_chance = 0.0
	explosion_damage_multiplier = 1.0
	explosion_radius_multiplier = 1.0
	laser_of_death_stacks = 0
	gold_gain_multiplier = 1.0
	slow_on_hit_enabled = false
	ammo_refund_chance = 0.0
	cooldown_reduction_on_kill_chance = 0.0
	cooldown_reduction_on_kill_amount = 0.0
	first_shot_damage_multiplier = 0.0
	
	# Apply each stat augment
	for augment in PlayerData.augments:
		apply_augment(augment)
	
	# Apply ability augments
	_apply_ability_augments()

	# Update allies after applying all augments
	_update_allies_stats()
	
	print("Applied ", PlayerData.augments.size(), " stat augments and ", PlayerData.ability_augments.size(), " ability augments")

## Apply a single augment's effects
func apply_augment(augment: AugmentData) -> void:
	# Apply primary effect
	_apply_augment_effect(augment.augment_type, augment.value)
	
	# Apply secondary effect if it exists
	if augment.has_secondary_effect:
		_apply_augment_effect(augment.secondary_augment_type, augment.secondary_value)
		print("Applied augment: ", augment.name, " (primary: ", augment.value, ", secondary: ", augment.secondary_value, ")")

	# Apply tertiary effect if it exists
	if augment.has_tertiary_effect:
		_apply_augment_effect(augment.tertiary_augment_type, augment.tertiary_value)
		print("Applied augment tertiary: ", augment.tertiary_value)
	
	# Apply quaternary effect if it exists
	if augment.has_quaternary_effect:
		_apply_augment_effect(augment.quaternary_augment_type, augment.quaternary_value)
		print("Applied augment quaternary: ", augment.quaternary_value)
	
	# Apply quinary effect if it exists
	if augment.has_quinary_effect:
		_apply_augment_effect(augment.quinary_augment_type, augment.quinary_value)
		print("Applied augment quinary: ", augment.quinary_value)
	else:
		if not augment.has_secondary_effect:
			print("Applied augment: ", augment.name, " (", augment.value, ")")

## Apply a specific augment effect
func _apply_augment_effect(augment_type: AugmentData.AugmentType, value: float) -> void:
	print("_apply_augment_effect called with type: ", augment_type, " (SLOW_ON_HIT = ", AugmentData.AugmentType.SLOW_ON_HIT, "), value: ", value)
	match augment_type:
		AugmentData.AugmentType.MAX_HEALTH:
			_apply_max_health(value)
		AugmentData.AugmentType.DAMAGE_MULTIPLIER:
			_apply_damage_multiplier(value)
		AugmentData.AugmentType.FIRE_RATE:
			_apply_fire_rate(value)
		AugmentData.AugmentType.CRIT_CHANCE:
			_apply_crit_chance(value)
		AugmentData.AugmentType.CRIT_MULTIPLIER:
			_apply_crit_multiplier(value)
		AugmentData.AugmentType.MOVEMENT_SPEED:
			_apply_movement_speed(value)
		AugmentData.AugmentType.RELOAD_SPEED:
			_apply_reload_speed(value)
		AugmentData.AugmentType.MAGAZINE_SIZE:
			_apply_magazine_size(value)
		AugmentData.AugmentType.ACCURACY:
			_apply_accuracy(value)
		AugmentData.AugmentType.PROJECTILE_PIERCING:
			_apply_projectile_piercing(value > 0)
		AugmentData.AugmentType.EXPLOSIVE_ROCKETS:
			_apply_explosive_rockets(value > 0)
		AugmentData.AugmentType.BLEED_CHANCE:
			_apply_bleed_chance(value)
		AugmentData.AugmentType.ALLY_DAMAGE_MULTIPLIER:
			_apply_ally_damage_multiplier(value)
		AugmentData.AugmentType.ALLY_FIRE_RATE:
			_apply_ally_fire_rate(value)
		AugmentData.AugmentType.ENEMY_DEATH_EXPLOSION_CHANCE:
			_apply_enemy_death_explosion_chance(value)
		AugmentData.AugmentType.EXPLOSION_DAMAGE_MULTIPLIER:
			_apply_explosion_damage_multiplier(value)
		AugmentData.AugmentType.EXPLOSION_RADIUS_MULTIPLIER:
			_apply_explosion_radius_multiplier(value)
		AugmentData.AugmentType.LASER_OF_DEATH:
			_apply_laser_of_death(value)
		AugmentData.AugmentType.GOLD_GAIN_MULTIPLIER:
			_apply_gold_gain_multiplier(value)
		AugmentData.AugmentType.SLOW_ON_HIT:
			_apply_slow_on_hit(value)
		AugmentData.AugmentType.BURST_COUNT:
			_apply_burst_count(value)
		AugmentData.AugmentType.AMMO_REFUND_CHANCE:
			_apply_ammo_refund_chance(value)
		AugmentData.AugmentType.COOLDOWN_REDUCTION_ON_KILL:
			_apply_cooldown_reduction_on_kill(value)
		AugmentData.AugmentType.FIRST_SHOT_DAMAGE:
			_apply_first_shot_damage(value)
		AugmentData.AugmentType.ABILITY:
			# Abilities are handled separately in _apply_ability_augments
			pass

# === Augment Application Functions ===

func _apply_max_health(value: float) -> void:
	if game_manager:
		var old_max = game_manager.max_health
		game_manager.max_health = base_max_health + int(value)
		# Scale current health proportionally
		if old_max > 0:
			var health_percent = float(game_manager.current_health) / float(old_max)
			game_manager.current_health = int(game_manager.max_health * health_percent)

func _apply_damage_multiplier(value: float) -> void:
	base_damage_multiplier += value
	_update_weapon_stats()

func _apply_fire_rate(value: float) -> void:
	base_fire_rate_multiplier += value
	_update_weapon_stats()

func _apply_crit_chance(value: float) -> void:
	if mouse_shooter and mouse_shooter.weapon_data:
		# Apply to both weapon data and current stats
		mouse_shooter.weapon_data.crit_chance = clamp(mouse_shooter.weapon_data.crit_chance + value, 0.0, 1.0)
		mouse_shooter.crit_chance = mouse_shooter.weapon_data.crit_chance

func _apply_crit_multiplier(value: float) -> void:
	if mouse_shooter and mouse_shooter.weapon_data:
		mouse_shooter.weapon_data.crit_multiplier += value
		mouse_shooter.crit_multiplier = mouse_shooter.weapon_data.crit_multiplier

func _apply_movement_speed(value: float) -> void:
	base_movement_speed_multiplier += value
	var player = get_tree().get_first_node_in_group("player")
	if player and "speed" in player:
		# Assuming player has a base_speed property, or we set it
		if not "base_speed" in player:
			player.set_meta("base_speed", player.speed)
		var base_speed = player.get_meta("base_speed")
		player.speed = base_speed * base_movement_speed_multiplier

func _apply_reload_speed(value: float) -> void:
	base_reload_speed_multiplier += value
	_update_weapon_stats()

func _apply_magazine_size(value: float) -> void:
	if mouse_shooter and mouse_shooter.weapon_data:
		mouse_shooter.weapon_data.magazine_size += int(value)
		mouse_shooter.magazine_size = mouse_shooter.weapon_data.magazine_size

func _apply_accuracy(value: float) -> void:
	if mouse_shooter and mouse_shooter.weapon_data:
		mouse_shooter.weapon_data.accuracy = clamp(mouse_shooter.weapon_data.accuracy + value, 0.0, 1.0)
		mouse_shooter.accuracy = mouse_shooter.weapon_data.accuracy

func _apply_projectile_piercing(enabled: bool) -> void:
	if mouse_shooter and mouse_shooter.weapon_data:
		mouse_shooter.weapon_data.projectile_piercing = enabled
		mouse_shooter.projectile_piercing = enabled

func _apply_explosive_rockets(enabled: bool) -> void:
	if mouse_shooter and mouse_shooter.weapon_data:
		mouse_shooter.weapon_data.explosive_rockets = enabled
		mouse_shooter.explosive_rockets = enabled

func _apply_bleed_chance(value: float) -> void:
	if mouse_shooter and mouse_shooter.weapon_data:
		mouse_shooter.weapon_data.bleed_chance = clamp(mouse_shooter.weapon_data.bleed_chance + value, 0.0, 1.0)
		mouse_shooter.bleed_chance = mouse_shooter.weapon_data.bleed_chance

func _apply_enemy_death_explosion_chance(value: float) -> void:
	# Accumulate chance across stacks; clamp at 100%
	enemy_death_explosion_chance = clamp(enemy_death_explosion_chance + value, 0.0, 1.0)

func get_enemy_death_explosion_chance() -> float:
	return enemy_death_explosion_chance

func _apply_explosion_damage_multiplier(value: float) -> void:
	explosion_damage_multiplier += value

func _apply_explosion_radius_multiplier(value: float) -> void:
	explosion_radius_multiplier += value

func _apply_laser_of_death(value: float) -> void:
	laser_of_death_stacks += int(value)
	
	# First stack: spawn the laser
	if laser_of_death_stacks == 1:
		_spawn_laser_of_death()
	# Subsequent stacks: upgrade the laser
	elif laser_of_death_instance:
		_upgrade_laser_of_death()

func _spawn_laser_of_death() -> void:
	const LASER_SCENE = preload("res://Objects/LaserOfDeath/laser_of_death.tscn")
	
	if not mouse_shooter:
		print("Warning: MouseShooter not found for laser spawn")
		return
	
	laser_of_death_instance = LASER_SCENE.instantiate()
	mouse_shooter.add_child(laser_of_death_instance)
	print("Laser of Death spawned!")

func _upgrade_laser_of_death() -> void:
	if not laser_of_death_instance:
		return
	
	# Each stack increases damage by 3 and follow speed by 2
	laser_of_death_instance.damage_per_tick += 3
	laser_of_death_instance.follow_speed += 2.0
	print("Laser of Death upgraded! Damage: ", laser_of_death_instance.damage_per_tick, ", Follow Speed: ", laser_of_death_instance.follow_speed)

func _apply_gold_gain_multiplier(value: float) -> void:
	gold_gain_multiplier += value
	print("Gold gain multiplier: ", gold_gain_multiplier)

func _apply_slow_on_hit(value: float) -> void:
	slow_on_hit_enabled = true
	slow_on_hit_multiplier = value
	print("Slow on hit enabled! Speed multiplier: ", slow_on_hit_multiplier)

func _apply_burst_count(value: float) -> void:
	if mouse_shooter and mouse_shooter.weapon_data:
		mouse_shooter.weapon_data.burst_count += int(value)
		mouse_shooter.burst_count = mouse_shooter.weapon_data.burst_count
		print("Burst count increased to: ", mouse_shooter.burst_count)

func _apply_ammo_refund_chance(value: float) -> void:
	ammo_refund_chance = clamp(ammo_refund_chance + value, 0.0, 1.0)
	print("Ammo refund chance: ", ammo_refund_chance * 100, "%")

func _apply_cooldown_reduction_on_kill(value: float) -> void:
	# Value format: chance stored in first decimal place, amount in second
	# e.g., 0.52 = 50% chance (0.5) to reduce by 2 seconds (2)
	cooldown_reduction_on_kill_chance = 0.5  # 50% chance
	cooldown_reduction_on_kill_amount = value  # Reduction amount in seconds
	print("Cooldown reduction on kill: ", cooldown_reduction_on_kill_chance * 100, "% chance to reduce by ", cooldown_reduction_on_kill_amount, "s")

func trigger_cooldown_reduction_on_kill() -> void:
	if cooldown_reduction_on_kill_chance <= 0.0:
		return
	
	if randf() < cooldown_reduction_on_kill_chance:
		var ability_manager = get_tree().get_first_node_in_group("ability_manager")
		if ability_manager:
			for ability in ability_manager.abilities:
				if ability.is_on_cooldown:
					ability.cooldown_remaining = max(0.0, ability.cooldown_remaining - cooldown_reduction_on_kill_amount)
					if ability.cooldown_remaining <= 0.0:
						ability.is_on_cooldown = false
						ability.cooldown_finished.emit()
			print("Cooldown reduction triggered! Reduced all ability cooldowns by ", cooldown_reduction_on_kill_amount, "s")

func _apply_first_shot_damage(value: float) -> void:
	first_shot_damage_multiplier += value
	print("First shot damage bonus: +", first_shot_damage_multiplier * 100, "%")

func _apply_ally_damage_multiplier(value: float) -> void:
	ally_damage_multiplier += value

func _apply_ally_fire_rate(value: float) -> void:
	ally_fire_rate_multiplier += value

func _update_allies_stats() -> void:
	var allies = get_tree().get_nodes_in_group("allies")
	for node in allies:
		# Only operate on Ally instances to avoid invalid property access
		if not (node is Ally):
			continue
		var ally: Ally = node

		# Ensure base metas exist
		if not ally.has_meta("base_ally_damage"):
			ally.set_meta("base_ally_damage", ally.bullet_damage)
		if not ally.has_meta("base_ally_fire_rate"):
			ally.set_meta("base_ally_fire_rate", ally.fire_rate)

		var base_ally_damage: int = int(ally.get_meta("base_ally_damage"))
		var base_ally_fire_rate: float = float(ally.get_meta("base_ally_fire_rate"))

		ally.bullet_damage = int(base_ally_damage * ally_damage_multiplier)
		ally.fire_rate = base_ally_fire_rate * ally_fire_rate_multiplier
		# Recalculate internal timing used by ally firing loop
		ally.time_between_shots = 60.0 / max(1.0, ally.fire_rate)

		# Optional: log once per ally type
		# print("Updated ally stats:", ally.ally_name, ally.bullet_damage, ally.fire_rate)

## Helper function to update weapon stats that use multipliers
## Call this after equipping a weapon to apply augment bonuses
func _update_weapon_stats() -> void:
	if not mouse_shooter or not mouse_shooter.weapon_data:
		return
	
	# Store base values if not already stored
	if not mouse_shooter.weapon_data.has_meta("base_damage"):
		mouse_shooter.weapon_data.set_meta("base_damage", mouse_shooter.weapon_data.bullet_damage)
	if not mouse_shooter.weapon_data.has_meta("base_fire_rate"):
		mouse_shooter.weapon_data.set_meta("base_fire_rate", mouse_shooter.weapon_data.fire_rate)
	if not mouse_shooter.weapon_data.has_meta("base_reload_time"):
		mouse_shooter.weapon_data.set_meta("base_reload_time", mouse_shooter.weapon_data.reload_time)
	if not mouse_shooter.weapon_data.has_meta("base_explosion_damage"):
		mouse_shooter.weapon_data.set_meta("base_explosion_damage", mouse_shooter.weapon_data.explosion_damage)
	if not mouse_shooter.weapon_data.has_meta("base_explosion_radius"):
		mouse_shooter.weapon_data.set_meta("base_explosion_radius", mouse_shooter.weapon_data.explosion_radius)
	
	# Get base values
	var base_damage = mouse_shooter.weapon_data.get_meta("base_damage")
	var base_fire_rate = mouse_shooter.weapon_data.get_meta("base_fire_rate")
	var base_reload_time = mouse_shooter.weapon_data.get_meta("base_reload_time")
	var base_explosion_damage = mouse_shooter.weapon_data.get_meta("base_explosion_damage")
	var base_explosion_radius = mouse_shooter.weapon_data.get_meta("base_explosion_radius")
	
	# Apply damage multiplier
	mouse_shooter.weapon_data.bullet_damage = int(base_damage * base_damage_multiplier)
	mouse_shooter.bullet_damage = mouse_shooter.weapon_data.bullet_damage
	
	# Apply fire rate multiplier
	mouse_shooter.weapon_data.fire_rate = base_fire_rate * base_fire_rate_multiplier
	mouse_shooter.fire_rate = mouse_shooter.weapon_data.fire_rate
	mouse_shooter.time_between_shots = 60.0 / mouse_shooter.fire_rate
	
	# Apply reload speed multiplier
	mouse_shooter.weapon_data.reload_time = base_reload_time * base_reload_speed_multiplier
	mouse_shooter.reload_time = mouse_shooter.weapon_data.reload_time

	# Apply explosion multipliers
	mouse_shooter.weapon_data.explosion_damage = int(base_explosion_damage * explosion_damage_multiplier)
	mouse_shooter.explosion_damage = mouse_shooter.weapon_data.explosion_damage
	mouse_shooter.weapon_data.explosion_radius = base_explosion_radius * explosion_radius_multiplier
	mouse_shooter.explosion_radius = mouse_shooter.weapon_data.explosion_radius
	
	print("Updated weapon stats - Reload time: ", mouse_shooter.reload_time, " (base: ", base_reload_time, ", multiplier: ", base_reload_speed_multiplier, ")")

## Apply ability augments by adding them to the AbilityManager
func _apply_ability_augments() -> void:
	var ability_manager = get_tree().get_first_node_in_group("ability_manager")
	if not ability_manager:
		print("Warning: AbilityManager not found!")
		return
	
	# Clear existing augment-granted abilities (keep only base abilities)
	_clear_augment_abilities(ability_manager)
	
	# Add each ability augment
	for augment in PlayerData.ability_augments:
		if augment.augment_type == AugmentData.AugmentType.ABILITY and augment.ability_script:
			# Create a new Node and attach the ability script
			var ability_node = Node.new()
			ability_node.set_script(augment.ability_script)
			ability_node.set_meta("from_augment", true)  # Mark as augment-granted
			ability_manager.add_child(ability_node)
			ability_manager.abilities.append(ability_node)
			print("Added ability from augment: ", augment.name)

## Clear abilities that were granted by augments
func _clear_augment_abilities(ability_manager: Node) -> void:
	var abilities_to_remove = []
	
	# Find all augment-granted abilities
	for ability in ability_manager.abilities:
		if ability.has_meta("from_augment") and ability.get_meta("from_augment"):
			abilities_to_remove.append(ability)
	
	# Remove them
	for ability in abilities_to_remove:
		ability_manager.abilities.erase(ability)
		ability.queue_free()
		print("Removed augment ability: ", ability.name)
