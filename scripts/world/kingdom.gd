extends Node2D
class_name Kingdom
## Central city. Takes damage when enemies reach the walls (near zone) and attack.
## Castle art is a circular-cropped sprite fitted to the kingdom radius.

signal died

@export var max_hp: int = GameConfig.KINGDOM_MAX_HP

var hp: int
var _sprite: Sprite2D
var _builder_timer: float = 0.0


func _ready() -> void:
	hp = max_hp
	GameState.kingdom = self
	GameState.notify_kingdom_hp(hp, max_hp)
	_ensure_sprite()
	queue_redraw()


func _process(delta: float) -> void:
	## Builders upgrade: passive regen every N seconds.
	if GameState.is_game_over:
		return
	if not GameState.has_upgrade(&"king_builders"):
		return
	if hp >= max_hp:
		_builder_timer = 0.0
		return
	_builder_timer += delta
	if _builder_timer >= GameConfig.UPG_KING_BUILDERS_INTERVAL:
		_builder_timer = 0.0
		var heal_amt: int = preload("res://scripts/systems/upgrades.gd").builders_heal_amount()
		if heal_amt > 0:
			heal(heal_amt)


func _ensure_sprite() -> void:
	_sprite = get_node_or_null("CastleSprite") as Sprite2D
	if _sprite == null:
		_sprite = Sprite2D.new()
		_sprite.name = "CastleSprite"
		add_child(_sprite)
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.texture = GameSprites.load_texture(GameConfig.SPRITE_KINGDOM)
	_fit_sprite_to_circle()


func _fit_sprite_to_circle() -> void:
	if _sprite == null or _sprite.texture == null:
		return
	var tex_size := _sprite.texture.get_size()
	if tex_size.x <= 0.0 or tex_size.y <= 0.0:
		return
	var diameter := (GameConfig.KINGDOM_RADIUS - 4.0) * 2.0
	var s := diameter / maxf(tex_size.x, tex_size.y)
	_sprite.scale = Vector2(s, s)


func _draw() -> void:
	var r := GameConfig.KINGDOM_RADIUS - 4.0
	# Soft fill behind the circular castle art.
	draw_circle(Vector2.ZERO, r, Color(0.32, 0.38, 0.26, 0.9))
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 64, Color(0.85, 0.7, 0.35, 1.0), 3.0, true)


func take_damage(amount: int) -> void:
	if GameState.is_game_over:
		return
	hp = maxi(0, hp - amount)
	Sfx.play_kingdom_hit()
	GameState.notify_kingdom_hp(hp, max_hp)
	queue_redraw()
	if hp <= 0:
		died.emit()


func heal(amount: int) -> void:
	if GameState.is_game_over:
		return
	hp = mini(max_hp, hp + amount)
	GameState.notify_kingdom_hp(hp, max_hp)
	queue_redraw()


func try_paid_heal() -> String:
	## Spend gold to restore HP. Returns empty string on success, else error reason.
	if GameState.is_game_over:
		return "Game over"
	if hp >= max_hp:
		return "Kingdom already at full HP"
	if not GameState.try_spend(GameConfig.COST_KINGDOM_HEAL):
		return "Not enough gold"
	heal(GameConfig.KINGDOM_HEAL_AMOUNT)
	Sfx.play_hire()
	return ""
