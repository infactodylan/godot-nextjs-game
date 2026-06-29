extends CanvasLayer

signal play_pressed
signal restart_pressed

const RELOAD_COLOR := Color(0.95, 0.12, 0.12, 1.0)
const HEALTH_COLOR := Color(0.2, 0.95, 0.35, 1.0)
const BOOST_COLOR := Color(0.82, 0.45, 1.0, 1.0)
const RESUME_COUNTDOWN := 5.0
const PICKUP_CALLOUT_DURATION := 1.0
const RELOAD_ARROW_LABEL := "AMMO"
const HEALTH_ARROW_LABEL := "HEALTH"
const BOOST_ARROW_LABEL := "SUPER WEAPON"
const RELOAD_CALLOUT_TEXT := "Reload available — get ammo!"
const HEALTH_CALLOUT_TEXT := "Health potion — get healing!"
const BOOST_CALLOUT_TEXT := "Super weapon boost — grab it now!"
const INTERACT_PROMPT_COLOR := Color(1.0, 0.95, 0.72, 1.0)
const OBJECTIVE_COLOR := Color(1.0, 0.85, 0.32, 1.0)
const DIALOGUE_MAX_SCREEN_WIDTH_RATIO := 0.7
const PAUSE_OVERLAY_ACTIVE_Z_INDEX := 295
const PAUSE_UI_LAYER := 400

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
@onready var pause_label: Label = $PauseOverlay/PauseLabel
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
var _get_ready_active := false
var _get_ready_left := 0.0
var _get_ready_callback: Callable
var _needs_resume_countdown: Callable
var _restore_pre_start_countdown: Callable
var _pickup_callout: Label
var _interact_prompt: Label
var _callout_tween: Tween
var _shake_off_hint: Control
var _shake_off_hint_shown := false
var _menu_mode := "start"
var _menu_secondary_button: Button
var _choice_yes_callback: Callable
var _choice_no_callback: Callable
var _tutorial_continue_callback: Callable
var _tutorial_panel: PanelContainer
var _tutorial_speaker_label: Label
var _tutorial_body_label: Label
var _objective_target: Node2D
var _objective_label := ""
var _pause_objectives_panel: VBoxContainer
var _pause_objectives_list: VBoxContainer
var _pause_objectives_hint: Label
var _pause_objective_checkboxes: Dictionary = {}
var _pause_objective_labels: Dictionary = {}
var _pause_ui_layer: CanvasLayer
var _pause_ui_root: Control
var _replay_objective_id := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("hud")
	$CountdownCenter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$MarginContainer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_label.visible = false
	wave_label.visible = false
	status_label.visible = false
	super_label.visible = false
	countdown_label.visible = false
	countdown_subtitle.visible = false
	$CountdownCenter.z_index = 100
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
	$TopRightControls.process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_pickup_callout()
	_setup_interact_prompt()
	_setup_tutorial_panel()
	_setup_shake_off_hint()
	_setup_pause_objectives_panel()
	_configure_dialogue_label(menu_message)
	get_viewport().size_changed.connect(_update_dialogue_width_limits)
	_update_dialogue_width_limits()
	if not SaveManager.is_objective_replay():
		show_start_screen()


func is_pause_menu_open() -> bool:
	return _pause_ui_root != null and _pause_ui_root.visible


func configure_resume_countdown(
	needs_countdown: Callable,
	restore_countdown: Callable
) -> void:
	_needs_resume_countdown = needs_countdown
	_restore_pre_start_countdown = restore_countdown


func bind_camera(camera: Camera2D) -> void:
	_camera = camera


func start_get_ready_countdown(on_finished: Callable) -> void:
	_get_ready_callback = on_finished
	_get_ready_active = true
	_get_ready_left = RESUME_COUNTDOWN
	get_tree().paused = true
	_hide_pause_ui()
	menu_overlay.visible = false
	pause_button.text = "Pause"
	start_countdown("Get ready")
	update_countdown(_get_ready_left)
	get_viewport().gui_release_focus()


func is_get_ready_active() -> bool:
	return _get_ready_active


