extends Node

var plant_power_on := true
var plant_blackout_triggered := false
var controls_tutorial_complete := false
var blackout_dialogue_complete := false


func is_plant_power_on() -> bool:
	return plant_power_on


func set_plant_power_on(on: bool) -> void:
	plant_power_on = on
	SaveManager.on_state_changed()


func has_plant_blackout_triggered() -> bool:
	return plant_blackout_triggered


func trigger_plant_blackout() -> void:
	if plant_blackout_triggered:
		return
	plant_blackout_triggered = true
	plant_power_on = false
	SaveManager.on_state_changed()


func is_controls_tutorial_complete() -> bool:
	return controls_tutorial_complete


func mark_controls_tutorial_complete() -> void:
	controls_tutorial_complete = true
	SaveManager.on_state_changed()


func is_blackout_dialogue_complete() -> bool:
	return blackout_dialogue_complete


func mark_blackout_dialogue_complete() -> void:
	blackout_dialogue_complete = true
	SaveManager.on_state_changed()


var plant_diagnostic_puzzle_complete := false


func is_plant_diagnostic_puzzle_complete() -> bool:
	return plant_diagnostic_puzzle_complete


func mark_plant_diagnostic_puzzle_complete() -> void:
	plant_diagnostic_puzzle_complete = true
	plant_component_failed = true
	SaveManager.on_state_changed()


var plant_component_failed := false
var mara_escorting := false
var battery_dialogue_complete := false
var emergency_battery_active := false
var radio_broadcast_received := false


func is_plant_component_failed() -> bool:
	return plant_component_failed


func is_mara_escorting() -> bool:
	return mara_escorting


func mark_mara_escorting(on: bool) -> void:
	mara_escorting = on
	SaveManager.on_state_changed()


func is_battery_dialogue_complete() -> bool:
	return battery_dialogue_complete


func mark_battery_dialogue_complete() -> void:
	battery_dialogue_complete = true
	SaveManager.on_state_changed()


func is_emergency_battery_active() -> bool:
	return emergency_battery_active


func set_emergency_battery_active(on: bool) -> void:
	emergency_battery_active = on
	SaveManager.on_state_changed()


func is_radio_broadcast_received() -> bool:
	return radio_broadcast_received


func mark_radio_broadcast_received() -> void:
	radio_broadcast_received = true
	SaveManager.on_state_changed()


func has_partial_power() -> bool:
	return emergency_battery_active


var mission_briefing_stub_complete := false
var mara_broadcast_reaction_complete := false


func is_mission_briefing_stub_complete() -> bool:
	return mission_briefing_stub_complete


func mark_mission_briefing_stub_complete() -> void:
	mission_briefing_stub_complete = true
	SaveManager.on_state_changed()


func is_mara_broadcast_reaction_complete() -> bool:
	return mara_broadcast_reaction_complete


func mark_mara_broadcast_reaction_complete() -> void:
	mara_broadcast_reaction_complete = true
	SaveManager.on_state_changed()


func reset_from_objective_index(from_index: int) -> void:
	if from_index <= 0:
		controls_tutorial_complete = false
	if from_index <= 1:
		plant_blackout_triggered = false
		blackout_dialogue_complete = false
		plant_power_on = true
		mara_escorting = false
	if from_index <= 2:
		plant_diagnostic_puzzle_complete = false
		plant_component_failed = false
	if from_index <= 3:
		battery_dialogue_complete = false
		mara_escorting = false
	if from_index <= 4:
		emergency_battery_active = false
		radio_broadcast_received = false
	if from_index <= 5:
		mara_broadcast_reaction_complete = false
		mara_escorting = false
	if from_index <= 6:
		mission_briefing_stub_complete = false
		mara_escorting = false
	SaveManager.on_state_changed()


func apply_from_save(data: Dictionary) -> void:
	if data.is_empty():
		return
	plant_power_on = data.get("plant_power_on", plant_power_on)
	plant_blackout_triggered = data.get("plant_blackout_triggered", plant_blackout_triggered)
	controls_tutorial_complete = data.get("controls_tutorial_complete", controls_tutorial_complete)
	blackout_dialogue_complete = data.get("blackout_dialogue_complete", blackout_dialogue_complete)
	plant_diagnostic_puzzle_complete = data.get(
		"plant_diagnostic_puzzle_complete", plant_diagnostic_puzzle_complete
	)
	plant_component_failed = data.get("plant_component_failed", plant_component_failed)
	mara_escorting = data.get("mara_escorting", mara_escorting)
	battery_dialogue_complete = data.get("battery_dialogue_complete", battery_dialogue_complete)
	emergency_battery_active = data.get("emergency_battery_active", emergency_battery_active)
	radio_broadcast_received = data.get("radio_broadcast_received", radio_broadcast_received)
	mission_briefing_stub_complete = data.get(
		"mission_briefing_stub_complete", mission_briefing_stub_complete
	)
	mara_broadcast_reaction_complete = data.get(
		"mara_broadcast_reaction_complete", mara_broadcast_reaction_complete
	)
