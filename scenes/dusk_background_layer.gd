extends Node2D

enum LayerType { FAR_BUILDINGS, MID_BUILDINGS, NEAR_RUINS, CLOUDS, HAZE }

@export var layer_type: LayerType

var _background: Node2D


func _ready() -> void:
	_background = get_parent()
	call_deferred("queue_redraw")


func _draw() -> void:
	if _background == null:
		return

	match layer_type:
		LayerType.FAR_BUILDINGS:
			DuskBackground.draw_building_layer(self, _background.far_buildings, Color(0.11, 0.09, 0.15))
		LayerType.MID_BUILDINGS:
			DuskBackground.draw_building_layer(self, _background.mid_buildings, Color(0.17, 0.13, 0.19))
		LayerType.NEAR_RUINS:
			DuskBackground.draw_ruins(self, _background.near_ruins, _background.rubble)
		LayerType.CLOUDS:
			DuskBackground.draw_clouds(self, _background.clouds)
		LayerType.HAZE:
			DuskBackground.draw_haze(self)
