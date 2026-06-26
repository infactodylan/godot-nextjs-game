extends CharacterBody2D

signal defeated

const SPEED := 120.0
const STAND_HEIGHT := 36.0
const SPRITE_TEXTURE_SIZE := 548.0
const SPRITE_FOOT_Y := 500.0
const SPRITE_SCALE := STAND_HEIGHT / 400.0
const HALF_WIDTH := 14.0
const ATTACK_COOLDOWN := 0.8

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var _player: CharacterBody2D
var _is_dying := false
var _attack_cooldown := 0.0

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


func _physics_process(delta: float) -> void:
	if _is_dying:
		return

	if _attack_cooldown > 0.0:
		_attack_cooldown = maxf(_attack_cooldown - delta, 0.0)

	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0.0

	if _attack_cooldown > 0.0 and animated_sprite.animation == "attack":
		velocity.x = 0.0
	elif _player and is_instance_valid(_player) and not _player.is_dead:
		var direction := signf(_player.global_position.x - global_position.x)
		velocity.x = direction * SPEED if direction != 0.0 else 0.0
		_update_animation(direction)
	else:
		velocity.x = 0.0
		_update_animation(0.0)

	move_and_slide()
	_check_player_collision()


func _update_animation(direction: float) -> void:
	if _attack_cooldown > 0.0 and animated_sprite.animation == "attack":
		return

	if absf(direction) > 0.0:
		animated_sprite.flip_h = direction < 0.0
		if animated_sprite.animation != "walk":
			animated_sprite.play("walk")
	else:
		if animated_sprite.animation != "idle":
			animated_sprite.play("idle")


func _check_player_collision() -> void:
	for i in get_slide_collision_count():
		var collider := get_slide_collision(i).get_collider()
		if collider and collider.is_in_group("player") and collider.has_method("take_damage"):
			collider.take_damage(1)
			_play_attack()


func _play_attack() -> void:
	if _is_dying or _attack_cooldown > 0.0:
		return

	_attack_cooldown = ATTACK_COOLDOWN
	velocity.x = 0.0
	animated_sprite.play("attack")


func die() -> void:
	if _is_dying:
		return

	_is_dying = true
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
