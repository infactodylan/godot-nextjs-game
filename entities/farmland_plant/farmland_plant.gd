extends Node2D
class_name FarmlandPlant

enum PlantStyle { GRASS_TUFT, CROP_STALKS, WEED_BUSH, BRAMBLE }

var _style: PlantStyle = PlantStyle.GRASS_TUFT
var _plant_scale := 1.0
var _in_front := false
var _rng := RandomNumberGenerator.new()


func configure(style: PlantStyle, plant_scale: float, in_front: bool) -> void:
	_style = style
	_plant_scale = plant_scale
	_in_front = in_front
	_rng.seed = hash(str(get_instance_id()) + str(style))
	queue_redraw()


func _draw() -> void:
	var s := _plant_scale
	var base_alpha := 0.92 if _in_front else 0.78
	match _style:
		PlantStyle.GRASS_TUFT:
			_draw_grass_tuft(s, base_alpha)
		PlantStyle.CROP_STALKS:
			_draw_crop_stalks(s, base_alpha)
		PlantStyle.WEED_BUSH:
			_draw_weed_bush(s, base_alpha)
		PlantStyle.BRAMBLE:
			_draw_bramble(s, base_alpha)


func _draw_grass_tuft(s: float, base_alpha: float) -> void:
	var stem := Color(0.2, 0.32, 0.12, base_alpha)
	var blade := Color(0.28, 0.42, 0.16, base_alpha * 0.95)
	for i in 7:
		var bx := _rng.randf_range(-16.0, 16.0) * s
		var bh := _rng.randf_range(28.0, 58.0) * s
		var tilt := _rng.randf_range(-0.35, 0.35)
		draw_line(
			Vector2(bx, 0.0),
			Vector2(bx + sin(tilt) * bh, -bh),
			blade if i % 2 == 0 else stem,
			_rng.randf_range(2.0, 3.5)
		)


func _draw_crop_stalks(s: float, base_alpha: float) -> void:
	var stalk := Color(0.34, 0.38, 0.14, base_alpha)
	var head := Color(0.42, 0.34, 0.12, base_alpha * 0.9)
	for i in 4:
		var sx := (-18.0 + i * 12.0) * s
		var sh := (52.0 + i * 8.0) * s
		draw_line(Vector2(sx, 0.0), Vector2(sx + 4.0 * s, -sh), stalk, 3.0 * s)
		draw_colored_polygon(
			PackedVector2Array([
				Vector2(sx - 5.0 * s, -sh + 6.0 * s),
				Vector2(sx + 10.0 * s, -sh - 4.0 * s),
				Vector2(sx + 14.0 * s, -sh + 10.0 * s),
			]),
			head
		)


func _draw_weed_bush(s: float, base_alpha: float) -> void:
	var leaf := Color(0.22, 0.36, 0.14, base_alpha)
	var dark := Color(0.14, 0.24, 0.1, base_alpha * 0.85)
	var radius := 22.0 * s
	draw_circle(Vector2(0.0, -18.0 * s), radius * 0.55, dark)
	for i in 6:
		var angle := _rng.randf_range(-2.4, -0.6)
		var dist := _rng.randf_range(14.0, 28.0) * s
		var center := Vector2(cos(angle) * dist * 0.5, sin(angle) * dist - 12.0 * s)
		draw_circle(center, _rng.randf_range(10.0, 18.0) * s, leaf if i % 2 == 0 else dark)


func _draw_bramble(s: float, base_alpha: float) -> void:
	var vine := Color(0.18, 0.3, 0.12, base_alpha)
	var thorn := Color(0.12, 0.2, 0.08, base_alpha)
	for i in 5:
		var start_x := _rng.randf_range(-12.0, 12.0) * s
		var end := Vector2(
			start_x + _rng.randf_range(-20.0, 20.0) * s,
			_rng.randf_range(-50.0, -22.0) * s
		)
		draw_line(Vector2(start_x, 0.0), end, vine, 2.5 * s)
		draw_circle(end, 8.0 * s, thorn)
	if _in_front:
		draw_colored_polygon(
			PackedVector2Array([
				Vector2(-24.0 * s, -8.0 * s),
				Vector2(0.0, -42.0 * s),
				Vector2(26.0 * s, -6.0 * s),
				Vector2(8.0 * s, 2.0 * s),
				Vector2(-10.0 * s, 2.0 * s),
			]),
			Color(0.2, 0.34, 0.13, base_alpha * 0.75)
		)
