extends Node2D

const MAP_WIDTH := 3600.0
const FLOOR_Y := 820.0
const CEILING_Y := 120.0

var power_on := true
var diagnostics_complete := false
var _turbine_phase := 0.0
var _pump_phase := 0.0
var _belt_phase := 0.0
var _water_phase := 0.0
var _panel_phase := 0.0


func _ready() -> void:
	set_process(power_on)
	queue_redraw()


func set_power_on(on: bool) -> void:
	power_on = on
	set_process(on)
	queue_redraw()


func set_diagnostics_complete(complete: bool) -> void:
	diagnostics_complete = complete
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and is_visible_in_tree():
		queue_redraw()


func _process(delta: float) -> void:
	if not power_on:
		return
	_turbine_phase += delta * 2.4
	_pump_phase += delta * 3.6
	_belt_phase += delta * 90.0
	_water_phase += delta * 2.0
	_panel_phase += delta * 4.0
	queue_redraw()


func _draw() -> void:
	_draw_shell()
	if power_on:
		_draw_overhead_lights()
	_draw_floor()
	_draw_overhead_pipes()
	_draw_catwalks()
	_draw_main_turbine()
	_draw_aux_pump()
	_draw_conveyor()
	_draw_control_bay()
	_draw_broken_component()
	_draw_intake_channel()
	_draw_entrance_door()
	if not power_on:
		draw_rect(Rect2(0.0, CEILING_Y, MAP_WIDTH, FLOOR_Y - CEILING_Y), Color(0.0, 0.0, 0.0, 0.42))


func _draw_shell() -> void:
	var wall := Color(0.22, 0.21, 0.23) if power_on else Color(0.1, 0.095, 0.105)
	var trim := Color(0.28, 0.26, 0.28) if power_on else Color(0.14, 0.13, 0.14)
	draw_rect(Rect2(0.0, CEILING_Y, MAP_WIDTH, FLOOR_Y - CEILING_Y), wall)
	draw_rect(Rect2(0.0, CEILING_Y, MAP_WIDTH, 18.0), trim)
	draw_rect(Rect2(0.0, FLOOR_Y - 28.0, MAP_WIDTH, 28.0), trim.darkened(0.12))
	for i in 7:
		var pillar_x := 260.0 + i * 480.0
		draw_rect(Rect2(pillar_x, CEILING_Y + 24.0, 22.0, FLOOR_Y - CEILING_Y - 52.0), trim.darkened(0.08))


func _draw_overhead_lights() -> void:
	for i in 15:
		var x := 120.0 + i * 232.0
		_draw_light_fixture(x, 132.0)


func _draw_light_fixture(x: float, y: float) -> void:
	var housing := Color(0.34, 0.33, 0.36)
	var bulb := Color(0.98, 0.94, 0.78)
	draw_rect(Rect2(x - 34.0, y - 10.0, 68.0, 20.0), housing)
	draw_rect(Rect2(x - 28.0, y - 6.0, 56.0, 12.0), bulb)
	draw_rect(Rect2(x - 20.0, y - 2.0, 40.0, 4.0), Color(1.0, 1.0, 0.92))

	var pool_top := y + 18.0
	var pool_bottom := FLOOR_Y - 18.0
	var pool_half_w := 110.0
	var pool_color := Color(1.0, 0.96, 0.82, 0.11)
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(x - 18.0, pool_top),
			Vector2(x + 18.0, pool_top),
			Vector2(x + pool_half_w, pool_bottom),
			Vector2(x - pool_half_w, pool_bottom),
		]),
		pool_color
	)


func _draw_floor() -> void:
	var grate := Color(0.18, 0.17, 0.19) if power_on else Color(0.1, 0.095, 0.1)
	draw_rect(Rect2(0.0, FLOOR_Y - 8.0, MAP_WIDTH, 8.0), grate)
	var line_color := Color(0.26, 0.25, 0.27) if power_on else Color(0.14, 0.13, 0.14)
	for x in range(0, int(MAP_WIDTH), 48):
		draw_line(Vector2(x, FLOOR_Y - 8.0), Vector2(x + 24.0, FLOOR_Y), line_color, 2.0)


func _draw_overhead_pipes() -> void:
	var pipe := Color(0.34, 0.36, 0.38) if power_on else Color(0.2, 0.21, 0.22)
	for y in [170.0, 210.0]:
		draw_rect(Rect2(120.0, y, MAP_WIDTH - 240.0, 16.0), pipe)
	for x in [520.0, 1180.0, 1860.0, 2540.0, 3220.0]:
		draw_rect(Rect2(x, 170.0, 14.0, 56.0), pipe.darkened(0.08))


func _draw_catwalks() -> void:
	_draw_catwalk_segment(900.0, 700.0, 280.0)
	_draw_catwalk_segment(1400.0, 620.0, 240.0)
	_draw_catwalk_segment(2200.0, 540.0, 300.0)


