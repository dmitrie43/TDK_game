extends Node2D
## Short orange smash ring for boss area attacks.

const LIFE := 0.45

var _radius: float = 70.0
var _age: float = 0.0


func setup(radius: float) -> void:
	_radius = radius


func _process(delta: float) -> void:
	_age += delta
	queue_redraw()
	if _age >= LIFE:
		queue_free()


func _draw() -> void:
	var t := clampf(_age / LIFE, 0.0, 1.0)
	var r := lerpf(_radius * 0.35, _radius, t)
	var alpha := (1.0 - t) * (1.0 - t)
	draw_circle(Vector2.ZERO, r * 0.55, Color(1.0, 0.45, 0.15, alpha * 0.28))
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 48, Color(1.0, 0.7, 0.25, alpha * 0.95), 3.5, true)
