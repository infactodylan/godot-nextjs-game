extends Node2D

enum GamePhase { MENU, PLAYING }

const SCREEN_SIZE_RATIO := 0.75
const MAP_SIZE := Vector2(3200.0, 2000.0)
const CAMERA_ZOOM_MULTIPLIER := 10.0
const MAX_PLAY_AREA_VIEWPORT_HEIGHT_RATIO := 5.5
const HORIZONTAL_FLOOR_Y := 1680.0
const HORIZONTAL_SECTION_Y := 1500.0
const MAP_BOUND_MARGIN := 32.0
const MAP_FALL_DEATH_Y := MAP_SIZE.y + MAP_BOUND_MARGIN
const POWER_PLANT_SCENE := "res://scenes/power_plant.tscn"
const RETURN_FROM_BASEMENT_META := "return_from_basement"
const BASEMENT_ENTRY_META := "basement_entry"
const SCENE_PATH := "res://scenes/power_plant_basement.tscn"

const RADIO_PART_ONE := (
	"*static crackles, then steadies*\n\n"
	+ "This is Ashford Settlement on the relay band. If anyone is listening — "
	+ "we've confirmed the archive is real. A pre-war supercomputer, still intact "
	+ "somewhere in the eastern bunkers."
)
const RADIO_PART_TWO := (
	"A machine that may hold all the knowledge we lost — blueprints, medicine, "
	+ "power systems, everything. We're organizing survivors to find it.\n\n"
	+ "If your settlement can relay this message or send volunteers, respond on "
	+ "this frequency. Ashford out."
)

@onready var player: CharacterBody2D = $Player
@onready var map_camera: Camera2D = $MapCamera
@onready var hud: CanvasLayer = $HUD
@onready var exit_door: Area2D = $ExitDoor
@onready var battery_switch: Area2D = $EmergencyBatterySwitch
@onready var basement_visual: Node2D = $BasementVisual
@onready var enemies: Node2D = $Enemies

var _enemy_scene: PackedScene = preload("res://entities/enemy/enemy.tscn")
var _phase := GamePhase.MENU
var _at_exit_door := false
var _at_battery_switch := false
var _can_restart := false
var _enemies_alive := 0
var _waves_spawned := false


func _ready() -> void:
	_setup_window_size()
	_setup_map_camera()
	player.set_physics_process(false)
	if basement_visual.has_method("set_emergency_power"):
		basement_visual.call("set_emergency_power", GameState.is_emergency_battery_active())

	hud.bind_player(player)
	hud.bind_camera(map_camera)
	hud.play_pressed.connect(_on_play_pressed)
	hud.restart_pressed.connect(_on_restart_pressed)
	player.died.connect(_on_player_died)
	exit_door.player_entered.connect(_on_exit_door_entered)
	exit_door.player_exited.connect(_on_exit_door_exited)
	battery_switch.player_entered.connect(_on_battery_switch_entered)
	battery_switch.player_exited.connect(_on_battery_switch_exited)

	var entering_from_plant := (
		SaveManager.has_pending_scene_entry(SCENE_PATH)
		or get_tree().has_meta(BASEMENT_ENTRY_META)
	)

	if SaveManager.is_death_respawn():
		SaveManager.clear_death_respawn()
		call_deferred("_apply_death_respawn")
	elif entering_from_plant:
		SaveManager.consume_scene_entry(SCENE_PATH)
		hud.hide_menu()
		call_deferred("_apply_basement_entry")
	elif SaveManager.consume_pending_resume(SCENE_PATH):
		call_deferred("_apply_saved_resume")
	else:
		hud.show_start_screen("Plant Basement")


func _process(_delta: float) -> void:
	if _can_restart and Input.is_action_just_pressed("restart"):
		_on_restart_pressed()
		return

	_sync_exit_door_prompt()
	_sync_battery_switch_prompt()
	_sync_battery_guide_arrow()
	_check_player_fell_off_map()

	if _phase == GamePhase.PLAYING:
		SaveManager.track_position(SCENE_PATH, player.global_position, _delta)

	if player.should_camera_follow():
		_update_camera_follow()


func _sync_battery_guide_arrow() -> void:
	if GameState.is_emergency_battery_active():
		hud.hide_objective_indicator()
		return
	if _phase != GamePhase.PLAYING or hud.is_menu_visible():
		hud.hide_objective_indicator()
		return
	if player.global_position.y < HORIZONTAL_SECTION_Y:
		hud.hide_objective_indicator()
		return
	if _is_at_battery_switch():
		hud.hide_objective_indicator()
		return
	hud.show_objective_indicator(battery_switch, "BATTERY")


