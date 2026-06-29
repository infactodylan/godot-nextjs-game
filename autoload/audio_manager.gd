extends Node

const MUSIC := preload("res://assets/audio/suspense_music.mp3")
const VILLAGE_DISTANT_AMBIENCE := preload("res://assets/audio/village_distant_ambience.mp3")
const VILLAGE_EVENING_AMBIENCE := preload("res://assets/audio/village_evening_ambience.mp3")
const PLAYER_GUNSHOT := preload("res://assets/audio/player_gunshot.mp3")
const BOSS_GUNSHOT := preload("res://assets/audio/boss_gunshot.mp3")
const PLAYER_RELOAD := preload("res://assets/audio/player_reload.mp3")
const POWER_DOWN := preload("res://assets/audio/power_down.mp3")
const ELECTRIC_ZAP := preload("res://assets/audio/electric_zap.mp3")
const SUSPENSFUL_MOMENT := preload("res://assets/audio/suspensful_moment.mp3")
const BASEMENT_CAVE_MONSTER := preload("res://assets/audio/basement_cave_monster.mp3")
const BASEMENT_CAVE_WIND := preload("res://assets/audio/basement_cave_wind.mp3")
const BASEMENT_WATER_DRIP := preload("res://assets/audio/basement_water_drip.mp3")
const RADIO_STATIC := preload("res://assets/audio/radio_static.mp3")
const TRACTOR_AMBIENCE := preload("res://assets/audio/tractor_ambience.mp3")

const BASEMENT_WIND_DB := -12.0
const BASEMENT_DRIP_DB := -18.0
const RADIO_STATIC_DB := -10.0

const TRACTOR_FADE_SECONDS := 2.0
const TRACTOR_SILENT_DB := -80.0
const TRACTOR_QUIET_DB := -26.0
const TRACTOR_NEAR_DB := -8.0

const ZOMBIE_DEATHS: Array[AudioStream] = [
	preload("res://assets/audio/zombie_death_1.wav"),
	preload("res://assets/audio/zombie_death_2.wav"),
	preload("res://assets/audio/zombie_death_3.wav"),
]
const ZOMBIE_ROARS: Array[AudioStream] = [
	preload("res://assets/audio/zombie_roar_1.wav"),
	preload("res://assets/audio/zombie_roar_2.wav"),
	preload("res://assets/audio/zombie_roar_3.wav"),
]

var _music_player: AudioStreamPlayer
var _village_distant_player: AudioStreamPlayer
var _village_evening_player: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_index := 0
var _muted := false
var _tractor_player: AudioStreamPlayer
var _tractor_current_db := TRACTOR_SILENT_DB
var _tractor_player_near := false
var _basement_wind_player: AudioStreamPlayer
var _basement_drip_player: AudioStreamPlayer
var _radio_static_player: AudioStreamPlayer
var _basement_ambience_active := false
var _suspensful_moment_scene_id := -1


func _ready() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.name = "MusicPlayer"
	_music_player.volume_db = -8.0
	add_child(_music_player)

	_village_distant_player = AudioStreamPlayer.new()
	_village_distant_player.name = "VillageDistantAmbience"
	_village_distant_player.volume_db = -14.0
	add_child(_village_distant_player)

	_village_evening_player = AudioStreamPlayer.new()
	_village_evening_player.name = "VillageEveningAmbience"
	_village_evening_player.volume_db = -10.0
	add_child(_village_evening_player)

	for i in 4:
		var player := AudioStreamPlayer.new()
		player.name = "SfxPlayer%d" % i
		player.volume_db = -2.0
		add_child(player)
		_sfx_players.append(player)

	_tractor_player = AudioStreamPlayer.new()
	_tractor_player.name = "TractorAmbience"
	_tractor_player.volume_db = TRACTOR_SILENT_DB
	add_child(_tractor_player)

	_basement_wind_player = AudioStreamPlayer.new()
	_basement_wind_player.name = "BasementCaveWind"
	_basement_wind_player.volume_db = BASEMENT_WIND_DB
	add_child(_basement_wind_player)

	_basement_drip_player = AudioStreamPlayer.new()
	_basement_drip_player.name = "BasementWaterDrip"
	_basement_drip_player.volume_db = BASEMENT_DRIP_DB
	add_child(_basement_drip_player)

	_radio_static_player = AudioStreamPlayer.new()
	_radio_static_player.name = "RadioBroadcastStatic"
	_radio_static_player.volume_db = RADIO_STATIC_DB
	add_child(_radio_static_player)
	set_process(true)


func _get_tractor_target_db() -> float:
	if _basement_ambience_active:
		return TRACTOR_SILENT_DB
	if not _is_plant_ambience_enabled():
		return TRACTOR_SILENT_DB
	if _tractor_player_near:
		return TRACTOR_NEAR_DB
	return TRACTOR_QUIET_DB


func _is_plant_ambience_enabled() -> bool:
	return GameState.is_plant_power_on() or GameState.is_emergency_battery_active()


