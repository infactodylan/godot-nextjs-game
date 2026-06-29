@tool
extends StaticBody2D
class_name BasementPlatform

const SURFACE_OFFSET := 8.0
const COLLISION_HEIGHT := 32.0
const COLLISION_OFFSET_Y := 8.0
const DECK_COLOR := Color(0.72, 0.66, 0.54, 0.85)
const EDGE_COLOR := Color(0.55, 0.5, 0.44)

@export_range(32.0, 2000.0, 1.0) var width: float = 180.0:
	set(value):
		width = maxf(32.0, value)
		_sync_geometry()

@export var level_name: String = "":
	set(value):
		level_name = value
		_sync_geometry()


func _ready() -> void:
	collision_layer = 2
	collision_mask = 0
	add_to_group("basement_platform")
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
	rect.size = Vector2(width, COLLISION_HEIGHT)
	collision.position = Vector2(0.0, COLLISION_OFFSET_Y)

	var deck := _get_deck_visual()
	deck.offset_left = -width * 0.5
	deck.offset_right = width * 0.5
	deck.offset_top = -SURFACE_OFFSET
	deck.offset_bottom = -SURFACE_OFFSET + 18.0
	deck.color = DECK_COLOR

	var edge := _get_edge_visual()
	edge.offset_left = -width * 0.5
	edge.offset_right = width * 0.5
	edge.offset_top = -SURFACE_OFFSET
	edge.offset_bottom = -SURFACE_OFFSET + 5.0
	edge.color = EDGE_COLOR

	var label := _get_level_label()
	label.text = level_name
	label.visible = not level_name.is_empty() and Engine.is_editor_hint()
	if label.visible:
		label.position = Vector2(-width * 0.5 + 8.0, -SURFACE_OFFSET - 20.0)


func _get_collision_shape() -> CollisionShape2D:
	var node := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if node == null:
		node = CollisionShape2D.new()
		node.name = "CollisionShape2D"
		add_child(node)
		node.owner = _scene_owner()
	return node


func _get_deck_visual() -> ColorRect:
	var node := get_node_or_null("Deck") as ColorRect
	if node == null:
		node = ColorRect.new()
		node.name = "Deck"
		add_child(node)
		node.owner = _scene_owner()
	return node


func _get_edge_visual() -> ColorRect:
	var node := get_node_or_null("Edge") as ColorRect
	if node == null:
		node = ColorRect.new()
		node.name = "Edge"
		add_child(node)
		node.owner = _scene_owner()
	return node


func _get_level_label() -> Label:
	var node := get_node_or_null("LevelLabel") as Label
	if node == null:
		node = Label.new()
		node.name = "LevelLabel"
		node.add_theme_font_size_override("font_size", 14)
		node.modulate = Color(0.42, 0.4, 0.36, 0.75)
		add_child(node)
		node.owner = _scene_owner()
	return node


func _scene_owner() -> Node:
	if Engine.is_editor_hint():
		return get_tree().edited_scene_root
	return owner
