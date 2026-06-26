extends Node2D
class_name VillageBackground

const MAP_SIZE := Vector2(7800.0, 900.0)
const GROUND_LINE := 820.0
const CONTENT_PADDING := 500.0

const SKY_PARALLAX := 0.05
const CLOUD_PARALLAX := 0.28
const FAR_HILL_PARALLAX := 0.15
const MID_VILLAGE_PARALLAX := 0.32
const NEAR_TREES_PARALLAX := 0.46
const HAZE_PARALLAX := 0.07

const HAZE_COLOR := Color(0.45, 0.28, 0.22, 0.22)
const CLOUD_COLOR := Color(0.35, 0.28, 0.26, 0.4)

var _rng := RandomNumberGenerator.new()
var _camera: Camera2D
var far_hills: Array[Dictionary] = []
var mid_village: Array[Dictionary] = []
var near_trees: Array[Dictionary] = []
var clouds: Array[Dictionary] = []
var debris: Array[Dictionary] = []
var farmland_rows: Array[Dictionary] = []
var plaza_paving: Array[Rect2] = []


func _enter_tree() -> void:
	_rng.seed = 4242
	var content_start := -CONTENT_PADDING
	var content_end := MAP_SIZE.x + CONTENT_PADDING
	_generate_hills(far_hills, 14, content_start, content_end)
	_generate_village_silhouettes(mid_village, 28, content_start, content_end)
	_generate_trees(near_trees, 24, content_start, content_end)
	_generate_debris(content_start, content_end)
	_generate_plaza_paving()
	_generate_farmland()
	_generate_clouds(content_start, content_end)


func _ready() -> void:
	z_index = -20
	set_process(false)
	_redraw_layers()


func bind_camera(camera: Camera2D) -> void:
	_camera = camera
	set_process(true)
	_update_parallax_offsets()


func get_camera_half_view() -> Vector2:
	if _camera == null:
		return Vector2(960.0, 270.0)
	var viewport_size := get_viewport().get_visible_rect().size
	var zoom := _camera.zoom
	return Vector2(
		viewport_size.x / (2.0 * zoom.x),
		viewport_size.y / (2.0 * zoom.y)
	)


func _process(_delta: float) -> void:
	if _camera == null:
		return
	_update_parallax_offsets()


func _update_parallax_offsets() -> void:
	var cam_x := _camera.global_position.x

	$Haze.global_position = Vector2(
		cam_x * (1.0 - HAZE_PARALLAX),
		_camera.global_position.y
	)
	var half_view := get_camera_half_view()
	$Haze.set_meta("half_view", half_view)
	$Haze.queue_redraw()

	$Clouds.position.x = cam_x * (1.0 - CLOUD_PARALLAX)
	$FarHills.position.x = cam_x * (1.0 - FAR_HILL_PARALLAX)
	$MidVillage.position.x = cam_x * (1.0 - MID_VILLAGE_PARALLAX)
	$NearTrees.position.x = cam_x * (1.0 - NEAR_TREES_PARALLAX)
	$Plaza.position.x = cam_x * (1.0 - NEAR_TREES_PARALLAX)
	$Farmland.position.x = cam_x * (1.0 - NEAR_TREES_PARALLAX)


func _redraw_layers() -> void:
	$Clouds.queue_redraw()
	$FarHills.queue_redraw()
	$MidVillage.queue_redraw()
	$NearTrees.queue_redraw()
	$Plaza.queue_redraw()
	$Farmland.queue_redraw()
	$Haze.queue_redraw()


func _generate_hills(target: Array[Dictionary], count: int, content_start: float, content_end: float) -> void:
	var x := content_start - 80.0
	while target.size() < count and x < content_end + 120.0:
		var width := _rng.randf_range(280.0, 520.0)
		var peak_h := _rng.randf_range(100.0, 240.0)
		var points := PackedVector2Array()
		points.append(Vector2(x, GROUND_LINE))
		var segments := _rng.randi_range(4, 7)
		var seg_w := width / float(segments)
		for i in segments:
			var px := x + seg_w * float(i)
			var py := GROUND_LINE - _rng.randf_range(peak_h * 0.35, peak_h)
			points.append(Vector2(px + seg_w * 0.5, py))
		points.append(Vector2(x + width, GROUND_LINE))
		target.append({"points": points, "shade": _rng.randf_range(0.0, 1.0)})
		x += width + _rng.randf_range(-40.0, 60.0)


