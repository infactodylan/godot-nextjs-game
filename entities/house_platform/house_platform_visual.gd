extends Node2D
class_name HousePlatformVisual

enum HouseType { COTTAGE, HOUSE, TALL_HOUSE }

@export var house_type: HouseType = HouseType.COTTAGE
@export var color_seed: int = 0

var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = color_seed if color_seed != 0 else hash(str(get_parent().name))
	queue_redraw()


func _draw() -> void:
	draw_line(Vector2(-120.0, 0.0), Vector2(120.0, 0.0), Color(0.18, 0.28, 0.14, 0.4), 2.0)
	match house_type:
		HouseType.COTTAGE:
			_draw_cottage()
		HouseType.HOUSE:
			_draw_house()
		HouseType.TALL_HOUSE:
			_draw_tall_house()


func _draw_cottage() -> void:
	var h := HousePlatformBody.COTTAGE_HEIGHT
	var hw := HousePlatformBody.COTTAGE_HALF_W
	var wall := _tint(Color(0.72, 0.58, 0.42), 0.06)
	var roof := _tint(Color(0.45, 0.22, 0.16), 0.05)
	var trim := _tint(Color(0.55, 0.42, 0.3), 0.04)
	var roof_y := -h

	draw_rect(Rect2(-hw + 6.0, roof_y - 18.0, hw * 2.0 - 12.0, 18.0), roof)
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-hw + 4.0, roof_y - 2.0),
			Vector2(0.0, roof_y - 22.0),
			Vector2(hw - 4.0, roof_y - 2.0),
		]),
		roof.darkened(0.08)
	)
	draw_rect(Rect2(-hw + 8.0, roof_y, hw * 2.0 - 16.0, h - 4.0), wall)
	draw_rect(Rect2(-hw + 8.0, roof_y, hw * 2.0 - 16.0, 4.0), trim)

	var door_w := 16.0
	var door_h := 22.0
	draw_rect(Rect2(-door_w * 0.5, -door_h, door_w, door_h), _tint(Color(0.38, 0.24, 0.14), 0.04))
	draw_circle(Vector2(-door_w * 0.5 + 12.0, -door_h * 0.5), 2.0, Color(0.85, 0.75, 0.35))

	draw_rect(Rect2(-hw + 18.0, roof_y + 10.0, 14.0, 12.0), Color(0.55, 0.72, 0.88, 0.75))
	draw_rect(Rect2(hw - 32.0, roof_y + 10.0, 14.0, 12.0), Color(0.55, 0.72, 0.88, 0.75))

	if _rng.randf() < 0.6:
		draw_rect(Rect2(hw - 22.0, roof_y - 28.0, 8.0, 14.0), _tint(Color(0.42, 0.38, 0.36), 0.04))
		draw_rect(Rect2(hw - 20.0, roof_y - 32.0, 4.0, 6.0), Color(0.35, 0.32, 0.3, 0.5))