func bind_player(player: CharacterBody2D) -> void:
	_player = player
	player.health_changed.connect(_on_player_health_changed)
	player.ammo_changed.connect(_on_player_ammo_changed)
	player.super_weapon_changed.connect(_on_super_weapon_changed)
	player.died.connect(_on_player_died)
	player.first_enemy_on_top.connect(show_shake_off_hint_once)
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
	_hide_pickup_banner_rows()
	_flash_pickup_callout(RELOAD_CALLOUT_TEXT, RELOAD_COLOR)
	if _camera:
		reload_arrow.activate(target, _camera, RELOAD_COLOR, _player, RELOAD_ARROW_LABEL)
		_update_reload_arrow_timer()


func update_reload_timer(seconds_left: float) -> void:
	_reload_time_left = seconds_left
	_update_reload_arrow_timer()


func hide_reload_indicator() -> void:
	_reload_target = null
	_reload_time_left = 0.0
	reload_arrow.deactivate()


func show_health_indicator(target: Node2D, duration: float) -> void:
	_health_target = target
	_health_time_left = duration
	_hide_pickup_banner_rows()
	_flash_pickup_callout(HEALTH_CALLOUT_TEXT, HEALTH_COLOR)
	if _camera:
		health_arrow.activate(target, _camera, HEALTH_COLOR, _player, HEALTH_ARROW_LABEL)
		_update_health_arrow_timer()


func update_health_timer(seconds_left: float) -> void:
	_health_time_left = seconds_left
	_update_health_arrow_timer()


func hide_health_indicator() -> void:
	_health_target = null
	_health_time_left = 0.0
	health_arrow.deactivate()


func show_boost_indicator(target: Node2D, duration: float) -> void:
	_boost_target = target
	_boost_time_left = duration
	_hide_pickup_banner_rows()
	_flash_pickup_callout(BOOST_CALLOUT_TEXT, BOOST_COLOR)
	if _camera:
		boost_arrow.activate(target, _camera, BOOST_COLOR, _player, BOOST_ARROW_LABEL)
		_update_boost_arrow_timer()


func update_boost_timer(seconds_left: float) -> void:
	_boost_time_left = seconds_left
	_update_boost_arrow_timer()


func hide_boost_indicator() -> void:
	_boost_target = null
	_boost_time_left = 0.0
	if _objective_target == null:
		boost_arrow.deactivate()


func show_objective_indicator(target: Node2D, label: String = "") -> void:
	_objective_target = target
	_objective_label = label


func hide_objective_indicator() -> void:
	_objective_target = null
	_objective_label = ""
	if _boost_target == null:
		boost_arrow.deactivate()


func show_shake_off_hint_once(enemy: CharacterBody2D) -> void:
	if _shake_off_hint_shown or enemy == null or not is_instance_valid(enemy):
		return
	if _camera == null:
		return
	_shake_off_hint_shown = true
	_shake_off_hint.activate(enemy, _camera)


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


func show_interact_prompt(message: String) -> void:
	_interact_prompt.text = message
	_interact_prompt.visible = true


func hide_interact_prompt() -> void:
	_interact_prompt.visible = false


func show_npc_dialogue(
	speaker: String,
	message: String,
	button_text: String,
	on_continue: Callable
) -> void:
	hide_interact_prompt()
	hide_tutorial_step()
	_menu_mode = "tutorial"
	_tutorial_continue_callback = on_continue
	_hide_secondary_button()
	hide_reload_indicator()
	hide_health_indicator()
	hide_boost_indicator()
	hide_countdown()
	get_tree().paused = true
	pause_overlay.visible = false
	pause_button.text = "Pause"
	menu_title.text = speaker
	menu_message.text = message
	menu_message.visible = true
	_update_dialogue_width_limits()
	menu_button.text = button_text
	menu_overlay.visible = true


func show_tutorial_step(speaker: String, instruction: String) -> void:
	_tutorial_speaker_label.text = speaker
	_tutorial_body_label.text = instruction
	_update_dialogue_width_limits()
	_tutorial_panel.visible = true


func hide_tutorial_step() -> void:
	if _tutorial_panel:
		_tutorial_panel.visible = false


