extends RefCounted
class_name PlantDoorSpawn

const GROUND_Y := 820.0
const PLAYER_HALF_WIDTH := 18.0
const DOOR_CLEARANCE := 8.0


static func interior_spawn(exit_door: Area2D) -> Vector2:
	var right_edge := _shape_right_edge(exit_door)
	if right_edge > 0.0:
		return Vector2(right_edge + PLAYER_HALF_WIDTH + DOOR_CLEARANCE, GROUND_Y)
	return Vector2(exit_door.global_position.x + 64.0, GROUND_Y)


static func exterior_spawn(entry_door: Area2D) -> Vector2:
	var left_edge := _shape_left_edge(entry_door)
	if left_edge > 0.0:
		return Vector2(left_edge - PLAYER_HALF_WIDTH - DOOR_CLEARANCE, GROUND_Y)
	var plant := entry_door.get_parent()
	if plant:
		return Vector2(plant.global_position.x - 36.0, GROUND_Y)
	return Vector2(entry_door.global_position.x - 52.0, GROUND_Y)


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
