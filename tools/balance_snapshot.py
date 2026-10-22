#!/usr/bin/env python3
"""Static balance snapshot from current GameConfig / wave formulas."""
from __future__ import annotations

import math

STARTING = 100
KINGDOM_HP = 200
WAVE_CLEAR = 50
BOSS_GOLD = 250
BOSS_HP = 650

# Current game_config.gd values
GOLD = {"inf": 10, "shd": 15, "arc": 11, "fly": 13, "vamp": 16}
HP = {"inf": 50, "shd": 100, "arc": 45, "fly": 40, "vamp": 150, "boss": 650}
DMG = {"inf": 11, "shd": 8, "arc": 9, "fly": 16, "vamp": 12, "boss": 32}


def wave_total(w: int) -> int:
	if w <= 1:
		return 2  # mid of 1–3
	if w <= 4:
		return 2 + w
	return 3 + w


def flyer_n(w: int, total: int) -> int:
	if w < 5:
		return 0
	return min(1 + (w - 5) // 2, total)


def archer_n(w: int, rem: int) -> int:
	if w < 2 or rem <= 1:
		return 0
	if w < 5:
		return min(1, rem - 1)
	return min(1 + (w - 5) // 3, rem - 1)


def vamp_n(w: int, rem: int) -> int:
	if w < 7 or rem <= 0:
		return 0
	return min(1 + (w - 7) // 3, rem)


def shield_n(w: int, ground: int) -> int:
	if w < 3 or ground <= 0:
		return 0
	return min(1 + (w - 3) // 3, ground)


def compose(w: int) -> dict:
	tot = wave_total(w)
	fly = flyer_n(w, tot)
	arc = archer_n(w, tot - fly)
	after = tot - arc - fly
	vamp = vamp_n(w, after)
	ground = after - vamp
	shd = shield_n(w, ground)
	inf = ground - shd
	return {"inf": inf, "shd": shd, "arc": arc, "fly": fly, "vamp": vamp, "tot": tot}


def boss_compose(w: int) -> dict:
	tier = (w - 10) // 5
	escort = 4 + tier
	return {"boss": 1, "fly": escort, "tier": tier}


def hits(hp: int, dmg: int) -> int:
	return math.ceil(hp / max(1, dmg))


def main() -> None:
	print("=== WAVES ===")
	cum = STARTING
	wave_rows = []
	for w in range(1, 21):
		is_boss = w >= 10 and (w - 10) % 5 == 0
		if is_boss:
			c = boss_compose(w)
			g = BOSS_GOLD + c["fly"] * GOLD["fly"] + WAVE_CLEAR
			threat = BOSS_HP + c["tier"] * 100 + c["fly"] * HP["fly"]
			label = f"boss t{c['tier']}+{c['fly']}fly"
			comp = {"inf": 0, "shd": 0, "arc": 0, "fly": c["fly"], "vamp": 0, "boss": 1}
		else:
			c = compose(w)
			g = (
				c["inf"] * GOLD["inf"]
				+ c["shd"] * GOLD["shd"]
				+ c["arc"] * GOLD["arc"]
				+ c["fly"] * GOLD["fly"]
				+ c["vamp"] * GOLD["vamp"]
				+ WAVE_CLEAR
			)
			threat = (
				c["inf"] * HP["inf"]
				+ c["shd"] * HP["shd"]
				+ c["arc"] * HP["arc"]
				+ c["fly"] * HP["fly"]
				+ c["vamp"] * HP["vamp"]
			)
			label = f"i{c['inf']} s{c['shd']} a{c['arc']} f{c['fly']} v{c['vamp']}"
			comp = {**c, "boss": 0}
		cum += g
		wave_rows.append(
			{
				"w": w,
				"label": label,
				"threat": threat,
				"gold": g,
				"cum": cum,
				**comp,
			}
		)
		print(f"W{w:2d}: {label:22s} HP={threat:4d} +{g:3d}g cum={cum}")

	print("\n=== TTK ===")
	ttk_rows = [
		("Пехота → пехота", 50, 20, 1.0),
		("Пехота → щит (×0.5)", 100, 10, 1.0),
		("Лучник → пехота", 50, 15, 1.2),
		("Лучник → щит (×0.2)", 100, 3, 1.2),
		("Лучник → вампир", 150, 15, 1.2),
		("Пехота → вампир", 150, 20, 1.0),
		("Орёл → летун (×1.3)", 40, 26, 1.0),
		("Пехота → босс", 650, 20, 1.0),
	]
	for name, hp, dmg, cd in ttk_rows:
		h = hits(hp, dmg)
		print(f"{name:24s} {h:3d} ударов / {h * cd:5.1f}s")

	print("\n=== NOTES ===")
	print(f"Марш пехоты Far→Near: {2 * 4.5:.1f}s")
	print(f"Марш щита Far→Near: {2 * 6.5:.1f}s")
	print(f"Королевство от 1 пехоты: {math.ceil(KINGDOM_HP / 11) * 2.6:.1f}s")
	print(f"Королевство от 1 босса: {math.ceil(KINGDOM_HP / 32) * 2.6:.1f}s")
	print(f"Gold/HP пехота: {GOLD['inf']/HP['inf']:.3f}")
	print(f"Gold/HP щит: {GOLD['shd']/HP['shd']:.3f}")
	print(f"Gold/HP вампир: {GOLD['vamp']/HP['vamp']:.3f}")
	print(f"Эфф. HP щита vs лучник: {HP['shd']/0.2:.0f} (награда {GOLD['shd']})")

	# Export JSON-ish for canvas embedding
	import json
	out = {
		"waves": wave_rows,
		"ttk": [
			{"name": n, "hits": hits(hp, dmg), "sec": round(hits(hp, dmg) * cd, 1)}
			for n, hp, dmg, cd in ttk_rows
		],
	}
	print("\nJSON_START")
	print(json.dumps(out))
	print("JSON_END")


if __name__ == "__main__":
	main()
