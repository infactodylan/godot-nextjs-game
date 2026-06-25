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
const STAND_HEIGHT := 56.0
const CROUCH_HEIGHT := 34.0
const HALF_WIDTH := 18.0
const SQUISH_SPEED := 18.0
const SHOOT_COOLDOWN := 0.25
const SUPER_FIRE_COOLDOWN := 0.08
const INVINCIBILITY_TIME := 0.5
const MAX_HEALTH := 4
const MAX_AMMO := 6
const LOW_AMMO_THRESHOLD := 2
const SUPER_WEAPON_DURATION := 10.0
const SUPER_MAG_SIZE := 20
const SPRITE_SCALE := 0.32
const SPRITE_FEET_Y := -28.0

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
var _was_on_floor := true
var _crouch_anim_played := false
var _normal_modulate := Color.WHITE

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite
@onready var muzzle: Node2D = $Muzzle

var _player_bullet_scene: PackedScene = preload("res://entities/player_bullet/player_bullet.tscn")


func _ready() -> void:
	add_to_group("player")
	animated_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var frames := PlayerSpriteFrames.build()
	if frames.get_animation_names().is_empty():
		push_error("Player has no sprite animations.")
	else:
		animated_sprite.sprite_frames = frames
		animated_sprite.play("idle")
	health_changed.emit(health, MAX_HEALTH)
	ammo_changed.emit(ammo, MAX_AMMO)


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
	_update_muzzle()
	_update_animation(is_crouching, wants_crouch)

	if is_on_floor() and not _was_on_floor:
		animated_sprite.play("land")

	_was_on_floor = is_on_floor()


func _update_animation(is_crouching: bool, wants_crouch: bool) -> void:
	animated_sprite.flip_h = facing_direction < 0.0

	if animated_sprite.animation == "land" and animated_sprite.is_playing():
		return

	if not is_on_floor():
		if velocity.y < -40.0:
			if animated_sprite.animation != "jump":
				animated_sprite.play("jump")
		elif abs(velocity.x) > 40.0:
			if animated_sprite.animation != "air_aim":
				animated_sprite.play("air_aim")
		elif animated_sprite.animation != "fall":
			animated_sprite.play("fall")
		return

	if is_crouching:
		if wants_crouch and not _crouch_anim_played and _current_height > CROUCH_HEIGHT + 2.0:
			animated_sprite.play("crouch_enter")
			_crouch_anim_played = true
		elif animated_sprite.animation != "crouch_enter" or not animated_sprite.is_playing():
			animated_sprite.play("crouch")
		return

	_crouch_anim_played = false

	if abs(velocity.x) > 20.0:
		if animated_sprite.animation != "run":
			animated_sprite.play("run")
	else:
		if animated_sprite.animation != "idle":
			animated_sprite.play("idle")


func _update_muzzle() -> void:
	var half_height := _current_height * 0.5
	var barrel_x := 34.0 * facing_direction
	muzzle.position = Vector2(barrel_x, -half_height - 2.0)


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
	animated_sprite.modulate = Color(1.0, 0.85, 1.0, 1.0)
	super_weapon_changed.emit(true, super_weapon_time_left)


func _deactivate_super_weapon() -> void:
	super_weapon_active = false
	super_weapon_time_left = 0.0
	super_mag_ammo = SUPER_MAG_SIZE
	animated_sprite.modulate = _normal_modulate
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
	animated_sprite.pause()
	died.emit()


func _apply_stance(height: float) -> void:
	var half_height := height * 0.5
	var rect_shape := collision_shape.shape as RectangleShape2D
	rect_shape.size = Vector2(HALF_WIDTH * 2.0, height)
	collision_shape.position = Vector2(0.0, -half_height)
	animated_sprite.position.y = -half_height


func _update_invincibility_visual() -> void:
	var base_color := Color(1.0, 0.85, 1.0, 1.0) if super_weapon_active else _normal_modulate
	if _invincibility_timer > 0.0:
		base_color.a = 0.5 if int(_invincibility_timer * 10.0) % 2 == 0 else 1.0
	animated_sprite.modulate = base_color
