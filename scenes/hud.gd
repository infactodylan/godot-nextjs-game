extends CanvasLayer

@onready var health_label: Label = $MarginContainer/VBoxContainer/HealthLabel
@onready var ammo_label: Label = $MarginContainer/VBoxContainer/AmmoLabel
@onready var super_label: Label = $MarginContainer/VBoxContainer/SuperLabel
@onready var boss_label: Label = $MarginContainer/VBoxContainer/BossLabel
@onready var status_label: Label = $MarginContainer/VBoxContainer/StatusLabel
@onready var countdown_label: Label = $CountdownCenter/CountdownVBox/CountdownLabel
@onready var countdown_subtitle: Label = $CountdownCenter/CountdownVBox/CountdownSubtitle


func _ready() -> void:
	boss_label.visible = false
	status_label.visible = false
	super_label.visible = false
	countdown_label.visible = false
	countdown_subtitle.visible = false


func bind_player(player: CharacterBody2D) -> void:
	player.health_changed.connect(_on_player_health_changed)
	player.ammo_changed.connect(_on_player_ammo_changed)
	player.super_weapon_changed.connect(_on_super_weapon_changed)
	player.died.connect(_on_player_died)
	_on_player_health_changed(player.health, 4)
	_on_player_ammo_changed(player.ammo, 6)


func bind_boss(boss: Node2D) -> void:
	boss.health_changed.connect(_on_boss_health_changed)
	boss.defeated.connect(_on_boss_defeated)
	boss_label.visible = true
	_on_boss_health_changed(boss.health, 20)


func start_countdown(subtitle: String) -> void:
	countdown_label.visible = true
	countdown_subtitle.visible = true
	countdown_subtitle.text = subtitle


func update_countdown(seconds_remaining: float, go_text: String = "GO!") -> void:
	if seconds_remaining > 0.0:
		countdown_label.text = str(maxi(ceili(seconds_remaining), 1))
	else:
		countdown_label.text = go_text


func hide_countdown() -> void:
	countdown_label.visible = false
	countdown_subtitle.visible = false


func show_wave_banner(text: String) -> void:
	countdown_subtitle.text = text
	countdown_label.text = ""
	countdown_subtitle.visible = true
	countdown_label.visible = true


func show_restart_message(message: String) -> void:
	status_label.text = message
	status_label.visible = true


func _on_player_health_changed(current: int, maximum: int) -> void:
	health_label.text = "HP: %d/%d" % [current, maximum]


func _on_player_ammo_changed(current: int, maximum: int) -> void:
	ammo_label.text = "Ammo: %d/%d" % [current, maximum]


func _on_super_weapon_changed(active: bool, seconds_left: float) -> void:
	if active:
		super_label.visible = true
		super_label.text = "SUPER: %ds" % maxi(ceili(seconds_left), 0)
	else:
		super_label.visible = false


func _on_player_died() -> void:
	show_restart_message("Game Over — press R to restart")


func _on_boss_health_changed(current: int, maximum: int) -> void:
	boss_label.text = "Boss HP: %d/%d" % [current, maximum]


func _on_boss_defeated() -> void:
	boss_label.text = "Boss HP: 0/20"
	show_restart_message("Victory! — press R to restart")
