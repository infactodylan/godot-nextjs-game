extends Control

const SKY_TOP := Color(0.08, 0.06, 0.14)
const SKY_MID := Color(0.32, 0.16, 0.22)
const SKY_HORIZON := Color(0.62, 0.28, 0.16)
const GROUND_SKY := Color(0.18, 0.14, 0.12)
const SUN_GLOW := Color(0.85, 0.32, 0.12, 0.35)
const SMOKE_COLOR := Color(0.18, 0.16, 0.15, 0.28)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	resized.connect(queue_redraw)
	call_deferred("queue_redraw")


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZE:
		queue_redraw()


func _draw() -> void:
	if size.x < 1.0 or size.y < 1.0:
		return

	var horizon_y := size.y * 0.72
	var bands := maxi(64, int(size.y / 6.0))
	for i in bands:
		var t0 := float(i) / float(bands)
		var t1 := float(i + 1) / float(bands)
		var y0 := lerpf(0.0, horizon_y, t0)
		var y1 := lerpf(0.0, horizon_y, t1)
		var color := _sky_color_at(lerpf(t0, t1, 0.5))
		draw_rect(Rect2(0.0, y0, size.x, y1 - y0 + 1.0), color)

	draw_rect(Rect2(0.0, horizon_y, size.x, size.y - horizon_y + 1.0), GROUND_SKY)

	var sun_center := Vector2(size.x * 0.78, size.y * 0.48)
	for i in 6:
		var radius := 70.0 + i * (size.x * 0.04)
		var alpha := lerpf(0.22, 0.02, float(i) / 5.0)
		var glow := SUN_GLOW
		glow.a = alpha
		draw_circle(sun_center, radius, glow)

	for i in 8:
		var t := float(i) / 7.0
		var sx := t * size.x + sin(t * 12.0) * size.x * 0.02
		var sh := size.y * 0.08 + t * size.y * 0.14
		var sw := size.x * 0.04 + t * size.x * 0.06
		draw_rect(Rect2(sx, horizon_y - sh, sw, sh), SMOKE_COLOR)


func _sky_color_at(t: float) -> Color:
	var eased := ease(t, -1.2)
	if eased < 0.45:
		return SKY_TOP.lerp(SKY_MID, eased / 0.45)
	return SKY_MID.lerp(SKY_HORIZON, (eased - 0.45) / 0.55)
