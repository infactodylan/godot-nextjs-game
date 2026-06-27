extends StaticBody2D
class_name HousePlatformBody

enum HouseType { COTTAGE, HOUSE, TALL_HOUSE, COURTHOUSE, BARN, SILO }

const SCALE := 1.75

const COTTAGE_HEIGHT := 40.0 * SCALE
const COTTAGE_HALF_W := 62.0 * SCALE
const HOUSE_HEIGHT := 76.0 * SCALE
const HOUSE_HALF_W := 84.0 * SCALE * 1.15
const TALL_HOUSE_HEIGHT := 118.0 * SCALE * 1.15
const TALL_HOUSE_HALF_W := 72.0 * SCALE * 1.2
const COURTHOUSE_HEIGHT := 200.0
const COURTHOUSE_HALF_W := 150.0
const BARN_HEIGHT := 110.0
const BARN_HALF_W := 125.0
const SILO_HEIGHT := 210.0
const SILO_HALF_W := 48.0

const LEDGE_DEPTH := 34.0
const LEDGE_THICKNESS := 12.0
const BUILDING_COLLISION_LAYER := 0

var house_type: HouseType = HouseType.COTTAGE
var roof_offset: float = COTTAGE_HEIGHT
var ledges: Array[Dictionary] = []


func configure(type: HouseType) -> void:
	house_type = type
	collision_layer = BUILDING_COLLISION_LAYER
	ledges.clear()
	_clear_collision_shapes()
	match house_type:
		HouseType.COTTAGE:
			roof_offset = COTTAGE_HEIGHT
			_add_box_collision(Vector2(0.0, -COTTAGE_HEIGHT * 0.5), Vector2(COTTAGE_HALF_W * 2.0, COTTAGE_HEIGHT))
		HouseType.HOUSE:
			roof_offset = HOUSE_HEIGHT
			_add_box_collision(Vector2(0.0, -HOUSE_HEIGHT * 0.5), Vector2(HOUSE_HALF_W * 2.0, HOUSE_HEIGHT))
			_add_climb_ledges([0.36, 0.68])
		HouseType.TALL_HOUSE:
			roof_offset = TALL_HOUSE_HEIGHT
			_add_box_collision(
				Vector2(0.0, -TALL_HOUSE_HEIGHT * 0.5),
				Vector2(TALL_HOUSE_HALF_W * 2.0, TALL_HOUSE_HEIGHT)
			)
			_add_climb_ledges([0.26, 0.48, 0.7, 0.88])
		HouseType.COURTHOUSE:
			roof_offset = COURTHOUSE_HEIGHT
			_add_box_collision(Vector2(0.0, -COURTHOUSE_HEIGHT * 0.5), Vector2(COURTHOUSE_HALF_W * 2.0, COURTHOUSE_HEIGHT))
			_add_box_collision(Vector2(0.0, -8.0), Vector2(COURTHOUSE_HALF_W * 2.0 + 40.0, 16.0))
		HouseType.BARN:
			roof_offset = BARN_HEIGHT
			_add_box_collision(Vector2(0.0, -BARN_HEIGHT * 0.5), Vector2(BARN_HALF_W * 2.0, BARN_HEIGHT))
		HouseType.SILO:
			roof_offset = SILO_HEIGHT
			_add_box_collision(Vector2(0.0, -SILO_HEIGHT * 0.5), Vector2(SILO_HALF_W * 2.0, SILO_HEIGHT))
			_add_climb_ledges([0.35, 0.62, 0.85])
	set_meta("roof_offset", roof_offset)
	set_meta("half_width", get_half_width())


func _add_climb_ledges(height_ratios: Array) -> void:
	var hw := get_half_width()
	for i in height_ratios.size():
		var side := 1 if i % 2 == 0 else -1
		var height: float = height_ratios[i] * roof_offset
		ledges.append({"side": side, "y": height})
		var center_x := side * (hw + LEDGE_DEPTH * 0.5)
		var center_y := -height - LEDGE_THICKNESS * 0.5
		_add_box_collision(Vector2(center_x, center_y), Vector2(LEDGE_DEPTH, LEDGE_THICKNESS))


func get_roof_offset() -> float:
	return roof_offset


func get_half_width() -> float:
	match house_type:
		HouseType.COTTAGE:
			return COTTAGE_HALF_W
		HouseType.HOUSE:
			return HOUSE_HALF_W
		HouseType.TALL_HOUSE:
			return TALL_HOUSE_HALF_W
		HouseType.COURTHOUSE:
			return COURTHOUSE_HALF_W
		HouseType.BARN:
			return BARN_HALF_W
		HouseType.SILO:
			return SILO_HALF_W
	return COTTAGE_HALF_W


func _clear_collision_shapes() -> void:
	for child in get_children():
		if child is CollisionShape2D:
			child.queue_free()


func _add_box_collision(center: Vector2, size: Vector2) -> void:
	var shape := RectangleShape2D.new()
	shape.size = size
	var collider := CollisionShape2D.new()
	collider.position = center
	collider.shape = shape
	add_child(collider)
