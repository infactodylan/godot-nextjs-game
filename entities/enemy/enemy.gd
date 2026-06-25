extends CharacterBody2D

signal defeated

const SPEED := 120.0

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var _player: CharacterBody2D


func _ready() -> void:
	add_to_group("enemy")
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
	else:
		velocity.x = 0.0

	move_and_slide()
	_check_player_collision()


func _check_player_collision() -> void:
	for i in get_slide_collision_count():
		var collider := get_slide_collision(i).get_collider()
		if collider and collider.is_in_group("player") and collider.has_method("die"):
			collider.die()


func die() -> void:
	AudioManager.play_enemy_death()
	defeated.emit()
	queue_free()
