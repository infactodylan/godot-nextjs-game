extends Node2D

enum GamePhase { MENU, PLAYING }

const HEALTH_POTION_DURATION := 20.0
const SCREEN_SIZE_RATIO := 0.75
const MAP_SIZE := Vector2(7800.0, 900.0)
const PLATFORM_SURFACE_OFFSET := 8.0
const PLATFORM_TOP_OFFSET := PLATFORM_SURFACE_OFFSET
const CAMERA_ZOOM_MULTIPLIER := 10.0
const MAX_PLAY_AREA_VIEWPORT_HEIGHT_RATIO := 2.25
const WASTELANDS_SCENE := "res://scenes/waste_lands.tscn"
const POWER_PLANT_SCENE := "res://scenes/power_plant.tscn"
const SCENE_PATH := "res://scenes/the_village.tscn"
const RETURN_FROM_PLANT_META := "return_from_plant"
const GROUND_Y := PlantDoorSpawn.GROUND_Y
const MISSION_BRIEFING_STUB := (
	"We made it in time. Half the village heard Ashford on the relay — everyone is "
	+ "talking about that archive computer.\n\n"
	+ "The council is putting a mission party together. They'll want volunteers "
	+ "who can survive the road east. This changes everything for River City."
)

@onready var player: CharacterBody2D = $Player
@onready var map_camera: Camera2D = $MapCamera
@onready var village_background: Node2D = $VillageBackground
@onready var hud: CanvasLayer = $HUD
@onready var pickups: Node2D = $Pickups
@onready var wasteland_gate: Area2D = $WastelandGate
@onready var courtyard_gate: Area2D = $CourtyardGate
@onready var power_plant_door: Area2D = $PowerPlant/EntryDoor
@onready var tutorial_guide: Node2D = $TutorialGuide

var _ammo_pot_scene: PackedScene = preload("res://entities/ammo_pot/ammo_pot.tscn")
var _health_potion_scene: PackedScene = preload("res://entities/health_potion/health_potion.tscn")

var _can_restart := false
var _phase := GamePhase.MENU
var _active_ammo_pot: Area2D
var _active_health_potion: Area2D
var _health_potion_timer := 0.0
var _wasteland_prompt_open := false
var _wasteland_gate_armed := true
var _at_power_plant_door := false


func _ready() -> void:
	_setup_window_size()
	_setup_map_camera()
	player.set_physics_process(false)
	AudioManager.play_village_ambience()
	AudioManager.reset_tractor_ambience()
	_apply_persisted_plant_power()

	hud.bind_player(player)
	hud.bind_camera(map_camera)
	village_background.bind_camera(map_camera)
	hud.play_pressed.connect(_on_play_pressed)
	hud.restart_pressed.connect(_on_restart_pressed)
	player.died.connect(_on_player_died)
	player.ammo_changed.connect(_on_player_ammo_changed)
	player.health_changed.connect(_on_player_health_changed)
	wasteland_gate.player_entered.connect(_on_wasteland_gate_entered)
	wasteland_gate.player_exited.connect(_on_wasteland_gate_exited)
	courtyard_gate.player_entered_courtyard.connect(_on_courtyard_entered)
	power_plant_door.player_entered.connect(_on_power_plant_door_entered)
	power_plant_door.player_exited.connect(_on_power_plant_door_exited)
	tutorial_guide.configure(hud, player, power_plant_door)
	tutorial_guide.finished.connect(_on_tutorial_finished)
	tutorial_guide.blackout_dialogue_finished.connect(_on_blackout_dialogue_finished)

	if SaveManager.is_death_respawn():
		SaveManager.clear_death_respawn()
		call_deferred("_apply_death_respawn")
	elif SaveManager.consume_pending_resume(SCENE_PATH):
		call_deferred("_apply_saved_resume")
	elif get_tree().has_meta("village_spawn_x") or get_tree().has_meta(RETURN_FROM_PLANT_META):
		call_deferred("_apply_entry_spawn")
	else:
		hud.show_start_screen("The Village")


func _process(delta: float) -> void:
	if _can_restart and Input.is_action_just_pressed("restart"):
		_on_restart_pressed()
		return

	_update_pickup_timers(delta)
	_sync_power_plant_door_prompt()
	_sync_courthouse_guide_arrow()

	if _phase == GamePhase.PLAYING:
		SaveManager.track_position(SCENE_PATH, player.global_position, delta)

	if player.should_camera_follow():
		_update_camera_follow()


