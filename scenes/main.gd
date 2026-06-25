extends Node2D

const ENEMY_SPAWN_DELAY := 5.0
const SCREEN_SIZE_RATIO := 0.75
const MAP_SIZE := Vector2(2400.0, 900.0)

@onready var player: CharacterBody2D = $Player
@onready var map_camera: Camera2D = $MapCamera
@onready var hud: CanvasLayer = $HUD
@onready var boss_gun: Node2D = $BossGun
@onready var enemies: Node2D = $Enemies

var _can_restart := false
var _enemies_active := false
var _spawn_countdown := ENEMY_SPAWN_DELAY


func _ready() -> void:
	_setup_window_size()
	_setup_map_camera()
	_prepare_enemies()
	_disable_boss()
	AudioManager.play_music()

	hud.bind_player(player)
	hud.bind_boss(boss_gun)
	hud.start_spawn_countdown(ENEMY_SPAWN_DELAY)
	player.died.connect(_on_player_died)
	boss_gun.defeated.connect(_on_boss_defeated)


func _process(delta: float) -> void:
	if _can_restart and Input.is_action_just_pressed("restart"):
		get_tree().reload_current_scene()
		return

	if _enemies_active:
		return

	_spawn_countdown -= delta
	hud.update_spawn_countdown(_spawn_countdown)

	if _spawn_countdown <= 0.0:
		_spawn_all_enemies()


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
	var zoom_factor := minf(
		viewport_size.x / MAP_SIZE.x,
		viewport_size.y / MAP_SIZE.y
	)
	map_camera.zoom = Vector2(zoom_factor, zoom_factor)
	map_camera.position = MAP_SIZE * 0.5


func _prepare_enemies() -> void:
	for enemy in enemies.get_children():
		enemy.visible = false
		enemy.process_mode = Node.PROCESS_MODE_DISABLED
		enemy.collision_layer = 0


func _disable_boss() -> void:
	boss_gun.set_process(false)


func _spawn_all_enemies() -> void:
	_enemies_active = true
	hud.hide_spawn_countdown()

	for enemy in enemies.get_children():
		enemy.visible = true
		enemy.process_mode = Node.PROCESS_MODE_INHERIT
		enemy.collision_layer = 4

	boss_gun.set_process(true)


func _on_player_died() -> void:
	_can_restart = true


func _on_boss_defeated() -> void:
	_can_restart = true
