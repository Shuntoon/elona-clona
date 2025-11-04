extends Ability
class_name FireRateBoostAbility

## Temporarily increases fire rate

@export var fire_rate_multiplier: float = 2.0
@export var duration: float = 5.0

var mouse_shooter: MouseShooter
var original_fire_rate: float
var is_active: bool = false

func _ready() -> void:
	super._ready()
	ability_name = "Rapid Fire"
	cooldown_time = 10.0

func activate() -> void:
	if not mouse_shooter:
		mouse_shooter = get_tree().get_first_node_in_group("mouse_shooter")
	
	if not mouse_shooter:
		return
	
	# Store original fire rate and boost it
	original_fire_rate = mouse_shooter.fire_rate
	mouse_shooter.fire_rate = original_fire_rate * fire_rate_multiplier
	mouse_shooter.time_between_shots = 60.0 / mouse_shooter.fire_rate
	is_active = true
	
	print("Fire Rate Boost Activated! (", duration, "s)")
	
	# Wait for duration then restore
	await get_tree().create_timer(duration).timeout
	
	if is_active:
		deactivate()

func deactivate() -> void:
	if mouse_shooter:
		mouse_shooter.fire_rate = original_fire_rate
		mouse_shooter.time_between_shots = 60.0 / mouse_shooter.fire_rate
	is_active = false
	print("Fire Rate Boost Ended")
