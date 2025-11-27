extends Node2D
class_name Froggert

## Projectile settings
@export var projectile_damage: int = 25
@export var projectile_speed: float = 300.0
@export var projectile_scene: PackedScene

## Explosion settings
@export var explosion_damage: int = 50
@export var explosion_scene: PackedScene

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

var target: Enemy
var is_shooting: bool = false
var shoot_timer: Timer

func _ready() -> void:
	animated_sprite_2d.play("idle")
	
	# Create shoot timer
	shoot_timer = Timer.new()
	shoot_timer.wait_time = 1.3
	shoot_timer.one_shot = false
	shoot_timer.timeout.connect(_on_shoot_timer_timeout)
	add_child(shoot_timer)

func _process(_delta: float) -> void:
	# Check if target is still valid
	if is_shooting and (not target or not is_instance_valid(target)):
		_stop_shooting()

func _on_collision_area_area_entered(_area: Area2D) -> void:
	# Spawn explosion at froggert's position
	if explosion_scene:
		var vfx_parent = get_tree().get_first_node_in_group("neutral_entities")
		if vfx_parent:
			var explosion_inst : Explosion = explosion_scene.instantiate()
			explosion_inst.global_position = global_position
			explosion_inst.damage = explosion_damage
			vfx_parent.add_child(explosion_inst)
	
	# Play death animation and clean up
	animated_sprite_2d.play("death")
	await get_tree().create_timer(0.6).timeout
	queue_free()

func _on_detection_area_area_entered(area: Area2D) -> void:
	if area.owner and area.owner.is_in_group("enemy"):
		target = area.owner
		
		# Start shooting
		if not is_shooting:
			is_shooting = true
			animated_sprite_2d.play("attack")
			shoot_timer.start()
			# Shoot immediately on detection
			_shoot_projectile()

func _on_detection_area_area_exited(area: Area2D) -> void:
	if area.owner == target:
		_stop_shooting()

func _stop_shooting() -> void:
	is_shooting = false
	target = null
	shoot_timer.stop()
	animated_sprite_2d.play("idle")

func _on_shoot_timer_timeout() -> void:
	if is_shooting and target and is_instance_valid(target):
		_shoot_projectile()

func _shoot_projectile() -> void:
	if not projectile_scene:
		return
	
	var projectile_parent = get_tree().get_first_node_in_group("neutral_entities")
	if not projectile_parent:
		return
	
	var projectile : Bullet = projectile_scene.instantiate()
	projectile.global_position = global_position
	
	# Set projectile to move left
	projectile.target = global_position + Vector2(-1000, 0)
	
	# Set projectile properties
	projectile.speed = projectile_speed

	projectile.scale = Vector2(5, 5)
	
	# Set damage on the hitbox
	var hitbox = projectile.get_node_or_null("Hitbox")
	if hitbox:
		hitbox.damage = projectile_damage
	
	projectile_parent.add_child(projectile)
