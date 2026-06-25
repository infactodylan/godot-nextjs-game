extends Node2D

enum GamePhase { PRE_START, WAVE1, SUPER_WEAPON_GRACE, WAVE2, BOSS_FIGHT }

const ENEMY_SPAWN_DELAY := 5.0
const SUPER_WEAPON_GRACE := 5.0
const SCREEN_SIZE_RATIO := 0.75
const MAP_SIZE := Vector2(3600.0, 900.0)
const PLATFORM_TOP_OFFSET := 12.0
const CAMERA_ZOOM_MULTIPLIER := 1.45

@onready var player: CharacterBody2D = $Player
@onready var map_camera: Camera2D = $MapCamera
@onready var hud: CanvasLayer = $HUD
@onready var boss_gun: Node2D = $BossGun
@onready var wave1: Node2D = $Enemies/Wave1
@onready var wave2: Node2D = $Enemies/Wave2
@onready var pickups: Node2D = $Pickups
@onready var super_weapon_platform: StaticBody2D = $Platforms/Platform10

var _ammo_pot_scene: PackedScene = preload("res://entities/ammo_pot/ammo_pot.tscn")
var _super_weapon_scene: PackedScene = preload("res://entities/super_weapon/super_weapon_pickup.tscn")

var _can_restart := false
var _phase := GamePhase.PRE_START
var _phase_timer := ENEMY_SPAWN_DELAY
var _wave1_alive := 0
var _wave2_alive := 0
var _active_ammo_pot: Area2D
var _active_super_weapon: Area2D


func _ready() -> void:
	_setup_window_size()
	_setup_map_camera()
	_prepare_wave(wave1)
	_prepare_wave(wave2)
	_disable_boss()
	AudioManager.play_music()

	hud.bind_player(player)
	hud.bind_boss(boss_gun)
	hud.start_countdown("Enemies spawn in")
	player.died.connect(_on_player_died)
	player.ammo_changed.connect(_on_player_ammo_changed)
	boss_gun.defeated.connect(_on_boss_defeated)


func _process(delta: float) -> void:
	if _can_restart and Input.is_action_just_pressed("restart"):
		get_tree().reload_current_scene()
		return

	match _phase:
		GamePhase.PRE_START:
			_phase_timer -= delta
			hud.update_countdown(_phase_timer)
			if _phase_timer <= 0.0:
				_start_wave1()
		GamePhase.SUPER_WEAPON_GRACE:
			_phase_timer -= delta
			hud.update_countdown(_phase_timer, "Fight the boss!")
			if _phase_timer <= 0.0:
				_finish_super_weapon_grace()

	if not player.is_dead:
		_update_camera_follow()


func _setup_window_size() -> void:
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
	var zoom_factor := base_zoom * CAMERA_ZOOM_MULTIPLIER
	map_camera.zoom = Vector2(zoom_factor, zoom_factor)
	map_camera.position = MAP_SIZE * 0.5


func _update_camera_follow() -> void:
	if player.is_dead:
		return

	var viewport_size := get_viewport().get_visible_rect().size
	var half_view := viewport_size / (2.0 * map_camera.zoom)
	var target_x := clampf(player.global_position.x, half_view.x, MAP_SIZE.x - half_view.x)
	map_camera.position = Vector2(target_x, MAP_SIZE.y * 0.5)


func _prepare_wave(wave_node: Node2D) -> void:
	for enemy in wave_node.get_children():
		enemy.visible = false
		enemy.process_mode = Node.PROCESS_MODE_DISABLED
		enemy.collision_layer = 0
		enemy.defeated.connect(_on_enemy_defeated.bind(wave_node))


func _disable_boss() -> void:
	boss_gun.set_process(false)


func _spawn_wave(wave_node: Node2D) -> int:
	var count := 0
	for enemy in wave_node.get_children():
		enemy.visible = true
		enemy.process_mode = Node.PROCESS_MODE_INHERIT
		enemy.collision_layer = 4
		count += 1
	return count


func _start_wave1() -> void:
	_phase = GamePhase.WAVE1
	hud.hide_countdown()
	_wave1_alive = _spawn_wave(wave1)


func _start_super_weapon_grace() -> void:
	_phase = GamePhase.SUPER_WEAPON_GRACE
	_phase_timer = SUPER_WEAPON_GRACE
	hud.start_countdown("Get the super weapon!")
	_spawn_super_weapon()


func _finish_super_weapon_grace() -> void:
	_despawn_super_weapon()
	hud.hide_countdown()
	_start_boss_fight()


func _start_wave2() -> void:
	_phase = GamePhase.WAVE2
	hud.show_wave_banner("Wave 2!")
	get_tree().create_timer(1.5).timeout.connect(hud.hide_countdown)
	_wave2_alive = _spawn_wave(wave2)
	boss_gun.set_process(true)


func _start_boss_fight() -> void:
	_phase = GamePhase.BOSS_FIGHT


func _on_enemy_defeated(wave_node: Node2D) -> void:
	if wave_node == wave1:
		_wave1_alive = max(_wave1_alive - 1, 0)
		if _wave1_alive == 0 and _phase == GamePhase.WAVE1:
			_start_wave2()
	elif wave_node == wave2:
		_wave2_alive = max(_wave2_alive - 1, 0)
		if _wave2_alive == 0 and _phase == GamePhase.WAVE2:
			_start_super_weapon_grace()


func _on_player_ammo_changed(current: int, _maximum: int) -> void:
	if current <= 2:
		_try_spawn_ammo_pot()


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


func _spawn_super_weapon() -> void:
	_despawn_super_weapon()
	var pickup := _super_weapon_scene.instantiate() as Area2D
	pickups.add_child(pickup)
	pickup.global_position = _platform_pickup_position(super_weapon_platform)
	pickup.collected.connect(_on_super_weapon_collected)
	_active_super_weapon = pickup


func _despawn_ammo_pot() -> void:
	if _active_ammo_pot and is_instance_valid(_active_ammo_pot):
		_active_ammo_pot.queue_free()
	_active_ammo_pot = null


func _despawn_super_weapon() -> void:
	if _active_super_weapon and is_instance_valid(_active_super_weapon):
		_active_super_weapon.queue_free()
	_active_super_weapon = null


func _on_ammo_pot_collected() -> void:
	_active_ammo_pot = null


func _on_super_weapon_collected() -> void:
	_active_super_weapon = null


func _get_available_platforms() -> Array[Node2D]:
	var platforms: Array[Node2D] = []
	for node in get_tree().get_nodes_in_group("platform"):
		if _active_super_weapon and is_instance_valid(_active_super_weapon):
			if node.global_position.distance_to(_active_super_weapon.global_position) < 40.0:
				continue
		platforms.append(node as Node2D)
	return platforms


func _platform_pickup_position(platform: Node2D) -> Vector2:
	return platform.global_position + Vector2(0.0, -PLATFORM_TOP_OFFSET)


func _on_player_died() -> void:
	_can_restart = true


func _on_boss_defeated() -> void:
	_can_restart = true
