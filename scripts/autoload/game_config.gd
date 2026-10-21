extends Node
## Tunable defaults for the foundation. Change numbers here, not scattered in units.

# --- Kingdom ---
const KINGDOM_MAX_HP := 200
const KINGDOM_RADIUS := 70.0
const COST_KINGDOM_HEAL := 100
const KINGDOM_HEAL_AMOUNT := 50
## Push all enemies one ring outward (toward Far). Far stays in place.
const COST_PUSH_WAVE := 90

# --- Sectors / rings (top-down, kingdom at origin) ---
const SECTOR_COUNT := 8
const SECTOR_ANGLE := TAU / float(SECTOR_COUNT) # 45°
## Near = walls (melee can hit kingdom). Mid = archer band. Far = spawn approach.
const NEAR_OUTER := 150.0
const MID_OUTER := 280.0
const FAR_OUTER := 420.0

# --- Upgrades (each can be leveled 1…MAX) ---
const UPGRADE_MAX_LEVEL := 5
## Base gold cost of level 1; higher levels use Upgrades.cost_for_next_level().
const COST_UPG_INF_HORSES := 110
const COST_UPG_INF_ARMOR := 160
## Once-only unlocks (not leveled).
const COST_UPG_INF_CROSSBOWS := 250
const COST_UPG_ARC_SIGHT := 250
const COST_UPG_ARC_BOWS := 210
const COST_UPG_ARC_FIRE_RATE := 190
const COST_UPG_KING_DURABILITY := 210
const COST_UPG_KING_BUILDERS := 230
## Per-level effect amounts (total = per_level * current_level).
const UPG_INF_HORSES_SPEED_PER_LEVEL := 0.08 ## L5 → +40% speed
const UPG_INF_ARMOR_HP_PER_LEVEL := 20
const UPG_ARC_BOWS_DAMAGE_PER_LEVEL := 8
## Fire rate: cooldown /= (1 + RATE_PER_LEVEL * level); L5 → ×1.5
const UPG_ARC_FIRE_RATE_PER_LEVEL := 0.1
## Longsight once-only: full Far range.
const UPG_ARC_SIGHT_RANGE := FAR_OUTER
const UPG_KING_DURABILITY_HP_PER_LEVEL := 50
const UPG_KING_BUILDERS_INTERVAL := 10.0
const UPG_KING_BUILDERS_HEAL_BASE := 2
const UPG_KING_BUILDERS_HEAL_PER_LEVEL := 1 ## L1→3 … L5→7 HP / interval


# --- Combat ---
const MELEE_RANGE := 36.0
const ARCHER_RANGE := 220.0
const MELEE_COOLDOWN := 1.0
const ARCHER_COOLDOWN := 1.2
## Enemies (all kinds) deal damage once per this interval.
const ENEMY_ATTACK_COOLDOWN := 2.6
## Archer projectile visual lifetime (seconds).
const PROJECTILE_LIFETIME := 1.0

# --- Enemy base stats (mild bump vs original easy pass) ---
const ENEMY_INFANTRY_HP := 50
const ENEMY_INFANTRY_DAMAGE := 11
const ENEMY_ARCHER_HP := 45
const ENEMY_ARCHER_DAMAGE := 9
const ENEMY_FLYER_HP := 40
const ENEMY_FLYER_DAMAGE := 16

# --- Movement ---
const ENEMY_INFANTRY_SPEED := 55.0
const ENEMY_ARCHER_SPEED := 45.0
const ENEMY_FLYER_SPEED := 80.0
const PLAYER_INFANTRY_SPEED := 70.0
## Discrete enemy march: Far → Mid → Near once per interval (not continuous run).
const ENEMY_STEP_INTERVAL := 4.5

# --- Boss kill rewards (free pick of 1 from 2 random) ---
const BOSS_REWARD_FROST_DURATION := 2.0
const BOSS_REWARD_POISON_DAMAGE := 5
const BOSS_REWARD_POISON_INTERVAL := 2.0
const BOSS_REWARD_INF_HP := 10
const BOSS_REWARD_INF_DAMAGE := 5
const BOSS_REWARD_ARC_HP := 10

# --- Economy (middle: harder than v1, fair early game) ---
const STARTING_GOLD := 100
const COST_PLAYER_INFANTRY := 45
const COST_PLAYER_ARCHER := 60
const GOLD_PER_ENEMY_INFANTRY := 9
const GOLD_PER_ENEMY_ARCHER := 11
const GOLD_PER_ENEMY_FLYER := 13
const GOLD_PER_BOSS_KNIGHT := 200
const GOLD_WAVE_CLEAR := 40

