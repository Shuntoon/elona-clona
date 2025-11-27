extends Node2D
class_name Spawner

@onready var ground: Node2D = %Ground
@onready var air: Node2D = %Air

enum TERRAIN {
	GROUND,
	AIR
}

func spawn_enemy(enemy : PackedScene, terrain : TERRAIN):
	var enemy_inst : Enemy = enemy.instantiate()
	var random_pos : Vector2
	var random_pos_offset = randi_range(-16,16)
	
	match terrain:
		TERRAIN.GROUND:
			var ground_children = ground.get_children()
			var random_ground : Marker2D = ground_children.pick_random()
			random_pos = random_ground.global_position
			enemy_inst.global_position = random_pos + random_pos_offset
		TERRAIN.AIR:
			var air_children = air.get_children()
			var random_air : Marker2D = air_children.pick_random()
			random_pos = random_air.global_position
			enemy_inst.global_position = random_pos + random_pos_offset
			
	var enemies : Node2D = get_tree().get_first_node_in_group("enemies")
	enemies.add_child(enemy_inst)
	
