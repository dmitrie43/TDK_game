extends UnitBase
class_name EnemyInfantry
## Marches Far → Mid → Near along its sector to the kingdom.
## Ignores player archers. May melee player infantry only if already in range.

var _route_step: GameConfig.RouteStep = GameConfig.RouteStep.FAR
var _step_timer: float = GameConfig.ENEMY_STEP_INTERVAL


func _ready() -> void:
	faction = GameConfig.Faction.ENEMY
	kind = GameConfig.UnitKind.INFANTRY
	is_flying = false
	max_hp = GameConfig.ENEMY_INFANTRY_HP
	damage = GameConfig.ENEMY_INFANTRY_DAMAGE
	move_speed = GameConfig.ENEMY_INFANTRY_SPEED
	attack_cooldown = GameConfig.ENEMY_ATTACK_COOLDOWN
	attack_range = GameConfig.MELEE_RANGE
	body_color = Color(0.75, 0.25, 0.22, 1.0)
	super._ready()
	position = packed_route_pos(_route_step)


func _tick_ai(delta: float) -> void:
	# Always march toward the kingdom (do not freeze because of archers).
	_try_route_step(delta)

	# Ignore archers. Only fight player infantry already in melee range.
	var engage := _nearest_player_infantry_in_sector()
	if engage != null and is_in_attack_range(engage.position):
		_target = engage
		try_attack_unit(engage)
		return

	if _route_step == GameConfig.RouteStep.NEAR:
		try_attack_kingdom()


func _nearest_player_infantry_in_sector() -> UnitBase:
	var best: UnitBase = null
	var best_d := INF
	for f in find_enemies(true):
		if f.is_flying:
			continue
		if f.kind == GameConfig.UnitKind.ARCHER:
			continue
		if not can_attack_target(f):
			continue
		var d := position.distance_to(f.position)
		if d < best_d:
			best_d = d
			best = f
	return best


func _try_route_step(delta: float) -> void:
	if _route_step >= GameConfig.RouteStep.NEAR:
		return
	if is_movement_frozen():
		return
	_step_timer -= delta
	if _step_timer > 0.0:
		return
	_step_timer = GameConfig.ENEMY_STEP_INTERVAL
	_route_step = (_route_step + 1) as GameConfig.RouteStep
	position = packed_route_pos(_route_step)


func push_outward_one_ring() -> bool:
	## Near → Mid → Far. Already on Far — stay.
	if _route_step <= GameConfig.RouteStep.FAR:
		return false
	_route_step = (_route_step - 1) as GameConfig.RouteStep
	position = packed_route_pos(_route_step)
	_step_timer = GameConfig.ENEMY_STEP_INTERVAL
	return true
