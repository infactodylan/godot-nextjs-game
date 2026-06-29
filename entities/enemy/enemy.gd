extends CharacterBody2D

signal defeated

const SPEED := 110.0
const PATROL_SPEED := 44.0
const NEAR_PLAYER_RANGE := 480.0
const JUMP_VELOCITY := -500.0
const JUMP_FORWARD_SPEED := 300.0
const JUMP_COOLDOWN := 0.5
const AIR_MOMENTUM_TIME := 0.65
const STAND_HEIGHT := 36.0
const SPRITE_TEXTURE_SIZE := 548.0
const SPRITE_FOOT_Y := 500.0
const SPRITE_SCALE := STAND_HEIGHT / 400.0
const HALF_WIDTH := 14.0
const ATTACK_COOLDOWN := 0.8
const PLAYER_JUMP_RANGE_X := 160.0
const PLAYER_JUMP_RANGE_Y := 18.0
const STEP_UP_THRESHOLD := 8.0
const PLATFORM_LOOKAHEAD := 150.0
const LEDGE_LOOKAHEAD := 24.0
const LEDGE_DROP_CHECK := 64.0
const JUMP_TRIGGER_MIN_GAP := 28.0
const JUMP_TRIGGER_MAX_GAP := 120.0
const WORLD_COLLISION_MASK := 2
const EMERGE_DEPTH := 52.0
const EMERGE_DURATION := 0.6
const STUCK_MOVE_THRESHOLD := 0.4
const STUCK_REVERSE_TIME := 1.0
const SEPARATION_BACKOFF_TIME := EnemyCoordinator.SEPARATION_BACKOFF_TIME

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var _player: CharacterBody2D
var _is_dying := false
var _awaiting_ground_for_death := false
var _is_emerging := false
var _emerge_target := Vector2.ZERO
var _emerge_progress := 0.0
var _attack_cooldown := 0.0
var _jump_cooldown := 0.0
var _air_momentum_timer := 0.0
var _platform_jump_active := false
var _jump_active := false
var _jump_was_airborne := false
var _reverse_timer := 0.0
var _forced_direction := 0.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite
@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	add_to_group("enemy")
	animated_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var frames := EnemySpriteFrames.build()
	if not frames.get_animation_names().is_empty():
		animated_sprite.sprite_frames = frames
		animated_sprite.play("idle")
		animated_sprite.scale = Vector2(SPRITE_SCALE, SPRITE_SCALE)
	_apply_stance()
	call_deferred("_find_player")


func _find_player() -> void:
	_player = get_tree().get_first_node_in_group("player") as CharacterBody2D


func is_active() -> bool:
	return not _is_dying and not _is_emerging


func begin_separation_backoff(duration: float = SEPARATION_BACKOFF_TIME) -> void:
	if not is_active() or not is_on_floor():
		return
	if _player == null or not is_instance_valid(_player) or _player.is_dead:
		return
	if _reverse_timer > 0.0:
		return

	var chase_direction := _get_chase_direction()
	if chase_direction == 0.0:
		return

	_forced_direction = -chase_direction
	_reverse_timer = duration
	_update_animation(_forced_direction)


func begin_emerge(target_position: Vector2) -> void:
	_is_emerging = true
	_emerge_target = target_position
	_emerge_progress = 0.0
	velocity = Vector2.ZERO
	set_physics_process(false)
	collision_shape.disabled = true
	global_position = target_position + Vector2(0.0, EMERGE_DEPTH)
	animated_sprite.modulate = Color(0.55, 0.48, 0.42, 1.0)
	set_process(true)


func _process(delta: float) -> void:
	if not _is_emerging:
		return

	_emerge_progress += delta / EMERGE_DURATION
	var t := clampf(_emerge_progress, 0.0, 1.0)
	var eased := 1.0 - pow(1.0 - t, 3.0)
	global_position.y = lerpf(_emerge_target.y + EMERGE_DEPTH, _emerge_target.y, eased)
	animated_sprite.modulate = Color(0.55, 0.48, 0.42, 1.0).lerp(Color.WHITE, eased)
	if t >= 1.0:
		_finish_emerge()


func _finish_emerge() -> void:
	_is_emerging = false
	global_position = _emerge_target
	animated_sprite.modulate = Color.WHITE
	collision_shape.disabled = false
	set_process(false)
	set_physics_process(true)


