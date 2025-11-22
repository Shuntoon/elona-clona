extends Node2D

@export var value: int = 10
@export var float_speed: float = 100.0
@export var fade_duration: float = 1.0
@export var drop_height: float = 60.0
@export var drop_duration: float = 0.6

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var is_collected: bool = false

func _ready() -> void:
	# Play drop animation when spawned
	_play_drop_animation()

func _play_drop_animation() -> void:
	# Store the target position
	var target_pos = position
	
	# Start above the target position
	position.y -= drop_height
	
	# Create drop tween with bounce effect
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BOUNCE)
	
	# Drop down to target position
	tween.tween_property(self, "position:y", target_pos.y, drop_duration)

func _on_mouse_area_2d_mouse_entered() -> void:
	if is_collected:
		return
	
	is_collected = true
	
	# Add gold to player data
	PlayerData.gold += value
	print("Collected ", value, " gold! Total: ", PlayerData.gold)
	
	# Start float and fade animation
	_play_collection_animation()

func _play_collection_animation() -> void:
	# Create a tween for smooth animation
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Move up
	tween.tween_property(self, "position", position + Vector2(0, -50), fade_duration)
	
	# Fade out
	tween.tween_property(animated_sprite, "modulate:a", 0.0, fade_duration)
	
	# Scale up slightly for visual effect
	tween.tween_property(animated_sprite, "scale", Vector2(1.5, 1.5), fade_duration * 0.5)
	
	# Wait for animation to finish then destroy
	await tween.finished
	queue_free()
