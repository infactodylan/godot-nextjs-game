extends CharacterBody2D

signal health_changed(current: int, maximum: int)
signal ammo_changed(current: int, maximum: int)
signal super_weapon_changed(active: bool, seconds_left: float)
signal died
signal first_enemy_on_top(enemy: CharacterBody2D)

const SPEED := 300.0
const JUMP_VELOCITY := -480.0
const DOUBLE_JUMP_VELOCITY := -420.0
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
const STUN_TIME := 0.3
const MAX_HEALTH := 4
const MAX_AMMO := 6
const LOW_AMMO_THRESHOLD := 2
const SUPER_WEAPON_DURATION := 10.0
const SUPER_MAG_SIZE := 20
const SPRITE_SCALE := 56.0 / 278.0
const SPRITE_TEXTURE_SIZE := 512.0
const SPRITE_FOOT_Y := 510.0
const GUN_HAND_OFFSET := Vector2(12.0, -34.0)
const GUN_BARREL_LENGTH := 26.0
const FIRE_POSE_TIME := 0.14
const SHAKE_OFF_SWITCHES := 3
const SHAKE_OFF_WINDOW := 1.1
const ENEMY_HALF_WIDTH := 14.0
const ENEMY_STAND_HEIGHT := 36.0
const STOMP_TOLERANCE := 14.0

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var facing_direction := 1.0
var health := MAX_HEALTH
var ammo := MAX_AMMO
var is_dead := false
var _death_animation_started := false
var super_weapon_active := false
var super_weapon_time_left := 0.0
var super_mag_ammo := SUPER_MAG_SIZE

var _coyote_timer := 0.0
var _jump_buffer_timer := 0.0
var _double_jump_available := false
var _current_height := STAND_HEIGHT
var _shoot_cooldown := 0.0
var _invincibility_timer := 0.0
var _stun_timer := 0.0
var _fire_pose_timer := 0.0
var _normal_modulate := Color.WHITE
var _last_nonzero_move_direction := 0.0
var _direction_switch_count := 0
var _direction_switch_timer := 0.0
var _shake_off_hint_triggered := false

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite
@onready var muzzle: Node2D = $Muzzle

var _player_bullet_scene: PackedScene = preload("res://entities/player_bullet/player_bullet.tscn")


func _ready() -> void:
	z_index = WreckPlatformVisual.PLAYER_SORT_Z
	z_as_relative = false
	add_to_group("player")
	animated_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var frames := PlayerSpriteFrames.build()
	if frames.get_animation_names().is_empty():
		push_error("Player has no sprite animations.")
	else:
		animated_sprite.sprite_frames = frames
		animated_sprite.play("idle")
	_apply_stance(STAND_HEIGHT)
	health_changed.emit(health, MAX_HEALTH)
	ammo_changed.emit(ammo, MAX_AMMO)