func _physics_process(delta: float) -> void:
	if _awaiting_ground_for_death:
		_process_death_fall(delta)
		return

	if _is_dying:
		return

	if _attack_cooldown > 0.0:
		_attack_cooldown = maxf(_attack_cooldown - delta, 0.0)
	if _jump_cooldown > 0.0:
		_jump_cooldown = maxf(_jump_cooldown - delta, 0.0)
	if _air_momentum_timer > 0.0:
		_air_momentum_timer = maxf(_air_momentum_timer - delta, 0.0)
	if _reverse_timer > 0.0:
		_reverse_timer = maxf(_reverse_timer - delta, 0.0)
		if _reverse_timer <= 0.0:
			_forced_direction = 0.0

	if not is_on_floor():
		velocity.y += gravity * delta
	elif velocity.y >= 0.0:
		velocity.y = 0.0

	_update_jump_state()

	var chase_direction := 0.0
	if _attack_cooldown > 0.0 and animated_sprite.animation == "attack":
		velocity.x = 0.0
	elif _player and is_instance_valid(_player) and not _player.is_dead:
		chase_direction = _get_chase_direction()
	else:
		velocity.x = 0.0
		_update_animation(0.0)

	var direction := chase_direction
	if _forced_direction != 0.0:
		direction = _forced_direction
		if is_on_floor() and _should_stop_at_ledge(_forced_direction, false):
			direction = 0.0
			_forced_direction = 0.0
			_reverse_timer = 0.0
	elif chase_direction != 0.0 and is_on_floor() and _should_stop_at_ledge(chase_direction):
		direction = 0.0

	if _forced_direction != 0.0:
		_update_animation(_forced_direction)
	elif direction != 0.0:
		_update_animation(direction)
	elif chase_direction != 0.0 and _attack_cooldown <= 0.0:
		animated_sprite.flip_h = chase_direction < 0.0
		if animated_sprite.animation != "idle":
			animated_sprite.play("idle")

	var jumped := false
	if (
		_forced_direction == 0.0
		and is_on_floor()
		and _jump_cooldown <= 0.0
		and _attack_cooldown <= 0.0
		and chase_direction != 0.0
		and _wants_jump(chase_direction)
	):
		if EnemyCoordinator.is_lead_enemy(self, _player) and EnemyCoordinator.request_jump(self):
			var platform_jump := _needs_platform_jump(chase_direction)
			if platform_jump:
				_begin_platform_jump()
			else:
				_jump_active = true
				_jump_was_airborne = false
			velocity.y = JUMP_VELOCITY
			velocity.x = chase_direction * JUMP_FORWARD_SPEED
			_jump_cooldown = JUMP_COOLDOWN
			_air_momentum_timer = AIR_MOMENTUM_TIME
			jumped = true

	if not jumped and direction != 0.0 and _attack_cooldown <= 0.0:
		if _forced_direction == 0.0 and (_air_momentum_timer > 0.0 or not is_on_floor()):
			velocity.x = chase_direction * JUMP_FORWARD_SPEED
		else:
			velocity.x = direction * _get_ground_move_speed()

	var previous_x := global_position.x
	move_and_slide()
	EnemyCoordinator.queue_spacing()
	if _forced_direction == 0.0:
		_check_world_stuck(chase_direction, previous_x)
	_check_player_collision()


func _get_chase_direction() -> float:
	var direction := signf(_player.global_position.x - global_position.x)
	if direction == 0.0:
		direction = -1.0 if animated_sprite.flip_h else 1.0
	return direction


func _get_ground_move_speed() -> float:
	if _player == null or not is_instance_valid(_player) or _player.is_dead:
		return PATROL_SPEED

	var distance := absf(_player.global_position.x - global_position.x)
	var blend := 1.0 - clampf(distance / NEAR_PLAYER_RANGE, 0.0, 1.0)
	return lerpf(PATROL_SPEED, SPEED, blend)


func _should_stop_at_ledge(direction: float, allow_jump_override: bool = true) -> bool:
	if direction == 0.0 or not is_on_floor():
		return false
	if _has_ground_ahead(direction):
		return false
	if allow_jump_override and _wants_jump(direction):
		return false
	return true


func _has_ground_ahead(direction: float) -> bool:
	var space_state := get_world_2d().direct_space_state
	var exclude: Array[RID] = [get_rid()]
	var feet_y := global_position.y
	var sample_offsets: Array[float] = [HALF_WIDTH + 4.0, HALF_WIDTH + LEDGE_LOOKAHEAD]
	for offset in sample_offsets:
		var ahead_x := global_position.x + direction * offset
		var from := Vector2(ahead_x, feet_y - 4.0)
		var to := Vector2(ahead_x, feet_y + LEDGE_DROP_CHECK)
		if _raycast(space_state, from, to, exclude).is_empty():
			return false
	return true


