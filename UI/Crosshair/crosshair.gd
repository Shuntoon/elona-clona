extends CanvasLayer
class_name Crosshair

## Base scale of the crosshair
@export var base_scale: Vector2 = Vector2(2.0, 2.0)
## Scale when expanded (on shoot)
@export var expanded_scale: Vector2 = Vector2(3.0, 3.0)
## Duration of expand animation
@export var expand_duration: float = 0.05
## Duration of contract animation
@export var contract_duration: float = 0.15

@onready var sprite: Sprite2D = $Sprite

var tween: Tween

func _ready() -> void:
	# Hide the default cursor
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
	# Set initial scale
	sprite.scale = base_scale
	
	# Center the texture
	sprite.centered = true

func _process(_delta: float) -> void:
	# Follow the mouse position
	sprite.global_position = get_viewport().get_mouse_position()

func _exit_tree() -> void:
	# Show the cursor again when crosshair is removed
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

## Call this when shooting to play the expand/contract animation
func on_shoot() -> void:
	# Kill any existing tween
	if tween and tween.is_valid():
		tween.kill()
	
	# Create new tween for expand then contract
	tween = create_tween()
	tween.tween_property(sprite, "scale", expanded_scale, expand_duration).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "scale", base_scale, contract_duration).set_ease(Tween.EASE_OUT)

## Reset to default cursor (for menus)
func hide_crosshair() -> void:
	visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

## Show crosshair (for gameplay)
func show_crosshair() -> void:
	visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
