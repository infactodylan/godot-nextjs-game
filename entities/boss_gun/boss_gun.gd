extends Node2D

signal defeated
signal health_changed(current: int, maximum: int)

const MAX_HEALTH := 20
const FIRE_INTERVAL := 1.2
const LOW_SHOT_Y := 808.0
const HIGH_SHOT_Y := 748.0

var health := MAX_HEALTH

var _fire_low := true
var _fire_timer := FIRE_INTERVAL * 0.5

@onready var hitbox: Area2D = $Hitbox
@onready var health_bar_fill: ColorRect = $HealthBar/Fill


func _ready() -> void:
	add_to_group("boss")
	hitbox.add_to_group("boss")
	_update_health_bar()
	health_changed.emit(health, MAX_HEALTH)


func _process(delta: float) -> void:
	if health <= 0:
		return

	_fire_timer -= delta
	if _fire_timer <= 0.0:
		_fire()
		_fire_timer = FIRE_INTERVAL


func _fire() -> void:
	var bullet_scene: PackedScene = preload("res://entities/enemy_bullet/enemy_bullet.tscn")
	var bullet := bullet_scene.instantiate()
	get_tree().current_scene.add_child(bullet)
	var shot_y := LOW_SHOT_Y if _fire_low else HIGH_SHOT_Y
	bullet.global_position = Vector2(global_position.x - 24.0, shot_y)
	_fire_low = not _fire_low


func take_damage(amount: int) -> void:
	if health <= 0:
		return

	health = max(health - amount, 0)
	_update_health_bar()
	health_changed.emit(health, MAX_HEALTH)

	if health <= 0:
		defeated.emit()
		queue_free()


func _update_health_bar() -> void:
	var ratio := float(health) / float(MAX_HEALTH)
	health_bar_fill.size.x = 80.0 * ratio
