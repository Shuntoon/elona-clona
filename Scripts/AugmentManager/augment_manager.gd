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

## Apply all augments from PlayerData
## Call this at the start of a new day to recalculate all bonuses
func apply_all_augments() -> void:
	print("=== Applying Augments ===")
	
	# Reset multipliers to base values
	base_damage_multiplier = 1.0
	base_fire_rate_multiplier = 1.0
	base_movement_speed_multiplier = 1.0
	base_reload_speed_multiplier = 1.0
	
	# Apply each stat augment
	for augment in PlayerData.augments:
		apply_augment(augment)
	
	# Apply ability augments
	_apply_ability_augments()
	
	print("Applied ", PlayerData.augments.size(), " stat augments and ", PlayerData.ability_augments.size(), " ability augments")

## Apply a single augment's effects
func apply_augment(augment: AugmentData) -> void:
	match augment.augment_type:
		AugmentData.AugmentType.MAX_HEALTH:
			_apply_max_health(augment.value)
		AugmentData.AugmentType.DAMAGE_MULTIPLIER:
			_apply_damage_multiplier(augment.value)
		AugmentData.AugmentType.FIRE_RATE:
			_apply_fire_rate(augment.value)
		AugmentData.AugmentType.CRIT_CHANCE:
			_apply_crit_chance(augment.value)
		AugmentData.AugmentType.CRIT_MULTIPLIER:
			_apply_crit_multiplier(augment.value)
		AugmentData.AugmentType.MOVEMENT_SPEED:
			_apply_movement_speed(augment.value)
		AugmentData.AugmentType.RELOAD_SPEED:
			_apply_reload_speed(augment.value)
		AugmentData.AugmentType.MAGAZINE_SIZE:
			_apply_magazine_size(augment.value)
		AugmentData.AugmentType.ACCURACY:
			_apply_accuracy(augment.value)
		AugmentData.AugmentType.PROJECTILE_PIERCING:
			_apply_projectile_piercing(augment.value > 0)
		AugmentData.AugmentType.EXPLOSIVE_ROCKETS:
			_apply_explosive_rockets(augment.value > 0)
		AugmentData.AugmentType.ABILITY:
			# Abilities are handled separately in _apply_ability_augments
			pass
	
	print("Applied augment: ", augment.name, " (", augment.value, ")")

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
	
	# Get base values
	var base_damage = mouse_shooter.weapon_data.get_meta("base_damage")
	var base_fire_rate = mouse_shooter.weapon_data.get_meta("base_fire_rate")
	var base_reload_time = mouse_shooter.weapon_data.get_meta("base_reload_time")
	
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
