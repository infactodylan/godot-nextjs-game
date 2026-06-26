extends StaticBody2D
class_name HousePlatformBody

enum HouseType { COTTAGE, HOUSE, TALL_HOUSE }

const COTTAGE_HEIGHT := 40.0
const COTTAGE_HALF_W := 62.0
const HOUSE_HEIGHT := 76.0
const HOUSE_HALF_W := 84.0
const TALL_HOUSE_HEIGHT := 118.0
const TALL_HOUSE_HALF_W := 72.0

var house_type: HouseType = HouseType.COTTAGE
var roof_offset: float = COTTAGE_HEIGHT


func configure(type: HouseType) -> void:
	house_type = type
	_clear_collision_shapes()
	match house_type:
		HouseType.COTTAGE:
			roof_offset = COTTAGE_HEIGHT
			_add_box_collision(Vector2(0.0, -COTTAGE_HEIGHT * 0.5), Vector2(COTTAGE_HALF_W * 2.0, COTTAGE_HEIGHT))
		HouseType.HOUSE:
			roof_offset = HOUSE_HEIGHT
			_add_box_collision(Vector2(0.0, -HOUSE_HEIGHT * 0.5), Vector2(HOUSE_HALF_W * 2.0, HOUSE_HEIGHT))
		HouseType.TALL_HOUSE:
			roof_offset = TALL_HOUSE_HEIGHT
			_add_box_collision(
				Vector2(0.0, -TALL_HOUSE_HEIGHT * 0.5),
				Vector2(TALL_HOUSE_HALF_W * 2.0, TALL_HOUSE_HEIGHT)
			)
	set_meta("roof_offset", roof_offset)
	set_meta("half_width", get_half_width())


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