func _setup_window_size() -> void:
	if OS.has_feature("web"):
		return

	var screen_index := DisplayServer.window_get_current_screen()
	var screen_size := DisplayServer.screen_get_size(screen_index)
	var target_width := int(screen_size.x * SCREEN_SIZE_RATIO)
	var target_height := int(screen_size.y * SCREEN_SIZE_RATIO)
	var map_aspect := MAP_SIZE.x / MAP_SIZE.y
	var window_aspect := float(target_width) / float(target_height)

	if window_aspect < map_aspect:
		target_height = int(float(target_width) / map_aspect)
	else:
		target_width = int(float(target_height) * map_aspect)

	var window_size := Vector2i(target_width, target_height)
	DisplayServer.window_set_size(window_size)
	DisplayServer.window_set_position((screen_size - window_size) / 2)


func _setup_map_camera() -> void:
	await get_tree().process_frame
	var viewport_size := get_viewport().get_visible_rect().size
	var base_zoom := minf(
		viewport_size.x / MAP_SIZE.x,
		viewport_size.y / MAP_SIZE.y
	)
	var desired_zoom := base_zoom * CAMERA_ZOOM_MULTIPLIER
	var max_zoom_for_play_area_height := (
		viewport_size.y * MAX_PLAY_AREA_VIEWPORT_HEIGHT_RATIO / MAP_SIZE.y
	)
	var zoom_factor := minf(desired_zoom, max_zoom_for_play_area_height)
	map_camera.configure(zoom_factor, MAP_SIZE)
	map_camera.make_current()
	var half_view := viewport_size / (2.0 * zoom_factor)
	var initial_y := MAP_SIZE.y * 0.5 if half_view.y >= MAP_SIZE.y * 0.5 else player.global_position.y
	map_camera.position = Vector2(player.global_position.x, initial_y)


func _update_camera_follow() -> void:
	if not player.should_camera_follow():
		return

	var viewport_size := get_viewport().get_visible_rect().size
	var half_view := viewport_size / (2.0 * map_camera.zoom)
	var target_x := clampf(player.global_position.x, half_view.x, MAP_SIZE.x - half_view.x)
	var target_y: float
	if half_view.y >= MAP_SIZE.y * 0.5:
		target_y = MAP_SIZE.y * 0.5
	else:
		target_y = clampf(player.global_position.y, half_view.y, MAP_SIZE.y - half_view.y)
	map_camera.position = Vector2(target_x, target_y)


func _update_pickup_timers(delta: float) -> void:
	if _active_health_potion and is_instance_valid(_active_health_potion):
		_health_potion_timer -= delta
		hud.update_health_timer(_health_potion_timer)
		if _health_potion_timer <= 0.0:
			_despawn_health_potion()


func _on_player_ammo_changed(current: int, _maximum: int) -> void:
	if current <= 2:
		_try_spawn_ammo_pot()


func _on_player_health_changed(current: int, _maximum: int) -> void:
	if current == 1:
		_try_spawn_health_potion()


func _try_spawn_health_potion() -> void:
	if _active_health_potion and is_instance_valid(_active_health_potion):
		return

	var platforms := _get_available_platforms()
	if platforms.is_empty():
		return

	var platform: Node2D = platforms.pick_random()
	_despawn_health_potion()
	var potion := _health_potion_scene.instantiate() as Area2D
	pickups.add_child(potion)
	potion.global_position = _platform_pickup_position(platform)
	potion.collected.connect(_on_health_potion_collected)
	_active_health_potion = potion
	_health_potion_timer = HEALTH_POTION_DURATION
	hud.show_health_indicator(potion, _health_potion_timer)


func _try_spawn_ammo_pot() -> void:
	if _active_ammo_pot and is_instance_valid(_active_ammo_pot):
		return

	var platforms := _get_available_platforms()
	if platforms.is_empty():
		return

	var platform: Node2D = platforms.pick_random()
	var pot := _ammo_pot_scene.instantiate() as Area2D
	pickups.add_child(pot)
	pot.global_position = _platform_pickup_position(platform)
	pot.collected.connect(_on_ammo_pot_collected)
	_active_ammo_pot = pot
	hud.show_reload_indicator(pot, -1.0)


func _despawn_health_potion() -> void:
	if _active_health_potion and is_instance_valid(_active_health_potion):
		_active_health_potion.queue_free()
	_active_health_potion = null
	_health_potion_timer = 0.0
	hud.hide_health_indicator()


func _on_ammo_pot_collected() -> void:
	_active_ammo_pot = null
	hud.hide_reload_indicator()


func _on_health_potion_collected() -> void:
	_active_health_potion = null
	_health_potion_timer = 0.0
	hud.hide_health_indicator()


func _get_available_platforms() -> Array[Node2D]:
	var platforms: Array[Node2D] = []
	for node in get_tree().get_nodes_in_group("platform"):
		if _active_health_potion and is_instance_valid(_active_health_potion):
			if node.global_position.distance_to(_active_health_potion.global_position) < 40.0:
				continue
		if _active_ammo_pot and is_instance_valid(_active_ammo_pot):
			if node.global_position.distance_to(_active_ammo_pot.global_position) < 40.0:
				continue
		platforms.append(node as Node2D)
	return platforms


