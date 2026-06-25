extends CanvasLayer

@onready var health_label: Label = $MarginContainer/VBoxContainer/HealthLabel
@onready var boss_label: Label = $MarginContainer/VBoxContainer/BossLabel
@onready var status_label: Label = $MarginContainer/VBoxContainer/StatusLabel


func _ready() -> void:
	boss_label.visible = false
	status_label.visible = false


func bind_player(player: CharacterBody2D) -> void:
	player.health_changed.connect(_on_player_health_changed)
	player.died.connect(_on_player_died)
	_on_player_health_changed(player.health, 4)


func bind_boss(boss: Node2D) -> void:
	boss.health_changed.connect(_on_boss_health_changed)
	boss.defeated.connect(_on_boss_defeated)
	boss_label.visible = true
	_on_boss_health_changed(boss.health, 20)


func show_restart_message(message: String) -> void:
	status_label.text = message
	status_label.visible = true


func _on_player_health_changed(current: int, maximum: int) -> void:
	health_label.text = "HP: %d/%d" % [current, maximum]


func _on_player_died() -> void:
	show_restart_message("Game Over — press R to restart")


func _on_boss_health_changed(current: int, maximum: int) -> void:
	boss_label.text = "Boss HP: %d/%d" % [current, maximum]


func _on_boss_defeated() -> void:
	boss_label.text = "Boss HP: 0/20"
	show_restart_message("Victory! — press R to restart")
