extends Area2D

signal collected


func _ready() -> void:
	add_to_group("super_weapon_pickup")
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	if body.has_method("activate_super_weapon"):
		body.activate_super_weapon()

	collected.emit()
	queue_free()
