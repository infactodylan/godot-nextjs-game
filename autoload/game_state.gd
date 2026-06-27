extends Node

var plant_power_on := true
var plant_blackout_triggered := false
var controls_tutorial_complete := false
var blackout_dialogue_complete := false


func is_plant_power_on() -> bool:
	return plant_power_on


func set_plant_power_on(on: bool) -> void:
	plant_power_on = on


func has_plant_blackout_triggered() -> bool:
	return plant_blackout_triggered


func trigger_plant_blackout() -> void:
	if plant_blackout_triggered:
		return
	plant_blackout_triggered = true
	plant_power_on = false


func is_controls_tutorial_complete() -> bool:
	return controls_tutorial_complete


func mark_controls_tutorial_complete() -> void:
	controls_tutorial_complete = true


func is_blackout_dialogue_complete() -> bool:
	return blackout_dialogue_complete


func mark_blackout_dialogue_complete() -> void:
	blackout_dialogue_complete = true


var plant_diagnostic_puzzle_complete := false


func is_plant_diagnostic_puzzle_complete() -> bool:
	return plant_diagnostic_puzzle_complete


func mark_plant_diagnostic_puzzle_complete() -> void:
	plant_diagnostic_puzzle_complete = true
