extends Node

const SAVE_PATH := "user://savegame.json"
const SAVE_VERSION := 1
const DEATH_RESPAWN_META := "death_respawn"
const DEFAULT_SCENE := "res://scenes/the_village.tscn"
const SAVE_INTERVAL := 1.5

var _save_debounce := 0.0
var _pending_resume := false
var _pending_scene_entry := ""
var _pending_scene_entry_kind := ""
var _has_save := false

var _current_scene := ""
var _player_position := Vector2.ZERO
var _room_entry_scene := ""
var _room_entry_position := Vector2.ZERO
var _play_session_active := false


func _ready() -> void:
	load_from_disk()
	if _has_save and _play_session_active and _current_scene != "":
		_pending_resume = true
		call_deferred("_boot_saved_scene")


func _boot_saved_scene() -> void:
	var tree := get_tree()
	if tree == null:
		return
	await tree.process_frame
	var active_path := ""
	if tree.current_scene:
		active_path = tree.current_scene.scene_file_path
	if active_path != _current_scene:
		tree.change_scene_to_file(_current_scene)


func has_save() -> bool:
	return _has_save


func has_active_session() -> bool:
	return _has_save and _play_session_active


func consume_pending_resume(scene_path: String = "") -> bool:
	if not _pending_resume:
		return false
	if scene_path != "" and _current_scene != scene_path:
		return false
	_pending_resume = false
	return true


func prepare_scene_transition(scene_path: String, kind: String = "entry") -> void:
	_pending_scene_entry = scene_path
	_pending_scene_entry_kind = kind
	_current_scene = scene_path
	_play_session_active = true
	save_now()


func has_pending_scene_entry(scene_path: String) -> bool:
	return _pending_scene_entry == scene_path


func consume_scene_entry(scene_path: String) -> String:
	if _pending_scene_entry != scene_path:
		return ""
	var kind := _pending_scene_entry_kind
	if kind.is_empty():
		kind = "entry"
	_pending_scene_entry = ""
	_pending_scene_entry_kind = ""
	return kind


func prepare_objective_replay(scene_path: String) -> void:
	_pending_resume = false
	_pending_scene_entry = ""
	_pending_scene_entry_kind = ""
	_current_scene = scene_path
	_player_position = Vector2.ZERO
	_room_entry_scene = ""
	_room_entry_position = Vector2.ZERO
	_play_session_active = true
	save_now()


func is_objective_replay() -> bool:
	return get_tree().has_meta(StoryObjectives.OBJECTIVE_REPLAY_META)


func consume_objective_replay() -> String:
	if not get_tree().has_meta(StoryObjectives.OBJECTIVE_REPLAY_META):
		return ""
	var replay_id: String = str(get_tree().get_meta(StoryObjectives.OBJECTIVE_REPLAY_META))
	get_tree().remove_meta(StoryObjectives.OBJECTIVE_REPLAY_META)
	StoryObjectives.consume_replay_id()
	return replay_id


func is_death_respawn() -> bool:
	return get_tree().has_meta(DEATH_RESPAWN_META)


func clear_death_respawn() -> void:
	if get_tree().has_meta(DEATH_RESPAWN_META):
		get_tree().remove_meta(DEATH_RESPAWN_META)


func get_saved_position() -> Vector2:
	return _player_position


func get_saved_scene() -> String:
	return _current_scene


func get_room_entry_position() -> Vector2:
	if _room_entry_position != Vector2.ZERO:
		return _room_entry_position
	return _player_position


func register_room_entry(scene_path: String, spawn_position: Vector2) -> void:
	_current_scene = scene_path
	_room_entry_scene = scene_path
	_room_entry_position = spawn_position
	_player_position = spawn_position
	_play_session_active = true
	save_now()


func track_position(scene_path: String, position: Vector2, delta: float) -> void:
	if scene_path.is_empty():
		return
	_current_scene = scene_path
	_player_position = position
	_save_debounce -= delta
	if _save_debounce <= 0.0:
		_save_debounce = SAVE_INTERVAL
		save_now()


func apply_resume_spawn(player: CharacterBody2D) -> void:
	if player == null:
		return
	if _player_position != Vector2.ZERO:
		player.global_position = _player_position
	if player.is_dead and player.has_method("reset_after_death"):
		player.call("reset_after_death")


func apply_death_respawn(player: CharacterBody2D) -> void:
	if player == null:
		return
	player.global_position = get_room_entry_position()
	if player.has_method("reset_after_death"):
		player.call("reset_after_death")


func handle_player_death() -> void:
	save_now()
	get_tree().set_meta(DEATH_RESPAWN_META, true)
	var scene_path := _room_entry_scene
	if scene_path.is_empty():
		scene_path = _current_scene
	if scene_path.is_empty():
		scene_path = DEFAULT_SCENE
	get_tree().call_deferred("change_scene_to_file", scene_path)


func on_state_changed() -> void:
	if _play_session_active:
		save_now()


func save_now() -> void:
	var payload := {
		"version": SAVE_VERSION,
		"play_session_active": _play_session_active,
		"current_scene": _current_scene,
		"player_x": _player_position.x,
		"player_y": _player_position.y,
		"room_entry_scene": _room_entry_scene,
		"room_entry_x": _room_entry_position.x,
		"room_entry_y": _room_entry_position.y,
		"game_state": _collect_game_state(),
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("SaveManager: could not write save to %s" % SAVE_PATH)
		return
	file.store_string(JSON.stringify(payload, "\t"))
	_has_save = true


func load_from_disk() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		_has_save = false
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		_has_save = false
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		_has_save = false
		return false
	_apply_save_dict(parsed)
	_has_save = true
	return true


func _apply_save_dict(data: Dictionary) -> void:
	_play_session_active = data.get("play_session_active", false)
	_current_scene = str(data.get("current_scene", ""))
	_player_position = Vector2(
		float(data.get("player_x", 0.0)),
		float(data.get("player_y", 0.0))
	)
	_room_entry_scene = str(data.get("room_entry_scene", ""))
	_room_entry_position = Vector2(
		float(data.get("room_entry_x", 0.0)),
		float(data.get("room_entry_y", 0.0))
	)
	var game_state: Variant = data.get("game_state", {})
	if typeof(game_state) == TYPE_DICTIONARY:
		GameState.apply_from_save(game_state)


func _collect_game_state() -> Dictionary:
	return {
		"plant_power_on": GameState.plant_power_on,
		"plant_blackout_triggered": GameState.plant_blackout_triggered,
		"controls_tutorial_complete": GameState.controls_tutorial_complete,
		"blackout_dialogue_complete": GameState.blackout_dialogue_complete,
		"plant_diagnostic_puzzle_complete": GameState.plant_diagnostic_puzzle_complete,
		"plant_component_failed": GameState.plant_component_failed,
		"mara_escorting": GameState.mara_escorting,
		"battery_dialogue_complete": GameState.battery_dialogue_complete,
		"emergency_battery_active": GameState.emergency_battery_active,
		"radio_broadcast_received": GameState.radio_broadcast_received,
		"mission_briefing_stub_complete": GameState.mission_briefing_stub_complete,
		"mara_broadcast_reaction_complete": GameState.mara_broadcast_reaction_complete,
	}
