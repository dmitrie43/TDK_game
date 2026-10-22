extends UnitBase
class_name PlayerArcher
## Stationed on a kingdom wall post (home_sector).
## Global mode (ARCHER_FIRE_ALL_SECTORS): all sectors, Near+Mid; Far needs Longsight.
## Legacy mode: own sector (+ Near exception in other sectors).

const _Upgrades := preload("res://scripts/systems/upgrades.gd")


func _ready() -> void:
	faction = GameConfig.Faction.PLAYER
	kind = GameConfig.UnitKind.ARCHER
	is_flying = false
	max_hp = GameConfig.PLAYER_ARCHER_HP
	damage = GameConfig.PLAYER_ARCHER_DAMAGE
	move_speed = 0.0
	attack_cooldown = GameConfig.ARCHER_COOLDOWN
	attack_range = GameConfig.player_archer_base_range()
	body_color = Color(0.3, 0.7, 0.9, 1.0)
	super._ready()
	_Upgrades.apply_to_player_unit(self)
	GameState.register_wall_archer(home_sector, self)
	tree_exiting.connect(_on_tree_exiting)


func _on_tree_exiting() -> void:
	if GameState.has_wall_archer(home_sector) and GameState.wall_archers[home_sector] == self:
		GameState.unregister_wall_archer(home_sector)


func _tick_ai(_delta: float) -> void:
	position = SectorMap.kingdom_post(home_sector)
	var target := _pick_target()
	if target != null and is_in_attack_range(target.position):
		try_attack_unit(target)


func _has_longsight() -> bool:
	return GameState.has_upgrade(&"arc_sight")


func _pick_target() -> UnitBase:
	if GameConfig.ARCHER_FIRE_ALL_SECTORS:
		return _pick_global_target()
	return _pick_sector_local_target()


func _can_engage_position(pos: Vector2) -> bool:
	## Ring gate (Near/Mid always; Far with Longsight) + Euclidean attack_range.
	if not is_in_attack_range(pos):
		return false
	if not GameConfig.ARCHER_FIRE_ALL_SECTORS:
		return true
	return GameConfig.archer_can_engage_zone(SectorMap.get_zone(pos), _has_longsight())


func _pick_global_target() -> UnitBase:
	## All sectors; rings: Near+Mid (base), Far with Longsight. Prefer flyers.
	var flying: Array[UnitBase] = []
	var ground: Array[UnitBase] = []
	for f in find_enemies(false):
		if not _can_engage_position(f.position):
			continue
		if f.is_flying:
			flying.append(f)
		else:
			ground.append(f)
	var t := nearest_attackable(flying)
	if t != null:
		return t
	return nearest_attackable(ground)


func _pick_sector_local_target() -> UnitBase:
	## Legacy: own sector first; Near-ring enemies in other sectors as fallback.
	var same_flying: Array[UnitBase] = []
	var same_ground: Array[UnitBase] = []
	for f in find_enemies(true):
		if f.is_flying:
			same_flying.append(f)
		else:
			same_ground.append(f)

	var t := nearest_attackable(same_flying)
	if t != null and is_in_attack_range(t.position):
		return t
	t = nearest_attackable(same_ground)
	if t != null and is_in_attack_range(t.position):
		return t

	var near_flying: Array[UnitBase] = []
	var near_ground: Array[UnitBase] = []
	for f in find_enemies(false):
		if SectorMap.get_sector(f.position) == home_sector:
			continue
		if not _is_close_ring(f.position):
			continue
		if f.is_flying:
			near_flying.append(f)
		else:
			near_ground.append(f)

	t = nearest_attackable(near_flying)
	if t != null and is_in_attack_range(t.position):
		return t
	t = nearest_attackable(near_ground)
	if t != null and is_in_attack_range(t.position):
		return t
	return null


func _is_close_ring(pos: Vector2) -> bool:
	var zone := SectorMap.get_zone(pos)
	return zone == GameConfig.Zone.NEAR or zone == GameConfig.Zone.KINGDOM
