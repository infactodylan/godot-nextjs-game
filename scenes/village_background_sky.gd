extends Node2D

const MAP_SIZE := Vector2(3600.0, 900.0)
const CONTENT_PADDING := 500.0

const SKY_TOP := Color(0.22, 0.38, 0.62)
const SKY_MID := Color(0.72, 0.52, 0.38)
const SKY_HORIZON := Color(0.95, 0.72, 0.42)
const SUN_GLOW := Color(1.0, 0.82, 0.45, 0.4)


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
		var color := _sky_color_at(lerpf(t0, t1, 0.5))
		draw_rect(Rect2(draw_left, y0, draw_width, y1 - y0 + 1.0), color)

	draw_rect(
		Rect2(draw_left, horizon_height, draw_width, MAP_SIZE.y - horizon_height),
		Color(0.32, 0.48, 0.22)
	)

	var sun_center := Vector2(MAP_SIZE.x * 0.22, MAP_SIZE.y * 0.48)
	for i in 5:
		var radius := 100.0 + i * 32.0
		var alpha := lerpf(0.25, 0.02, float(i) / 4.0)
		var glow := SUN_GLOW
		glow.a = alpha
		draw_circle(sun_center, radius, glow)


func _sky_color_at(t: float) -> Color:
	var eased := ease(t, -1.0)
	if eased < 0.5:
		return SKY_TOP.lerp(SKY_MID, eased / 0.5)
	return SKY_MID.lerp(SKY_HORIZON, (eased - 0.5) / 0.5)
