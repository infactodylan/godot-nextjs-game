extends Node2D
class_name WreckPlatformVisual

enum WreckType { CAR, BUS, STREET_SIGN }
enum SignLayer { NONE, BACK, FRONT }

@export var wreck_type: WreckType = WreckType.CAR
@export var sign_layer: SignLayer = SignLayer.NONE
@export var color_seed: int = 0

const PLAYER_SORT_Z := 5
const SIGN_BACK_Z := 1
const SIGN_FRONT_Z := 10

var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = color_seed if color_seed != 0 else hash(str(get_parent().name))
	z_as_relative = false
	match sign_layer:
		SignLayer.BACK:
			z_index = SIGN_BACK_Z
		SignLayer.FRONT:
			z_index = SIGN_FRONT_Z
	queue_redraw()


func _draw() -> void:
	# Local y = 0 is the ground line; shapes extend upward (negative y).
	draw_line(Vector2(-120.0, 0.0), Vector2(120.0, 0.0), Color(0.12, 0.1, 0.08, 0.35), 2.0)
	match wreck_type:
		WreckType.CAR:
			_draw_car()
		WreckType.BUS:
			_draw_bus()
		WreckType.STREET_SIGN:
			if sign_layer == SignLayer.FRONT:
				_draw_street_sign_front()
			else:
				_draw_street_sign_back()


func _draw_car() -> void:
	var h := WreckPlatformBody.CAR_HEIGHT
	var hw := WreckPlatformBody.CAR_HALF_W
	var body := _tint(Color(0.42, 0.24, 0.16), 0.08)
	var dark := _tint(Color(0.16, 0.12, 0.1), 0.05)
	var accent := _tint(Color(0.55, 0.3, 0.18), 0.1)
	var roof_y := -h

	draw_rect(Rect2(-hw + 8.0, roof_y, hw * 2.0 - 16.0, 5.0), _tint(Color(0.34, 0.22, 0.15), 0.06))
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-hw, -8.0),
			Vector2(-hw + 4.0, -4.0),
			Vector2(-hw + 14.0, roof_y + 6.0),
			Vector2(hw - 10.0, roof_y + 4.0),
			Vector2(hw, -6.0),
			Vector2(hw - 6.0, 0.0),
			Vector2(-hw + 8.0, 0.0),
		]),
		body
	)
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-hw, -8.0),
			Vector2(-hw + 18.0, roof_y + 14.0),
			Vector2(-hw + 8.0, 0.0),
		]),
		dark
	)
	draw_rect(Rect2(8.0, roof_y + 12.0, 28.0, 10.0), accent)
	draw_rect(Rect2(12.0, roof_y + 14.0, 10.0, 6.0), Color(0.08, 0.1, 0.14, 0.85))

	for wheel_x in [-38.0, 36.0]:
		draw_circle(Vector2(wheel_x, -9.0), 9.0, dark)
		draw_circle(Vector2(wheel_x, -9.0), 4.0, Color(0.08, 0.08, 0.08))

	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-4.0, roof_y + 10.0),
			Vector2(18.0, roof_y + 11.0),
			Vector2(14.0, roof_y + 22.0),
			Vector2(-2.0, roof_y + 21.0),
		]),
		Color(0.45, 0.55, 0.62, 0.35)
	)


