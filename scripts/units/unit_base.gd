extends Node2D
class_name UnitBase
## Shared combat / movement for player and enemy squads.

signal died(unit: UnitBase)

@export var faction: GameConfig.Faction = GameConfig.Faction.ENEMY
@export var kind: GameConfig.UnitKind = GameConfig.UnitKind.INFANTRY
@export var is_flying: bool = false
@export var max_hp: int = 50
@export var damage: int = 10
@export var move_speed: float = 50.0
@export var attack_cooldown: float = 1.0
@export var attack_range: float = GameConfig.MELEE_RANGE
@export var body_color: Color = Color.WHITE

## Home sector for enemies (they only march in this sector). Player archers are bound to wall sector.
var home_sector: int = 0
## Pack formation: slot within a same-sector group (0..pack_total-1).
var pack_slot: int = 0
var pack_total: int = 1
var hp: int
var _attack_timer: float = 0.0
var _target: Node2D = null
var _alive: bool = true
var _label: Label
## Static body fallback (enemies / missing sheet).
var _body_tex: Texture2D
## Player anim sheet: 4×3 frames of idle / walk / attack.
var _sheet_tex: Texture2D
var _anim_time: float = 0.0
var _attack_anim_left: float = 0.0
var _teleport_anim_left: float = 0.0
var _moved_this_frame: bool = false
var _facing_right: bool = true
## Status from player archer boss-rewards (enemies only).
var _freeze_left: float = 0.0
var _poison_dps: int = 0
var _poison_tick: float = 0.0


func packed_route_pos(step: GameConfig.RouteStep) -> Vector2:
	## Route ring position with pack fan so stacked enemies stay visible.
	return SectorMap.route_point_packed(home_sector, step, pack_slot, pack_total)


func _ready() -> void:
	hp = max_hp
	_load_body_texture()
	_ensure_label()
	add_to_group("units")
	if faction == GameConfig.Faction.PLAYER:
		add_to_group("player_units")
	else:
		add_to_group("enemy_units")
	_update_label()
	queue_redraw()


func _load_body_texture() -> void:
	## Subclasses must set faction/kind/is_flying before calling super._ready().
	var sheet_path := _sheet_path()
	if not sheet_path.is_empty():
		_sheet_tex = GameSprites.load_texture(sheet_path)
		if _sheet_tex == null:
			push_warning("Unit sheet missing: %s" % sheet_path)
	_body_tex = GameSprites.load_texture(_sprite_path())
	if _body_tex == null and _sheet_tex == null:
		push_warning("Unit sprite missing: %s" % _sprite_path())


func _sheet_path() -> String:
	## Animated sheets: player units + enemy infantry/archer/flyer/boss.
	if faction == GameConfig.Faction.PLAYER:
		match kind:
			GameConfig.UnitKind.ARCHER:
				return GameConfig.SPRITE_PLAYER_ARCHER_SHEET
			GameConfig.UnitKind.EAGLE:
				return GameConfig.SPRITE_PLAYER_EAGLE_SHEET
			GameConfig.UnitKind.HEALER:
				return GameConfig.SPRITE_PLAYER_HEALER_SHEET
			_:
				return GameConfig.SPRITE_PLAYER_INFANTRY_SHEET
	if is_flying:
		return GameConfig.SPRITE_ENEMY_FLYER_SHEET
	if kind == GameConfig.UnitKind.BOSS:
		return GameConfig.SPRITE_ENEMY_BOSS_KNIGHT_SHEET
	if kind == GameConfig.UnitKind.ARCHER:
		return GameConfig.SPRITE_ENEMY_ARCHER_SHEET
	if kind == GameConfig.UnitKind.SHIELD:
		return GameConfig.SPRITE_ENEMY_SHIELD_SHEET
	if kind == GameConfig.UnitKind.VAMPIRE:
		return GameConfig.SPRITE_ENEMY_VAMPIRE_SHEET
	if kind == GameConfig.UnitKind.INFANTRY:
		return GameConfig.SPRITE_ENEMY_INFANTRY_SHEET
	return ""


