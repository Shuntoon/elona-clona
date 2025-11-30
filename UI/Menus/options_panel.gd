extends Panel
class_name OptionsPanel

signal back_pressed

@onready var master_volume_slider: HSlider = %MasterVolumeSlider
@onready var music_volume_slider: HSlider = %MusicVolumeSlider
@onready var sfx_volume_slider: HSlider = %SFXVolumeSlider
@onready var fullscreen_checkbox: CheckBox = %FullscreenCheckbox
@onready var menu_sound: AudioStreamPlayer = %MenuSound

func _ready() -> void:
	# Sync UI with current settings
	fullscreen_checkbox.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN

func show_panel() -> void:
	show()
	# Sync options UI with current settings
	fullscreen_checkbox.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	# Animate popup in
	modulate.a = 0.0
	scale = Vector2(0.9, 0.9)
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "modulate:a", 1.0, 0.2).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func hide_panel() -> void:
	hide()

func _on_master_volume_changed(value: float) -> void:
	var db = linear_to_db(value / 100.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), db)

func _on_music_volume_changed(value: float) -> void:
	var bus_idx = AudioServer.get_bus_index("Music")
	if bus_idx >= 0:
		var db = linear_to_db(value / 100.0)
		AudioServer.set_bus_volume_db(bus_idx, db)

func _on_sfx_volume_changed(value: float) -> void:
	var bus_idx = AudioServer.get_bus_index("SFX")
	if bus_idx >= 0:
		var db = linear_to_db(value / 100.0)
		AudioServer.set_bus_volume_db(bus_idx, db)

func _on_fullscreen_toggled(toggled_on: bool) -> void:
	menu_sound.play()
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _on_back_button_pressed() -> void:
	menu_sound.play()
	back_pressed.emit()
	hide_panel()
