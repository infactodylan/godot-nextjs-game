extends Area2D

signal collected


func _ready() -> void:
	add_to_group("health_potion")
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	if body.has_method("heal_to_full"):
		body.heal_to_full()

	collected.emit()
	queue_free()
