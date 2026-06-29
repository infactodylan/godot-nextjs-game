extends RefCounted
class_name GateSpawn

const GROUND_Y := 820.0
const PLAYER_HALF_WIDTH := 18.0
const GATE_CLEARANCE := 8.0


static func spawn_west_of_gate(gate: Area2D, ground_y: float = GROUND_Y) -> Vector2:
	var left_edge := _shape_left_edge(gate)
	if left_edge > 0.0:
		return Vector2(left_edge - PLAYER_HALF_WIDTH - GATE_CLEARANCE, ground_y)
	return Vector2(gate.global_position.x - 64.0, ground_y)


static func spawn_east_of_gate(gate: Area2D, ground_y: float = GROUND_Y) -> Vector2:
	var right_edge := _shape_right_edge(gate)
	if right_edge > 0.0:
		return Vector2(right_edge + PLAYER_HALF_WIDTH + GATE_CLEARANCE, ground_y)
	return Vector2(gate.global_position.x + 64.0, ground_y)


static func village_entry_from_wasteland(wasteland_gate: Area2D) -> Vector2:
	return spawn_west_of_gate(wasteland_gate)


static func wasteland_entry_from_village(village_gate: Area2D) -> Vector2:
	return spawn_east_of_gate(village_gate)


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
