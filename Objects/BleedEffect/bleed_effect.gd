extends Node
class_name BleedEffect

signal bleed_tick(damage: int)

var bleed_stacks: int = 0
var bleed_duration: float = 4.0
var tick_rate: float = 1.0
var time_since_last_tick: float = 0.0
var time_remaining: float = 0.0

var is_bleeding: bool = false

func _ready() -> void:
	set_process(false)

func _process(delta: float) -> void:
	if not is_bleeding:
		return
	
	time_remaining -= delta
	time_since_last_tick += delta
	
	# Apply damage every tick_rate seconds
	if time_since_last_tick >= tick_rate:
		time_since_last_tick = 0.0
		_apply_bleed_damage()
	
	# Stop bleeding when duration expires
	if time_remaining <= 0.0:
		stop_bleeding()

func apply_bleed_stack() -> void:
	bleed_stacks += 1
	
	# Reset duration when new stack is applied
	time_remaining = bleed_duration
	
	if not is_bleeding:
		is_bleeding = true
		set_process(true)
		time_since_last_tick = 0.0
	
	print("Bleed stack applied! Total stacks: ", bleed_stacks)

func _apply_bleed_damage() -> void:
	if bleed_stacks > 0:
		bleed_tick.emit(bleed_stacks)

func stop_bleeding() -> void:
	is_bleeding = false
	bleed_stacks = 0
	time_remaining = 0.0
	time_since_last_tick = 0.0
	set_process(false)
	print("Bleed effect ended")

func get_bleed_stacks() -> int:
	return bleed_stacks
