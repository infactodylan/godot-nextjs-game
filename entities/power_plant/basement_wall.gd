@tool
extends StaticBody2D
class_name BasementWall

const WALL_COLOR := Color(0.55, 0.5, 0.44, 0.9)
const SHAFT_COLOR := Color(0.05, 0.07, 0.1)

@export var wall_size: Vector2 = Vector2(24.0, 100.0):
	set(value):
		wall_size = value.max(Vector2(4.0, 4.0))
		_sync_geometry()

@export var is_shaft_fill: bool = false:
	set(value):
		is_shaft_fill = value
		_sync_geometry()


func _ready() -> void:
	collision_layer = 2
	collision_mask = 0
	add_to_group("basement_wall")
	_sync_geometry()


func _enter_tree() -> void:
	_sync_geometry()


func _sync_geometry() -> void:
	if not is_inside_tree():
		return

	var collision := _get_collision_shape()
	var rect := collision.shape as RectangleShape2D
	if rect == null:
		rect = RectangleShape2D.new()
		collision.shape = rect
	rect.size = wall_size
	collision.position = Vector2.ZERO

	var visual := _get_visual()
	visual.size = wall_size
	visual.position = Vector2(-wall_size.x * 0.5, -wall_size.y * 0.5)
	visual.color = SHAFT_COLOR if is_shaft_fill else WALL_COLOR
	visual.visible = true

	if is_shaft_fill:
		collision.disabled = true
	else:
		collision.disabled = false


func _get_collision_shape() -> CollisionShape2D:
	var node := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if node == null:
		node = CollisionShape2D.new()
		node.name = "CollisionShape2D"
		add_child(node)
		node.owner = _scene_owner()
	return node


func _get_visual() -> ColorRect:
	var node := get_node_or_null("Visual") as ColorRect
	if node == null:
		node = ColorRect.new()
		node.name = "Visual"
		add_child(node)
		node.owner = _scene_owner()
	return node


func _scene_owner() -> Node:
	if Engine.is_editor_hint():
		return get_tree().edited_scene_root
	return owner
