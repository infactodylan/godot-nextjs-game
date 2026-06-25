extends Area2D

signal collected


func _ready() -> void:
	add_to_group("ammo_pot")
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	if body.has_method("add_ammo"):
		body.add_ammo()

	collected.emit()
	queue_free()
