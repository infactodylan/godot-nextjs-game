extends CanvasLayer

signal play_pressed
signal restart_pressed

const RELOAD_COLOR := Color(0.95, 0.12, 0.12, 1.0)
const HEALTH_COLOR := Color(0.2, 0.95, 0.35, 1.0)
const BOOST_COLOR := Color(0.82, 0.45, 1.0, 1.0)
const RESUME_COUNTDOWN := 5.0

@onready var health_label: Label = $MarginContainer/VBoxContainer/HealthLabel
@onready var ammo_label: Label = $MarginContainer/VBoxContainer/AmmoLabel
@onready var super_label: Label = $MarginContainer/VBoxContainer/SuperLabel
@onready var boss_label: Label = $MarginContainer/VBoxContainer/BossLabel
@onready var wave_label: Label = $MarginContainer/VBoxContainer/WaveLabel
@onready var status_label: Label = $MarginContainer/VBoxContainer/StatusLabel
@onready var countdown_label: Label = $CountdownCenter/CountdownVBox/CountdownLabel
@onready var countdown_subtitle: Label = $CountdownCenter/CountdownVBox/CountdownSubtitle
@onready var pickup_banner: PanelContainer = $PickupBanner
@onready var reload_banner_row: HBoxContainer = $PickupBanner/BannerMargin/BannerVBox/ReloadRow
@onready var reload_banner_label: Label = $PickupBanner/BannerMargin/BannerVBox/ReloadRow/ReloadText
@onready var reload_timer_label: Label = $PickupBanner/BannerMargin/BannerVBox/ReloadRow/ReloadTimer
@onready var health_banner_row: HBoxContainer = $PickupBanner/BannerMargin/BannerVBox/HealthRow
@onready var health_banner_label: Label = $PickupBanner/BannerMargin/BannerVBox/HealthRow/HealthText
@onready var health_timer_label: Label = $PickupBanner/BannerMargin/BannerVBox/HealthRow/HealthTimer
@onready var boost_banner_row: HBoxContainer = $PickupBanner/BannerMargin/BannerVBox/BoostRow
@onready var boost_banner_label: Label = $PickupBanner/BannerMargin/BannerVBox/BoostRow/BoostText
@onready var boost_timer_label: Label = $PickupBanner/BannerMargin/BannerVBox/BoostRow/BoostTimer
@onready var reload_arrow: Control = $PickupGuides/ReloadArrow
@onready var health_arrow: Control = $PickupGuides/HealthArrow
@onready var boost_arrow: Control = $PickupGuides/BoostArrow
@onready var pause_button: Button = $TopRightControls/PauseButton
@onready var mute_button: Button = $TopRightControls/MuteButton
@onready var pause_overlay: ColorRect = $PauseOverlay
@onready var menu_overlay: ColorRect = $MenuOverlay
@onready var menu_title: Label = $MenuOverlay/MenuCenter/MenuVBox/MenuTitle
@onready var menu_message: Label = $MenuOverlay/MenuCenter/MenuVBox/MenuMessage
@onready var menu_button: Button = $MenuOverlay/MenuCenter/MenuVBox/MenuButton

var _camera: Camera2D
var _player: CharacterBody2D
var _reload_target: Node2D
var _health_target: Node2D
var _boost_target: Node2D
var _reload_time_left := 0.0
var _health_time_left := 0.0
var _boost_time_left := 0.0
var _resume_countdown_active := false
var _resume_countdown_left := 0.0
var _needs_resume_countdown: Callable
var _restore_pre_start_countdown: Callable


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	$CountdownCenter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$MarginContainer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_label.visible = false
	wave_label.visible = false
	status_label.visible = false
	super_label.visible = false
	countdown_label.visible = false
	countdown_subtitle.visible = false
	pickup_banner.visible = false
	reload_banner_row.visible = false
	health_banner_row.visible = false
	boost_banner_row.visible = false
	pause_overlay.visible = false
	menu_overlay.visible = false
	pause_button.pressed.connect(_on_pause_pressed)
	mute_button.pressed.connect(_on_mute_pressed)
	menu_button.pressed.connect(_on_menu_button_pressed)
	_disable_button_keyboard_focus()
	show_start_screen()


