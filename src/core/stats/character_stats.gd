class_name CharacterStats
extends Resource

## Stat data resource for all characters: player, companions, and enemies.
##
## CharacterStats is the single source of truth for numeric attributes.
## All downstream systems (health/damage, AI, movement) read only the
## computed properties (max_hp, atk, def, spd) - never base_* or mod_* directly.
##
## Two-layer structure:
##   base_*  - permanent values; written only by the level-up system.
##   mod_*   - temporary modifiers; written only by the combat buff system.
##             MVP: always 0. Setters emit push_warning() to catch accidental writes.
##   computed getters - clamp(base + mod, min, max); these are what callers read.
##
## Lifecycle:
##   1. Save a CharacterStats as a .tres template (read-only source).
##   2. Call stats_template.duplicate() at runtime to get a per-character instance.
##   3. Write base_* only through the level-up system.
##   4. Write mod_* only through the combat buff system (VS+ phase).
##
## Usage:
##   var stats: CharacterStats = preload("res://assets/data/stats/player.tres").duplicate()
##   var speed: float = stats.spd          # always read computed property
##   stats.base_atk = stats.base_atk + 3  # level-up system writes base_*
##   stats.stats_changed.connect(_on_stats_changed)

# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------

## Emitted whenever a stat value changes. stat_name matches the computed
## property name ("max_hp", "atk", "def", "spd").
signal stats_changed(stat_name: StringName)

# ---------------------------------------------------------------------------
# Constants - clamp boundaries (mirrors GDD Formulas section)
# ---------------------------------------------------------------------------

const MAX_HP_MIN: int = 1
const MAX_HP_MAX: int = 9999
const ATK_MIN: int = 0
const ATK_MAX: int = 999
const DEF_MIN: int = 0
const DEF_MAX: int = 999
const SPD_MIN: float = 10.0
const SPD_MAX: float = 600.0

# ---------------------------------------------------------------------------
# Export - base values (permanent, written by level-up system only)
# ---------------------------------------------------------------------------

@export_group("Base Stats")

## Permanent base HP ceiling. Written only by the level-up system.
## Must satisfy: MAX_HP_MIN <= base_max_hp <= MAX_HP_MAX.
@export_range(MAX_HP_MIN, MAX_HP_MAX, 1) var base_max_hp: int = 80:
	set(value):
		var clamped: int = clampi(value, MAX_HP_MIN, MAX_HP_MAX)
		if clamped == base_max_hp:
			return
		base_max_hp = clamped
		stats_changed.emit(&"max_hp")

## Permanent base attack power. Written only by the level-up system.
@export_range(ATK_MIN, ATK_MAX, 1) var base_atk: int = 20:
	set(value):
		var clamped: int = clampi(value, ATK_MIN, ATK_MAX)
		if clamped == base_atk:
			return
		base_atk = clamped
		stats_changed.emit(&"atk")

## Permanent base defence. Written only by the level-up system.
@export_range(DEF_MIN, DEF_MAX, 1) var base_def: int = 8:
	set(value):
		var clamped: int = clampi(value, DEF_MIN, DEF_MAX)
		if clamped == base_def:
			return
		base_def = clamped
		stats_changed.emit(&"def")

## Permanent base movement speed (px/s). Written only by the level-up system.
@export_range(SPD_MIN, SPD_MAX, 0.1) var base_spd: float = 130.0:
	set(value):
		var clamped: float = clampf(value, SPD_MIN, SPD_MAX)
		if clamped == base_spd:
			return
		base_spd = clamped
		stats_changed.emit(&"spd")

# ---------------------------------------------------------------------------
# Modifier values - temporary (written by combat buff system; MVP always 0)
# ---------------------------------------------------------------------------

## Temporary HP ceiling modifier. MVP: 0. Combat buff system writes this.
## Setter emits push_warning() to catch accidental writes during MVP.
var mod_max_hp: int = 0:
	set(value):
		if value == mod_max_hp:
			return
		if value != 0:
			push_warning(
				("CharacterStats: mod_max_hp written (value=%d). " \
				+ "Modifier writes are reserved for the combat buff system (VS+ phase). " \
				+ "If intentional, suppress this warning in the buff system.") % value
			)
		mod_max_hp = value
		stats_changed.emit(&"max_hp")

## Temporary attack modifier. MVP: 0. Combat buff system writes this.
var mod_atk: int = 0:
	set(value):
		if value == mod_atk:
			return
		if value != 0:
			push_warning(
				("CharacterStats: mod_atk written (value=%d). " \
				+ "Modifier writes are reserved for the combat buff system (VS+ phase).") % value
			)
		mod_atk = value
		stats_changed.emit(&"atk")

## Temporary defence modifier. MVP: 0. Combat buff system writes this.
var mod_def: int = 0:
	set(value):
		if value == mod_def:
			return
		if value != 0:
			push_warning(
				("CharacterStats: mod_def written (value=%d). " \
				+ "Modifier writes are reserved for the combat buff system (VS+ phase).") % value
			)
		mod_def = value
		stats_changed.emit(&"def")

## Temporary speed modifier (px/s). MVP: 0. Combat buff system writes this.
var mod_spd: float = 0.0:
	set(value):
		if value == mod_spd:
			return
		if value != 0.0:
			push_warning(
				("CharacterStats: mod_spd written (value=%f). " \
				+ "Modifier writes are reserved for the combat buff system (VS+ phase).") % value
			)
		mod_spd = value
		stats_changed.emit(&"spd")

# ---------------------------------------------------------------------------
# Computed properties - downstream systems read ONLY these
# ---------------------------------------------------------------------------

## Effective HP ceiling: clamp(base_max_hp + mod_max_hp, 1, 9999).
var max_hp: int:
	get:
		return clampi(base_max_hp + mod_max_hp, MAX_HP_MIN, MAX_HP_MAX)

## Effective attack power: clamp(base_atk + mod_atk, 0, 999).
var atk: int:
	get:
		return clampi(base_atk + mod_atk, ATK_MIN, ATK_MAX)

## Effective defence: clamp(base_def + mod_def, 0, 999).
var def: int:
	get:
		return clampi(base_def + mod_def, DEF_MIN, DEF_MAX)

## Effective movement speed (px/s): clamp(base_spd + mod_spd, 10.0, 600.0).
## base_spd is never mutated by clamping - only the computed result is clamped.
var spd: float:
	get:
		return clampf(base_spd + mod_spd, SPD_MIN, SPD_MAX)
