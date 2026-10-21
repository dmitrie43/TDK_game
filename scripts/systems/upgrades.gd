extends RefCounted
class_name Upgrades
## Most upgrades level 1…5. Crossbows & Longsight are once-only unlocks.

const ID_INF_HORSES := &"inf_horses"
const ID_INF_ARMOR := &"inf_armor"
const ID_INF_CROSSBOWS := &"inf_crossbows"
const ID_ARC_BOWS := &"arc_bows"
const ID_ARC_SIGHT := &"arc_sight"
const ID_ARC_FIRE_RATE := &"arc_fire_rate"
const ID_KING_DURABILITY := &"king_durability"
const ID_KING_BUILDERS := &"king_builders"

const CAT_INFANTRY := &"infantry"
const CAT_ARCHERS := &"archers"
const CAT_KINGDOM := &"kingdom"


static func categories() -> Array[Dictionary]:
	return [
		{"id": CAT_INFANTRY, "title": "Пехота"},
		{"id": CAT_ARCHERS, "title": "Лучники"},
		{"id": CAT_KINGDOM, "title": "Королевство"},
	]


static func is_once_only(upgrade_id: StringName) -> bool:
	return upgrade_id == ID_INF_CROSSBOWS or upgrade_id == ID_ARC_SIGHT


static func max_level_of(upgrade_id: StringName) -> int:
	return 1 if is_once_only(upgrade_id) else GameConfig.UPGRADE_MAX_LEVEL


static func upgrades_for(category: StringName) -> Array[Dictionary]:
	var ids: Array[StringName] = []
	match category:
		CAT_INFANTRY:
			ids = [ID_INF_HORSES, ID_INF_ARMOR, ID_INF_CROSSBOWS]
		CAT_ARCHERS:
			ids = [ID_ARC_BOWS, ID_ARC_SIGHT, ID_ARC_FIRE_RATE]
		CAT_KINGDOM:
			ids = [ID_KING_DURABILITY, ID_KING_BUILDERS]
		_:
			return []
	var out: Array[Dictionary] = []
	for id in ids:
		out.append(_def_for(id))
	return out


static func _def_for(upgrade_id: StringName) -> Dictionary:
	var lvl: int = GameState.get_upgrade_level(upgrade_id)
	var max_lvl: int = max_level_of(upgrade_id)
	var maxed: bool = lvl >= max_lvl
	var next_lvl: int = mini(lvl + 1, max_lvl)
	var cost: int = 0 if maxed else cost_for_next_level(upgrade_id)
	return {
		"id": upgrade_id,
		"title": _title(upgrade_id),
		"desc": _desc(upgrade_id, lvl, next_lvl if not maxed else lvl),
		"level": lvl,
		"max_level": max_lvl,
		"cost": cost,
		"maxed": maxed,
		"once_only": is_once_only(upgrade_id),
	}


static func cost_for_next_level(upgrade_id: StringName) -> int:
	var base := _base_cost(upgrade_id)
	if base < 0:
		return -1
	var next_lvl: int = GameState.get_upgrade_level(upgrade_id) + 1
	if next_lvl > max_level_of(upgrade_id):
		return -1
	if is_once_only(upgrade_id):
		return base
	## L1 = base, L2 ≈ 1.55×, L3 ≈ 2.1× … L5 ≈ 3.2×
	return int(round(float(base) * (1.0 + 0.55 * float(next_lvl - 1))))


static func try_buy(upgrade_id: StringName, tree: SceneTree) -> String:
	if GameState.is_game_over:
		return "Игра окончена"
	var lvl: int = GameState.get_upgrade_level(upgrade_id)
	if lvl >= max_level_of(upgrade_id):
		return "Уже куплено" if is_once_only(upgrade_id) else "Макс. уровень"
	var cost := cost_for_next_level(upgrade_id)
	if cost < 0:
		return "Неизвестное улучшение"
	if not GameState.try_spend(cost):
		return "Недостаточно золота"
	GameState.bump_upgrade_level(upgrade_id)
	_apply_world(upgrade_id, tree)
	Sfx.play_hire()
	return ""


