extends UnitBase
class_name PlayerArcher
## Stationed on one sector ray. Shoots own sector at full range;
## also can shoot enemies in ANY sector if they are in Near (close ring).

const _Upgrades := preload("res://scripts/systems/upgrades.gd")

func _ready() -> void:
	faction = GameConfig.Faction.PLAYER
	kind = GameConfig.UnitKind.ARCHER
	is_flying = false
	max_hp = 80
	damage = 15
	move_speed = 0.0
	attack_cooldown = GameConfig.ARCHER_COOLDOWN
	attack_range = GameConfig.ARCHER_RANGE
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


func _pick_target() -> UnitBase:
	## 1) Own sector (flying first). 2) Near-ring enemies in other sectors.
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
