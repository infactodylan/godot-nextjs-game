extends Area2D

signal player_entered_courtyard

var _triggered := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	collision_layer = 0
	collision_mask = 1
	monitoring = true


func _on_body_entered(body: Node2D) -> void:
	if _triggered:
		return
	if body.is_in_group("player"):
		_triggered = true
		player_entered_courtyard.emit()
