extends Control
class_name BossRewardMenu
## Pause overlay: pick 1 of 2 random free abilities after a boss kill.

const _BossRewards := preload("res://scripts/systems/boss_rewards.gd")

signal closed

const COL_PANEL := Color(0.12, 0.16, 0.11, 0.96)
const COL_BORDER := Color(0.72, 0.58, 0.28, 1.0)
const COL_TITLE := Color(0.95, 0.86, 0.55, 1.0)
const COL_TEXT := Color(0.88, 0.92, 0.78, 1.0)
const COL_BTN := Color(0.22, 0.3, 0.18, 1.0)
const COL_BTN_HOVER := Color(0.32, 0.42, 0.24, 1.0)
const COL_BTN_PRESS := Color(0.16, 0.22, 0.12, 1.0)
const COL_DIM := Color(0, 0, 0, 0.6)

var _options_box: HBoxContainer
var _status: Label
var _pending: Array[StringName] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	_build_ui()


func open_menu() -> void:
	_pending = _BossRewards.pick_two_options()
	_rebuild_options()
	_status.text = "Выберите одну способность — бесплатно"
	_status.add_theme_color_override("font_color", COL_TEXT)
	visible = true
	get_tree().paused = true


func close_menu() -> void:
	visible = false
	get_tree().paused = false
	closed.emit()


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
	panel.custom_minimum_size = Vector2(560, 280)
	panel.add_theme_stylebox_override("panel", _panel_style())
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 14)
	margin.add_child(root)

	var title := Label.new()
	title.text = "Награда за босса"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", COL_TITLE)
	root.add_child(title)

	_status = Label.new()
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.add_theme_font_size_override("font_size", 13)
	_status.add_theme_color_override("font_color", COL_TEXT)
	root.add_child(_status)

	_options_box = HBoxContainer.new()
	_options_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_options_box.add_theme_constant_override("separation", 16)
	_options_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(_options_box)


func _rebuild_options() -> void:
	for c in _options_box.get_children():
		c.queue_free()
	for id in _pending:
		_options_box.add_child(_make_option_card(id))


func _make_option_card(id: StringName) -> Control:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(240, 160)
	card.add_theme_stylebox_override("panel", _card_style())

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	card.add_child(margin)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	margin.add_child(col)

	var name_l := Label.new()
	name_l.text = _BossRewards.title(id)
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_l.add_theme_font_size_override("font_size", 16)
	name_l.add_theme_color_override("font_color", COL_TITLE)
	col.add_child(name_l)

	var desc := Label.new()
	desc.text = _BossRewards.description(id)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	desc.add_theme_font_size_override("font_size", 12)
	desc.add_theme_color_override("font_color", COL_TEXT)
	col.add_child(desc)

	var btn := Button.new()
	btn.text = "Выбрать"
	btn.custom_minimum_size = Vector2(0, 36)
	_style_button(btn)
	btn.pressed.connect(_on_pick.bind(id))
	col.add_child(btn)
	return card


func _on_pick(id: StringName) -> void:
	var err: String = _BossRewards.try_choose(id, get_tree())
	if not err.is_empty():
		_status.text = err
		_status.add_theme_color_override("font_color", Color(1.0, 0.45, 0.4, 1.0))
		return
	_status.text = "Получено: %s" % _BossRewards.title(id)
	_status.add_theme_color_override("font_color", Color(0.6, 1.0, 0.65, 1.0))
	close_menu()


func _panel_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = COL_PANEL
	sb.border_color = COL_BORDER
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 4
	sb.content_margin_right = 4
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	return sb


func _card_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.18, 0.24, 0.15, 0.95)
	sb.border_color = Color(0.55, 0.48, 0.28, 1.0)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(6)
	return sb


func _style_button(btn: Button) -> void:
	var n := StyleBoxFlat.new()
	n.bg_color = COL_BTN
	n.border_color = COL_BORDER
	n.set_border_width_all(1)
	n.set_corner_radius_all(4)
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
