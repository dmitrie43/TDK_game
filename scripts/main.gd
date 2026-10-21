extends Node2D
## Root level: wires map clicks to recruitment and centers the camera world.

@onready var world: Node2D = $World
@onready var sector_map: SectorMap = $World/SectorMap
@onready var recruitment: Recruitment = $Recruitment
@onready var hud: CanvasLayer = $HUD


func _ready() -> void:
	# Place world so kingdom is centered on screen.
	var vp := get_viewport_rect().size
	world.position = vp * 0.5
	world.add_to_group("world_root")
	if hud.has_method("setup"):
		hud.call("setup", recruitment)
	else:
		push_error("HUD.setup missing — UI script failed to load")
	sector_map.sector_clicked.connect(_on_sector_clicked)
	GameState.reset_run()


func _on_sector_clicked(sector: int) -> void:
	## During archer hire, map click confirms the sector; otherwise just selects.
	if hud.has_method("select_sector"):
		hud.call("select_sector", sector)


func _unhandled_input(event: InputEvent) -> void:
	# Debug: F1 spawns a flying stub in the selected sector.
	if event is InputEventKey and event.pressed and not event.echo:
		if (event as InputEventKey).keycode == KEY_F1:
			$UnitFactory.spawn_enemy_flyer(recruitment.selected_sector)
