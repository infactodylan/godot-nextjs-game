extends Node2D

enum GamePhase { MENU, PRE_START, WAVE1, SUPER_WEAPON_GRACE, WAVE2, BOSS_FIGHT }

const ENEMY_SPAWN_DELAY := 5.0
const SUPER_WEAPON_GRACE := 105.0
const WAVE1_ENEMY_COUNT := 12
const WAVE2_ENEMY_COUNT := 18
const AMMO_POT_DURATION := 20.0
const HEALTH_POTION_DURATION := 20.0
const SCREEN_SIZE_RATIO := 0.75
const MAP_SIZE := Vector2(3600.0, 900.0)
const ENEMY_SPAWN_X := MAP_SIZE.x - 30.0
const ENEMY_SPAWN_GROUND_Y := 820.0
const ENEMY_SPAWN_INTERVAL := 0.45
const PLATFORM_SURFACE_OFFSET := 8.0
const PLATFORM_TOP_OFFSET := PLATFORM_SURFACE_OFFSET
const CAMERA_ZOOM_MULTIPLIER := 3.3
const MAX_PLAY_AREA_VIEWPORT_HEIGHT_RATIO := 0.9

@onready var player: CharacterBody2D = $Player
@onready var map_camera: Camera2D = $MapCamera
@onready var hud: CanvasLayer = $HUD
@onready var boss_gun: Node2D = $BossGun
@onready var wave1: Node2D = $Enemies/Wave1
@onready var wave2: Node2D = $Enemies/Wave2
@onready var pickups: Node2D = $Pickups
@onready var super_weapon_platform: StaticBody2D = $Platforms/Platform5

var _ammo_pot_scene: PackedScene = preload("res://entities/ammo_pot/ammo_pot.tscn")
var _health_potion_scene: PackedScene = preload("res://entities/health_potion/health_potion.tscn")
var _super_weapon_scene: PackedScene = preload("res://entities/super_weapon/super_weapon_pickup.tscn")
var _enemy_scene: PackedScene = preload("res://entities/enemy/enemy.tscn")

var _can_restart := false
var _phase := GamePhase.MENU
var _wave1_alive := 0
var _wave2_alive := 0
var _active_ammo_pot: Area2D
var _active_health_potion: Area2D
var _active_super_weapon: Area2D
var _ammo_pot_timer := 0.0
var _health_potion_timer := 0.0
var _grace_leads_to_wave2 := true
var _super_weapon_subtitle := "Get the super weapon!"
var _phase_timer := ENEMY_SPAWN_DELAY


func _ready() -> void:
	_setup_window_size()
	_setup_map_camera()
	_disable_boss()
	player.set_physics_process(false)
	AudioManager.play_music()

	hud.bind_player(player)
	hud.bind_boss(boss_gun)
	hud.bind_camera(map_camera)
	hud.configure_resume_countdown(
		func() -> bool: return _phase == GamePhase.PRE_START,
		_restore_pre_start_countdown
	)
	hud.play_pressed.connect(_on_play_pressed)
	hud.restart_pressed.connect(_on_restart_pressed)
	player.died.connect(_on_player_died)
	player.ammo_changed.connect(_on_player_ammo_changed)
	player.health_changed.connect(_on_player_health_changed)
	boss_gun.defeated.connect(_on_boss_defeated)


func _process(delta: float) -> void:
	if _can_restart and Input.is_action_just_pressed("restart"):
		_on_restart_pressed()
		return

	match _phase:
		GamePhase.MENU:
			pass
		GamePhase.PRE_START:
			_phase_timer -= delta
			hud.update_countdown(_phase_timer)
			if _phase_timer <= 0.0:
				_start_wave1()
		GamePhase.SUPER_WEAPON_GRACE:
			_phase_timer -= delta
			hud.update_countdown(_phase_timer, _super_weapon_subtitle)
			hud.update_boost_timer(_phase_timer)
			if _phase_timer <= 0.0:
				_finish_super_weapon_grace()

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
	map_camera.position = player.global_position


func _update_camera_follow() -> void:
	if not player.should_camera_follow():
		return

	var viewport_size := get_viewport().get_visible_rect().size
	var half_view := viewport_size / (2.0 * map_camera.zoom)
	var target_x := clampf(player.global_position.x, half_view.x, MAP_SIZE.x - half_view.x)
	var target_y := clampf(player.global_position.y, half_view.y, MAP_SIZE.y - half_view.y)
	map_camera.position = Vector2(target_x, target_y)


func _spawn_wave(wave_node: Node2D, enemy_count: int, wave_number: int) -> void:
	_clear_wave(wave_node)
	hud.update_wave_status(wave_number, enemy_count, enemy_count)
	for i in enemy_count:
		if wave_number == 1 and _phase != GamePhase.WAVE1:
			return
		if wave_number == 2 and _phase != GamePhase.WAVE2:
			return
		_spawn_single_enemy(wave_node, i)
		if i < enemy_count - 1:
			await get_tree().create_timer(ENEMY_SPAWN_INTERVAL).timeout


func _clear_wave(wave_node: Node2D) -> void:
	for child in wave_node.get_children():
		wave_node.remove_child(child)
		child.free()


func _spawn_single_enemy(wave_node: Node2D, index: int) -> void:
	var enemy := _enemy_scene.instantiate() as CharacterBody2D
	wave_node.add_child(enemy)
	enemy.global_position = Vector2(
		ENEMY_SPAWN_X - (index % 3) * 24.0,
		ENEMY_SPAWN_GROUND_Y
	)
	enemy.defeated.connect(_on_enemy_defeated.bind(wave_node))