func _process(delta: float) -> void:
	var target_db := _get_tractor_target_db()
	var fade_speed := (TRACTOR_NEAR_DB - TRACTOR_SILENT_DB) / TRACTOR_FADE_SECONDS
	_tractor_current_db = move_toward(_tractor_current_db, target_db, fade_speed * delta)

	if _tractor_current_db > TRACTOR_SILENT_DB + 0.5:
		if not _tractor_player.playing:
			var stream := TRACTOR_AMBIENCE.duplicate() as AudioStreamMP3
			stream.loop = true
			_tractor_player.stream = stream
			_tractor_player.play()
		_tractor_player.volume_db = _tractor_current_db
	elif _tractor_player.playing:
		_tractor_player.stop()


func play_music() -> void:
	if _music_player.playing:
		return

	var stream := MUSIC.duplicate() as AudioStreamMP3
	stream.loop = true
	_music_player.stream = stream
	_music_player.play()


func stop_music() -> void:
	_music_player.stop()


func play_village_ambience() -> void:
	stop_music()
	if _village_distant_player.playing and _village_evening_player.playing:
		return

	var distant := VILLAGE_DISTANT_AMBIENCE.duplicate() as AudioStreamMP3
	distant.loop = true
	_village_distant_player.stream = distant
	_village_distant_player.play()

	var evening := VILLAGE_EVENING_AMBIENCE.duplicate() as AudioStreamMP3
	evening.loop = true
	_village_evening_player.stream = evening
	_village_evening_player.play()


func stop_village_ambience() -> void:
	_village_distant_player.stop()
	_village_evening_player.stop()


func play_basement_ambience() -> void:
	stop_village_ambience()
	_basement_ambience_active = true
	_tractor_player_near = false
	if not _basement_wind_player.playing:
		var wind := BASEMENT_CAVE_WIND.duplicate() as AudioStreamMP3
		wind.loop = true
		_basement_wind_player.stream = wind
		_basement_wind_player.play()
	if not _basement_drip_player.playing:
		var drip := BASEMENT_WATER_DRIP.duplicate() as AudioStreamMP3
		drip.loop = true
		_basement_drip_player.stream = drip
		_basement_drip_player.play()


func stop_basement_ambience() -> void:
	_basement_ambience_active = false
	_basement_wind_player.stop()
	_basement_drip_player.stop()
	stop_radio_broadcast()


func start_radio_broadcast() -> void:
	if _radio_static_player.playing:
		return
	var stream := RADIO_STATIC.duplicate() as AudioStreamMP3
	stream.loop = true
	_radio_static_player.stream = stream
	_radio_static_player.play()


func stop_radio_broadcast() -> void:
	_radio_static_player.stop()


func play_radio_static() -> void:
	start_radio_broadcast()


func set_muted(muted: bool) -> void:
	_muted = muted
	AudioServer.set_bus_mute(0, muted)


func is_muted() -> bool:
	return _muted


func toggle_muted() -> bool:
	set_muted(not _muted)
	return _muted


func play_player_shoot() -> void:
	_play_sfx(BOSS_GUNSHOT)


func play_boss_shoot() -> void:
	_play_sfx(PLAYER_GUNSHOT)


func play_enemy_death() -> void:
	_play_sfx(ZOMBIE_DEATHS[randi() % ZOMBIE_DEATHS.size()])


func play_enemy_roar() -> void:
	_play_sfx(ZOMBIE_ROARS[randi() % ZOMBIE_ROARS.size()])


func play_player_reload() -> void:
	_play_sfx(PLAYER_RELOAD)


func play_power_down() -> void:
	_play_sfx(POWER_DOWN)


func play_electric_zap() -> void:
	_play_sfx(ELECTRIC_ZAP)


func play_basement_cave_monster() -> void:
	_play_sfx(BASEMENT_CAVE_MONSTER)


func play_suspensful_moment() -> void:
	_play_sfx(SUSPENSFUL_MOMENT)


func try_play_suspensful_moment_for_map() -> bool:
	if not _player_can_perceive_enemies():
		return false
	var scene := get_tree().current_scene
	if scene == null:
		return false
	var scene_id := scene.get_instance_id()
	if scene_id == _suspensful_moment_scene_id:
		return false
	_suspensful_moment_scene_id = scene_id
	play_suspensful_moment()
	return true


func _player_can_perceive_enemies() -> bool:
	if get_tree().paused:
		return false
	var player := get_tree().get_first_node_in_group("player") as CharacterBody2D
	if player == null or not is_instance_valid(player):
		return false
	if player.is_dead:
		return false
	if not player.is_physics_processing():
		return false
	return true


func set_tractor_ambience_power_on(on: bool) -> void:
	GameState.set_plant_power_on(on)


func is_plant_power_on() -> bool:
	return GameState.is_plant_power_on()


func set_tractor_ambience_near(near: bool) -> void:
	_tractor_player_near = near


func reset_tractor_ambience() -> void:
	_tractor_player_near = false
	_tractor_current_db = TRACTOR_SILENT_DB
	_tractor_player.stop()


func _play_sfx(stream: AudioStream) -> void:
	var player := _sfx_players[_sfx_index]
	_sfx_index = (_sfx_index + 1) % _sfx_players.size()
	player.stream = stream
	player.play()
