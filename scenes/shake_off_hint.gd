extends Control

const HINT_TEXT := "shake him off"
const ENEMY_HEAD_CLEARANCE := 50.0
const DISPLAY_DURATION := 4.0
const ARROW_ALTERNATE_PERIOD := 0.26
const ARROW_SPREAD := 48.0
const ARROW_LENGTH := 30.0
const ARROW_WIDTH := 22.0
const TEXT_GAP_ABOVE_ARROWS := 38.0
const FONT_SIZE := 28
const OUTLINE_COLOR := Color(0.05, 0.04, 0.03, 0.95)
const TEXT_COLOR := Color(1.0, 0.98, 0.55, 1.0)
const LIT_COLOR := Color(1.0, 0.92, 0.45, 1.0)
const DIM_ARROW_COLOR := Color(0.34, 0.3, 0.26, 0.5)
const OUTLINE_SIZE := 4

var _enemy: CharacterBody2D
var _camera: Camera2D
var _time := 0.0
var _active := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = 115
	visible = false


func activate(enemy: CharacterBody2D, camera: Camera2D) -> void:
	_enemy = enemy
	_camera = camera
	_time = 0.0
	_active = true
	visible = true
	set_process(true)
	queue_redraw()


func deactivate() -> void:
	_active = false
	visible = false
	set_process(false)
	_enemy = null
	_camera = null


func _process(delta: float) -> void:
	if not _active:
		return

	_time += delta
	if _time >= DISPLAY_DURATION:
		deactivate()
		return

	if _enemy == null or not is_instance_valid(_enemy):
		deactivate()
		return

	if _enemy.has_method("is_active") and not _enemy.is_active():
		deactivate()
		return

	queue_redraw()


func _draw() -> void:
	if not _active or _enemy == null or _camera == null:
		return

	var world_anchor := _enemy.global_position + Vector2(0.0, -ENEMY_HEAD_CLEARANCE)
	var anchor := _world_to_screen(world_anchor)

	var arrow_phase := int(_time / ARROW_ALTERNATE_PERIOD) % 2
	_draw_direction_arrow(anchor + Vector2(-ARROW_SPREAD, 0.0), PI, arrow_phase == 0)
	_draw_direction_arrow(anchor + Vector2(ARROW_SPREAD, 0.0), 0.0, arrow_phase == 1)
	_draw_hint_text(anchor + Vector2(0.0, -TEXT_GAP_ABOVE_ARROWS))


func _draw_direction_arrow(pos: Vector2, angle: float, lit: bool) -> void:
	var color := LIT_COLOR if lit else DIM_ARROW_COLOR
	var tip := Vector2(ARROW_LENGTH * 0.5, 0.0)
	var wing_a := Vector2(-ARROW_LENGTH * 0.45, -ARROW_WIDTH * 0.5)
	var wing_b := Vector2(-ARROW_LENGTH * 0.45, ARROW_WIDTH * 0.5)
	var points := PackedVector2Array([
		pos + tip.rotated(angle),
		pos + wing_a.rotated(angle),
		pos + wing_b.rotated(angle),
	])
	draw_colored_polygon(points, color)


func _draw_hint_text(pos: Vector2) -> void:
	var font := ThemeDB.fallback_font
	var text_size := font.get_string_size(HINT_TEXT, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE)
	var line_pos := Vector2(pos.x - text_size.x * 0.5, pos.y - text_size.y)

	for ox in range(-OUTLINE_SIZE, OUTLINE_SIZE + 1):
		for oy in range(-OUTLINE_SIZE, OUTLINE_SIZE + 1):
			if ox == 0 and oy == 0:
				continue
			draw_string(
				font,
				line_pos + Vector2(ox, oy),
				HINT_TEXT,
				HORIZONTAL_ALIGNMENT_LEFT,
				-1,
				FONT_SIZE,
				OUTLINE_COLOR
			)

	draw_string(
		font,
		line_pos,
		HINT_TEXT,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		FONT_SIZE,
		TEXT_COLOR
	)


func _world_to_screen(world_pos: Vector2) -> Vector2:
	var viewport_size := get_viewport().get_visible_rect().size
	return (world_pos - _camera.get_screen_center_position()) * _camera.zoom + viewport_size * 0.5
