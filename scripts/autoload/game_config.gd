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
const COST_UPG_INF_HORSES := 90
const COST_UPG_INF_ARMOR := 130
## Once-only unlocks (not leveled).
const COST_UPG_INF_CROSSBOWS := 200
const COST_UPG_ARC_SIGHT := 200
const COST_UPG_ARC_BOWS := 170
const COST_UPG_ARC_FIRE_RATE := 150
const COST_UPG_KING_DURABILITY := 170
const COST_UPG_KING_BUILDERS := 190
const COST_UPG_EAG_FLIGHT := 110
const COST_UPG_EAG_MANEUVER := 140
const COST_UPG_HEA_HERBS := 120
const COST_UPG_HEA_HANDS := 130
## Per-level effect amounts (total = per_level * current_level).
const UPG_INF_HORSES_SPEED_PER_LEVEL := 0.10 ## L1 +10% … L5 +50%
const UPG_INF_ARMOR_HP_PER_LEVEL := 10 ## L1 +10 … L5 +50 HP
const UPG_ARC_BOWS_DAMAGE_PER_LEVEL := 5 ## L1 +5 … L5 +25 damage
## Fire rate: cooldown /= (1 + RATE_PER_LEVEL * level); L1 +10% … L5 +50%
const UPG_ARC_FIRE_RATE_PER_LEVEL := 0.10
## Longsight once-only: Euclidean reach covering Far from any wall post (opposite side).
const UPG_ARC_SIGHT_RANGE := FAR_OUTER + KINGDOM_RADIUS
const UPG_KING_DURABILITY_HP_PER_LEVEL := 50
const UPG_KING_BUILDERS_INTERVAL := 10.0
const UPG_KING_BUILDERS_HEAL_BASE := 2
const UPG_KING_BUILDERS_HEAL_PER_LEVEL := 1 ## L1→3 … L5→7 HP / interval
const UPG_EAG_FLIGHT_SPEED_PER_LEVEL := 0.08 ## L5 → +40% speed
const UPG_EAG_MANEUVER_DODGE_PER_LEVEL := 0.10 ## L1 10% … L5 50%
## Healer: bonus = BASE + PER_LEVEL * L → L1 +20% … L5 +60%.
const UPG_HEA_HERBS_HEAL_BASE := 0.10
const UPG_HEA_HERBS_HEAL_PER_LEVEL := 0.10
const UPG_HEA_HANDS_RATE_BASE := 0.10
const UPG_HEA_HANDS_RATE_PER_LEVEL := 0.10


# --- Combat ---
const MELEE_RANGE := 36.0
const ARCHER_RANGE := 220.0
## When firing all sectors: must reach Mid opposite the castle (~post+MID_OUTER).
const ARCHER_RANGE_ALL_SECTORS := 330.0
const MELEE_COOLDOWN := 1.0
const ARCHER_COOLDOWN := 1.2
## --- Archer placement / targeting (flip to restore old behaviour) ---
## true: hire places on a free wall sector automatically (no sector picker).
const ARCHER_AUTO_PLACE := true
## true: wall archers shoot any enemy in range, not only own sector (+ Near exception).
const ARCHER_FIRE_ALL_SECTORS := true
## Enemies (all kinds) deal damage once per this interval.
const ENEMY_ATTACK_COOLDOWN := 2.6
## Archer projectile visual lifetime (seconds).
const PROJECTILE_LIFETIME := 1.0

# --- Enemy base stats (mild bump vs original easy pass) ---
const ENEMY_INFANTRY_HP := 50
const ENEMY_INFANTRY_DAMAGE := 11
const ENEMY_SHIELD_HP := 100
const ENEMY_SHIELD_DAMAGE := 8
## Player archers deal this fraction of damage to shield-bearers (80% reduction → 0.2).
const ENEMY_SHIELD_ARCHER_DAMAGE_MULT := 0.2
## Infantry deal this fraction of damage to shield-bearers (20% reduction → 0.8).
const ENEMY_SHIELD_INFANTRY_DAMAGE_MULT := 0.5
const ENEMY_ARCHER_HP := 45
const ENEMY_ARCHER_DAMAGE := 9
const ENEMY_FLYER_HP := 40
const ENEMY_FLYER_DAMAGE := 16
const ENEMY_VAMPIRE_HP := 150
const ENEMY_VAMPIRE_DAMAGE := 12
## Heal for this fraction of damage dealt on hit.
const ENEMY_VAMPIRE_LIFESTEAL := 0.5

