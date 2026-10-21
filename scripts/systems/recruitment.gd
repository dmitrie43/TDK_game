extends Node
class_name Recruitment
## Hires player troops. Archers require an explicit sector pick from the menu.

signal hire_failed(reason: String)
signal hire_succeeded(kind: GameConfig.UnitKind, sector: int)
signal archer_hire_started
signal archer_hire_cancelled

@export var factory_path: NodePath = ^"../UnitFactory"

## Sector used for map hover / debug. Infantry ignores this (random).
var selected_sector: int = 0
## True after pressing Hire Archers — waiting for sector choice.
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


func begin_archer_hire() -> void:
	if GameState.is_game_over:
		hire_failed.emit("Game over")
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
