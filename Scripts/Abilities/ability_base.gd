extends Node
class_name Ability

## Base class for all abilities

signal cooldown_started(duration: float)
signal cooldown_finished()
signal ability_activated()

@export var ability_name: String = "Ability"
@export var cooldown_time: float = 5.0
@export var ability_icon: Texture2D

var is_on_cooldown: bool = false
var cooldown_remaining: float = 0.0
var owner_node: Node

func _ready() -> void:
	owner_node = get_parent()
	set_process(true)

func _process(delta: float) -> void:
	if is_on_cooldown:
		cooldown_remaining -= delta
		if cooldown_remaining <= 0:
			cooldown_remaining = 0
			is_on_cooldown = false
			cooldown_finished.emit()

## Try to activate the ability. Returns true if successful
func try_activate() -> bool:
	if is_on_cooldown:
		return false
	
	if can_activate():
		activate()
		start_cooldown()
		ability_activated.emit()
		return true
	
	return false

## Override this to add custom activation conditions
func can_activate() -> bool:
	return true

## Override this to implement ability effect
func activate() -> void:
	pass

func start_cooldown() -> void:
	is_on_cooldown = true
	cooldown_remaining = cooldown_time
	cooldown_started.emit(cooldown_time)

func get_cooldown_progress() -> float:
	if not is_on_cooldown:
		return 1.0
	return 1.0 - (cooldown_remaining / cooldown_time)
