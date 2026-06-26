extends Node2D

const HousePlatformBodyScript = preload("res://entities/house_platform/house_platform.gd")
const HousePlatformVisual = preload("res://entities/house_platform/house_platform_visual.gd")

const GROUND_Y := 820.0

const HOUSE_TYPES := [
	HousePlatformVisual.HouseType.COTTAGE,
	HousePlatformVisual.HouseType.HOUSE,
	HousePlatformVisual.HouseType.COTTAGE,
	HousePlatformVisual.HouseType.TALL_HOUSE,
	HousePlatformVisual.HouseType.HOUSE,
	HousePlatformVisual.HouseType.COTTAGE,
	HousePlatformVisual.HouseType.TALL_HOUSE,
	HousePlatformVisual.HouseType.HOUSE,
	HousePlatformVisual.HouseType.COTTAGE,
	HousePlatformVisual.HouseType.TALL_HOUSE,
]


func _ready() -> void:
	var type_index := 0
	for platform in get_children():
		if not platform.is_in_group("platform"):
			continue

		platform.position.y = GROUND_Y

		for child in platform.get_children():
			child.queue_free()

		platform.set_script(HousePlatformBodyScript)
		var house: HousePlatformBody = platform as HousePlatformBody
		var house_type: HousePlatformBody.HouseType = HOUSE_TYPES[type_index % HOUSE_TYPES.size()]
		house.configure(house_type)

		var visual := HousePlatformVisual.new()
		visual.name = "Visual"
		visual.house_type = house_type as HousePlatformVisual.HouseType
		visual.color_seed = type_index * 97 + 13
		house.add_child(visual)

		type_index += 1
