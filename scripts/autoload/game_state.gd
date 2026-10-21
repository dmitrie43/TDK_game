extends Node
## Runtime state shared across scenes + persistent record / settings.

signal gold_changed(new_amount: int)
signal kingdom_hp_changed(current: int, maximum: int)
signal game_over(victory: bool)
signal unit_hired(kind: GameConfig.UnitKind, sector: int)
signal wave_started(wave_index: int)
## Emitted when a clear starts the between-wave rest (seconds remaining).
signal wave_rest_started(seconds: float)
signal upgrade_purchased(upgrade_id: StringName)
signal best_wave_changed(best: int)
signal cheats_changed(enabled: bool)
## Boss died — HUD opens free ability pick menu.
signal boss_killed
signal boss_reward_chosen(reward_id: StringName)

const SAVE_PATH := "user://kingdom_defense.cfg"
const CHEAT_GOLD_AMOUNT := 1000

var gold: int = GameConfig.STARTING_GOLD:
	set(value):
		gold = maxi(0, value)
		gold_changed.emit(gold)

## sector_index -> player archer instance (max 1 per sector)
var wall_archers: Dictionary = {}

var kingdom: Node2D = null
var sector_map: Node2D = null
var is_game_over: bool = false

## Upgrade levels (StringName id -> int 1…UPGRADE_MAX_LEVEL). Missing = 0.
var upgrades_owned: Dictionary = {}
## Boss reward stacks (StringName id -> int). Missing = 0. Cleared each run.
var boss_rewards: Dictionary = {}

## Highest wave index reached in any run (persisted).
var best_wave: int = 0
## Current run wave (not persisted).
var current_wave: int = 0
## When true, HUD shows cheat buttons (persisted).
var cheats_enabled: bool = false


func _ready() -> void:
	gold = GameConfig.STARTING_GOLD
	load_save()
	wave_started.connect(_on_wave_started_for_record)


func set_cheats_enabled(enabled: bool) -> void:
	if cheats_enabled == enabled:
		return
	cheats_enabled = enabled
	cheats_changed.emit(cheats_enabled)
	save_settings()


func cheat_add_gold() -> void:
	if not cheats_enabled:
		return
	add_gold(CHEAT_GOLD_AMOUNT)


func reset_run() -> void:
	is_game_over = false
	wall_archers.clear()
	upgrades_owned.clear()
	boss_rewards.clear()
	current_wave = 0
	gold = GameConfig.STARTING_GOLD


func get_upgrade_level(upgrade_id: StringName) -> int:
	return int(upgrades_owned.get(upgrade_id, 0))


func has_upgrade(upgrade_id: StringName) -> bool:
	return get_upgrade_level(upgrade_id) > 0


func bump_upgrade_level(upgrade_id: StringName) -> int:
	## +1 level (caller must validate max). Returns new level.
	var lvl := get_upgrade_level(upgrade_id) + 1
	upgrades_owned[upgrade_id] = lvl
	upgrade_purchased.emit(upgrade_id)
	return lvl


func boss_reward_stacks(reward_id: StringName) -> int:
	return int(boss_rewards.get(reward_id, 0))


func has_boss_reward(reward_id: StringName) -> bool:
	return boss_reward_stacks(reward_id) > 0


func add_boss_reward(reward_id: StringName) -> int:
	var n := boss_reward_stacks(reward_id) + 1
	boss_rewards[reward_id] = n
	boss_reward_chosen.emit(reward_id)
	return n


func notify_boss_killed() -> void:
	if is_game_over:
		return
	boss_killed.emit()


func can_afford(cost: int) -> bool:
	return gold >= cost


func try_spend(cost: int) -> bool:
	if not can_afford(cost):
		return false
	gold -= cost
	return true


func add_gold(amount: int) -> void:
	gold += amount


func has_wall_archer(sector: int) -> bool:
	return wall_archers.has(sector) and is_instance_valid(wall_archers[sector])


func register_wall_archer(sector: int, archer: Node) -> void:
	wall_archers[sector] = archer
	unit_hired.emit(GameConfig.UnitKind.ARCHER, sector)


func unregister_wall_archer(sector: int) -> void:
	wall_archers.erase(sector)


func notify_kingdom_hp(current: int, maximum: int) -> void:
	kingdom_hp_changed.emit(current, maximum)
	if current <= 0 and not is_game_over:
		is_game_over = true
		game_over.emit(false)


func _on_wave_started_for_record(wave_index: int) -> void:
	current_wave = wave_index
	if wave_index > best_wave:
		best_wave = wave_index
		best_wave_changed.emit(best_wave)
		save_settings()


func load_save() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(SAVE_PATH)
	if err != OK:
		return
	best_wave = maxi(0, int(cfg.get_value("record", "best_wave", 0)))
	var vol := float(cfg.get_value("settings", "volume", 1.0))
	Sfx.set_volume_linear(vol)
	cheats_enabled = bool(cfg.get_value("settings", "cheats", false))
	best_wave_changed.emit(best_wave)
	cheats_changed.emit(cheats_enabled)


func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.load(SAVE_PATH) # keep other keys if file exists
	cfg.set_value("record", "best_wave", best_wave)
	cfg.set_value("settings", "volume", Sfx.get_volume_linear())
	cfg.set_value("settings", "cheats", cheats_enabled)
	cfg.save(SAVE_PATH)
