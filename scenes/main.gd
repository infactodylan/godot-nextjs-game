extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var hud: CanvasLayer = $HUD
@onready var boss_gun: Node2D = $BossGun

var _can_restart := false


func _ready() -> void:
	hud.bind_player(player)
	hud.bind_boss(boss_gun)
	player.died.connect(_on_player_died)
	boss_gun.defeated.connect(_on_boss_defeated)


func _process(_delta: float) -> void:
	if _can_restart and Input.is_action_just_pressed("restart"):
		get_tree().reload_current_scene()


func _on_player_died() -> void:
	_can_restart = true


func _on_boss_defeated() -> void:
	_can_restart = true