func bind_camera(camera: Camera2D) -> void:
	_camera = camera


func configure_resume_countdown(
	needs_countdown: Callable,
	restore_countdown: Callable
) -> void:
	_needs_resume_countdown = needs_countdown
	_restore_pre_start_countdown = restore_countdown


func bind_player(player: CharacterBody2D) -> void:
	_player = player
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


func show_reload_indicator(target: Node2D, duration: float) -> void:
	_reload_target = target
	_reload_time_left = duration
	reload_banner_row.visible = true
	reload_banner_label.text = "RELOAD AVAILABLE — GET AMMO"
	_update_reload_timer_label()
	_refresh_pickup_banner()
	if _camera:
		reload_arrow.activate(target, _camera, RELOAD_COLOR, _player)


func update_reload_timer(seconds_left: float) -> void:
	_reload_time_left = seconds_left
	_update_reload_timer_label()


func hide_reload_indicator() -> void:
	_reload_target = null
	_reload_time_left = 0.0
	reload_banner_row.visible = false
	reload_arrow.deactivate()
	_refresh_pickup_banner()


func show_health_indicator(target: Node2D, duration: float) -> void:
	_health_target = target
	_health_time_left = duration
	health_banner_row.visible = true
	health_banner_label.text = "HEALTH POTION — GET HEALING"
	_update_health_timer_label()
	_refresh_pickup_banner()
	if _camera:
		health_arrow.activate(target, _camera, HEALTH_COLOR, _player)


func update_health_timer(seconds_left: float) -> void:
	_health_time_left = seconds_left
	_update_health_timer_label()


func hide_health_indicator() -> void:
	_health_target = null
	_health_time_left = 0.0
	health_banner_row.visible = false
	health_arrow.deactivate()
	_refresh_pickup_banner()


func show_boost_indicator(target: Node2D, duration: float) -> void:
	_boost_target = target
	_boost_time_left = duration
	boost_banner_row.visible = true
	boost_banner_label.text = "SUPER WEAPON BOOST — GRAB IT NOW"
	_update_boost_timer_label()
	_refresh_pickup_banner()
	if _camera:
		boost_arrow.activate(target, _camera, BOOST_COLOR, _player)


func update_boost_timer(seconds_left: float) -> void:
	_boost_time_left = seconds_left
	_update_boost_timer_label()


func hide_boost_indicator() -> void:
	_boost_target = null
	_boost_time_left = 0.0
	boost_banner_row.visible = false
	boost_arrow.deactivate()
	_refresh_pickup_banner()


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


func update_wave_status(wave_number: int, remaining: int, total: int) -> void:
	wave_label.text = "Wave %d — Enemies: %d/%d" % [wave_number, remaining, total]
	wave_label.visible = true


func hide_wave_status() -> void:
	wave_label.visible = false


func show_wave_banner(text: String) -> void:
	countdown_subtitle.text = text
	countdown_label.text = ""
	countdown_subtitle.visible = true
	countdown_label.visible = true


func show_start_screen() -> void:
	menu_title.text = "New Game Project"
	menu_message.visible = false
	menu_button.text = "Play"
	menu_overlay.visible = true


func show_game_over() -> void:
	hide_reload_indicator()
	hide_health_indicator()
	hide_boost_indicator()
	hide_countdown()
	hide_wave_status()
	get_tree().paused = true
	pause_overlay.visible = false
	pause_button.text = "Pause"
	menu_title.text = "You Died"
	menu_message.text = "Better luck next time."
	menu_message.visible = true
	menu_button.text = "Restart"
	menu_overlay.visible = true


