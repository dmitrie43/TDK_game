extends UnitBase
class_name PlayerHealer
## Seeks wounded allies and heals them. Never attacks enemies.

const _Upgrades := preload("res://scripts/systems/upgrades.gd")

var heal_amount: int = GameConfig.PLAYER_HEALER_HEAL
var _patrol_target: Vector2 = Vector2.ZERO
var _has_patrol: bool = false


func _ready() -> void:
	faction = GameConfig.Faction.PLAYER
	kind = GameConfig.UnitKind.HEALER
	is_flying = false
	max_hp = GameConfig.PLAYER_HEALER_HP
	damage = 0
	heal_amount = GameConfig.PLAYER_HEALER_HEAL
	move_speed = GameConfig.PLAYER_HEALER_SPEED
	attack_cooldown = GameConfig.PLAYER_HEALER_COOLDOWN
	attack_range = GameConfig.PLAYER_HEALER_RANGE
	body_color = Color(0.35, 0.75, 0.45, 1.0)
	super._ready()
	_Upgrades.apply_to_player_unit(self)


func _tick_ai(delta: float) -> void:
	var wounded := _nearest_wounded_ally()
	if wounded == null:
		_patrol(delta)
		return

	_has_patrol = false
	_target = wounded
	if is_in_attack_range(wounded.position):
		try_heal_unit(wounded)
	else:
		move_toward_point(wounded.position, delta)


func _nearest_wounded_ally() -> UnitBase:
	var best: UnitBase = null
	var best_d := INF
	for n in get_tree().get_nodes_in_group("player_units"):
		if n == self or not (n is UnitBase):
			continue
		var u := n as UnitBase
		if not u._alive or u.hp >= u.max_hp:
			continue
		var d := position.distance_to(u.position)
		if d < best_d:
			best_d = d
			best = u
	return best


func try_heal_unit(other: UnitBase) -> bool:
	if _attack_timer > 0.0:
		return false
	if other == null or not is_instance_valid(other) or not other._alive:
		return false
	if other.faction != GameConfig.Faction.PLAYER:
		return false
	if other.hp >= other.max_hp:
		return false
	if not is_in_attack_range(other.position):
		return false
	_face_toward(other.position)
	var healed := other.receive_heal(heal_amount)
	if healed > 0:
		Sfx.play_heal()
	_attack_timer = attack_cooldown
	_begin_attack_anim()
	return healed > 0


func _patrol(delta: float) -> void:
	if not _has_patrol or position.distance_to(_patrol_target) <= 14.0:
		_pick_patrol_point()
	move_toward_point(_patrol_target, delta)


func _pick_patrol_point() -> void:
	var sector := randi() % GameConfig.SECTOR_COUNT
	var r := randf_range(GameConfig.KINGDOM_RADIUS + 28.0, GameConfig.MID_OUTER - 12.0)
	_patrol_target = SectorMap.clamp_to_sector_ray(Vector2.ZERO, sector, r)
	_has_patrol = true