func _check_world_stuck(chase_direction: float, previous_x: float) -> void:
	if (
		chase_direction == 0.0
		or not is_on_floor()
		or _attack_cooldown > 0.0
		or absf(velocity.x) < 4.0
	):
		return

	if absf(global_position.x - previous_x) > STUCK_MOVE_THRESHOLD:
		return

	if not _is_world_blocking(chase_direction):
		return

	_forced_direction = -chase_direction
	_reverse_timer = STUCK_REVERSE_TIME
	_update_animation(_forced_direction)


func _is_world_blocking(direction: float) -> bool:
	if _is_world_blocking_slide(direction):
		return true
	return not test_move(global_transform, Vector2(direction * 12.0, 0.0))


func _is_world_blocking_slide(direction: float) -> bool:
	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		var collider := collision.get_collider()
		if collider == null:
			continue
		if collider.is_in_group("player"):
			continue
		if collider.is_in_group("enemy"):
			continue
		var normal := collision.get_normal()
		if absf(normal.x) > 0.35 and signf(normal.x) != direction:
			return true
	return false


func _process_death_fall(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 420.0 * delta)
	if not is_on_floor():
		velocity.y += gravity * delta
	elif velocity.y > 0.0:
		velocity.y = 0.0
	move_and_slide()
	if is_on_floor():
		_begin_death_animation()


func _update_jump_state() -> void:
	if not _platform_jump_active and not _jump_active:
		return

	if not is_on_floor():
		_jump_was_airborne = true
	elif _jump_was_airborne:
		if _platform_jump_active:
			_end_platform_jump()
		else:
			_end_jump()


func _end_jump() -> void:
	_jump_active = false
	_jump_was_airborne = false
	EnemyCoordinator.release_jump(self)


func _begin_platform_jump() -> void:
	_platform_jump_active = true
	_jump_active = true
	_jump_was_airborne = false
	for node in get_tree().get_nodes_in_group("platform"):
		if node is CollisionObject2D:
			add_collision_exception_with(node)


func _end_platform_jump() -> void:
	if not _platform_jump_active:
		return

	_platform_jump_active = false
	_jump_active = false
	_jump_was_airborne = false
	for node in get_tree().get_nodes_in_group("platform"):
		if node is CollisionObject2D:
			remove_collision_exception_with(node)
	EnemyCoordinator.release_jump(self)


func _update_animation(direction: float) -> void:
	if _attack_cooldown > 0.0 and animated_sprite.animation == "attack":
		return
	if _forced_direction != 0.0:
		direction = _forced_direction

	animated_sprite.flip_h = direction < 0.0
	if animated_sprite.animation != "walk":
		animated_sprite.play("walk")


func _wants_jump(direction: float) -> bool:
	if _is_player_above():
		return true
	return _get_nearest_blocking_platform(direction) != null


func _needs_platform_jump(direction: float) -> bool:
	return not _is_player_above() and _get_nearest_blocking_platform(direction) != null


func _get_nearest_blocking_platform(direction: float) -> Node2D:
	var nearest: Node2D = null
	var nearest_gap := INF

	for node in get_tree().get_nodes_in_group("platform"):
		if not node is Node2D:
			continue
		var platform := node as Node2D
		if _can_walk_under_platform(platform, direction):
			continue

		var edge_gap := _platform_edge_gap(platform, direction)
		if edge_gap < JUMP_TRIGGER_MIN_GAP or edge_gap > JUMP_TRIGGER_MAX_GAP:
			continue

		var roof_y := _platform_roof_y(platform)
		if roof_y >= global_position.y - STEP_UP_THRESHOLD:
			continue

		if edge_gap < nearest_gap:
			nearest_gap = edge_gap
			nearest = platform

	return nearest


func _platform_edge_gap(platform: Node2D, direction: float) -> float:
	var half_w: float = 90.0
	if platform.has_method("get_half_width"):
		half_w = platform.call("get_half_width")
	elif platform.has_meta("half_width"):
		half_w = platform.get_meta("half_width")

	if direction < 0.0:
		return global_position.x - (platform.global_position.x + half_w)
	return (platform.global_position.x - half_w) - global_position.x


func _platform_roof_y(platform: Node2D) -> float:
	var roof_y := platform.global_position.y
	if platform.has_method("get_roof_offset"):
		roof_y -= platform.call("get_roof_offset")
	elif platform.has_meta("roof_offset"):
		roof_y -= platform.get_meta("roof_offset")
	return roof_y


