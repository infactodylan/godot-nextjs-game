extends Node2D

enum GamePhase { MENU, PLAYING }

const SCREEN_SIZE_RATIO := 0.75
const MAP_SIZE := Vector2(3600.0, 900.0)
const CAMERA_ZOOM_MULTIPLIER := 10.0
const MAX_PLAY_AREA_VIEWPORT_HEIGHT_RATIO := 2.25
const VILLAGE_SCENE := "res://scenes/the_village.tscn"
const BASEMENT_SCENE := "res://scenes/power_plant_basement.tscn"
const SCENE_PATH := "res://scenes/power_plant.tscn"
const RETURN_FROM_PLANT_META := "return_from_plant"
const RETURN_FROM_BASEMENT_META := "return_from_basement"
const MARA_ACCOMPANYING_META := "mara_accompanying"
const GROUND_Y := PlantDoorSpawn.GROUND_Y
const DISCOVERY_MESSAGE := (
	"Fault log unlocked.\n\n"
	+ "Wear is past tolerance on multiple systems — relay banks, intake seals, "
	+ "turbine bearings, and pump couplings are all breaking down faster than expected.\n\n"
	+ "Several repairs have to be completed before this plant can run safely again."
)
const MARA_BATTERY_PROMPT := (
	"So the main plant is still dead — tenth relay failure this month, and the intake "
	+ "has no flow. We're not getting Ashford's broadcast like this.\n\n"
	+ "The village radio runs off emergency power. If we can't restore that, we miss "
	+ "everything they're sending tonight."
)
const PLAYER_BATTERY_OFFER := (
	"The emergency battery supply — it's in the basement. I can get that online. "
	+ "It won't fix the turbines, but it should power the radio."
)
const MARA_POST_BROADCAST := (
	"You did it — I can hear the relay humming again. Ashford wasn't kidding about "
	+ "that archive computer.\n\n"
	+ "The council will be gathering at the courthouse. Come on — we need to be "
	+ "there before they start making plans without us."
)

@onready var player: CharacterBody2D = $Player
@onready var map_camera: Camera2D = $MapCamera
@onready var hud: CanvasLayer = $HUD
@onready var exit_door: Area2D = $ExitDoor
@onready var diagnostic_console: Area2D = $DiagnosticConsole
@onready var basement_door: Area2D = $BasementDoor
@onready var interior_visual: Node2D = $InteriorVisual
@onready var puzzle_layer: CanvasLayer = $PuzzleLayer
@onready var slide_puzzle: Control = $PuzzleLayer/SlidePuzzle
@onready var mara_companion: Node2D = $MaraCompanion

var _phase := GamePhase.MENU
var _at_exit_door := false
var _at_diagnostic_console := false
var _at_basement_door := false
var _can_restart := false


func _ready() -> void:
	_reset_play_state()
	_setup_window_size()
	_setup_map_camera()
	player.set_physics_process(false)
	_configure_interior_power()
	AudioManager.set_tractor_ambience_near(true)

	hud.bind_player(player)
	hud.bind_camera(map_camera)
	hud.play_pressed.connect(_on_play_pressed)
	hud.restart_pressed.connect(_on_restart_pressed)
	player.died.connect(_on_player_died)
	exit_door.player_entered.connect(_on_exit_door_entered)
	exit_door.player_exited.connect(_on_exit_door_exited)
	diagnostic_console.player_entered.connect(_on_diagnostic_console_entered)
	diagnostic_console.player_exited.connect(_on_diagnostic_console_exited)
	basement_door.player_entered.connect(_on_basement_door_entered)
	basement_door.player_exited.connect(_on_basement_door_exited)
	slide_puzzle.solved.connect(_on_diagnostic_puzzle_solved)
	slide_puzzle.closed.connect(_on_diagnostic_puzzle_closed)
	_configure_mara_companion()

	if SaveManager.is_death_respawn():
		SaveManager.clear_death_respawn()
		call_deferred("_apply_death_respawn")
	elif SaveManager.consume_pending_resume(SCENE_PATH):
		call_deferred("_apply_saved_resume")
	elif get_tree().has_meta(RETURN_FROM_BASEMENT_META):
		call_deferred("_apply_basement_return")
	elif SaveManager.is_objective_replay():
		call_deferred("_apply_objective_replay_entry")
	elif get_tree().has_meta("power_plant_entry"):
		call_deferred("_apply_village_entry")
	else:
		hud.show_start_screen("Power Plant")


