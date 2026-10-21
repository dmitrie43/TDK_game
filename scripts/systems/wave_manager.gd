extends Node
class_name WaveManager
## Spawns waves into sectors. Later waves pack more enemies into the same sector.

@export var factory_path: NodePath = ^"../UnitFactory"
@export var auto_start: bool = true

var _factory: UnitFactory
var _wave_index: int = 0
var _timer: float = GameConfig.TIME_BEFORE_FIRST_WAVE
var _running: bool = false
## true while waiting for first wave or WAVE_CLEAR_DELAY after a wipe
var _waiting_to_spawn: bool = true


func _ready() -> void:
	_factory = get_node(factory_path)
	_running = auto_start
	_waiting_to_spawn = true
	_timer = GameConfig.TIME_BEFORE_FIRST_WAVE


func _process(delta: float) -> void:
	if not _running or GameState.is_game_over:
		return

	if _waiting_to_spawn:
		_timer -= delta
		if _timer <= 0.0:
			_start_wave()
		return

	# In an active wave — wait until every enemy is gone, then rest before next spawn.
	if _enemy_count() == 0:
		GameState.add_gold(GameConfig.GOLD_WAVE_CLEAR)
		_waiting_to_spawn = true
		_timer = GameConfig.WAVE_CLEAR_DELAY
		GameState.wave_rest_started.emit(GameConfig.WAVE_CLEAR_DELAY)


func _enemy_count() -> int:
	return get_tree().get_nodes_in_group("enemy_units").size()


func _start_wave() -> void:
	_wave_index += 1
	_waiting_to_spawn = false
	GameState.wave_started.emit(_wave_index)

	if GameConfig.is_boss_knight_wave(_wave_index):
		_spawn_boss_knight_wave()
		return

	var total := _enemy_total_for_wave(_wave_index)
	var flyer_count := _flyer_count_for_wave(_wave_index, total)
	var archer_count := _archer_count_for_wave(_wave_index, total - flyer_count)
	var infantry_count := maxi(0, total - archer_count - flyer_count)

	## Queue of spawn callables — packed into shared sectors by wave.
	var jobs: Array[Callable] = []
	for i in infantry_count:
		jobs.append(_factory.spawn_enemy_infantry)
	for i in archer_count:
		jobs.append(_factory.spawn_enemy_archer)
	for i in flyer_count:
		jobs.append(_factory.spawn_enemy_flyer)
	_spawn_jobs_packed(jobs, _pack_size_for_wave(_wave_index))


func _spawn_boss_knight_wave() -> void:
	## Knight + escort. Tier grows on waves 10, 15, 20, …
	var tier: int = GameConfig.boss_knight_tier(_wave_index)
	var escort: int = GameConfig.BOSS_KNIGHT_FLYER_ESCORT + tier * GameConfig.BOSS_KNIGHT_ESCORT_PER_TIER
	var boss_sector := randi() % GameConfig.SECTOR_COUNT
	_factory.spawn_enemy_boss_knight(boss_sector, 0, 1, tier)
	var jobs: Array[Callable] = []
	for i in escort:
		jobs.append(_factory.spawn_enemy_flyer)
	_spawn_jobs_packed_prefer(jobs, _pack_size_for_wave(_wave_index), boss_sector)


func _pack_size_for_wave(wave: int) -> int:
	## Wave 1→1, 4→2, 7→3, 10→4 … more enemies share one sector over time.
	return maxi(1, 1 + int((wave - 1) / GameConfig.SECTOR_PACK_WAVE_STEP))


func _spawn_jobs_packed(jobs: Array[Callable], pack_size: int) -> void:
	var i := 0
	while i < jobs.size():
		var sector := randi() % GameConfig.SECTOR_COUNT
		var n := mini(pack_size, jobs.size() - i)
		for j in n:
			## slot + total → fan formation so packs don't occupy one pixel.
			jobs[i + j].call(sector, j, n)
		i += n


func _spawn_jobs_packed_prefer(jobs: Array[Callable], pack_size: int, prefer_sector: int) -> void:
	## Fill prefer_sector up to pack_size, then pack the rest normally.
	var i := 0
	var first := mini(pack_size, jobs.size())
	for j in first:
		jobs[j].call(prefer_sector, j, first)
	i = first
	if i >= jobs.size():
		return
	var rest: Array[Callable] = []
	while i < jobs.size():
		rest.append(jobs[i])
		i += 1
	_spawn_jobs_packed(rest, pack_size)


func _enemy_total_for_wave(wave: int) -> int:
	# Wave 1: 1–3. Then gentle growth; mid/late slightly above original easy curve.
	if wave <= 1:
		return randi_range(1, 3)
	if wave <= 4:
		return 2 + wave  # 2→4, 3→5, 4→6
	return 3 + wave  # 5→8, 10→13


func _archer_count_for_wave(wave: int, remaining: int) -> int:
	if wave < 2 or remaining <= 1:
		return 0
	if wave < GameConfig.FLYER_START_WAVE:
		return mini(1, remaining - 1)
	return mini(1 + int((wave - 5) / 3), remaining - 1)


func _flyer_count_for_wave(wave: int, total: int) -> int:
	## Birds from wave 5: at least 1, then grow slowly.
	if wave < GameConfig.FLYER_START_WAVE or total <= 0:
		return 0
	var n := 1 + int((wave - GameConfig.FLYER_START_WAVE) / 2)
	return mini(n, total)


func skip_to_next_wave() -> void:
	## Debug helper: force clear delay to finish immediately.
	if _waiting_to_spawn:
		_timer = 0.0
