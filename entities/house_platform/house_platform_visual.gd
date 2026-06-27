extends Node2D
class_name HousePlatformVisual

enum HouseType { COTTAGE, HOUSE, TALL_HOUSE, COURTHOUSE, BARN, SILO }

@export var house_type: HouseType = HouseType.COTTAGE
@export var color_seed: int = 0

var lights_on := true
var light_brightness := 1.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	add_to_group("village_lit_building")
	_rng.seed = color_seed if color_seed != 0 else hash(str(get_parent().name))
	queue_redraw()


func set_light_brightness(brightness: float) -> void:
	light_brightness = clampf(brightness, 0.0, 1.0)
	lights_on = light_brightness > 0.01
	queue_redraw()


func set_lights_on(on: bool) -> void:
	set_light_brightness(1.0 if on else 0.0)


func _draw() -> void:
	var hw := _half_width()
	draw_line(Vector2(-hw - 40.0, 0.0), Vector2(hw + 40.0, 0.0), Color(0.14, 0.12, 0.1, 0.55), 2.0)
	_draw_rubble_base()
	match house_type:
		HouseType.COTTAGE:
			_draw_cottage()
		HouseType.HOUSE:
			_draw_house()
		HouseType.TALL_HOUSE:
			_draw_tall_house()
		HouseType.COURTHOUSE:
			_draw_courthouse()
		HouseType.BARN:
			_draw_barn()
		HouseType.SILO:
			_draw_silo()
	_draw_climb_ledges()


func _half_width() -> float:
	match house_type:
		HouseType.COTTAGE:
			return HousePlatformBody.COTTAGE_HALF_W
		HouseType.HOUSE:
			return HousePlatformBody.HOUSE_HALF_W
		HouseType.TALL_HOUSE:
			return HousePlatformBody.TALL_HOUSE_HALF_W
		HouseType.COURTHOUSE:
			return HousePlatformBody.COURTHOUSE_HALF_W
		HouseType.BARN:
			return HousePlatformBody.BARN_HALF_W
		HouseType.SILO:
			return HousePlatformBody.SILO_HALF_W
	return HousePlatformBody.COTTAGE_HALF_W


func _body_ledges() -> Array:
	var parent := get_parent()
	if parent is HousePlatformBody:
		return parent.ledges
	return []


func _draw_climb_ledges() -> void:
	var hw := _half_width()
	var plank := _tint(Color(0.32, 0.26, 0.2), 0.05)
	var rail := _tint(Color(0.22, 0.18, 0.16), 0.04)
	var depth := HousePlatformBody.LEDGE_DEPTH
	var thick := HousePlatformBody.LEDGE_THICKNESS

	for ledge in _body_ledges():
		var side: int = ledge["side"]
		var height: float = ledge["y"]
		var top_y := -height - thick
		var outer_x := side * (hw + depth)
		var inner_x := side * hw
		var left_x := minf(inner_x, outer_x)
		draw_rect(Rect2(left_x, top_y, depth, thick), plank)
		draw_rect(Rect2(left_x, top_y - 14.0, depth, 3.0), rail)
		var post_x1 := left_x + 4.0 if side > 0 else left_x + depth - 6.0
		var post_x2 := left_x + depth - 6.0 if side > 0 else left_x + 4.0
		draw_line(Vector2(post_x1, top_y), Vector2(post_x1, top_y - 14.0), rail, 2.0)
		draw_line(Vector2(post_x2, top_y), Vector2(post_x2, top_y - 14.0), rail, 2.0)
		if _rng.randf() < 0.4:
			draw_line(
				Vector2(left_x + 2.0, top_y - 5.0),
				Vector2(left_x + depth - 2.0, top_y - 11.0),
				Color(0.14, 0.12, 0.1, 0.5),
				1.5
			)


func _draw_rubble_base() -> void:
	var hw := _half_width()
	var rubble := _tint(Color(0.28, 0.24, 0.22), 0.05)
	for i in 6:
		var rx := _rng.randf_range(-hw + 10.0, hw - 10.0)
		var rw := _rng.randf_range(12.0, 34.0)
		var rh := _rng.randf_range(5.0, 14.0)
		draw_rect(Rect2(rx - rw * 0.5, -rh, rw, rh), rubble.darkened(_rng.randf_range(0.0, 0.2)))