func _reset_play_state() -> void:
	get_tree().paused = false
	if puzzle_layer:
		puzzle_layer.visible = false
	if slide_puzzle and slide_puzzle.has_method("force_close"):
		slide_puzzle.force_close()


func _process(_delta: float) -> void:
	if _can_restart and Input.is_action_just_pressed("restart"):
		_on_restart_pressed()
		return

	_sync_exit_door_prompt()
	_sync_diagnostic_console_prompt()
	_sync_basement_door_prompt()
	_sync_basement_guide_arrow()
	_sync_village_return_arrow()

	if _phase == GamePhase.PLAYING:
		SaveManager.track_position(SCENE_PATH, player.global_position, _delta)

	if player.should_camera_follow():
		_update_camera_follow()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("interact"):
		return
	if slide_puzzle.is_open():
		return
	if _try_diagnostic_console():
		get_viewport().set_input_as_handled()
		return
	if _try_basement_entry():
		get_viewport().set_input_as_handled()
		return
	if _try_exit_to_village():
		get_viewport().set_input_as_handled()


func _is_at_exit_door() -> bool:
	return exit_door.is_player_inside(player)


func _is_at_diagnostic_console() -> bool:
	return diagnostic_console.is_player_inside(player)


func _is_at_basement_door() -> bool:
	return basement_door.is_player_inside(player)


func _can_use_basement_door() -> bool:
	return (
		GameState.is_plant_diagnostic_puzzle_complete()
		and GameState.is_battery_dialogue_complete()
	)


func _sync_basement_door_prompt() -> void:
	if not _can_use_basement_door():
		if _at_basement_door:
			_at_basement_door = false
			if not _at_exit_door and not _at_diagnostic_console:
				hud.hide_interact_prompt()
		return

	var at_door := _is_at_basement_door()
	if at_door and _phase == GamePhase.PLAYING and not hud.is_menu_visible() and not slide_puzzle.is_open():
		if not _at_basement_door:
			_at_basement_door = true
			hud.show_interact_prompt("Press E to enter the basement")
	elif _at_basement_door:
		_at_basement_door = false
		if not _at_exit_door and not _at_diagnostic_console:
			hud.hide_interact_prompt()


func _sync_basement_guide_arrow() -> void:
	if not _can_use_basement_door():
		hud.hide_objective_indicator()
		return
	if _phase != GamePhase.PLAYING or hud.is_menu_visible() or slide_puzzle.is_open():
		hud.hide_objective_indicator()
		return
	if _is_at_basement_door():
		hud.hide_objective_indicator()
		return
	hud.show_objective_indicator(basement_door, "BASEMENT")


func _sync_village_return_arrow() -> void:
	if not GameState.is_radio_broadcast_received():
		return
	if not GameState.is_mara_broadcast_reaction_complete():
		return
	if GameState.is_mission_briefing_stub_complete():
		return
	if _phase != GamePhase.PLAYING or hud.is_menu_visible() or slide_puzzle.is_open():
		return
	if _is_at_exit_door():
		hud.hide_objective_indicator()
		return
	hud.show_objective_indicator(exit_door, "VILLAGE")


func _try_basement_entry() -> bool:
	if not _can_use_basement_door():
		return false
	if not _is_at_basement_door() or _phase != GamePhase.PLAYING:
		return false
	if hud.is_menu_visible() or slide_puzzle.is_open():
		return false
	_enter_basement()
	return true


