class_name PlayerSpriteFrames
extends RefCounted

const IDLE := [
	preload("res://assets/player/animations/Idle/Armature_idle_00.png"),
	preload("res://assets/player/animations/Idle/Armature_idle_01.png"),
	preload("res://assets/player/animations/Idle/Armature_idle_02.png"),
	preload("res://assets/player/animations/Idle/Armature_idle_03.png"),
	preload("res://assets/player/animations/Idle/Armature_idle_04.png"),
	preload("res://assets/player/animations/Idle/Armature_idle_05.png"),
	preload("res://assets/player/animations/Idle/Armature_idle_06.png"),
	preload("res://assets/player/animations/Idle/Armature_idle_07.png"),
	preload("res://assets/player/animations/Idle/Armature_idle_08.png"),
	preload("res://assets/player/animations/Idle/Armature_idle_09.png"),
	preload("res://assets/player/animations/Idle/Armature_idle_10.png"),
	preload("res://assets/player/animations/Idle/Armature_idle_11.png"),
]
const RUN := [
	preload("res://assets/player/animations/Run/Armature_run_0.png"),
	preload("res://assets/player/animations/Run/Armature_run_1.png"),
	preload("res://assets/player/animations/Run/Armature_run_2.png"),
	preload("res://assets/player/animations/Run/Armature_run_3.png"),
	preload("res://assets/player/animations/Run/Armature_run_4.png"),
	preload("res://assets/player/animations/Run/Armature_run_5.png"),
	preload("res://assets/player/animations/Run/Armature_run_6.png"),
	preload("res://assets/player/animations/Run/Armature_run_7.png"),
]
const CROUCH := [preload("res://assets/player/animations/Crouch/Armature_crouch_0.png")]
const JUMP := [preload("res://assets/player/animations/Jump/Armature_jump_0.png")]
const FALL := [preload("res://assets/player/animations/Fall/Armature_fall_0.png")]
const DEATH := [
	preload("res://assets/player/animations/Death/Armature_death_0.png"),
	preload("res://assets/player/animations/Death/Armature_death_1.png"),
	preload("res://assets/player/animations/Death/Armature_death_2.png"),
	preload("res://assets/player/animations/Death/Armature_death_3.png"),
	preload("res://assets/player/animations/Death/Armature_death_4.png"),
]
const SHOOT := [
	preload("res://assets/player/animations/Shot Anim/Armature_shoot_0.png"),
	preload("res://assets/player/animations/Shot Anim/Armature_shoot_1.png"),
]
const SHOOT_UP := [
	preload("res://assets/player/animations/Shoot Up/Armature_shoot_up_0.png"),
	preload("res://assets/player/animations/Shoot Up/Armature_shoot_up_1.png"),
]
const CROUCH_SHOOT := [
	preload("res://assets/player/animations/Crouch Shoot/Armature_crouch_shoot_0.png"),
	preload("res://assets/player/animations/Crouch Shoot/Armature_crouch_shoot_1.png"),
]
const RUN_SHOOT := [
	preload("res://assets/player/animations/Running Shoot/Armature_running_shoot_0.png"),
	preload("res://assets/player/animations/Running Shoot/Armature_running_shoot_1.png"),
	preload("res://assets/player/animations/Running Shoot/Armature_running_shoot_2.png"),
	preload("res://assets/player/animations/Running Shoot/Armature_running_shoot_3.png"),
	preload("res://assets/player/animations/Running Shoot/Armature_running_shoot_4.png"),
	preload("res://assets/player/animations/Running Shoot/Armature_running_shoot_5.png"),
	preload("res://assets/player/animations/Running Shoot/Armature_running_shoot_6.png"),
	preload("res://assets/player/animations/Running Shoot/Armature_running_shoot_7.png"),
]
const JUMP_SHOOT := [
	preload("res://assets/player/animations/Jumping Shoot/Armature_jumping_shoot_0.png"),
	preload("res://assets/player/animations/Jumping Shoot/Armature_jumping_shoot_1.png"),
]
const FALL_SHOOT := [
	preload("res://assets/player/animations/Falling Shoot/Armature_falling_shoot_0.png"),
	preload("res://assets/player/animations/Falling Shoot/Armature_falling_shoot_1.png"),
]


static func build() -> SpriteFrames:
	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")

	_add_loop(frames, "idle", IDLE, 8.0)
	_add_loop(frames, "run", RUN, 12.0)
	_add_loop(frames, "crouch", CROUCH, 5.0)
	_add_loop(frames, "jump", JUMP, 5.0)
	_add_loop(frames, "fall", FALL, 5.0)
	_add_loop(frames, "death", DEATH, 8.0, false)
	_add_loop(frames, "shoot", SHOOT, 14.0, false)
	_add_loop(frames, "shoot_up", SHOOT_UP, 6.0)
	_add_loop(frames, "crouch_shoot", CROUCH_SHOOT, 6.0)
	_add_loop(frames, "run_shoot", RUN_SHOOT, 12.0)
	_add_loop(frames, "jump_shoot", JUMP_SHOOT, 6.0)
	_add_loop(frames, "fall_shoot", FALL_SHOOT, 6.0)

	return frames


static func _add_loop(
	sf: SpriteFrames,
	anim_name: String,
	textures: Array,
	speed: float,
	loop: bool = true
) -> void:
	if textures.is_empty():
		push_error("Player animation '%s' has no frames." % anim_name)
		return

	sf.add_animation(anim_name)
	sf.set_animation_speed(anim_name, speed)
	sf.set_animation_loop(anim_name, loop)
	for texture in textures:
		sf.add_frame(anim_name, texture)
