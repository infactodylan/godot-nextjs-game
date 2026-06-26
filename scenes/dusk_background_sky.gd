extends Node2D

const MAP_SIZE := Vector2(3600.0, 900.0)
const CONTENT_PADDING := 500.0

const SKY_TOP := Color(0.1, 0.08, 0.2)
const SKY_MID := Color(0.38, 0.2, 0.32)
const SKY_HORIZON := Color(0.82, 0.42, 0.26)
const SUN_GLOW := Color(1.0, 0.55, 0.22, 0.45)


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	var draw_left := -CONTENT_PADDING
	var draw_width := MAP_SIZE.x + CONTENT_PADDING * 2.0
	var horizon_height := MAP_SIZE.y * 0.72
	var bands := 96
	for i in bands:
		var t0 := float(i) / float(bands)
		var t1 := float(i + 1) / float(bands)
		var y0 := lerpf(0.0, horizon_height, t0)
		var y1 := lerpf(0.0, horizon_height, t1)
		var color := _sky_color_at(lerpf(t0, t1, 0.5))
		draw_rect(Rect2(draw_left, y0, draw_width, y1 - y0 + 1.0), color)

	draw_rect(
		Rect2(draw_left, horizon_height, draw_width, MAP_SIZE.y - horizon_height),
		SKY_HORIZON.darkened(0.15)
	)

	var sun_center := Vector2(MAP_SIZE.x * 0.78, MAP_SIZE.y * 0.52)
	for i in 6:
		var radius := 120.0 + i * 38.0
		var alpha := lerpf(0.28, 0.02, float(i) / 5.0)
		var glow := SUN_GLOW
		glow.a = alpha
		draw_circle(sun_center, radius, glow)


func _sky_color_at(t: float) -> Color:
	var eased := ease(t, -1.2)
	if eased < 0.45:
		return SKY_TOP.lerp(SKY_MID, eased / 0.45)
	return SKY_MID.lerp(SKY_HORIZON, (eased - 0.45) / 0.55)
