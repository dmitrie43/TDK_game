extends Node
class_name UnitFactory
## Spawns coded unit nodes under a container.

const _EnemyFlyer := preload("res://scripts/units/enemy_flyer.gd")
const _EnemyBossKnight := preload("res://scripts/units/enemy_boss_knight.gd")
const _PlayerEagle := preload("res://scripts/units/player_eagle.gd")

@export var container_path: NodePath = ^"../Units"

var _container: Node2D


func _ready() -> void:
	_container = get_node(container_path)


func spawn_enemy_infantry(sector: int, pack_slot: int = 0, pack_total: int = 1) -> UnitBase:
	return _spawn(EnemyInfantry.new(), sector, pack_slot, pack_total)


func spawn_enemy_archer(sector: int, pack_slot: int = 0, pack_total: int = 1) -> UnitBase:
	return _spawn(EnemyArcher.new(), sector, pack_slot, pack_total)


func spawn_player_infantry(sector: int) -> UnitBase:
	## Spawn near kingdom rim on the chosen (random) sector; patrols until enemies appear.
	var pos := SectorMap.clamp_to_sector_ray(Vector2.ZERO, sector, GameConfig.KINGDOM_RADIUS + 20.0)
	var unit := PlayerInfantry.new()
	unit.home_sector = sector
	unit.position = pos
	_container.add_child(unit)
	return unit


func spawn_player_archer(sector: int) -> UnitBase:
	if GameState.has_wall_archer(sector):
		push_warning("Sector %d already has a wall archer" % sector)
		return null
	var unit := PlayerArcher.new()
	unit.home_sector = sector
	unit.position = SectorMap.kingdom_post(sector)
	_container.add_child(unit)
	return unit


func spawn_player_eagle(sector: int) -> UnitBase:
	## Spawn near kingdom rim; flies and patrols like infantry.
	var pos := SectorMap.clamp_to_sector_ray(Vector2.ZERO, sector, GameConfig.KINGDOM_RADIUS + 24.0)
	var unit: UnitBase = _PlayerEagle.new()
	unit.home_sector = sector
	unit.position = pos
	_container.add_child(unit)
	return unit


func spawn_enemy_flyer(sector: int, pack_slot: int = 0, pack_total: int = 1) -> UnitBase:
	return _spawn(_EnemyFlyer.new(), sector, pack_slot, pack_total)


func spawn_enemy_boss_knight(sector: int, pack_slot: int = 0, pack_total: int = 1, tier: int = 0) -> UnitBase:
	var boss: UnitBase = _spawn(_EnemyBossKnight.new(), sector, pack_slot, pack_total)
	## Scale after _ready so repeat bosses (15, 20, …) are stronger.
	var t := maxi(0, tier)
	boss.max_hp = GameConfig.BOSS_KNIGHT_HP + t * GameConfig.BOSS_KNIGHT_HP_PER_TIER
	boss.hp = boss.max_hp
	boss.damage = GameConfig.BOSS_KNIGHT_DAMAGE + t * GameConfig.BOSS_KNIGHT_DAMAGE_PER_TIER
	return boss


func _spawn(unit: UnitBase, sector: int, pack_slot: int = 0, pack_total: int = 1) -> UnitBase:
	unit.home_sector = sector
	unit.pack_slot = pack_slot
	unit.pack_total = maxi(1, pack_total)
	unit.position = SectorMap.spawn_point_packed(sector, unit.pack_slot, unit.pack_total)
	_container.add_child(unit)
	return unit
