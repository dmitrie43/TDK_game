extends Control
class_name UpgradeMenu
## Full-screen pause overlay: category list left, upgrades right.

const _Upgrades := preload("res://scripts/systems/upgrades.gd")

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

var _selected_category: StringName = _Upgrades.CAT_INFANTRY
var _cat_box: VBoxContainer
var _upg_box: VBoxContainer
var _status: Label
var _gold_label: Label
var _cat_buttons: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	_build_ui()
	GameState.gold_changed.connect(_on_gold)
	GameState.upgrade_purchased.connect(func(_id: StringName) -> void: _refresh_upgrades())


func open_menu() -> void:
	visible = true
	_selected_category = _Upgrades.CAT_INFANTRY
	_on_gold(GameState.gold)
	_refresh_categories()
	_refresh_upgrades()
	_status.text = "Выберите войско или королевство"
	_status.add_theme_color_override("font_color", COL_TEXT)
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
	panel.custom_minimum_size = Vector2(640, 360)
	panel.add_theme_stylebox_override("panel", _panel_style())
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	margin.add_child(root)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	root.add_child(header)

	var title := Label.new()
	title.text = "Улучшения"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", COL_TITLE)
	header.add_child(title)

	_gold_label = Label.new()
	_gold_label.add_theme_font_size_override("font_size", 14)
	_gold_label.add_theme_color_override("font_color", COL_GOLD)
	header.add_child(_gold_label)

	var btn_close := Button.new()
	btn_close.text = "Закрыть"
	btn_close.custom_minimum_size = Vector2(100, 32)
	_style_button(btn_close)
	btn_close.pressed.connect(close_menu)
	header.add_child(btn_close)

	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 14)
	root.add_child(columns)

	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(180, 0)
	left.add_theme_constant_override("separation", 6)
	columns.add_child(left)

	var left_title := Label.new()
	left_title.text = "Кто"
	left_title.add_theme_color_override("font_color", COL_TEXT)
	left.add_child(left_title)

	_cat_box = VBoxContainer.new()
	_cat_box.add_theme_constant_override("separation", 6)
	left.add_child(_cat_box)

	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 6)
	columns.add_child(right)

	var right_title := Label.new()
	right_title.text = "Улучшения"
	right_title.add_theme_color_override("font_color", COL_TEXT)
	right.add_child(right_title)

	_upg_box = VBoxContainer.new()
	_upg_box.add_theme_constant_override("separation", 8)
	right.add_child(_upg_box)

	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.add_theme_font_size_override("font_size", 12)
	_status.add_theme_color_override("font_color", COL_TEXT)
	root.add_child(_status)


func _refresh_categories() -> void:
	for c in _cat_box.get_children():
		c.queue_free()
	_cat_buttons.clear()
	for cat in _Upgrades.categories():
		var id: StringName = cat["id"]
		var b := Button.new()
		b.text = str(cat["title"])
		b.custom_minimum_size = Vector2(0, 36)
		_style_button(b)
		if id == _selected_category:
			b.add_theme_color_override("font_color", COL_GOLD)
		b.pressed.connect(_on_category.bind(id))
		_cat_box.add_child(b)
		_cat_buttons[id] = b


func _refresh_upgrades() -> void:
	for c in _upg_box.get_children():
		c.queue_free()
	for def in _Upgrades.upgrades_for(_selected_category):
		_upg_box.add_child(_make_upgrade_row(def))


func _make_upgrade_row(def: Dictionary) -> Control:
	var id: StringName = def["id"]
	var lvl: int = int(def.get("level", 0))
	var max_lvl: int = int(def.get("max_level", 5))
	var maxed: bool = bool(def.get("maxed", false))
	var once_only: bool = bool(def.get("once_only", false))
	var row := PanelContainer.new()
	row.add_theme_stylebox_override("panel", _row_style())

	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	row.add_child(h)

	var texts := VBoxContainer.new()
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(texts)

	var title := Label.new()
	if once_only:
		title.text = str(def["title"])
	else:
		title.text = "%s  ·  ур.%d/%d" % [str(def["title"]), lvl, max_lvl]
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", COL_TITLE)
	texts.add_child(title)

	var desc := Label.new()
	desc.text = str(def["desc"])
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 12)
	desc.add_theme_color_override("font_color", COL_TEXT)
	texts.add_child(desc)

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(120, 40)
	if maxed:
		btn.text = "Куплено" if once_only else "Макс."
		btn.disabled = true
	elif once_only:
		btn.text = "%d зол." % int(def["cost"])
		btn.disabled = GameState.is_game_over
	else:
		btn.text = "Ур.%d · %d" % [lvl + 1, int(def["cost"])]
		btn.disabled = GameState.is_game_over
	_style_button(btn)
	btn.pressed.connect(_on_buy.bind(id))
	h.add_child(btn)
	return row


func _on_category(category: StringName) -> void:
	_selected_category = category
	_refresh_categories()
	_refresh_upgrades()
	_status.text = ""
	_status.add_theme_color_override("font_color", COL_TEXT)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if (event as InputEventKey).keycode == KEY_ESCAPE:
			close_menu()
			get_viewport().set_input_as_handled()


func _on_buy(upgrade_id: StringName) -> void:
	var err: String = _Upgrades.try_buy(upgrade_id, get_tree())
	if err != "":
		_status.text = err
		_status.add_theme_color_override("font_color", Color(1.0, 0.5, 0.4, 1))
		return
	if _Upgrades.is_once_only(upgrade_id):
		_status.text = "Куплено"
	else:
		_status.text = "Улучшено до ур.%d" % GameState.get_upgrade_level(upgrade_id)
	_status.add_theme_color_override("font_color", Color(0.6, 1.0, 0.65, 1))
	_refresh_upgrades()


func _on_gold(amount: int) -> void:
	if _gold_label:
		_gold_label.text = "Золото: %d" % amount


func _panel_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = COL_PANEL
	sb.border_color = COL_BORDER
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(12)
	sb.shadow_color = Color(0, 0, 0, 0.4)
	sb.shadow_size = 10
	return sb


func _row_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.18, 0.24, 0.15, 0.95)
	sb.border_color = Color(0.45, 0.4, 0.25, 1.0)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
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
	var d := n.duplicate() as StyleBoxFlat
	d.bg_color = Color(0.18, 0.2, 0.16, 0.7)
	btn.add_theme_stylebox_override("normal", n)
	btn.add_theme_stylebox_override("hover", h)
	btn.add_theme_stylebox_override("pressed", p)
	btn.add_theme_stylebox_override("disabled", d)
	btn.add_theme_color_override("font_color", COL_TEXT)
	btn.add_theme_color_override("font_disabled_color", Color(0.55, 0.55, 0.5, 1))
