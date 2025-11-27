extends Panel
class_name AugmentsPage

@export var augment_selection : Array[AugmentData] = []
@export var augment_selection_size : int = 3
@export var augment_panel_button_scene : PackedScene

@export var reroll_cost : int = 10

# Rarity weights (higher = more common)
@export var common_weight: float = 50.0
@export var uncommon_weight: float = 30.0
@export var rare_weight: float = 15.0
@export var legendary_weight: float = 5.0

@onready var augment_hbox_container: HBoxContainer = %AugmentHBoxContainer
@onready var owned_grid: GridContainer = %AugmentsIconGridContainer

var rng: RandomNumberGenerator

func _ready():
	rng = RandomNumberGenerator.new()
	rng.randomize()
	# Helpful group for cross-refresh after purchases
	add_to_group("augments_page")
	# Configure grid columns (optional tweak)
	if owned_grid:
		owned_grid.columns = 16
	populate_augment_hbox()
	_populate_owned_augments_grid()

func _on_visibility_changed() -> void:
	if augment_hbox_container != null:
		populate_augment_hbox()
		_populate_owned_augments_grid()

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
	
	# Add augment panels for each selected augment with staggered animation
	var delay := 0.0
	for augment_data in selected_augments:
		var augment_panel_button_inst : AugmentPanelButton = augment_panel_button_scene.instantiate()
		augment_panel_button_inst.augment_data = augment_data
		augment_hbox_container.add_child(augment_panel_button_inst)
		# Animate each card with staggered delay
		augment_panel_button_inst.animate_entrance(delay)
		delay += 0.1

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


func _on_reroll_button_pressed() -> void:
	if PlayerData.gold < reroll_cost:
		print("Not enough gold to reroll augments!")
		return


	populate_augment_hbox()
	PlayerData.gold -= reroll_cost
	pass # Replace with function body.

## Build the Owned Augments grid: one cell per unique augment with icon and stack count
func _populate_owned_augments_grid() -> void:
	if owned_grid == null:
		return
	# Clear existing
	for child in owned_grid.get_children():
		child.queue_free()

	# Count augments by name
	var augment_counts: Dictionary = {}
	
	# Count stat augments
	for aug in PlayerData.augments:
		if aug == null:
			continue
		var aug_name: String = aug.name
		if not augment_counts.has(aug_name):
			augment_counts[aug_name] = {"data": aug, "count": 0}
		augment_counts[aug_name]["count"] += 1

	# Include ability augments
	for aaug in PlayerData.ability_augments:
		if aaug == null:
			continue
		var aaug_name: String = aaug.name
		if not augment_counts.has(aaug_name):
			augment_counts[aaug_name] = {"data": aaug, "count": 0}
		augment_counts[aaug_name]["count"] += 1

	# Create cells for each unique augment
	for aug_name in augment_counts:
		var info: Dictionary = augment_counts[aug_name]
		var aug_data: AugmentData = info["data"]
		var count: int = info["count"]
		var cell: Control = preload("res://UI/UpgradeScreen/augments_page/owned_augment_cell.tscn").instantiate()
		cell.setup(aug_data, count)
		owned_grid.add_child(cell)
