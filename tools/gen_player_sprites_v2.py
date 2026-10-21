#!/usr/bin/env python3
"""Build detailed player spritesheets from generated reference poses."""
from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageEnhance

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "units"
TMP = OUT / "_tmp"
REF = Path(r"C:\Users\Дмитрий\.cursor\projects\c-OwnGames-TDK\assets")

FW = 48
COLS, ROWS = 4, 3


def _is_bg(r: int, g: int, b: int, mode: str) -> bool:
	"""Strict bg key — do not eat dark brown armor / boots."""
	lum = (r + g + b) / 3.0
	chroma = max(abs(r - g), abs(g - b), abs(r - b))
	if mode == "dark":
		# Only near-black neutrals (studio void), keep dark clothing (chroma or brown).
		return lum < 18 and chroma < 12
	if mode == "light":
		return lum > 225 or (chroma < 12 and lum > 200)
	if lum < 18 and chroma < 12:
		return True
	if chroma < 10 and lum > 210:
		return True
	return False


def extract_character(path: Path, bg_mode: str = "auto", pad: float = 0.08) -> Image.Image:
	im = Image.open(path).convert("RGBA")
	px = im.load()
	w, h = im.size
	for y in range(h):
		for x in range(w):
			r, g, b, _a = px[x, y]
			if _is_bg(r, g, b, bg_mode):
				px[x, y] = (0, 0, 0, 0)
	# Mild corner cleanup only (tol low so armor is not flooded away).
	for cx, cy in ((0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1)):
		_flood_clear(im, cx, cy, tol=18)

	bbox = im.getbbox()
	if bbox is None:
		raise RuntimeError(f"no opaque pixels in {path}")
	c = im.crop(bbox)
	side = max(c.size)
	margin = int(side * pad)
	side2 = side + margin * 2
	sq = Image.new("RGBA", (side2, side2), (0, 0, 0, 0))
	sq.paste(c, ((side2 - c.size[0]) // 2, (side2 - c.size[1]) // 2), c)
	return sq


def _flood_clear(im: Image.Image, x0: int, y0: int, tol: int = 18) -> None:
	px = im.load()
	w, h = im.size
	r0, g0, b0, a0 = px[x0, y0]
	if a0 == 0:
		return
	stack = [(x0, y0)]
	seen = set()
	while stack:
		x, y = stack.pop()
		if (x, y) in seen or x < 0 or y < 0 or x >= w or y >= h:
			continue
		seen.add((x, y))
		r, g, b, a = px[x, y]
		if a == 0:
			continue
		if abs(r - r0) + abs(g - g0) + abs(b - b0) > tol * 3:
			continue
		lum = (r + g + b) / 3.0
		chroma = max(abs(r - g), abs(g - b), abs(r - b))
		# Only clear near-black / near-white neutrals — never brown/red clothing.
		if not ((lum < 22 and chroma < 14) or (chroma < 12 and lum > 200)):
			continue
		px[x, y] = (0, 0, 0, 0)
		stack.extend(((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)))


def fit_content(im: Image.Image, size: int = FW, fill: float = 0.86) -> Image.Image:
	"""Crop to opaque content and letterbox into size×size so nothing is clipped."""
	bbox = im.getbbox()
	if bbox is None:
		return Image.new("RGBA", (size, size), (0, 0, 0, 0))
	c = im.crop(bbox)
	cw, ch = c.size
	target = max(8, int(size * fill))
	scale = min(target / cw, target / ch)
	nw, nh = max(1, int(cw * scale)), max(1, int(ch * scale))
	resized = c.resize((nw, nh), Image.Resampling.LANCZOS)
	out = Image.new("RGBA", (size, size), (0, 0, 0, 0))
	out.paste(resized, ((size - nw) // 2, (size - nh) // 2), resized)
	return out


def _lift_darks(im: Image.Image) -> Image.Image:
	"""Raise near-black clothing so legs/boots stay readable on dark fields."""
	out = im.copy()
	px = out.load()
	w, h = out.size
	for y in range(h):
		for x in range(w):
			r, g, b, a = px[x, y]
			if a < 20:
				continue
			lum = (r + g + b) / 3.0
			if lum < 55 and lum > 8:
				# push dark browns/grays up without bleaching reds
				boost = int(28 - lum * 0.25)
				px[x, y] = (min(255, r + boost), min(255, g + boost), min(255, b + boost // 2), a)
	return out


def to_pixel(im: Image.Image, size: int = FW) -> Image.Image:
	"""Downscale to crisp pixel art with limited palette; full body kept in frame."""
	fitted = fit_content(im, size=size, fill=0.90)
	fitted = _lift_darks(fitted)
	alpha = fitted.getchannel("A")
	base = fitted.convert("RGB")
	base = ImageEnhance.Brightness(base).enhance(1.14)
	base = ImageEnhance.Contrast(base).enhance(1.18)
	base = ImageEnhance.Color(base).enhance(1.15)
	q = base.quantize(colors=32, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE)
	q = q.convert("RGB")
	out = Image.new("RGBA", (size, size), (0, 0, 0, 0))
	sp = q.load()
	ap = alpha.load()
	op = out.load()
	for y in range(size):
		for x in range(size):
			a = ap[x, y]
			if a < 20:
				continue
			r, g, b = sp[x, y]
			op[x, y] = (r, g, b, 255)
	_add_outline(out)
	return out


def _add_outline(im: Image.Image) -> None:
	## Dark-brown rim (not pure black) so silhouettes stay readable on grass.
	px = im.load()
	w, h = im.size
	edge = []
	for y in range(h):
		for x in range(w):
			if px[x, y][3] < 128:
				continue
			for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
				nx, ny = x + dx, y + dy
				if nx < 0 or ny < 0 or nx >= w or ny >= h or px[nx, ny][3] < 64:
					edge.append((x, y))
					break
	for x, y in edge:
		r, g, b, a = px[x, y]
		px[x, y] = (
			max(40, min(r, 70)),
			max(28, min(g, 48)),
			max(20, min(b, 36)),
			a,
		)


def shift(im: Image.Image, dx: int = 0, dy: int = 0) -> Image.Image:
	out = Image.new("RGBA", im.size, (0, 0, 0, 0))
	out.paste(im, (dx, dy), im)
	return out


def nudge_legs(im: Image.Image, left_dy: int, right_dy: int) -> Image.Image:
	"""Subtle leg bob without punching holes — composite shifted lower halves."""
	w, h = im.size
	y0 = int(h * 0.58)
	left = im.crop((0, y0, w // 2, h))
	right = im.crop((w // 2, y0, w, h))
	base = im.crop((0, 0, w, y0 + 2))
	out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
	out.paste(base, (0, 0), base)
	out.paste(left, (0, y0 + left_dy), left)
	out.paste(right, (w // 2, y0 + right_dy), right)
	return out


def alpha_composite_blend(a: Image.Image, b: Image.Image, t: float) -> Image.Image:
	"""Prefer B as t→1; keep opaque coverage from either."""
	if t <= 0.0:
		return a.copy()
	if t >= 1.0:
		return b.copy()
	out = Image.new("RGBA", a.size, (0, 0, 0, 0))
	pa, pb, po = a.load(), b.load(), out.load()
	w, h = a.size
	for y in range(h):
		for x in range(w):
			ca, cb = pa[x, y], pb[x, y]
			if ca[3] < 40 and cb[3] < 40:
				continue
			if ca[3] < 40:
				po[x, y] = cb
			elif cb[3] < 40:
				po[x, y] = ca
			elif t < 0.45:
				po[x, y] = ca
			elif t > 0.55:
				po[x, y] = cb
			else:
				po[x, y] = cb if sum(cb[:3]) >= sum(ca[:3]) else ca
	return out


def make_idle_cycle(base: Image.Image) -> list[Image.Image]:
	## Tiny bob only — keep full body inside the frame.
	return [base, shift(base, 0, -1), base, shift(base, 0, 1)]


def make_walk_cycle(idle: Image.Image, walk: Image.Image) -> list[Image.Image]:
	w1 = walk
	w2 = shift(walk, 0, -1)
	alt = nudge_legs(idle, 1, -1)
	alt2 = nudge_legs(idle, -1, 1)
	return [w1, alt, w2, alt2]


def make_attack_cycle(idle: Image.Image, attack: Image.Image) -> list[Image.Image]:
	## No cross-pose blends — they cause ghosting / cut-off looks at 48px.
	windup = shift(idle, 0, -1)
	draw = shift(attack, 0, -1)
	return [idle, windup, draw, attack]


def sheet_from_rows(rows: list[list[Image.Image]]) -> Image.Image:
	sheet = Image.new("RGBA", (FW * COLS, FW * ROWS), (0, 0, 0, 0))
	for ri, frames in enumerate(rows):
		for ci, fr in enumerate(frames):
			if fr.size != (FW, FW):
				fr = fr.resize((FW, FW), Image.Resampling.NEAREST)
			sheet.paste(fr, (ci * FW, ri * FW), fr)
	return sheet


def build_unit(
	name: str,
	idle_path: Path,
	walk_path: Path | None,
	attack_path: Path,
	bg_idle: str,
	bg_walk: str,
	bg_attack: str,
) -> None:
	idle_hi = extract_character(idle_path, bg_idle)
	atk_hi = extract_character(attack_path, bg_attack)
	idle = to_pixel(idle_hi)
	attack = to_pixel(atk_hi)
	if walk_path and walk_path.exists():
		walk = to_pixel(extract_character(walk_path, bg_walk))
	else:
		walk = nudge_legs(idle, -2, 2)

	TMP.mkdir(parents=True, exist_ok=True)
	idle.save(TMP / f"{name}_idle48.png")
	walk.save(TMP / f"{name}_walk48.png")
	attack.save(TMP / f"{name}_attack48.png")

	rows = [
		make_idle_cycle(idle),
		make_walk_cycle(idle, walk),
		make_attack_cycle(idle, attack),
	]
	sheet = sheet_from_rows(rows)
	OUT.mkdir(parents=True, exist_ok=True)
	sheet.save(OUT / f"{name}_sheet.png")
	idle.save(OUT / f"{name}.png")
	print(f"OK {name}: sheet {sheet.size}")


def main() -> None:
	build_unit(
		"player_infantry",
		REF / "ref_infantry_idle.jpg",
		REF / "ref_infantry_walk.jpg",
		REF / "ref_infantry_attack.jpg",
		"dark",
		"dark",
		"dark",
	)
	build_unit(
		"player_archer",
		REF / "ref_archer_idle2.jpg",
		None,
		REF / "ref_archer_attack.jpg",
		"light",
		"light",
		"light",
	)
	build_unit(
		"enemy_infantry",
		REF / "enemy_inf_red_idle_v4.jpg",
		REF / "enemy_inf_red_walk_v4.jpg",
		REF / "enemy_inf_red_attack_v4.jpg",
		"dark",
		"dark",
		"dark",
	)
	build_unit(
		"enemy_archer",
		REF / "enemy_arc_red_idle_v3.jpg",
		REF / "enemy_arc_red_walk_v3.jpg",
		REF / "enemy_arc_red_attack_v3.jpg",
		"dark",
		"dark",
		"dark",
	)
	build_unit(
		"enemy_flyer",
		REF / "enemy_fly_bat_idle.jpg",
		REF / "enemy_fly_bat_flap.jpg",
		REF / "enemy_fly_bat_attack.jpg",
		"dark",
		"dark",
		"dark",
	)
	build_unit(
		"enemy_boss_knight",
		REF / "enemy_boss_var_a_red_knight.jpg",
		REF / "enemy_boss_red_walk.jpg",
		REF / "enemy_boss_red_attack.jpg",
		"dark",
		"dark",
		"dark",
	)
	print("done ->", OUT)


if __name__ == "__main__":
	main()