func _draw_cottage() -> void:
	var h := HousePlatformBody.COTTAGE_HEIGHT
	var hw := HousePlatformBody.COTTAGE_HALF_W
	var wall := _tint(Color(0.38, 0.32, 0.28), 0.07)
	var roof := _tint(Color(0.22, 0.16, 0.14), 0.06)
	var soot := _tint(Color(0.16, 0.14, 0.13), 0.04)
	var roof_y := -h

	draw_rect(Rect2(-hw + 8.0, roof_y - 20.0, hw * 2.0 - 16.0, 20.0), roof)
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-hw + 10.0, roof_y - 2.0),
			Vector2(-hw * 0.2, roof_y - 28.0),
			Vector2(hw - 14.0, roof_y - 8.0),
		]),
		roof.darkened(0.15)
	)
	if _rng.randf() < 0.7:
		draw_colored_polygon(
			PackedVector2Array([
				Vector2(hw - 36.0, roof_y - 10.0),
				Vector2(hw - 6.0, roof_y - 4.0),
				Vector2(hw - 12.0, roof_y + 2.0),
			]),
			soot
		)

	draw_rect(Rect2(-hw + 10.0, roof_y, hw * 2.0 - 20.0, h - 4.0), wall)
	_draw_cracks(-hw + 12.0, roof_y + 8.0, hw * 2.0 - 24.0, h - 14.0, 4)
	_draw_soot_streak(-hw + 18.0, roof_y + 10.0, 22.0, h * 0.55)

	var door_w := 18.0
	var door_h := 28.0
	draw_rect(Rect2(-door_w * 0.5, -door_h, door_w, door_h), _tint(Color(0.2, 0.14, 0.1), 0.05))

	_draw_lit_window(-hw + 22.0, roof_y + 14.0, 18.0, 16.0)
	_draw_lit_window(hw - 40.0, roof_y + 14.0, 18.0, 16.0)


func _draw_house() -> void:
	var h := HousePlatformBody.HOUSE_HEIGHT
	var hw := HousePlatformBody.HOUSE_HALF_W
	var wall := _tint(Color(0.34, 0.28, 0.24), 0.07)
	var roof := _tint(Color(0.2, 0.14, 0.12), 0.06)
	var soot := _tint(Color(0.14, 0.12, 0.11), 0.04)
	var roof_y := -h
	var floor_y := roof_y + h * 0.48

	draw_rect(Rect2(-hw + 6.0, roof_y - 26.0, hw * 1.2, 26.0), roof)
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-hw, roof_y),
			Vector2(-hw * 0.35, roof_y - 34.0),
			Vector2(hw * 0.4, roof_y - 14.0),
		]),
		roof.darkened(0.12)
	)
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(hw * 0.2, roof_y - 10.0),
			Vector2(hw, roof_y),
			Vector2(hw - 8.0, roof_y + 4.0),
		]),
		soot
	)

	draw_rect(Rect2(-hw + 8.0, roof_y, hw * 2.0 - 16.0, h - 6.0), wall)
	draw_line(Vector2(-hw + 8.0, floor_y), Vector2(hw - 8.0, floor_y), soot, 3.0)
	_draw_cracks(-hw + 10.0, roof_y + 6.0, hw * 2.0 - 20.0, h - 12.0, 5)
	_draw_soot_streak(hw - 36.0, roof_y + 12.0, 18.0, h * 0.65)

	for wx in [-58.0, -18.0, 26.0, 66.0]:
		var wy := roof_y + 16.0 if wx < 0.0 else floor_y + 10.0
		_draw_lit_window(wx, wy, 22.0, 20.0)

	draw_rect(Rect2(-16.0, floor_y - 2.0, 32.0, floor_y * -1.0 + 2.0), _tint(Color(0.18, 0.12, 0.08), 0.05))


