extends Control
## Pause overlay: volume + record. PROCESS_MODE_WHEN_PAUSED.

signal closed

const COL_PANEL := Color(0.12, 0.16, 0.11, 0.96)
const COL_BORDER := Color(0.72, 0.58, 0.28, 1.0)
const COL_TITLE := Color(0.95, 0.86, 0.55, 1.0)
const COL_TEXT := Color(0.88, 0.92, 0.78, 1.0)
const COL_GOLD := Color(1.0, 0.86, 0.35, 1.0)
const COL_BTN := Color(0.22, 0.3, 0.18, 1.0)
const COL_BTN_HOVER := Color(0.32, 0.42, 0.24, 1.0)
const COL_BTN_PRESS := Color(0.16, 0.22, 0.12, 1.0)
const COL_DIM := Color(0, 0, 0, 0.55)

var _volume_slider: HSlider
var _volume_value: Label
var _record_label: Label
var _cheats_check: CheckButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	_build_ui()
	GameState.best_wave_changed.connect(_on_best_wave)


func open_menu() -> void:
	visible = true
	_sync_volume_ui()
	_sync_cheats_ui()
	_on_best_wave(GameState.best_wave)
	get_tree().paused = true


func close_menu() -> void:
	visible = false
	get_tree().paused = false
	closed.emit()


func hide_quiet() -> void:
	visible = false


func _build_ui() -> void:
	var dim := ColorRect.new()
	dim.color = COL_DIM
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(420, 320)
	panel.add_theme_stylebox_override("panel", _panel_style())
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	margin.add_child(root)

	var header := HBoxContainer.new()
	root.add_child(header)

	var title := Label.new()
	title.text = "Настройки"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", COL_TITLE)
	header.add_child(title)

	var btn_close := Button.new()
	btn_close.text = "Закрыть"
	btn_close.custom_minimum_size = Vector2(100, 32)
	_style_button(btn_close)
	btn_close.pressed.connect(close_menu)
	header.add_child(btn_close)

	_record_label = Label.new()
	_record_label.add_theme_font_size_override("font_size", 14)
	_record_label.add_theme_color_override("font_color", COL_GOLD)
	root.add_child(_record_label)

	var sep := HSeparator.new()
	root.add_child(sep)

	var vol_title := Label.new()
	vol_title.text = "Громкость звука"
	vol_title.add_theme_color_override("font_color", COL_TEXT)
	root.add_child(vol_title)

	var vol_row := HBoxContainer.new()
	vol_row.add_theme_constant_override("separation", 10)
	root.add_child(vol_row)

	_volume_slider = HSlider.new()
	_volume_slider.min_value = 0.0
	_volume_slider.max_value = 100.0
	_volume_slider.step = 1.0
	_volume_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_volume_slider.custom_minimum_size = Vector2(200, 24)
	_volume_slider.value_changed.connect(_on_volume_changed)
	vol_row.add_child(_volume_slider)

	_volume_value = Label.new()
	_volume_value.custom_minimum_size = Vector2(48, 0)
	_volume_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_volume_value.add_theme_color_override("font_color", COL_TEXT)
	vol_row.add_child(_volume_value)

	var sep2 := HSeparator.new()
	root.add_child(sep2)

	var cheats_title := Label.new()
	cheats_title.text = "Читы"
	cheats_title.add_theme_color_override("font_color", COL_TITLE)
	root.add_child(cheats_title)

	_cheats_check = CheckButton.new()
	_cheats_check.text = "Включить читы в игровом меню"
	_cheats_check.add_theme_color_override("font_color", COL_TEXT)
	_cheats_check.toggled.connect(_on_cheats_toggled)
	root.add_child(_cheats_check)

	var cheats_hint := Label.new()
	cheats_hint.text = "Появится кнопка «+1000 золота» в боковом меню."
	cheats_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cheats_hint.add_theme_font_size_override("font_size", 11)
	cheats_hint.add_theme_color_override("font_color", Color(0.7, 0.75, 0.65, 1))
	root.add_child(cheats_hint)

	var hint := Label.new()
	hint.text = "Esc — закрыть. Рекорд волн сохраняется автоматически."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 11)
	hint.add_theme_color_override("font_color", Color(0.7, 0.75, 0.65, 1))
	root.add_child(hint)


func _sync_volume_ui() -> void:
	var pct := Sfx.get_volume_percent()
	_volume_slider.set_value_no_signal(pct)
	_volume_value.text = "%d%%" % int(pct)


func _sync_cheats_ui() -> void:
	if _cheats_check:
		_cheats_check.set_pressed_no_signal(GameState.cheats_enabled)


func _on_volume_changed(value: float) -> void:
	Sfx.set_volume_percent(value)
	_volume_value.text = "%d%%" % int(value)
	GameState.save_settings()


func _on_cheats_toggled(pressed: bool) -> void:
	GameState.set_cheats_enabled(pressed)


func _on_best_wave(best: int) -> void:
	if _record_label == null:
		return
	if best <= 0:
		_record_label.text = "Рекорд волн: —"
	else:
		_record_label.text = "Рекорд волн: %d" % best


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if (event as InputEventKey).keycode == KEY_ESCAPE:
			close_menu()
			get_viewport().set_input_as_handled()


func _panel_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = COL_PANEL
	sb.border_color = COL_BORDER
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(12)
	sb.shadow_color = Color(0, 0, 0, 0.4)
	sb.shadow_size = 10
	return sb


func _style_button(btn: Button) -> void:
	var n := StyleBoxFlat.new()
	n.bg_color = COL_BTN
	n.border_color = COL_BORDER
	n.set_border_width_all(2)
	n.set_corner_radius_all(8)
	n.content_margin_left = 10
	n.content_margin_right = 10
	n.content_margin_top = 6
	n.content_margin_bottom = 6
	var h := n.duplicate() as StyleBoxFlat
	h.bg_color = COL_BTN_HOVER
	var p := n.duplicate() as StyleBoxFlat
	p.bg_color = COL_BTN_PRESS
	btn.add_theme_stylebox_override("normal", n)
	btn.add_theme_stylebox_override("hover", h)
	btn.add_theme_stylebox_override("pressed", p)
	btn.add_theme_color_override("font_color", COL_TEXT)
