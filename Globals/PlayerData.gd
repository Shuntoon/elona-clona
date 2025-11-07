extends Node

@export var ally_datas : Array[AllyData]

@export var weapon_1_data : WeaponData
@export var weapon_2_data : WeaponData

@export var gold : int = 0

@export var armory_level : int = 1

func add_ally_data(ally_data: AllyData) -> void:
	ally_datas.append(ally_data)
