extends Node2D

signal finished
signal blackout_dialogue_finished

const NPC_NAME := "Mara"
const GROUND_Y := 820.0
const APPROACH_OFFSET := 420.0
const APPROACH_STOP_GAP := 96.0
const APPROACH_WALK_SPEED := 155.0
const PATROL_MIN_X := 360.0
const PATROL_MAX_X := 7420.0
const PATROL_WALK_SPEED := 52.0
const NPC_DRAW_SCALE := 0.82

enum Step {
	NONE,
	APPROACH,
	INTRO,
	MOVE,
	JUMP,
	CROUCH,
	SHOOT,
	OUTRO,
	PATROL,
	BLACKOUT_APPROACH,
	BLACKOUT_DIALOGUE,
}

var _step := Step.NONE
var _walk_phase := 0.0
var _facing := -1.0
var _patrol_direction := 1.0
var _hud: CanvasLayer
var _player: CharacterBody2D


func _ready() -> void:
	z_index = 6
	z_as_relative = false
	visible = false


func configure(hud: CanvasLayer, player: CharacterBody2D) -> void:
	_hud = hud
	_player = player


func start_if_needed() -> void:
	if _player == null or _hud == null:
		return
	if GameState.is_controls_tutorial_complete():
		_resume_after_tutorial()
		return
	visible = true
	set_process(true)
	_step = Step.APPROACH
	_walk_phase = 0.0
	_facing = -1.0
	global_position = Vector2(_player.global_position.x + APPROACH_OFFSET, GROUND_Y)
	_player.set_physics_process(false)
	_player.velocity = Vector2.ZERO


func is_active() -> bool:
	return _step != Step.NONE and _step != Step.PATROL


func start_blackout_if_needed() -> void:
	if GameState.is_blackout_dialogue_complete():
		return
	if _player == null or _hud == null:
		return
	if _step == Step.BLACKOUT_APPROACH or _step == Step.BLACKOUT_DIALOGUE:
		return
	visible = true
	set_process(true)
	_step = Step.BLACKOUT_APPROACH


func _is_walking() -> bool:
	return _step == Step.APPROACH or _step == Step.BLACKOUT_APPROACH or _step == Step.PATROL


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
	if _step == Step.NONE or _hud == null or _player == null:
		return

	match _step:
		Step.APPROACH, Step.BLACKOUT_APPROACH:
			_process_approach(delta)
		Step.PATROL:
			_process_patrol(delta)
		Step.MOVE:
			if absf(Input.get_axis("move_left", "move_right")) > 0.05:
				_begin_jump_step()
		Step.JUMP:
			if Input.is_action_just_pressed("jump"):
				_begin_crouch_step()
		Step.CROUCH:
			if Input.is_action_pressed("move_down") and _player.is_on_floor():
				_begin_shoot_step()
		Step.SHOOT:
			if Input.is_action_just_pressed("shoot"):
				_show_outro()

	queue_redraw()


func _process_approach(delta: float) -> void:
	var target_x := _player.global_position.x + APPROACH_STOP_GAP
	_walk_phase += delta * 11.0
	var dx := target_x - global_position.x
	if absf(dx) > 2.0:
		var dir := signf(dx)
		global_position.x += dir * APPROACH_WALK_SPEED * delta
		_facing = dir
		return
	global_position.x = target_x
	match _step:
		Step.APPROACH:
			_show_intro()
		Step.BLACKOUT_APPROACH:
			_show_blackout_dialogue()


func _process_patrol(delta: float) -> void:
	_walk_phase += delta * 8.0
	global_position.x += _patrol_direction * PATROL_WALK_SPEED * delta
	_facing = _patrol_direction
	if global_position.x >= PATROL_MAX_X:
		global_position.x = PATROL_MAX_X
		_patrol_direction = -1.0
	elif global_position.x <= PATROL_MIN_X:
		global_position.x = PATROL_MIN_X
		_patrol_direction = 1.0


func _resume_after_tutorial() -> void:
	if GameState.has_plant_blackout_triggered() and not GameState.is_blackout_dialogue_complete():
		start_blackout_if_needed()
	else:
		_start_patrol()


func _start_patrol() -> void:
	visible = true
	set_process(true)
	_step = Step.PATROL
	if global_position.x <= PATROL_MIN_X + 8.0:
		_patrol_direction = 1.0
	elif global_position.x >= PATROL_MAX_X - 8.0:
		_patrol_direction = -1.0
	_facing = _patrol_direction


func _show_intro() -> void:
	_step = Step.INTRO
	_hud.show_npc_dialogue(
		NPC_NAME,
		"Easy — easy. Stay with me. I'm Mara.\n\n"
		+ "You took a bad hit swapping a relay at the plant. You've been out cold "
		+ "for three days. The village needs their engineer back — show me you can move first.",
		"I'm awake",
		_begin_move_step
	)


func _begin_move_step() -> void:
	_step = Step.MOVE
	_player.set_physics_process(true)
	_hud.show_tutorial_step(
		NPC_NAME,
		"Move — press A / D or the Left / Right arrow keys."
	)


func _begin_jump_step() -> void:
	_step = Step.JUMP
	_hud.show_tutorial_step(
		NPC_NAME,
		"Jump — press Space or W."
	)


func _begin_crouch_step() -> void:
	_step = Step.CROUCH
	_hud.show_tutorial_step(
		NPC_NAME,
		"Crouch — hold S or the Down arrow."
	)


func _begin_shoot_step() -> void:
	_step = Step.SHOOT
	_hud.show_tutorial_step(
		NPC_NAME,
		"Shoot — left-click to fire your sidearm."
	)


func _show_outro() -> void:
	_step = Step.OUTRO
	_hud.hide_tutorial_step()
	_hud.show_npc_dialogue(
		NPC_NAME,
		"That's it. When you're near a door or machine, press E to interact.\n\n"
		+ "Take it slow and get your legs back. The village is glad you're up again.",
		"Thanks, Mara",
		_finish
	)


func _finish() -> void:
	GameState.mark_controls_tutorial_complete()
	_hud.hide_tutorial_step()
	finished.emit()
	_start_patrol()


func _show_blackout_dialogue() -> void:
	_step = Step.BLACKOUT_DIALOGUE
	_player.set_physics_process(false)
	_player.velocity = Vector2.ZERO
	_hud.show_npc_dialogue(
		NPC_NAME,
		"Ugh, looks like we lost power again. Are you feeling good enough to take a look?",
		"I'll take a look",
		_finish_blackout_dialogue
	)


func _finish_blackout_dialogue() -> void:
	GameState.mark_blackout_dialogue_complete()
	_player.set_physics_process(true)
	blackout_dialogue_finished.emit()
	_start_patrol()
