extends Resource
class_name WaveData

## Configuration for a single wave with manual difficulty phase setup

@export var wave_number: int = 1

# Enemy pools for each difficulty phase (first third, second third, final third of day)
@export var easy_enemies: Array[EnemyData]  # Array of EnemyData
@export var medium_enemies: Array[EnemyData]  # Array of EnemyData
@export var hard_enemies: Array[EnemyData]  # Array of EnemyData

# Weights for weighted randomness (must match array sizes)
@export var easy_weights: Array[float] = []
@export var medium_weights: Array[float] = []
@export var hard_weights: Array[float] = []

# Spawn timing configuration
@export var base_spawn_interval: float = 2.0
@export var easy_spawn_multiplier: float = 1.5
@export var medium_spawn_multiplier: float = 1.0
@export var hard_spawn_multiplier: float = 0.6

func validate() -> bool:
	var valid = true
	
	# Check easy phase
	if easy_enemies.size() > 0:
		if easy_enemies.size() != easy_weights.size():
			push_error("Wave ", wave_number, ": Easy enemies (", easy_enemies.size(), ") and weights (", easy_weights.size(), ") size mismatch!")
			valid = false
	else:
		push_warning("Wave ", wave_number, ": No easy enemies configured")
	
	# Check medium phase
	if medium_enemies.size() > 0:
		if medium_enemies.size() != medium_weights.size():
			push_error("Wave ", wave_number, ": Medium enemies (", medium_enemies.size(), ") and weights (", medium_weights.size(), ") size mismatch!")
			valid = false
	else:
		push_warning("Wave ", wave_number, ": No medium enemies configured")
	
	# Check hard phase
	if hard_enemies.size() > 0:
		if hard_enemies.size() != hard_weights.size():
			push_error("Wave ", wave_number, ": Hard enemies (", hard_enemies.size(), ") and weights (", hard_weights.size(), ") size mismatch!")
			valid = false
	else:
		push_warning("Wave ", wave_number, ": No hard enemies configured")
	
	return valid

func get_spawn_interval(phase: String) -> float:
	match phase:
		"easy":
			return base_spawn_interval * easy_spawn_multiplier
		"medium":
			return base_spawn_interval * medium_spawn_multiplier
		"hard":
			return base_spawn_interval * hard_spawn_multiplier
		_:
			return base_spawn_interval

func get_enemy_pool(phase: String) -> Array:
	match phase:
		"easy":
			return easy_enemies
		"medium":
			return medium_enemies
		"hard":
			return hard_enemies
		_:
			return []

func get_weights(phase: String) -> Array[float]:
	match phase:
		"easy":
			return easy_weights
		"medium":
			return medium_weights
		"hard":
			return hard_weights
		_:
			return []