func show_victory() -> void:
	hide_countdown()
	hide_wave_status()
	get_tree().paused = true
	pause_overlay.visible = false
	pause_button.text = "Pause"
	menu_title.text = "You Won!"
	menu_message.text = "The boss has been defeated."
	menu_message.visible = true
	menu_button.text = "Restart"
	menu_overlay.visible = true


func hide_menu() -> void:
	menu_overlay.visible = false
	get_tree().paused = false
	get_viewport().gui_release_focus()


func is_menu_visible() -> bool:
	return menu_overlay.visible


func show_restart_message(message: String) -> void:
	status_label.text = message
	status_label.visible = true


func _unhandled_input(event: InputEvent) -> void:
	if is_menu_visible() or _resume_countdown_active:
		return
	if event.is_action_pressed("pause"):
		_toggle_pause()


func _on_pause_pressed() -> void:
	_toggle_pause()


func _on_mute_pressed() -> void:
	var muted := AudioManager.toggle_muted()
	mute_button.text = "Unmute" if muted else "Mute"


func _toggle_pause() -> void:
	if is_menu_visible() or _resume_countdown_active:
		return

	if get_tree().paused:
		if _needs_resume_countdown.is_valid() and _needs_resume_countdown.call():
			_start_resume_countdown()
		else:
			_apply_unpause()
	else:
		get_tree().paused = true
		pause_overlay.visible = true
		pause_button.text = "Resume"
		get_viewport().gui_release_focus()


func _start_resume_countdown() -> void:
	_resume_countdown_active = true
	_resume_countdown_left = RESUME_COUNTDOWN
	pause_overlay.visible = false
	pause_button.text = "Pause"
	start_countdown("Get ready")
	update_countdown(_resume_countdown_left)
	get_viewport().gui_release_focus()


func _apply_unpause() -> void:
	get_tree().paused = false
	pause_overlay.visible = false
	pause_button.text = "Pause"
	get_viewport().gui_release_focus()


func _finish_resume_countdown() -> void:
	_resume_countdown_active = false
	_apply_unpause()
	if _restore_pre_start_countdown.is_valid():
		_restore_pre_start_countdown.call()
	else:
		hide_countdown()


func _disable_button_keyboard_focus() -> void:
	for button in [pause_button, mute_button, menu_button]:
		button.focus_mode = Control.FOCUS_NONE


func _on_menu_button_pressed() -> void:
	if menu_button.text == "Play":
		play_pressed.emit()
	else:
		restart_pressed.emit()


func _update_reload_timer_label() -> void:
	reload_timer_label.text = "%ds" % maxi(ceili(_reload_time_left), 0)


func _update_health_timer_label() -> void:
	health_timer_label.text = "%ds" % maxi(ceili(_health_time_left), 0)


func _update_boost_timer_label() -> void:
	boost_timer_label.text = "%ds" % maxi(ceili(_boost_time_left), 0)


func _refresh_pickup_banner() -> void:
	pickup_banner.visible = (
		reload_banner_row.visible
		or health_banner_row.visible
		or boost_banner_row.visible
	)


func _process(delta: float) -> void:
	if _resume_countdown_active:
		_resume_countdown_left -= delta
		update_countdown(_resume_countdown_left)
		if _resume_countdown_left <= 0.0:
			_finish_resume_countdown()
		return

	if _reload_target and is_instance_valid(_reload_target) and _camera and _player:
		if not reload_arrow.visible:
			reload_arrow.activate(_reload_target, _camera, RELOAD_COLOR, _player)
	elif reload_arrow.visible:
		reload_arrow.deactivate()

	if _health_target and is_instance_valid(_health_target) and _camera and _player:
		if not health_arrow.visible:
			health_arrow.activate(_health_target, _camera, HEALTH_COLOR, _player)
	elif health_arrow.visible:
		health_arrow.deactivate()


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
	pass


func _on_boss_health_changed(current: int, maximum: int) -> void:
	boss_label.text = "Boss HP: %d/%d" % [current, maximum]


func _on_boss_defeated() -> void:
	boss_label.text = "Boss HP: 0/20"
