extends RefCounted
class_name BasementSpawn

const GROUND_Y := 820.0
# Level 1 floor line — matches catwalk / village GROUND_Y convention.
const BASEMENT_TOP_ENTRY_Y := 180.0
const BASEMENT_TOP_ENTRY_X := 280.0
const PLAYER_HALF_WIDTH := 18.0
const DOOR_CLEARANCE := 8.0


static func top_entry_spawn() -> Vector2:
	return Vector2(BASEMENT_TOP_ENTRY_X, BASEMENT_TOP_ENTRY_Y)


static func plant_basement_door_spawn(door: Area2D) -> Vector2:
	var left_edge := _shape_left_edge(door)
	if left_edge > 0.0:
		return Vector2(left_edge - PLAYER_HALF_WIDTH - DOOR_CLEARANCE, GROUND_Y)
	return Vector2(door.global_position.x - 64.0, GROUND_Y)


static func basement_entry_spawn(exit_door: Area2D) -> Vector2:
	var right_edge := _shape_right_edge(exit_door)
	if right_edge > 0.0:
		return Vector2(right_edge + PLAYER_HALF_WIDTH + DOOR_CLEARANCE, BASEMENT_TOP_ENTRY_Y)
	return Vector2(exit_door.global_position.x + 64.0, BASEMENT_TOP_ENTRY_Y)


static func basement_return_spawn(door: Area2D) -> Vector2:
	return plant_basement_door_spawn(door)


static func battery_spawn() -> Vector2:
	return Vector2(1260.0, 1300.0)


static func _shape_right_edge(area: Area2D) -> float:
	var shape_node := area.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape_node == null or not shape_node.shape is RectangleShape2D:
		return -1.0
	var rect := shape_node.shape as RectangleShape2D
	return area.global_position.x + shape_node.position.x + rect.size.x * 0.5


static func _shape_left_edge(area: Area2D) -> float:
	var shape_node := area.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape_node == null or not shape_node.shape is RectangleShape2D:
		return -1.0
	var rect := shape_node.shape as RectangleShape2D
	return area.global_position.x + shape_node.position.x - rect.size.x * 0.5
