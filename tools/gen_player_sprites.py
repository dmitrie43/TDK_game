#!/usr/bin/env python3
"""Generate custom 32x32 player unit spritesheets (idle / walk / attack)."""
from __future__ import annotations

from pathlib import Path

from PIL import Image

OUT = Path(__file__).resolve().parents[1] / "assets" / "units"
OUT.mkdir(parents=True, exist_ok=True)

TRANSP = (0, 0, 0, 0)
BLUE_D = (28, 70, 150, 255)
BLUE = (45, 110, 210, 255)
BLUE_L = (90, 155, 240, 255)
STEEL = (170, 180, 195, 255)
STEEL_D = (110, 120, 135, 255)
STEEL_L = (220, 230, 240, 255)
SKIN = (230, 185, 145, 255)
BOOT = (55, 45, 40, 255)
OUTLINE = (15, 18, 28, 255)
GOLD = (220, 175, 60, 255)
HOOD = (35, 95, 200, 255)
HOOD_D = (20, 60, 140, 255)
CLOAK = (40, 100, 195, 255)
WOOD = (140, 95, 50, 255)
WOOD_L = (175, 125, 70, 255)
STRING = (230, 220, 200, 255)
QUIVER = (90, 60, 35, 255)
LEG_C = (60, 55, 50, 255)

FW, FH = 32, 32
COLS, ROWS = 4, 3


def new_frame() -> Image.Image:
	return Image.new("RGBA", (FW, FH), TRANSP)


def px(img: Image.Image, x: int, y: int, c: tuple[int, int, int, int]) -> None:
	if 0 <= x < FW and 0 <= y < FH and c[3] > 0:
		img.putpixel((x, y), c)


def fill_rect(img: Image.Image, x0: int, y0: int, x1: int, y1: int, c) -> None:
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			px(img, x, y, c)


