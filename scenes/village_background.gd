extends Node2D
class_name VillageBackground

const MAP_SIZE := Vector2(7800.0, 900.0)
const GROUND_LINE := 820.0
const BACKDROP_LINE := 700.0
const CONTENT_PADDING := 500.0

const SKY_PARALLAX := 0.05
const SKYLINE_PARALLAX := 0.09
const CLOUD_PARALLAX := 0.22
const FAR_HILL_PARALLAX := 0.15
const MID_VILLAGE_PARALLAX := 0.32
const NEAR_TREES_PARALLAX := 0.46
const HAZE_PARALLAX := 0.07

const CLOUD_DRIFT_SPEED := 14.0
const CLOUD_LOOP_WIDTH := MAP_SIZE.x + CONTENT_PADDING * 2.0

const HAZE_COLOR := Color(0.45, 0.28, 0.22, 0.22)
const CLOUD_COLOR := Color(0.42, 0.3, 0.34, 0.32)
const SKYLINE_COLOR := Color(0.12, 0.08, 0.12, 0.95)
const DISTANT_BUILDING_COLOR := Color(0.26, 0.2, 0.22, 0.72)
const DISTANT_TREE_COLOR := Color(0.18, 0.15, 0.16, 0.65)

var _rng := RandomNumberGenerator.new()
var _camera: Camera2D
var _cloud_drift := 0.0
var skyline: Array[Dictionary] = []
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
	_generate_skyline(content_start, content_end)
	_generate_hills(far_hills, 14, content_start, content_end)
	_generate_village_silhouettes(mid_village, 32, content_start, content_end)
	_generate_trees(near_trees, 28, content_start, content_end)
	_generate_debris(content_start, content_end)
	_generate_plaza_paving()
	_generate_farmland()
	_generate_clouds(content_start, content_end)


func _ready() -> void:
	z_index = -20
	set_process(false)
	_redraw_layers()


func get_cloud_drift() -> float:
	return _cloud_drift


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


func _process(delta: float) -> void:
	if _camera == null:
		return
	_cloud_drift = fmod(_cloud_drift + delta * CLOUD_DRIFT_SPEED, CLOUD_LOOP_WIDTH)
	_update_parallax_offsets()
	$Clouds.queue_redraw()


func _update_parallax_offsets() -> void:
	var cam_x := _camera.global_position.x
	var half_view := get_camera_half_view()

	$Haze.global_position = Vector2(
		cam_x * (1.0 - HAZE_PARALLAX),
		_camera.global_position.y
	)
	$Haze.set_meta("half_view", half_view)
	$Haze.queue_redraw()

	$Clouds.position.x = cam_x * (1.0 - CLOUD_PARALLAX)
	$Skyline.position.x = cam_x * (1.0 - SKYLINE_PARALLAX)
	$FarHills.position.x = cam_x * (1.0 - FAR_HILL_PARALLAX)
	$MidVillage.position.x = cam_x * (1.0 - MID_VILLAGE_PARALLAX)
	$NearTrees.position.x = cam_x * (1.0 - NEAR_TREES_PARALLAX)
	$Plaza.position.x = cam_x * (1.0 - NEAR_TREES_PARALLAX)
	$Farmland.position.x = cam_x * (1.0 - NEAR_TREES_PARALLAX)


func _redraw_layers() -> void:
	$Skyline.queue_redraw()
	$Clouds.queue_redraw()
	$FarHills.queue_redraw()
	$MidVillage.queue_redraw()
	$NearTrees.queue_redraw()
	$Plaza.queue_redraw()
	$Farmland.queue_redraw()
	$Haze.queue_redraw()


func _generate_skyline(content_start: float, content_end: float) -> void:
	var x := content_start - 120.0
	while x < content_end + 160.0:
		var width := _rng.randf_range(48.0, 140.0)
		var height := _rng.randf_range(240.0, 520.0)
		skyline.append({
			"x": x,
			"width": width,
			"height": height,
			"spire": _rng.randf() < 0.28,
			"antenna": _rng.randf() < 0.22,
			"broken": _rng.randf() < 0.55,
			"break_ratio": _rng.randf_range(0.35, 0.78),
			"shade": _rng.randf_range(0.0, 1.0),
		})
		x += width + _rng.randf_range(4.0, 22.0)


