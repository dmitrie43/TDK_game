extends Node2D
class_name SectorMap
## 8 pie sectors × 3 rings (near / mid / far). Kingdom sits at local origin.

signal sector_clicked(sector: int)

@export var show_labels: bool = true

var _hover_sector: int = -1
var _field_tex: Texture2D


func _ready() -> void:
	GameState.sector_map = self
	_field_tex = GameSprites.load_texture(GameConfig.SPRITE_FIELD_GRASS)
	if _field_tex == null:
		push_warning("SectorMap: grass field texture missing")
	queue_redraw()


func _draw() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_draw_world_backdrop()
	_draw_grass_field()
	_draw_ring_overlays()
	_draw_sectors()
	if show_labels:
		_draw_sector_labels()


func _draw_world_backdrop() -> void:
	## Forest-earth surround so the screen isn't default gray around the arena.
	var r := GameConfig.FAR_OUTER
	draw_circle(Vector2.ZERO, r + 900.0, GameConfig.COLOR_WORLD_VOID)
	draw_circle(Vector2.ZERO, r + 36.0, GameConfig.COLOR_WORLD_DIRT)
	## Soft rim between dirt and grass.
	draw_arc(Vector2.ZERO, r + 2.0, 0.0, TAU, 72, Color(0.18, 0.28, 0.14, 0.85), 6.0, true)


func _draw_grass_field() -> void:
	## Circular grass disk (texture clipped to circle — no black square corners).
	var r := GameConfig.FAR_OUTER
	draw_circle(Vector2.ZERO, r, GameConfig.COLOR_FIELD_GRASS)
	if _field_tex == null:
		return
	var pts := PackedVector2Array()
	var uvs := PackedVector2Array()
	var cols := PackedColorArray()
	var steps := 64
	for s in range(steps):
		var a := float(s) / float(steps) * TAU
		var dir := Vector2.from_angle(a)
		pts.append(dir * r)
		## Inscribed circle of the square grass texture (avoids black corners).
		uvs.append(Vector2(0.5, 0.5) + dir * 0.48)
		cols.append(Color.WHITE)
	draw_polygon(pts, cols, uvs, _field_tex)


func _draw_ring_overlays() -> void:
	## Soft band tints so Near / Mid / Far stay readable on the grass.
	draw_circle(Vector2.ZERO, GameConfig.MID_OUTER, Color(0.15, 0.25, 0.1, 0.12))
	draw_circle(Vector2.ZERO, GameConfig.NEAR_OUTER, Color(0.2, 0.28, 0.12, 0.16))
	# Hole under kingdom (castle draws itself).
	draw_circle(Vector2.ZERO, GameConfig.KINGDOM_RADIUS, Color(0.25, 0.3, 0.18, 0.35))

	for rad in [GameConfig.KINGDOM_RADIUS, GameConfig.NEAR_OUTER, GameConfig.MID_OUTER, GameConfig.FAR_OUTER]:
		draw_arc(Vector2.ZERO, rad, 0.0, TAU, 64, Color(0.95, 0.95, 0.75, 0.55), 2.0, true)


func _draw_sectors() -> void:
	for i in GameConfig.SECTOR_COUNT:
		var a0 := sector_start_angle(i)
		var a1 := a0 + GameConfig.SECTOR_ANGLE
		var col := Color(1.0, 1.0, 1.0, 0.0)
		if i == _hover_sector:
			col = Color(0.95, 1.0, 0.55, 0.2)
			_draw_slice(GameConfig.KINGDOM_RADIUS, GameConfig.FAR_OUTER, a0, a1, col)
		# Sector divider
		var p0 := Vector2.from_angle(a0) * GameConfig.KINGDOM_RADIUS
		var p1 := Vector2.from_angle(a0) * GameConfig.FAR_OUTER
		draw_line(p0, p1, Color(0.95, 0.95, 0.8, 0.65), 2.0)


func _draw_slice(r_inner: float, r_outer: float, a0: float, a1: float, color: Color) -> void:
	var pts: PackedVector2Array = []
	var steps := 8
	for s in range(steps + 1):
		var t := float(s) / float(steps)
		var a := lerpf(a0, a1, t)
		pts.append(Vector2.from_angle(a) * r_outer)
	for s in range(steps, -1, -1):
		var t := float(s) / float(steps)
		var a := lerpf(a0, a1, t)
		pts.append(Vector2.from_angle(a) * r_inner)
	draw_colored_polygon(pts, color)


func _draw_sector_labels() -> void:
	for i in GameConfig.SECTOR_COUNT:
		var mid := sector_bisector(i) * ((GameConfig.MID_OUTER + GameConfig.FAR_OUTER) * 0.5)
		draw_string(ThemeDB.fallback_font, mid + Vector2(-6, 4), str(i), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.85, 0.9, 0.7, 0.9))


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var local := to_local(get_global_mouse_position())
		var prev := _hover_sector
		if local.length() <= GameConfig.FAR_OUTER and local.length() >= GameConfig.KINGDOM_RADIUS:
			_hover_sector = get_sector(local)
		else:
			_hover_sector = -1
		if prev != _hover_sector:
			queue_redraw()
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			var local := to_local(get_global_mouse_position())
			if local.length() <= GameConfig.FAR_OUTER and local.length() >= GameConfig.KINGDOM_RADIUS:
				sector_clicked.emit(get_sector(local))


