extends UnitBase
class_name EnemyBossKnight
## Wave-10 boss: big knight. Marches Far→Mid→Near. Area smash vs player squads.

const _SlamFx := preload("res://scripts/fx/boss_slam_fx.gd")

var _route_step: GameConfig.RouteStep = GameConfig.RouteStep.FAR
var _step_timer: float = GameConfig.ENEMY_STEP_INTERVAL


func _ready() -> void:
	faction = GameConfig.Faction.ENEMY
	kind = GameConfig.UnitKind.BOSS
	is_flying = false
	max_hp = GameConfig.BOSS_KNIGHT_HP
	damage = GameConfig.BOSS_KNIGHT_DAMAGE
	move_speed = GameConfig.ENEMY_INFANTRY_SPEED * 0.85
	attack_cooldown = GameConfig.ENEMY_ATTACK_COOLDOWN
	attack_range = GameConfig.BOSS_AOE_RADIUS
	body_color = Color(0.55, 0.45, 0.35, 1.0)
	super._ready()
	position = packed_route_pos(_route_step)


func _sprite_path() -> String:
	return GameConfig.SPRITE_ENEMY_BOSS_KNIGHT


func _draw() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_draw_body()
	draw_arc(Vector2.ZERO, 22.0, 0.0, TAU, 32, Color(0.95, 0.75, 0.25, 0.9), 2.0, true)
	var ratio := float(hp) / float(maxi(1, max_hp))
	draw_rect(Rect2(Vector2(-18, -28), Vector2(36, 4)), Color(0.1, 0.1, 0.1, 0.85))
	draw_rect(Rect2(Vector2(-18, -28), Vector2(36.0 * ratio, 4)), Color(0.95, 0.55, 0.2, 1.0))


func _update_label() -> void:
	if _label == null:
		return
	_label.position = Vector2(-18, 16)
	_label.size = Vector2(36, 14)
	_label.add_theme_font_size_override("font_size", 10)
	_label.text = "БОСС"


func _tick_ai(delta: float) -> void:
	_try_route_step(delta)

	var engage := _nearest_player_infantry_in_sector()
	if engage != null and position.distance_to(engage.position) <= GameConfig.BOSS_AOE_RADIUS:
		_target = engage
		_try_aoe_slam(false)
		return

	if _route_step == GameConfig.RouteStep.NEAR:
		_try_aoe_slam(true)


func _try_aoe_slam(include_kingdom: bool) -> bool:
	## Smash: damage every player unit in AOE radius (optional kingdom hit).
	if _attack_timer > 0.0:
		return false
	var radius := GameConfig.BOSS_AOE_RADIUS
	var hit := false
	for n in get_tree().get_nodes_in_group("player_units"):
		if not (n is UnitBase):
			continue
		var u := n as UnitBase
		if not can_attack_target(u):
			continue
		if position.distance_to(u.position) > radius:
			continue
		u.take_damage(damage)
		hit = true
	if include_kingdom and GameState.kingdom != null and not GameState.is_game_over:
		GameState.kingdom.take_damage(damage)
		hit = true
	if not hit and not include_kingdom:
		return false
	_attack_timer = attack_cooldown
	_begin_attack_anim()
	_spawn_slam_fx(radius)
	return true


func _spawn_slam_fx(radius: float) -> void:
	var fx := _SlamFx.new()
	fx.setup(radius)
	var parent_node := get_parent()
	if parent_node:
		parent_node.add_child(fx)
		fx.position = position
	else:
		add_child(fx)


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
	if _route_step <= GameConfig.RouteStep.FAR:
		return false
	_route_step = (_route_step - 1) as GameConfig.RouteStep
	position = packed_route_pos(_route_step)
	_step_timer = GameConfig.ENEMY_STEP_INTERVAL
	return true
