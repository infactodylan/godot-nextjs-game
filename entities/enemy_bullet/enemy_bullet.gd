extends Area2D

const SPEED := 480.0
const DESPAWN_X := -32.0


func _ready() -> void:
	monitoring = true
	monitorable = false
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	position.x -= SPEED * delta

	if position.x < DESPAWN_X:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	if body.has_method("take_damage"):
		body.take_damage(1)

	queue_free()
