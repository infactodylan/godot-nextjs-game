extends Node2D

enum LayerType { FAR_HILLS, MID_VILLAGE, NEAR_TREES, CLOUDS, HAZE, PLAZA, FARMLAND }

@export var layer_type: LayerType

var _background: Node2D


func _ready() -> void:
	_background = get_parent()
	call_deferred("queue_redraw")


func _draw() -> void:
	if _background == null:
		return

	match layer_type:
		LayerType.FAR_HILLS:
			VillageBackground.draw_hills(self, _background.far_hills)
		LayerType.MID_VILLAGE:
			VillageBackground.draw_village(self, _background.mid_village)
		LayerType.NEAR_TREES:
			VillageBackground.draw_trees(self, _background.near_trees, _background.debris)
		LayerType.PLAZA:
			VillageBackground.draw_plaza(self, _background.plaza_paving)
		LayerType.FARMLAND:
			VillageBackground.draw_farmland(self, _background.farmland_rows)
		LayerType.CLOUDS:
			VillageBackground.draw_clouds(self, _background.clouds)
		LayerType.HAZE:
			var half_view: Vector2 = get_meta("half_view", Vector2(960.0, 270.0))
			VillageBackground.draw_haze(self, half_view)
