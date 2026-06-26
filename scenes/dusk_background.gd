extends Node2D
class_name DuskBackground

const MAP_SIZE := Vector2(3600.0, 900.0)
const GROUND_LINE := 820.0
const CONTENT_PADDING := 500.0

const SKY_PARALLAX := 0.05
const CLOUD_PARALLAX := 0.32
const FAR_BUILDING_PARALLAX := 0.18
const MID_BUILDING_PARALLAX := 0.34
const NEAR_RUIN_PARALLAX := 0.48
const HAZE_PARALLAX := 0.07

const HAZE_COLOR := Color(0.72, 0.5, 0.58, 0.22)
const CLOUD_COLOR := Color(0.55, 0.42, 0.5, 0.28)

var _rng := RandomNumberGenerator.new()
var _camera: Camera2D
var far_buildings: Array[Dictionary] = []
var mid_buildings: Array[Dictionary] = []
var near_ruins: Array[Dictionary] = []
var clouds: Array[Dictionary] = []
var rubble: Array[Dictionary] = []


func _enter_tree() -> void:
	_rng.seed = 1337
	var content_start := -CONTENT_PADDING
	var content_end := MAP_SIZE.x + CONTENT_PADDING
	_generate_buildings(far_buildings, 32, 90.0, 310.0, 0.12, 0.0, content_start, content_end)
	_generate_buildings(mid_buildings, 38, 120.0, 430.0, 0.2, 0.04, content_start, content_end)
	_generate_ruins(near_ruins, 20, content_start, content_end)
	_generate_rubble(content_start, content_end)
	_generate_clouds(content_start, content_end)


func _ready() -> void:
	z_index = -20
	set_process(false)
	_redraw_layers()


func bind_camera(camera: Camera2D) -> void:
	_camera = camera
	set_process(true)
	_update_parallax_offsets()


func _process(_delta: float) -> void:
	if _camera == null:
		return
	_update_parallax_offsets()


func _update_parallax_offsets() -> void:
	var cam_x := _camera.global_position.x
	$Sky.position.x = cam_x * (1.0 - SKY_PARALLAX)
	$Clouds.position.x = cam_x * (1.0 - CLOUD_PARALLAX)
	$FarBuildings.position.x = cam_x * (1.0 - FAR_BUILDING_PARALLAX)
	$MidBuildings.position.x = cam_x * (1.0 - MID_BUILDING_PARALLAX)
	$NearRuins.position.x = cam_x * (1.0 - NEAR_RUIN_PARALLAX)
	$Haze.position.x = cam_x * (1.0 - HAZE_PARALLAX)


func _redraw_layers() -> void:
	$Sky.queue_redraw()
	$Clouds.queue_redraw()
	$FarBuildings.queue_redraw()
	$MidBuildings.queue_redraw()
	$NearRuins.queue_redraw()
	$Haze.queue_redraw()


func _generate_buildings(
	target: Array[Dictionary],
	count: int,
	min_w: float,
	max_h: float,
	gap: float,
	window_glow_strength: float,
	content_start: float,
	content_end: float
) -> void:
	var x := content_start - 40.0
	while x < content_end + 80.0 and target.size() < count:
		var width := _rng.randf_range(min_w, min_w * 1.8)
		var height := _rng.randf_range(max_h * 0.45, max_h)
		var roof_points := _make_broken_roof(x, width, height)
		var windows := _make_windows(x, width, height, window_glow_strength)
		var collapsed := _rng.randf() < 0.35
		target.append({
			"x": x,
			"width": width,
			"height": height,
			"roof": roof_points,
			"windows": windows,
			"collapsed": collapsed,
			"collapse_x": x + width * _rng.randf_range(0.35, 0.75) if collapsed else 0.0,
		})
		x += width + _rng.randf_range(gap, gap * 3.5)


func _make_broken_roof(x: float, width: float, height: float) -> PackedVector2Array:
	var base_y := GROUND_LINE - height
	var points := PackedVector2Array()
	points.append(Vector2(x, GROUND_LINE))
	points.append(Vector2(x, base_y + _rng.randf_range(0.0, height * 0.08)))

	var segments := _rng.randi_range(3, 6)
	var seg_w := width / float(segments)
	for i in segments:
		var px := x + seg_w * float(i)
		var peak := base_y + _rng.randf_range(-height * 0.12, height * 0.1)
		points.append(Vector2(px + seg_w * 0.15, peak))
		if _rng.randf() < 0.4:
			points.append(Vector2(px + seg_w * 0.55, peak + _rng.randf_range(8.0, 28.0)))
		points.append(Vector2(px + seg_w, peak + _rng.randf_range(-10.0, 16.0)))

	points.append(Vector2(x + width, GROUND_LINE))
	return points


func _make_windows(x: float, width: float, height: float, glow_strength: float) -> Array[Dictionary]:
	var windows: Array[Dictionary] = []
	var cols := maxi(1, int(width / 28.0))
	var rows := maxi(2, int(height / 36.0))
	for row in rows:
		for col in cols:
			if _rng.randf() < 0.38:
				continue
			var wx := x + 10.0 + col * (width - 20.0) / float(cols)
			var wy := GROUND_LINE - height + 18.0 + row * (height - 30.0) / float(rows)
			windows.append({
				"rect": Rect2(wx, wy, 10.0, 14.0),
				"lit": _rng.randf() < 0.12 + glow_strength,
			})
	return windows