func _physics_process(delta: float) -> void:
	if is_dead:
		if not _death_animation_started:
			_process_death_fall(delta)
		return

	_shoot_cooldown = max(_shoot_cooldown - delta, 0.0)
	_invincibility_timer = max(_invincibility_timer - delta, 0.0)
	_stun_timer = max(_stun_timer - delta, 0.0)
	_fire_pose_timer = max(_fire_pose_timer - delta, 0.0)
	_update_invincibility_visual()

	var is_stunned := _stun_timer > 0.0

	if super_weapon_active and not is_stunned:
		super_weapon_time_left -= delta
		super_weapon_changed.emit(true, super_weapon_time_left)
		if super_weapon_time_left <= 0.0:
			_deactivate_super_weapon()
		elif Input.is_action_pressed("shoot"):
			_try_shoot_super()

	var direction := 0.0
	var wants_crouch := false
	var jump_just_pressed := false

	if not is_stunned:
		direction = Input.get_axis("move_left", "move_right")
		wants_crouch = Input.is_action_pressed("move_down")
		jump_just_pressed = Input.is_action_just_pressed("jump")
		if jump_just_pressed:
			_jump_buffer_timer = JUMP_BUFFER_TIME
		else:
			_jump_buffer_timer = max(_jump_buffer_timer - delta, 0.0)
	else:
		_jump_buffer_timer = max(_jump_buffer_timer - delta, 0.0)
		velocity.x = move_toward(velocity.x, 0.0, SPEED * 2.0)

	var target_height := CROUCH_HEIGHT if wants_crouch else STAND_HEIGHT
	_current_height = move_toward(_current_height, target_height, SQUISH_SPEED * delta * (STAND_HEIGHT - CROUCH_HEIGHT))
	_apply_stance(_current_height)

	if is_on_floor():
		_coyote_timer = COYOTE_TIME
		_double_jump_available = true
	else:
		_coyote_timer = max(_coyote_timer - delta, 0.0)
		velocity.y += gravity * delta

	if not is_stunned:
		if direction != 0.0:
			velocity.x = direction * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0.0, SPEED)

	var is_crouching := _current_height < STAND_HEIGHT - 1.0
	if not is_stunned:
		if _jump_buffer_timer > 0.0 and _coyote_timer > 0.0 and not is_crouching:
			velocity.y = JUMP_VELOCITY
			_coyote_timer = 0.0
			_jump_buffer_timer = 0.0
		elif jump_just_pressed and not is_on_floor() and _double_jump_available and not is_crouching:
			velocity.y = DOUBLE_JUMP_VELOCITY
			_double_jump_available = false
			_jump_buffer_timer = 0.0

		if Input.is_action_just_released("jump") and velocity.y < 0.0:
			velocity.y *= JUMP_CUT_MULTIPLIER

		if not super_weapon_active and Input.is_action_just_pressed("shoot"):
			_try_shoot()

	var was_falling := velocity.y > 0.0
	move_and_slide()
	if was_falling:
		_check_stomp_enemies()
	_clamp_to_screen_bounds()
	if not is_stunned:
		_update_shake_off(delta, direction)
		_update_aim_facing()
	_update_muzzle()
	_update_animation(is_crouching)


func _update_animation(is_crouching: bool) -> void:
	animated_sprite.flip_h = facing_direction < 0.0

	if _fire_pose_timer > 0.0:
		var fire_anim := _pick_fire_animation(is_crouching)
		if animated_sprite.animation != fire_anim:
			animated_sprite.play(fire_anim)
		return

	var target_anim := _pick_movement_animation(is_crouching)
	if animated_sprite.animation != target_anim:
		animated_sprite.play(target_anim)


func _pick_movement_animation(is_crouching: bool) -> String:
	if not is_on_floor():
		return "fall" if velocity.y > 0.0 else "jump"
	if is_crouching:
		return "crouch"
	if abs(velocity.x) > 20.0:
		return "run"
	return "idle"


func _pick_fire_animation(is_crouching: bool) -> String:
	if _is_aiming_up():
		return "shoot_up"
	if not is_on_floor():
		return "fall_shoot" if velocity.y > 0.0 else "jump_shoot"
	if is_crouching:
		return "crouch_shoot"
	if abs(velocity.x) > 20.0:
		return "run_shoot"
	return "shoot"


func _update_shake_off(delta: float, move_direction: float) -> void:
	var enemies_on_top := _get_enemies_on_top()
	if enemies_on_top.is_empty():
		_direction_switch_count = 0
		_direction_switch_timer = 0.0
		return

	if not _shake_off_hint_triggered:
		_shake_off_hint_triggered = true
		first_enemy_on_top.emit(enemies_on_top[0])

	_direction_switch_timer = maxf(_direction_switch_timer - delta, 0.0)
	if _direction_switch_timer <= 0.0:
		_direction_switch_count = 0

	if move_direction == 0.0:
		return

	var signed_direction := signf(move_direction)
	if (
		_last_nonzero_move_direction != 0.0
		and signed_direction != _last_nonzero_move_direction
	):
		_direction_switch_count += 1
		_direction_switch_timer = SHAKE_OFF_WINDOW
		if _direction_switch_count >= SHAKE_OFF_SWITCHES:
			for enemy in enemies_on_top:
				if is_instance_valid(enemy) and enemy.has_method("die"):
					enemy.die()
			_direction_switch_count = 0
			_direction_switch_timer = 0.0

	_last_nonzero_move_direction = signed_direction


