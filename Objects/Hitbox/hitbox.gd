extends Area2D
class_name Hitbox

@export var destroy_instantly : bool = true
@export var piercing : bool = false
@export var damage : int = 1

# VFX scenes to spawn
var hit_enemy_vfx: PackedScene
var hit_ground_vfx: PackedScene

var vfx_parent: Node
var hit_enemy: bool = false  # Track if we hit an enemy

func _on_area_entered(area: Area2D) -> void:
	if area.owner.is_in_group("enemy"):
		hit_enemy = true  # Mark that we hit an enemy
		var hurtbox : Hurtbox = area
		var enemy : Enemy = area.owner
		var is_critical = false
		
		match hurtbox.hurtbox_type:
			Hurtbox.HURTBOX_TYPE.BODY:
				enemy.current_health -= damage
			Hurtbox.HURTBOX_TYPE.HEAD:
				enemy.current_health -= damage * 2 # temp 
				is_critical = true
		
		# Spawn enemy hit VFX (red and bigger for headshots)
		_spawn_vfx(hit_enemy_vfx, global_position, is_critical)
		
		# Only destroy if not piercing
		if not piercing:
			await get_tree().create_timer(.1).timeout #despawn after 
			queue_free()

func _ready() -> void:
	# Get VFX parent node
	vfx_parent = get_tree().get_first_node_in_group("neutral_entities")
	
	if destroy_instantly:
		await get_tree().create_timer(.1).timeout #wait to check if we hit enemy
		# Only spawn ground VFX if we didn't hit an enemy
		if not hit_enemy:
			_spawn_vfx(hit_ground_vfx, global_position)
		queue_free()

func _spawn_vfx(vfx_scene: PackedScene, spawn_position: Vector2, is_critical: bool = false) -> void:
	if vfx_scene == null or vfx_parent == null:
		return
	
	var vfx_inst = vfx_scene.instantiate()
	vfx_inst.global_position = spawn_position
	
	# Set critical flag if the VFX has this property
	if "is_critical" in vfx_inst:
		vfx_inst.is_critical = is_critical
	
	vfx_parent.add_child(vfx_inst)
