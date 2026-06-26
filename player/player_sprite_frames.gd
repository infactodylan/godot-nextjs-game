class_name PlayerSpriteFrames
extends RefCounted

const SHEET := preload("res://assets/player/player_character_sheet.png")
const ROW_HEIGHT := 1105

# Row 0: walk right. Row 1: walk left. Each entry is [x, width] in sheet pixels.
const FRAMES_RIGHT := [
	[0, 527],
	[893, 407],
	[1641, 372],
	[2207, 508],
	[3056, 377],
	[3693, 403],
]
const FRAMES_LEFT := [
	[0, 403],
	[663, 377],
	[1381, 508],
	[2083, 372],
	[2796, 407],
	[3569, 527],
]

const ROW_RIGHT := 0
const ROW_LEFT := 1
const IDLE_RIGHT_COL := 2
const IDLE_LEFT_COL := 0


static func build() -> SpriteFrames:
	var sheet := SHEET as Texture2D
	if sheet == null:
		push_error("Player sprite sheet failed to load.")
		return SpriteFrames.new()

	var frames := SpriteFrames.new()

	_add_loop(frames, "idle_right", sheet, ROW_RIGHT, [IDLE_RIGHT_COL], 5.0)
	_add_loop(frames, "idle_left", sheet, ROW_LEFT, [IDLE_LEFT_COL], 5.0)
	_add_loop(frames, "run_right", sheet, ROW_RIGHT, [0, 1, 2, 3, 4, 5], 10.0)
	_add_loop(frames, "run_left", sheet, ROW_LEFT, [0, 1, 2, 3, 4, 5], 10.0)

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
	var frame_data: Array = FRAMES_RIGHT[col] if row == ROW_RIGHT else FRAMES_LEFT[col]
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	atlas.region = Rect2(
		frame_data[0],
		row * ROW_HEIGHT,
		frame_data[1],
		ROW_HEIGHT
	)
	return atlas