# --- Movement ---
const ENEMY_INFANTRY_SPEED := 55.0
const ENEMY_SHIELD_SPEED := 38.0
const ENEMY_ARCHER_SPEED := 45.0
const ENEMY_FLYER_SPEED := 80.0
const ENEMY_VAMPIRE_SPEED := 90.0
## Shield march is slower than other ground enemies.
const ENEMY_SHIELD_STEP_INTERVAL := 6.5
## Vampire teleports toward prey this often (faster than standard 4.5s march).
const ENEMY_VAMPIRE_STEP_INTERVAL := 4.0
const PLAYER_INFANTRY_SPEED := 70.0
const PLAYER_ARCHER_HP := 80
const PLAYER_ARCHER_DAMAGE := 10
const PLAYER_EAGLE_SPEED := 78.0
const PLAYER_EAGLE_HP := 100
const PLAYER_EAGLE_DAMAGE := 20
## Bonus multiplier when eagles hit flying enemies.
const PLAYER_EAGLE_AIR_DAMAGE_MULT := 1.3
const PLAYER_HEALER_SPEED := 62.0
const PLAYER_HEALER_HP := 30
const PLAYER_HEALER_HEAL := 15
const PLAYER_HEALER_COOLDOWN := 3.0
const PLAYER_HEALER_RANGE := 42.0
## Discrete enemy march: Far → Mid → Near once per interval (not continuous run).
const ENEMY_STEP_INTERVAL := 4.5
## How far a vampire blinks toward its target each teleport.
const ENEMY_VAMPIRE_TELEPORT_RANGE := 110.0
const ANIM_TELEPORT_DURATION := 0.28

# --- Boss kill rewards (free pick of 1 from 2 random) ---
const BOSS_REWARD_FROST_DURATION := 2.0
const BOSS_REWARD_POISON_DAMAGE := 5
const BOSS_REWARD_POISON_INTERVAL := 2.0
const BOSS_REWARD_INF_HP := 10
const BOSS_REWARD_INF_DAMAGE := 5
const BOSS_REWARD_ARC_HP := 10
const BOSS_REWARD_EAG_HP := 10
const BOSS_REWARD_EAG_DAMAGE := 10

# --- Economy (middle: harder than v1, fair early game) ---
const STARTING_GOLD := 100
const COST_PLAYER_INFANTRY := 45
const COST_PLAYER_ARCHER := 60
const COST_PLAYER_EAGLE := 80
const COST_PLAYER_HEALER := 70
const GOLD_PER_ENEMY_INFANTRY := 10
const GOLD_PER_ENEMY_SHIELD := 15
const GOLD_PER_ENEMY_ARCHER := 11
const GOLD_PER_ENEMY_FLYER := 13
const GOLD_PER_ENEMY_VAMPIRE := 16
const GOLD_PER_BOSS_KNIGHT := 250
const GOLD_WAVE_CLEAR := 50
## Shield-bearers first appear on this wave index.
const SHIELD_START_WAVE := 3
## Vampires first appear on this wave index.
const VAMPIRE_START_WAVE := 7

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

# --- Global enemy power (all kinds, including boss) every N waves ---
## Tier 0 on waves 1–4, tier 1 on 5–9, tier 2 on 10–14, …
const ENEMY_POWER_WAVE_STEP := 5
## +15% max HP and +10% damage per power tier (multiplicative on base/boss stats).
const ENEMY_HP_MULT_PER_POWER_TIER := 0.15
const ENEMY_DAMAGE_MULT_PER_POWER_TIER := 0.10


func player_archer_base_range() -> float:
	## Base wall-archer range before Longsight. Global fire needs Mid coverage cross-map.
	if ARCHER_FIRE_ALL_SECTORS:
		return ARCHER_RANGE_ALL_SECTORS
	return ARCHER_RANGE


