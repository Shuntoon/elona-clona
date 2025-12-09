extends Panel
class_name AugmentsPage

@export var augment_selection : Array[AugmentData] = []
@export var augment_selection_size : int = 3
@export var augment_panel_button_scene : PackedScene

const BASE_REROLL_COST: int = 150
const REROLL_DISCOUNT_PER_LEVEL: float = 0.15

# Rarity weights (higher = more common) - base values at wave 1
@export var common_weight: float = 50.0
@export var uncommon_weight: float = 30.0
@export var rare_weight: float = 15.0
@export var legendary_weight: float = 5.0

# How much rarity improves per wave (percentage increase per wave for better rarities)
@export var rarity_scaling_per_wave: float = 0.08  # 8% improvement per wave

@onready var augment_hbox_container: HBoxContainer = %AugmentHBoxContainer
@onready var owned_grid: GridContainer = %AugmentsIconGridContainer
@onready var reroll_button: Button = $MarginContainer/HBoxContainer/RerollButton
@onready var reroll_sound: AudioStreamPlayer = %RerollSound

var rng: RandomNumberGenerator

func _ready():
	rng = RandomNumberGenerator.new()
	rng.randomize()
	# Helpful group for cross-refresh after purchases
	add_to_group("augments_page")
	# Configure grid columns (optional tweak)
	if owned_grid:
		owned_grid.columns = 12  # Reduced from 16/18 to prevent overflow
	populate_augment_hbox()
	_populate_owned_augments_grid()
	#update_reroll_button()

func _on_visibility_changed() -> void:
	if augment_hbox_container != null:
		populate_augment_hbox()
		_populate_owned_augments_grid()
		#update_reroll_button()

func _process(delta: float) -> void:
	update_reroll_button()

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

## Pick a random augment from the list with weighted rarity (scales with wave count)
func _pick_weighted_augment(augments: Array[AugmentData]) -> AugmentData:
	if augments.is_empty():
		return null
	
	# Get current wave for scaling
	var current_wave: int = 1
	var wave_manager = get_tree().get_first_node_in_group("wave_manager")
	if wave_manager:
		current_wave = wave_manager.current_display_wave
	
	# Calculate wave scaling factor (waves beyond 1 improve rarity chances)
	var wave_bonus = (current_wave - 1) * rarity_scaling_per_wave
	
	# Calculate scaled weights - common decreases, others increase with wave
	var scaled_common = common_weight * max(0.2, 1.0 - wave_bonus)  # Common decreases (min 20% of base)
	var scaled_uncommon = uncommon_weight * (1.0 + wave_bonus * 0.5)  # Uncommon increases slower
	var scaled_rare = rare_weight * (1.0 + wave_bonus)  # Rare increases
	var scaled_legendary = legendary_weight * (1.0 + wave_bonus * 1.5)  # Legendary increases fastest
	
	# Build weights array based on rarity
	var weights: PackedFloat32Array = PackedFloat32Array()
	
	for augment in augments:
		var weight: float
		match augment.rarity:
			AugmentData.Rarity.COMMON:
				weight = scaled_common
			AugmentData.Rarity.UNCOMMON:
				weight = scaled_uncommon
			AugmentData.Rarity.RARE:
				weight = scaled_rare
			AugmentData.Rarity.LEGENDARY:
				weight = scaled_legendary
			_:
				weight = scaled_common  # Default to common
		
		weights.append(weight)
	
	# Use weighted random selection
	var selected_index = rng.rand_weighted(weights)
	return augments[selected_index]


func get_current_reroll_cost() -> int:
	var discount = PlayerData.reroll_discount_level * REROLL_DISCOUNT_PER_LEVEL
	return int(BASE_REROLL_COST * (1.0 - discount))

func update_reroll_button() -> void:
	if not reroll_button:
		return
	var current_cost = get_current_reroll_cost()
	reroll_button.text = "Reroll [%d Gold]" % current_cost
	reroll_button.disabled = PlayerData.gold < current_cost

func _on_reroll_button_pressed() -> void:
	reroll_sound.play()
	var current_cost = get_current_reroll_cost()
	if PlayerData.gold < current_cost:
		print("Not enough gold to reroll augments!")
		return

	populate_augment_hbox()
	PlayerData.gold -= current_cost
	update_reroll_button()

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