func _draw_tall_house() -> void:
	var h := HousePlatformBody.TALL_HOUSE_HEIGHT
	var hw := HousePlatformBody.TALL_HOUSE_HALF_W
	var wall := _tint(Color(0.3, 0.26, 0.22), 0.07)
	var roof := _tint(Color(0.18, 0.12, 0.1), 0.06)
	var stone := _tint(Color(0.24, 0.22, 0.2), 0.05)
	var roof_y := -h

	draw_rect(Rect2(-hw + 4.0, roof_y - 30.0, hw * 1.4, 30.0), roof)
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-hw, roof_y),
			Vector2(-hw * 0.15, roof_y - 42.0),
			Vector2(hw * 0.25, roof_y - 18.0),
		]),
		roof.darkened(0.18)
	)
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(hw * 0.1, roof_y - 12.0),
			Vector2(hw, roof_y),
			Vector2(hw - 10.0, roof_y + 6.0),
			Vector2(hw - 36.0, roof_y + 2.0),
		]),
		stone.darkened(0.2)
	)

	draw_rect(Rect2(-hw + 6.0, roof_y, hw * 2.0 - 12.0, h - 4.0), wall)

	var floor_h := (h - 8.0) / 3.0
	for i in 3:
		var fy := roof_y + floor_h * float(i + 1)
		draw_line(Vector2(-hw + 6.0, fy), Vector2(hw - 6.0, fy), stone, 2.0)

	_draw_cracks(-hw + 8.0, roof_y + 8.0, hw * 2.0 - 16.0, h - 14.0, 6)
	_draw_soot_streak(-hw + 16.0, roof_y + 18.0, 26.0, h * 0.7)

	for row in 3:
		for col in 3:
			var wx := -hw + 20.0 + col * 34.0
			var wy := roof_y + 16.0 + row * floor_h + 8.0
			if row == 2 and col == 1:
				draw_rect(Rect2(wx - 6.0, wy, 32.0, floor_h - 12.0), _tint(Color(0.16, 0.1, 0.06), 0.04))
				continue
			_draw_lit_window(wx, wy, 18.0, 18.0)

	draw_rect(Rect2(-hw + 10.0, roof_y + 6.0, hw * 2.0 - 20.0, 8.0), stone)


func _draw_courthouse() -> void:
	var h := HousePlatformBody.COURTHOUSE_HEIGHT
	var hw := HousePlatformBody.COURTHOUSE_HALF_W
	var stone := _tint(Color(0.42, 0.4, 0.38), 0.05)
	var wall := _tint(Color(0.34, 0.32, 0.3), 0.06)
	var roof := _tint(Color(0.2, 0.16, 0.14), 0.05)
	var roof_y := -h

	draw_rect(Rect2(-hw - 20.0, -12.0, hw * 2.0 + 40.0, 12.0), stone.darkened(0.1))
	for step in 4:
		var sy := -step * 5.0
		draw_rect(Rect2(-hw - 16.0 + step * 4.0, sy - 5.0, hw * 2.0 + 32.0 - step * 8.0, 5.0), stone)
	draw_rect(Rect2(-hw + 8.0, roof_y, hw * 2.0 - 16.0, h - 4.0), wall)
	draw_rect(Rect2(-hw, roof_y - 28.0, hw * 2.0, 28.0), roof)
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-hw, roof_y - 28.0),
			Vector2(0.0, roof_y - 52.0),
			Vector2(hw, roof_y - 28.0),
		]),
		roof.darkened(0.12)
	)
	for col_x in [-hw + 28.0, -hw + 68.0, hw - 68.0, hw - 28.0]:
		draw_rect(Rect2(col_x, roof_y + 8.0, 14.0, h - 20.0), stone.lightened(0.06))
	draw_rect(Rect2(-28.0, roof_y + 20.0, 56.0, h - 28.0), Color(0.14, 0.1, 0.08, 0.9))
	draw_rect(Rect2(-hw + 20.0, roof_y + 30.0, hw * 2.0 - 40.0, 8.0), stone)
	for wx in [-hw + 36.0, -hw + 76.0, hw - 94.0, hw - 54.0]:
		_draw_lit_window(wx, roof_y + 38.0, 16.0, 18.0)
		_draw_lit_window(wx, roof_y + 68.0, 16.0, 18.0)


