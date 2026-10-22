extends SceneTree
## Headless smoke: hire healer, apply upgrades, heal wounded ally.
## godot --headless -s res://scripts/tools/test_healer.gd


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== HEALER SMOKE ===")
	var state: Node = root.get_node_or_null("GameState")
	var cfg: Node = root.get_node_or_null("GameConfig")
	if state == null or cfg == null:
		print("FAIL autoloads")
		quit(1)
		return

	var err := change_scene_to_file("res://scenes/main.tscn")
	if err != OK:
		print("FAIL change_scene")
		quit(1)
		return
	await process_frame
	await process_frame
	await process_frame

	var main := current_scene
	state.call("add_gold", 5000)
	var factory: Node = main.get_node("UnitFactory")
	var recr: Node = main.get_node("Recruitment")

	if not bool(recr.call("hire_healer")):
		print("FAIL hire_healer")
		quit(1)
		return

	var healer: Node = null
	for n in get_nodes_in_group("player_units"):
		var scr: Script = n.get_script()
		if scr and String(scr.resource_path).ends_with("player_healer.gd"):
			healer = n
			break
	if healer == null:
		print("FAIL no healer spawned")
		quit(1)
		return

	var ally: Node = factory.call("spawn_player_infantry", 0)
	ally.set("hp", 20)
	ally.set("max_hp", 100)
	healer.position = ally.position
	healer.set("_attack_timer", 0.0)
	var ok: bool = bool(healer.call("try_heal_unit", ally))
	var hp_after: int = int(ally.get("hp"))
	if not ok or hp_after != 35:
		print("FAIL heal got hp=%d ok=%s amount=%s" % [hp_after, ok, healer.get("heal_amount")])
		quit(1)
		return

	state.call("bump_upgrade_level", &"hea_herbs")
	var Upg = load("res://scripts/systems/upgrades.gd")
	Upg.apply_to_player_unit(healer)
	if int(healer.get("heal_amount")) != 18:
		print("FAIL herbs heal_amount=%s want 18" % healer.get("heal_amount"))
		quit(1)
		return

	state.call("bump_upgrade_level", &"hea_hands")
	Upg.apply_to_player_unit(healer)
	var want_cd: float = float(cfg.get("PLAYER_HEALER_COOLDOWN")) / 1.2
	var got_cd: float = float(healer.get("attack_cooldown"))
	if absf(got_cd - want_cd) > 0.01:
		print("FAIL hands cd=%s want %s" % [got_cd, want_cd])
		quit(1)
		return

	print("OK healer smoke: heal=%s cd=%.3f" % [healer.get("heal_amount"), got_cd])
	quit(0)