func is_tutorial_step_visible() -> bool:
	return _tutorial_panel != null and _tutorial_panel.visible


func show_start_screen(title: String = "The Village") -> void:
	hide_tutorial_step()
	hide_interact_prompt()
	_menu_mode = "start"
	_hide_secondary_button()
	menu_title.text = title
	menu_message.visible = false
	menu_button.text = "Play"
	menu_overlay.visible = true


func show_game_over() -> void:
	_menu_mode = "restart"
	_hide_secondary_button()
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
	_menu_mode = "restart"
	_hide_secondary_button()
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
	get_viewport().gui_release_focus()


func is_menu_visible() -> bool:
	return menu_overlay.visible


func show_restart_message(message: String) -> void:
	status_label.text = message
	status_label.visible = true


func show_choice_prompt(
	title: String,
	message: String,
	yes_text: String,
	no_text: String,
	on_yes: Callable,
	on_no: Callable
) -> void:
	hide_interact_prompt()
	_menu_mode = "choice"
	_choice_yes_callback = on_yes
	_choice_no_callback = on_no
	hide_reload_indicator()
	hide_health_indicator()
	hide_boost_indicator()
	hide_countdown()
	get_tree().paused = true
	pause_overlay.visible = false
	pause_button.text = "Pause"
	menu_title.text = title
	menu_message.text = message
	menu_message.visible = true
	_update_dialogue_width_limits()
	menu_button.text = yes_text
	_ensure_secondary_button()
	_menu_secondary_button.text = no_text
	_menu_secondary_button.visible = true
	menu_overlay.visible = true


func _ensure_secondary_button() -> void:
	if _menu_secondary_button != null:
		return
	_menu_secondary_button = Button.new()
	_menu_secondary_button.custom_minimum_size = Vector2(220, 56)
	_menu_secondary_button.add_theme_font_size_override("font_size", 32)
	_menu_secondary_button.focus_mode = Control.FOCUS_NONE
	_menu_secondary_button.pressed.connect(_on_menu_secondary_pressed)
	var vbox: VBoxContainer = menu_button.get_parent()
	vbox.add_child(_menu_secondary_button)
	vbox.move_child(_menu_secondary_button, menu_button.get_index() + 1)


func _hide_secondary_button() -> void:
	if _menu_secondary_button:
		_menu_secondary_button.visible = false


func _close_tutorial_dialogue() -> void:
	menu_overlay.visible = false
	get_tree().paused = false
	get_viewport().gui_release_focus()


func _close_choice_prompt() -> void:
	_hide_secondary_button()
	menu_overlay.visible = false
	get_tree().paused = false
	get_viewport().gui_release_focus()


func _unhandled_input(event: InputEvent) -> void:
	if is_menu_visible() or _get_ready_active:
		return
	if event.is_action_pressed("pause"):
		_toggle_pause()


func _on_pause_pressed() -> void:
	_toggle_pause()


func _on_mute_pressed() -> void:
	var muted := AudioManager.toggle_muted()
	mute_button.text = "Unmute" if muted else "Mute"


func _toggle_pause() -> void:
	if is_menu_visible() or _get_ready_active:
		return

	if get_tree().paused:
		if _needs_resume_countdown.is_valid() and _needs_resume_countdown.call():
			start_get_ready_countdown(_finish_get_ready_after_resume)
		else:
			_apply_unpause()
	else:
		_refresh_pause_objectives_panel()
		get_tree().paused = true
		pause_overlay.z_index = PAUSE_OVERLAY_ACTIVE_Z_INDEX
		pause_overlay.visible = true
		if _pause_ui_root:
			_pause_ui_root.visible = true
		pause_button.text = "Resume"
		get_viewport().gui_release_focus()


func _apply_unpause() -> void:
	_clear_replay_objective_selection()
	get_tree().paused = false
	_hide_pause_ui()
	pause_button.text = "Pause"
	get_viewport().gui_release_focus()


func _finish_get_ready() -> void:
	_get_ready_active = false
	if _get_ready_callback.is_valid():
		_get_ready_callback.call()
	if get_tree().paused:
		get_tree().paused = false


