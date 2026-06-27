extends Node

var plant_power_on := true
var plant_blackout_triggered := false


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