func _sprite_path() -> String:
	if faction == GameConfig.Faction.PLAYER:
		match kind:
			GameConfig.UnitKind.ARCHER:
				return GameConfig.SPRITE_PLAYER_ARCHER
			GameConfig.UnitKind.EAGLE:
				return GameConfig.SPRITE_PLAYER_EAGLE
			GameConfig.UnitKind.HEALER:
				return GameConfig.SPRITE_PLAYER_HEALER
			_:
				return GameConfig.SPRITE_PLAYER_INFANTRY
	if is_flying:
		return GameConfig.SPRITE_ENEMY_FLYER
	if kind == GameConfig.UnitKind.ARCHER:
		return GameConfig.SPRITE_ENEMY_ARCHER
	if kind == GameConfig.UnitKind.SHIELD:
		return GameConfig.SPRITE_ENEMY_SHIELD
	if kind == GameConfig.UnitKind.VAMPIRE:
		return GameConfig.SPRITE_ENEMY_VAMPIRE
	return GameConfig.SPRITE_ENEMY_INFANTRY


func _ensure_label() -> void:
	_label = get_node_or_null("Label") as Label
	if _label == null:
		_label = Label.new()
		_label.name = "Label"
		_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_label.position = Vector2(-14, 12)
		_label.size = Vector2(28, 12)
		_label.add_theme_font_size_override("font_size", 9)
		add_child(_label)


func _draw() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_draw_body()
	if is_flying:
		draw_arc(Vector2.ZERO, 14.0, 0.0, TAU, 24, Color(0.7, 0.85, 1.0, 0.8), 1.5, true)
	if _freeze_left > 0.0:
		draw_arc(Vector2.ZERO, 16.0, 0.0, TAU, 20, Color(0.55, 0.85, 1.0, 0.85), 2.0, true)
	if _poison_dps > 0:
		draw_arc(Vector2.ZERO, 18.0, 0.0, TAU, 20, Color(0.45, 0.9, 0.35, 0.7), 1.5, true)
	var ratio := float(hp) / float(maxi(1, max_hp))
	draw_rect(Rect2(Vector2(-12, -18), Vector2(24, 3)), Color(0.1, 0.1, 0.1, 0.8))
	var bar_col := Color(0.3, 0.85, 0.35, 1.0) if faction == GameConfig.Faction.PLAYER else Color(0.9, 0.35, 0.3, 1.0)
	draw_rect(Rect2(Vector2(-12, -18), Vector2(24.0 * ratio, 3)), bar_col)


func _draw_body() -> void:
	var s := _sprite_scale()
	if _sheet_tex != null:
		var fs := float(GameConfig.UNIT_SHEET_FRAME)
		var sz := Vector2(fs, fs) * s
		var src := _anim_src_rect()
		var dest := Rect2(-sz * 0.5, sz)
		if _facing_right:
			draw_texture_rect_region(_sheet_tex, dest, src)
		else:
			draw_set_transform(Vector2.ZERO, 0.0, Vector2(-1.0, 1.0))
			draw_texture_rect_region(_sheet_tex, dest, src)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		return
	if _body_tex != null:
		var sz2 := _body_tex.get_size() * s
		draw_texture_rect(_body_tex, Rect2(-sz2 * 0.5, sz2), false)
		return
	var r := 18.0 if is_flying else (14.0 if kind == GameConfig.UnitKind.INFANTRY else 12.0)
	draw_circle(Vector2.ZERO, r, body_color)


func _sprite_scale() -> float:
	if _sheet_tex != null:
		if kind == GameConfig.UnitKind.BOSS:
			return GameConfig.BOSS_SHEET_SCALE
		if is_flying:
			return GameConfig.FLYER_SHEET_SCALE
		return GameConfig.PLAYER_SPRITE_SCALE
	if kind == GameConfig.UnitKind.BOSS:
		return GameConfig.BOSS_SPRITE_SCALE
	if is_flying:
		return GameConfig.FLYER_SPRITE_SCALE
	return GameConfig.UNIT_SPRITE_SCALE


