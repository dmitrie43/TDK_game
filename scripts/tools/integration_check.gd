extends SceneTree
## Full gameplay smoke check (uses /root autoloads — works with -s).


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var ok := true
	print("=== INTEGRATION CHECK ===")

	var cfg: Node = root.get_node_or_null("GameConfig")
	var state: Node = root.get_node_or_null("GameState")
	var sfx: Node = root.get_node_or_null("Sfx")
	if cfg == null or state == null or sfx == null:
		print("FAIL autoloads cfg=", cfg, " state=", state, " sfx=", sfx)
		ok = false
		quit(1)
		return
	print("OK autoloads COST_PUSH_WAVE=", cfg.get("COST_PUSH_WAVE"))

	var err := change_scene_to_file("res://scenes/main.tscn")
	if err != OK:
		print("FAIL change_scene ", err)
		quit(1)
		return
	await process_frame
	await process_frame
	await process_frame

	var main := current_scene
	if main == null:
		print("FAIL no current_scene")
		quit(1)
		return
	print("OK main scene")

	var factory: Node = main.get_node_or_null("UnitFactory")
	var recruitment: Node = main.get_node_or_null("Recruitment")
	var hud: Node = main.get_node_or_null("HUD")
	var waves: Node = main.get_node_or_null("WaveManager")
	var world: Node = main.get_node_or_null("World")

	if factory == null or recruitment == null or hud == null or waves == null or world == null:
		print("FAIL core nodes factory=", factory, " recr=", recruitment, " hud=", hud, " waves=", waves, " world=", world)
		ok = false
	else:
		print("OK core nodes")

	if not hud.has_method("setup"):
		print("FAIL HUD.setup missing — script likely failed to compile")
		ok = false
	else:
		print("OK HUD script")
	if not hud.has_method("_on_push_wave"):
		print("FAIL HUD wave button handler missing")
		ok = false
	else:
		print("OK HUD wave handler")

	var sprite_paths: Array = [
		cfg.get("SPRITE_PLAYER_INFANTRY"),
		cfg.get("SPRITE_ENEMY_INFANTRY"),
		cfg.get("SPRITE_KINGDOM"),
		cfg.get("SPRITE_FIELD_GRASS"),
	]
	var GameSpritesScript = load("res://scripts/fx/game_sprites.gd")
	for p in sprite_paths:
		var tex = GameSpritesScript.load_texture(p)
		if tex == null:
			print("FAIL texture ", p)
			ok = false
		else:
			print("OK texture ", String(p).get_file())

	var enemy: Node = factory.call("spawn_enemy_infantry", 0)
	await process_frame
	if enemy == null:
		print("FAIL enemy spawn")
		ok = false
	elif enemy.get("_body_tex") == null:
		print("FAIL enemy sprite tex null")
		ok = false
	else:
		print("OK enemy spawn+sprite")

	if enemy != null and enemy.has_method("push_outward_one_ring"):
		var RouteStep = cfg.get("RouteStep")
		# RouteStep is an enum dict-like from script; use numeric NEAR=2 FAR=0
		enemy.set("_route_step", 2)
		var SectorMapScript = load("res://scripts/world/sector_map.gd")
		enemy.position = SectorMapScript.route_point(0, 2)
		if not enemy.call("push_outward_one_ring"):
			print("FAIL push from NEAR")
			ok = false
		else:
			print("OK push NEAR->outward")

		enemy.set("_route_step", 0)
		enemy.position = SectorMapScript.route_point(0, 0)
		if enemy.call("push_outward_one_ring"):
			print("FAIL Far should stay")
			ok = false
		else:
			print("OK Far stays")

	state.set("gold", 500)
	if not recruitment.call("hire_infantry"):
		print("FAIL hire infantry")
		ok = false
	else:
		print("OK hire infantry")

	state.set("gold", 200)
	var PushWaveScript = load("res://scripts/systems/push_wave.gd")
	var msg: String = PushWaveScript.try_cast(self)
	print("PushWave: ", msg)
	if msg.begins_with("Not enough") or msg == "Game over":
		print("FAIL push cast")
		ok = false
	else:
		print("OK push cast")

	var kingdom: Node = state.get("kingdom")
	if kingdom != null:
		kingdom.set("hp", 100)
		state.set("gold", 200)
		var herr: String = kingdom.call("try_paid_heal")
		if herr != "":
			print("FAIL heal ", herr)
			ok = false
		else:
			print("OK heal hp=", kingdom.get("hp"))
	else:
		print("FAIL no kingdom on GameState")
		ok = false

	state.set("gold", 200)
	recruitment.call("begin_archer_hire")
	if not recruitment.get("pending_archer_hire"):
		print("FAIL archer hire pending")
		ok = false
	else:
		var ok_arc: bool = recruitment.call("confirm_archer_sector", 3)
		print("OK archer hire sector3=", ok_arc)
		if not ok_arc:
			ok = false

	# Upgrades: buy horses + durability; HUD has open handler
	if not hud.has_method("_on_open_upgrades"):
		print("FAIL upgrades button missing")
		ok = false
	else:
		print("OK upgrades HUD hook")
	var Upg = load("res://scripts/systems/upgrades.gd")
	state.set("gold", 500)
	var uerr: String = Upg.try_buy(Upg.ID_INF_HORSES, self)
	if uerr != "":
		print("FAIL buy horses ", uerr)
		ok = false
	else:
		print("OK upgrade horses")
	uerr = Upg.try_buy(Upg.ID_KING_DURABILITY, self)
	if uerr != "":
		print("FAIL buy durability ", uerr)
		ok = false
	else:
		print("OK upgrade durability max=", kingdom.get("max_hp"))
	var base_spd: float = float(cfg.get("PLAYER_INFANTRY_SPEED"))
	var per: float = float(cfg.get("UPG_INF_HORSES_SPEED_PER_LEVEL"))
	var horses_lvl: int = int(state.call("get_upgrade_level", Upg.ID_INF_HORSES))
	var expect_spd: float = base_spd * (1.0 + per * float(horses_lvl))
	for n in get_nodes_in_group("player_units"):
		if n.get("kind") != 0: # UnitKind.INFANTRY
			continue
		var spd: float = float(n.get("move_speed"))
		if absf(spd - expect_spd) > 0.01:
			print("FAIL infantry speed ", spd, " expect ", expect_spd)
			ok = false
		else:
			print("OK infantry speed after horses")
		break

	# Soft wait — wave manager should exist and not crash
	await create_timer(0.5).timeout
	print("OK runtime 0.5s")

	print("=== RESULT: ", "PASS" if ok else "FAIL", " ===")
	quit(0 if ok else 1)
