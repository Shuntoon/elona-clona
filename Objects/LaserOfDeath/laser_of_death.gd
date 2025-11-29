extends Node2D
class_name LaserOfDeath

const HITBOX = preload("res://Objects/Hitbox/hitbox.tscn")
const DAMAGE_NUMBER = preload("res://Objects/DamageNumber/damage_number.tscn")

@onready var line_2d: Line2D = %Line2D
@onready var damage_timer: Timer = Timer.new()

@export var enabled: bool = false
@export var damage_per_tick: int = 5
@export var tick_interval: float = 0.1  # Damage every 0.1 seconds
@export var follow_speed: float = 15.0  # Higher = faster follow, lower = more delay

var neutral_entities: Node
var current_target_pos: Vector2 = Vector2.ZERO
var damaged_enemies_this_tick: Array[Enemy] = []  # Track enemies hit this tick

func _ready() -> void:
	# Always show when ready - visibility controlled by enabled flag in _process
	show()
	z_index = 50  # Make sure laser renders on top
	
	neutral_entities = get_tree().get_first_node_in_group("neutral_entities")
	
	# Setup damage timer
	add_child(damage_timer)
	damage_timer.wait_time = tick_interval
	damage_timer.timeout.connect(_on_damage_tick)
	damage_timer.start()
	
	# Initialize target position to mouse position
	var mouse_pos = get_global_mouse_position()
	current_target_pos = line_2d.to_local(mouse_pos)
	line_2d.set_point_position(1, current_target_pos)
	
	print("Laser of Death ready! Enabled: ", enabled, " Position: ", global_position)

func _process(_delta: float) -> void:
	if not enabled:
		return
		
	var mouse_pos = get_global_mouse_position()
	var target_local_pos = line_2d.to_local(mouse_pos)
	
	# Smoothly interpolate current position towards mouse position
	current_target_pos = current_target_pos.lerp(target_local_pos, follow_speed * _delta)
	line_2d.set_point_position(1, current_target_pos)

func _on_damage_tick() -> void:
	# Clear the list of damaged enemies for this tick
	damaged_enemies_this_tick.clear()
	
	# Damage enemies directly instead of using hitboxes
	_damage_enemies_along_laser()

func _damage_enemies_along_laser() -> void:
	var enemies_node = get_tree().get_first_node_in_group("enemies")
	if not enemies_node:
		return
	
	# Get start and end points of the laser in global coordinates
	var start_pos = line_2d.global_position
	var end_pos = line_2d.to_global(line_2d.points[1])
	
	# Check each enemy to see if they intersect with the laser
	for child in enemies_node.get_children():
		if child is Enemy:
			var enemy: Enemy = child
			
			# Check if enemy is close to the laser line
			var closest_point = _get_closest_point_on_line(enemy.global_position, start_pos, end_pos)
			var distance = enemy.global_position.distance_to(closest_point)
			
			# If enemy is within 30 pixels of the laser line, damage them
			if distance < 30.0 and not damaged_enemies_this_tick.has(enemy):
				enemy.current_health -= damage_per_tick
				damaged_enemies_this_tick.append(enemy)
				
				# Spawn floating damage number
				_spawn_damage_number(damage_per_tick, enemy.global_position)
				print("Laser damaged enemy for ", damage_per_tick)

func _spawn_damage_number(damage_value: int, spawn_position: Vector2) -> void:
	if DAMAGE_NUMBER == null or neutral_entities == null:
		return
	
	var damage_number_inst = DAMAGE_NUMBER.instantiate()
	damage_number_inst.global_position = spawn_position + Vector2(randi_range(-20, 20), randi_range(-20, -30))
	damage_number_inst.set_damage(damage_value, false)  # false = not critical
	neutral_entities.add_child(damage_number_inst)

func _get_closest_point_on_line(point: Vector2, line_start: Vector2, line_end: Vector2) -> Vector2:
	var line_vec = line_end - line_start
	var point_vec = point - line_start
	var line_length_sq = line_vec.length_squared()
	
	if line_length_sq == 0:
		return line_start
	
	var t = clamp(point_vec.dot(line_vec) / line_length_sq, 0.0, 1.0)
	return line_start + line_vec * t
