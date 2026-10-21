extends CanvasLayer
class_name HUD

const _PushWaveScript := preload("res://scripts/systems/push_wave.gd")
const _UpgradeMenuScript := preload("res://scripts/ui/upgrade_menu.gd")
const _SettingsMenuScript := preload("res://scripts/ui/settings_menu.gd")
const _BossRewardMenuScript := preload("res://scripts/ui/boss_reward_menu.gd")

@onready var side_menu: PanelContainer = %SideMenu
@onready var hire_menu: PanelContainer = %HireMenu
@onready var root_ui: Control = $Root
@onready var title_label: Label = %TitleLabel
@onready var hire_title: Label = %HireTitle
@onready var gold_label: Label = %GoldLabel
@onready var hp_label: Label = %HpLabel
@onready var wave_label: Label = %WaveLabel
@onready var record_label: Label = %RecordLabel
@onready var sector_label: Label = %SectorLabel
@onready var status_label: Label = %StatusLabel
@onready var btn_infantry: Button = %BtnInfantry
@onready var btn_archer: Button = %BtnArcher
@onready var btn_eagle: Button = %BtnEagle
@onready var btn_heal: Button = %BtnHeal
@onready var btn_wave: Button = %BtnWave
@onready var btn_upgrades: Button = %BtnUpgrades
@onready var btn_settings: Button = %BtnSettings
@onready var cheat_sep: HSeparator = %CheatSep
@onready var cheat_title: Label = %CheatTitle
@onready var btn_cheat_gold: Button = %BtnCheatGold
@onready var cheat_wave_row: HBoxContainer = %CheatWaveRow
@onready var cheat_wave_edit: LineEdit = %CheatWaveEdit
@onready var btn_cheat_wave: Button = %BtnCheatWave
@onready var btn_restart: Button = %BtnRestart
@onready var sector_buttons: HBoxContainer = %SectorButtons

var _recruitment: Recruitment
var _upgrade_menu: Control
var _settings_menu: Control
var _boss_reward_menu: Control
var _defeat_overlay: Control

const COL_PANEL := Color(0.14, 0.18, 0.12, 0.92)
const COL_BORDER := Color(0.72, 0.58, 0.28, 1.0)
const COL_TITLE := Color(0.95, 0.86, 0.55, 1.0)
const COL_TEXT := Color(0.88, 0.92, 0.78, 1.0)
const COL_GOLD := Color(1.0, 0.86, 0.35, 1.0)
const COL_HP := Color(0.55, 0.9, 0.55, 1.0)
const COL_WAVE := Color(0.7, 0.85, 1.0, 1.0)
const COL_BTN := Color(0.22, 0.3, 0.18, 1.0)
const COL_BTN_HOVER := Color(0.32, 0.42, 0.24, 1.0)
const COL_BTN_PRESS := Color(0.16, 0.22, 0.12, 1.0)
const COL_BTN_DISABLED := Color(0.18, 0.2, 0.16, 0.7)


func setup(recruitment: Recruitment) -> void:
	_recruitment = recruitment
	_recruitment.hire_failed.connect(_on_hire_failed)
	_recruitment.hire_succeeded.connect(_on_hire_succeeded)
	_recruitment.archer_hire_started.connect(_on_archer_hire_started)
	_recruitment.archer_hire_cancelled.connect(_on_archer_hire_cancelled)


