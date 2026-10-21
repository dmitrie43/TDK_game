extends UnitBase
class_name EnemyFlyer
## Large birds. Attack player squads only — never the kingdom.
## Spawn from wave 5+. Infantry cannot hit them; player archers can.

var _route_step: GameConfig.RouteStep = GameConfig.RouteStep.FAR


func _ready() -> void:
	faction = GameConfig.Faction.ENEMY
	kind = GameConfig.UnitKind.FLYER
	is_flying = true
	max_hp = GameConfig.ENEMY_FLYER_HP
	damage = GameConfig.ENEMY_FLYER_DAMAGE
	move_speed = GameConfig.ENEMY_FLYER_SPEED
	attack_cooldown = GameConfig.ENEMY_ATTACK_COOLDOWN
	attack_range = GameConfig.MELEE_RANGE + 8.0
	body_color = Color(0.55, 0.4, 0.75, 1.0)
	super._ready()
	position = packed_route_pos(_route_step)


func _tick_ai(delta: float) -> void:
	var target := _nearest_player_squad()
	if target == null:
		## No troops — hover over home Mid, do not touch the kingdom.
		var hold := packed_route_pos(GameConfig.RouteStep.MID)
		if position.distance_to(hold) > 8.0:
			move_toward_point(hold, delta)
		return

	_target = target
	if is_in_attack_range(target.position):
		try_attack_unit(target)
	else:
		move_toward_point(target.position, delta)


func _nearest_player_squad() -> UnitBase:
	## Hunt any player infantry / archer on the field (birds ignore sector walls).
	return nearest_attackable(find_enemies(false))


func push_outward_one_ring() -> bool:
	## Knock toward Far along home sector (same rings as ground troops).
	var zone := SectorMap.get_zone(position)
	match zone:
		GameConfig.Zone.KINGDOM, GameConfig.Zone.NEAR:
			_route_step = GameConfig.RouteStep.MID
		GameConfig.Zone.MID:
			_route_step = GameConfig.RouteStep.FAR
		_:
			return false
	position = packed_route_pos(_route_step)
	return true


func move_toward_point(target: Vector2, delta: float) -> void:
	## Flyers are not clamped to a sector ray — they chase troops across the field.
	if is_movement_frozen():
		return
	var to := target - position
	if to.length() <= 1.0:
		return
	_face_toward(target)
	_moved_this_frame = true
	position += to.normalized() * move_speed * delta
	position = SectorMap.clamp_to_playfield(position)