func _platform_pickup_position(platform: Node2D) -> Vector2:
	var roof_offset := PLATFORM_TOP_OFFSET
	if platform.has_method("get_roof_offset"):
		roof_offset = platform.call("get_roof_offset")
	elif platform.has_meta("roof_offset"):
		roof_offset = platform.get_meta("roof_offset")
	return platform.global_position + Vector2(0.0, -roof_offset)


func _on_player_died() -> void:
	get_tree().paused = false
	SaveManager.handle_player_death()


func _apply_saved_resume() -> void:
	SaveManager.apply_resume_spawn(player)
	hud.hide_menu()
	get_tree().paused = false
	player.set_physics_process(true)
	_phase = GamePhase.PLAYING
	_snap_camera_to_player()
	tutorial_guide.start_if_needed()
	_sync_power_plant_door_prompt()
	call_deferred("_sync_courthouse_guide_arrow")


func _apply_death_respawn() -> void:
	SaveManager.apply_death_respawn(player)
	hud.hide_menu()
	get_tree().paused = false
	player.set_physics_process(true)
	_phase = GamePhase.PLAYING
	_snap_camera_to_player()
	tutorial_guide.start_if_needed()
	_sync_power_plant_door_prompt()
	call_deferred("_sync_courthouse_guide_arrow")


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("interact"):
		return
	if _try_power_plant_entry():
		get_viewport().set_input_as_handled()


func _is_at_power_plant_door() -> bool:
	return power_plant_door.is_player_inside(player)


func _is_at_courthouse() -> bool:
	return courtyard_gate.is_player_inside(player)


func _should_escort_to_courthouse() -> bool:
	return (
		GameState.is_radio_broadcast_received()
		and not GameState.is_mission_briefing_stub_complete()
	)


func _sync_courthouse_guide_arrow() -> void:
	if not _should_escort_to_courthouse():
		hud.hide_objective_indicator()
		return
	if _phase != GamePhase.PLAYING or hud.is_menu_visible():
		hud.hide_objective_indicator()
		return
	if _is_at_courthouse():
		hud.hide_objective_indicator()
		return
	hud.show_objective_indicator(courtyard_gate, "COURTHOUSE")


func _sync_power_plant_door_prompt() -> void:
	var at_door := _is_at_power_plant_door()
	if at_door and _phase == GamePhase.PLAYING and not hud.is_menu_visible():
		if not GameState.is_controls_tutorial_complete():
			if not _at_power_plant_door:
				_at_power_plant_door = true
				hud.show_interact_prompt("Complete Mara's training first.")
			return
		if not _at_power_plant_door:
			_at_power_plant_door = true
			if tutorial_guide.is_following_to_plant() or GameState.is_mara_escorting():
				hud.show_interact_prompt("Press E to enter the power plant (Mara follows)")
			else:
				hud.show_interact_prompt("Press E to enter the power plant")
	elif _at_power_plant_door:
		_at_power_plant_door = false
		hud.hide_interact_prompt()


func _try_power_plant_entry() -> bool:
	if not GameState.is_controls_tutorial_complete():
		return false
	if not _is_at_power_plant_door() or _phase != GamePhase.PLAYING:
		return false
	if hud.is_menu_visible():
		return false
	_enter_power_plant()
	return true


func _on_power_plant_door_entered() -> void:
	_sync_power_plant_door_prompt()


func _on_power_plant_door_exited() -> void:
	_sync_power_plant_door_prompt()


func _enter_power_plant() -> void:
	hud.hide_interact_prompt()
	_at_power_plant_door = false
	if GameState.is_mara_escorting() or tutorial_guide.is_following_to_plant():
		get_tree().set_meta("mara_accompanying", true)
		GameState.mark_mara_escorting(true)
	get_tree().set_meta("power_plant_entry", true)
	get_tree().call_deferred("change_scene_to_file", POWER_PLANT_SCENE)


func _on_wasteland_gate_entered() -> void:
	if not GameState.is_controls_tutorial_complete():
		return
	if not _wasteland_gate_armed or _wasteland_prompt_open or _phase != GamePhase.PLAYING:
		return
	_wasteland_prompt_open = true
	hud.show_choice_prompt(
		"Edge of the Village",
		"The wastelands lie ahead — ruined streets, enemies, and a boss gun.\nDo you want to leave the village?",
		"Enter the Wastelands",
		"Stay in the Village",
		_go_to_wastelands,
		_stay_in_village
	)


func _go_to_wastelands() -> void:
	AudioManager.stop_village_ambience()
	AudioManager.reset_tractor_ambience()
	get_tree().set_meta("wasteland_spawn_x", 250.0)
	get_tree().change_scene_to_file(WASTELANDS_SCENE)


