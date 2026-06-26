class_name EnemySpriteFrames
extends RefCounted

const SHEET := preload("res://assets/enemy/enemy_character_sheet.png")
const FRAME_COUNT := 6
const IDLE_COL := 0


static func build() -> SpriteFrames:
	var sheet := SHEET as Texture2D
	if sheet == null:
		push_error("Enemy sprite sheet failed to load.")
		return SpriteFrames.new()

	var frame_width := sheet.get_width() / float(FRAME_COUNT)
	var frame_height := sheet.get_height()
	var frames := SpriteFrames.new()

	_add_loop(frames, "idle", sheet, [IDLE_COL], frame_width, frame_height, 5.0)
	_add_loop(frames, "run", sheet, [0, 1, 2, 3, 4, 5], frame_width, frame_height, 8.0)

	return frames


static func _add_loop(
	sf: SpriteFrames,
	anim_name: String,
	sheet: Texture2D,
	cols: Array[int],
	frame_width: float,
	frame_height: float,
	speed: float
) -> void:
	sf.add_animation(anim_name)
	sf.set_animation_speed(anim_name, speed)
	sf.set_animation_loop(anim_name, true)
	for col in cols:
		var atlas := AtlasTexture.new()
		atlas.atlas = sheet
		atlas.region = Rect2(col * frame_width, 0.0, frame_width, frame_height)
		sf.add_frame(anim_name, atlas)
