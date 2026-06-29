extends Node2D

const MAP_WIDTH := 3200.0
const MAP_HEIGHT := 2000.0
const HORIZONTAL_FLOOR_Y := 1680.0
const TUNNEL_FLOOR_SURFACE_OFFSET := 8.0
const TUNNEL_WALK_CLEARANCE := 88.0
const TUNNEL_CEILING_THICKNESS := 24.0

const MAZE_CEILING_SPECS: Array[Dictionary] = [
	{"floor_y": 240.0, "center_x": 460.0, "width": 760.0},
	{"floor_y": 460.0, "center_x": 700.0, "width": 1240.0},
	{"floor_y": 660.0, "center_x": 700.0, "width": 1240.0},
	{"floor_y": 860.0, "center_x": 900.0, "width": 1640.0},
	{"floor_y": 1060.0, "center_x": 700.0, "width": 1240.0},
	{"floor_y": 1260.0, "center_x": 220.0, "width": 280.0},
	{"floor_y": 1260.0, "center_x": 1180.0, "width": 280.0},
	{"floor_y": 1460.0, "center_x": 300.0, "width": 440.0},
	{"floor_y": 1460.0, "center_x": 1100.0, "width": 440.0},
]

const FLOOR_PITS: Array[Dictionary] = [
	{"left": 420.0, "right": 520.0, "floor_y": 240.0},
	{"left": 400.0, "right": 600.0, "floor_y": 660.0},
	{"left": 800.0, "right": 920.0, "floor_y": 660.0},
	{"left": 420.0, "right": 560.0, "floor_y": 860.0},
	{"left": 800.0, "right": 920.0, "floor_y": 860.0},
	{"left": 1280.0, "right": 1380.0, "floor_y": 860.0},
	{"left": 360.0, "right": 480.0, "floor_y": 1060.0},
	{"left": 840.0, "right": 960.0, "floor_y": 1060.0},
	{"left": 1200.0, "right": 1320.0, "floor_y": 1060.0},
]

const BASE_FLOOR_GAPS: Array[Dictionary] = [
	{"left": 360.0, "right": 520.0},
	{"left": 1290.0, "right": 1450.0},
	{"left": 1900.0, "right": 2060.0},
	{"left": 2440.0, "right": 2580.0},
]

const DROP_SHAFTS: Array[Dictionary] = [
	# Left-side descents
	{"left": 140.0, "right": 220.0, "top": 250.0, "bottom": 460.0},
	{"left": 140.0, "right": 220.0, "top": 670.0, "bottom": 860.0},
	{"left": 140.0, "right": 220.0, "top": 870.0, "bottom": 1060.0},
	{"left": 140.0, "right": 220.0, "top": 1070.0, "bottom": 1260.0},
	{"left": 280.0, "right": 360.0, "top": 1270.0, "bottom": 1460.0},
	{"left": 140.0, "right": 220.0, "top": 1470.0, "bottom": 1680.0},
	# Right-side descents
	{"left": 1280.0, "right": 1360.0, "top": 470.0, "bottom": 660.0},
	{"left": 1120.0, "right": 1200.0, "top": 1070.0, "bottom": 1260.0},
	{"left": 960.0, "right": 1040.0, "top": 1270.0, "bottom": 1460.0},
	{"left": 1120.0, "right": 1200.0, "top": 1470.0, "bottom": 1680.0},
]

const LADDERS: Array[Dictionary] = [
	{"x": 180.0, "top": 670.0, "bottom": 860.0},
	{"x": 180.0, "top": 870.0, "bottom": 1060.0},
	{"x": 180.0, "top": 1070.0, "bottom": 1460.0},
	{"x": 1160.0, "top": 1070.0, "bottom": 1460.0},
]

const SIDE_BOUNDARY_WALLS: Array[Dictionary] = [
	{"left": 44.0, "right": 68.0, "top": 30.0, "bottom": 1890.0},
	{"left": 1378.0, "right": 1402.0, "top": 40.0, "bottom": 460.0},
	{"left": 1378.0, "right": 1402.0, "top": 670.0, "bottom": 1050.0},
	{"left": 1378.0, "right": 1402.0, "top": 1060.0, "bottom": 1260.0},
	{"left": 1648.0, "right": 1672.0, "top": 730.0, "bottom": 990.0},
	{"left": 1276.0, "right": 1300.0, "top": 1100.0, "bottom": 1620.0},
	{"left": 368.0, "right": 392.0, "top": 1100.0, "bottom": 1620.0},
	{"left": 980.0, "right": 1004.0, "top": 1420.0, "bottom": 1760.0},
	{"left": 3136.0, "right": 3160.0, "top": 1420.0, "bottom": 1760.0},
]

