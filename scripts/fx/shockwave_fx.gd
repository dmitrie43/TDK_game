extends Node2D
class_name ShockwaveFx
## Expanding ring blast from the kingdom — visual for the push-wave ability.

const LIFE := 0.85


var _age: float = 0.0


func _process(delta: float) -> void:
	_age += delta
	queue_redraw()
	if _age >= LIFE:
		queue_free()


func _draw() -> void:
	var t := clampf(_age / LIFE, 0.0, 1.0)
	var r := lerpf(GameConfig.KINGDOM_RADIUS * 0.4, GameConfig.FAR_OUTER + 20.0, t)
	var alpha := (1.0 - t) * (1.0 - t)
	# Outer shock front
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 72, Color(0.55, 0.85, 1.0, alpha * 0.95), 5.0, true)
	# Inner echo
	var r2 := maxf(8.0, r * 0.72)
	draw_arc(Vector2.ZERO, r2, 0.0, TAU, 64, Color(0.9, 0.97, 1.0, alpha * 0.55), 2.5, true)
	# Soft fill flash early on
	if t < 0.35:
		var flash := (1.0 - t / 0.35) * 0.22
		draw_circle(Vector2.ZERO, r * 0.55, Color(0.7, 0.9, 1.0, flash))