# --- Public API ---

static func sector_start_angle(sector: int) -> float:
	return float(sector) * GameConfig.SECTOR_ANGLE


static func sector_bisector(sector: int) -> Vector2:
	var angle := (float(sector) + 0.5) * GameConfig.SECTOR_ANGLE
	return Vector2.from_angle(angle)


static func get_sector(pos: Vector2) -> int:
	var angle := pos.angle()
	if angle < 0.0:
		angle += TAU
	return int(angle / GameConfig.SECTOR_ANGLE) % GameConfig.SECTOR_COUNT


static func get_zone(pos: Vector2) -> GameConfig.Zone:
	var r := pos.length()
	if r < GameConfig.KINGDOM_RADIUS:
		return GameConfig.Zone.KINGDOM
	if r < GameConfig.NEAR_OUTER:
		return GameConfig.Zone.NEAR
	if r < GameConfig.MID_OUTER:
		return GameConfig.Zone.MID
	if r < GameConfig.FAR_OUTER:
		return GameConfig.Zone.FAR
	return GameConfig.Zone.OUT


static func clamp_to_sector_ray(pos: Vector2, sector: int, radius: float) -> Vector2:
	return sector_bisector(sector) * radius


static func spawn_point(sector: int) -> Vector2:
	## Far edge, center of sector — enemy entry.
	return route_point(sector, GameConfig.RouteStep.FAR)


static func pack_offset(sector: int, slot: int, pack_total: int) -> Vector2:
	## Fan units sideways (and slightly in depth) so packs are readable.
	if pack_total <= 1:
		return Vector2.ZERO
	var bis := sector_bisector(sector)
	var tangent := Vector2(-bis.y, bis.x)
	var centered := float(slot) - (float(pack_total) - 1.0) * 0.5
	## Keep fan inside the 45° wedge (~half-angle 22.5°).
	var spacing := 24.0
	return tangent * centered * spacing + bis * centered * 5.0


static func route_point_packed(
	sector: int, step: GameConfig.RouteStep, slot: int = 0, pack_total: int = 1
) -> Vector2:
	return clamp_to_playfield(route_point(sector, step) + pack_offset(sector, slot, pack_total))


static func spawn_point_packed(sector: int, slot: int = 0, pack_total: int = 1) -> Vector2:
	return route_point_packed(sector, GameConfig.RouteStep.FAR, slot, pack_total)


static func wall_point(sector: int) -> Vector2:
	## Legacy wall post (near ring). Prefer kingdom_post for player archers.
	return clamp_to_sector_ray(Vector2.ZERO, sector, GameConfig.NEAR_OUTER - 8.0)


static func kingdom_post(sector: int) -> Vector2:
	## Player archer post: on sector ray inside the kingdom radius.
	return clamp_to_sector_ray(Vector2.ZERO, sector, GameConfig.KINGDOM_RADIUS * 0.55)


static func mid_hold_point(sector: int) -> Vector2:
	## Mid ring hold — enemy archers shoot from here.
	return route_point(sector, GameConfig.RouteStep.MID)


static func route_point(sector: int, step: GameConfig.RouteStep) -> Vector2:
	## Canonical Far → Mid → Near points on the sector bisector (map-local coords).
	match step:
		GameConfig.RouteStep.FAR:
			## Center of the far ring — spawn / start of march.
			return clamp_to_sector_ray(Vector2.ZERO, sector, (GameConfig.MID_OUTER + GameConfig.FAR_OUTER) * 0.5)
		GameConfig.RouteStep.MID:
			return clamp_to_sector_ray(Vector2.ZERO, sector, (GameConfig.NEAR_OUTER + GameConfig.MID_OUTER) * 0.5)
		GameConfig.RouteStep.NEAR:
			return clamp_to_sector_ray(Vector2.ZERO, sector, (GameConfig.KINGDOM_RADIUS + GameConfig.NEAR_OUTER) * 0.5)
		_:
			return clamp_to_sector_ray(Vector2.ZERO, sector, (GameConfig.MID_OUTER + GameConfig.FAR_OUTER) * 0.5)


static func clamp_to_playfield(pos: Vector2) -> Vector2:
	## Keep anyone inside the outer sector ring (playfield = sectors).
	var r := pos.length()
	if r <= 0.001:
		return pos
	if r > GameConfig.FAR_OUTER - 12.0:
		return pos.normalized() * (GameConfig.FAR_OUTER - 12.0)
	return pos


static func clamp_to_home_sector(pos: Vector2, sector: int) -> Vector2:
	## Project onto the sector bisector and keep inside the playfield.
	var r := clampf(pos.length(), 0.0, GameConfig.FAR_OUTER - 12.0)
	return sector_bisector(sector) * r


static func is_same_sector(a: Vector2, b: Vector2) -> bool:
	return get_sector(a) == get_sector(b)
