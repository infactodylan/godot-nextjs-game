extends Area2D

signal player_entered
signal player_exited


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	collision_layer = 0
	collision_mask = 1
	monitoring = true
	monitorable = false


func is_player_inside(player: Node2D) -> bool:
	return player != null and is_instance_valid(player) and overlaps_body(player)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_entered.emit()


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_exited.emit()
