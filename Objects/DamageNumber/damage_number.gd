extends Label
class_name DamageNumber

@export var float_speed: float = 50.0
@export var lifetime: float = 1.0
@export var spread_range: float = 30.0

var velocity: Vector2 = Vector2.ZERO
var is_critical: bool = false
var is_bleed: bool = false
var is_explosion: bool = false

func _ready() -> void:
	# Random horizontal spread
	velocity.x = randf_range(-spread_range, spread_range)
	velocity.y = -float_speed
	
	# Style based on damage type
	if is_explosion:
		add_theme_color_override("font_color", Color(1.0, 0.15, 0.1))  # Bright red for explosions
		add_theme_font_size_override("font_size", 36)
		scale = Vector2(1.8, 1.8)
	elif is_bleed:
		add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))  # Red for bleed
		add_theme_font_size_override("font_size", 20)
		scale = Vector2(1.0, 1.0)
	elif is_critical:
		add_theme_color_override("font_color", Color(1.0, 0.8, 0.0))  # Gold for crits
		scale = Vector2(1.5, 1.5)
		add_theme_font_size_override("font_size", 32)
	else:
		add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))  # White for normal
		add_theme_font_size_override("font_size", 24)
	
	# Add outline
	add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0))
	add_theme_constant_override("outline_size", 2)
	
	# Fade out animation
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, lifetime).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "scale", scale * 0.5, lifetime).set_ease(Tween.EASE_IN)
	
	# Delete after lifetime
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _process(delta: float) -> void:
	position += velocity * delta
	# Slow down over time
	velocity = velocity.lerp(Vector2.ZERO, delta * 2.0)

func set_damage(damage_value: int, critical: bool = false) -> void:
	text = str(damage_value)
	is_critical = critical

func set_bleed_damage(damage_value: int) -> void:
	text = str(damage_value)
	is_bleed = true

func set_bleed_color() -> void:
	# Deprecated - use set_bleed_damage() instead
	is_bleed = true

func set_explosion_damage(damage_value: int) -> void:
	text = str(damage_value)
	is_explosion = true
