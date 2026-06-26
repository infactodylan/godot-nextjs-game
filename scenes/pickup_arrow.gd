extends Control

const EDGE_PADDING := 48.0
const LABEL_EDGE_PADDING := 12.0
const ARROW_LENGTH := 56.0
const ARROW_WIDTH := 34.0
const HOVER_GAP := 18.0
const HOVER_BOB_AMOUNT := 8.0
const HOVER_BOB_SPEED := 4.0
const OUTLINE_COLOR := Color(1.0, 1.0, 1.0, 0.95)
const LABEL_FONT_SIZE := 18
const LABEL_OUTLINE_SIZE := 4

var target: Node2D
var origin: Node2D
var camera: Camera2D
var arrow_color := Color(0.95, 0.1, 0.1, 1.0)
var label_text := ""
var timer_text := ""
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
	p_origin: Node2D = null,
	p_label: String = ""
) -> void:
	target = p_target
	camera = p_camera
	origin = p_origin
	arrow_color = color
	label_text = p_label
	visible = true
	set_process(true)
	queue_redraw()


func set_timer_text(text: String) -> void:
	timer_text = text
	queue_redraw()


func deactivate() -> void:
	target = null
	origin = null
	camera = null
	label_text = ""
	timer_text = ""
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
	_draw_label(arrow_pos, aim_dir, target_on_screen)


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


func _draw_label(arrow_pos: Vector2, aim_dir: Vector2, target_on_screen: bool) -> void:
	if label_text.is_empty():
		return

	var font := ThemeDB.fallback_font
	var display_text := label_text
	if not timer_text.is_empty():
		display_text += " (%s)" % timer_text

	var text_size := font.get_string_size(display_text, HORIZONTAL_ALIGNMENT_CENTER, -1, LABEL_FONT_SIZE)
	var label_offset := Vector2(0.0, -ARROW_LENGTH * 0.5 - 10.0)
	if not target_on_screen:
		label_offset = -aim_dir * (ARROW_LENGTH * 0.5 + 14.0)
		if aim_dir.x < -0.2:
			label_offset.x = absf(label_offset.x)
		elif aim_dir.x > 0.2:
			label_offset.x = -absf(label_offset.x) - text_size.x
	var label_pos := arrow_pos + label_offset - Vector2(text_size.x * 0.5, text_size.y)
	if not target_on_screen:
		label_pos.x = clampf(
			label_pos.x,
			LABEL_EDGE_PADDING,
			get_viewport().get_visible_rect().size.x - text_size.x - LABEL_EDGE_PADDING
		)
		label_pos.y = clampf(
			label_pos.y,
			LABEL_EDGE_PADDING,
			get_viewport().get_visible_rect().size.y - LABEL_EDGE_PADDING
		)

	for ox in range(-LABEL_OUTLINE_SIZE, LABEL_OUTLINE_SIZE + 1):
		for oy in range(-LABEL_OUTLINE_SIZE, LABEL_OUTLINE_SIZE + 1):
			if ox == 0 and oy == 0:
				continue
			draw_string(
				font,
				label_pos + Vector2(ox, oy),
				display_text,
				HORIZONTAL_ALIGNMENT_LEFT,
				-1,
				LABEL_FONT_SIZE,
				OUTLINE_COLOR
			)

	draw_string(
		font,
		label_pos,
		display_text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		LABEL_FONT_SIZE,
		arrow_color
	)