func _anim_src_rect() -> Rect2:
	var row := 0
	var fps := GameConfig.ANIM_IDLE_FPS
	if _attack_anim_left > 0.0:
		row = 2
		var t := 1.0 - (_attack_anim_left / GameConfig.ANIM_ATTACK_DURATION)
		var col := clampi(int(t * float(GameConfig.UNIT_SHEET_COLS)), 0, GameConfig.UNIT_SHEET_COLS - 1)
		return GameSprites.sheet_frame_rect(col, row, GameConfig.UNIT_SHEET_FRAME)
	if _teleport_anim_left > 0.0:
		## Vampire blink: row 1 is dissolve / reappear frames.
		row = 1
		var tt := 1.0 - (_teleport_anim_left / GameConfig.ANIM_TELEPORT_DURATION)
		var col_tp := clampi(int(tt * float(GameConfig.UNIT_SHEET_COLS)), 0, GameConfig.UNIT_SHEET_COLS - 1)
		return GameSprites.sheet_frame_rect(col_tp, row, GameConfig.UNIT_SHEET_FRAME)
	if is_flying:
		## Bats always flap (row 1 = flap poses); slightly faster while chasing.
		row = 1
		fps = GameConfig.ANIM_FLAP_FPS if _moved_this_frame else GameConfig.ANIM_IDLE_FPS
	elif _moved_this_frame:
		row = 1
		fps = GameConfig.ANIM_WALK_FPS
	var col2 := int(_anim_time * fps) % GameConfig.UNIT_SHEET_COLS
	return GameSprites.sheet_frame_rect(col2, row, GameConfig.UNIT_SHEET_FRAME)


func _physics_process(delta: float) -> void:
	if not _alive or GameState.is_game_over:
		return
	_moved_this_frame = false
	_attack_timer = maxf(0.0, _attack_timer - delta)
	_attack_anim_left = maxf(0.0, _attack_anim_left - delta)
	_teleport_anim_left = maxf(0.0, _teleport_anim_left - delta)
	_tick_status(delta)
	_tick_ai(delta)
	_anim_time += delta
	queue_redraw()
	_update_label()


func _tick_status(delta: float) -> void:
	if _freeze_left > 0.0:
		_freeze_left = maxf(0.0, _freeze_left - delta)
	if _poison_dps <= 0 or faction != GameConfig.Faction.ENEMY:
		return
	_poison_tick -= delta
	if _poison_tick > 0.0:
		return
	_poison_tick = GameConfig.BOSS_REWARD_POISON_INTERVAL
	take_damage(_poison_dps)


func is_movement_frozen() -> bool:
	return _freeze_left > 0.0


func apply_freeze(duration: float) -> void:
	if faction != GameConfig.Faction.ENEMY or not _alive:
		return
	_freeze_left = maxf(_freeze_left, duration)


func apply_poison(damage_per_tick: int) -> void:
	if faction != GameConfig.Faction.ENEMY or not _alive:
		return
	## Keep the strongest poison aura from archer boss-rewards.
	_poison_dps = maxi(_poison_dps, damage_per_tick)
	if _poison_tick <= 0.0:
		_poison_tick = GameConfig.BOSS_REWARD_POISON_INTERVAL


func _begin_attack_anim() -> void:
	if _sheet_tex == null:
		return
	_attack_anim_left = GameConfig.ANIM_ATTACK_DURATION


func _begin_teleport_anim() -> void:
	if _sheet_tex == null:
		return
	_teleport_anim_left = GameConfig.ANIM_TELEPORT_DURATION


func _tick_ai(_delta: float) -> void:
	pass


func _update_label() -> void:
	if _label == null:
		return
	var tag := "P" if faction == GameConfig.Faction.PLAYER else "E"
	var k := "Inf"
	match kind:
		GameConfig.UnitKind.ARCHER:
			k = "Arc"
		GameConfig.UnitKind.FLYER:
			k = "Fly"
		GameConfig.UnitKind.BOSS:
			k = "Boss"
		GameConfig.UnitKind.EAGLE:
			k = "Eag"
		GameConfig.UnitKind.SHIELD:
			k = "Shd"
		GameConfig.UnitKind.VAMPIRE:
			k = "Vmp"
		GameConfig.UnitKind.HEALER:
			k = "Hea"
		_:
			k = "Inf"
	_label.text = "%s-%s" % [tag, k]


func push_outward_one_ring() -> bool:
	## Knock back one Far/Mid/Near ring away from the kingdom. Default: no-op.
	return false


func take_damage(amount: int) -> void:
	if not _alive:
		return
	if _try_dodge_damage():
		_spawn_dodge_popup()
		return
	hp = maxi(0, hp - amount)
	_spawn_damage_popup(amount)
	if hp <= 0:
		_die()