func _draw_catwalk_segment(center_x: float, surface_y: float, width: float) -> void:
	var rail := Color(0.38, 0.37, 0.4) if power_on else Color(0.22, 0.21, 0.23)
	var deck := Color(0.3, 0.29, 0.32) if power_on else Color(0.16, 0.15, 0.17)
	var left := center_x - width * 0.5
	draw_rect(Rect2(left, surface_y - 10.0, width, 10.0), deck)
	draw_rect(Rect2(left, surface_y - 28.0, 6.0, 18.0), rail)
	draw_rect(Rect2(left + width - 6.0, surface_y - 28.0, 6.0, 18.0), rail)
	for x in range(int(left + 18.0), int(left + width - 18.0), 28):
		draw_line(Vector2(x, surface_y - 28.0), Vector2(x, surface_y - 10.0), rail.lightened(0.05), 2.0)


func _draw_main_turbine() -> void:
	var center := Vector2(980.0, FLOOR_Y - 120.0)
	var metal := Color(0.32, 0.34, 0.36) if power_on else Color(0.2, 0.21, 0.22)
	draw_rect(Rect2(center.x - 110.0, center.y - 150.0, 220.0, 150.0), metal.darkened(0.12))
	draw_circle(center, 78.0, metal)
	draw_circle(center, 52.0, metal.lightened(0.06))
	var blade_count := 5
	for i in blade_count:
		var angle := (i * TAU / blade_count) + (_turbine_phase if power_on else 0.0)
		var end := center + Vector2(cos(angle), sin(angle)) * 72.0
		draw_line(center, end, metal.lightened(0.12 if power_on else 0.02), 5.0)
	var status := "MAIN TURBINE — ONLINE" if power_on else "MAIN TURBINE — OFFLINE"
	var status_color := Color(0.55, 0.95, 0.62) if power_on else Color(0.45, 0.46, 0.48)
	draw_string(
		ThemeDB.fallback_font,
		Vector2(center.x - 92.0, center.y + 118.0),
		status,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		18,
		status_color
	)


func _draw_aux_pump() -> void:
	var center := Vector2(2380.0, FLOOR_Y - 96.0)
	var metal := Color(0.3, 0.32, 0.34) if power_on else Color(0.18, 0.19, 0.2)
	draw_rect(Rect2(center.x - 54.0, center.y - 72.0, 108.0, 72.0), metal.darkened(0.1))
	draw_circle(center, 34.0, metal)
	for i in 3:
		var angle := (i * TAU / 3.0) + (_pump_phase if power_on else 0.0)
		var end := center + Vector2(cos(angle), sin(angle)) * 28.0
		draw_line(center, end, metal.lightened(0.1 if power_on else 0.0), 4.0)
	draw_rect(Rect2(center.x - 18.0, center.y + 34.0, 36.0, 48.0), metal.darkened(0.08))


func _draw_conveyor() -> void:
	var belt_x := 1240.0
	var belt_y := FLOOR_Y - 54.0
	var belt_w := 320.0
	var belt := Color(0.24, 0.23, 0.25) if power_on else Color(0.14, 0.13, 0.14)
	draw_rect(Rect2(belt_x, belt_y, belt_w, 18.0), belt)
	for i in 11:
		var stripe_x := belt_x + 8.0 + i * 28.0
		var offset := fmod(_belt_phase + i * 14.0, 28.0) if power_on else 0.0
		draw_rect(Rect2(stripe_x + offset - 28.0, belt_y + 3.0, 10.0, 12.0), belt.lightened(0.08))


func _draw_control_bay() -> void:
	var panel_x := 430.0
	var panel_y := FLOOR_Y - 170.0
	draw_rect(Rect2(panel_x, panel_y, 180.0, 170.0), Color(0.26, 0.25, 0.28) if power_on else Color(0.14, 0.13, 0.15))
	var screen := Color(0.1, 0.12, 0.14) if power_on else Color(0.05, 0.05, 0.06)
	if not power_on and not diagnostics_complete:
		screen = Color(0.06, 0.07, 0.08)
	draw_rect(Rect2(panel_x + 14.0, panel_y + 18.0, 152.0, 92.0), screen)
	if not power_on and not diagnostics_complete:
		_draw_diagnostic_grid(panel_x + 20.0, panel_y + 24.0)
	elif not power_on and diagnostics_complete:
		draw_string(
			ThemeDB.fallback_font,
			Vector2(panel_x + 22.0, panel_y + 58.0),
			"FAULT LOG",
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			16,
			Color(0.52, 0.58, 0.62)
		)
		draw_string(
			ThemeDB.fallback_font,
			Vector2(panel_x + 22.0, panel_y + 78.0),
			"REPAIRS REQ.",
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			14,
			Color(0.42, 0.46, 0.48)
		)
	for i in 6:
		var lamp_x := panel_x + 24.0 + (i % 3) * 44.0
		var lamp_y := panel_y + 130.0 + floori(i / 3.0) * 18.0
		var lamp_color := Color(0.15, 0.16, 0.18)
		if power_on:
			var blink := sin(_panel_phase + i * 0.8) > 0.0
			lamp_color = Color(0.35, 0.92, 0.45) if blink else Color(0.18, 0.55, 0.28)
		draw_circle(Vector2(lamp_x, lamp_y), 5.0, lamp_color)


