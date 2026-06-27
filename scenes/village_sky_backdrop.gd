extends ColorRect

const SKY_TOP := Color(0.06, 0.05, 0.14)
const SKY_MID := Color(0.22, 0.1, 0.2)
const SKY_LOWER := Color(0.18, 0.12, 0.18)
const GROUND_SKY := Color(0.14, 0.11, 0.13)
const SMOKE_COLOR := Color(0.14, 0.12, 0.14, 0.32)
const CLOUD_COLOR := Color(0.38, 0.28, 0.36, 0.2)

var _cloud_phase := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	color = Color(0.0, 0.0, 0.0, 0.0)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	set_offsets_preset(Control.PRESET_FULL_RECT)
	resized.connect(queue_redraw)
	get_viewport().size_changed.connect(queue_redraw)
	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	_cloud_phase = fmod(_cloud_phase + delta * 0.022, 1.0)
	queue_redraw()


func _draw() -> void:
	var canvas := _canvas_size()
	if canvas.x < 2.0 or canvas.y < 2.0:
		return

	var bands := maxi(96, int(canvas.y / 3.0))
	for i in bands:
		var t0 := float(i) / float(bands)
		var t1 := float(i + 1) / float(bands)
		var y0 := lerpf(0.0, canvas.y, t0)
		var y1 := lerpf(0.0, canvas.y, t1)
		var color_at := _sky_color_at(lerpf(t0, t1, 0.5))
		draw_rect(Rect2(0.0, y0, canvas.x, y1 - y0 + 1.0), color_at)

	_draw_clouds(canvas)
	_draw_smoke(canvas)


func _canvas_size() -> Vector2:
	if size.x > 2.0 and size.y > 2.0:
		return size
	var vp := get_viewport_rect().size
	return vp if vp.x > 2.0 else Vector2(1920.0, 480.0)


func _draw_clouds(canvas: Vector2) -> void:
	var loop_w := canvas.x * 1.35
	var cloud_ceiling := canvas.y * 0.58
	for i in 10:
		var t := float(i) / 9.0
		var drift := _cloud_phase * loop_w
		var cx := fmod(t * loop_w + drift, loop_w) - canvas.x * 0.08
		var cy := canvas.y * (0.06 + t * 0.28)
		if cy > cloud_ceiling:
			continue
		var cloud_w := canvas.x * (0.11 + t * 0.07)
		var cloud_h := canvas.y * (0.028 + t * 0.018)
		var color := CLOUD_COLOR
		color.a = lerpf(0.1, 0.24, 1.0 - t * 0.6)
		_paint_cloud(Vector2(cx, cy), cloud_w, cloud_h, color)
		_paint_cloud(Vector2(cx + loop_w, cy), cloud_w, cloud_h, color)


func _draw_smoke(canvas: Vector2) -> void:
	var horizon_y := canvas.y * 0.72
	for i in 12:
		var t := float(i) / 11.0
		var sx := t * canvas.x + sin(t * 10.0) * canvas.x * 0.015
		var sh := canvas.y * 0.05 + t * canvas.y * 0.12
		var sw := canvas.x * 0.03 + t * canvas.x * 0.055
		draw_rect(Rect2(sx, horizon_y - sh, sw, sh), SMOKE_COLOR)


func _paint_cloud(center: Vector2, width: float, height: float, color: Color) -> void:
	draw_ellipse(center, width * 0.5, height * 0.5, color, true, -1.0, true)
	draw_ellipse(
		center + Vector2(width * 0.16, -height * 0.12),
		width * 0.28,
		height * 0.36,
		color,
		true,
		-1.0,
		true
	)


func _sky_color_at(t: float) -> Color:
	var eased := ease(t, -0.75)
	if eased < 0.45:
		return SKY_TOP.lerp(SKY_MID, eased / 0.45)
	if eased < 0.82:
		return SKY_MID.lerp(SKY_LOWER, (eased - 0.45) / 0.37)
	return SKY_LOWER.lerp(GROUND_SKY, (eased - 0.82) / 0.18)
