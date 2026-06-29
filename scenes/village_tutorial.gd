extends Node2D

signal finished
signal blackout_dialogue_finished

const MaraCompanionScript := preload("res://entities/npc/mara_companion.gd")

const NPC_NAME := "Mara"
const GROUND_Y := 820.0
const APPROACH_OFFSET := 420.0
const APPROACH_STOP_GAP := 96.0
const PATROL_MIN_X := 360.0
const PATROL_MAX_X := 7420.0
const PLANT_DOOR_X := 2232.0
const COURTHOUSE_GATE_X := 4320.0

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
	FOLLOW_TO_PLANT,
	FOLLOW_TO_COURTHOUSE,
}

var _step := Step.NONE
var _hud: CanvasLayer
var _player: CharacterBody2D
var _companion: Node2D
var _plant_door: Area2D


func _ready() -> void:
	z_index = 6
	z_as_relative = false


func configure(hud: CanvasLayer, player: CharacterBody2D, plant_door: Area2D = null) -> void:
	_hud = hud
	_player = player
	_plant_door = plant_door
	_ensure_companion()


func _ensure_companion() -> void:
	if _companion != null:
		return
	_companion = Node2D.new()
	_companion.set_script(MaraCompanionScript)
	add_child(_companion)
	_companion.approach_finished.connect(_on_companion_approach_finished)
	if _player:
		_companion.configure(_player)
		_companion.set_bounds(PATROL_MIN_X, PATROL_MAX_X, GROUND_Y)


func start_if_needed() -> void:
	if _player == null or _hud == null:
		return
	_ensure_companion()
	if GameState.is_controls_tutorial_complete():
		_resume_after_tutorial()
		return
	_companion.visible = true
	set_process(true)
	_step = Step.APPROACH
	_companion.global_position = Vector2(_player.global_position.x + APPROACH_OFFSET, GROUND_Y)
	_companion.begin_approach(APPROACH_STOP_GAP)
	_player.set_physics_process(false)
	_player.velocity = Vector2.ZERO


func is_active() -> bool:
	return (
		_step != Step.NONE
		and _step != Step.PATROL
		and _step != Step.FOLLOW_TO_PLANT
		and _step != Step.FOLLOW_TO_COURTHOUSE
	)


func is_following_to_plant() -> bool:
	return _step == Step.FOLLOW_TO_PLANT


func is_following_to_courthouse() -> bool:
	return _step == Step.FOLLOW_TO_COURTHOUSE


func start_blackout_if_needed() -> void:
	if GameState.is_blackout_dialogue_complete():
		return
	if _player == null or _hud == null:
		return
	if _step == Step.BLACKOUT_APPROACH or _step == Step.BLACKOUT_DIALOGUE:
		return
	_ensure_companion()
	_companion.visible = true
	set_process(true)
	_step = Step.BLACKOUT_APPROACH
	_companion.begin_approach(APPROACH_STOP_GAP)


func _process(_delta: float) -> void:
	if _step == Step.NONE or _hud == null or _player == null:
		return

	match _step:
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
		Step.FOLLOW_TO_PLANT:
			_check_plant_door_reached()
		Step.FOLLOW_TO_COURTHOUSE:
			pass


func _on_companion_approach_finished() -> void:
	match _step:
		Step.APPROACH:
			_show_intro()
		Step.BLACKOUT_APPROACH:
			_show_blackout_dialogue()


func _check_plant_door_reached() -> void:
	if _plant_door == null:
		return
	if not _plant_door.is_player_inside(_player):
		return
	if _player.global_position.x >= PLANT_DOOR_X - 80.0:
		GameState.mark_mara_escorting(true)


func _resume_after_tutorial() -> void:
	if GameState.has_plant_blackout_triggered() and not GameState.is_blackout_dialogue_complete():
		start_blackout_if_needed()
	elif GameState.is_blackout_dialogue_complete() and not GameState.is_radio_broadcast_received():
		_start_follow_to_plant()
	elif (
		GameState.is_radio_broadcast_received()
		and not GameState.is_mission_briefing_stub_complete()
	):
		_start_follow_to_courthouse()
	else:
		_start_patrol()


func _start_patrol() -> void:
	_ensure_companion()
	_companion.visible = true
	set_process(true)
	_step = Step.PATROL
	_companion.set_bounds(PATROL_MIN_X, PATROL_MAX_X, GROUND_Y)
	_companion.start_patrol()


func _start_follow_to_plant() -> void:
	_ensure_companion()
	_companion.visible = true
	set_process(true)
	_step = Step.FOLLOW_TO_PLANT
	GameState.mark_mara_escorting(true)
	_companion.set_bounds(PATROL_MIN_X, PLANT_DOOR_X + 40.0, GROUND_Y)
	_companion.set_follow_gap(120.0)
	_companion.start_follow()


func _start_follow_to_courthouse() -> void:
	_ensure_companion()
	_companion.visible = true
	set_process(true)
	_step = Step.FOLLOW_TO_COURTHOUSE
	GameState.mark_mara_escorting(true)
	_companion.set_bounds(PATROL_MIN_X, COURTHOUSE_GATE_X + 40.0, GROUND_Y)
	_companion.set_follow_gap(120.0)
	_companion.teleport_near_player()
	_companion.start_follow()


func finish_follow_to_courthouse() -> void:
	if _step != Step.FOLLOW_TO_COURTHOUSE:
		return
	_companion.stop_follow()
	_start_patrol()


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
		"Ugh — power's out again. Ashford was supposed to broadcast tonight. "
		+ "Their settlement picks up signals from the old grid, and we were counting on "
		+ "that transmission.\n\n"
		+ "Without power our radio is dead. Come with me to the plant — let's see what's wrong.",
		"I'll take a look",
		_finish_blackout_dialogue
	)


func _finish_blackout_dialogue() -> void:
	GameState.mark_blackout_dialogue_complete()
	GameState.mark_mara_escorting(true)
	_player.set_physics_process(true)
	blackout_dialogue_finished.emit()
	_start_follow_to_plant()


func get_companion() -> Node2D:
	_ensure_companion()
	return _companion
