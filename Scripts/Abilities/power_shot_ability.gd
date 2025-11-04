extends Ability
class_name PowerShotAbility

## Fires a powerful piercing projectile

@export var damage_multiplier: float = 5.0
@export var projectile_speed_multiplier: float = 1.5

const BULLET_BASE = preload("uid://bljxubxu5eg3j")
const HIT_ENEMY_VFX = preload("uid://cubkpuvcxnh63")
const HIT_GROUND_VFX = preload("uid://doaytv1th1j3v")

var mouse_shooter: MouseShooter

func _ready() -> void:
	super._ready()
	ability_name = "Power Shot"
	cooldown_time = 8.0

func activate() -> void:
	if not mouse_shooter:
		mouse_shooter = get_tree().get_first_node_in_group("mouse_shooter")
	
	if not mouse_shooter:
		return
	
	var neutral_entities = get_tree().get_first_node_in_group("neutral_entities")
	if not neutral_entities:
		return
	
	# Get mouse position from viewport
	var mouse_position = get_viewport().get_mouse_position()
	
	# Create a powerful piercing bullet
	var bullet_inst : Bullet = BULLET_BASE.instantiate()
	bullet_inst.global_position = mouse_shooter.bullet_spawn_point
	bullet_inst.target = mouse_position + mouse_shooter._calculate_accuracy_offset()
	bullet_inst.piercing = true  # Always piercing
	bullet_inst.speed *= projectile_speed_multiplier
	bullet_inst.hit_enemy_vfx = HIT_ENEMY_VFX
	bullet_inst.hit_ground_vfx = HIT_GROUND_VFX
	
	# Make it more powerful and visually distinct
	bullet_inst.scale = Vector2(2.0, 2.0)  # Bigger bullet
	bullet_inst.modulate = Color(1.5, 1.0, 0.3, 1.0)  # Golden glow
	
	# Get the hitbox and make it stronger
	await get_tree().process_frame  # Wait for bullet to be added to tree
	neutral_entities.add_child(bullet_inst)
	
	await get_tree().process_frame
	var hitbox = bullet_inst.get_node_or_null("Hitbox")
	if hitbox:
		hitbox.damage = int(hitbox.damage * damage_multiplier)
		hitbox.piercing = true
	
	print("Power Shot Fired!")
