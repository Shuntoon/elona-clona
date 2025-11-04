extends Node
class_name AbilityManager

## Manages player abilities and input

@export var abilities: Array[Ability] = []

func _ready() -> void:
	add_to_group("ability_manager")
	
	# Clear the array first in case it was set in the editor
	abilities.clear()
	
	# Get all child abilities
	for child in get_children():
		if child is Ability:
			abilities.append(child)
			print("Ability added: ", child.ability_name)
	
	print("AbilityManager ready with ", abilities.size(), " abilities")
	
	# Debug: Print ability details
	for i in range(abilities.size()):
		var ability = abilities[i]
		print("  [", i, "] ", ability.ability_name, " - Cooldown: ", ability.cooldown_time, "s")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ability_1") and abilities.size() > 0:
		var success = abilities[0].try_activate()
		if success:
			print("Ability 1 activated: ", abilities[0].ability_name)
		else:
			print("Ability 1 on cooldown")
	
	if event.is_action_pressed("ability_2") and abilities.size() > 1:
		var success = abilities[1].try_activate()
		if success:
			print("Ability 2 activated: ", abilities[1].ability_name)
		else:
			print("Ability 2 on cooldown")
	
	if event.is_action_pressed("ability_3") and abilities.size() > 2:
		var success = abilities[2].try_activate()
		if success:
			print("Ability 3 activated: ", abilities[2].ability_name)
		else:
			print("Ability 3 on cooldown")

func get_ability(index: int) -> Ability:
	if index >= 0 and index < abilities.size():
		return abilities[index]
	return null
