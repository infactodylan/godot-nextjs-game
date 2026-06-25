class_name PlayerSpriteFrames
extends RefCounted

const SHEET := preload("res://assets/player/silas_character_sheet.png")
const FRAME_W := 128
const FRAME_H := 186

# Row 0: run right (5 frames). Row 1: run left (unused; we flip). Row 2: actions.
const ROW_RUN := 0
const ROW_ACTION := 2


static func build() -> SpriteFrames:
	var sheet := SHEET as Texture2D
	if sheet == null:
		push_error("Player sprite sheet failed to load.")
		return SpriteFrames.new()

	var frames := SpriteFrames.new()

	_add_loop(frames, "idle", sheet, ROW_RUN, [0], 5.0)
	_add_loop(frames, "run", sheet, ROW_RUN, [0, 1, 2, 3, 4], 10.0)
	_add_loop(frames, "crouch_enter", sheet, ROW_ACTION, [0, 1, 2], 8.0, false)
	_add_loop(frames, "crouch", sheet, ROW_ACTION, [2], 5.0)
	_add_loop(frames, "jump", sheet, ROW_ACTION, [3], 5.0)
	_add_loop(frames, "fall", sheet, ROW_ACTION, [4], 5.0)
	_add_loop(frames, "air_aim", sheet, ROW_ACTION, [5], 5.0)
	_add_loop(frames, "land", sheet, ROW_ACTION, [6], 8.0, false)

	return frames


static func _add_loop(
	sf: SpriteFrames,
	anim_name: String,
	sheet: Texture2D,
	row: int,
	cols: Array[int],
	speed: float,
	loop: bool = true
) -> void:
	sf.add_animation(anim_name)
	sf.set_animation_speed(anim_name, speed)
	sf.set_animation_loop(anim_name, loop)
	for col in cols:
		sf.add_frame(anim_name, _atlas(sheet, col, row))


static func _atlas(sheet: Texture2D, col: int, row: int) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	atlas.region = Rect2(col * FRAME_W, row * FRAME_H, FRAME_W, FRAME_H)
	return atlas