func _generate_village_silhouettes(target: Array[Dictionary], count: int, content_start: float, content_end: float) -> void:
	var x := content_start
	while target.size() < count and x < content_end:
		if x > 3680.0 and x < 4980.0 and _rng.randf() < 0.7:
			x += _rng.randf_range(60.0, 140.0)
			continue
		if x > 6380.0 and _rng.randf() < 0.55:
			x += _rng.randf_range(80.0, 200.0)
			continue
		var width := _rng.randf_range(70.0, 160.0)
		var height := _rng.randf_range(70.0, 190.0)
		if x > 5000.0 and x < 6400.0:
			width *= 1.1
			height *= 1.05
		target.append({
			"x": x,
			"width": width,
			"height": height,
			"chimney": _rng.randf() < 0.35,
			"roof_style": _rng.randi_range(0, 2),
			"collapsed": _rng.randf() < 0.42,
			"collapse_side": _rng.randf_range(0.25, 0.75),
			"lit_window": _rng.randf() < 0.08,
			"boarded": _rng.randf() < 0.4,
		})
		x += width + _rng.randf_range(10.0, 40.0)


func _generate_trees(target: Array[Dictionary], count: int, content_start: float, content_end: float) -> void:
	var x := content_start + 40.0
	while target.size() < count and x < content_end:
		if x > 6280.0:
			x += _rng.randf_range(120.0, 280.0)
			continue
		target.append({
			"x": x,
			"scale": _rng.randf_range(0.65, 1.35),
			"dead": _rng.randf() < 0.75,
			"lean": _rng.randf_range(-0.15, 0.15),
		})
		x += _rng.randf_range(55.0, 160.0)


func _generate_debris(content_start: float, content_end: float) -> void:
	var x := content_start
	while x < content_end:
		if _rng.randf() < 0.6:
			debris.append({
				"rect": Rect2(x, GROUND_LINE - _rng.randf_range(6.0, 22.0), _rng.randf_range(14.0, 48.0), _rng.randf_range(5.0, 16.0)),
			})
			x += _rng.randf_range(18.0, 70.0)
		else:
			x += _rng.randf_range(30.0, 90.0)


func _generate_plaza_paving() -> void:
	var x := 3720.0
	while x < 4920.0:
		plaza_paving.append(Rect2(x, GROUND_LINE - 6.0, _rng.randf_range(28.0, 64.0), 6.0))
		x += _rng.randf_range(8.0, 36.0)


func _generate_farmland() -> void:
	var x := 6320.0
	while x < MAP_SIZE.x - 200.0:
		farmland_rows.append({
			"x": x,
			"width": _rng.randf_range(90.0, 180.0),
			"height": _rng.randf_range(14.0, 28.0),
		})
		x += _rng.randf_range(20.0, 50.0)


func _generate_clouds(content_start: float, content_end: float) -> void:
	for i in 12:
		clouds.append({
			"pos": Vector2(_rng.randf_range(content_start, content_end), _rng.randf_range(40.0, 260.0)),
			"size": Vector2(_rng.randf_range(200.0, 480.0), _rng.randf_range(32.0, 90.0)),
			"alpha": _rng.randf_range(0.18, 0.38),
		})


static func draw_hills(canvas: CanvasItem, hills: Array[Dictionary]) -> void:
	for hill in hills:
		var shade: float = hill["shade"]
		var color := Color(0.16, 0.2, 0.14).lerp(Color(0.12, 0.14, 0.1), shade)
		canvas.draw_colored_polygon(hill["points"], color)


static func draw_village(canvas: CanvasItem, buildings: Array[Dictionary]) -> void:
	for b in buildings:
		var x: float = b["x"]
		var w: float = b["width"]
		var h: float = b["height"]
		var wall := Color(0.28, 0.24, 0.22)
		var roof := Color(0.16, 0.12, 0.1)
		var soot := Color(0.12, 0.1, 0.09)
		var base_y := GROUND_LINE

		canvas.draw_rect(Rect2(x + 4.0, base_y - h, w - 8.0, h), wall)
		if b["collapsed"]:
			var cx: float = x + w * b["collapse_side"]
			canvas.draw_colored_polygon(
				PackedVector2Array([
					Vector2(cx, base_y - h * 0.5),
					Vector2(cx + w * 0.4, base_y),
					Vector2(cx - w * 0.15, base_y),
				]),
				wall.darkened(0.2)
			)
			canvas.draw_rect(Rect2(cx - 4.0, base_y - h * 0.55, w * 0.45, h * 0.55), soot)

		match b["roof_style"]:
			0:
				if not b["collapsed"]:
					canvas.draw_colored_polygon(
						PackedVector2Array([
							Vector2(x, base_y - h),
							Vector2(x + w * 0.4, base_y - h - 22.0),
							Vector2(x + w, base_y - h),
						]),
						roof
					)
			1:
				canvas.draw_rect(Rect2(x, base_y - h - 12.0, w * 0.7, 12.0), roof)
			2:
				canvas.draw_colored_polygon(
					PackedVector2Array([
						Vector2(x, base_y - h),
						Vector2(x + w * 0.3, base_y - h - 18.0),
						Vector2(x + w * 0.55, base_y - h - 8.0),
						Vector2(x + w, base_y - h),
					]),
					roof.darkened(0.1)
				)

		if b["lit_window"]:
			canvas.draw_rect(Rect2(x + w * 0.35, base_y - h * 0.55, 8.0, 10.0), Color(0.75, 0.38, 0.12, 0.45))
		elif b["boarded"]:
			canvas.draw_rect(Rect2(x + w * 0.3, base_y - h * 0.5, 14.0, 12.0), Color(0.2, 0.16, 0.12))
			canvas.draw_line(Vector2(x + w * 0.32, base_y - h * 0.48), Vector2(x + w * 0.42, base_y - h * 0.38), soot, 1.5)

		if b["chimney"]:
			canvas.draw_rect(Rect2(x + w - 16.0, base_y - h - 28.0, 7.0, 16.0), soot)