func receive_heal(amount: int) -> int:
	## Returns actual HP restored (0 if full / dead).
	if not _alive or amount <= 0 or hp >= max_hp:
		return 0
	var before := hp
	hp = mini(max_hp, hp + amount)
	var gained := hp - before
	if gained > 0:
		_spawn_heal_popup(gained)
	return gained


func _try_dodge_damage() -> bool:
	## Eagle maneuverability upgrade: chance to ignore incoming hits.
	if faction != GameConfig.Faction.PLAYER or kind != GameConfig.UnitKind.EAGLE:
		return false
	var lvl: int = GameState.get_upgrade_level(&"eag_maneuver")
	if lvl <= 0:
		return false
	var chance: float = GameConfig.UPG_EAG_MANEUVER_DODGE_PER_LEVEL * float(lvl)
	return randf() < chance


func _spawn_dodge_popup() -> void:
	var popup := DamagePopup.new()
	popup.setup_text("мисс", Color(0.55, 0.85, 1.0, 1.0))
	var parent_node := get_parent()
	if parent_node:
		parent_node.add_child(popup)
		popup.position = position + Vector2(0, -28)
	else:
		add_child(popup)
		popup.position = Vector2(0, -28)


func _spawn_damage_popup(amount: int) -> void:
	var popup := DamagePopup.new()
	var col := Color(1.0, 0.45, 0.35, 1.0) if faction == GameConfig.Faction.PLAYER else Color(1.0, 0.9, 0.35, 1.0)
	popup.setup(amount, col)
	var parent_node := get_parent()
	if parent_node:
		parent_node.add_child(popup)
		popup.position = position + Vector2(0, -28)
	else:
		add_child(popup)
		popup.position = Vector2(0, -28)


func _spawn_heal_popup(amount: int) -> void:
	var popup := DamagePopup.new()
	popup.setup_text("+%d" % amount, Color(0.45, 0.95, 0.55, 1.0))
	var parent_node := get_parent()
	if parent_node:
		parent_node.add_child(popup)
		popup.position = position + Vector2(0, -28)
	else:
		add_child(popup)
		popup.position = Vector2(0, -28)


func _die() -> void:
	_alive = false
	died.emit(self)
	if faction == GameConfig.Faction.ENEMY:
		GameState.add_gold(_kill_gold())
		if kind == GameConfig.UnitKind.BOSS:
			GameState.notify_boss_killed()
	remove_from_group("units")
	remove_from_group("player_units")
	remove_from_group("enemy_units")
	queue_free()


func _kill_gold() -> int:
	match kind:
		GameConfig.UnitKind.ARCHER:
			return GameConfig.GOLD_PER_ENEMY_ARCHER
		GameConfig.UnitKind.FLYER:
			return GameConfig.GOLD_PER_ENEMY_FLYER
		GameConfig.UnitKind.BOSS:
			return GameConfig.GOLD_PER_BOSS_KNIGHT
		GameConfig.UnitKind.SHIELD:
			return GameConfig.GOLD_PER_ENEMY_SHIELD
		GameConfig.UnitKind.VAMPIRE:
			return GameConfig.GOLD_PER_ENEMY_VAMPIRE
		_:
			return GameConfig.GOLD_PER_ENEMY_INFANTRY


func can_attack_target(other: UnitBase) -> bool:
	if other == null or not is_instance_valid(other) or not other._alive:
		return false
	if other.faction == faction:
		return false
	if other.is_flying and kind == GameConfig.UnitKind.VAMPIRE:
		return false
	if other.is_flying and kind == GameConfig.UnitKind.INFANTRY:
		## Player infantry with Crossbows can engage flyers.
		if faction != GameConfig.Faction.PLAYER or not GameState.has_upgrade(&"inf_crossbows"):
			return false
	return true


func is_in_attack_range(target_pos: Vector2) -> bool:
	## target_pos is map-local (same space as position under World/Units).
	return position.distance_to(target_pos) <= attack_range