func _ready() -> void:
	_apply_menu_style()
	_fit_menu_heights()
	_upgrade_menu = _UpgradeMenuScript.new()
	root_ui.add_child(_upgrade_menu)
	_settings_menu = _SettingsMenuScript.new()
	root_ui.add_child(_settings_menu)
	_boss_reward_menu = _BossRewardMenuScript.new()
	root_ui.add_child(_boss_reward_menu)
	GameState.gold_changed.connect(_on_gold)
	GameState.kingdom_hp_changed.connect(_on_hp)
	GameState.wave_started.connect(_on_wave)
	GameState.wave_rest_started.connect(_on_wave_rest)
	GameState.best_wave_changed.connect(_on_best_wave)
	GameState.game_over.connect(_on_game_over)
	GameState.boss_killed.connect(_on_boss_killed)
	btn_infantry.pressed.connect(_on_hire_infantry)
	btn_archer.pressed.connect(_on_hire_archer)
	btn_eagle.pressed.connect(_on_hire_eagle)
	btn_heal.pressed.connect(_on_heal_kingdom)
	btn_wave.pressed.connect(_on_push_wave)
	btn_upgrades.pressed.connect(_on_open_upgrades)
	btn_settings.pressed.connect(_on_open_settings)
	btn_cheat_gold.pressed.connect(_on_cheat_gold)
	btn_cheat_wave.pressed.connect(_on_cheat_wave)
	cheat_wave_edit.text_submitted.connect(func(_t: String) -> void: _on_cheat_wave())
	btn_restart.pressed.connect(_on_restart)
	GameState.cheats_changed.connect(_on_cheats_changed)
	_build_sector_buttons()
	sector_buttons.visible = false
	_on_gold(GameState.gold)
	_on_best_wave(GameState.best_wave)
	_on_cheats_changed(GameState.cheats_enabled)
	_refresh_sector_label()
	btn_infantry.text = "Пехота  ·  %d" % GameConfig.COST_PLAYER_INFANTRY
	btn_archer.text = "Лучники  ·  %d" % GameConfig.COST_PLAYER_ARCHER
	btn_eagle.text = "Орлы  ·  %d" % GameConfig.COST_PLAYER_EAGLE
	btn_heal.text = "Лечение +%d  ·  %d" % [GameConfig.KINGDOM_HEAL_AMOUNT, GameConfig.COST_KINGDOM_HEAL]
	btn_wave.text = "Толчок  ·  %d" % GameConfig.COST_PUSH_WAVE
	btn_upgrades.text = "Улучшения"
	btn_settings.text = "Настройки"
	btn_cheat_gold.text = "+%d золота" % GameState.CHEAT_GOLD_AMOUNT
	btn_cheat_wave.text = "Перейти"
	cheat_wave_edit.placeholder_text = "№ волны"
	btn_restart.text = "Заново"
	status_label.text = "Нанимайте войска справа."
	wave_label.text = "Волна: —"
	# Refit after sector buttons exist / visibility changes.
	call_deferred("_fit_menu_heights")


func _fit_menu_heights() -> void:
	## Keep panels only as tall as content — don't stretch over the battlefield.
	await get_tree().process_frame
	_fit_panel_height(side_menu)
	_fit_panel_height(hire_menu)


func _fit_panel_height(panel: PanelContainer) -> void:
	if panel == null:
		return
	var content := panel.get_child(0) as Control
	if content == null:
		return
	var h := content.get_combined_minimum_size().y + 4.0
	panel.offset_bottom = panel.offset_top + h


func _apply_menu_style() -> void:
	side_menu.add_theme_stylebox_override("panel", _make_panel_style())
	hire_menu.add_theme_stylebox_override("panel", _make_panel_style())
	title_label.add_theme_color_override("font_color", COL_TITLE)
	hire_title.add_theme_color_override("font_color", COL_TITLE)
	for lab in [sector_label, status_label]:
		lab.add_theme_color_override("font_color", COL_TEXT)
	_style_button(btn_infantry)
	_style_button(btn_archer)
	_style_button(btn_eagle)
	_style_button(btn_heal)
	_style_button(btn_wave)
	_style_button(btn_upgrades)
	_style_button(btn_settings)
	_style_button(btn_cheat_gold)
	_style_button(btn_cheat_wave)
	cheat_title.add_theme_color_override("font_color", COL_GOLD)
	_style_button(btn_restart, true)


func _make_panel_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = COL_PANEL
	sb.border_color = COL_BORDER
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(10)
	sb.shadow_color = Color(0, 0, 0, 0.35)
	sb.shadow_size = 6
	sb.shadow_offset = Vector2(0, 3)
	return sb


func _make_button_style(bg: Color, border: Color = COL_BORDER) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 5
	sb.content_margin_bottom = 5
	return sb


