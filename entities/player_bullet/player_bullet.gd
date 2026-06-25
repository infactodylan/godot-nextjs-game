extends Area2D

const SPEED := 600.0
const LIFETIME := 2.0

var direction := 1.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	get_tree().create_timer(LIFETIME).timeout.connect(queue_free)


func _physics_process(delta: float) -> void:
	position.x += direction * SPEED * delta


func _on_body_entered(body: Node2D) -> void:
	_handle_hit(body)


func _on_area_entered(area: Area2D) -> void:
	_handle_hit(area)


func _handle_hit(target: Node) -> void:
	if target.is_in_group("enemy") and target.has_method("die"):
		target.die()
		queue_free()
		return

	if target.is_in_group("boss"):
		var boss := target
		if not boss.has_method("take_damage"):
			boss = target.get_parent()
		if boss and boss.has_method("take_damage"):
			boss.take_damage(1)
			queue_free()
