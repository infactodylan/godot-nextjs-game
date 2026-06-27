extends StaticBody2D

const HALF_W := 130.0
const HEIGHT := 168.0

func _ready() -> void:
	var shape := RectangleShape2D.new()
	shape.size = Vector2(HALF_W * 2.0, HEIGHT)
	var collider := CollisionShape2D.new()
	collider.position = Vector2(0.0, -HEIGHT * 0.5)
	collider.shape = shape
	add_child(collider)
	set_meta("roof_offset", HEIGHT)
	set_meta("half_width", HALF_W)
