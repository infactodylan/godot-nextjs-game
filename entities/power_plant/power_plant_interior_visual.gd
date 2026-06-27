extends Node2D

const MAP_WIDTH := 3600.0
const FLOOR_Y := 820.0
const CEILING_Y := 120.0

var _spark_phase := 0.0


func _ready() -> void:
	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	_spark_phase += delta * 9.0
	queue_redraw()


func _draw() -> void:
	_draw_shell()
	_draw_floor()
	_draw_overhead_pipes()
	_draw_catwalks()
	_draw_main_turbine()
	_draw_control_bay()
	_draw_broken_component()
	_draw_dry_intake()
	_draw_entrance_door()


func _draw_shell() -> void:
	var wall := Color(0.18, 0.17, 0.19)
	var trim := Color(0.24, 0.22, 0.24)
	draw_rect(Rect2(0.0, CEILING_Y, MAP_WIDTH, FLOOR_Y - CEILING_Y), wall)
	draw_rect(Rect2(0.0, CEILING_Y, MAP_WIDTH, 18.0), trim)
	draw_rect(Rect2(0.0, FLOOR_Y - 28.0, MAP_WIDTH, 28.0), trim.darkened(0.12))
	for i in 7:
		var pillar_x := 260.0 + i * 480.0
		draw_rect(Rect2(pillar_x, CEILING_Y + 24.0, 22.0, FLOOR_Y - CEILING_Y - 52.0), trim.darkened(0.08))


func _draw_floor() -> void:
	var grate := Color(0.14, 0.13, 0.15)
	draw_rect(Rect2(0.0, FLOOR_Y - 8.0, MAP_WIDTH, 8.0), grate)
	for x in range(0, int(MAP_WIDTH), 48):
		draw_line(Vector2(x, FLOOR_Y - 8.0), Vector2(x + 24.0, FLOOR_Y), Color(0.2, 0.19, 0.21), 2.0)


func _draw_overhead_pipes() -> void:
	var pipe := Color(0.3, 0.32, 0.34)
	for y in [170.0, 210.0]:
		draw_rect(Rect2(120.0, y, MAP_WIDTH - 240.0, 16.0), pipe)
	for x in [520.0, 1180.0, 1860.0, 2540.0, 3220.0]:
		draw_rect(Rect2(x, 170.0, 14.0, 56.0), pipe.darkened(0.08))


func _draw_catwalks() -> void:
	_draw_catwalk_segment(900.0, 700.0, 280.0)
	_draw_catwalk_segment(1400.0, 620.0, 240.0)
	_draw_catwalk_segment(2200.0, 540.0, 300.0)


func _draw_catwalk_segment(center_x: float, surface_y: float, width: float) -> void:
	var rail := Color(0.34, 0.33, 0.36)
	var deck := Color(0.26, 0.25, 0.28)
	var left := center_x - width * 0.5
	draw_rect(Rect2(left, surface_y - 10.0, width, 10.0), deck)
	draw_rect(Rect2(left, surface_y - 28.0, 6.0, 18.0), rail)
	draw_rect(Rect2(left + width - 6.0, surface_y - 28.0, 6.0, 18.0), rail)
	for x in range(int(left + 18.0), int(left + width - 18.0), 28):
		draw_line(Vector2(x, surface_y - 28.0), Vector2(x, surface_y - 10.0), rail.lightened(0.05), 2.0)


func _draw_main_turbine() -> void:
	var center := Vector2(980.0, FLOOR_Y - 120.0)
	var metal := Color(0.28, 0.3, 0.32)
	draw_rect(Rect2(center.x - 110.0, center.y - 150.0, 220.0, 150.0), metal.darkened(0.12))
	draw_circle(center, 78.0, metal)
	draw_circle(center, 52.0, metal.lightened(0.06))
	for i in 5:
		var angle := i * TAU / 5.0
		var end := center + Vector2(cos(angle), sin(angle)) * 72.0
		draw_line(center, end, metal.lightened(0.1), 5.0)
	draw_string(
		ThemeDB.fallback_font,
		Vector2(center.x - 92.0, center.y + 118.0),
		"MAIN TURBINE — OFFLINE",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		18,
		Color(0.72, 0.74, 0.78)
	)


func _draw_control_bay() -> void:
	var panel_x := 430.0
	var panel_y := FLOOR_Y - 170.0
	draw_rect(Rect2(panel_x, panel_y, 180.0, 170.0), Color(0.22, 0.21, 0.24))
	draw_rect(Rect2(panel_x + 14.0, panel_y + 18.0, 152.0, 92.0), Color(0.08, 0.1, 0.12))
	for i in 6:
		var lamp_x := panel_x + 24.0 + (i % 3) * 44.0
		var lamp_y := panel_y + 130.0 + floori(i / 3.0) * 18.0
		var lamp_color := Color(0.85, 0.2, 0.18) if i < 4 else Color(0.15, 0.16, 0.18)
		draw_circle(Vector2(lamp_x, lamp_y), 5.0, lamp_color)


func _draw_broken_component() -> void:
	var base := Vector2(1680.0, FLOOR_Y - 48.0)
	draw_rect(Rect2(base.x - 70.0, base.y - 88.0, 140.0, 88.0), Color(0.3, 0.28, 0.26))
	draw_rect(Rect2(base.x - 42.0, base.y - 118.0, 84.0, 30.0), Color(0.22, 0.2, 0.18))
	var spark_strength := 0.55 + sin(_spark_phase) * 0.45
	var spark := Color(0.95, 0.72, 0.2, spark_strength)
	draw_circle(base + Vector2(18.0, -96.0), 8.0 + spark_strength * 4.0, spark)
	draw_line(base + Vector2(10.0, -102.0), base + Vector2(34.0, -88.0), spark, 2.0)
	draw_string(
		ThemeDB.fallback_font,
		Vector2(base.x - 110.0, base.y + 24.0),
		"Relay bank failed — tenth replacement this month.",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		16,
		Color(0.78, 0.72, 0.58)
	)


func _draw_dry_intake() -> void:
	var channel_x := 2580.0
	draw_rect(Rect2(channel_x, FLOOR_Y - 120.0, 760.0, 120.0), Color(0.16, 0.14, 0.13))
	draw_rect(Rect2(channel_x + 40.0, FLOOR_Y - 92.0, 680.0, 64.0), Color(0.11, 0.1, 0.09))
	for i in 8:
		var crack_x := channel_x + 80.0 + i * 78.0
		draw_line(
			Vector2(crack_x, FLOOR_Y - 88.0),
			Vector2(crack_x + 18.0, FLOOR_Y - 36.0),
			Color(0.07, 0.06, 0.05),
			2.0
		)
	draw_string(
		ThemeDB.fallback_font,
		Vector2(channel_x + 48.0, FLOOR_Y - 132.0),
		"RIVER INTAKE — NO FLOW",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		20,
		Color(0.62, 0.58, 0.52)
	)


func _draw_entrance_door() -> void:
	var door_x := 96.0
	var door_top := FLOOR_Y - 132.0
	draw_rect(Rect2(door_x, door_top, 72.0, 132.0), Color(0.14, 0.12, 0.1, 0.95))
	draw_rect(Rect2(door_x + 8.0, door_top + 12.0, 56.0, 108.0), Color(0.08, 0.07, 0.06))
	draw_line(Vector2(door_x + 36.0, door_top + 18.0), Vector2(door_x + 36.0, door_top + 114.0), Color(0.2, 0.18, 0.16), 2.0)
