extends RefCounted
class_name PushWave
## Spend gold to knock every enemy one ring outward (Far stays put).

const _ShockwaveScript := preload("res://scripts/fx/shockwave_fx.gd")


static func try_cast(tree: SceneTree) -> String:
	if GameState.is_game_over:
		return "Game over"
	if not GameState.try_spend(GameConfig.COST_PUSH_WAVE):
		return "Not enough gold"

	var moved := 0
	for n in tree.get_nodes_in_group("enemy_units"):
		if n is UnitBase and (n as UnitBase)._alive:
			if (n as UnitBase).push_outward_one_ring():
				moved += 1

	_spawn_fx(tree)
	Sfx.play_wave()
	if moved == 0:
		return "Толчок! (враги уже на дальней части)"
	return "Толчок! Отброшено: %d" % moved


static func _spawn_fx(tree: SceneTree) -> void:
	var fx: Node2D = _ShockwaveScript.new()
	var world: Node = tree.get_first_node_in_group("world_root")
	if world == null:
		var main := tree.current_scene
		if main != null and main.has_node("World"):
			world = main.get_node("World")
	if world != null:
		world.add_child(fx)
	elif tree.current_scene != null:
		tree.current_scene.add_child(fx)
