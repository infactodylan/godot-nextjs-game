extends Node2D

const WreckPlatformBodyScript = preload("res://entities/wreck_platform/wreck_platform.gd")
const WreckPlatformVisual = preload("res://entities/wreck_platform/wreck_platform_visual.gd")

const GROUND_Y := 820.0

const WRECK_TYPES := [
	WreckPlatformVisual.WreckType.CAR,
	WreckPlatformVisual.WreckType.BUS,
	WreckPlatformVisual.WreckType.CAR,
	WreckPlatformVisual.WreckType.STREET_SIGN,
	WreckPlatformVisual.WreckType.BUS,
	WreckPlatformVisual.WreckType.CAR,
	WreckPlatformVisual.WreckType.STREET_SIGN,
	WreckPlatformVisual.WreckType.BUS,
	WreckPlatformVisual.WreckType.CAR,
	WreckPlatformVisual.WreckType.STREET_SIGN,
]


func _ready() -> void:
	var type_index := 0
	for platform in get_children():
		if not platform.is_in_group("platform"):
			continue

		platform.position.y = GROUND_Y

		for child in platform.get_children():
			child.queue_free()

		platform.set_script(WreckPlatformBodyScript)
		var wreck: WreckPlatformBody = platform as WreckPlatformBody
		var wreck_type: WreckPlatformBody.WreckType = WRECK_TYPES[type_index % WRECK_TYPES.size()]
		wreck.configure(wreck_type)

		if wreck_type == WreckPlatformBody.WreckType.STREET_SIGN:
			var back_visual := WreckPlatformVisual.new()
			back_visual.name = "VisualBack"
			back_visual.wreck_type = WreckPlatformVisual.WreckType.STREET_SIGN
			back_visual.sign_layer = WreckPlatformVisual.SignLayer.BACK
			back_visual.color_seed = type_index * 97 + 13
			wreck.add_child(back_visual)

			var front_visual := WreckPlatformVisual.new()
			front_visual.name = "VisualFront"
			front_visual.wreck_type = WreckPlatformVisual.WreckType.STREET_SIGN
			front_visual.sign_layer = WreckPlatformVisual.SignLayer.FRONT
			front_visual.color_seed = type_index * 97 + 13
			wreck.add_child(front_visual)
		else:
			var visual := WreckPlatformVisual.new()
			visual.name = "Visual"
			visual.wreck_type = wreck_type as WreckPlatformVisual.WreckType
			visual.color_seed = type_index * 97 + 13
			wreck.add_child(visual)

		type_index += 1