func _can_walk_under_platform(platform: Node2D, direction: float) -> bool:
	if not platform is WreckPlatformBody:
		return false
	if platform.wreck_type != WreckPlatformBody.WreckType.STREET_SIGN:
		return false

	var half_w: float = platform.get_half_width()
	var edge_gap := _platform_edge_gap(platform, direction)
	if edge_gap < 0.0 or edge_gap > PLATFORM_LOOKAHEAD:
		return false

	var body_center_y := global_position.y - STAND_HEIGHT * 0.5
	var clearance_y := platform.global_position.y - WreckPlatformBody.SIGN_CLEARANCE + STAND_HEIGHT * 0.5
	if body_center_y < clearance_y - 4.0:
		return false

	var space_state := get_world_2d().direct_space_state
	var exclude: Array[RID] = [get_rid()]
	var from_x := global_position.x + direction * (HALF_WIDTH + 4.0)
	var to_x: float = platform.global_position.x + direction * half_w * 0.35
	var from := Vector2(from_x, body_center_y)
	var to := Vector2(to_x, body_center_y)
	return _raycast(space_state, from, to, exclude).is_empty()


func _is_player_above() -> bool:
	if _player == null or not is_instance_valid(_player):
		return false
	var delta_y := global_position.y - _player.global_position.y
	if delta_y < PLAYER_JUMP_RANGE_Y:
		return false
	return absf(_player.global_position.x - global_position.x) <= PLAYER_JUMP_RANGE_X


func _raycast(
	space_state: PhysicsDirectSpaceState2D,
	from: Vector2,
	to: Vector2,
	exclude: Array[RID]
) -> Dictionary:
	var query := PhysicsRayQueryParameters2D.create(from, to)
	query.collision_mask = WORLD_COLLISION_MASK
	query.exclude = exclude
	query.hit_from_inside = true
	return space_state.intersect_ray(query)


func _check_player_collision() -> void:
	for i in get_slide_collision_count():
		var collider := get_slide_collision(i).get_collider()
		if collider and collider.is_in_group("player") and collider.has_method("take_damage"):
			if _is_player_stomping_from_above(collider):
				continue
			collider.take_damage(1)
			_play_attack()


func _is_player_stomping_from_above(player: Node) -> bool:
	if not player is CharacterBody2D:
		return false

	var body := player as CharacterBody2D
	if body.velocity.y <= 0.0:
		return false

	var player_feet_y := body.global_position.y
	var enemy_top_y := global_position.y - STAND_HEIGHT
	if player_feet_y > enemy_top_y + 14.0:
		return false

	var player_half_width := 18.0
	var player_left := body.global_position.x - player_half_width
	var player_right := body.global_position.x + player_half_width
	var enemy_left := global_position.x - HALF_WIDTH
	var enemy_right := global_position.x + HALF_WIDTH
	return enemy_left < player_right and enemy_right > player_left


func _play_attack() -> void:
	if _is_dying or _attack_cooldown > 0.0:
		return

	_attack_cooldown = ATTACK_COOLDOWN
	velocity.x = 0.0
	_air_momentum_timer = 0.0
	AudioManager.play_enemy_roar()
	animated_sprite.play("attack")


func die() -> void:
	if _is_dying:
		return

	_is_dying = true
	_is_emerging = false
	set_process(false)
	if _platform_jump_active:
		_end_platform_jump()
	elif _jump_active:
		_end_jump()
	else:
		EnemyCoordinator.clear_jump_if(self)

	if is_on_floor():
		_begin_death_animation()
	else:
		_awaiting_ground_for_death = true


func _begin_death_animation() -> void:
	_awaiting_ground_for_death = false
	velocity = Vector2.ZERO
	set_physics_process(false)
	collision_shape.set_deferred("disabled", true)
	AudioManager.play_enemy_death()
	animated_sprite.animation_finished.connect(_on_death_animation_finished, CONNECT_ONE_SHOT)
	animated_sprite.play("dead")


func _on_death_animation_finished() -> void:
	if animated_sprite.animation != "dead":
		return
	defeated.emit()
	queue_free()


func _apply_stance() -> void:
	var half_height := STAND_HEIGHT * 0.5
	var rect_shape := collision_shape.shape as RectangleShape2D
	rect_shape.size = Vector2(HALF_WIDTH * 2.0, STAND_HEIGHT)
	collision_shape.position = Vector2(0.0, -half_height)
	animated_sprite.position.y = -(SPRITE_FOOT_Y - SPRITE_TEXTURE_SIZE * 0.5) * SPRITE_SCALE
