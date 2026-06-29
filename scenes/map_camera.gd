extends Camera2D
class_name MapCamera

const PLAY_ZOOM_FROM_CONFIGURED := 0.5
const OVERVIEW_ZOOM_OUT_EXTRA := 1.5
const ZOOM_LERP_SPEED := 1.6

var _play_zoom := 1.0
var _map_size := Vector2.ZERO


func _ready() -> void:
	process_priority = -10


func configure(play_zoom: float, map_size: Vector2) -> void:
	_play_zoom = play_zoom * PLAY_ZOOM_FROM_CONFIGURED
	_map_size = map_size
	zoom = Vector2(_play_zoom, _play_zoom)


func _process(delta: float) -> void:
	if get_tree().paused or not is_current():
		return
	var target := _overview_zoom() if Input.is_action_pressed("map_overview") else _play_zoom
	var next := move_toward(zoom.x, target, ZOOM_LERP_SPEED * delta)
	if is_equal_approx(next, zoom.x):
		return
	zoom = Vector2(next, next)


func _overview_zoom() -> float:
	return _play_zoom / OVERVIEW_ZOOM_OUT_EXTRA