func _finish_get_ready_after_resume() -> void:
	_apply_unpause()
	if _restore_pre_start_countdown.is_valid():
		_restore_pre_start_countdown.call()
	else:
		hide_countdown()


func _disable_button_keyboard_focus() -> void:
	for button in [pause_button, mute_button, menu_button]:
		button.focus_mode = Control.FOCUS_NONE


func _on_menu_button_pressed() -> void:
	if _menu_mode == "tutorial":
		var callback := _tutorial_continue_callback
		_close_tutorial_dialogue()
		if callback.is_valid():
			callback.call()
		return
	if _menu_mode == "choice":
		var callback := _choice_yes_callback
		_close_choice_prompt()
		if callback.is_valid():
			callback.call()
		return
	if menu_button.text == "Play":
		play_pressed.emit()
	else:
		restart_pressed.emit()


func _on_menu_secondary_pressed() -> void:
	if _menu_mode != "choice":
		return
	var callback := _choice_no_callback
	_close_choice_prompt()
	if callback.is_valid():
		callback.call()


func _update_reload_arrow_timer() -> void:
	if reload_arrow.visible:
		if _reload_time_left < 0.0:
			reload_arrow.set_timer_text("")
		else:
			reload_arrow.set_timer_text("%ds" % maxi(ceili(_reload_time_left), 0))


func _update_health_arrow_timer() -> void:
	if health_arrow.visible:
		health_arrow.set_timer_text("%ds" % maxi(ceili(_health_time_left), 0))


func _update_boost_arrow_timer() -> void:
	if boost_arrow.visible:
		boost_arrow.set_timer_text("%ds" % maxi(ceili(_boost_time_left), 0))


func _setup_tutorial_panel() -> void:
	_tutorial_panel = PanelContainer.new()
	_tutorial_panel.name = "TutorialPanel"
	_tutorial_panel.z_index = 109
	_tutorial_panel.visible = false
	_tutorial_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_tutorial_panel.offset_top = 12.0
	_tutorial_panel.offset_bottom = 108.0
	_tutorial_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 12)
	_tutorial_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)

	_tutorial_speaker_label = Label.new()
	_tutorial_speaker_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tutorial_speaker_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_tutorial_speaker_label.add_theme_font_size_override("font_size", 28)
	_tutorial_speaker_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.45))
	vbox.add_child(_tutorial_speaker_label)

	_tutorial_body_label = Label.new()
	_configure_dialogue_label(_tutorial_body_label)
	_tutorial_body_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_tutorial_body_label.add_theme_font_size_override("font_size", 24)
	_tutorial_body_label.add_theme_color_override("font_color", Color(0.92, 0.94, 0.98))
	vbox.add_child(_tutorial_body_label)

	add_child(_tutorial_panel)


func _configure_dialogue_label(label: Label) -> void:
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER


func _dialogue_max_width() -> float:
	return get_viewport().get_visible_rect().size.x * DIALOGUE_MAX_SCREEN_WIDTH_RATIO


func _apply_dialogue_max_width(label: Label) -> void:
	if label == null:
		return
	var max_width := _dialogue_max_width()
	label.custom_minimum_size.x = max_width
	label.size.x = max_width


func _update_dialogue_width_limits() -> void:
	_apply_dialogue_max_width(menu_message)
	_apply_dialogue_max_width(_tutorial_body_label)


func _setup_interact_prompt() -> void:
	_interact_prompt = Label.new()
	_interact_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_interact_prompt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_interact_prompt.add_theme_font_size_override("font_size", 34)
	_interact_prompt.add_theme_color_override("font_color", INTERACT_PROMPT_COLOR)
	_interact_prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_interact_prompt.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_interact_prompt.offset_left = -420.0
	_interact_prompt.offset_top = -96.0
	_interact_prompt.offset_right = 420.0
	_interact_prompt.offset_bottom = -24.0
	_interact_prompt.z_index = 108
	_interact_prompt.visible = false
	add_child(_interact_prompt)


func _setup_pickup_callout() -> void:
	_pickup_callout = Label.new()
	_pickup_callout.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pickup_callout.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_pickup_callout.add_theme_font_size_override("font_size", 44)
	_pickup_callout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pickup_callout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_pickup_callout.z_index = 110
	_pickup_callout.visible = false
	add_child(_pickup_callout)


