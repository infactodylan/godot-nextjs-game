extends Node

const OBJECTIVE_REPLAY_META := "objective_replay"

const ENTRIES: Array[Dictionary] = [
	{
		"id": "controls_tutorial",
		"title": "Learn the controls with Mara",
		"scene": "res://scenes/the_village.tscn",
	},
	{
		"id": "blackout",
		"title": "Investigate the courtroom blackout",
		"scene": "res://scenes/the_village.tscn",
	},
	{
		"id": "plant_investigation",
		"title": "Diagnose the plant shutdown",
		"scene": "res://scenes/power_plant.tscn",
	},
	{
		"id": "battery_briefing",
		"title": "Brief with Mara about the emergency battery",
		"scene": "res://scenes/power_plant.tscn",
	},
	{
		"id": "emergency_power",
		"title": "Restore emergency power in the basement",
		"scene": "res://scenes/power_plant_basement.tscn",
	},
	{
		"id": "plant_debrief",
		"title": "Debrief with Mara after the broadcast",
		"scene": "res://scenes/power_plant.tscn",
	},
	{
		"id": "mission_briefing",
		"title": "Attend the mission briefing",
		"scene": "res://scenes/the_village.tscn",
	},
]

var _pending_replay_id := ""


func get_entries() -> Array[Dictionary]:
	return ENTRIES


func is_complete(objective_id: String) -> bool:
	match objective_id:
		"controls_tutorial":
			return GameState.is_controls_tutorial_complete()
		"blackout":
			return GameState.is_blackout_dialogue_complete()
		"plant_investigation":
			return GameState.is_plant_diagnostic_puzzle_complete()
		"battery_briefing":
			return GameState.is_battery_dialogue_complete()
		"emergency_power":
			return GameState.is_radio_broadcast_received()
		"plant_debrief":
			return GameState.is_mara_broadcast_reaction_complete()
		"mission_briefing":
			return GameState.is_mission_briefing_stub_complete()
	return false


func get_completed_objectives() -> Array[Dictionary]:
	var completed: Array[Dictionary] = []
	for entry in ENTRIES:
		if is_complete(entry.id):
			completed.append(entry)
	return completed


func has_any_completed() -> bool:
	return not get_completed_objectives().is_empty()


func begin_replay(objective_id: String, tree: SceneTree) -> void:
	var index := _index_of(objective_id)
	if index < 0:
		return
	GameState.reset_from_objective_index(index)
	_pending_replay_id = objective_id
	var scene_path: String = ENTRIES[index].scene
	SaveManager.prepare_objective_replay(scene_path)
	tree.set_meta(OBJECTIVE_REPLAY_META, objective_id)
	tree.call_deferred("change_scene_to_file", scene_path)


func has_pending_replay() -> bool:
	return not _pending_replay_id.is_empty()


func consume_replay_id() -> String:
	var replay_id := _pending_replay_id
	_pending_replay_id = ""
	return replay_id


func peek_replay_id() -> String:
	return _pending_replay_id


func _index_of(objective_id: String) -> int:
	for i in ENTRIES.size():
		if ENTRIES[i].id == objective_id:
			return i
	return -1