# --- Boss knight (first at wave 10, then every REPEAT waves, stronger each time) ---
const BOSS_KNIGHT_WAVE := 10
const BOSS_KNIGHT_REPEAT := 5
const BOSS_KNIGHT_HP := 550
const BOSS_KNIGHT_DAMAGE := 32
const BOSS_KNIGHT_FLYER_ESCORT := 4
const BOSS_KNIGHT_HP_PER_TIER := 100
const BOSS_KNIGHT_DAMAGE_PER_TIER := 5
const BOSS_KNIGHT_ESCORT_PER_TIER := 1
## Boss smash hits all player squads in this radius.
const BOSS_AOE_RADIUS := 70.0
## How many enemies share one sector: 1 + floor((wave-1) / this).
const SECTOR_PACK_WAVE_STEP := 3


func is_boss_knight_wave(wave: int) -> bool:
	return wave >= BOSS_KNIGHT_WAVE and (wave - BOSS_KNIGHT_WAVE) % BOSS_KNIGHT_REPEAT == 0


func boss_knight_tier(wave: int) -> int:
	## 0 on wave 10, 1 on 15, 2 on 20, …
	if not is_boss_knight_wave(wave):
		return -1
	return int((wave - BOSS_KNIGHT_WAVE) / BOSS_KNIGHT_REPEAT)

# --- Waves (clear-based) ---
const TIME_BEFORE_FIRST_WAVE := 3.0
## Rest between waves after a clear (seconds).
const WAVE_CLEAR_DELAY := 3.0
## Flyers (birds) first appear on this wave index.
const FLYER_START_WAVE := 5

enum Zone { KINGDOM, NEAR, MID, FAR, OUT }
enum Faction { PLAYER, ENEMY }
enum UnitKind { INFANTRY, ARCHER, FLYER, BOSS }
## Enemy march rings along a sector ray.
enum RouteStep { FAR, MID, NEAR }

# --- Sprites ---
## Player units: custom generated sheets (idle/walk/attack), not Kenney.
const SPRITE_PLAYER_INFANTRY := "res://assets/units/player_infantry.png"
const SPRITE_PLAYER_ARCHER := "res://assets/units/player_archer.png"
const SPRITE_PLAYER_INFANTRY_SHEET := "res://assets/units/player_infantry_sheet.png"
const SPRITE_PLAYER_ARCHER_SHEET := "res://assets/units/player_archer_sheet.png"
## Enemy infantry / archer / flyer / boss: custom sheets. Field still Kenney until replaced.
const SPRITE_ENEMY_INFANTRY := "res://assets/units/enemy_infantry.png"
const SPRITE_ENEMY_INFANTRY_SHEET := "res://assets/units/enemy_infantry_sheet.png"
const SPRITE_ENEMY_ARCHER := "res://assets/units/enemy_archer.png"
const SPRITE_ENEMY_ARCHER_SHEET := "res://assets/units/enemy_archer_sheet.png"
const SPRITE_ENEMY_FLYER := "res://assets/units/enemy_flyer.png"
const SPRITE_ENEMY_FLYER_SHEET := "res://assets/units/enemy_flyer_sheet.png"
const SPRITE_ENEMY_BOSS_KNIGHT := "res://assets/units/enemy_boss_knight.png"
const SPRITE_ENEMY_BOSS_KNIGHT_SHEET := "res://assets/units/enemy_boss_knight_sheet.png"
const SPRITE_KINGDOM := "res://assets/kenney/kingdom/castle.png"
const SPRITE_FIELD_GRASS := "res://assets/kenney/field/grass_field.png"
## Backdrop around the circular arena (viewport clear + outer dirt).
const COLOR_WORLD_VOID := Color(0.12, 0.16, 0.10, 1.0)
const COLOR_WORLD_DIRT := Color(0.22, 0.20, 0.14, 1.0)
const COLOR_FIELD_GRASS := Color(0.30, 0.48, 0.24, 1.0)
const UNIT_SPRITE_SCALE := 1.5
## Legacy static flyer scale (pre-sheet).
const FLYER_SPRITE_SCALE := 2.2
## 48px bat sheet — a bit larger than ground units.
const FLYER_SHEET_SCALE := 1.45
## Legacy static boss scale (pre-sheet).
const BOSS_SPRITE_SCALE := 2.8
## 48px boss sheet — clearly larger than infantry.
const BOSS_SHEET_SCALE := 1.85
## Anim sheets: 4 cols × 3 rows of 48×48 (idle / walk-or-flap / attack).
const UNIT_SHEET_FRAME := 48
const UNIT_SHEET_COLS := 4
const UNIT_SHEET_ROWS := 3
const ANIM_IDLE_FPS := 5.0
const ANIM_WALK_FPS := 5.0
const ANIM_FLAP_FPS := 6.0
const ANIM_ATTACK_DURATION := 0.32
## Scale for custom 48px ground-unit sheets.
const PLAYER_SPRITE_SCALE := 1.15
