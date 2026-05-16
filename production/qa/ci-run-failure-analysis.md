# CI-RUN Failure Analysis — Sprint 2

**Date**: 2026-05-15  
**Runner**: GUT (addons/gut/gut_cmdln.gd)  
**Command**: `Godot_v4.6.2-stable_win64_console.exe --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -ginclude_subdirs -gexit`

---

## Final Result

| Run | Tests | Passing | Failing | Risky |
|-----|-------|---------|---------|-------|
| Initial (2026-05-15) | 518 | 515 | 3 | 2 |
| After fixes | 518 | 516 | **0** | 2 |

**CI Status: ✅ PASS** (0 failures, 2 risky are hardware-dependent placeholders)

---

## Root Cause Analysis

### Previously Reported Root Causes (from prior session)
The 334 failures reported in the previous session had already been resolved before this session:
1. Autoload name collision / ClassName.new() — **RESOLVED**
2. RefCounted .free() — **RESOLVED**
3. JOY_BUTTON_WEST constant name — **RESOLVED**

### Failures Found This Session (3 total)

#### RC-1: DialogueManager mock injection shadowed by Autoload
- **Affected**: `portal_transition_test.gd` — `test_portal_can_trigger_dialogue_active_blocks_player_body`
- **Root cause**: `DialogueManager` is registered as an Autoload in `project.godot`, so `/root/DialogueManager` already exists at test runtime. Adding a mock node with `name = "DialogueManager"` caused Godot to silently rename it to `DialogueManager2`. `get_node_or_null("/root/DialogueManager")` returned the real Autoload (with `is_active = false` default), so `_can_trigger()` returned `true` instead of `false`.
- **Fix**: Removed `_DialogueManagerStub` inner class. All 3 DialogueManager tests now use the Autoload singleton directly (`DialogueManager.is_active = true/false`) with save/restore pattern.
- **Files changed**: `tests/unit/scene/portal_transition_test.gd`

#### RC-2: GUT treats push_error() as Unexpected Error unless consumed
- **Affected**: `scene_transition_fsm_test.gd` — `test_ac6_load_failed_sets_state_to_idle`, `test_ac6_load_failed_overlay_remains_visible`
- **Root cause**: `_handle_load_status(THREAD_LOAD_FAILED)` calls `push_error()` by design (correct logging). GUT 9.x counts unclaimed `push_error()` calls as "Unexpected Errors" and fails the test even when all assertions pass.
- **Fix**: Added `assert_push_error_count(1)` before the state assertions. This "consumes" the expected error so GUT no longer treats it as unexpected. `assert_engine_error_count(1)` was tried first (wrong — that's for C++ engine errors, not GDScript push_error).
- **Files changed**: `tests/unit/scene/scene_transition_fsm_test.gd`

---

## Risky Tests (not failures)

| Test | Reason |
|------|--------|
| `test_f2a_normalization_requires_hardware` | Hardware-dependent — no assert by design |
| `test_game_confirm_events_have_zero_overlap_with_ui_accept` | Platform-dependent — no assert by design |

These are intentional placeholders and do not block CI.

---

## Lessons Learned

1. **Autoload + mock injection**: When an Autoload is registered, attempting to add a mock node with the same name to `/root` will silently rename it. Always use the Autoload singleton directly in tests; save and restore state in cleanup.
2. **GUT push_error tracking**: Use `assert_push_error_count(N)` (not `assert_engine_error_count`) to acknowledge expected `push_error()` calls from GDScript. `assert_engine_error_count` is for C++-level Godot engine errors only.