func _flash_pickup_callout(message: String, color: Color) -> void:
	if _callout_tween and _callout_tween.is_valid():
		_callout_tween.kill()
	_pickup_callout.text = message
	_pickup_callout.add_theme_color_override("font_color", color)
	_pickup_callout.visible = true
	_callout_tween = create_tween()
	_callout_tween.tween_interval(PICKUP_CALLOUT_DURATION)
	_callout_tween.tween_callback(func() -> void: _pickup_callout.visible = false)


func _setup_shake_off_hint() -> void:
	_shake_off_hint = Control.new()
	_shake_off_hint.name = "ShakeOffHint"
	_shake_off_hint.set_script(load("res://scenes/shake_off_hint.gd"))
	add_child(_shake_off_hint)


func _setup_pause_objectives_panel() -> void:
	pause_label.visible = false
	pause_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	pause_overlay.mouse_filter = Control.MOUSE_FILTER_STOP

	_pause_ui_layer = CanvasLayer.new()
	_pause_ui_layer.name = "PauseUILayer"
	_pause_ui_layer.layer = PAUSE_UI_LAYER
	_pause_ui_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_pause_ui_layer)

	_pause_ui_root = Control.new()
	_pause_ui_root.name = "PauseUIRoot"
	_pause_ui_root.process_mode = Node.PROCESS_MODE_ALWAYS
	_pause_ui_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_pause_ui_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_pause_ui_root.visible = false
	_pause_ui_layer.add_child(_pause_ui_root)

	var center := MarginContainer.new()
	center.name = "PauseCenter"
	center.process_mode = Node.PROCESS_MODE_ALWAYS
	center.mouse_filter = Control.MOUSE_FILTER_STOP
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.add_theme_constant_override("margin_left", 24)
	center.add_theme_constant_override("margin_right", 24)
	center.add_theme_constant_override("margin_top", 24)
	center.add_theme_constant_override("margin_bottom", 24)
	_pause_ui_root.add_child(center)

	_pause_objectives_panel = VBoxContainer.new()
	_pause_objectives_panel.name = "PauseVBox"
	_pause_objectives_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	_pause_objectives_panel.add_theme_constant_override("separation", 14)
	_pause_objectives_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_pause_objectives_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center.add_child(_pause_objectives_panel)

	var title := Label.new()
	title.text = "PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 56)
	title.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	_pause_objectives_panel.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Story objectives"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 24)
	subtitle.add_theme_color_override("font_color", Color(0.85, 0.9, 1, 1))
	_pause_objectives_panel.add_child(subtitle)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 220)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	scroll.process_mode = Node.PROCESS_MODE_ALWAYS
	_pause_objectives_panel.add_child(scroll)

	_pause_objectives_list = VBoxContainer.new()
	_pause_objectives_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_pause_objectives_list.add_theme_constant_override("separation", 8)
	_pause_objectives_list.process_mode = Node.PROCESS_MODE_ALWAYS
	scroll.add_child(_pause_objectives_list)

	for entry in StoryObjectives.get_entries():
		var objective_id: String = entry.id
		var row := Button.new()
		row.name = "Objective_%s" % objective_id
		row.alignment = HORIZONTAL_ALIGNMENT_LEFT
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.custom_minimum_size = Vector2(0, 44)
		row.add_theme_font_size_override("font_size", 20)
		row.focus_mode = Control.FOCUS_NONE
		row.mouse_filter = Control.MOUSE_FILTER_STOP
		row.process_mode = Node.PROCESS_MODE_ALWAYS
		row.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
		row.visible = false
		row.pressed.connect(_on_objective_replay_selected.bind(objective_id))
		_pause_objectives_list.add_child(row)
		_pause_objective_checkboxes[objective_id] = row

		var pending := Label.new()
		pending.name = "Pending_%s" % objective_id
		pending.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		pending.custom_minimum_size = Vector2(0, 32)
		pending.add_theme_font_size_override("font_size", 20)
		pending.add_theme_color_override("font_color", Color(0.55, 0.58, 0.65, 1))
		pending.visible = true
		pending.text = entry.title
		_pause_objectives_list.add_child(pending)
		_pause_objective_labels[objective_id] = pending

	_pause_objectives_hint = Label.new()
	_pause_objectives_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_pause_objectives_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pause_objectives_hint.add_theme_font_size_override("font_size", 18)
	_pause_objectives_hint.add_theme_color_override("font_color", Color(0.78, 0.82, 0.9, 1))
	_pause_objectives_panel.add_child(_pause_objectives_hint)

	var resume_hint := Label.new()
	resume_hint.text = "Press Resume or Pause to continue playing"
	resume_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	resume_hint.add_theme_font_size_override("font_size", 18)
	resume_hint.add_theme_color_override("font_color", Color(0.7, 0.74, 0.82, 1))
	_pause_objectives_panel.add_child(resume_hint)