func _apply_entry_spawn() -> void:
	var spawn_x: float
	if get_tree().has_meta(RETURN_FROM_PLANT_META):
		get_tree().remove_meta(RETURN_FROM_PLANT_META)
		spawn_x = PlantDoorSpawn.exterior_spawn(power_plant_door).x
	elif get_tree().has_meta("village_spawn_x"):
		spawn_x = get_tree().get_meta("village_spawn_x")
		get_tree().remove_meta("village_spawn_x")
	else:
		return
	player.global_position = Vector2(spawn_x, GROUND_Y)
	hud.hide_menu()
	player.set_physics_process(true)
	_phase = GamePhase.PLAYING
	_snap_camera_to_player()
	tutorial_guide.start_if_needed()
	_sync_power_plant_door_prompt()
	call_deferred("_sync_courthouse_guide_arrow")
	SaveManager.register_room_entry(SCENE_PATH, player.global_position)


func _snap_camera_to_player() -> void:
	if not player.should_camera_follow():
		return
	var viewport_size := get_viewport().get_visible_rect().size
	var half_view := viewport_size / (2.0 * map_camera.zoom)
	map_camera.position.x = clampf(player.global_position.x, half_view.x, MAP_SIZE.x - half_view.x)


func _stay_in_village() -> void:
	_wasteland_prompt_open = false


func _on_wasteland_gate_exited() -> void:
	_wasteland_gate_armed = true
	_wasteland_prompt_open = false


func _apply_persisted_plant_power() -> void:
	if GameState.is_plant_power_on():
		_set_village_lights(true)
	elif GameState.is_emergency_battery_active():
		_set_village_light_brightness(0.38)
	else:
		_set_village_lights(false)


func _start_mission_briefing_at_courthouse() -> void:
	if GameState.is_mission_briefing_stub_complete():
		return
	if _phase != GamePhase.PLAYING or hud.is_menu_visible():
		return
	tutorial_guide.finish_follow_to_courthouse()
	hud.hide_objective_indicator()
	player.set_physics_process(false)
	player.velocity = Vector2.ZERO
	hud.show_npc_dialogue(
		"Mara",
		MISSION_BRIEFING_STUB,
		"Understood",
		_on_mission_briefing_stub_done
	)


func _on_mission_briefing_stub_done() -> void:
	GameState.mark_mission_briefing_stub_complete()
	GameState.mark_mara_escorting(false)
	player.set_physics_process(true)


func _on_courtyard_entered() -> void:
	if not GameState.is_controls_tutorial_complete():
		return
	if _phase != GamePhase.PLAYING:
		return
	if _should_escort_to_courthouse():
		_start_mission_briefing_at_courthouse()
		return
	if GameState.has_plant_blackout_triggered():
		return
	GameState.trigger_plant_blackout()
	AudioManager.play_power_down()
	AudioManager.play_electric_zap()
	await _flicker_out_village_lights()
	tutorial_guide.start_blackout_if_needed()


func _flicker_out_village_lights() -> void:
	var flicker_pattern: Array[Vector2] = [
		Vector2(0.14, 0.0),
		Vector2(0.07, 1.0),
		Vector2(0.10, 0.0),
		Vector2(0.05, 0.85),
		Vector2(0.08, 0.0),
		Vector2(0.04, 1.0),
		Vector2(0.06, 0.0),
		Vector2(0.05, 0.55),
		Vector2(0.07, 0.0),
		Vector2(0.04, 0.35),
		Vector2(0.05, 0.0),
		Vector2(0.03, 0.15),
		Vector2(0.04, 0.0),
		Vector2(0.06, 0.0),
	]
	for step in flicker_pattern:
		await get_tree().create_timer(step.x).timeout
		_set_village_light_brightness(step.y)
	_set_village_lights(false)


func _set_village_light_brightness(brightness: float) -> void:
	for node in get_tree().get_nodes_in_group("village_lit_building"):
		if node.has_method("set_light_brightness"):
			node.call("set_light_brightness", brightness)


func _set_village_lights(on: bool) -> void:
	for node in get_tree().get_nodes_in_group("village_lit_building"):
		if node.has_method("set_lights_on"):
			node.call("set_lights_on", on)


func _on_play_pressed() -> void:
	_start_level_from_beginning()


func _start_level_from_beginning() -> void:
	hud.hide_menu()
	get_tree().paused = false
	player.set_physics_process(true)
	_phase = GamePhase.PLAYING
	tutorial_guide.start_if_needed()
	_sync_power_plant_door_prompt()
	call_deferred("_sync_courthouse_guide_arrow")
	SaveManager.register_room_entry(SCENE_PATH, player.global_position)


func _on_tutorial_finished() -> void:
	_sync_power_plant_door_prompt()


func _on_blackout_dialogue_finished() -> void:
	_sync_power_plant_door_prompt()


func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