func _get_enemies_on_top() -> Array[CharacterBody2D]:
	var results: Array[CharacterBody2D] = []
	var player_top := global_position.y - _current_height
	var player_left := global_position.x - HALF_WIDTH
	var player_right := global_position.x + HALF_WIDTH

	for node in get_tree().get_nodes_in_group("enemy"):
		if not node is CharacterBody2D:
			continue
		var enemy := node as CharacterBody2D
		if enemy.has_method("is_active") and not enemy.is_active():
			continue

		var enemy_left := enemy.global_position.x - ENEMY_HALF_WIDTH
		var enemy_right := enemy.global_position.x + ENEMY_HALF_WIDTH
		var x_overlap := enemy_left < player_right and enemy_right > player_left
		if not x_overlap:
			continue

		var enemy_feet_y := enemy.global_position.y
		var feet_on_head := enemy_feet_y <= player_top + 14.0 and enemy_feet_y >= player_top - 26.0
		if feet_on_head:
			results.append(enemy)

	return results


func _check_stomp_enemies() -> void:
	var checked: Array[CharacterBody2D] = []

	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		_try_stomp_enemy(collision.get_collider(), collision.get_normal(), checked)

	if is_on_floor():
		var last_collision := get_last_slide_collision()
		if last_collision:
			_try_stomp_enemy(
				last_collision.get_collider(),
				last_collision.get_normal(),
				checked
			)


func _try_stomp_enemy(
	collider: Object,
	normal: Vector2,
	checked: Array[CharacterBody2D]
) -> void:
	if collider == null or not collider is CharacterBody2D:
		return

	var enemy := collider as CharacterBody2D
	if not enemy.is_in_group("enemy") or enemy in checked:
		return

	if enemy.has_method("is_active") and not enemy.is_active():
		return

	if normal.y >= -0.3:
		return

	if not _is_stomping_enemy(enemy):
		return

	checked.append(enemy)
	if enemy.has_method("die"):
		enemy.die()
	take_damage(1)


func _is_stomping_enemy(enemy: CharacterBody2D) -> bool:
	var player_feet_y := global_position.y
	var enemy_top_y := enemy.global_position.y - ENEMY_STAND_HEIGHT
	if player_feet_y > enemy_top_y + STOMP_TOLERANCE:
		return false

	var enemy_left := enemy.global_position.x - ENEMY_HALF_WIDTH
	var enemy_right := enemy.global_position.x + ENEMY_HALF_WIDTH
	var player_left := global_position.x - HALF_WIDTH
	var player_right := global_position.x + HALF_WIDTH
	return enemy_left < player_right and enemy_right > player_left


func _clamp_to_screen_bounds() -> void:
	var camera := get_viewport().get_camera_2d()
	if not camera:
		return

	var half_view := get_viewport().get_visible_rect().size / (2.0 * camera.zoom)
	var center := camera.get_screen_center_position()
	var min_x := center.x - half_view.x + HALF_WIDTH
	var max_x := center.x + half_view.x - HALF_WIDTH

	if global_position.x < min_x:
		global_position.x = min_x
		velocity.x = maxf(velocity.x, 0.0)
	elif global_position.x > max_x:
		global_position.x = max_x
		velocity.x = minf(velocity.x, 0.0)


func _update_muzzle() -> void:
	var aim_direction := _get_aim_direction()
	var height_ratio := _current_height / STAND_HEIGHT
	var hand := Vector2(GUN_HAND_OFFSET.x, GUN_HAND_OFFSET.y * height_ratio)
	if facing_direction < 0.0:
		hand.x *= -1.0
	muzzle.position = hand + aim_direction * GUN_BARREL_LENGTH * height_ratio


func _update_aim_facing() -> void:
	var aim_direction := _get_aim_direction()
	if absf(aim_direction.x) > 0.15:
		facing_direction = signf(aim_direction.x)


func _is_aiming_up() -> bool:
	var aim_direction := _get_aim_direction()
	return aim_direction.y < 0.0 and absf(aim_direction.y) >= absf(aim_direction.x)


func _start_fire_pose() -> void:
	_fire_pose_timer = FIRE_POSE_TIME
	var is_crouching := _current_height < STAND_HEIGHT - 1.0
	animated_sprite.play(_pick_fire_animation(is_crouching))