static func apply_to_player_unit(unit: UnitBase) -> void:
	if unit == null or unit.faction != GameConfig.Faction.PLAYER:
		return
	if unit.kind == GameConfig.UnitKind.INFANTRY:
		_apply_infantry_stats(unit, false)
	elif unit.kind == GameConfig.UnitKind.ARCHER:
		_apply_archer_stats(unit, false)


static func builders_heal_amount() -> int:
	var lvl: int = GameState.get_upgrade_level(ID_KING_BUILDERS)
	if lvl <= 0:
		return 0
	return GameConfig.UPG_KING_BUILDERS_HEAL_BASE + GameConfig.UPG_KING_BUILDERS_HEAL_PER_LEVEL * lvl


static func _base_cost(upgrade_id: StringName) -> int:
	match upgrade_id:
		ID_INF_HORSES:
			return GameConfig.COST_UPG_INF_HORSES
		ID_INF_ARMOR:
			return GameConfig.COST_UPG_INF_ARMOR
		ID_INF_CROSSBOWS:
			return GameConfig.COST_UPG_INF_CROSSBOWS
		ID_ARC_BOWS:
			return GameConfig.COST_UPG_ARC_BOWS
		ID_ARC_SIGHT:
			return GameConfig.COST_UPG_ARC_SIGHT
		ID_ARC_FIRE_RATE:
			return GameConfig.COST_UPG_ARC_FIRE_RATE
		ID_KING_DURABILITY:
			return GameConfig.COST_UPG_KING_DURABILITY
		ID_KING_BUILDERS:
			return GameConfig.COST_UPG_KING_BUILDERS
		_:
			return -1


static func _title(upgrade_id: StringName) -> String:
	match upgrade_id:
		ID_INF_HORSES:
			return "Лошади"
		ID_INF_ARMOR:
			return "Броня"
		ID_INF_CROSSBOWS:
			return "Арбалеты"
		ID_ARC_BOWS:
			return "Усиленные луки"
		ID_ARC_SIGHT:
			return "Дальнозоркость"
		ID_ARC_FIRE_RATE:
			return "Скорострельность"
		ID_KING_DURABILITY:
			return "Прочность"
		ID_KING_BUILDERS:
			return "Строители"
		_:
			return String(upgrade_id)


static func _desc(upgrade_id: StringName, current_lvl: int, preview_lvl: int) -> String:
	var L: int = maxi(1, preview_lvl)
	match upgrade_id:
		ID_INF_HORSES:
			var pct: int = int(round(GameConfig.UPG_INF_HORSES_SPEED_PER_LEVEL * 100.0 * float(L)))
			return "Скорость пехоты +%d%% (ур.%d)" % [pct, L]
		ID_INF_ARMOR:
			return "Здоровье пехоты +%d (ур.%d)" % [GameConfig.UPG_INF_ARMOR_HP_PER_LEVEL * L, L]
		ID_INF_CROSSBOWS:
			return "Пехота может бить летающих"
		ID_ARC_BOWS:
			return "Урон лучников +%d (ур.%d)" % [GameConfig.UPG_ARC_BOWS_DAMAGE_PER_LEVEL * L, L]
		ID_ARC_SIGHT:
			return "Стрельба по всему сектору (Far→Near)"
		ID_ARC_FIRE_RATE:
			var rate_pct: int = int(round(GameConfig.UPG_ARC_FIRE_RATE_PER_LEVEL * 100.0 * float(L)))
			return "Скорость атаки +%d%% (ур.%d)" % [rate_pct, L]
		ID_KING_DURABILITY:
			return "Прочность королевства +%d за уровень (сейчас ур.%d)" % [
				GameConfig.UPG_KING_DURABILITY_HP_PER_LEVEL, current_lvl
			]
		ID_KING_BUILDERS:
			var heal: int = GameConfig.UPG_KING_BUILDERS_HEAL_BASE + GameConfig.UPG_KING_BUILDERS_HEAL_PER_LEVEL * L
			return "+%d прочности каждые %.0f с (ур.%d)" % [
				heal, GameConfig.UPG_KING_BUILDERS_INTERVAL, L
			]
		_:
			return ""