func _draw_diagnostic_grid(origin_x: float, origin_y: float) -> void:
	const GRID := 3
	var preview: Array[int] = [1, 4, 7, 2, 0, 8, 3, 5, 6]
	var cell := 22.0
	var gap := 2.0
	var tile_colors: Array[Color] = [
		Color(0.22, 0.21, 0.23),
		Color(0.26, 0.25, 0.27),
		Color(0.2, 0.22, 0.24),
	]
	for row in GRID:
		for col in GRID:
			var index: int = row * GRID + col
			var value: int = preview[index]
			var x := origin_x + col * (cell + gap)
			var y := origin_y + row * (cell + gap)
			if value == 0:
				draw_rect(Rect2(x, y, cell, cell), Color(0.07, 0.065, 0.06))
				continue
			draw_rect(Rect2(x, y, cell, cell), tile_colors[(value - 1) % tile_colors.size()])
			draw_string(
				ThemeDB.fallback_font,
				Vector2(x + 6.0, y + 16.0),
				str(value),
				HORIZONTAL_ALIGNMENT_LEFT,
				-1,
				11,
				Color(0.62, 0.64, 0.68)
			)


func _draw_broken_component() -> void:
	var base := Vector2(1680.0, FLOOR_Y - 48.0)
	draw_rect(Rect2(base.x - 70.0, base.y - 88.0, 140.0, 88.0), Color(0.32, 0.3, 0.28) if power_on else Color(0.18, 0.17, 0.16))
	draw_rect(Rect2(base.x - 42.0, base.y - 118.0, 84.0, 30.0), Color(0.24, 0.22, 0.2) if power_on else Color(0.12, 0.11, 0.1))
	if not power_on:
		var char_color := Color(0.42, 0.4, 0.38)
		draw_line(base + Vector2(-8.0, -102.0), base + Vector2(28.0, -88.0), char_color, 2.0)
		draw_string(
			ThemeDB.fallback_font,
			Vector2(base.x - 110.0, base.y + 24.0),
			"Relay bank failed — tenth replacement this month.",
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			16,
			Color(0.48, 0.44, 0.4)
		)


func _draw_intake_channel() -> void:
	var channel_x := 2580.0
	if power_on:
		var basin := Color(0.18, 0.22, 0.24)
		var water_deep := Color(0.14, 0.34, 0.44, 0.95)
		var water_shallow := Color(0.2, 0.48, 0.58, 0.88)
		draw_rect(Rect2(channel_x, FLOOR_Y - 120.0, 760.0, 120.0), basin)
		draw_rect(Rect2(channel_x + 40.0, FLOOR_Y - 92.0, 680.0, 64.0), water_deep)
		for i in 10:
			var stripe_x := channel_x + 60.0 + i * 62.0
			var wave := sin(_water_phase + i * 0.7) * 3.0
			draw_rect(
				Rect2(stripe_x, FLOOR_Y - 86.0 + wave, 34.0, 8.0),
				water_shallow
			)
		draw_string(
			ThemeDB.fallback_font,
			Vector2(channel_x + 48.0, FLOOR_Y - 132.0),
			"RIVER INTAKE — FLOW OK",
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			20,
			Color(0.62, 0.88, 0.78)
		)
	else:
		draw_rect(Rect2(channel_x, FLOOR_Y - 120.0, 760.0, 120.0), Color(0.12, 0.11, 0.1))
		draw_rect(Rect2(channel_x + 40.0, FLOOR_Y - 92.0, 680.0, 64.0), Color(0.08, 0.07, 0.06))
		for i in 8:
			var crack_x := channel_x + 80.0 + i * 78.0
			draw_line(
				Vector2(crack_x, FLOOR_Y - 88.0),
				Vector2(crack_x + 18.0, FLOOR_Y - 36.0),
				Color(0.06, 0.05, 0.04),
				2.0
			)
		draw_string(
			ThemeDB.fallback_font,
			Vector2(channel_x + 48.0, FLOOR_Y - 132.0),
			"RIVER INTAKE — NO FLOW",
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			20,
			Color(0.4, 0.38, 0.34)
		)


func _draw_entrance_door() -> void:
	var door_x := 96.0
	var door_top := FLOOR_Y - 132.0
	var frame := Color(0.18, 0.16, 0.14) if power_on else Color(0.1, 0.09, 0.08)
	var door := Color(0.12, 0.11, 0.1) if power_on else Color(0.06, 0.05, 0.05)
	draw_rect(Rect2(door_x, door_top, 72.0, 132.0), frame)
	draw_rect(Rect2(door_x + 8.0, door_top + 12.0, 56.0, 108.0), door)
	draw_line(Vector2(door_x + 36.0, door_top + 18.0), Vector2(door_x + 36.0, door_top + 114.0), frame.lightened(0.08), 2.0)