func _enter_basement() -> void:
	hud.hide_interact_prompt()
	hud.hide_objective_indicator()
	hud.hide_menu()
	_at_basement_door = false
	player.set_physics_process(false)
	player.velocity = Vector2.ZERO
	if mara_companion and mara_companion.has_method("start_idle_near"):
		mara_companion.call("start_idle_near", player)
	var entry_spawn := BasementSpawn.top_entry_spawn()
	SaveManager.prepare_scene_transition(BASEMENT_SCENE, "from_plant")
	SaveManager.register_room_entry(BASEMENT_SCENE, entry_spawn)
	get_tree().set_meta("basement_entry", true)
	get_tree().change_scene_to_file(BASEMENT_SCENE)


func _configure_mara_companion() -> void:
	if mara_companion == null:
		return
	if mara_companion.has_method("configure"):
		mara_companion.call("configure", player)
	if mara_companion.has_method("set_bounds"):
		mara_companion.call("set_bounds", 120.0, MAP_SIZE.x - 120.0, GROUND_Y)


func _spawn_mara_if_needed() -> void:
	if mara_companion == null:
		return
	if not GameState.is_mara_escorting() and not get_tree().has_meta(MARA_ACCOMPANYING_META):
		mara_companion.visible = false
		return
	get_tree().remove_meta(MARA_ACCOMPANYING_META)
	GameState.mark_mara_escorting(true)
	mara_companion.visible = true
	mara_companion.teleport_near_player()
	if mara_companion.has_method("start_idle_near"):
		mara_companion.call("start_idle_near", player)


func _on_basement_door_entered() -> void:
	_sync_basement_door_prompt()


func _on_basement_door_exited() -> void:
	_sync_basement_door_prompt()


func _sync_exit_door_prompt() -> void:
	var at_door := _is_at_exit_door()
	if at_door and _phase == GamePhase.PLAYING and not hud.is_menu_visible() and not slide_puzzle.is_open():
		if not _at_exit_door:
			_at_exit_door = true
			hud.show_interact_prompt("Press E to exit to the village")
	elif _at_exit_door:
		_at_exit_door = false
		if not _at_diagnostic_console:
			hud.hide_interact_prompt()


func _sync_diagnostic_console_prompt() -> void:
	if not _can_use_diagnostic_console():
		if _at_diagnostic_console:
			_at_diagnostic_console = false
			if not _at_exit_door:
				hud.hide_interact_prompt()
		return

	var at_console := _is_at_diagnostic_console()
	if at_console and _phase == GamePhase.PLAYING and not hud.is_menu_visible() and not slide_puzzle.is_open():
		if not _at_diagnostic_console:
			_at_diagnostic_console = true
			if GameState.is_plant_diagnostic_puzzle_complete():
				hud.show_interact_prompt("Press E to review the fault log")
			else:
				hud.show_interact_prompt("Press E to run diagnostics")
	elif _at_diagnostic_console:
		_at_diagnostic_console = false
		if not _at_exit_door:
			hud.hide_interact_prompt()


func _can_use_diagnostic_console() -> bool:
	return GameState.is_blackout_dialogue_complete() and not GameState.is_plant_power_on()


func _try_diagnostic_console() -> bool:
	if not _can_use_diagnostic_console():
		return false
	if not _is_at_diagnostic_console() or _phase != GamePhase.PLAYING:
		return false
	if hud.is_menu_visible() or slide_puzzle.is_open():
		return false
	if GameState.is_plant_diagnostic_puzzle_complete():
		_show_fault_log()
		return true
	_open_diagnostic_puzzle()
	return true


func _open_diagnostic_puzzle() -> void:
	hud.hide_interact_prompt()
	player.set_physics_process(false)
	player.velocity = Vector2.ZERO
	slide_puzzle.open_puzzle()


