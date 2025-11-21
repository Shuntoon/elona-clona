extends Resource
class_name EnemyData

@export_category("Generics")
@export var enemy_name : String
@export var speed : float = 2
@export var max_health : int = 5
@export var range : float = 30
@export var damage : int = 1
@export var sprite : Texture2D
@export var animated_sprite_frames : SpriteFrames
@export var attack_speed : float = 1
@export var gold_reward : int = 5
@export var gold_reward_variance : int = 2
@export var terrain_type : Enemy.TERRAIN_TYPE

@export var body_hitbox_size : Vector2 = Vector2(16, 16)
@export var body_pos : Vector2 = Vector2(0, 0)

@export var head_hitbox_size : Vector2 = Vector2(12, 12)
@export var head_pos : Vector2 = Vector2(0, -10)