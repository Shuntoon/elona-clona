extends Panel
class_name HowToPlayPanel

signal back_pressed

func show_panel() -> void:
	show()
	# Animate popup in
	modulate.a = 0.0
	scale = Vector2(0.9, 0.9)
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "modulate:a", 1.0, 0.2).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func hide_panel() -> void:
	hide()

func _on_back_button_pressed() -> void:
	back_pressed.emit()
	hide_panel()