static func draw_trees(canvas: CanvasItem, trees: Array[Dictionary], debris_piles: Array[Dictionary] = []) -> void:
	for tree in trees:
		var x: float = tree["x"]
		var s: float = tree["scale"]
		var trunk_h := 30.0 * s
		var trunk_w := 9.0 * s
		var lean: float = tree.get("lean", 0.0)
		canvas.draw_rect(
			Rect2(x - trunk_w * 0.5 + lean * 8.0, GROUND_LINE - trunk_h, trunk_w, trunk_h),
			Color(0.22, 0.18, 0.14)
		)
		if tree.get("dead", true):
			var branch_y := GROUND_LINE - trunk_h
			for angle in [-0.9, -0.4, 0.3, 0.85]:
				var len := 22.0 * s
				var end := Vector2(x + cos(angle) * len, branch_y + sin(angle) * len * 0.4)
				canvas.draw_line(Vector2(x, branch_y), end, Color(0.18, 0.15, 0.13), 2.0)
		else:
			canvas.draw_circle(Vector2(x, GROUND_LINE - trunk_h - 20.0 * s), 24.0 * s, Color(0.14, 0.22, 0.12))

	for pile in debris_piles:
		var rect: Rect2 = pile["rect"]
		canvas.draw_rect(rect, Color(0.22, 0.19, 0.17))


static func draw_plaza(canvas: CanvasItem, paving: Array[Rect2]) -> void:
	var stone := Color(0.3, 0.28, 0.26)
	for rect in paving:
		canvas.draw_rect(rect, stone.darkened(_hash_rect(rect) * 0.08))


static func draw_farmland(canvas: CanvasItem, rows: Array[Dictionary]) -> void:
	var crop := Color(0.22, 0.3, 0.14)
	var soil := Color(0.26, 0.2, 0.14)
	for row in rows:
		var x: float = row["x"]
		var w: float = row["width"]
		var h: float = row["height"]
		canvas.draw_rect(Rect2(x, GROUND_LINE - h, w, h), soil)
		for i in 4:
			var lx := x + i * (w / 4.0) + 4.0
			canvas.draw_rect(Rect2(lx, GROUND_LINE - h - 10.0, w * 0.15, 10.0), crop.darkened(0.05 * i))


static func _hash_rect(rect: Rect2) -> float:
	return fmod(absf(rect.position.x * 0.17 + rect.size.x * 0.31), 1.0)


static func draw_clouds(canvas: CanvasItem, cloud_data: Array[Dictionary]) -> void:
	for cloud in cloud_data:
		var color := CLOUD_COLOR
		color.a = cloud["alpha"]
		var pos: Vector2 = cloud["pos"]
		var size: Vector2 = cloud["size"]
		var center := pos + size * 0.5
		canvas.draw_ellipse(center, size.x * 0.5, size.y * 0.5, color, true, -1.0, true)
		canvas.draw_ellipse(center + Vector2(size.x * 0.12, -size.y * 0.08), size.x * 0.3, size.y * 0.35, color, true, -1.0, true)


static func draw_haze(canvas: CanvasItem, half_view: Vector2 = Vector2(960.0, 270.0)) -> void:
	var pad := 160.0
	var top := -half_view.y - pad
	var bottom := half_view.y + pad
	var left := -half_view.x - CONTENT_PADDING
	var width := half_view.x * 2.0 + CONTENT_PADDING * 2.0
	var bands := 40
	for i in bands:
		var t := float(i) / float(bands - 1)
		var t_next := float(i + 1) / float(bands - 1)
		var y := lerpf(top + (bottom - top) * 0.35, bottom, t)
		var y_next := lerpf(top + (bottom - top) * 0.35, bottom, t_next)
		var color := HAZE_COLOR
		color.a = lerpf(0.04, 0.2, ease(t, -0.8))
		canvas.draw_rect(Rect2(left, y, width, y_next - y + 1.0), color)
