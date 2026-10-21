extends UnitBase
class_name EnemyArcher
## Marches Far → Mid along its sector, then shoots from mid.
## Priority: player archers on this sector → otherwise the kingdom.

var _route_step: GameConfig.RouteStep = GameConfig.RouteStep.FAR
var _step_timer: float = GameConfig.ENEMY_STEP_INTERVAL


func _ready() -> void:
	faction = GameConfig.Faction.ENEMY
	kind = GameConfig.UnitKind.ARCHER
	is_flying = false
	max_hp = GameConfig.ENEMY_ARCHER_HP
	damage = GameConfig.ENEMY_ARCHER_DAMAGE
	move_speed = GameConfig.ENEMY_ARCHER_SPEED
	attack_cooldown = GameConfig.ENEMY_ATTACK_COOLDOWN
	attack_range = GameConfig.ARCHER_RANGE
	body_color = Color(0.85, 0.45, 0.2, 1.0)
	super._ready()
	position = packed_route_pos(_route_step)


func _tick_ai(delta: float) -> void:
	# March to mid first — never stop for combat on the way.
	if _route_step < GameConfig.RouteStep.MID:
		_try_route_step(delta)
		return

	# At mid: archers on this sector first; if none — kingdom.
	if GameState.has_wall_archer(home_sector):
		var wall_arc: UnitBase = GameState.wall_archers[home_sector]
		if is_instance_valid(wall_arc) and wall_arc._alive:
			try_attack_unit(wall_arc)
			return

	try_attack_kingdom()


func _try_route_step(delta: float) -> void:
	if _route_step >= GameConfig.RouteStep.MID:
		return
	if is_movement_frozen():
		return
	_step_timer -= delta
	if _step_timer > 0.0:
		return
	_step_timer = GameConfig.ENEMY_STEP_INTERVAL
	_route_step = GameConfig.RouteStep.MID
	position = packed_route_pos(_route_step)


func push_outward_one_ring() -> bool:
	## Mid → Far. Already on Far — stay. (Archers don't use Near.)
	if _route_step <= GameConfig.RouteStep.FAR:
		return false
	_route_step = GameConfig.RouteStep.FAR
	position = packed_route_pos(_route_step)
	_step_timer = GameConfig.ENEMY_STEP_INTERVAL
	return true
