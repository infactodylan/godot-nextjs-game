class_name EnemySpriteFrames
extends RefCounted

const IDLE := [
	preload("res://assets/enemy/animations/Idle/zombie_idle_00.png"),
	preload("res://assets/enemy/animations/Idle/zombie_idle_01.png"),
	preload("res://assets/enemy/animations/Idle/zombie_idle_02.png"),
	preload("res://assets/enemy/animations/Idle/zombie_idle_03.png"),
	preload("res://assets/enemy/animations/Idle/zombie_idle_04.png"),
	preload("res://assets/enemy/animations/Idle/zombie_idle_05.png"),
	preload("res://assets/enemy/animations/Idle/zombie_idle_06.png"),
	preload("res://assets/enemy/animations/Idle/zombie_idle_07.png"),
	preload("res://assets/enemy/animations/Idle/zombie_idle_08.png"),
	preload("res://assets/enemy/animations/Idle/zombie_idle_09.png"),
]
const WALK := [
	preload("res://assets/enemy/animations/Walk/zombie_walk_00.png"),
	preload("res://assets/enemy/animations/Walk/zombie_walk_01.png"),
	preload("res://assets/enemy/animations/Walk/zombie_walk_02.png"),
	preload("res://assets/enemy/animations/Walk/zombie_walk_03.png"),
	preload("res://assets/enemy/animations/Walk/zombie_walk_04.png"),
	preload("res://assets/enemy/animations/Walk/zombie_walk_05.png"),
	preload("res://assets/enemy/animations/Walk/zombie_walk_06.png"),
	preload("res://assets/enemy/animations/Walk/zombie_walk_07.png"),
	preload("res://assets/enemy/animations/Walk/zombie_walk_08.png"),
	preload("res://assets/enemy/animations/Walk/zombie_walk_09.png"),
]
const ATTACK := [
	preload("res://assets/enemy/animations/Attack/zombie_attack_00.png"),
	preload("res://assets/enemy/animations/Attack/zombie_attack_01.png"),
	preload("res://assets/enemy/animations/Attack/zombie_attack_02.png"),
	preload("res://assets/enemy/animations/Attack/zombie_attack_03.png"),
	preload("res://assets/enemy/animations/Attack/zombie_attack_04.png"),
	preload("res://assets/enemy/animations/Attack/zombie_attack_05.png"),
	preload("res://assets/enemy/animations/Attack/zombie_attack_06.png"),
	preload("res://assets/enemy/animations/Attack/zombie_attack_07.png"),
]
const HURT := [
	preload("res://assets/enemy/animations/Hurt/zombie_hurt_00.png"),
	preload("res://assets/enemy/animations/Hurt/zombie_hurt_01.png"),
	preload("res://assets/enemy/animations/Hurt/zombie_hurt_02.png"),
	preload("res://assets/enemy/animations/Hurt/zombie_hurt_03.png"),
	preload("res://assets/enemy/animations/Hurt/zombie_hurt_04.png"),
	preload("res://assets/enemy/animations/Hurt/zombie_hurt_05.png"),
	preload("res://assets/enemy/animations/Hurt/zombie_hurt_06.png"),
	preload("res://assets/enemy/animations/Hurt/zombie_hurt_07.png"),
]
const DEAD := [
	preload("res://assets/enemy/animations/Dead/zombie_dead_00.png"),
	preload("res://assets/enemy/animations/Dead/zombie_dead_01.png"),
	preload("res://assets/enemy/animations/Dead/zombie_dead_02.png"),
	preload("res://assets/enemy/animations/Dead/zombie_dead_03.png"),
	preload("res://assets/enemy/animations/Dead/zombie_dead_04.png"),
	preload("res://assets/enemy/animations/Dead/zombie_dead_05.png"),
	preload("res://assets/enemy/animations/Dead/zombie_dead_06.png"),
	preload("res://assets/enemy/animations/Dead/zombie_dead_07.png"),
]


static func build() -> SpriteFrames:
	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")

	_add_loop(frames, "idle", IDLE, 8.0)
	_add_loop(frames, "walk", WALK, 10.0)
	_add_loop(frames, "attack", ATTACK, 12.0, false)
	_add_loop(frames, "hurt", HURT, 10.0, false)
	_add_loop(frames, "dead", DEAD, 8.0, false)

	return frames


static func _add_loop(
	sf: SpriteFrames,
	anim_name: String,
	textures: Array,
	speed: float,
	loop: bool = true
) -> void:
	if textures.is_empty():
		push_error("Enemy animation '%s' has no frames." % anim_name)
		return

	sf.add_animation(anim_name)
	sf.set_animation_speed(anim_name, speed)
	sf.set_animation_loop(anim_name, loop)
	for texture in textures:
		sf.add_frame(anim_name, texture)
