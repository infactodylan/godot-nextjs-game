extends Node2D

const HousePlatformBodyScript = preload("res://entities/house_platform/house_platform.gd")
const HousePlatformVisual = preload("res://entities/house_platform/house_platform_visual.gd")

const GROUND_Y := 820.0

const RESIDENTIAL_TYPES := [
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

const EAST_VILLAGE_TYPES := [
	HousePlatformVisual.HouseType.HOUSE,
	HousePlatformVisual.HouseType.TALL_HOUSE,
	HousePlatformVisual.HouseType.COTTAGE,
	HousePlatformVisual.HouseType.HOUSE,
	HousePlatformVisual.HouseType.TALL_HOUSE,
]


func _ready() -> void:
	var residential_index := 0
	var east_index := 0
	for platform in get_children():
		if not platform.is_in_group("platform"):
			continue

		platform.position.y = GROUND_Y

		for child in platform.get_children():
			child.queue_free()

		platform.set_script(HousePlatformBodyScript)
		var house: HousePlatformBody = platform as HousePlatformBody
		var house_type := _resolve_house_type(platform.name, residential_index, east_index)
		if platform.name.begins_with("Platform") and platform.name != "Courthouse":
			var num := int(platform.name.trim_prefix("Platform"))
			if num <= 10:
				residential_index += 1
			elif num <= 15:
				east_index += 1
		house.configure(house_type)

		var visual := HousePlatformVisual.new()
		visual.name = "Visual"
		visual.house_type = house_type as HousePlatformVisual.HouseType
		visual.color_seed = hash(platform.name) + residential_index * 97
		house.add_child(visual)


func _resolve_house_type(
	platform_name: String,
	residential_index: int,
	east_index: int
) -> HousePlatformBody.HouseType:
	match platform_name:
		"Courthouse":
			return HousePlatformBody.HouseType.COURTHOUSE
		"FarmBarn":
			return HousePlatformBody.HouseType.BARN
		"FarmSilo":
			return HousePlatformBody.HouseType.SILO
		_:
			if platform_name.begins_with("Platform"):
				var num := int(platform_name.trim_prefix("Platform"))
				if num <= 10:
					return RESIDENTIAL_TYPES[residential_index % RESIDENTIAL_TYPES.size()]
				if num <= 15:
					return EAST_VILLAGE_TYPES[east_index % EAST_VILLAGE_TYPES.size()]
	return HousePlatformBody.HouseType.COTTAGE