static func _apply_world(upgrade_id: StringName, tree: SceneTree) -> void:
	match upgrade_id:
		ID_INF_HORSES, ID_INF_ARMOR, ID_INF_CROSSBOWS:
			for n in tree.get_nodes_in_group("player_units"):
				if n is UnitBase:
					var u := n as UnitBase
					if u.kind == GameConfig.UnitKind.INFANTRY and u._alive:
						_apply_infantry_stats(u, true)
		ID_ARC_BOWS, ID_ARC_SIGHT, ID_ARC_FIRE_RATE:
			for n in tree.get_nodes_in_group("player_units"):
				if n is UnitBase:
					var u := n as UnitBase
					if u.kind == GameConfig.UnitKind.ARCHER and u._alive:
						_apply_archer_stats(u, true)
		ID_KING_DURABILITY:
			_apply_kingdom_durability_level_up()
		ID_KING_BUILDERS:
			pass


static func _apply_infantry_stats(unit: UnitBase, live_purchase: bool) -> void:
	var horses: int = GameState.get_upgrade_level(ID_INF_HORSES)
	if horses > 0:
		unit.move_speed = GameConfig.PLAYER_INFANTRY_SPEED * (
			1.0 + GameConfig.UPG_INF_HORSES_SPEED_PER_LEVEL * float(horses)
		)
	else:
		unit.move_speed = GameConfig.PLAYER_INFANTRY_SPEED

	var armor: int = GameState.get_upgrade_level(ID_INF_ARMOR)
	var boss_hp: int = GameState.boss_reward_stacks(&"boss_inf_armor")
	var target_max: int = (
		100
		+ GameConfig.UPG_INF_ARMOR_HP_PER_LEVEL * armor
		+ GameConfig.BOSS_REWARD_INF_HP * boss_hp
	)
	if unit.max_hp != target_max:
		var gain: int = target_max - unit.max_hp
		unit.max_hp = target_max
		if live_purchase and gain > 0:
			unit.hp = mini(unit.max_hp, unit.hp + gain)
		elif not live_purchase:
			unit.hp = unit.max_hp

	var boss_dmg: int = GameState.boss_reward_stacks(&"boss_inf_blades")
	## Crossbows: unlock only — no damage bonus. Boss blades stack.
	unit.damage = 20 + GameConfig.BOSS_REWARD_INF_DAMAGE * boss_dmg


static func _apply_archer_stats(unit: UnitBase, live_purchase: bool = false) -> void:
	var bows: int = GameState.get_upgrade_level(ID_ARC_BOWS)
	var sight: int = GameState.get_upgrade_level(ID_ARC_SIGHT)
	var rate: int = GameState.get_upgrade_level(ID_ARC_FIRE_RATE)
	unit.damage = 15 + GameConfig.UPG_ARC_BOWS_DAMAGE_PER_LEVEL * bows
	if sight > 0:
		unit.attack_range = GameConfig.UPG_ARC_SIGHT_RANGE
	else:
		unit.attack_range = GameConfig.ARCHER_RANGE
	if rate > 0:
		var mult: float = 1.0 + GameConfig.UPG_ARC_FIRE_RATE_PER_LEVEL * float(rate)
		unit.attack_cooldown = GameConfig.ARCHER_COOLDOWN / mult
	else:
		unit.attack_cooldown = GameConfig.ARCHER_COOLDOWN

	var boss_hp: int = GameState.boss_reward_stacks(&"boss_arc_armor")
	var target_max: int = 80 + GameConfig.BOSS_REWARD_ARC_HP * boss_hp
	if unit.max_hp != target_max:
		var gain: int = target_max - unit.max_hp
		unit.max_hp = target_max
		if live_purchase and gain > 0:
			unit.hp = mini(unit.max_hp, unit.hp + gain)
		elif not live_purchase:
			unit.hp = unit.max_hp


static func _apply_kingdom_durability_level_up() -> void:
	var k := GameState.kingdom
	if k == null or not is_instance_valid(k):
		return
	var gain: int = GameConfig.UPG_KING_DURABILITY_HP_PER_LEVEL
	k.max_hp += gain
	k.hp = mini(k.max_hp, k.hp + gain)
	GameState.notify_kingdom_hp(k.hp, k.max_hp)