func _style_button(btn: Button, secondary: bool = false) -> void:
	var base := COL_BTN_PRESS if secondary else COL_BTN
	var hover := Color(0.28, 0.3, 0.22, 1.0) if secondary else COL_BTN_HOVER
	btn.add_theme_stylebox_override("normal", _make_button_style(base))
	btn.add_theme_stylebox_override("hover", _make_button_style(hover, Color(0.9, 0.75, 0.35, 1.0)))
	btn.add_theme_stylebox_override("pressed", _make_button_style(COL_BTN_PRESS))
	btn.add_theme_stylebox_override("disabled", _make_button_style(COL_BTN_DISABLED, Color(0.4, 0.4, 0.35, 1.0)))
	btn.add_theme_stylebox_override("focus", _make_button_style(hover, Color(1.0, 0.85, 0.4, 1.0)))
	btn.add_theme_color_override("font_color", COL_TEXT)
	btn.add_theme_color_override("font_hover_color", Color(1, 1, 0.9, 1))
	btn.add_theme_color_override("font_pressed_color", COL_GOLD)
	btn.add_theme_color_override("font_disabled_color", Color(0.55, 0.55, 0.5, 1))


func _build_sector_buttons() -> void:
	for c in sector_buttons.get_children():
		c.queue_free()
	for i in GameConfig.SECTOR_COUNT:
		var b := Button.new()
		b.text = str(i)
		b.custom_minimum_size = Vector2(28, 26)
		_style_button(b)
		var sector := i
		b.pressed.connect(func() -> void: _on_sector_picked(sector))
		sector_buttons.add_child(b)


func select_sector(sector: int) -> void:
	if _recruitment and _recruitment.pending_archer_hire:
		_recruitment.confirm_archer_sector(sector)
		_refresh_sector_label()
		call_deferred("_fit_menu_heights")
		return
	if _recruitment:
		_recruitment.set_selected_sector(sector)
	_refresh_sector_label()


func _on_sector_picked(sector: int) -> void:
	select_sector(sector)


func _refresh_sector_label() -> void:
	if _recruitment and _recruitment.pending_archer_hire:
		sector_label.text = "Сектор лучников: 0–7"
		sector_label.add_theme_color_override("font_color", COL_GOLD)
		return
	var s := _recruitment.selected_sector if _recruitment else 0
	var occupied := " · занят" if GameState.has_wall_archer(s) else ""
	sector_label.text = "Сектор: %d%s" % [s, occupied]
	sector_label.add_theme_color_override("font_color", COL_TEXT)


func _on_gold(amount: int) -> void:
	gold_label.text = "Золото: %d" % amount
	gold_label.add_theme_color_override("font_color", COL_GOLD)


func _on_hp(current: int, maximum: int) -> void:
	hp_label.text = "Прочность: %d / %d" % [current, maximum]
	var t := clampf(float(current) / float(maxi(1, maximum)), 0.0, 1.0)
	hp_label.add_theme_color_override("font_color", COL_HP.lerp(Color(1.0, 0.4, 0.35, 1.0), 1.0 - t))


func _on_wave(index: int) -> void:
	if GameConfig.is_boss_knight_wave(index):
		var tier: int = GameConfig.boss_knight_tier(index)
		wave_label.text = "%d волна · БОСС" % index
		wave_label.add_theme_color_override("font_color", Color(1.0, 0.7, 0.25, 1.0))
		if tier <= 0:
			status_label.text = "Большой рыцарь + летуны!"
		else:
			status_label.text = "Босс усилен (ур.%d) + летуны!" % (tier + 1)
		status_label.add_theme_color_override("font_color", Color(1.0, 0.75, 0.35, 1))
	else:
		wave_label.text = "%d волна" % index
		wave_label.add_theme_color_override("font_color", COL_WAVE)
		status_label.text = "Волна началась"
		status_label.add_theme_color_override("font_color", COL_WAVE)


func _on_wave_rest(seconds: float) -> void:
	status_label.text = "Передышка %.0f сек — готовьтесь" % seconds
	status_label.add_theme_color_override("font_color", Color(0.75, 0.9, 0.55, 1))
	wave_label.text = "Передышка…"
	wave_label.add_theme_color_override("font_color", Color(0.75, 0.9, 0.55, 1))


func _on_best_wave(best: int) -> void:
	if best <= 0:
		record_label.text = "Рекорд: —"
	else:
		record_label.text = "Рекорд: %d" % best
	record_label.add_theme_color_override("font_color", COL_GOLD)


