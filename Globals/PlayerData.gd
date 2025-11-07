extends Node

@export var ally_datas : Array[AllyData]

@export var gold : int = 0

func add_ally_data(ally_data: AllyData) -> void:
	ally_datas.append(ally_data)
