extends UnitBase
class_name EnemyVampire
## Hunts player ground troops. Teleports instead of marching. Never attacks the kingdom.
## Cannot hit flyers. Heals for a share of damage dealt.

var _route_step: GameConfig.RouteStep = GameConfig.RouteStep.FAR
var _step_timer: float = GameConfig.ENEMY_VAMPIRE_STEP_INTERVAL


func _ready() -> void:
	faction = GameConfig.Faction.ENEMY
	kind = GameConfig.UnitKind.VAMPIRE
	is_flying = false
	max_hp = GameConfig.ENEMY_VAMPIRE_HP
	damage = GameConfig.ENEMY_VAMPIRE_DAMAGE
	move_speed = GameConfig.ENEMY_VAMPIRE_SPEED
	attack_cooldown = GameConfig.ENEMY_ATTACK_COOLDOWN
	attack_range = GameConfig.MELEE_RANGE + 4.0
	body_color = Color(0.55, 0.12, 0.22, 1.0)
	super._ready()
	position = packed_route_pos(_route_step)


func _tick_ai(delta: float) -> void:
	var target := _nearest_ground_prey()
	if target != null and is_in_attack_range(target.position):
		_target = target
		try_attack_unit(target)
		return

	_try_teleport(delta, target)


func _nearest_ground_prey() -> UnitBase:
	## Prefer same sector, then any ground player unit (no flyers).
	var best: UnitBase = null
	var best_d := INF
	for f in find_enemies(false):
		if f.is_flying:
			continue
		if not can_attack_target(f):
			continue
		var d := position.distance_to(f.position)
		## Prefer prey in home sector slightly.
		if SectorMap.get_sector(f.position) == home_sector:
			d *= 0.85
		if d < best_d:
			best_d = d
			best = f
	return best


func _try_teleport(delta: float, target: UnitBase) -> void:
	if is_movement_frozen():
		return
	_step_timer -= delta
	if _step_timer > 0.0:
		return
	_step_timer = GameConfig.ENEMY_VAMPIRE_STEP_INTERVAL

	var dest: Vector2
	if target != null:
		_face_toward(target.position)
		var to := target.position - position
		var dist := to.length()
		if dist <= 1.0:
			dest = position
		else:
			var leap := mini(GameConfig.ENEMY_VAMPIRE_TELEPORT_RANGE, dist - attack_range * 0.35)
			leap = maxf(leap, mini(dist, 40.0))
			dest = position + to.normalized() * leap
	else:
		## No prey — blink around Mid of home sector, waiting to hunt.
		var hold := packed_route_pos(GameConfig.RouteStep.MID)
		var jitter := Vector2(randf_range(-28.0, 28.0), randf_range(-28.0, 28.0))
		dest = hold + jitter

	dest = SectorMap.clamp_to_playfield(dest)
	position = dest
	_moved_this_frame = true
	_begin_teleport_anim()


func push_outward_one_ring() -> bool:
	var zone := SectorMap.get_zone(position)
	match zone:
		GameConfig.Zone.KINGDOM, GameConfig.Zone.NEAR:
			_route_step = GameConfig.RouteStep.MID
		GameConfig.Zone.MID:
			_route_step = GameConfig.RouteStep.FAR
		_:
			return false
	position = packed_route_pos(_route_step)
	_step_timer = GameConfig.ENEMY_VAMPIRE_STEP_INTERVAL
	_begin_teleport_anim()
	return true
