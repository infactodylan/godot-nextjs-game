extends Node2D

enum Mode { IDLE, FOLLOW, PATROL, APPROACH }

signal approach_finished

const NPC_NAME := "Mara"
const GROUND_Y := 820.0
const FOLLOW_GAP := 120.0
const FOLLOW_STOP_THRESHOLD := 4.0
const FOLLOW_WALK_SPEED := 145.0
const FOLLOW_CATCHUP_SPEED := 210.0
const PATROL_WALK_SPEED := 52.0
const APPROACH_WALK_SPEED := 155.0
const APPROACH_STOP_GAP := 96.0
const NPC_DRAW_SCALE := 0.82

var _mode := Mode.IDLE
var _walk_phase := 0.0
var _facing := -1.0
var _patrol_direction := 1.0
var _player: CharacterBody2D
var _patrol_min_x := 360.0
var _patrol_max_x := 7420.0
var _follow_min_x := 80.0
var _follow_max_x := 3500.0
var _ground_y := GROUND_Y
var _follow_gap := FOLLOW_GAP


func _ready() -> void:
	z_index = 6
	z_as_relative = false
	visible = false


func configure(player: CharacterBody2D) -> void:
	_player = player


func set_bounds(min_x: float, max_x: float, ground_y: float = GROUND_Y) -> void:
	_follow_min_x = min_x
	_follow_max_x = max_x
	_patrol_min_x = min_x
	_patrol_max_x = max_x
	_ground_y = ground_y


func set_follow_gap(gap: float) -> void:
	_follow_gap = gap


func is_following() -> bool:
	return _mode == Mode.FOLLOW


func start_follow() -> void:
	if _player == null:
		return
	visible = true
	set_process(true)
	_mode = Mode.FOLLOW
	global_position.y = _ground_y


func start_patrol() -> void:
	visible = true
	set_process(true)
	_mode = Mode.PATROL
	if global_position.x <= _patrol_min_x + 8.0:
		_patrol_direction = 1.0
	elif global_position.x >= _patrol_max_x - 8.0:
		_patrol_direction = -1.0
	_facing = _patrol_direction


func start_idle_near(player: CharacterBody2D) -> void:
	configure(player)
	visible = true
	set_process(false)
	_mode = Mode.IDLE
	global_position = Vector2(
		clampf(player.global_position.x - _follow_gap, _follow_min_x, _follow_max_x),
		_ground_y
	)
	_facing = -1.0
	queue_redraw()


func stop_follow() -> void:
	if _mode == Mode.FOLLOW:
		_mode = Mode.IDLE
		set_process(false)


func teleport_near_player() -> void:
	if _player == null:
		return
	global_position = Vector2(
		clampf(_player.global_position.x - _follow_gap, _follow_min_x, _follow_max_x),
		_ground_y
	)


func begin_approach(stop_gap: float = APPROACH_STOP_GAP) -> void:
	if _player == null:
		return
	visible = true
	set_process(true)
	_mode = Mode.APPROACH
	_follow_gap = stop_gap
	global_position.y = _ground_y


func is_approach_complete() -> bool:
	return _mode != Mode.APPROACH


func _is_walking() -> bool:
	return _mode == Mode.FOLLOW or _mode == Mode.PATROL or _mode == Mode.APPROACH


func _draw() -> void:
	if not visible:
		return
	_draw_mara(_is_walking())


func _draw_mara(walking: bool) -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(NPC_DRAW_SCALE * _facing, NPC_DRAW_SCALE))

	var foot_y := 0.0
	var stride := sin(_walk_phase) * 5.0 if walking else 0.0
	var bob := absf(sin(_walk_phase * 2.0)) * 2.0 if walking else 0.0

	var skin := Color(0.38, 0.5, 0.58)
	var coat := Color(0.46, 0.38, 0.32)
	var coat_shadow := coat.darkened(0.14)
	var hair := Color(0.22, 0.18, 0.16)
	var boot := Color(0.18, 0.16, 0.14)

	var left_leg_x := -7.0 + stride * 0.35
	var right_leg_x := 7.0 - stride * 0.35
	draw_rect(Rect2(left_leg_x - 5.0, foot_y - 22.0 - bob, 10.0, 22.0), coat_shadow)
	draw_rect(Rect2(right_leg_x - 5.0, foot_y - 22.0 + bob * 0.5, 10.0, 22.0), coat_shadow)
	draw_rect(Rect2(left_leg_x - 6.0, foot_y - 6.0, 12.0, 6.0), boot)
	draw_rect(Rect2(right_leg_x - 6.0, foot_y - 6.0, 12.0, 6.0), boot)

	draw_rect(Rect2(-15.0, foot_y - 54.0 - bob, 30.0, 34.0), coat)
	draw_rect(Rect2(-11.0, foot_y - 50.0 - bob, 8.0, 26.0), coat.lightened(0.06))

	var left_arm_y := foot_y - 48.0 - bob + stride * 0.25
	var right_arm_y := foot_y - 48.0 - bob - stride * 0.25
	draw_line(Vector2(-15.0, foot_y - 48.0 - bob), Vector2(-24.0, left_arm_y), coat_shadow, 5.0)
	draw_line(Vector2(15.0, foot_y - 48.0 - bob), Vector2(24.0, right_arm_y), coat_shadow, 5.0)
	draw_circle(Vector2(-24.0, left_arm_y), 4.0, skin)
	draw_circle(Vector2(24.0, right_arm_y), 4.0, skin)

	draw_circle(Vector2(0.0, foot_y - 66.0 - bob), 13.0, skin)
	draw_arc(Vector2(0.0, foot_y - 70.0 - bob), 13.0, PI, TAU, 16, hair, 7.0, true)
	draw_rect(Rect2(-13.0, foot_y - 72.0 - bob, 26.0, 8.0), hair)

	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _process(delta: float) -> void:
	if _player == null:
		return

	match _mode:
		Mode.FOLLOW:
			_process_follow(delta)
		Mode.PATROL:
			_process_patrol(delta)
		Mode.APPROACH:
			_process_approach(delta)

	queue_redraw()


func _process_follow(delta: float) -> void:
	var target_x := clampf(
		_player.global_position.x - _follow_gap,
		_follow_min_x,
		_follow_max_x
	)
	var dx := target_x - global_position.x
	if absf(dx) <= FOLLOW_STOP_THRESHOLD:
		global_position.x = target_x
		return

	_walk_phase += delta * 11.0
	var speed := FOLLOW_CATCHUP_SPEED if absf(dx) > 180.0 else FOLLOW_WALK_SPEED
	var dir := signf(dx)
	global_position.x += dir * speed * delta
	_facing = dir


func _process_patrol(delta: float) -> void:
	_walk_phase += delta * 8.0
	global_position.x += _patrol_direction * PATROL_WALK_SPEED * delta
	_facing = _patrol_direction
	if global_position.x >= _patrol_max_x:
		global_position.x = _patrol_max_x
		_patrol_direction = -1.0
	elif global_position.x <= _patrol_min_x:
		global_position.x = _patrol_min_x
		_patrol_direction = 1.0


func _process_approach(delta: float) -> void:
	var target_x := _player.global_position.x + _follow_gap
	_walk_phase += delta * 11.0
	var dx := target_x - global_position.x
	if absf(dx) > 2.0:
		var dir := signf(dx)
		global_position.x += dir * APPROACH_WALK_SPEED * delta
		_facing = dir
		return
	global_position.x = target_x
	_mode = Mode.IDLE
	approach_finished.emit()