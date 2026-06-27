extends Control

signal solved
signal closed

const GRID_SIZE := 3
const CELL_COUNT := 9
const SCRAMBLE_MOVES := 80
const SOLVE_GLOW_DURATION := 1.35

const FRAME_COLOR := Color(0.1, 0.095, 0.09, 0.96)
const GLOW_COLOR := Color(0.42, 0.82, 0.95)
const TILE_COLORS: Array[Color] = [
	Color(0.24, 0.23, 0.25),
	Color(0.28, 0.27, 0.29),
	Color(0.22, 0.24, 0.26),
	Color(0.26, 0.25, 0.24),
	Color(0.25, 0.26, 0.27),
]
const TILE_TEXT_COLOR := Color(0.78, 0.8, 0.84)
const SOLVED_TEXT_COLOR := Color(0.88, 0.96, 1.0)
const EMPTY_COLOR := Color(0.08, 0.075, 0.07)
const TITLE_COLOR := Color(0.62, 0.64, 0.68)
const HINT_COLOR := Color(0.45, 0.47, 0.5)
const GOAL_LABEL_COLOR := Color(0.55, 0.78, 0.86)
const GOAL_TILE_SIZE := 44
const GOAL_LAYOUT: Array[int] = [1, 2, 3, 4, 5, 6, 7, 8, 0]

var _tiles: Array[int] = []
var _cells: Array[Button] = []
var _grid: GridContainer
var _panel: PanelContainer
var _panel_style: StyleBoxFlat
var _moves := 0
var _is_open := false
var _is_resolving := false
var _glow_intensity := 0.0
var _cell_size := 80
var _layer: CanvasLayer
var _resolve_tween: Tween
var _resolve_timer: SceneTreeTimer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_layer = get_parent() as CanvasLayer
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 1
	visible = false
	if _layer:
		_layer.visible = false
	_build_ui()


func force_close() -> void:
	_cancel_resolve_animation()
	if not _is_open and not visible:
		if _layer:
			_layer.visible = false
		get_tree().paused = false
		return
	close_puzzle()


func open_puzzle() -> void:
	if _is_open:
		return
	_cancel_resolve_animation()
	_is_resolving = false
	_glow_intensity = 0.0
	_is_open = true
	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	if _layer:
		_layer.visible = true
	_moves = 0
	_scramble_board()
	_refresh_cells()
	_apply_panel_glow(0.0)
	get_tree().paused = true


func close_puzzle() -> void:
	if _is_resolving:
		return
	if not _is_open and not visible:
		return
	_cancel_resolve_animation()
	_is_open = false
	_is_resolving = false
	_glow_intensity = 0.0
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _layer:
		_layer.visible = false
	get_tree().paused = false
	closed.emit()


func is_open() -> bool:
	return _is_open or _is_resolving


func _build_ui() -> void:
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.01, 0.02, 0.04, 0.78)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	_panel = PanelContainer.new()
	_panel_style = StyleBoxFlat.new()
	_panel_style.bg_color = FRAME_COLOR
	_panel_style.border_color = Color(0.32, 0.31, 0.33)
	_panel_style.set_border_width_all(2)
	_panel_style.set_corner_radius_all(6)
	_panel_style.set_content_margin_all(20)
	_panel.add_theme_stylebox_override("panel", _panel_style)
	center.add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	_panel.add_child(vbox)

	var title := Label.new()
	title.text = "Diagnostic relay sequencer"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", TITLE_COLOR)
	vbox.add_child(title)

	var hint := Label.new()
	hint.text = "Slide the tiles below to match the goal layout."
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.custom_minimum_size.x = GRID_SIZE * _cell_size + 24.0
	hint.add_theme_font_size_override("font_size", 18)
	hint.add_theme_color_override("font_color", HINT_COLOR)
	vbox.add_child(hint)

	_add_goal_preview(vbox)

	_grid = GridContainer.new()
	_grid.columns = GRID_SIZE
	_grid.add_theme_constant_override("h_separation", 6)
	_grid.add_theme_constant_override("v_separation", 6)
	vbox.add_child(_grid)

	for i in CELL_COUNT:
		var button := Button.new()
		button.custom_minimum_size = Vector2(_cell_size, _cell_size)
		button.focus_mode = Control.FOCUS_NONE
		button.add_theme_font_size_override("font_size", 32)
		button.pressed.connect(_on_cell_pressed.bind(i))
		_grid.add_child(button)
		_cells.append(button)

	var close_row := HBoxContainer.new()
	close_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(close_row)

	var close_button := Button.new()
	close_button.text = "Close"
	close_button.custom_minimum_size = Vector2(140, 44)
	close_button.focus_mode = Control.FOCUS_NONE
	close_button.pressed.connect(close_puzzle)
	close_row.add_child(close_button)

	_reset_board()