var emergency_power := false
var _drip_phase := 0.0


func _ready() -> void:
	set_process(true)
	queue_redraw()


func set_emergency_power(on: bool) -> void:
	emergency_power = on
	queue_redraw()


func _process(delta: float) -> void:
	_drip_phase += delta
	queue_redraw()


func _draw() -> void:
	var bg := Color(0.08, 0.11, 0.16) if not emergency_power else Color(0.1, 0.13, 0.18)
	draw_rect(Rect2(0.0, 0.0, MAP_WIDTH, MAP_HEIGHT), bg)

	_draw_maze_tunnels()
	_draw_side_walls()
	_draw_drop_shafts()
	_draw_ladders()
	_draw_landmarks()
	_draw_pits()
	_draw_base_tunnel()

	if emergency_power:
		for i in 6:
			var lx := 260.0 + i * 520.0
			draw_circle(Vector2(lx, 140.0 + (i % 2) * 40.0), 24.0, Color(0.9, 0.75, 0.2, 0.1))

	if not emergency_power:
		draw_rect(Rect2(0.0, 0.0, MAP_WIDTH, MAP_HEIGHT), Color(0.0, 0.0, 0.0, 0.28))


func _tunnel_ceiling_y(floor_y: float) -> float:
	return (
		floor_y
		- TUNNEL_FLOOR_SURFACE_OFFSET
		- TUNNEL_WALK_CLEARANCE
		- TUNNEL_CEILING_THICKNESS * 0.5
	)


func _tunnel_ceiling_top(floor_y: float) -> float:
	return _tunnel_ceiling_y(floor_y) - TUNNEL_CEILING_THICKNESS * 0.5


func _tunnel_floor_surface(floor_y: float) -> float:
	return floor_y - TUNNEL_FLOOR_SURFACE_OFFSET


func _draw_maze_tunnels() -> void:
	draw_string(
		ThemeDB.fallback_font,
		Vector2(560.0, 120.0),
		"BASEMENT MAZE — DESCEND TO THE EMERGENCY BATTERY",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		16,
		Color(0.55, 0.5, 0.45)
	)

	for spec in MAZE_CEILING_SPECS:
		var floor_y: float = spec["floor_y"]
		var ceiling_top := _tunnel_ceiling_top(floor_y)
		var floor_surface := _tunnel_floor_surface(floor_y)
		var tunnel_h := floor_surface - ceiling_top
		var tunnel_left: float = spec["center_x"] - spec["width"] * 0.5
		draw_rect(
			Rect2(tunnel_left, ceiling_top, spec["width"], tunnel_h),
			Color(0.72, 0.66, 0.54, 0.35)
		)
		draw_rect(
			Rect2(tunnel_left, ceiling_top, spec["width"], 6.0),
			Color(0.55, 0.5, 0.44)
		)


func _draw_side_walls() -> void:
	for wall in SIDE_BOUNDARY_WALLS:
		draw_rect(
			Rect2(
				wall["left"],
				wall["top"],
				wall["right"] - wall["left"],
				wall["bottom"] - wall["top"]
			),
			Color(0.55, 0.5, 0.44, 0.85)
		)


func _draw_drop_shafts() -> void:
	for shaft in DROP_SHAFTS:
		var rect := Rect2(
			shaft["left"],
			shaft["top"],
			shaft["right"] - shaft["left"],
			shaft["bottom"] - shaft["top"]
		)
		draw_rect(rect, Color(0.05, 0.07, 0.1))
		draw_rect(
			Rect2(shaft["left"], shaft["top"], 6.0, rect.size.y),
			Color(0.55, 0.5, 0.44)
		)
		draw_rect(
			Rect2(shaft["right"] - 6.0, shaft["top"], 6.0, rect.size.y),
			Color(0.55, 0.5, 0.44)
		)