func _get_aim_direction() -> Vector2:
	var half_height := _current_height * 0.5
	var aim_origin := global_position + Vector2(0.0, -half_height - 4.0)
	var to_mouse := get_global_mouse_position() - aim_origin
	if to_mouse.length_squared() < 1.0:
		return Vector2(facing_direction, 0.0)
	return to_mouse.normalized()


func _try_shoot() -> void:
	if _shoot_cooldown > 0.0 or ammo <= 0:
		return

	_shoot_cooldown = SHOOT_COOLDOWN
	ammo -= 1
	ammo_changed.emit(ammo, MAX_AMMO)
	_start_fire_pose()
	_fire_bullet()


func _try_shoot_super() -> void:
	if _shoot_cooldown > 0.0:
		return

	if super_mag_ammo <= 0:
		super_mag_ammo = SUPER_MAG_SIZE

	super_mag_ammo -= 1
	_shoot_cooldown = SUPER_FIRE_COOLDOWN
	_start_fire_pose()
	_fire_bullet()


func _fire_bullet() -> void:
	AudioManager.play_player_shoot()
	var bullet := _player_bullet_scene.instantiate()
	get_tree().current_scene.add_child(bullet)
	bullet.global_position = muzzle.global_position
	bullet.direction = _get_aim_direction()


func add_ammo() -> void:
	ammo = MAX_AMMO
	ammo_changed.emit(ammo, MAX_AMMO)
	AudioManager.play_player_reload()


func heal_to_full() -> void:
	if is_dead:
		return

	health = MAX_HEALTH
	_invincibility_timer = INVINCIBILITY_TIME
	health_changed.emit(health, MAX_HEALTH)
	AudioManager.play_player_reload()


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


func take_damage(amount: int, stun: bool = false) -> void:
	if is_dead or _invincibility_timer > 0.0:
		return

	health = max(health - amount, 0)
	_invincibility_timer = INVINCIBILITY_TIME
	if stun:
		_stun_timer = STUN_TIME
	health_changed.emit(health, MAX_HEALTH)

	if health <= 0:
		die()


func die() -> void:
	if is_dead:
		return

	is_dead = true
	_fire_pose_timer = 0.0
	if super_weapon_active:
		_deactivate_super_weapon()

	if is_on_floor():
		_start_death_animation()


func should_camera_follow() -> bool:
	return not _death_animation_started


func _process_death_fall(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, SPEED)
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0.0

	_current_height = STAND_HEIGHT
	_apply_stance(STAND_HEIGHT)
	move_and_slide()
	animated_sprite.flip_h = facing_direction < 0.0
	var fall_anim := "fall" if velocity.y > 0.0 or not is_on_floor() else "idle"
	if animated_sprite.animation != fall_anim:
		animated_sprite.play(fall_anim)

	if is_on_floor():
		_start_death_animation()


func _start_death_animation() -> void:
	if _death_animation_started:
		return

	_death_animation_started = true
	velocity = Vector2.ZERO
	animated_sprite.flip_h = facing_direction < 0.0
	animated_sprite.animation_finished.connect(_on_death_animation_finished, CONNECT_ONE_SHOT)
	animated_sprite.play("death")


func _on_death_animation_finished() -> void:
	if animated_sprite.animation != "death":
		return
	died.emit()


func _apply_stance(height: float) -> void:
	var half_height := height * 0.5
	var height_ratio := height / STAND_HEIGHT
	var rect_shape := collision_shape.shape as RectangleShape2D
	rect_shape.size = Vector2(HALF_WIDTH * 2.0, height)
	collision_shape.position = Vector2(0.0, -half_height)
	animated_sprite.position.y = -(SPRITE_FOOT_Y - SPRITE_TEXTURE_SIZE * 0.5) * SPRITE_SCALE * height_ratio
	animated_sprite.scale = Vector2(SPRITE_SCALE, SPRITE_SCALE * height_ratio)


func _update_invincibility_visual() -> void:
	var base_color := Color(1.0, 0.85, 1.0, 1.0) if super_weapon_active else _normal_modulate
	if _invincibility_timer > 0.0:
		base_color.a = 0.5 if int(_invincibility_timer * 10.0) % 2 == 0 else 1.0
	animated_sprite.modulate = base_color