func try_attack_unit(other: UnitBase) -> bool:
	if _attack_timer > 0.0:
		return false
	if not can_attack_target(other):
		return false
	if not is_in_attack_range(other.position):
		return false
	_face_toward(other.position)
	if kind == GameConfig.UnitKind.ARCHER:
		_spawn_projectile(other.position)
		Sfx.play_arrow()
		if faction == GameConfig.Faction.PLAYER:
			_apply_archer_on_hit(other)
	var dealt := damage
	if kind == GameConfig.UnitKind.EAGLE and other.is_flying:
		dealt = int(round(float(damage) * GameConfig.PLAYER_EAGLE_AIR_DAMAGE_MULT))
	## Shield resists archer fire and softens infantry hits.
	if other.kind == GameConfig.UnitKind.SHIELD:
		if kind == GameConfig.UnitKind.ARCHER:
			dealt = maxi(1, int(round(float(dealt) * GameConfig.ENEMY_SHIELD_ARCHER_DAMAGE_MULT)))
		elif kind == GameConfig.UnitKind.INFANTRY:
			dealt = maxi(1, int(round(float(dealt) * GameConfig.ENEMY_SHIELD_INFANTRY_DAMAGE_MULT)))
	other.take_damage(dealt)
	if kind == GameConfig.UnitKind.VAMPIRE and dealt > 0:
		var heal := maxi(1, int(round(float(dealt) * GameConfig.ENEMY_VAMPIRE_LIFESTEAL)))
		hp = mini(max_hp, hp + heal)
	_attack_timer = attack_cooldown
	_begin_attack_anim()
	return true


func _apply_archer_on_hit(other: UnitBase) -> void:
	if GameState.has_boss_reward(&"boss_frost_arrows"):
		other.apply_freeze(GameConfig.BOSS_REWARD_FROST_DURATION)
	if GameState.has_boss_reward(&"boss_poison_arrows"):
		var stacks := GameState.boss_reward_stacks(&"boss_poison_arrows")
		other.apply_poison(GameConfig.BOSS_REWARD_POISON_DAMAGE * stacks)


func try_attack_kingdom() -> bool:
	if _attack_timer > 0.0:
		return false
	if GameState.kingdom == null:
		return false
	_face_toward(Vector2.ZERO)
	if kind == GameConfig.UnitKind.ARCHER:
		_spawn_projectile(Vector2.ZERO)
		Sfx.play_arrow()
	GameState.kingdom.take_damage(damage)
	_attack_timer = attack_cooldown
	_begin_attack_anim()
	return true


func _spawn_projectile(target_pos: Vector2) -> void:
	var shot := ArcherProjectile.new()
	var col := Color(0.45, 0.85, 1.0, 1.0) if faction == GameConfig.Faction.PLAYER else Color(1.0, 0.75, 0.3, 1.0)
	shot.setup(position, target_pos, col)
	var parent_node := get_parent()
	if parent_node:
		parent_node.add_child(shot)
	else:
		add_child(shot)


func move_toward_point(target: Vector2, delta: float) -> void:
	## target and position are map-local (kingdom at origin). Never leave the playfield.
	if is_movement_frozen():
		return
	var to := target - position
	if to.length() <= 1.0:
		return
	_face_toward(target)
	_moved_this_frame = true
	position += to.normalized() * move_speed * delta
	if faction == GameConfig.Faction.ENEMY:
		position = SectorMap.clamp_to_home_sector(position, home_sector)
	else:
		position = SectorMap.clamp_to_playfield(position)


func _face_toward(target: Vector2) -> void:
	var dx := target.x - position.x
	if absf(dx) > 0.5:
		_facing_right = dx >= 0.0


func find_enemies(prefer_same_sector: bool = false) -> Array[UnitBase]:
	var result: Array[UnitBase] = []
	var group := "player_units" if faction == GameConfig.Faction.ENEMY else "enemy_units"
	for n in get_tree().get_nodes_in_group(group):
		if n is UnitBase and (n as UnitBase)._alive:
			var u := n as UnitBase
			if prefer_same_sector and SectorMap.get_sector(u.position) != home_sector:
				continue
			result.append(u)
	return result


func nearest_attackable(units: Array[UnitBase]) -> UnitBase:
	var best: UnitBase = null
	var best_d := INF
	for u in units:
		if not can_attack_target(u):
			continue
		var d := position.distance_to(u.position)
		if d < best_d:
			best_d = d
			best = u
	return best