func _draw_ladders() -> void:
	for ladder in LADDERS:
		var top: float = ladder["top"]
		var bottom: float = ladder["bottom"]
		var x: float = ladder["x"]
		var rung_count := int((bottom - top) / 18.0)
		for i in rung_count:
			var rung_y := top + 12.0 + i * 18.0
			draw_line(Vector2(x - 10.0, rung_y), Vector2(x + 10.0, rung_y), Color(0.9, 0.9, 0.85, 0.55), 2.0)
		draw_line(Vector2(x - 12.0, top), Vector2(x - 12.0, bottom), Color(0.55, 0.5, 0.44), 3.0)
		draw_line(Vector2(x + 12.0, top), Vector2(x + 12.0, bottom), Color(0.55, 0.5, 0.44), 3.0)


func _draw_landmarks() -> void:
	draw_rect(Rect2(708.0, 196.0, 24.0, 24.0), Color(0.55, 0.35, 0.75, 0.85))
	draw_rect(Rect2(596.0, 228.0, 88.0, 10.0), Color(0.2, 0.72, 0.68, 0.9))
	draw_rect(Rect2(688.0, 648.0, 120.0, 12.0), Color(0.9, 0.55, 0.2, 0.9))
	draw_rect(Rect2(660.0, 848.0, 80.0, 10.0), Color(0.65, 0.5, 0.85, 0.85))
	draw_rect(Rect2(2480.0, 1620.0, 20.0, 48.0), Color(0.3, 0.75, 0.45, 0.85))


func _draw_pits() -> void:
	for pit in FLOOR_PITS:
		var floor_y: float = pit["floor_y"]
		_draw_pit_rect(pit["left"], pit["right"], floor_y)
	for gap in BASE_FLOOR_GAPS:
		_draw_pit_rect(gap["left"], gap["right"], HORIZONTAL_FLOOR_Y)


func _draw_pit_rect(left: float, right: float, floor_y: float) -> void:
	var pit_rect := Rect2(left, floor_y - 8.0, right - left, MAP_HEIGHT - floor_y + 40.0)
	draw_rect(pit_rect, Color(0.04, 0.05, 0.08))
	for i in 4:
		var spike_x := left + 16.0 + i * ((right - left) / 5.0)
		var base_y := floor_y - 4.0
		draw_colored_polygon(
			PackedVector2Array([
				Vector2(spike_x - 8.0, base_y),
				Vector2(spike_x + 8.0, base_y),
				Vector2(spike_x, base_y - 14.0),
			]),
			Color(0.55, 0.5, 0.44, 0.75)
		)


func _draw_base_tunnel() -> void:
	var ceiling_top := _tunnel_ceiling_top(HORIZONTAL_FLOOR_Y)
	var floor_surface := _tunnel_floor_surface(HORIZONTAL_FLOOR_Y)
	var tunnel_h := floor_surface - ceiling_top
	draw_rect(Rect2(980.0, ceiling_top, 2100.0, tunnel_h), Color(0.72, 0.66, 0.54, 0.35))
	draw_rect(Rect2(980.0, ceiling_top, 2100.0, 6.0), Color(0.55, 0.5, 0.44))

	draw_string(
		ThemeDB.fallback_font,
		Vector2(1280.0, ceiling_top + 28.0),
		"LOWER TUNNEL — JUMP THE PITS — BATTERY AHEAD",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		18,
		Color(0.55, 0.5, 0.45) if not emergency_power else Color(0.85, 0.75, 0.25)
	)

	var switch_x := 2900.0
	draw_arc(Vector2(switch_x, HORIZONTAL_FLOOR_Y - 48.0), 36.0, PI, TAU, 16, Color(0.35, 0.55, 0.85, 0.9), 6.0)
	draw_rect(Rect2(switch_x - 60.0, HORIZONTAL_FLOOR_Y - 96.0, 120.0, 88.0), Color(0.18, 0.16, 0.14))
	draw_string(
		ThemeDB.fallback_font,
		Vector2(switch_x - 52.0, HORIZONTAL_FLOOR_Y - 36.0),
		"BATTERY",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		16,
		Color(0.85, 0.75, 0.25) if emergency_power else Color(0.5, 0.46, 0.4)
	)