func _draw_house() -> void:
	var h := HousePlatformBody.HOUSE_HEIGHT
	var hw := HousePlatformBody.HOUSE_HALF_W
	var wall := _tint(Color(0.68, 0.52, 0.38), 0.06)
	var roof := _tint(Color(0.38, 0.2, 0.14), 0.05)
	var trim := _tint(Color(0.5, 0.38, 0.28), 0.04)
	var roof_y := -h
	var floor_y := roof_y + h * 0.48

	draw_rect(Rect2(-hw + 4.0, roof_y - 22.0, hw * 2.0 - 8.0, 22.0), roof)
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-hw, roof_y),
			Vector2(0.0, roof_y - 28.0),
			Vector2(hw, roof_y),
		]),
		roof.darkened(0.1)
	)
	draw_rect(Rect2(-hw + 6.0, roof_y, hw * 2.0 - 12.0, h - 6.0), wall)
	draw_line(Vector2(-hw + 6.0, floor_y), Vector2(hw - 6.0, floor_y), trim, 3.0)

	for wx in [-48.0, -14.0, 20.0, 54.0]:
		var wy := roof_y + 12.0 if wx < 0.0 else floor_y + 8.0
		draw_rect(Rect2(wx, wy, 18.0, 16.0), Color(0.52, 0.68, 0.82, 0.8))
		draw_line(Vector2(wx + 2.0, wy + 2.0), Vector2(wx + 16.0, wy + 14.0), Color(0.35, 0.45, 0.55, 0.35), 1.0)

	draw_rect(Rect2(-14.0, floor_y - 4.0, 28.0, floor_y * -1.0 + 4.0), _tint(Color(0.35, 0.22, 0.12), 0.04))
	draw_rect(Rect2(-hw + 10.0, roof_y + 6.0, hw * 2.0 - 20.0, 5.0), trim)

	draw_rect(Rect2(hw - 20.0, roof_y - 34.0, 10.0, 18.0), _tint(Color(0.4, 0.36, 0.34), 0.04))
	draw_rect(Rect2(hw - 18.0, roof_y - 38.0, 6.0, 8.0), Color(0.3, 0.28, 0.26, 0.6))


func _draw_tall_house() -> void:
	var h := HousePlatformBody.TALL_HOUSE_HEIGHT
	var hw := HousePlatformBody.TALL_HOUSE_HALF_W
	var wall := _tint(Color(0.62, 0.48, 0.36), 0.06)
	var roof := _tint(Color(0.34, 0.18, 0.12), 0.05)
	var stone := _tint(Color(0.48, 0.46, 0.44), 0.04)
	var roof_y := -h

	draw_rect(Rect2(-hw + 2.0, roof_y - 26.0, hw * 2.0 - 4.0, 26.0), roof)
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-hw, roof_y),
			Vector2(-hw * 0.3, roof_y - 34.0),
			Vector2(0.0, roof_y - 42.0),
			Vector2(hw * 0.3, roof_y - 34.0),
			Vector2(hw, roof_y),
		]),
		roof.darkened(0.12)
	)
	draw_rect(Rect2(-hw + 4.0, roof_y, hw * 2.0 - 8.0, h - 4.0), wall)

	var floor_h := (h - 8.0) / 3.0
	for i in 3:
		var fy := roof_y + floor_h * float(i + 1)
		draw_line(Vector2(-hw + 4.0, fy), Vector2(hw - 4.0, fy), stone, 2.0)

	for row in 3:
		for col in 3:
			var wx := -hw + 16.0 + col * 28.0
			var wy := roof_y + 12.0 + row * floor_h + 6.0
			if row == 2 and col == 1:
				draw_rect(Rect2(wx - 4.0, wy, 26.0, floor_h - 10.0), _tint(Color(0.32, 0.2, 0.1), 0.04))
				continue
			draw_rect(Rect2(wx, wy, 14.0, 14.0), Color(0.58, 0.74, 0.9, 0.75))
			if _rng.randf() < 0.35:
				draw_rect(Rect2(wx + 2.0, wy + 2.0, 10.0, 10.0), Color(0.95, 0.78, 0.35, 0.45))

	draw_rect(Rect2(-hw + 8.0, roof_y + 4.0, hw * 2.0 - 16.0, 6.0), stone)
	draw_rect(Rect2(hw - 18.0, roof_y - 48.0, 12.0, 22.0), stone)
	draw_rect(Rect2(hw - 16.0, roof_y - 54.0, 8.0, 10.0), Color(0.28, 0.26, 0.24, 0.55))


func _tint(base: Color, variance: float) -> Color:
	return Color(
		clampf(base.r + _rng.randf_range(-variance, variance), 0.0, 1.0),
		clampf(base.g + _rng.randf_range(-variance, variance), 0.0, 1.0),
		clampf(base.b + _rng.randf_range(-variance, variance), 0.0, 1.0),
		base.a
	)