func _draw_bus() -> void:
	var h := WreckPlatformBody.BUS_HEIGHT
	var hw := WreckPlatformBody.BUS_HALF_W
	var body := _tint(Color(0.48, 0.38, 0.12), 0.08)
	var dark := _tint(Color(0.18, 0.14, 0.1), 0.05)
	var stripe := _tint(Color(0.28, 0.22, 0.1), 0.06)
	var roof_y := -h

	draw_rect(Rect2(-hw + 6.0, roof_y, hw * 2.0 - 12.0, 6.0), _tint(Color(0.3, 0.24, 0.12), 0.05))
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-hw, -4.0),
			Vector2(-hw + 6.0, roof_y + 8.0),
			Vector2(hw - 8.0, roof_y + 6.0),
			Vector2(hw, -2.0),
			Vector2(hw - 4.0, 0.0),
			Vector2(-hw + 4.0, 0.0),
		]),
		body
	)
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(hw - 8.0, roof_y + 6.0),
			Vector2(hw, -2.0),
			Vector2(hw - 4.0, 0.0),
			Vector2(hw - 22.0, 0.0),
			Vector2(hw - 14.0, roof_y + 20.0),
		]),
		dark
	)
	draw_rect(Rect2(-hw + 8.0, roof_y + 24.0, hw * 2.0 - 16.0, 5.0), stripe)

	for wx in [-52.0, -18.0, 16.0, 50.0]:
		draw_rect(Rect2(wx, roof_y + 14.0, 20.0, 14.0), Color(0.1, 0.12, 0.16, 0.9))
		if _rng.randf() < 0.55:
			draw_line(
				Vector2(wx + 3.0, roof_y + 16.0),
				Vector2(wx + 16.0, roof_y + 26.0),
				Color(0.45, 0.55, 0.62, 0.45),
				1.5
			)

	for wheel_x in [-42.0, 38.0]:
		draw_circle(Vector2(wheel_x, -10.0), 11.0, dark)
		draw_circle(Vector2(wheel_x, -10.0), 5.0, Color(0.08, 0.08, 0.08))


func _draw_street_sign_back() -> void:
	var h := WreckPlatformBody.SIGN_HEIGHT
	var hw := WreckPlatformBody.SIGN_HALF_W
	var clearance := WreckPlatformBody.SIGN_CLEARANCE
	var post_w := WreckPlatformBody.SIGN_POST_W
	var metal := _tint(Color(0.34, 0.36, 0.38), 0.06)
	var dark := _tint(Color(0.14, 0.14, 0.16), 0.04)
	var sign_color := _tint(Color(0.22, 0.3, 0.42), 0.08)
	var sign_edge := _tint(Color(0.5, 0.52, 0.55), 0.05)
	var roof_y := -h
	var post_top := roof_y + 14.0

	draw_line(Vector2(-hw, 0.0), Vector2(hw, 0.0), Color(0.2, 0.18, 0.16, 0.25), 1.0)

	# Rear leg (left) — behind the player.
	draw_rect(Rect2(-hw, post_top, post_w, -post_top), metal)
	draw_rect(Rect2(-hw, -post_w, post_w, post_w), metal.darkened(0.1))

	# Sign beam and rear half of the arch.
	draw_rect(Rect2(-hw, roof_y, hw * 2.0, 14.0), sign_edge)
	draw_rect(Rect2(-hw + 4.0, roof_y + 2.0, hw * 2.0 - 8.0, 10.0), sign_color)
	for i in 4:
		var lx := -hw + 14.0 + i * 26.0
		draw_rect(Rect2(lx, roof_y + 4.0, 18.0, 4.0), Color(0.72, 0.74, 0.78, 0.35))
	draw_line(Vector2(-hw + post_w, -clearance), Vector2(hw - post_w, -clearance), dark, 2.0)

	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-hw - 6.0, -4.0),
			Vector2(-hw + 8.0, -8.0),
			Vector2(-hw + 14.0, 0.0),
			Vector2(-hw - 2.0, 0.0),
		]),
		Color(0.55, 0.14, 0.12, 0.85)
	)


func _draw_street_sign_front() -> void:
	var h := WreckPlatformBody.SIGN_HEIGHT
	var hw := WreckPlatformBody.SIGN_HALF_W
	var post_w := WreckPlatformBody.SIGN_POST_W
	var metal := _tint(Color(0.34, 0.36, 0.38), 0.06)
	var roof_y := -h
	var post_top := roof_y + 14.0

	# Front leg (right) — in front of the player as they pass through.
	draw_rect(Rect2(hw - post_w, post_top, post_w, -post_top), metal)
	draw_rect(Rect2(hw - post_w, -post_w, post_w, post_w), metal.darkened(0.1))
	draw_line(Vector2(hw - post_w * 0.5, post_top), Vector2(hw - post_w * 0.5, 0.0), metal.lightened(0.08), 1.5)


func _tint(base: Color, variance: float) -> Color:
	return Color(
		clampf(base.r + _rng.randf_range(-variance, variance), 0.0, 1.0),
		clampf(base.g + _rng.randf_range(-variance, variance), 0.0, 1.0),
		clampf(base.b + _rng.randf_range(-variance, variance), 0.0, 1.0),
		base.a
	)
