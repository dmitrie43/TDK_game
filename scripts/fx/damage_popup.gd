extends Node2D
class_name DamagePopup
## Floating damage number above a unit. Rises and fades out.

var _label: Label
var _age: float = 0.0
const LIFE := 0.9
const RISE_SPEED := 36.0


func setup(amount: int, color: Color = Color(1.0, 0.85, 0.35, 1.0)) -> void:
	_label = Label.new()
	_label.text = "-%d" % amount
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.position = Vector2(-18, -8)
	_label.size = Vector2(36, 16)
	_label.add_theme_font_size_override("font_size", 14)
	_label.add_theme_color_override("font_color", color)
	_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	_label.add_theme_constant_override("outline_size", 4)
	add_child(_label)


func _process(delta: float) -> void:
	_age += delta
	position.y -= RISE_SPEED * delta
	var t := clampf(_age / LIFE, 0.0, 1.0)
	modulate.a = 1.0 - t
	if _age >= LIFE:
		queue_free()