func _is_at_exit_door() -> bool:
	return exit_door.is_player_inside(player)


func _is_at_battery_switch() -> bool:
	return battery_switch.is_player_inside(player)


func _is_player_outside_map() -> bool:
	var pos := player.global_position
	return (
		pos.y > MAP_FALL_DEATH_Y
		or pos.x < -MAP_BOUND_MARGIN
		or pos.x > MAP_SIZE.x + MAP_BOUND_MARGIN
	)


func _check_player_fell_off_map() -> void:
	if _phase != GamePhase.PLAYING or player.is_dead or hud.is_menu_visible():
		return
	if not _is_player_outside_map():
		return
	player.die_from_void()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("interact"):
		return
	if _try_battery_switch():
		get_viewport().set_input_as_handled()
		return
	if _try_exit_to_plant():
		get_viewport().set_input_as_handled()


func _sync_exit_door_prompt() -> void:
	var at_door: bool = _is_at_exit_door()
	if at_door and _phase == GamePhase.PLAYING and not hud.is_menu_visible():
		if not _at_exit_door:
			_at_exit_door = true
			hud.show_interact_prompt("Press E to return to the plant")
	elif _at_exit_door:
		_at_exit_door = false
		if not _at_battery_switch:
			hud.hide_interact_prompt()


func _sync_battery_switch_prompt() -> void:
	if GameState.is_emergency_battery_active():
		if _at_battery_switch:
			_at_battery_switch = false
			if not _at_exit_door:
				hud.hide_interact_prompt()
		return

	var at_switch: bool = _is_at_battery_switch()
	if at_switch and _phase == GamePhase.PLAYING and not hud.is_menu_visible():
		if not _at_battery_switch:
			_at_battery_switch = true
			hud.show_interact_prompt("Press E to activate emergency battery")
	elif _at_battery_switch:
		_at_battery_switch = false
		if not _at_exit_door:
			hud.hide_interact_prompt()


func _try_battery_switch() -> bool:
	if GameState.is_emergency_battery_active():
		return false
	if not _is_at_battery_switch() or _phase != GamePhase.PLAYING:
		return false
	if hud.is_menu_visible():
		return false
	_activate_emergency_battery()
	return true


func _try_exit_to_plant() -> bool:
	if not _is_at_exit_door() or _phase != GamePhase.PLAYING:
		return false
	if hud.is_menu_visible():
		return false
	_exit_to_plant()
	return true


func _activate_emergency_battery() -> void:
	hud.hide_interact_prompt()
	hud.hide_objective_indicator()
	player.set_physics_process(false)
	player.velocity = Vector2.ZERO
	GameState.set_emergency_battery_active(true)
	if basement_visual.has_method("set_emergency_power"):
		basement_visual.call("set_emergency_power", true)
	AudioManager.play_electric_zap()
	hud.show_npc_dialogue(
		"Radio — Ashford Settlement",
		RADIO_PART_ONE,
		"Keep listening",
		_show_radio_part_two
	)


func _show_radio_part_two() -> void:
	hud.show_npc_dialogue(
		"Radio — Ashford Settlement",
		RADIO_PART_TWO,
		"Signal lost",
		_on_radio_broadcast_finished
	)


func _on_radio_broadcast_finished() -> void:
	GameState.mark_radio_broadcast_received()
	player.set_physics_process(true)
	_sync_battery_switch_prompt()


func _spawn_enemy_waves() -> void:
	if _waves_spawned:
		return
	_waves_spawned = true
	var tunnel_spawns: Array[Vector2] = [
		Vector2(720.0, 200.0),
		Vector2(360.0, 200.0),
		Vector2(700.0, 420.0),
		Vector2(700.0, 620.0),
		Vector2(1100.0, 620.0),
		Vector2(680.0, 820.0),
		Vector2(1100.0, 820.0),
		Vector2(850.0, 1020.0),
		Vector2(220.0, 1220.0),
		Vector2(1180.0, 1220.0),
		Vector2(380.0, 1420.0),
		Vector2(1020.0, 1420.0),
	]
	var base_spawns: Array[Vector2] = [
		Vector2(220.0, 1640.0),
		Vector2(1150.0, 1640.0),
		Vector2(1720.0, 1640.0),
		Vector2(2300.0, 1640.0),
		Vector2(2800.0, 1640.0),
	]
	for pos in tunnel_spawns:
		_spawn_single_enemy(pos)
	for pos in base_spawns:
		_spawn_single_enemy(pos)


