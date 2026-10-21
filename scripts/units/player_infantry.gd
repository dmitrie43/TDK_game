extends UnitBase
class_name PlayerInfantry
## Seeks enemies. Without a target — patrols. Crossbows upgrade allows hitting flyers.

const _Upgrades := preload("res://scripts/systems/upgrades.gd")

var _patrol_target: Vector2 = Vector2.ZERO
var _has_patrol: bool = false


func _ready() -> void:
	faction = GameConfig.Faction.PLAYER
	kind = GameConfig.UnitKind.INFANTRY
	is_flying = false
	max_hp = 100
	damage = 20
	move_speed = GameConfig.PLAYER_INFANTRY_SPEED
	attack_cooldown = GameConfig.MELEE_COOLDOWN
	attack_range = GameConfig.MELEE_RANGE
	body_color = Color(0.25, 0.45, 0.85, 1.0)
	super._ready()
	_Upgrades.apply_to_player_unit(self)


func _tick_ai(delta: float) -> void:
	var foes := find_enemies(false)
	var can_air: bool = GameState.has_upgrade(_Upgrades.ID_INF_CROSSBOWS)
	var flying: Array[UnitBase] = []
	var ground: Array[UnitBase] = []
	for f in foes:
		if f.is_flying:
			if can_air:
				flying.append(f)
		else:
			ground.append(f)

	var target := nearest_attackable(flying) if can_air else null
	if target == null:
		target = nearest_attackable(ground)
	if target == null:
		_patrol(delta)
		return

	_has_patrol = false
	_target = target
	if is_in_attack_range(target.position):
		try_attack_unit(target)
	else:
		move_toward_point(target.position, delta)


func _patrol(delta: float) -> void:
	if not _has_patrol or position.distance_to(_patrol_target) <= 14.0:
		_pick_patrol_point()
	move_toward_point(_patrol_target, delta)


func _pick_patrol_point() -> void:
	## Wander mid-field rings across random sectors (stay out of deep Far clutter).
	var sector := randi() % GameConfig.SECTOR_COUNT
	var r := randf_range(GameConfig.KINGDOM_RADIUS + 28.0, GameConfig.MID_OUTER - 12.0)
	_patrol_target = SectorMap.clamp_to_sector_ray(Vector2.ZERO, sector, r)
	_has_patrol = true
