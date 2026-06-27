extends Node2D

const MAP_SIZE := Vector2(7800.0, 900.0)
const CONTENT_PADDING := 500.0

const SKY_TOP := Color(0.06, 0.05, 0.14)
const SKY_MID := Color(0.28, 0.12, 0.22)
const SKY_HORIZON := Color(0.72, 0.32, 0.14)
const SKY_GLOW := Color(0.92, 0.42, 0.16)
const GROUND_SKY := Color(0.16, 0.12, 0.11)
const SUN_GLOW := Color(0.95, 0.38, 0.14, 0.42)


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	var draw_left := -CONTENT_PADDING
	var draw_width := MAP_SIZE.x + CONTENT_PADDING * 2.0
	var horizon_height := MAP_SIZE.y * 0.68
	var bands := 96
	for i in bands:
		var t0 := float(i) / float(bands)
		var t1 := float(i + 1) / float(bands)
		var y0 := lerpf(0.0, horizon_height, t0)
		var y1 := lerpf(0.0, horizon_height, t1)
		draw_rect(Rect2(draw_left, y0, draw_width, y1 - y0 + 1.0), _sky_color_at(lerpf(t0, t1, 0.5)))

	draw_rect(
		Rect2(draw_left, horizon_height, draw_width, MAP_SIZE.y - horizon_height),
		GROUND_SKY
	)

	var sun_center := Vector2(MAP_SIZE.x * 0.74, MAP_SIZE.y * 0.42)
	for i in 7:
		var radius := 90.0 + i * 38.0
		var alpha := lerpf(0.28, 0.02, float(i) / 6.0)
		var glow := SUN_GLOW
		glow.a = alpha
		draw_circle(sun_center, radius, glow)
	draw_circle(sun_center, 26.0, SKY_GLOW)


func _sky_color_at(t: float) -> Color:
	var eased := ease(t, -1.35)
	if eased < 0.42:
		return SKY_TOP.lerp(SKY_MID, eased / 0.42)
	if eased < 0.72:
		return SKY_MID.lerp(SKY_HORIZON, (eased - 0.42) / 0.3)
	return SKY_HORIZON.lerp(SKY_GLOW, (eased - 0.72) / 0.28)