func _on_diagnostic_puzzle_closed() -> void:
	player.set_physics_process(true)
	_sync_diagnostic_console_prompt()


func _on_diagnostic_puzzle_solved() -> void:
	GameState.mark_plant_diagnostic_puzzle_complete()
	player.set_physics_process(false)
	player.velocity = Vector2.ZERO
	hud.show_npc_dialogue(
		"Plant diagnostic",
		DISCOVERY_MESSAGE,
		"Understood",
		_on_discovery_acknowledged
	)


func _on_discovery_acknowledged() -> void:
	if interior_visual.has_method("set_diagnostics_complete"):
		interior_visual.call("set_diagnostics_complete", true)
	if not GameState.is_battery_dialogue_complete():
		_show_battery_dialogue_chain()
	else:
		player.set_physics_process(true)


func _show_battery_dialogue_chain() -> void:
	hud.show_npc_dialogue(
		"Mara",
		MARA_BATTERY_PROMPT,
		"Continue",
		_show_player_battery_offer
	)


func _show_player_battery_offer() -> void:
	hud.show_npc_dialogue(
		"You",
		PLAYER_BATTERY_OFFER,
		"I'll go now",
		_on_battery_offer_acknowledged
	)


func _on_battery_offer_acknowledged() -> void:
	GameState.mark_battery_dialogue_complete()
	if interior_visual.has_method("set_basement_unlocked"):
		interior_visual.call("set_basement_unlocked", true)
	hud.hide_objective_indicator()
	_enter_basement()


func _show_mara_broadcast_reaction() -> void:
	if GameState.is_mara_broadcast_reaction_complete():
		return
	if not GameState.is_radio_broadcast_received():
		return
	if not GameState.is_mara_escorting():
		return
	GameState.mark_mara_broadcast_reaction_complete()
	player.set_physics_process(false)
	player.velocity = Vector2.ZERO
	hud.show_npc_dialogue(
		"Mara",
		MARA_POST_BROADCAST,
		"We should get back",
		_on_mara_broadcast_reaction_done
	)


func _on_mara_broadcast_reaction_done() -> void:
	player.set_physics_process(true)
	GameState.mark_mara_escorting(true)


func _apply_basement_return() -> void:
	get_tree().remove_meta(RETURN_FROM_BASEMENT_META)
	_reset_play_state()
	player.global_position = BasementSpawn.plant_basement_door_spawn(basement_door)
	hud.hide_menu()
	player.set_physics_process(true)
	_phase = GamePhase.PLAYING
	_spawn_mara_if_needed()
	if mara_companion and mara_companion.visible and mara_companion.has_method("start_idle_near"):
		mara_companion.call("start_idle_near", player)
	await get_tree().process_frame
	_snap_camera_to_player()
	_configure_interior_power()
	interior_visual.queue_redraw()
	call_deferred("_show_mara_broadcast_reaction")
	if GameState.is_battery_dialogue_complete() and not GameState.is_emergency_battery_active():
		call_deferred("_sync_basement_guide_arrow")
	_register_room_entry()


func _show_fault_log() -> void:
	hud.show_npc_dialogue(
		"Plant diagnostic",
		DISCOVERY_MESSAGE,
		"Close",
		func() -> void: player.set_physics_process(true)
	)


func _try_exit_to_village() -> bool:
	if not _is_at_exit_door() or _phase != GamePhase.PLAYING:
		return false
	if hud.is_menu_visible() or slide_puzzle.is_open():
		return false
	_exit_to_village()
	return true


func _configure_interior_power() -> void:
	var powered := _resolve_plant_powered()
	if interior_visual.has_method("set_power_on"):
		interior_visual.call("set_power_on", powered)
	if interior_visual.has_method("set_diagnostics_complete"):
		interior_visual.call(
			"set_diagnostics_complete",
			GameState.is_plant_diagnostic_puzzle_complete()
		)
	if interior_visual.has_method("set_basement_unlocked"):
		interior_visual.call(
			"set_basement_unlocked",
			GameState.is_battery_dialogue_complete()
		)


