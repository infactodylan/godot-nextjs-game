extends Control

const EDGE_PADDING := 48.0
const ARROW_LENGTH := 56.0
const ARROW_WIDTH := 34.0
const HOVER_GAP := 18.0
const HOVER_BOB_AMOUNT := 8.0
const HOVER_BOB_SPEED := 4.0
const OUTLINE_COLOR := Color(1.0, 1.0, 1.0, 0.95)

var target: Node2D
var origin: Node2D
var camera: Camera2D
var arrow_color := Color(0.95, 0.1, 0.1, 1.0)
var _hover_time := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = 100
	visible = false


func activate(
	p_target: Node2D,
	p_camera: Camera2D,
	color: Color = arrow_color,
	p_origin: Node2D = null
) -> void:
	target = p_target
	camera = p_camera
	origin = p_origin
	arrow_color = color
	visible = true
	set_process(true)
	queue_redraw()


func deactivate() -> void:
	target = null
	origin = null
	camera = null
	_hover_time = 0.0
	visible = false
	set_process(false)


func _process(delta: float) -> void:
	if target == null or not is_instance_valid(target) or camera == null:
		deactivate()
		return
	_hover_time += delta
	queue_redraw()


func _draw() -> void:
	if target == null or camera == null:
		return

	var viewport_size := get_viewport().get_visible_rect().size
	var screen_target := _world_to_screen(target.global_position)
	var screen_origin := _get_origin_screen_position(viewport_size)
	var viewport_rect := Rect2(Vector2.ZERO, viewport_size).grow_individual(
		-EDGE_PADDING, -EDGE_PADDING, -EDGE_PADDING, -EDGE_PADDING
	)
	var target_on_screen := viewport_rect.has_point(screen_target)

	var arrow_pos: Vector2
	var aim_dir: Vector2

	if target_on_screen:
		var bob := sin(_hover_time * HOVER_BOB_SPEED) * HOVER_BOB_AMOUNT
		var hover_distance := ARROW_LENGTH * 0.5 + HOVER_GAP + bob
		arrow_pos = screen_target + Vector2(0.0, -hover_distance)
		aim_dir = Vector2.DOWN
	else:
		var direction := screen_target - screen_origin
		if direction.length_squared() < 1.0:
			direction = Vector2.RIGHT
		arrow_pos = _clamp_ray_to_rect_edge(screen_origin, direction, viewport_rect)
		aim_dir = direction.normalized()

	_draw_arrow(arrow_pos, aim_dir.angle(), OUTLINE_COLOR, 1.18)
	_draw_arrow(arrow_pos, aim_dir.angle(), arrow_color, 1.0)


func _get_origin_screen_position(viewport_size: Vector2) -> Vector2:
	if origin != null and is_instance_valid(origin):
		return _world_to_screen(origin.global_position)
	return viewport_size * 0.5


func _world_to_screen(world_pos: Vector2) -> Vector2:
	var viewport_size := get_viewport().get_visible_rect().size
	return (world_pos - camera.get_screen_center_position()) * camera.zoom + viewport_size * 0.5


func _clamp_ray_to_rect_edge(start: Vector2, direction: Vector2, bounds: Rect2) -> Vector2:
	var dir := direction.normalized()
	var t := INF

	if dir.x > 0.0:
		t = minf(t, (bounds.end.x - start.x) / dir.x)
	elif dir.x < 0.0:
		t = minf(t, (bounds.position.x - start.x) / dir.x)

	if dir.y > 0.0:
		t = minf(t, (bounds.end.y - start.y) / dir.y)
	elif dir.y < 0.0:
		t = minf(t, (bounds.position.y - start.y) / dir.y)

	if t == INF or t < 0.0:
		return bounds.get_center()

	return start + dir * t


func _draw_arrow(pos: Vector2, angle: float, color: Color, scale: float = 1.0) -> void:
	var tip := Vector2(ARROW_LENGTH * 0.5 * scale, 0.0)
	var wing_a := Vector2(-ARROW_LENGTH * 0.45 * scale, -ARROW_WIDTH * 0.5 * scale)
	var wing_b := Vector2(-ARROW_LENGTH * 0.45 * scale, ARROW_WIDTH * 0.5 * scale)
	var points := PackedVector2Array([
		pos + tip.rotated(angle),
		pos + wing_a.rotated(angle),
		pos + wing_b.rotated(angle),
	])
	draw_colored_polygon(points, color)
