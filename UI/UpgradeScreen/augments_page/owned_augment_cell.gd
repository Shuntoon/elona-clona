class_name OwnedAugmentCell
extends VBoxContainer

@onready var texture_rect: TextureRect = $TextureRect
@onready var stack_label: Label = $StackLabel

var augment_data: AugmentData
var stack_count: int = 1

func setup(aug_data: AugmentData, count: int) -> void:
	augment_data = aug_data
	stack_count = count

func _ready() -> void:
	if augment_data:
		texture_rect.texture = augment_data.icon
		stack_label.text = "x%d" % max(1, stack_count)
		stack_label.add_theme_font_size_override("font_size", 10)
		tooltip_text = "%s\n%s" % [augment_data.name, augment_data.description]
