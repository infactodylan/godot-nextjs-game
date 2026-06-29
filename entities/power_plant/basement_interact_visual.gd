@tool
extends Node2D
class_name BasementInteractVisual

enum Kind { EXIT_DOOR, EMERGENCY_BATTERY }

@export var kind: Kind = Kind.EXIT_DOOR:
	set(value):
		kind = value
		queue_redraw()

@export var active: bool = false:
	set(value):
		active = value
		queue_redraw()


func _ready() -> void:
	queue_redraw()


func set_active(on: bool) -> void:
	active = on


func _draw() -> void:
	match kind:
		Kind.EXIT_DOOR:
			_draw_exit_door()
		Kind.EMERGENCY_BATTERY:
			_draw_battery()


func _draw_exit_door() -> void:
	var frame := Color(0.18, 0.16, 0.14)
	var door := Color(0.12, 0.11, 0.1)
	var accent := Color(0.2, 0.72, 0.68, 0.95)
	var sign := Color(0.55, 0.95, 0.62)

	draw_rect(Rect2(-36.0, -66.0, 72.0, 132.0), frame)
	draw_rect(Rect2(-28.0, -54.0, 56.0, 108.0), door)
	draw_line(Vector2(0.0, -48.0), Vector2(0.0, 54.0), frame.lightened(0.08), 2.0)
	draw_rect(Rect2(-36.0, 54.0, 72.0, 10.0), accent)
	draw_circle(Vector2(24.0, 8.0), 4.0, accent)
	draw_string(
		ThemeDB.fallback_font,
		Vector2(-52.0, -82.0),
		"EXIT TO PLANT",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		14,
		sign
	)


func _draw_battery() -> void:
	var frame := Color(0.18, 0.16, 0.14)
	var active_color := Color(0.85, 0.75, 0.25)
	var idle_color := Color(0.5, 0.46, 0.4)
	var label_color := active_color if active else idle_color
	var ring_color := (
		Color(0.9, 0.75, 0.2, 0.95) if active else Color(0.35, 0.55, 0.85, 0.9)
	)

	if active:
		draw_circle(Vector2(0.0, -8.0), 42.0, Color(0.9, 0.75, 0.2, 0.18))
	draw_arc(Vector2(0.0, -8.0), 36.0, PI, TAU, 16, ring_color, 5.0)
	draw_rect(Rect2(-54.0, -52.0, 108.0, 76.0), frame)
	draw_rect(Rect2(-46.0, -44.0, 92.0, 20.0), Color(0.28, 0.26, 0.24))
	draw_rect(Rect2(-46.0, -18.0, 92.0, 34.0), Color(0.14, 0.13, 0.12))
	draw_string(
		ThemeDB.fallback_font,
		Vector2(-46.0, -2.0),
		"EMERGENCY",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		13,
		label_color
	)
	draw_string(
		ThemeDB.fallback_font,
		Vector2(-46.0, 16.0),
		"BATTERY",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		16,
		label_color
	)
	if not active:
		draw_string(
			ThemeDB.fallback_font,
			Vector2(-30.0, 36.0),
			"Press E",
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			12,
			Color(0.62, 0.6, 0.56)
		)