func _draw_barn() -> void:
	var h := HousePlatformBody.BARN_HEIGHT
	var hw := HousePlatformBody.BARN_HALF_W
	var wall := _tint(Color(0.36, 0.22, 0.18), 0.06)
	var roof := _tint(Color(0.18, 0.12, 0.1), 0.05)
	var roof_y := -h

	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-hw, roof_y),
			Vector2(0.0, roof_y - 38.0),
			Vector2(hw, roof_y),
		]),
		roof
	)
	draw_rect(Rect2(-hw + 6.0, roof_y, hw * 2.0 - 12.0, h - 4.0), wall)
	draw_rect(Rect2(-hw * 0.35, roof_y + 8.0, hw * 0.7, h - 16.0), Color(0.12, 0.08, 0.06, 0.85))
	_draw_lit_window(-hw + 18.0, roof_y + 18.0, 20.0, 18.0)
	_draw_lit_window(hw - 38.0, roof_y + 18.0, 20.0, 18.0)
	_draw_lit_window(-14.0, roof_y + 42.0, 28.0, 22.0)
	_draw_cracks(-hw + 10.0, roof_y + 6.0, hw * 2.0 - 20.0, h - 12.0, 3)


func _draw_silo() -> void:
	var h := HousePlatformBody.SILO_HEIGHT
	var hw := HousePlatformBody.SILO_HALF_W
	var metal := _tint(Color(0.38, 0.36, 0.34), 0.05)
	var roof_y := -h

	draw_rect(Rect2(-hw + 4.0, roof_y, hw * 2.0 - 8.0, h - 6.0), metal)
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-hw + 6.0, roof_y),
			Vector2(0.0, roof_y - 22.0),
			Vector2(hw - 6.0, roof_y),
		]),
		metal.darkened(0.15)
	)
	for band in 4:
		var by := roof_y + band * (h / 4.0)
		draw_line(Vector2(-hw + 6.0, by), Vector2(hw - 6.0, by), metal.darkened(0.2), 2.0)
	_draw_lit_window(-10.0, roof_y + 28.0, 20.0, 16.0)


func _draw_lit_window(x: float, y: float, w: float, h: float) -> void:
	if light_brightness <= 0.01:
		_draw_dark_window(x, y, w, h)
		return
	var frame := _tint(Color(0.2, 0.18, 0.16), 0.04)
	var glow := Color(0.95, 0.72, 0.32, 0.85 * light_brightness)
	var halo := Color(0.85, 0.55, 0.18, 0.25 * light_brightness)
	draw_rect(Rect2(x - 2.0, y - 2.0, w + 4.0, h + 4.0), halo)
	draw_rect(Rect2(x, y, w, h), glow)
	draw_rect(Rect2(x, y, w, 2.0), frame)
	draw_rect(Rect2(x, y + h - 2.0, w, 2.0), frame)
	draw_rect(Rect2(x, y, 2.0, h), frame)
	draw_rect(Rect2(x + w - 2.0, y, 2.0, h), frame)


func _draw_dark_window(x: float, y: float, w: float, h: float) -> void:
	var frame := _tint(Color(0.2, 0.18, 0.16), 0.04)
	draw_rect(Rect2(x, y, w, h), Color(0.05, 0.04, 0.04, 0.95))
	draw_rect(Rect2(x, y, w, 2.0), frame)
	draw_rect(Rect2(x, y + h - 2.0, w, 2.0), frame)
	draw_rect(Rect2(x, y, 2.0, h), frame)
	draw_rect(Rect2(x + w - 2.0, y, 2.0, h), frame)


func _draw_cracks(x: float, y: float, w: float, h: float, count: int) -> void:
	var crack_color := Color(0.12, 0.1, 0.09, 0.65)
	for i in count:
		var sx := x + _rng.randf_range(0.0, w)
		var sy := y + _rng.randf_range(0.0, h * 0.6)
		draw_line(Vector2(sx, sy), Vector2(sx + _rng.randf_range(-14.0, 14.0), sy + _rng.randf_range(10.0, 28.0)), crack_color, 1.2)


func _draw_soot_streak(x: float, y: float, w: float, h: float) -> void:
	draw_rect(Rect2(x, y, w, h), Color(0.1, 0.09, 0.08, 0.35))


func _tint(base: Color, variance: float) -> Color:
	return Color(
		clampf(base.r + _rng.randf_range(-variance, variance), 0.0, 1.0),
		clampf(base.g + _rng.randf_range(-variance, variance), 0.0, 1.0),
		clampf(base.b + _rng.randf_range(-variance, variance), 0.0, 1.0),
		base.a
	)