def draw_infantry(img: Image.Image, bob: int = 0, leg: int = 0, arm: int = 0, sword_ang: int = 0) -> None:
	cy = 15 + bob
	ly = cy + 8
	if leg == 0:
		fill_rect(img, 12, ly, 14, ly + 5, STEEL_D)
		fill_rect(img, 17, ly, 19, ly + 5, STEEL_D)
		fill_rect(img, 11, ly + 5, 14, ly + 6, BOOT)
		fill_rect(img, 17, ly + 5, 20, ly + 6, BOOT)
	elif leg < 0:
		fill_rect(img, 11, ly - 1, 13, ly + 4, STEEL_D)
		fill_rect(img, 17, ly + 1, 19, ly + 6, STEEL_D)
		fill_rect(img, 10, ly + 4, 13, ly + 5, BOOT)
		fill_rect(img, 17, ly + 6, 20, ly + 7, BOOT)
	else:
		fill_rect(img, 12, ly + 1, 14, ly + 6, STEEL_D)
		fill_rect(img, 18, ly - 1, 20, ly + 4, STEEL_D)
		fill_rect(img, 11, ly + 6, 14, ly + 7, BOOT)
		fill_rect(img, 18, ly + 4, 21, ly + 5, BOOT)

	fill_rect(img, 11, cy - 2, 20, cy + 7, BLUE)
	fill_rect(img, 12, cy - 1, 19, cy + 2, BLUE_L)
	fill_rect(img, 11, cy + 5, 20, cy + 7, BLUE_D)
	fill_rect(img, 9, cy - 1, 11, cy + 2, BLUE_L)
	fill_rect(img, 20, cy - 1, 22, cy + 2, BLUE_L)

	hy = cy - 8
	fill_rect(img, 12, hy, 19, hy + 5, STEEL)
	fill_rect(img, 13, hy + 1, 18, hy + 3, STEEL_L)
	fill_rect(img, 13, hy + 3, 18, hy + 3, OUTLINE)
	fill_rect(img, 15, hy - 2, 16, hy - 1, BLUE)
	px(img, 15, hy - 3, BLUE_L)
	fill_rect(img, 14, hy + 4, 17, hy + 5, SKIN)

	fill_rect(img, 8, cy + 1, 10, cy + 4, STEEL)
	sx = 21 + (2 if sword_ang > 0 else 0) + (1 if arm > 0 else 0)
	sy = cy + 1 - (3 if sword_ang > 1 else (1 if sword_ang > 0 else 0))
	fill_rect(img, sx - 1, sy, sx + 1, sy + 3, STEEL)
	if sword_ang <= 0:
		fill_rect(img, sx + 1, sy + 2, sx + 2, sy + 8, STEEL_L)
		px(img, sx + 1, sy + 1, GOLD)
		fill_rect(img, sx, sy + 8, sx + 3, sy + 8, STEEL_D)
	elif sword_ang == 1:
		for i in range(7):
			px(img, sx + 1 + i // 2, sy - 1 - i, STEEL_L)
			px(img, sx + 2 + i // 2, sy - 1 - i, STEEL)
		px(img, sx, sy, GOLD)
	else:
		fill_rect(img, sx, sy, sx + 9, sy + 1, STEEL_L)
		fill_rect(img, sx, sy - 1, sx + 1, sy + 2, GOLD)
		for i in range(3):
			px(img, sx + 7 + i, sy - 1 - i, (200, 220, 255, 180))

	for x, y in ((11, cy - 2), (20, cy - 2), (12, hy), (19, hy)):
		px(img, x, y, OUTLINE)


def _draw_bow_curve(img: Image.Image, bx: int, by: int, open_left: bool) -> None:
	## D-shaped bow: curved limbs + string.
	sign = -1 if open_left else 1
	for i in range(11):
		bend = min(i, 10 - i) // 2
		px(img, bx + sign * bend, by + i, WOOD)
		px(img, bx + sign * bend + sign, by + i, WOOD_L)
	for i in range(11):
		px(img, bx, by + i, STRING)


def draw_archer(img: Image.Image, bob: int = 0, leg: int = 0, draw_bow: int = 0) -> None:
	cy = 15 + bob
	ly = cy + 8
	if leg == 0:
		fill_rect(img, 12, ly, 14, ly + 5, LEG_C)
		fill_rect(img, 17, ly, 19, ly + 5, LEG_C)
		fill_rect(img, 11, ly + 5, 14, ly + 6, BOOT)
		fill_rect(img, 17, ly + 5, 20, ly + 6, BOOT)
	elif leg < 0:
		fill_rect(img, 11, ly - 1, 13, ly + 4, LEG_C)
		fill_rect(img, 17, ly + 1, 19, ly + 6, LEG_C)
		fill_rect(img, 10, ly + 4, 13, ly + 5, BOOT)
		fill_rect(img, 17, ly + 6, 20, ly + 7, BOOT)
	else:
		fill_rect(img, 12, ly + 1, 14, ly + 6, LEG_C)
		fill_rect(img, 18, ly - 1, 20, ly + 4, LEG_C)
		fill_rect(img, 11, ly + 6, 14, ly + 7, BOOT)
		fill_rect(img, 18, ly + 4, 21, ly + 5, BOOT)

	# Wide hooded cloak
	fill_rect(img, 10, cy - 1, 21, cy + 8, CLOAK)
	fill_rect(img, 11, cy, 20, cy + 5, HOOD)
	fill_rect(img, 9, cy + 3, 10, cy + 9, HOOD_D)
	fill_rect(img, 21, cy + 3, 22, cy + 9, HOOD_D)

	# Quiver + fletching
	fill_rect(img, 7, cy - 3, 9, cy + 5, QUIVER)
	px(img, 7, cy - 5, (200, 60, 50, 255))
	px(img, 8, cy - 5, (220, 220, 230, 255))
	px(img, 9, cy - 5, (200, 60, 50, 255))
	fill_rect(img, 7, cy - 4, 9, cy - 4, WOOD_L)

	# Pointed hood over face
	hy = cy - 9
	fill_rect(img, 11, hy, 20, hy + 7, HOOD)
	fill_rect(img, 12, hy + 1, 19, hy + 5, HOOD_D)
	# pointed tip
	fill_rect(img, 14, hy - 3, 17, hy - 1, HOOD)
	fill_rect(img, 15, hy - 4, 16, hy - 4, BLUE_L)
	fill_rect(img, 13, hy + 3, 18, hy + 5, SKIN)
	px(img, 14, hy + 4, OUTLINE)
	px(img, 17, hy + 4, OUTLINE)

	by = cy - 3
	if draw_bow == 0:
		_draw_bow_curve(img, 23, by, open_left=True)
		fill_rect(img, 9, cy + 2, 10, cy + 4, SKIN)
	elif draw_bow == 1:
		_draw_bow_curve(img, 22, by, open_left=True)
		for i in range(5):
			px(img, 21 - i, by + 5, STRING)
		fill_rect(img, 16, by + 4, 20, by + 5, WOOD_L)
		fill_rect(img, 10, cy + 1, 12, cy + 3, SKIN)
	elif draw_bow == 2:
		_draw_bow_curve(img, 21, by, open_left=True)
		for i in range(8):
			px(img, 20 - min(i, 7 - i), by + 1 + i, STRING)
		fill_rect(img, 11, by + 4, 19, by + 5, WOOD_L)
		px(img, 10, by + 4, STEEL_L)
		fill_rect(img, 9, cy, 11, cy + 2, SKIN)
	else:
		_draw_bow_curve(img, 24, by, open_left=True)
		fill_rect(img, 25, by + 4, 30, by + 5, WOOD_L)
		px(img, 31, by + 4, STEEL_L)
		px(img, 26, by + 3, (220, 220, 255, 160))
		fill_rect(img, 10, cy + 2, 12, cy + 4, SKIN)


def make_sheet(rows: list[list[Image.Image]]) -> Image.Image:
	sheet = Image.new("RGBA", (FW * COLS, FH * ROWS), TRANSP)
	for row_i, frames in enumerate(rows):
		for col_i, fr in enumerate(frames):
			sheet.paste(fr, (col_i * FW, row_i * FH), fr)
	return sheet


def main() -> None:
	inf_idle = []
	for bob in (0, -1, 0, 1):
		im = new_frame()
		draw_infantry(im, bob=bob, leg=0, sword_ang=0)
		inf_idle.append(im)

	inf_walk = []
	for bob, leg in ((0, -1), (-1, 0), (0, 1), (-1, 0)):
		im = new_frame()
		draw_infantry(im, bob=bob, leg=leg, sword_ang=0)
		inf_walk.append(im)

	inf_atk = []
	for sword_ang, bob, arm in ((0, 0, 0), (1, -1, 1), (2, 0, 2), (1, 0, 1)):
		im = new_frame()
		draw_infantry(im, bob=bob, leg=0, arm=arm, sword_ang=sword_ang)
		inf_atk.append(im)

	inf_sheet = make_sheet([inf_idle, inf_walk, inf_atk])
	inf_sheet.save(OUT / "player_infantry_sheet.png")
	inf_idle[0].save(OUT / "player_infantry.png")

	arc_idle = []
	for bob in (0, -1, 0, 1):
		im = new_frame()
		draw_archer(im, bob=bob, leg=0, draw_bow=0)
		arc_idle.append(im)

	arc_walk = []
	for bob, leg in ((0, -1), (-1, 0), (0, 1), (-1, 0)):
		im = new_frame()
		draw_archer(im, bob=bob, leg=leg, draw_bow=0)
		arc_walk.append(im)

	arc_atk = []
	for db, bob in ((0, 0), (1, 0), (2, -1), (3, 0)):
		im = new_frame()
		draw_archer(im, bob=bob, leg=0, draw_bow=db)
		arc_atk.append(im)

	arc_sheet = make_sheet([arc_idle, arc_walk, arc_atk])
	arc_sheet.save(OUT / "player_archer_sheet.png")
	arc_idle[0].save(OUT / "player_archer.png")

	print("OK", OUT)
	print(" infantry", (OUT / "player_infantry_sheet.png").stat().st_size)
	print(" archer  ", (OUT / "player_archer_sheet.png").stat().st_size)


if __name__ == "__main__":
	main()
