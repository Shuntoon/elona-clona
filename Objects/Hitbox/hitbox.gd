extends Area2D
class_name Hitbox

var damage : int = 1

func _on_area_entered(area: Area2D) -> void:
	if area.owner.is_in_group("enemy"):
		var hurtbox : Hurtbox = area
		var enemy : Enemy = area.owner
		match hurtbox.hurtbox_type:
			Hurtbox.HURTBOX_TYPE.BODY:
				enemy.current_health -= damage
			Hurtbox.HURTBOX_TYPE.HEAD:
				enemy.current_health -= damage * 2 # temp 
				print("Critcal Hit!")
		
	pass # Replace with function body.

func _ready() -> void:
	await get_tree().create_timer(.1).timeout #despawn after 
	queue_free()