func _on_hire_infantry() -> void:
	if _recruitment:
		if _recruitment.pending_archer_hire:
			_recruitment.cancel_archer_hire()
		_recruitment.hire_infantry()


func _on_hire_archer() -> void:
	if _recruitment == null:
		return
	if _recruitment.pending_archer_hire:
		_recruitment.cancel_archer_hire()
		call_deferred("_fit_menu_heights")
		return
	_recruitment.begin_archer_hire()


func _on_hire_eagle() -> void:
	if _recruitment:
		if _recruitment.pending_archer_hire:
			_recruitment.cancel_archer_hire()
		_recruitment.hire_eagle()


func _on_archer_hire_started() -> void:
	sector_buttons.visible = true
	status_label.text = "Выберите сектор"
	status_label.add_theme_color_override("font_color", COL_GOLD)
	_refresh_sector_label()
	call_deferred("_fit_menu_heights")


func _on_archer_hire_cancelled() -> void:
	sector_buttons.visible = false
	status_label.text = "Найм отменён"
	status_label.add_theme_color_override("font_color", Color(0.75, 0.8, 0.7, 1))
	_refresh_sector_label()
	call_deferred("_fit_menu_heights")


func _on_hire_failed(reason: String) -> void:
	status_label.text = reason
	status_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.4, 1))
	_refresh_sector_label()


func _on_hire_succeeded(kind: GameConfig.UnitKind, sector: int) -> void:
	var name := "Пехота"
	match kind:
		GameConfig.UnitKind.ARCHER:
			name = "Лучники"
		GameConfig.UnitKind.EAGLE:
			name = "Орлы"
		_:
			name = "Пехота"
	status_label.text = "%s → с.%d" % [name, sector]
	status_label.add_theme_color_override("font_color", Color(0.6, 1.0, 0.65, 1))
	if kind == GameConfig.UnitKind.ARCHER:
		sector_buttons.visible = false
	_refresh_sector_label()
	call_deferred("_fit_menu_heights")


func _on_heal_kingdom() -> void:
	if GameState.kingdom == null:
		status_label.text = "Ошибка"
		status_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.4, 1))
		return
	var err: String = GameState.kingdom.try_paid_heal()
	if err != "":
		status_label.text = err
		status_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.4, 1))
		return
	status_label.text = "Исцелено +%d" % GameConfig.KINGDOM_HEAL_AMOUNT
	status_label.add_theme_color_override("font_color", Color(0.6, 1.0, 0.65, 1))


func _on_push_wave() -> void:
	var msg: String = _PushWaveScript.try_cast(get_tree())
	var ok: bool = not msg.begins_with("Not enough") and msg != "Game over"
	status_label.text = msg
	status_label.add_theme_color_override(
		"font_color",
		Color(0.65, 0.9, 1.0, 1) if ok else Color(1.0, 0.5, 0.4, 1)
	)


func _on_boss_killed() -> void:
	if GameState.is_game_over:
		return
	if _upgrade_menu != null and _upgrade_menu.has_method("hide_quiet"):
		_upgrade_menu.call("hide_quiet")
	if _settings_menu != null and _settings_menu.has_method("hide_quiet"):
		_settings_menu.call("hide_quiet")
	if _boss_reward_menu != null and _boss_reward_menu.has_method("open_menu"):
		_boss_reward_menu.call("open_menu")
	status_label.text = "Награда за босса"
	status_label.add_theme_color_override("font_color", COL_GOLD)


func _on_open_upgrades() -> void:
	if _recruitment and _recruitment.pending_archer_hire:
		_recruitment.cancel_archer_hire()
	if _settings_menu and _settings_menu.has_method("hide_quiet"):
		_settings_menu.call("hide_quiet")
	if _upgrade_menu and _upgrade_menu.has_method("open_menu"):
		_upgrade_menu.call("open_menu")


func _on_open_settings() -> void:
	if _recruitment and _recruitment.pending_archer_hire:
		_recruitment.cancel_archer_hire()
	if _upgrade_menu and _upgrade_menu.has_method("hide_quiet"):
		_upgrade_menu.call("hide_quiet")
	if _settings_menu and _settings_menu.has_method("open_menu"):
		_settings_menu.call("open_menu")


