extends Node2D

const FarmlandPlant = preload("res://entities/farmland_plant/farmland_plant.gd")

const GROUND_Y := 820.0
const FARMLAND_START_X := 6360.0
const FARMLAND_END_X := 7720.0
const PLANT_COUNT := 58
const BEHIND_Z := WreckPlatformVisual.PLAYER_SORT_Z - 2
const FRONT_Z := WreckPlatformVisual.PLAYER_SORT_Z + 2


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 8801
	for i in PLANT_COUNT:
		var x := rng.randf_range(FARMLAND_START_X, FARMLAND_END_X)
		if x > 7460.0 and x < 7580.0:
			continue
		var in_front := rng.randf() < 0.46
		var plant := FarmlandPlant.new()
		plant.name = "Plant%d" % i
		plant.position = Vector2(x, GROUND_Y)
		plant.z_as_relative = false
		plant.z_index = FRONT_Z if in_front else BEHIND_Z
		var style: FarmlandPlant.PlantStyle = rng.randi() % 4
		plant.configure(style, rng.randf_range(0.8, 1.4), in_front)
		add_child(plant)