func _generate_hills(target: Array[Dictionary], count: int, content_start: float, content_end: float) -> void:
	var x := content_start - 80.0
	while target.size() < count and x < content_end + 120.0:
		var width := _rng.randf_range(280.0, 520.0)
		var peak_h := _rng.randf_range(100.0, 240.0)
		var points := PackedVector2Array()
		points.append(Vector2(x, BACKDROP_LINE))
		var segments := _rng.randi_range(4, 7)
		var seg_w := width / float(segments)
		for i in segments:
			var px := x + seg_w * float(i)
			var py := BACKDROP_LINE - _rng.randf_range(peak_h * 0.35, peak_h)
			points.append(Vector2(px + seg_w * 0.5, py))
		points.append(Vector2(x + width, BACKDROP_LINE))
		target.append({"points": points, "shade": _rng.randf_range(0.0, 1.0)})
		x += width + _rng.randf_range(-40.0, 60.0)


func _generate_village_silhouettes(target: Array[Dictionary], count: int, content_start: float, content_end: float) -> void:
	var x := content_start
	while target.size() < count and x < content_end:
		if x > 3680.0 and x < 4980.0 and _rng.randf() < 0.7:
			x += _rng.randf_range(60.0, 140.0)
			continue
		if x > 2080.0 and x < 2720.0:
			x += _rng.randf_range(120.0, 220.0)
			continue
		if x > 6380.0 and _rng.randf() < 0.55:
			x += _rng.randf_range(80.0, 200.0)
			continue
		var width := _rng.randf_range(70.0, 160.0)
		var height := _rng.randf_range(120.0, 320.0)
		if x > 5000.0 and x < 6400.0:
			width *= 1.1
			height *= 1.05
		target.append({
			"x": x,
			"width": width,
			"height": height,
			"chimney": _rng.randf() < 0.35,
			"roof_style": _rng.randi_range(0, 2),
			"collapsed": _rng.randf() < 0.62,
			"collapse_side": _rng.randf_range(0.25, 0.75),
			"lit_window": false,
			"boarded": _rng.randf() < 0.55,
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
	var loop_start := -CONTENT_PADDING
	var loop_end := MAP_SIZE.x + CONTENT_PADDING
	for i in 22:
		clouds.append({
			"pos": Vector2(_rng.randf_range(loop_start, loop_end), _rng.randf_range(36.0, 280.0)),
			"size": Vector2(_rng.randf_range(220.0, 520.0), _rng.randf_range(28.0, 86.0)),
			"alpha": _rng.randf_range(0.14, 0.34),
			"drift_scale": _rng.randf_range(0.75, 1.25),
		})


static func draw_skyline(canvas: CanvasItem, buildings: Array[Dictionary]) -> void:
	var base_y := BACKDROP_LINE
	for building in buildings:
		var x: float = building["x"]
		var w: float = building["width"]
		var h: float = building["height"]
		var shade: float = building["shade"]
		var color := SKYLINE_COLOR.lerp(Color(0.14, 0.09, 0.13, 0.88), shade)
		var top_y := base_y - h

		canvas.draw_rect(Rect2(x + 3.0, top_y, w - 6.0, h), color)

		if building["broken"]:
			var break_x: float = x + w * float(building["break_ratio"])
			canvas.draw_colored_polygon(
				PackedVector2Array([
					Vector2(break_x, top_y + h * 0.22),
					Vector2(break_x + w * 0.34, base_y),
					Vector2(break_x - w * 0.12, base_y),
				]),
				color.darkened(0.12)
			)

		if building["spire"]:
			canvas.draw_rect(Rect2(x + w * 0.42, top_y - 34.0, w * 0.12, 34.0), color.lightened(0.04))
			canvas.draw_colored_polygon(
				PackedVector2Array([
					Vector2(x + w * 0.48, top_y - 52.0),
					Vector2(x + w * 0.38, top_y - 34.0),
					Vector2(x + w * 0.58, top_y - 34.0),
				]),
				color
			)

		if building["antenna"]:
			var ax := x + w * 0.72
			canvas.draw_line(Vector2(ax, top_y), Vector2(ax, top_y - 48.0), color.lightened(0.08), 1.5)
			canvas.draw_line(
				Vector2(ax - 8.0, top_y - 40.0),
				Vector2(ax + 8.0, top_y - 40.0),
				color.lightened(0.08),
				1.2
			)


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
		var wall := DISTANT_BUILDING_COLOR
		var roof := DISTANT_BUILDING_COLOR.darkened(0.14)
		var soot := DISTANT_BUILDING_COLOR.darkened(0.22)
		var base_y := BACKDROP_LINE

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
			var window_y := base_y - h * 0.55
			var window_w := 8.0
			var window_h := 10.0
			var glow := Color(0.95, 0.72, 0.32, 0.22)
			for slot in 2:
				var wx := x + w * (0.28 + slot * 0.28)
				canvas.draw_rect(Rect2(wx, window_y, window_w, window_h), glow)
		elif b["boarded"]:
			canvas.draw_rect(Rect2(x + w * 0.3, base_y - h * 0.5, 14.0, 12.0), soot)
			canvas.draw_line(
				Vector2(x + w * 0.32, base_y - h * 0.48),
				Vector2(x + w * 0.42, base_y - h * 0.38),
				soot.darkened(0.1),
				1.5
			)

		if b["chimney"]:
			canvas.draw_rect(Rect2(x + w - 16.0, base_y - h - 28.0, 7.0, 16.0), soot)


static func draw_trees(canvas: CanvasItem, trees: Array[Dictionary], debris_piles: Array[Dictionary] = []) -> void:
	for tree in trees:
		var x: float = tree["x"]
		var s: float = tree["scale"]
		var trunk_h := 30.0 * s
		var trunk_w := 9.0 * s
		var lean: float = tree.get("lean", 0.0)
		var trunk_color := DISTANT_TREE_COLOR.darkened(0.05)
		canvas.draw_rect(
			Rect2(x - trunk_w * 0.5 + lean * 8.0, BACKDROP_LINE - trunk_h, trunk_w, trunk_h),
			trunk_color
		)
		if tree.get("dead", true):
			var branch_y := BACKDROP_LINE - trunk_h
			for angle in [-0.9, -0.4, 0.3, 0.85]:
				var len := 22.0 * s
				var end := Vector2(x + cos(angle) * len, branch_y + sin(angle) * len * 0.4)
				canvas.draw_line(Vector2(x, branch_y), end, trunk_color.darkened(0.08), 2.0)
			canvas.draw_circle(
				Vector2(x + lean * 6.0, branch_y - 6.0 * s),
				18.0 * s,
				Color(trunk_color.r, trunk_color.g, trunk_color.b, 0.18)
			)
		else:
			canvas.draw_circle(
				Vector2(x, BACKDROP_LINE - trunk_h - 20.0 * s),
				24.0 * s,
				Color(0.14, 0.18, 0.13, 0.35)
			)

	for pile in debris_piles:
		var rect: Rect2 = pile["rect"]
		canvas.draw_rect(rect, Color(0.22, 0.19, 0.17, 0.42))


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


static func draw_clouds(
	canvas: CanvasItem,
	cloud_data: Array[Dictionary],
	drift_x: float = 0.0,
	loop_width: float = CLOUD_LOOP_WIDTH
) -> void:
	for cloud in cloud_data:
		var color := CLOUD_COLOR
		color.a = cloud["alpha"]
		var pos: Vector2 = cloud["pos"]
		var size: Vector2 = cloud["size"]
		var scale: float = cloud.get("drift_scale", 1.0)
		var base_x := posmod(pos.x + drift_x * scale, loop_width) - CONTENT_PADDING
		for tile in [-1, 0, 1]:
			var wrapped_x: float = base_x + float(tile) * loop_width
			var center := Vector2(wrapped_x + size.x * 0.5, pos.y + size.y * 0.5)
			canvas.draw_ellipse(center, size.x * 0.5, size.y * 0.5, color, true, -1.0, true)
			canvas.draw_ellipse(
				center + Vector2(size.x * 0.12, -size.y * 0.08),
				size.x * 0.3,
				size.y * 0.35,
				color,
				true,
				-1.0,
				true
			)


static func draw_depth_softening(canvas: CanvasItem, strength: float = 1.0) -> void:
	var top := BACKDROP_LINE - 560.0
	var height := 580.0
	var left := -CONTENT_PADDING
	var width := MAP_SIZE.x + CONTENT_PADDING * 2.0
	var bands := 20
	for i in bands:
		var t0 := float(i) / float(bands)
		var t1 := float(i + 1) / float(bands)
		var y0 := top + height * t0
		var y1 := top + height * t1
		var color := Color(0.38, 0.22, 0.28, lerpf(0.01, 0.08, t0) * strength)
		canvas.draw_rect(Rect2(left, y0, width, y1 - y0 + 1.0), color)


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
