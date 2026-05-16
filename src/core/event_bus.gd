extends Node

## Global signal hub for cross-system communication.
##
## EventBus decouples systems that should not hold direct references to each other.
## All signals are declared here and connected via code (never via editor).
##
## Usage:
##   # Emit
##   EventBus.health_changed.emit(new_health, max_health)
##
##   # Connect (in _ready)
##   EventBus.health_changed.connect(_on_health_changed)
##
## Conventions:
##   - Signals use snake_case past-tense naming (health_changed, companion_joined)
##   - All parameters are statically typed
##   - Listeners disconnect in _exit_tree to prevent stale references

# ---------------------------------------------------------------------------
# Player signals
# ---------------------------------------------------------------------------

## Emitted when the player's health value changes.
signal health_changed(new_health: float, max_health: float)

## Emitted when the player dies (health reaches zero).
signal player_died()

## Emitted when the player enters a new map region.
signal player_region_entered(region_id: StringName)

# ---------------------------------------------------------------------------
# Party / Companion signals
# ---------------------------------------------------------------------------

## 동료 합류 요청 신호 - 동료-합류-이벤트 시스템이 발행, 파티 매니저 등 다운스트림이 수신 (TR-ebus-001)
signal companion_join_requested(companion_id: StringName)

## Emitted when a companion successfully joins the party.
signal companion_joined(companion_id: StringName)

## Emitted when a companion leaves the party for any reason.
signal companion_left(companion_id: StringName)

## Emitted when a companion's stat changes (e.g. affinity, mood).
signal companion_stat_changed(companion_id: StringName, stat_name: StringName, new_value: float)

# ---------------------------------------------------------------------------
# Quest signals
# ---------------------------------------------------------------------------

## Emitted when a quest becomes active.
signal quest_started(quest_id: StringName)

## Emitted when a quest objective is updated.
signal quest_objective_updated(quest_id: StringName, objective_id: StringName)

## Emitted when a quest reaches a completed state.
signal quest_completed(quest_id: StringName)

## Emitted when a quest is failed.
signal quest_failed(quest_id: StringName)

# ---------------------------------------------------------------------------
# Dialogue signals
# ---------------------------------------------------------------------------

## Emitted when a dialogue sequence begins.
signal dialogue_started(dialogue_id: StringName, speaker_id: StringName)

## Emitted when a dialogue sequence ends.
signal dialogue_ended(dialogue_id: StringName)

# ---------------------------------------------------------------------------
# Combat signals
# ---------------------------------------------------------------------------

## Emitted when any entity deals damage to another.
signal damage_dealt(target_id: StringName, amount: float, damage_type: StringName)

## Emitted when combat begins in the current scene.
signal combat_started()

## Emitted when combat ends (victory or retreat).
signal combat_ended(result: StringName)

# ---------------------------------------------------------------------------
# Scene / World signals
# ---------------------------------------------------------------------------

## Emitted just before the active scene transitions to another.
signal scene_transition_started(from_scene: StringName, to_scene: StringName)

## Emitted after the new scene has fully loaded.
signal scene_transition_completed(to_scene: StringName)

# ---------------------------------------------------------------------------
# Internal
# ---------------------------------------------------------------------------

func _ready() -> void:
	# EventBus is a pure signal hub - no child nodes or state needed.
	pass
