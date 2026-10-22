extends Node
class_name Recruitment
## Hires player troops.
## Archers: auto-place (GameConfig.ARCHER_AUTO_PLACE) or manual sector pick.

signal hire_failed(reason: String)
signal hire_succeeded(kind: GameConfig.UnitKind, sector: int)
signal archer_hire_started
signal archer_hire_cancelled

@export var factory_path: NodePath = ^"../UnitFactory"

## Sector used for map hover / debug. Infantry ignores this (random).
var selected_sector: int = 0
## True after pressing Hire Archers — waiting for sector choice (manual mode only).
var pending_archer_hire: bool = false

var _factory: UnitFactory


func _ready() -> void:
	_factory = get_node(factory_path)


func set_selected_sector(sector: int) -> void:
	selected_sector = clampi(sector, 0, GameConfig.SECTOR_COUNT - 1)


func hire_infantry() -> bool:
	if GameState.is_game_over:
		hire_failed.emit("Game over")
		return false
	if not GameState.try_spend(GameConfig.COST_PLAYER_INFANTRY):
		hire_failed.emit("Not enough gold")
		return false
	var sector := randi() % GameConfig.SECTOR_COUNT
	var unit := _factory.spawn_player_infantry(sector)
	if unit == null:
		GameState.add_gold(GameConfig.COST_PLAYER_INFANTRY)
		hire_failed.emit("Spawn failed")
		return false
	GameState.unit_hired.emit(GameConfig.UnitKind.INFANTRY, sector)
	hire_succeeded.emit(GameConfig.UnitKind.INFANTRY, sector)
	Sfx.play_hire()
	return true


func hire_eagle() -> bool:
	if GameState.is_game_over:
		hire_failed.emit("Game over")
		return false
	if not GameState.try_spend(GameConfig.COST_PLAYER_EAGLE):
		hire_failed.emit("Not enough gold")
		return false
	var sector := randi() % GameConfig.SECTOR_COUNT
	var unit := _factory.spawn_player_eagle(sector)
	if unit == null:
		GameState.add_gold(GameConfig.COST_PLAYER_EAGLE)
		hire_failed.emit("Spawn failed")
		return false
	GameState.unit_hired.emit(GameConfig.UnitKind.EAGLE, sector)
	hire_succeeded.emit(GameConfig.UnitKind.EAGLE, sector)
	Sfx.play_hire()
	return true


func hire_healer() -> bool:
	if GameState.is_game_over:
		hire_failed.emit("Game over")
		return false
	if not GameState.try_spend(GameConfig.COST_PLAYER_HEALER):
		hire_failed.emit("Not enough gold")
		return false
	var sector := randi() % GameConfig.SECTOR_COUNT
	var unit := _factory.spawn_player_healer(sector)
	if unit == null:
		GameState.add_gold(GameConfig.COST_PLAYER_HEALER)
		hire_failed.emit("Spawn failed")
		return false
	GameState.unit_hired.emit(GameConfig.UnitKind.HEALER, sector)
	hire_succeeded.emit(GameConfig.UnitKind.HEALER, sector)
	Sfx.play_hire()
	return true


func hire_archer() -> bool:
	## One-click hire: auto sector when ARCHER_AUTO_PLACE, else start sector picker.
	if GameConfig.ARCHER_AUTO_PLACE:
		return hire_archer_auto()
	begin_archer_hire()
	return true


func hire_archer_auto() -> bool:
	if pending_archer_hire:
		cancel_archer_hire()
	var sector := _pick_free_archer_sector()
	if sector < 0:
		hire_failed.emit("Все сектора заняты лучниками")
		return false
	return hire_archer_at(sector)


func _pick_free_archer_sector() -> int:
	var free: Array[int] = []
	for i in GameConfig.SECTOR_COUNT:
		if not GameState.has_wall_archer(i):
			free.append(i)
	if free.is_empty():
		return -1
	return free[randi() % free.size()]


func begin_archer_hire() -> void:
	if GameState.is_game_over:
		hire_failed.emit("Game over")
		return
	if GameConfig.ARCHER_AUTO_PLACE:
		hire_archer_auto()
		return
	pending_archer_hire = true
	archer_hire_started.emit()


func cancel_archer_hire() -> void:
	if not pending_archer_hire:
		return
	pending_archer_hire = false
	archer_hire_cancelled.emit()


func confirm_archer_sector(sector: int) -> bool:
	## Called when player picks a sector from the archer menu (or map click).
	set_selected_sector(sector)
	if not pending_archer_hire:
		return false
	return hire_archer_at(selected_sector)


func hire_archer_at(sector: int) -> bool:
	sector = clampi(sector, 0, GameConfig.SECTOR_COUNT - 1)
	if GameState.is_game_over:
		hire_failed.emit("Game over")
		return false
	if GameState.has_wall_archer(sector):
		hire_failed.emit("Sector %d already has archers" % sector)
		return false
	if not GameState.try_spend(GameConfig.COST_PLAYER_ARCHER):
		hire_failed.emit("Not enough gold")
		return false
	var unit := _factory.spawn_player_archer(sector)
	if unit == null:
		GameState.add_gold(GameConfig.COST_PLAYER_ARCHER)
		hire_failed.emit("Spawn failed")
		return false
	pending_archer_hire = false
	hire_succeeded.emit(GameConfig.UnitKind.ARCHER, sector)
	Sfx.play_hire()
	return true