func _on_cheats_changed(enabled: bool) -> void:
	cheat_sep.visible = enabled
	cheat_title.visible = enabled
	btn_cheat_gold.visible = enabled
	cheat_wave_row.visible = enabled
	call_deferred("_fit_menu_heights")


func _on_cheat_gold() -> void:
	if not GameState.cheats_enabled:
		return
	GameState.cheat_add_gold()
	status_label.text = "Чит: +%d золота" % GameState.CHEAT_GOLD_AMOUNT
	status_label.add_theme_color_override("font_color", COL_GOLD)


func _on_cheat_wave() -> void:
	if not GameState.cheats_enabled:
		return
	if GameState.is_game_over:
		status_label.text = "Игра окончена"
		status_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.4, 1))
		return
	var raw := cheat_wave_edit.text.strip_edges()
	if not raw.is_valid_int():
		status_label.text = "Введите номер волны"
		status_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.4, 1))
		return
	var wave := int(raw)
	if wave < 1:
		status_label.text = "Волна ≥ 1"
		status_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.4, 1))
		return
	var wm := get_tree().get_first_node_in_group("wave_manager")
	if wm == null:
		var main := get_tree().current_scene
		if main != null:
			wm = main.get_node_or_null("WaveManager")
	if wm == null or not wm.has_method("cheat_jump_to_wave"):
		status_label.text = "WaveManager не найден"
		status_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.4, 1))
		return
	var err: String = wm.call("cheat_jump_to_wave", wave)
	if err != "":
		status_label.text = err
		status_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.4, 1))
		return
	status_label.text = "Чит: волна %d" % wave
	status_label.add_theme_color_override("font_color", COL_GOLD)


func _on_restart() -> void:
	get_tree().paused = false
	GameState.reset_run()
	get_tree().reload_current_scene()


func _on_game_over(victory: bool) -> void:
	var base := "Победа!" if victory else "Королевство пало"
	if (
		not GameState.cheats_enabled
		and GameState.current_wave > 0
		and GameState.current_wave >= GameState.best_wave
	):
		base += " · рекорд: %d" % GameState.best_wave
	elif GameState.cheats_enabled:
		base += " · читы (рекорд не пишется)"
	status_label.text = base
	status_label.add_theme_color_override(
		"font_color",
		Color(1, 0.85, 0.3, 1) if victory else Color(1, 0.4, 0.4, 1)
	)
	btn_infantry.disabled = true
	btn_archer.disabled = true
	btn_eagle.disabled = true
	btn_heal.disabled = true
	btn_wave.disabled = true
	btn_upgrades.disabled = true
	sector_buttons.visible = false
	if not victory:
		_show_defeat_overlay()
	call_deferred("_fit_menu_heights")


func _show_defeat_overlay() -> void:
	if _defeat_overlay != null and is_instance_valid(_defeat_overlay):
		_defeat_overlay.visible = true
		return
	var overlay := Control.new()
	overlay.name = "DefeatOverlay"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.z_index = 100

	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.05, 0.02, 0.02, 0.72)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(dim)

	var center := VBoxContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	center.grow_horizontal = Control.GROW_DIRECTION_BOTH
	center.grow_vertical = Control.GROW_DIRECTION_BOTH
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_theme_constant_override("separation", 28)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(center)
	# Anchor center box roughly in the middle of the screen.
	center.offset_left = -220.0
	center.offset_right = 220.0
	center.offset_top = -80.0
	center.offset_bottom = 80.0

	var label := Label.new()
	label.text = "Королевство пало"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 64)
	label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.32, 1.0))
	label.add_theme_color_override("font_outline_color", Color(0.15, 0.02, 0.02, 1.0))
	label.add_theme_constant_override("outline_size", 8)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(label)

	var btn := Button.new()
	btn.text = "Заново"
	btn.custom_minimum_size = Vector2(180, 48)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_style_button(btn)
	btn.add_theme_font_size_override("font_size", 20)
	btn.pressed.connect(_on_restart)
	center.add_child(btn)

	root_ui.add_child(overlay)
	_defeat_overlay = overlay
