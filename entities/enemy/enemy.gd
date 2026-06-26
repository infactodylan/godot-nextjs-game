extends CharacterBody2D

signal defeated

const SPEED := 120.0
const SPRITE_SCALE := 0.16
const STAND_HEIGHT := 36.0
const HALF_WIDTH := 14.0

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var _player: CharacterBody2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite


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
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0.0

	if _player and is_instance_valid(_player) and not _player.is_dead:
		var direction := signf(_player.global_position.x - global_position.x)
		velocity.x = direction * SPEED if direction != 0.0 else 0.0
		_update_animation(direction)
	else:
		velocity.x = 0.0
		_update_animation(0.0)

	move_and_slide()
	_check_player_collision()


func _update_animation(direction: float) -> void:
	if absf(direction) > 0.0:
		animated_sprite.flip_h = direction < 0.0
		if animated_sprite.animation != "run":
			animated_sprite.play("run")
	else:
		if animated_sprite.animation != "idle":
			animated_sprite.play("idle")


func _check_player_collision() -> void:
	for i in get_slide_collision_count():
		var collider := get_slide_collision(i).get_collider()
		if collider and collider.is_in_group("player") and collider.has_method("take_damage"):
			collider.take_damage(1)


func die() -> void:
	AudioManager.play_enemy_death()
	defeated.emit()
	queue_free()


func _apply_stance() -> void:
	var half_height := STAND_HEIGHT * 0.5
	var collision_shape := $CollisionShape2D
	var rect_shape := collision_shape.shape as RectangleShape2D
	rect_shape.size = Vector2(HALF_WIDTH * 2.0, STAND_HEIGHT)
	collision_shape.position = Vector2(0.0, -half_height)
	animated_sprite.position.y = -half_height