func _resolve_plant_powered() -> bool:
	return GameState.is_plant_power_on() or GameState.is_emergency_battery_active()


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
	var viewport_size := _viewport_size()
	var zoom_factor := _compute_camera_zoom(viewport_size)
	map_camera.configure(zoom_factor, MAP_SIZE)
	map_camera.make_current()
	_snap_camera_to_player(viewport_size)


func _viewport_size() -> Vector2:
	return get_viewport().get_visible_rect().size


func _compute_camera_zoom(viewport_size: Vector2) -> float:
	if viewport_size.x <= 1.0 or viewport_size.y <= 1.0:
		return 0.35
	var base_zoom := minf(
		viewport_size.x / MAP_SIZE.x,
		viewport_size.y / MAP_SIZE.y
	)
	var desired_zoom := base_zoom * CAMERA_ZOOM_MULTIPLIER
	var max_zoom_for_play_area_height := (
		viewport_size.y * MAX_PLAY_AREA_VIEWPORT_HEIGHT_RATIO / MAP_SIZE.y
	)
	return maxf(minf(desired_zoom, max_zoom_for_play_area_height), 0.08)


func _update_camera_follow() -> void:
	if not player.should_camera_follow():
		return

	var viewport_size := _viewport_size()
	var zoom_factor := map_camera.zoom.x
	if zoom_factor <= 0.0:
		zoom_factor = _compute_camera_zoom(viewport_size)
		map_camera.configure(zoom_factor, MAP_SIZE)
	var half_view := viewport_size / (2.0 * zoom_factor)
	var target_x := clampf(player.global_position.x, half_view.x, MAP_SIZE.x - half_view.x)
	var target_y: float
	if half_view.y >= MAP_SIZE.y * 0.5:
		target_y = MAP_SIZE.y * 0.5
	else:
		target_y = clampf(player.global_position.y, half_view.y, MAP_SIZE.y - half_view.y)
	map_camera.position = Vector2(target_x, target_y)


func _apply_village_entry() -> void:
	get_tree().remove_meta("power_plant_entry")
	_reset_play_state()
	_place_player_at_interior_door()
	hud.hide_menu()
	player.set_physics_process(true)
	_phase = GamePhase.PLAYING
	_spawn_mara_if_needed()
	await get_tree().process_frame
	_snap_camera_to_player()
	_configure_interior_power()
	interior_visual.queue_redraw()
	if GameState.is_plant_diagnostic_puzzle_complete() and not GameState.is_battery_dialogue_complete():
		call_deferred("_show_battery_dialogue_chain")
	elif GameState.is_radio_broadcast_received():
		call_deferred("_show_mara_broadcast_reaction")
	elif GameState.is_battery_dialogue_complete():
		call_deferred("_sync_basement_guide_arrow")
	_register_room_entry()


func _apply_objective_replay_entry() -> void:
	var objective_id := SaveManager.consume_objective_replay()
	_reset_play_state()
	_place_player_at_interior_door()
	hud.hide_menu()
	player.set_physics_process(true)
	_phase = GamePhase.PLAYING
	_spawn_mara_if_needed()
	_configure_interior_power()
	_snap_camera_to_player()
	interior_visual.queue_redraw()
	match objective_id:
		"battery_briefing":
			call_deferred("_show_battery_dialogue_chain")
		"plant_debrief":
			GameState.mark_mara_escorting(true)
			if mara_companion:
				mara_companion.visible = true
				mara_companion.teleport_near_player()
				if mara_companion.has_method("start_idle_near"):
					mara_companion.call("start_idle_near", player)
			call_deferred("_show_mara_broadcast_reaction")
		"plant_investigation":
			if interior_visual.has_method("set_diagnostics_complete"):
				interior_visual.call("set_diagnostics_complete", false)
	_register_room_entry()


