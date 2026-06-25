extends Area2D

signal collected

const SHEET_PATH := "res://assets/ammo_pot/reload_item_sheet.png"
const FRAME_COUNT := 3
const FRAME_H := 182
const DISPLAY_SCALE := 0.2

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite


func _ready() -> void:
	add_to_group("ammo_pot")
	body_entered.connect(_on_body_entered)
	animated_sprite.sprite_frames = _build_sprite_frames()
	animated_sprite.play("idle")


func _build_sprite_frames() -> SpriteFrames:
	var sheet := load(SHEET_PATH) as Texture2D
	var sheet_width := sheet.get_width()
	var frame_width := sheet_width / float(FRAME_COUNT)
	var frames := SpriteFrames.new()

	frames.add_animation("idle")
	frames.set_animation_speed("idle", 4.0)
	frames.set_animation_loop("idle", true)

	for i in FRAME_COUNT:
		var atlas := AtlasTexture.new()
		atlas.atlas = sheet
		atlas.region = Rect2(i * frame_width, 0.0, frame_width, FRAME_H)
		frames.add_frame("idle", atlas)

	return frames


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	if body.has_method("add_ammo"):
		body.add_ammo()

	collected.emit()
	queue_free()
