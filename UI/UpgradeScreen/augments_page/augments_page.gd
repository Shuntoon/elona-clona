extends Panel
class_name AugmentsPage

@export var augment_selection : Array[AugmentData] = []
@export var augment_selection_size : int = 3
@export var augment_panel_button_scene : PackedScene

# Rarity weights (higher = more common)
@export var common_weight: float = 50.0
@export var uncommon_weight: float = 30.0
@export var rare_weight: float = 15.0
@export var legendary_weight: float = 5.0

@onready var augment_hbox_container: HBoxContainer = %AugmentHBoxContainer

var rng: RandomNumberGenerator

func _ready():
	rng = RandomNumberGenerator.new()
	rng.randomize()
	populate_augment_hbox()

func _on_visibility_changed() -> void:
	if augment_hbox_container != null:
		populate_augment_hbox()

func populate_augment_hbox() -> void:
	# Clear existing children
	for child in augment_hbox_container.get_children():
		child.queue_free()

	# Select unique augments with weighted rarity
	var selected_augments: Array[AugmentData] = []
	var available_augments = augment_selection.duplicate()
	
	# Filter out ability augments if player already has 3
	if not PlayerData.can_purchase_ability():
		available_augments = available_augments.filter(func(aug): return aug.augment_type != AugmentData.AugmentType.ABILITY)
		print("Player has max abilities - filtering ability augments from selection")
	
	for i in range(min(augment_selection_size, available_augments.size())):
		if available_augments.is_empty():
			break
		
		var augment_data = _pick_weighted_augment(available_augments)
		selected_augments.append(augment_data)
		
		# Remove selected augment to prevent duplicates
		available_augments.erase(augment_data)
	
	# Add augment panels for each selected augment
	for augment_data in selected_augments:
		var augment_panel_button_inst : AugmentPanelButton = augment_panel_button_scene.instantiate()
		augment_panel_button_inst.augment_data = augment_data
		augment_hbox_container.add_child(augment_panel_button_inst)

## Pick a random augment from the list with weighted rarity
func _pick_weighted_augment(augments: Array[AugmentData]) -> AugmentData:
	if augments.is_empty():
		return null
	
	# Build weights array based on rarity
	var weights: PackedFloat32Array = PackedFloat32Array()
	
	for augment in augments:
		var weight: float
		match augment.rarity:
			AugmentData.Rarity.COMMON:
				weight = common_weight
			AugmentData.Rarity.UNCOMMON:
				weight = uncommon_weight
			AugmentData.Rarity.RARE:
				weight = rare_weight
			AugmentData.Rarity.LEGENDARY:
				weight = legendary_weight
			_:
				weight = common_weight  # Default to common
		
		weights.append(weight)
	
	# Use weighted random selection
	var selected_index = rng.rand_weighted(weights)
	return augments[selected_index]
