@tool
extends Node2D
class_name BasementMap

const DEFAULT_MAP_SIZE := Vector2(1600.0, 1600.0)

@export var map_size: Vector2 = DEFAULT_MAP_SIZE:
	set(value):
		map_size = value.max(Vector2(320.0, 320.0))
		queue_redraw()
		_sync_bounds_guide()

@export var emergency_power: bool = false:
	set(value):
		emergency_power = value
		queue_redraw()

@export var show_bounds_guide: bool = true:
	set(value):
		show_bounds_guide = value
		_sync_bounds_guide()

var _bounds_guide: ColorRect


func _ready() -> void:
	_sync_bounds_guide()
	queue_redraw()


func _draw() -> void:
	var bg := Color(0.08, 0.11, 0.16) if not emergency_power else Color(0.1, 0.13, 0.18)
	draw_rect(Rect2(Vector2.ZERO, map_size), bg)

	if emergency_power:
		for i in 6:
			var lx := 180.0 + i * 240.0
			draw_circle(Vector2(lx, 90.0 + (i % 2) * 30.0), 18.0, Color(0.9, 0.75, 0.2, 0.12))

	if not emergency_power:
		draw_rect(Rect2(Vector2.ZERO, map_size), Color(0.0, 0.0, 0.0, 0.28))

	if Engine.is_editor_hint() and show_bounds_guide:
		draw_rect(Rect2(Vector2.ZERO, map_size), Color(0.35, 0.55, 0.85, 0.35), false, 2.0)
		draw_string(
			ThemeDB.fallback_font,
			Vector2(16.0, 28.0),
			"Basement map — drag platforms/walls/spawns to edit",
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			16,
			Color(0.55, 0.5, 0.45)
		)


func set_emergency_power(on: bool) -> void:
	emergency_power = on


func get_enemy_spawn_positions() -> Array[Vector2]:
	var spawns: Array[Vector2] = []
	var container := get_node_or_null("EnemySpawns")
	if container == null:
		return spawns
	for child in container.get_children():
		if child is Node2D:
			spawns.append(child.position)
	return spawns


func _sync_bounds_guide() -> void:
	if not is_inside_tree():
		return
	var guide := _get_bounds_guide()
	guide.visible = Engine.is_editor_hint() and show_bounds_guide
	guide.size = map_size
	guide.color = Color(0.35, 0.55, 0.85, 0.08)


func _get_bounds_guide() -> ColorRect:
	if is_instance_valid(_bounds_guide):
		return _bounds_guide
	_bounds_guide = get_node_or_null("BoundsGuide") as ColorRect
	if _bounds_guide == null:
		_bounds_guide = ColorRect.new()
		_bounds_guide.name = "BoundsGuide"
		_bounds_guide.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_bounds_guide)
		move_child(_bounds_guide, 0)
		if Engine.is_editor_hint():
			_bounds_guide.owner = get_tree().edited_scene_root
	return _bounds_guide
