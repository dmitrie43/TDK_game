extends Node2D
class_name ArcherProjectile
## Visual arrow shot by archers. Travels toward the target and frees after lifetime.

var _from: Vector2 = Vector2.ZERO
var _to: Vector2 = Vector2.ZERO
var _color: Color = Color(1, 0.9, 0.4, 1)
var _age: float = 0.0
var _lifetime: float = GameConfig.PROJECTILE_LIFETIME


func setup(from: Vector2, to: Vector2, color: Color) -> void:
	_from = from
	_to = to
	_color = color
	position = from
	rotation = (to - from).angle()


func _process(delta: float) -> void:
	_age += delta
	var t := clampf(_age / _lifetime, 0.0, 1.0)
	position = _from.lerp(_to, t)
	modulate.a = 1.0 - t * 0.35
	queue_redraw()
	if _age >= _lifetime:
		queue_free()


func _draw() -> void:
	# Small shaft + tip so the shot reads clearly on the map.
	draw_line(Vector2(-8, 0), Vector2(6, 0), _color, 2.5, true)
	draw_circle(Vector2(6, 0), 3.0, _color)