func _add_goal_preview(vbox: VBoxContainer) -> void:
	var section := VBoxContainer.new()
	section.add_theme_constant_override("separation", 8)
	section.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(section)

	var goal_label := Label.new()
	goal_label.text = "Goal order"
	goal_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	goal_label.add_theme_font_size_override("font_size", 20)
	goal_label.add_theme_color_override("font_color", GOAL_LABEL_COLOR)
	section.add_child(goal_label)

	var goal_wrap := CenterContainer.new()
	section.add_child(goal_wrap)

	var goal_frame := PanelContainer.new()
	var frame_style := StyleBoxFlat.new()
	frame_style.bg_color = Color(0.07, 0.08, 0.09)
	frame_style.border_color = Color(0.28, 0.48, 0.55, 0.65)
	frame_style.set_border_width_all(1)
	frame_style.set_corner_radius_all(4)
	frame_style.set_content_margin_all(8)
	goal_frame.add_theme_stylebox_override("panel", frame_style)
	goal_wrap.add_child(goal_frame)

	var goal_grid := GridContainer.new()
	goal_grid.columns = GRID_SIZE
	goal_grid.add_theme_constant_override("h_separation", 4)
	goal_grid.add_theme_constant_override("v_separation", 4)
	goal_frame.add_child(goal_grid)

	for value in GOAL_LAYOUT:
		var cell := PanelContainer.new()
		cell.custom_minimum_size = Vector2(GOAL_TILE_SIZE, GOAL_TILE_SIZE)
		cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var cell_style := StyleBoxFlat.new()
		cell_style.set_corner_radius_all(3)
		if value == 0:
			cell_style.bg_color = EMPTY_COLOR
			cell_style.border_color = Color(0.14, 0.13, 0.12)
		else:
			cell_style.bg_color = TILE_COLORS[(value - 1) % TILE_COLORS.size()]
			cell_style.border_color = cell_style.bg_color.lightened(0.1)
		cell_style.set_border_width_all(1)
		cell.add_theme_stylebox_override("panel", cell_style)

		if value != 0:
			var center := CenterContainer.new()
			center.set_anchors_preset(Control.PRESET_FULL_RECT)
			center.mouse_filter = Control.MOUSE_FILTER_IGNORE
			cell.add_child(center)
			var label := Label.new()
			label.text = str(value)
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.add_theme_font_size_override("font_size", 20)
			label.add_theme_color_override("font_color", TILE_TEXT_COLOR)
			label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			center.add_child(label)

		goal_grid.add_child(cell)


func _reset_board() -> void:
	_tiles.clear()
	for i in range(1, CELL_COUNT):
		_tiles.append(i)
	_tiles.append(0)


func _scramble_board() -> void:
	_reset_board()
	var empty_index := CELL_COUNT - 1
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for _move in SCRAMBLE_MOVES:
		var neighbors := _neighbor_indices(empty_index)
		var pick: int = neighbors[rng.randi_range(0, neighbors.size() - 1)]
		_swap_tiles(empty_index, pick)
		empty_index = pick


func _neighbor_indices(index: int) -> Array[int]:
	var row := index / GRID_SIZE
	var col := index % GRID_SIZE
	var neighbors: Array[int] = []
	if row > 0:
		neighbors.append(index - GRID_SIZE)
	if row < GRID_SIZE - 1:
		neighbors.append(index + GRID_SIZE)
	if col > 0:
		neighbors.append(index - 1)
	if col < GRID_SIZE - 1:
		neighbors.append(index + 1)
	return neighbors


func _empty_index() -> int:
	return _tiles.find(0)


func _swap_tiles(a: int, b: int) -> void:
	var temp := _tiles[a]
	_tiles[a] = _tiles[b]
	_tiles[b] = temp


