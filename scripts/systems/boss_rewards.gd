extends RefCounted
class_name BossRewards
## Free ability picks after killing a boss (2 random options, choose 1).

const ID_FROST_ARROWS := &"boss_frost_arrows"
const ID_POISON_ARROWS := &"boss_poison_arrows"
const ID_INF_ARMOR := &"boss_inf_armor"
const ID_INF_BLADES := &"boss_inf_blades"
const ID_ARC_ARMOR := &"boss_arc_armor"
const ID_EAG_FEATHERS := &"boss_eag_feathers"
const ID_EAG_BEAKS := &"boss_eag_beaks"

const ALL_IDS: Array[StringName] = [
	ID_FROST_ARROWS,
	ID_POISON_ARROWS,
	ID_INF_ARMOR,
	ID_INF_BLADES,
	ID_ARC_ARMOR,
	ID_EAG_FEATHERS,
	ID_EAG_BEAKS,
]


static func title(id: StringName) -> String:
	match id:
		ID_FROST_ARROWS:
			return "Морозные стрелы"
		ID_POISON_ARROWS:
			return "Ядовитые стрелы"
		ID_INF_ARMOR:
			return "Усиленные доспехи пехоты"
		ID_INF_BLADES:
			return "Заточенные клинки"
		ID_ARC_ARMOR:
			return "Усиленные доспехи лучников"
		ID_EAG_FEATHERS:
			return "Стальные перья"
		ID_EAG_BEAKS:
			return "Смертоносные клювы"
		_:
			return String(id)


static func description(id: StringName) -> String:
	match id:
		ID_FROST_ARROWS:
			return "Лучники замораживают врагов на %.0f с\n(перемещение откладывается)" % GameConfig.BOSS_REWARD_FROST_DURATION
		ID_POISON_ARROWS:
			return "Лучники: яд +%d урона каждые %.0f с" % [
				GameConfig.BOSS_REWARD_POISON_DAMAGE, GameConfig.BOSS_REWARD_POISON_INTERVAL
			]
		ID_INF_ARMOR:
			return "Здоровье пехоты +%d" % GameConfig.BOSS_REWARD_INF_HP
		ID_INF_BLADES:
			return "Урон пехоты +%d" % GameConfig.BOSS_REWARD_INF_DAMAGE
		ID_ARC_ARMOR:
			return "Здоровье лучников +%d" % GameConfig.BOSS_REWARD_ARC_HP
		ID_EAG_FEATHERS:
			return "Здоровье орлов +%d" % GameConfig.BOSS_REWARD_EAG_HP
		ID_EAG_BEAKS:
			return "Урон орлов +%d" % GameConfig.BOSS_REWARD_EAG_DAMAGE
		_:
			return ""


static func pick_two_options() -> Array[StringName]:
	## Prefer not-yet-owned; fill from full list if fewer than 2 remain.
	var fresh: Array[StringName] = []
	for id in ALL_IDS:
		if not GameState.has_boss_reward(id):
			fresh.append(id)
	fresh.shuffle()
	var picks: Array[StringName] = []
	for id in fresh:
		if picks.size() >= 2:
			break
		picks.append(id)
	if picks.size() < 2:
		var pool: Array[StringName] = ALL_IDS.duplicate()
		pool.shuffle()
		for id in pool:
			if picks.size() >= 2:
				break
			if id in picks:
				continue
			picks.append(id)
	return picks


static func try_choose(id: StringName, tree: SceneTree) -> String:
	if GameState.is_game_over:
		return "Игра окончена"
	if not ALL_IDS.has(id):
		return "Неизвестная способность"
	GameState.add_boss_reward(id)
	_apply_world(id, tree)
	Sfx.play_hire()
	return ""


static func _apply_world(id: StringName, tree: SceneTree) -> void:
	var UpgradesScript = load("res://scripts/systems/upgrades.gd")
	match id:
		ID_INF_ARMOR, ID_INF_BLADES:
			for n in tree.get_nodes_in_group("player_units"):
				if n is UnitBase:
					var u := n as UnitBase
					if u.kind == GameConfig.UnitKind.INFANTRY and u._alive:
						var old_max := u.max_hp
						UpgradesScript.apply_to_player_unit(u)
						var gain := u.max_hp - old_max
						if gain > 0:
							u.hp = mini(u.max_hp, u.hp + gain)
		ID_ARC_ARMOR:
			for n in tree.get_nodes_in_group("player_units"):
				if n is UnitBase:
					var u := n as UnitBase
					if u.kind == GameConfig.UnitKind.ARCHER and u._alive:
						var old_max := u.max_hp
						UpgradesScript.apply_to_player_unit(u)
						var gain := u.max_hp - old_max
						if gain > 0:
							u.hp = mini(u.max_hp, u.hp + gain)
		ID_EAG_FEATHERS, ID_EAG_BEAKS:
			for n in tree.get_nodes_in_group("player_units"):
				if n is UnitBase:
					var u := n as UnitBase
					if u.kind == GameConfig.UnitKind.EAGLE and u._alive:
						var old_max := u.max_hp
						UpgradesScript.apply_to_player_unit(u)
						var gain := u.max_hp - old_max
						if gain > 0:
							u.hp = mini(u.max_hp, u.hp + gain)
		_:
			pass
