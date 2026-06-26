extends Area2D

signal collected

const SHEET := preload("res://assets/ammo_pot/reload_item_sheet.png")
const FRAME_COUNT := 2
const DISPLAY_SCALE := 0.055

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite

var _collected := false


func _ready() -> void:
	add_to_group("ammo_pot")
	body_entered.connect(_on_body_entered)
	animated_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	animated_sprite.sprite_frames = _build_sprite_frames()
	animated_sprite.scale = Vector2(DISPLAY_SCALE, DISPLAY_SCALE)
	animated_sprite.play("idle")
	_apply_layout()


func _physics_process(_delta: float) -> void:
	if _collected:
		return

	for body in get_overlapping_bodies():
		_try_collect(body)


func _build_sprite_frames() -> SpriteFrames:
	var sheet := SHEET as Texture2D
	if sheet == null:
		push_error("Reload item sheet failed to load.")
		return SpriteFrames.new()

	var frame_width := sheet.get_width() / float(FRAME_COUNT)
	var frame_height := sheet.get_height()
	var frames := SpriteFrames.new()

	frames.add_animation("idle")
	frames.set_animation_speed("idle", 3.0)
	frames.set_animation_loop("idle", true)

	for i in FRAME_COUNT:
		var atlas := AtlasTexture.new()
		atlas.atlas = sheet
		atlas.region = Rect2(i * frame_width, 0.0, frame_width, frame_height)
		frames.add_frame("idle", atlas)

	return frames


func _apply_layout() -> void:
	var half_height := SHEET.get_height() * DISPLAY_SCALE * 0.5
	animated_sprite.position.y = -half_height
	$CollisionShape2D.position.y = -half_height


func _on_body_entered(body: Node2D) -> void:
	_try_collect(body)


func _try_collect(body: Node) -> void:
	if _collected:
		return

	if not body.is_in_group("player"):
		return

	if not body.has_method("add_ammo"):
		return

	_collected = true
	body.add_ammo()
	collected.emit()
	queue_free()