func _spawn_single_enemy(spawn_position: Vector2) -> void:
	var enemy := _enemy_scene.instantiate() as CharacterBody2D
	enemies.add_child(enemy)
	_enemies_alive += 1
	enemy.defeated.connect(_on_enemy_defeated)
	if enemy.has_method("begin_emerge"):
		enemy.begin_emerge(spawn_position)
	else:
		enemy.global_position = spawn_position


func _on_enemy_defeated() -> void:
	_enemies_alive = maxi(_enemies_alive - 1, 0)


func _apply_basement_entry() -> void:
	get_tree().remove_meta(BASEMENT_ENTRY_META)
	player.global_position = BasementSpawn.basement_entry_spawn(exit_door)
	hud.hide_menu()
	player.set_physics_process(true)
	_phase = GamePhase.PLAYING
	await get_tree().process_frame
	_snap_camera_to_player()
	_spawn_enemy_waves()
	SaveManager.register_room_entry(SCENE_PATH, player.global_position)


func _apply_saved_resume() -> void:
	player.global_position = SaveManager.get_saved_position()
	if player.global_position == Vector2.ZERO:
		player.global_position = BasementSpawn.basement_entry_spawn(exit_door)
	SaveManager.apply_resume_spawn(player)
	hud.hide_menu()
	player.set_physics_process(true)
	_phase = GamePhase.PLAYING
	_snap_camera_to_player()
	if not _waves_spawned:
		_spawn_enemy_waves()


func _apply_death_respawn() -> void:
	_clear_enemies()
	_waves_spawned = false
	player.global_position = SaveManager.get_room_entry_position()
	if player.global_position == Vector2.ZERO:
		player.global_position = BasementSpawn.basement_entry_spawn(exit_door)
	SaveManager.apply_death_respawn(player)
	hud.hide_menu()
	player.set_physics_process(true)
	_phase = GamePhase.PLAYING
	_snap_camera_to_player()
	_spawn_enemy_waves()
	SaveManager.register_room_entry(SCENE_PATH, player.global_position)


func _clear_enemies() -> void:
	for child in enemies.get_children():
		enemies.remove_child(child)
		child.free()
	_enemies_alive = 0


func _exit_to_plant() -> void:
	hud.hide_interact_prompt()
	hud.hide_objective_indicator()
	get_tree().set_meta(RETURN_FROM_BASEMENT_META, true)
	get_tree().call_deferred("change_scene_to_file", POWER_PLANT_SCENE)


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
	_snap_camera_to_player(viewport_size, zoom_factor)


func _viewport_size() -> Vector2:
	return get_viewport().get_visible_rect().size


func _compute_camera_zoom(viewport_size: Vector2) -> float:
	if viewport_size.x <= 1.0 or viewport_size.y <= 1.0:
		return 0.35
	var base_zoom := minf(viewport_size.x / MAP_SIZE.x, viewport_size.y / MAP_SIZE.y)
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
	var target_y := clampf(player.global_position.y, half_view.y, MAP_SIZE.y - half_view.y)
	map_camera.position = Vector2(target_x, target_y)


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
	var target_y := clampf(player.global_position.y, half_view.y, MAP_SIZE.y - half_view.y)
	map_camera.position = Vector2(target_x, target_y)
	map_camera.make_current()


func _on_exit_door_entered() -> void:
	_sync_exit_door_prompt()


func _on_exit_door_exited() -> void:
	_sync_exit_door_prompt()


func _on_battery_switch_entered() -> void:
	_sync_battery_switch_prompt()


func _on_battery_switch_exited() -> void:
	_sync_battery_switch_prompt()


func _on_player_died() -> void:
	get_tree().paused = false
	SaveManager.handle_player_death()


func _on_play_pressed() -> void:
	_start_level_from_beginning()


func _start_level_from_beginning() -> void:
	hud.hide_menu()
	player.global_position = BasementSpawn.basement_entry_spawn(exit_door)
	player.set_physics_process(true)
	_phase = GamePhase.PLAYING
	_snap_camera_to_player()
	_spawn_enemy_waves()
	SaveManager.register_room_entry(SCENE_PATH, player.global_position)


func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
