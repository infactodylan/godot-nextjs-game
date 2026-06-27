extends Node2D

const HALF_W := 130.0
const HEIGHT := 168.0
const WATER_TOP := 6.0
const WATER_DEPTH := 28.0

var _rng := RandomNumberGenerator.new()
var _water_phase := 0.0
var _turbine_phase := 0.0
var lights_on := true
var light_brightness := 1.0


func _ready() -> void:
	add_to_group("village_lit_building")
	_rng.seed = 9001
	set_process(true)
	queue_redraw()


func set_light_brightness(brightness: float) -> void:
	light_brightness = clampf(brightness, 0.0, 1.0)
	lights_on = light_brightness > 0.01
	queue_redraw()


func set_lights_on(on: bool) -> void:
	set_light_brightness(1.0 if on else 0.0)


func _process(delta: float) -> void:
	_water_phase += delta * 1.6
	if light_brightness > 0.01:
		_turbine_phase += delta * 1.6 * light_brightness
	queue_redraw()


func _draw() -> void:
	_draw_river_channel()
	_draw_plant()
	_draw_intake_pipes()
	_draw_ground_line()


func _draw_river_channel() -> void:
	var channel_left := -360.0
	var channel_right := HALF_W + 40.0
	var channel_w := channel_right - channel_left
	var bank := Color(0.24, 0.2, 0.16)
	var water_deep := Color(0.12, 0.28, 0.38, 0.95)
	var water_shallow := Color(0.18, 0.42, 0.52, 0.88)

	draw_rect(Rect2(channel_left - 8.0, WATER_TOP - 4.0, channel_w + 16.0, WATER_DEPTH + 10.0), bank)
	draw_rect(Rect2(channel_left, WATER_TOP, channel_w, WATER_DEPTH), water_deep)

	for i in 8:
		var stripe_x := channel_left + 20.0 + i * (channel_w / 8.0)
		var wave := sin(_water_phase + i * 0.9) * 2.0
		draw_rect(
			Rect2(stripe_x, WATER_TOP + 4.0 + wave, channel_w / 10.0, 6.0),
			water_shallow
		)

	for i in 5:
		var rx := channel_left + _rng.randf_range(24.0, channel_w - 24.0)
		draw_circle(Vector2(rx, WATER_TOP + WATER_DEPTH * 0.55), _rng.randf_range(1.5, 3.0), Color(0.28, 0.55, 0.62, 0.35))


func _draw_plant() -> void:
	var wall := Color(0.34, 0.32, 0.3)
	var concrete := Color(0.4, 0.38, 0.36)
	var metal := Color(0.28, 0.3, 0.32)
	var roof_y := -HEIGHT

	draw_rect(Rect2(-HALF_W + 6.0, roof_y, HALF_W * 2.0 - 12.0, HEIGHT - 8.0), wall)
	draw_rect(Rect2(-HALF_W + 10.0, roof_y + 12.0, HALF_W * 2.0 - 20.0, 14.0), concrete)

	draw_rect(Rect2(-48.0, roof_y - 34.0, 96.0, 34.0), metal.darkened(0.1))
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-56.0, roof_y - 34.0),
			Vector2(0.0, roof_y - 58.0),
			Vector2(56.0, roof_y - 34.0),
		]),
		metal
	)

	draw_rect(Rect2(HALF_W - 28.0, roof_y - 92.0, 18.0, 92.0), Color(0.22, 0.2, 0.19))
	draw_rect(Rect2(HALF_W - 24.0, roof_y - 98.0, 10.0, 8.0), Color(0.16, 0.14, 0.13))

	draw_rect(Rect2(-HALF_W + 18.0, roof_y + 36.0, 52.0, 72.0), Color(0.16, 0.14, 0.12, 0.92))
	_draw_lit_window(-HALF_W + 24.0, roof_y + 44.0, 18.0, 20.0)
	_draw_lit_window(-HALF_W + 46.0, roof_y + 44.0, 18.0, 20.0)
	_draw_lit_window(-HALF_W + 24.0, roof_y + 72.0, 18.0, 20.0)
	_draw_lit_window(-HALF_W + 46.0, roof_y + 72.0, 18.0, 20.0)

	_draw_lit_window(8.0, roof_y + 44.0, 22.0, 24.0)
	_draw_lit_window(38.0, roof_y + 44.0, 22.0, 24.0)
	_draw_lit_window(68.0, roof_y + 44.0, 22.0, 24.0)

	draw_rect(Rect2(-18.0, roof_y + 88.0, 36.0, 52.0), Color(0.14, 0.1, 0.08, 0.95))

	var turbine_x := HALF_W - 54.0
	draw_circle(Vector2(turbine_x, roof_y + 78.0), 22.0, metal)
	draw_circle(Vector2(turbine_x, roof_y + 78.0), 14.0, metal.lightened(0.08))
	for i in 4:
		var angle := _turbine_phase * 0.8 + i * TAU / 4.0
		var end := Vector2(turbine_x + cos(angle) * 18.0, roof_y + 78.0 + sin(angle) * 18.0)
		draw_line(Vector2(turbine_x, roof_y + 78.0), end, metal.lightened(0.12), 3.0)


func _draw_intake_pipes() -> void:
	var pipe := Color(0.3, 0.32, 0.34)
	var pipe_y := WATER_TOP + 8.0
	draw_rect(Rect2(-HALF_W + 8.0, pipe_y, HALF_W - 20.0, 12.0), pipe)
	draw_rect(Rect2(-HALF_W + 8.0, pipe_y - 18.0, 12.0, 18.0), pipe.darkened(0.08))
	draw_rect(Rect2(-20.0, pipe_y, 14.0, 10.0), pipe.lightened(0.06))


func _draw_ground_line() -> void:
	draw_line(Vector2(-380.0, 0.0), Vector2(HALF_W + 60.0, 0.0), Color(0.14, 0.12, 0.1, 0.55), 2.0)


func _draw_lit_window(x: float, y: float, w: float, h: float) -> void:
	var frame := Color(0.2, 0.18, 0.16)
	if light_brightness <= 0.01:
		draw_rect(Rect2(x, y, w, h), Color(0.05, 0.04, 0.04, 0.95))
		draw_rect(Rect2(x, y, w, 2.0), frame)
		draw_rect(Rect2(x, y + h - 2.0, w, 2.0), frame)
		draw_rect(Rect2(x, y, 2.0, h), frame)
		draw_rect(Rect2(x + w - 2.0, y, 2.0, h), frame)
		return
	var glow := Color(0.95, 0.72, 0.32, 0.88 * light_brightness)
	var halo := Color(0.85, 0.55, 0.18, 0.28 * light_brightness)
	draw_rect(Rect2(x - 3.0, y - 3.0, w + 6.0, h + 6.0), halo)
	draw_rect(Rect2(x, y, w, h), glow)
	draw_rect(Rect2(x, y, w, 2.0), frame)
	draw_rect(Rect2(x, y + h - 2.0, w, 2.0), frame)
	draw_rect(Rect2(x, y, 2.0, h), frame)
	draw_rect(Rect2(x + w - 2.0, y, 2.0, h), frame)