func _refresh_pause_objectives_panel() -> void:
	_replay_objective_id = ""
	var has_completed := false
	for entry in StoryObjectives.get_entries():
		var objective_id: String = entry.id
		var completed := StoryObjectives.is_complete(objective_id)
		if completed:
			has_completed = true
		var button: Button = _pause_objective_checkboxes.get(objective_id)
		var pending: Label = _pause_objective_labels.get(objective_id)
		if button:
			button.visible = completed
			button.text = "Replay: %s" % entry.title
		if pending:
			pending.visible = not completed
			pending.text = entry.title

	if has_completed:
		_pause_objectives_hint.text = (
			"Click a completed objective to replay it. "
			+ "Later objectives will reset too."
		)
	else:
		_pause_objectives_hint.text = "No story objectives completed yet."


func _hide_pause_ui() -> void:
	pause_overlay.visible = false
	if _pause_ui_root:
		_pause_ui_root.visible = false
	pause_overlay.z_index = 50


func _on_objective_replay_selected(objective_id: String) -> void:
	call_deferred("_start_objective_replay", objective_id)


func _start_objective_replay(objective_id: String) -> void:
	if not StoryObjectives.is_complete(objective_id):
		return
	_replay_objective_id = ""
	get_tree().paused = false
	_hide_pause_ui()
	pause_button.text = "Pause"
	get_viewport().gui_release_focus()
	StoryObjectives.begin_replay(objective_id, get_tree())


func _clear_replay_objective_selection() -> void:
	_replay_objective_id = ""


func _hide_pickup_banner_rows() -> void:
	reload_banner_row.visible = false
	health_banner_row.visible = false
	boost_banner_row.visible = false
	pickup_banner.visible = false


func _process(delta: float) -> void:
	if _get_ready_active:
		_get_ready_left -= delta
		update_countdown(_get_ready_left)
		if _get_ready_left <= 0.0:
			_finish_get_ready()
		return

	if _reload_target and is_instance_valid(_reload_target) and _camera and _player:
		if not reload_arrow.visible:
			reload_arrow.activate(
				_reload_target, _camera, RELOAD_COLOR, _player, RELOAD_ARROW_LABEL
			)
			_update_reload_arrow_timer()
	elif reload_arrow.visible:
		reload_arrow.deactivate()

	if _health_target and is_instance_valid(_health_target) and _camera and _player:
		if not health_arrow.visible:
			health_arrow.activate(
				_health_target, _camera, HEALTH_COLOR, _player, HEALTH_ARROW_LABEL
			)
			_update_health_arrow_timer()
	elif health_arrow.visible:
		health_arrow.deactivate()

	if _objective_target and is_instance_valid(_objective_target) and _camera and _player:
		if not boost_arrow.visible or boost_arrow.label_text != _objective_label:
			boost_arrow.activate(
				_objective_target, _camera, OBJECTIVE_COLOR, _player, _objective_label
			)
	elif _boost_target and is_instance_valid(_boost_target) and _camera and _player:
		if not boost_arrow.visible:
			boost_arrow.activate(
				_boost_target, _camera, BOOST_COLOR, _player, BOOST_ARROW_LABEL
			)
			_update_boost_arrow_timer()
	elif boost_arrow.visible and _objective_target == null:
		boost_arrow.deactivate()


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