func _register_room_entry() -> void:
	SaveManager.register_room_entry(SCENE_PATH, player.global_position)


func _apply_saved_resume() -> void:
	_reset_play_state()
	SaveManager.apply_resume_spawn(player)
	hud.hide_menu()
	player.set_physics_process(true)
	_phase = GamePhase.PLAYING
	_spawn_mara_if_needed()
	_configure_interior_power()
	_snap_camera_to_player()
	interior_visual.queue_redraw()


func _apply_death_respawn() -> void:
	_reset_play_state()
	_place_player_at_interior_door()
	SaveManager.apply_death_respawn(player)
	hud.hide_menu()
	player.set_physics_process(true)
	_phase = GamePhase.PLAYING
	_spawn_mara_if_needed()
	_configure_interior_power()
	_snap_camera_to_player()
	interior_visual.queue_redraw()
	if GameState.is_battery_dialogue_complete() and not GameState.is_emergency_battery_active():
		call_deferred("_sync_basement_guide_arrow")
	_register_room_entry()


func _place_player_at_interior_door() -> void:
	player.global_position = PlantDoorSpawn.interior_spawn(exit_door)


func _snap_camera_to_player(
	viewport_size: Vector2 = Vector2.ZERO,
	zoom_factor: float = -1.0
) -> void:
	if not player.should_camera_follow():
		return
	if viewport_size == Vector2.ZERO:
		viewport_size = _viewport_size()
	if zoom_factor <= 0.0:
		zoom_factor = map_camera.zoom.x
	if zoom_factor <= 0.0:
		zoom_factor = _compute_camera_zoom(viewport_size)
		map_camera.configure(zoom_factor, MAP_SIZE)
	var half_view := viewport_size / (2.0 * zoom_factor)
	var target_x := clampf(player.global_position.x, half_view.x, MAP_SIZE.x - half_view.x)
	var target_y: float
	if half_view.y >= MAP_SIZE.y * 0.5:
		target_y = MAP_SIZE.y * 0.5
	else:
		target_y = clampf(player.global_position.y, half_view.y, MAP_SIZE.y - half_view.y)
	map_camera.position = Vector2(target_x, target_y)
	map_camera.make_current()


func _on_exit_door_entered() -> void:
	_sync_exit_door_prompt()


func _on_exit_door_exited() -> void:
	_sync_exit_door_prompt()


func _on_diagnostic_console_entered() -> void:
	_sync_diagnostic_console_prompt()


func _on_diagnostic_console_exited() -> void:
	_sync_diagnostic_console_prompt()


func _exit_to_village() -> void:
	hud.hide_interact_prompt()
	_at_exit_door = false
	_at_diagnostic_console = false
	if slide_puzzle.is_open():
		slide_puzzle.force_close()
	get_tree().paused = false
	if puzzle_layer:
		puzzle_layer.visible = false
	AudioManager.set_tractor_ambience_near(false)
	get_tree().set_meta(RETURN_FROM_PLANT_META, true)
	get_tree().call_deferred("change_scene_to_file", VILLAGE_SCENE)


func _on_player_died() -> void:
	get_tree().paused = false
	SaveManager.handle_player_death()


func _on_play_pressed() -> void:
	_start_level_from_beginning()


func _start_level_from_beginning() -> void:
	_reset_play_state()
	hud.hide_menu()
	_place_player_at_interior_door()
	player.set_physics_process(true)
	_phase = GamePhase.PLAYING
	_spawn_mara_if_needed()
	_configure_interior_power()
	_snap_camera_to_player()
	interior_visual.queue_redraw()
	if GameState.is_battery_dialogue_complete():
		call_deferred("_sync_basement_guide_arrow")
	_register_room_entry()


func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