func _generate_ruins(target: Array[Dictionary], count: int, content_start: float, content_end: float) -> void:
	var x := content_start + 60.0
	while target.size() < count and x < content_end:
		var width := _rng.randf_range(140.0, 280.0)
		var height := _rng.randf_range(180.0, 360.0)
		var chunk_count := _rng.randi_range(2, 4)
		var chunks: Array[PackedVector2Array] = []
		for i in chunk_count:
			var cx := x + _rng.randf_range(0.0, width * 0.55)
			var cw := _rng.randf_range(width * 0.25, width * 0.55)
			var ch := _rng.randf_range(height * 0.25, height * 0.85)
			chunks.append(_make_broken_roof(cx, cw, ch))
		var debris_pieces: Array[Rect2] = []
		if _rng.randf() < 0.7:
			for j in 5:
				debris_pieces.append(Rect2(
					x + _rng.randf_range(0.0, width),
					GROUND_LINE - _rng.randf_range(6.0, 22.0),
					_rng.randf_range(12.0, 36.0),
					_rng.randf_range(6.0, 18.0)
				))
		target.append({
			"x": x,
			"width": width,
			"chunks": chunks,
			"debris": debris_pieces,
		})
		x += width + _rng.randf_range(80.0, 200.0)


func _generate_rubble(content_start: float, content_end: float) -> void:
	var x := content_start
	while x < content_end:
		if _rng.randf() < 0.55:
			var pile_w := _rng.randf_range(30.0, 110.0)
			var pile_h := _rng.randf_range(8.0, 28.0)
			rubble.append({
				"rect": Rect2(x, GROUND_LINE - pile_h, pile_w, pile_h),
			})
			x += pile_w + _rng.randf_range(10.0, 50.0)
		else:
			x += _rng.randf_range(20.0, 80.0)


func _generate_clouds(content_start: float, content_end: float) -> void:
	for i in 18:
		clouds.append({
			"pos": Vector2(_rng.randf_range(content_start, content_end), _rng.randf_range(40.0, 340.0)),
			"size": Vector2(_rng.randf_range(200.0, 460.0), _rng.randf_range(36.0, 100.0)),
			"alpha": _rng.randf_range(0.14, 0.32),
		})


static func draw_building_layer(canvas: CanvasItem, buildings: Array[Dictionary], color: Color) -> void:
	for building in buildings:
		canvas.draw_colored_polygon(building["roof"], color)
		if building["collapsed"]:
			var collapse_x: float = building["collapse_x"]
			canvas.draw_rect(
				Rect2(collapse_x, GROUND_LINE - building["height"] * 0.55, building["width"] * 0.35, building["height"] * 0.55),
				color.lightened(0.06)
			)
		for window: Dictionary in building["windows"]:
			var window_color := Color(0.04, 0.03, 0.06) if not window["lit"] else Color(0.95, 0.62, 0.28, 0.55)
			canvas.draw_rect(window["rect"], window_color)


static func draw_ruins(canvas: CanvasItem, ruins: Array[Dictionary], rubble_piles: Array[Dictionary]) -> void:
	var ruin_color := Color(0.24, 0.19, 0.22)
	var shadow := Color(0.14, 0.11, 0.13)
	for ruin in ruins:
		for chunk: PackedVector2Array in ruin["chunks"]:
			canvas.draw_colored_polygon(chunk, ruin_color)
			var bounds := _polygon_bounds(chunk)
			canvas.draw_rect(Rect2(bounds.position.x + 4.0, bounds.end.y - 18.0, bounds.size.x - 8.0, 16.0), shadow)
		for piece: Rect2 in ruin["debris"]:
			canvas.draw_rect(piece, shadow.lightened(0.08))

	var rubble_color := Color(0.3, 0.24, 0.2)
	for pile in rubble_piles:
		var rect: Rect2 = pile["rect"]
		canvas.draw_rect(rect, rubble_color)
		canvas.draw_rect(Rect2(rect.position.x + 4.0, rect.end.y - 4.0, rect.size.x * 0.6, 4.0), rubble_color.darkened(0.2))


static func draw_clouds(canvas: CanvasItem, cloud_data: Array[Dictionary]) -> void:
	for cloud in cloud_data:
		var color := CLOUD_COLOR
		color.a = cloud["alpha"]
		var pos: Vector2 = cloud["pos"]
		var size: Vector2 = cloud["size"]
		var center := pos + size * 0.5
		canvas.draw_ellipse(center, size.x * 0.5, size.y * 0.5, color, true, -1.0, true)
		canvas.draw_ellipse(
			center + Vector2(size.x * 0.18, -size.y * 0.15),
			size.x * 0.35,
			size.y * 0.4,
			color,
			true,
			-1.0,
			true
		)
		canvas.draw_ellipse(
			center + Vector2(-size.x * 0.12, size.y * 0.08),
			size.x * 0.28,
			size.y * 0.32,
			color,
			true,
			-1.0,
			true
		)


static func draw_haze(canvas: CanvasItem) -> void:
	var draw_left := -CONTENT_PADDING
	var draw_width := MAP_SIZE.x + CONTENT_PADDING * 2.0
	var bands := 40
	for i in bands:
		var t := float(i) / float(bands - 1)
		var t_next := float(i + 1) / float(bands - 1)
		var y := lerpf(MAP_SIZE.y * 0.35, MAP_SIZE.y, t)
		var y_next := lerpf(MAP_SIZE.y * 0.35, MAP_SIZE.y, t_next)
		var h := y_next - y + 1.0
		var color := HAZE_COLOR
		color.a = lerpf(0.03, 0.18, ease(t, -0.8))
		canvas.draw_rect(Rect2(draw_left, y, draw_width, h), color)


static func _polygon_bounds(points: PackedVector2Array) -> Rect2:
	if points.is_empty():
		return Rect2()
	var min_p := points[0]
	var max_p := points[0]
	for p in points:
		min_p = min_p.min(p)
		max_p = max_p.max(p)
	return Rect2(min_p, max_p - min_p)
