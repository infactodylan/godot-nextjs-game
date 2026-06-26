extends Node2D

const AMMO_OFFSET_X := -24.0
const HEALTH_OFFSET_X := 6.0
const HEAD_CLEARANCE := 10.0
const BULLET_BODY_W := 3.0
const BULLET_BODY_H := 9.0
const BULLET_TIP_H := 2.0
const BULLET_GAP := 2.5
const BAR_WIDTH := 30.0
const BAR_HEIGHT := 5.0
const BAR_PADDING := 1.0

var _health := 4
var _max_health := 4
var _ammo := 6
var _max_ammo := 6

var _player: Node


func _ready() -> void:
	_player = get_parent()
	z_index = WreckPlatformVisual.PLAYER_SORT_Z + 1
	z_as_relative = false
	_player.health_changed.connect(_on_health_changed)
	_player.ammo_changed.connect(_on_ammo_changed)
	_player.super_weapon_changed.connect(_on_super_weapon_changed)
	_health = _player.health
	_max_health = _player.MAX_HEALTH
	_ammo = _player.ammo
	_max_ammo = _player.MAX_AMMO
	queue_redraw()


func _process(_delta: float) -> void:
	if _player.super_weapon_active:
		var super_ammo: int = _player.super_mag_ammo
		var super_max: int = _player.SUPER_MAG_SIZE
		if super_ammo != _ammo or super_max != _max_ammo:
			_ammo = super_ammo
			_max_ammo = super_max
			queue_redraw()
	elif _max_ammo != _player.MAX_AMMO:
		_ammo = _player.ammo
		_max_ammo = _player.MAX_AMMO
		queue_redraw()


func _on_health_changed(current: int, maximum: int) -> void:
	_health = current
	_max_health = maximum
	queue_redraw()


func _on_ammo_changed(current: int, maximum: int) -> void:
	if _player.super_weapon_active:
		return
	_ammo = current
	_max_ammo = maximum
	queue_redraw()


func _on_super_weapon_changed(active: bool, _seconds_left: float) -> void:
	if active:
		_ammo = _player.super_mag_ammo
		_max_ammo = _player.SUPER_MAG_SIZE
	else:
		_ammo = _player.ammo
		_max_ammo = _player.MAX_AMMO
	queue_redraw()


func _draw() -> void:
	if _player.is_dead:
		return

	var head_y := _get_head_y()
	_draw_ammo(Vector2(AMMO_OFFSET_X, head_y))
	_draw_health(Vector2(HEALTH_OFFSET_X, head_y))


func _get_head_y() -> float:
	var shape_node := _player.get_node("CollisionShape2D") as CollisionShape2D
	var rect := shape_node.shape as RectangleShape2D
	var half_height := rect.size.y * 0.5
	return shape_node.position.y - half_height - HEAD_CLEARANCE


func _draw_ammo(origin: Vector2) -> void:
	if _max_ammo <= 0:
		return

	var bullet_w := BULLET_BODY_W
	var bullet_gap := BULLET_GAP
	var total_width := _max_ammo * bullet_w + (_max_ammo - 1) * bullet_gap
	if total_width > 34.0:
		var scale := 34.0 / total_width
		bullet_w *= scale
		bullet_gap *= scale

	for i in _max_ammo:
		var x := origin.x + i * (bullet_w + bullet_gap)
		var filled := i < _ammo
		var body_color := Color(0.92, 0.74, 0.18, 1.0) if filled else Color(0.28, 0.24, 0.18, 0.45)
		var tip_color := Color(1.0, 0.88, 0.42, 1.0) if filled else Color(0.35, 0.3, 0.22, 0.35)
		var tip_h := BULLET_TIP_H * (bullet_w / BULLET_BODY_W)
		var body_h := BULLET_BODY_H * (bullet_w / BULLET_BODY_W)
		draw_rect(Rect2(x, origin.y, bullet_w, body_h), body_color)
		draw_rect(Rect2(x, origin.y - tip_h, bullet_w, tip_h), tip_color)


func _draw_health(origin: Vector2) -> void:
	var back_rect := Rect2(origin.x, origin.y, BAR_WIDTH, BAR_HEIGHT)
	draw_rect(back_rect, Color(0.1, 0.08, 0.08, 0.85))
	draw_rect(back_rect.grow(-BAR_PADDING), Color(0.18, 0.14, 0.14, 0.9))

	var ratio := 0.0 if _max_health <= 0 else float(_health) / float(_max_health)
	var inner := back_rect.grow(-BAR_PADDING)
	var fill_width := inner.size.x * ratio
	if fill_width <= 0.0:
		return

	var fill_color := Color(0.32, 0.82, 0.34, 1.0)
	if ratio <= 0.25:
		fill_color = Color(0.9, 0.24, 0.2, 1.0)
	elif ratio <= 0.5:
		fill_color = Color(0.92, 0.62, 0.18, 1.0)

	draw_rect(Rect2(inner.position.x, inner.position.y, fill_width, inner.size.y), fill_color)
