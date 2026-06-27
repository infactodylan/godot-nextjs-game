extends Node2D

enum GamePhase { MENU, PLAYING }

const HEALTH_POTION_DURATION := 20.0
const SCREEN_SIZE_RATIO := 0.75
const MAP_SIZE := Vector2(7800.0, 900.0)
const PLATFORM_SURFACE_OFFSET := 8.0
const PLATFORM_TOP_OFFSET := PLATFORM_SURFACE_OFFSET
const CAMERA_ZOOM_MULTIPLIER := 4.29
const MAX_PLAY_AREA_VIEWPORT_HEIGHT_RATIO := 0.9
const WASTELANDS_SCENE := "res://scenes/waste_lands.tscn"
const DEATH_RESTART_META := "death_restart"

@onready var player: CharacterBody2D = $Player
@onready var map_camera: Camera2D = $MapCamera
@onready var village_background: Node2D = $VillageBackground
@onready var hud: CanvasLayer = $HUD
@onready var pickups: Node2D = $Pickups
@onready var super_weapon_platform: StaticBody2D = $Platforms/Platform5
@onready var wasteland_gate: Area2D = $WastelandGate

var _ammo_pot_scene: PackedScene = preload("res://entities/ammo_pot/ammo_pot.tscn")
var _health_potion_scene: PackedScene = preload("res://entities/health_potion/health_potion.tscn")
var _super_weapon_scene: PackedScene = preload("res://entities/super_weapon/super_weapon_pickup.tscn")

var _can_restart := false
var _phase := GamePhase.MENU
var _active_ammo_pot: Area2D
var _active_health_potion: Area2D
var _active_super_weapon: Area2D
var _health_potion_timer := 0.0
var _wasteland_prompt_open := false
var _wasteland_gate_armed := true


func _ready() -> void:
	_setup_window_size()
	_setup_map_camera()
	player.set_physics_process(false)
	AudioManager.play_village_ambience()

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

	if get_tree().has_meta(DEATH_RESTART_META):
		get_tree().remove_meta(DEATH_RESTART_META)
		call_deferred("_start_level_from_beginning")
	elif get_tree().has_meta("village_spawn_x"):
		_apply_entry_spawn()


func _process(delta: float) -> void:
	if _can_restart and Input.is_action_just_pressed("restart"):
		_on_restart_pressed()
		return

	_update_pickup_timers(delta)

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
	map_camera.zoom = Vector2(zoom_factor, zoom_factor)
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


func _spawn_super_weapon() -> void:
	_despawn_super_weapon()
	var pickup := _super_weapon_scene.instantiate() as Area2D
	pickups.add_child(pickup)
	pickup.global_position = _platform_pickup_position(super_weapon_platform)
	pickup.collected.connect(_on_super_weapon_collected)
	_active_super_weapon = pickup
	hud.show_boost_indicator(pickup, -1.0)


func _despawn_health_potion() -> void:
	if _active_health_potion and is_instance_valid(_active_health_potion):
		_active_health_potion.queue_free()
	_active_health_potion = null
	_health_potion_timer = 0.0
	hud.hide_health_indicator()


func _despawn_super_weapon() -> void:
	if _active_super_weapon and is_instance_valid(_active_super_weapon):
		_active_super_weapon.queue_free()
	_active_super_weapon = null
	hud.hide_boost_indicator()


func _on_ammo_pot_collected() -> void:
	_active_ammo_pot = null
	hud.hide_reload_indicator()


func _on_health_potion_collected() -> void:
	_active_health_potion = null
	_health_potion_timer = 0.0
	hud.hide_health_indicator()


func _on_super_weapon_collected() -> void:
	_active_super_weapon = null
	hud.hide_boost_indicator()


func _get_available_platforms() -> Array[Node2D]:
	var platforms: Array[Node2D] = []
	for node in get_tree().get_nodes_in_group("platform"):
		if _active_super_weapon and is_instance_valid(_active_super_weapon):
			if node.global_position.distance_to(_active_super_weapon.global_position) < 40.0:
				continue
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
	get_tree().set_meta(DEATH_RESTART_META, true)
	get_tree().call_deferred("reload_current_scene")


func _on_wasteland_gate_entered() -> void:
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
	get_tree().set_meta("wasteland_spawn_x", 250.0)
	get_tree().change_scene_to_file(WASTELANDS_SCENE)


func _apply_entry_spawn() -> void:
	if not get_tree().has_meta("village_spawn_x"):
		return
	player.global_position.x = get_tree().get_meta("village_spawn_x")
	player.global_position.y = 820.0
	get_tree().remove_meta("village_spawn_x")
	hud.hide_menu()
	player.set_physics_process(true)
	_phase = GamePhase.PLAYING


func _stay_in_village() -> void:
	_wasteland_prompt_open = false


func _on_wasteland_gate_exited() -> void:
	_wasteland_gate_armed = true
	_wasteland_prompt_open = false


func _on_play_pressed() -> void:
	_start_level_from_beginning()


func _start_level_from_beginning() -> void:
	hud.hide_menu()
	get_tree().paused = false
	player.set_physics_process(true)
	_phase = GamePhase.PLAYING
	_spawn_super_weapon()


func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