func _on_cell_pressed(index: int) -> void:
	if not _is_open or _is_resolving:
		return
	var empty := _empty_index()
	if index not in _neighbor_indices(empty):
		return
	_swap_tiles(index, empty)
	_moves += 1
	_refresh_cells()
	if _is_solved():
		_begin_solved_sequence()


func _is_solved() -> bool:
	for i in range(CELL_COUNT - 1):
		if _tiles[i] != i + 1:
			return false
	return _tiles[CELL_COUNT - 1] == 0


func _tile_style(value: int, glow: float) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	var base: Color = TILE_COLORS[(value - 1) % TILE_COLORS.size()]
	style.bg_color = base.lerp(GLOW_COLOR.darkened(0.45), glow * 0.55)
	style.border_color = GLOW_COLOR.lerp(base.lightened(0.12), 1.0 - glow)
	style.set_border_width_all(1 + int(glow * 2.0))
	style.set_corner_radius_all(4)
	style.shadow_color = Color(GLOW_COLOR.r, GLOW_COLOR.g, GLOW_COLOR.b, 0.45 * glow)
	style.shadow_size = int(10.0 * glow)
	return style


func _refresh_cells() -> void:
	for i in CELL_COUNT:
		var value: int = _tiles[i]
		var button := _cells[i]
		if value == 0:
			button.text = ""
			button.disabled = true
			var empty_style := StyleBoxFlat.new()
			empty_style.bg_color = EMPTY_COLOR
			if _glow_intensity > 0.0:
				empty_style.border_color = Color(GLOW_COLOR.r, GLOW_COLOR.g, GLOW_COLOR.b, 0.35 * _glow_intensity)
				empty_style.set_border_width_all(1)
			empty_style.set_corner_radius_all(4)
			button.add_theme_stylebox_override("normal", empty_style)
			button.add_theme_stylebox_override("disabled", empty_style)
			continue
		button.disabled = _is_resolving
		button.text = str(value)
		var text_color := SOLVED_TEXT_COLOR if _is_resolving else TILE_TEXT_COLOR
		button.add_theme_color_override("font_color", text_color.lerp(GLOW_COLOR, _glow_intensity * 0.35))
		var style := _tile_style(value, _glow_intensity)
		button.add_theme_stylebox_override("normal", style)
		button.add_theme_stylebox_override("hover", style)
		button.add_theme_stylebox_override("pressed", style)
	_apply_panel_glow(_glow_intensity)


func _apply_panel_glow(intensity: float) -> void:
	if _panel_style == null:
		return
	_panel_style.border_color = Color(0.32, 0.31, 0.33).lerp(GLOW_COLOR, intensity)
	_panel_style.set_border_width_all(2 + int(intensity * 2.0))
	_panel_style.shadow_color = Color(GLOW_COLOR.r, GLOW_COLOR.g, GLOW_COLOR.b, 0.35 * intensity)
	_panel_style.shadow_size = int(14.0 * intensity)


func _set_glow_intensity(intensity: float) -> void:
	_glow_intensity = intensity
	_refresh_cells()


func _begin_solved_sequence() -> void:
	if _is_resolving:
		return
	_is_resolving = true
	for button in _cells:
		button.disabled = true

	_cancel_resolve_animation()
	_resolve_tween = create_tween()
	_resolve_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_resolve_tween.set_loops(2)
	_resolve_tween.tween_method(_set_glow_intensity, 0.15, 1.0, 0.28).set_trans(Tween.TRANS_SINE)
	_resolve_tween.tween_method(_set_glow_intensity, 1.0, 0.55, 0.28).set_trans(Tween.TRANS_SINE)
	_resolve_tween.finished.connect(_hold_solved_glow)


func _hold_solved_glow() -> void:
	_set_glow_intensity(1.0)
	_resolve_timer = get_tree().create_timer(SOLVE_GLOW_DURATION, true)
	_resolve_timer.timeout.connect(_finish_solved)


func _finish_solved() -> void:
	if not _is_resolving:
		return
	_cancel_resolve_animation()
	_is_resolving = false
	_is_open = false
	_glow_intensity = 0.0
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _layer:
		_layer.visible = false
	get_tree().paused = false
	solved.emit()


func _cancel_resolve_animation() -> void:
	if _resolve_tween and _resolve_tween.is_valid():
		_resolve_tween.kill()
	_resolve_tween = null
	if _resolve_timer:
		_resolve_timer = null