func _start_wave1() -> void:
	_phase = GamePhase.WAVE1
	hud.hide_countdown()
	_wave1_alive = WAVE1_ENEMY_COUNT
	_spawn_wave(wave1, WAVE1_ENEMY_COUNT, 1)


func _update_pickup_timers(delta: float) -> void:
	if _active_ammo_pot and is_instance_valid(_active_ammo_pot):
		_ammo_pot_timer -= delta
		hud.update_reload_timer(_ammo_pot_timer)
		if _ammo_pot_timer <= 0.0:
			_despawn_ammo_pot()

	if _active_health_potion and is_instance_valid(_active_health_potion):
		_health_potion_timer -= delta
		hud.update_health_timer(_health_potion_timer)
		if _health_potion_timer <= 0.0:
			_despawn_health_potion()


func _disable_boss() -> void:
	boss_gun.set_process(false)


func _enable_boss() -> void:
	boss_gun.activate()


func _start_super_weapon_grace(leads_to_wave2: bool) -> void:
	_phase = GamePhase.SUPER_WEAPON_GRACE
	hud.hide_wave_status()
	_phase_timer = SUPER_WEAPON_GRACE
	_grace_leads_to_wave2 = leads_to_wave2
	_super_weapon_subtitle = "Wave 2 incoming!" if leads_to_wave2 else "Boss incoming!"
	hud.start_countdown("Get the super weapon!")
	_spawn_super_weapon()


func _finish_super_weapon_grace() -> void:
	_despawn_super_weapon()
	hud.hide_boost_indicator()
	hud.hide_countdown()
	if _grace_leads_to_wave2:
		_start_wave2()
	else:
		_start_boss_fight()


func _start_wave2() -> void:
	_phase = GamePhase.WAVE2
	hud.show_wave_banner("Wave 2!")
	get_tree().create_timer(1.5).timeout.connect(hud.hide_countdown)
	_wave2_alive = WAVE2_ENEMY_COUNT
	_spawn_wave(wave2, WAVE2_ENEMY_COUNT, 2)


func _start_boss_fight() -> void:
	_phase = GamePhase.BOSS_FIGHT
	_enable_boss()


func _on_enemy_defeated(wave_node: Node2D) -> void:
	if wave_node == wave1:
		_wave1_alive = max(_wave1_alive - 1, 0)
		hud.update_wave_status(1, _wave1_alive, WAVE1_ENEMY_COUNT)
		if _wave1_alive == 0 and _phase == GamePhase.WAVE1:
			_enable_boss()
			_start_super_weapon_grace(true)
	elif wave_node == wave2:
		_wave2_alive = max(_wave2_alive - 1, 0)
		hud.update_wave_status(2, _wave2_alive, WAVE2_ENEMY_COUNT)
		if _wave2_alive == 0 and _phase == GamePhase.WAVE2:
			hud.hide_countdown()
			_start_super_weapon_grace(false)


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
	_despawn_ammo_pot()
	var pot := _ammo_pot_scene.instantiate() as Area2D
	pickups.add_child(pot)
	pot.global_position = _platform_pickup_position(platform)
	pot.collected.connect(_on_ammo_pot_collected)
	_active_ammo_pot = pot
	_ammo_pot_timer = AMMO_POT_DURATION
	hud.show_reload_indicator(pot, _ammo_pot_timer)


func _spawn_super_weapon() -> void:
	_despawn_super_weapon()
	var pickup := _super_weapon_scene.instantiate() as Area2D
	pickups.add_child(pickup)
	pickup.global_position = _platform_pickup_position(super_weapon_platform)
	pickup.collected.connect(_on_super_weapon_collected)
	_active_super_weapon = pickup
	hud.show_boost_indicator(pickup, SUPER_WEAPON_GRACE)


func _despawn_ammo_pot() -> void:
	if _active_ammo_pot and is_instance_valid(_active_ammo_pot):
		_active_ammo_pot.queue_free()
	_active_ammo_pot = null
	_ammo_pot_timer = 0.0
	hud.hide_reload_indicator()


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
	_ammo_pot_timer = 0.0
	hud.hide_reload_indicator()


func _on_health_potion_collected() -> void:
	_active_health_potion = null
	_health_potion_timer = 0.0
	hud.hide_health_indicator()


func _on_super_weapon_collected() -> void:
	_active_super_weapon = null
	hud.hide_boost_indicator()
	if _phase == GamePhase.SUPER_WEAPON_GRACE:
		_finish_super_weapon_grace()


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
	return platform.global_position + Vector2(0.0, -PLATFORM_TOP_OFFSET)


func _on_player_died() -> void:
	_can_restart = true
	hud.show_game_over()


func _on_boss_defeated() -> void:
	_can_restart = true
	hud.show_victory()


func _restore_pre_start_countdown() -> void:
	hud.start_countdown("Enemies spawn in")
	hud.update_countdown(_phase_timer)


func _on_get_ready_finished() -> void:
	get_tree().paused = false
	player.set_physics_process(true)
	_phase = GamePhase.PRE_START
	_phase_timer = ENEMY_SPAWN_DELAY
	hud.start_countdown("Enemies spawn in")
	hud.update_countdown(_phase_timer)


func _on_play_pressed() -> void:
	hud.hide_menu()
	player.set_physics_process(false)
	hud.start_get_ready_countdown(_on_get_ready_finished)


func _on_restart_pressed() -> void:
	get_tree().reload_current_scene()
