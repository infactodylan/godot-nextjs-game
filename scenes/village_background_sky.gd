extends Node2D

const CONTENT_PADDING := 500.0
const VIEW_PADDING := 96.0

const SKY_TOP := Color(0.08, 0.06, 0.14)
const SKY_MID := Color(0.32, 0.16, 0.22)
const SKY_HORIZON := Color(0.62, 0.28, 0.16)
const GROUND_SKY := Color(0.18, 0.14, 0.12)
const SUN_GLOW := Color(0.85, 0.32, 0.12, 0.35)
const SMOKE_COLOR := Color(0.18, 0.16, 0.15, 0.28)


func _draw() -> void:
	var half_view: Vector2 = get_meta("half_view", Vector2(960.0, 270.0))
	var top := -half_view.y - VIEW_PADDING
	var bottom := half_view.y + VIEW_PADDING
	var left := -half_view.x - CONTENT_PADDING
	var width := half_view.x * 2.0 + CONTENT_PADDING * 2.0
	var total_h := bottom - top
	var horizon_y := top + total_h * 0.7

	var bands := 96
	for i in bands:
		var t0 := float(i) / float(bands)
		var t1 := float(i + 1) / float(bands)
		var y0 := lerpf(top, horizon_y, t0)
		var y1 := lerpf(top, horizon_y, t1)
		var color := _sky_color_at(lerpf(t0, t1, 0.5))
		draw_rect(Rect2(left, y0, width, y1 - y0 + 1.0), color)

	draw_rect(Rect2(left, horizon_y, width, bottom - horizon_y + 1.0), GROUND_SKY)

	var sun_center := Vector2(half_view.x * 0.35, top + total_h * 0.42)
	for i in 6:
		var radius := 90.0 + i * 34.0
		var alpha := lerpf(0.22, 0.02, float(i) / 5.0)
		var glow := SUN_GLOW
		glow.a = alpha
		draw_circle(sun_center, radius, glow)

	for i in 8:
		var t := float(i) / 7.0
		var sx := left + t * width + sin(t * 12.0) * 40.0
		var sh := 60.0 + t * 90.0
		var sw := 50.0 + t * 70.0
		draw_rect(Rect2(sx, horizon_y - sh, sw, sh), SMOKE_COLOR)


func _sky_color_at(t: float) -> Color:
	var eased := ease(t, -1.2)
	if eased < 0.45:
		return SKY_TOP.lerp(SKY_MID, eased / 0.45)
	return SKY_MID.lerp(SKY_HORIZON, (eased - 0.45) / 0.55)
