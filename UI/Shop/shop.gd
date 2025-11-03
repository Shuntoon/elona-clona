extends Control

func _ready() -> void:
	position.y = position.y - 1000
	var tween := create_tween()
	tween.tween_property(self, "position:y", position.y + 1000, 1).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
