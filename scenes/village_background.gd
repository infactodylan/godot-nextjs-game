extends Node2D
class_name VillageBackground

const MAP_SIZE := Vector2(3600.0, 900.0)
const GROUND_LINE := 820.0
const CONTENT_PADDING := 500.0

const SKY_PARALLAX := 0.05
const CLOUD_PARALLAX := 0.28
const FAR_HILL_PARALLAX := 0.15
const MID_VILLAGE_PARALLAX := 0.32
const NEAR_TREES_PARALLAX := 0.46
const HAZE_PARALLAX := 0.07

const HAZE_COLOR := Color(0.85, 0.62, 0.38, 0.18)
const CLOUD_COLOR := Color(0.95, 0.82, 0.68, 0.35)

var _rng := RandomNumberGenerator.new()
var _camera: Camera2D
var far_hills: Array[Dictionary] = []
var mid_village: Array[Dictionary] = []
var near_trees: Array[Dictionary] = []
var clouds: Array[Dictionary] = []


func _enter_tree() -> void:
	_rng.seed = 4242
	var content_start := -CONTENT_PADDING
	var content_end := MAP_SIZE.x + CONTENT_PADDING
	_generate_hills(far_hills, 14, content_start, content_end)
	_generate_village_silhouettes(mid_village, 28, content_start, content_end)
	_generate_trees(near_trees, 24, content_start, content_end)
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
	$FarHills.position.x = cam_x * (1.0 - FAR_HILL_PARALLAX)
	$MidVillage.position.x = cam_x * (1.0 - MID_VILLAGE_PARALLAX)
	$NearTrees.position.x = cam_x * (1.0 - NEAR_TREES_PARALLAX)
	$Haze.position.x = cam_x * (1.0 - HAZE_PARALLAX)


func _redraw_layers() -> void:
	$Sky.queue_redraw()
	$Clouds.queue_redraw()
	$FarHills.queue_redraw()
	$MidVillage.queue_redraw()
	$NearTrees.queue_redraw()
	$Haze.queue_redraw()


func _generate_hills(target: Array[Dictionary], count: int, content_start: float, content_end: float) -> void:
	var x := content_start - 80.0
	while target.size() < count and x < content_end + 120.0:
		var width := _rng.randf_range(280.0, 520.0)
		var peak_h := _rng.randf_range(120.0, 280.0)
		var points := PackedVector2Array()
		points.append(Vector2(x, GROUND_LINE))
		var segments := _rng.randi_range(4, 7)
		var seg_w := width / float(segments)
		for i in segments:
			var px := x + seg_w * float(i)
			var py := GROUND_LINE - _rng.randf_range(peak_h * 0.4, peak_h)
			points.append(Vector2(px + seg_w * 0.5, py))
		points.append(Vector2(x + width, GROUND_LINE))
		target.append({"points": points, "shade": _rng.randf_range(0.0, 1.0)})
		x += width + _rng.randf_range(-40.0, 60.0)


func _generate_village_silhouettes(target: Array[Dictionary], count: int, content_start: float, content_end: float) -> void:
	var x := content_start
	while target.size() < count and x < content_end:
		var width := _rng.randf_range(70.0, 160.0)
		var height := _rng.randf_range(80.0, 200.0)
		var has_chimney := _rng.randf() < 0.45
		var roof_style := _rng.randi_range(0, 2)
		target.append({
			"x": x,
			"width": width,
			"height": height,
			"chimney": has_chimney,
			"roof_style": roof_style,
			"lit_window": _rng.randf() < 0.25,
		})
		x += width + _rng.randf_range(12.0, 48.0)


func _generate_trees(target: Array[Dictionary], count: int, content_start: float, content_end: float) -> void:
	var x := content_start + 40.0
	while target.size() < count and x < content_end:
		var scale := _rng.randf_range(0.7, 1.4)
		var style := _rng.randi_range(0, 1)
		target.append({
			"x": x,
			"scale": scale,
			"style": style,
		})
		x += _rng.randf_range(60.0, 180.0)


func _generate_clouds(content_start: float, content_end: float) -> void:
	for i in 14:
		clouds.append({
			"pos": Vector2(_rng.randf_range(content_start, content_end), _rng.randf_range(30.0, 280.0)),
			"size": Vector2(_rng.randf_range(180.0, 420.0), _rng.randf_range(28.0, 80.0)),
			"alpha": _rng.randf_range(0.2, 0.45),
		})


