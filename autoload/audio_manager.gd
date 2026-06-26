extends Node

const MUSIC := preload("res://assets/audio/suspense_music.mp3")
const PLAYER_GUNSHOT := preload("res://assets/audio/player_gunshot.mp3")
const BOSS_GUNSHOT := preload("res://assets/audio/boss_gunshot.mp3")
const SQUISHY_DEATH := preload("res://assets/audio/squishy_death.mp3")
const PLAYER_RELOAD := preload("res://assets/audio/player_reload.mp3")

var _music_player: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_index := 0


func _ready() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.name = "MusicPlayer"
	_music_player.volume_db = -8.0
	add_child(_music_player)

	for i in 4:
		var player := AudioStreamPlayer.new()
		player.name = "SfxPlayer%d" % i
		player.volume_db = -2.0
		add_child(player)
		_sfx_players.append(player)


func play_music() -> void:
	if _music_player.playing:
		return

	var stream := MUSIC.duplicate() as AudioStreamMP3
	stream.loop = true
	_music_player.stream = stream
	_music_player.play()


func stop_music() -> void:
	_music_player.stop()


func play_player_shoot() -> void:
	_play_sfx(BOSS_GUNSHOT)


func play_boss_shoot() -> void:
	_play_sfx(PLAYER_GUNSHOT)


func play_enemy_death() -> void:
	_play_sfx(SQUISHY_DEATH)


func play_player_reload() -> void:
	_play_sfx(PLAYER_RELOAD)


func _play_sfx(stream: AudioStream) -> void:
	var player := _sfx_players[_sfx_index]
	_sfx_index = (_sfx_index + 1) % _sfx_players.size()
	player.stream = stream
	player.play()