func archer_zone_in_base_reach(zone: Zone) -> bool:
	## Without Longsight: Near + Mid (+ kingdom). Far locked until sight upgrade.
	return (
		zone == Zone.KINGDOM
		or zone == Zone.NEAR
		or zone == Zone.MID
	)


func archer_can_engage_zone(zone: Zone, has_longsight: bool) -> bool:
	if archer_zone_in_base_reach(zone):
		return true
	return has_longsight and zone == Zone.FAR


func is_boss_knight_wave(wave: int) -> bool:
	return wave >= BOSS_KNIGHT_WAVE and (wave - BOSS_KNIGHT_WAVE) % BOSS_KNIGHT_REPEAT == 0


func boss_knight_tier(wave: int) -> int:
	## 0 on wave 10, 1 on 15, 2 on 20, …
	if not is_boss_knight_wave(wave):
		return -1
	return int((wave - BOSS_KNIGHT_WAVE) / BOSS_KNIGHT_REPEAT)


func enemy_power_tier(wave: int) -> int:
	## 0 until wave 5, then +1 every ENEMY_POWER_WAVE_STEP waves.
	if wave < ENEMY_POWER_WAVE_STEP:
		return 0
	return int(wave / ENEMY_POWER_WAVE_STEP)

# --- Waves (clear-based) ---
const TIME_BEFORE_FIRST_WAVE := 3.0
## Rest between waves after a clear (seconds).
const WAVE_CLEAR_DELAY := 3.0
## Flyers (birds) first appear on this wave index.
const FLYER_START_WAVE := 5

enum Zone { KINGDOM, NEAR, MID, FAR, OUT }
enum Faction { PLAYER, ENEMY }
enum UnitKind { INFANTRY, ARCHER, FLYER, BOSS, EAGLE, SHIELD, VAMPIRE, HEALER }
## Enemy march rings along a sector ray.
enum RouteStep { FAR, MID, NEAR }

# --- Sprites ---
## Player units: custom generated sheets (idle/walk/attack), not Kenney.
const SPRITE_PLAYER_INFANTRY := "res://assets/units/player_infantry.png"
const SPRITE_PLAYER_ARCHER := "res://assets/units/player_archer.png"
const SPRITE_PLAYER_EAGLE := "res://assets/units/player_eagle.png"
const SPRITE_PLAYER_HEALER := "res://assets/units/player_healer.png"
const SPRITE_PLAYER_INFANTRY_SHEET := "res://assets/units/player_infantry_sheet.png"
const SPRITE_PLAYER_ARCHER_SHEET := "res://assets/units/player_archer_sheet.png"
const SPRITE_PLAYER_EAGLE_SHEET := "res://assets/units/player_eagle_sheet.png"
const SPRITE_PLAYER_HEALER_SHEET := "res://assets/units/player_healer_sheet.png"
## Enemy infantry / archer / flyer / boss: custom sheets. Field still Kenney until replaced.
const SPRITE_ENEMY_INFANTRY := "res://assets/units/enemy_infantry.png"
const SPRITE_ENEMY_INFANTRY_SHEET := "res://assets/units/enemy_infantry_sheet.png"
const SPRITE_ENEMY_SHIELD := "res://assets/units/enemy_shield.png"
const SPRITE_ENEMY_SHIELD_SHEET := "res://assets/units/enemy_shield_sheet.png"
const SPRITE_ENEMY_ARCHER := "res://assets/units/enemy_archer.png"
const SPRITE_ENEMY_ARCHER_SHEET := "res://assets/units/enemy_archer_sheet.png"
const SPRITE_ENEMY_FLYER := "res://assets/units/enemy_flyer.png"
const SPRITE_ENEMY_FLYER_SHEET := "res://assets/units/enemy_flyer_sheet.png"
const SPRITE_ENEMY_VAMPIRE := "res://assets/units/enemy_vampire.png"
const SPRITE_ENEMY_VAMPIRE_SHEET := "res://assets/units/enemy_vampire_sheet.png"
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
