extends CharacterBody2D

signal health_changed(current: int, maximum: int)
signal ammo_changed(current: int, maximum: int)
signal super_weapon_changed(active: bool, seconds_left: float)
signal died

const SPEED := 300.0
const JUMP_VELOCITY := -480.0
const COYOTE_TIME := 0.12
const JUMP_BUFFER_TIME := 0.12
const JUMP_CUT_MULTIPLIER := 0.45
const STAND_HEIGHT := 48.0
const CROUCH_HEIGHT := 28.0
const HALF_WIDTH := 16.0
const SQUISH_SPEED := 18.0
const SHOOT_COOLDOWN := 0.25
const SUPER_FIRE_COOLDOWN := 0.08
const INVINCIBILITY_TIME := 0.5
const MAX_HEALTH := 4
const MAX_AMMO := 6
const LOW_AMMO_THRESHOLD := 2
const SUPER_WEAPON_DURATION := 10.0
const SUPER_MAG_SIZE := 20

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var facing_direction := 1.0
var health := MAX_HEALTH
var ammo := MAX_AMMO
var is_dead := false
var super_weapon_active := false
var super_weapon_time_left := 0.0
var super_mag_ammo := SUPER_MAG_SIZE

var _coyote_timer := 0.0
var _jump_buffer_timer := 0.0
var _current_height := STAND_HEIGHT
var _shoot_cooldown := 0.0
var _invincibility_timer := 0.0
var _normal_visual_color := Color(0.25, 0.65, 1, 1)

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var visual: ColorRect = $Visual
@onready var direction_indicator: ColorRect = $DirectionIndicator
@onready var muzzle: Node2D = $Muzzle

var _player_bullet_scene: PackedScene = preload("res://entities/player_bullet/player_bullet.tscn")


func _ready() -> void:
	add_to_group("player")
	_normal_visual_color = visual.color
	health_changed.emit(health, MAX_HEALTH)
	ammo_changed.emit(ammo, MAX_AMMO)
	_update_direction_indicator()


func _physics_process(delta: float) -> void:
	if is_dead:
		return

	_shoot_cooldown = max(_shoot_cooldown - delta, 0.0)
	_invincibility_timer = max(_invincibility_timer - delta, 0.0)
	_update_invincibility_visual()

	if super_weapon_active:
		super_weapon_time_left -= delta
		super_weapon_changed.emit(true, super_weapon_time_left)
		if super_weapon_time_left <= 0.0:
			_deactivate_super_weapon()
		elif Input.is_action_pressed("shoot"):
			_try_shoot_super()

	var wants_crouch := Input.is_action_pressed("move_down")
	var target_height := CROUCH_HEIGHT if wants_crouch else STAND_HEIGHT
	_current_height = move_toward(_current_height, target_height, SQUISH_SPEED * delta * (STAND_HEIGHT - CROUCH_HEIGHT))
	_apply_stance(_current_height)

	if is_on_floor():
		_coyote_timer = COYOTE_TIME
	else:
		_coyote_timer = max(_coyote_timer - delta, 0.0)
		velocity.y += gravity * delta

	if Input.is_action_just_pressed("jump"):
		_jump_buffer_timer = JUMP_BUFFER_TIME
	else:
		_jump_buffer_timer = max(_jump_buffer_timer - delta, 0.0)

	var direction := Input.get_axis("move_left", "move_right")
	if direction != 0.0:
		facing_direction = direction
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0.0, SPEED)

	muzzle.position = Vector2(20.0 * facing_direction, -_current_height * 0.5)
	_update_direction_indicator()

	var is_crouching := _current_height < STAND_HEIGHT - 1.0
	if _jump_buffer_timer > 0.0 and _coyote_timer > 0.0 and not is_crouching:
		velocity.y = JUMP_VELOCITY
		_coyote_timer = 0.0
		_jump_buffer_timer = 0.0

	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= JUMP_CUT_MULTIPLIER

	if not super_weapon_active and Input.is_action_just_pressed("shoot"):
		_try_shoot()

	move_and_slide()


func _try_shoot() -> void:
	if _shoot_cooldown > 0.0 or ammo <= 0:
		return

	_shoot_cooldown = SHOOT_COOLDOWN
	ammo -= 1
	ammo_changed.emit(ammo, MAX_AMMO)
	_fire_bullet()


func _try_shoot_super() -> void:
	if _shoot_cooldown > 0.0:
		return

	if super_mag_ammo <= 0:
		super_mag_ammo = SUPER_MAG_SIZE

	super_mag_ammo -= 1
	_shoot_cooldown = SUPER_FIRE_COOLDOWN
	_fire_bullet()


func _fire_bullet() -> void:
	AudioManager.play_player_shoot()
	var bullet := _player_bullet_scene.instantiate()
	get_tree().current_scene.add_child(bullet)
	bullet.global_position = muzzle.global_position
	bullet.direction = facing_direction


func add_ammo() -> void:
	ammo = MAX_AMMO
	ammo_changed.emit(ammo, MAX_AMMO)


func activate_super_weapon() -> void:
	super_weapon_active = true
	super_weapon_time_left = SUPER_WEAPON_DURATION
	super_mag_ammo = SUPER_MAG_SIZE
	visual.color = Color(0.95, 0.55, 1.0, 1.0)
	super_weapon_changed.emit(true, super_weapon_time_left)


func _deactivate_super_weapon() -> void:
	super_weapon_active = false
	super_weapon_time_left = 0.0
	super_mag_ammo = SUPER_MAG_SIZE
	visual.color = _normal_visual_color
	super_weapon_changed.emit(false, 0.0)


func take_damage(amount: int) -> void:
	if is_dead or _invincibility_timer > 0.0:
		return

	health = max(health - amount, 0)
	_invincibility_timer = INVINCIBILITY_TIME
	health_changed.emit(health, MAX_HEALTH)

	if health <= 0:
		die()


func die() -> void:
	if is_dead:
		return

	is_dead = true
	velocity = Vector2.ZERO
	set_physics_process(false)
	died.emit()


func _apply_stance(height: float) -> void:
	var half_height := height * 0.5
	var rect_shape := collision_shape.shape as RectangleShape2D
	rect_shape.size = Vector2(HALF_WIDTH * 2.0, height)
	collision_shape.position = Vector2(0.0, -half_height)
	visual.offset_left = -HALF_WIDTH
	visual.offset_top = -height
	visual.offset_right = HALF_WIDTH
	visual.offset_bottom = 0.0
	_update_direction_indicator()


func _update_direction_indicator() -> void:
	var half_height := _current_height * 0.5
	var indicator_width := 10.0
	var indicator_height := 8.0
	var y_top := -half_height - indicator_height * 0.5
	var y_bottom := y_top + indicator_height

	if facing_direction > 0.0:
		direction_indicator.offset_left = HALF_WIDTH
		direction_indicator.offset_right = HALF_WIDTH + indicator_width
	else:
		direction_indicator.offset_left = -HALF_WIDTH - indicator_width
		direction_indicator.offset_right = -HALF_WIDTH

	direction_indicator.offset_top = y_top
	direction_indicator.offset_bottom = y_bottom


func _update_invincibility_visual() -> void:
	if _invincibility_timer > 0.0:
		visual.modulate.a = 0.5 if int(_invincibility_timer * 10.0) % 2 == 0 else 1.0
	else:
		visual.modulate.a = 1.0