static func draw_hills(canvas: CanvasItem, hills: Array[Dictionary]) -> void:
	for hill in hills:
		var shade: float = hill["shade"]
		var color := Color(0.28, 0.42, 0.22).lerp(Color(0.22, 0.36, 0.18), shade)
		canvas.draw_colored_polygon(hill["points"], color)


static func draw_village(canvas: CanvasItem, buildings: Array[Dictionary]) -> void:
	for b in buildings:
		var x: float = b["x"]
		var w: float = b["width"]
		var h: float = b["height"]
		var wall := Color(0.55, 0.42, 0.32)
		var roof := Color(0.38, 0.22, 0.16)
		var base_y := GROUND_LINE

		canvas.draw_rect(Rect2(x + 4.0, base_y - h, w - 8.0, h), wall)
		match b["roof_style"]:
			0:
				canvas.draw_colored_polygon(
					PackedVector2Array([
						Vector2(x, base_y - h),
						Vector2(x + w * 0.5, base_y - h - 28.0),
						Vector2(x + w, base_y - h),
					]),
					roof
				)
			1:
				canvas.draw_rect(Rect2(x, base_y - h - 16.0, w, 16.0), roof)
			2:
				canvas.draw_colored_polygon(
					PackedVector2Array([
						Vector2(x, base_y - h),
						Vector2(x + w * 0.25, base_y - h - 22.0),
						Vector2(x + w * 0.5, base_y - h - 32.0),
						Vector2(x + w * 0.75, base_y - h - 22.0),
						Vector2(x + w, base_y - h),
					]),
					roof
				)

		if b["lit_window"]:
			canvas.draw_rect(Rect2(x + w * 0.35, base_y - h * 0.55, 10.0, 12.0), Color(0.95, 0.78, 0.35, 0.6))

		if b["chimney"]:
			canvas.draw_rect(Rect2(x + w - 18.0, base_y - h - 36.0, 8.0, 20.0), Color(0.42, 0.38, 0.36))


static func draw_trees(canvas: CanvasItem, trees: Array[Dictionary]) -> void:
	for tree in trees:
		var x: float = tree["x"]
		var s: float = tree["scale"]
		var trunk_h := 28.0 * s
		var trunk_w := 10.0 * s
		var foliage_r := 34.0 * s
		canvas.draw_rect(Rect2(x - trunk_w * 0.5, GROUND_LINE - trunk_h, trunk_w, trunk_h), Color(0.38, 0.28, 0.18))
		if tree["style"] == 0:
			canvas.draw_circle(Vector2(x, GROUND_LINE - trunk_h - foliage_r * 0.4), foliage_r, Color(0.22, 0.48, 0.2))
		else:
			canvas.draw_colored_polygon(
				PackedVector2Array([
					Vector2(x, GROUND_LINE - trunk_h - foliage_r * 1.2),
					Vector2(x - foliage_r, GROUND_LINE - trunk_h),
					Vector2(x + foliage_r, GROUND_LINE - trunk_h),
				]),
				Color(0.2, 0.44, 0.18)
			)


static func draw_clouds(canvas: CanvasItem, cloud_data: Array[Dictionary]) -> void:
	for cloud in cloud_data:
		var color := CLOUD_COLOR
		color.a = cloud["alpha"]
		var pos: Vector2 = cloud["pos"]
		var size: Vector2 = cloud["size"]
		var center := pos + size * 0.5
		canvas.draw_ellipse(center, size.x * 0.5, size.y * 0.5, color, true, -1.0, true)
		canvas.draw_ellipse(center + Vector2(size.x * 0.15, -size.y * 0.1), size.x * 0.32, size.y * 0.38, color, true, -1.0, true)


static func draw_haze(canvas: CanvasItem) -> void:
	var draw_left := -CONTENT_PADDING
	var draw_width := MAP_SIZE.x + CONTENT_PADDING * 2.0
	var bands := 36
	for i in bands:
		var t := float(i) / float(bands - 1)
		var t_next := float(i + 1) / float(bands - 1)
		var y := lerpf(MAP_SIZE.y * 0.4, MAP_SIZE.y, t)
		var y_next := lerpf(MAP_SIZE.y * 0.4, MAP_SIZE.y, t_next)
		var color := HAZE_COLOR
		color.a = lerpf(0.02, 0.14, ease(t, -0.8))
		canvas.draw_rect(Rect2(draw_left, y, draw_width, y_next - y + 1.0), color)
