extends Control
class_name WaveAnnouncement

@onready var wave_label: Label = $CenterContainer/VBoxContainer/WaveLabel
@onready var subtitle_label: Label = $CenterContainer/VBoxContainer/SubtitleLabel

@export var fade_in_duration: float = 0.5
@export var display_duration: float = 1.5
@export var fade_out_duration: float = 0.5

func _ready() -> void:
	add_to_group("wave_announcement")
	modulate.a = 0.0
	hide()

func announce_wave(wave_number: int, wave_name: String = "") -> void:
	# Set the wave text
	wave_label.text = "Wave %d" % wave_number
	
	if wave_name.is_empty():
		subtitle_label.hide()
	else:
		subtitle_label.text = wave_name
		subtitle_label.show()
	
	show()
	
	# Animate fade in
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, fade_in_duration).set_ease(Tween.EASE_OUT)
	
	# Wait for display duration
	tween.tween_interval(display_duration)
	
	# Animate fade out
	tween.tween_property(self, "modulate:a", 0.0, fade_out_duration).set_ease(Tween.EASE_IN)
	
	# Hide when done
	tween.tween_callback(hide)
