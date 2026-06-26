extends StaticBody2D
class_name WreckPlatformBody

enum WreckType { CAR, BUS, STREET_SIGN }

const CAR_HEIGHT := 40.0
const CAR_HALF_W := 62.0
const BUS_HEIGHT := 76.0
const BUS_HALF_W := 84.0
const SIGN_HEIGHT := 118.0
const SIGN_HALF_W := 72.0
const SIGN_CLEARANCE := 74.0
const SIGN_POST_W := 6.0
const SIGN_LINTEL_H := 14.0

var wreck_type: WreckType = WreckType.CAR
var roof_offset: float = CAR_HEIGHT


func configure(type: WreckType) -> void:
	wreck_type = type
	_clear_collision_shapes()
	match wreck_type:
		WreckType.CAR:
			roof_offset = CAR_HEIGHT
			_add_box_collision(Vector2(0.0, -CAR_HEIGHT * 0.5), Vector2(CAR_HALF_W * 2.0, CAR_HEIGHT))
		WreckType.BUS:
			roof_offset = BUS_HEIGHT
			_add_box_collision(Vector2(0.0, -BUS_HEIGHT * 0.5), Vector2(BUS_HALF_W * 2.0, BUS_HEIGHT))
		WreckType.STREET_SIGN:
			roof_offset = SIGN_HEIGHT
			var lintel_center_y := -SIGN_HEIGHT + SIGN_LINTEL_H * 0.5
			var post_base_y := -SIGN_CLEARANCE
			var post_top_y := -SIGN_HEIGHT + SIGN_LINTEL_H
			var post_height := post_base_y - post_top_y
			var post_center_y := (post_base_y + post_top_y) * 0.5
			var left_post_x := -SIGN_HALF_W + SIGN_POST_W * 0.5
			var right_post_x := SIGN_HALF_W - SIGN_POST_W * 0.5
			_add_box_collision(
				Vector2(left_post_x, post_center_y),
				Vector2(SIGN_POST_W, post_height)
			)
			_add_box_collision(
				Vector2(right_post_x, post_center_y),
				Vector2(SIGN_POST_W, post_height)
			)
			_add_box_collision(
				Vector2(0.0, lintel_center_y),
				Vector2(SIGN_HALF_W * 2.0, SIGN_LINTEL_H)
			)
	set_meta("roof_offset", roof_offset)
	set_meta("half_width", get_half_width())


func get_roof_offset() -> float:
	return roof_offset


func get_half_width() -> float:
	match wreck_type:
		WreckType.CAR:
			return CAR_HALF_W
		WreckType.BUS:
			return BUS_HALF_W
		WreckType.STREET_SIGN:
			return SIGN_HALF_W
	return CAR_HALF_W


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
