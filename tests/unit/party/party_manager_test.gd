extends GutTest

## Tests for PartyManager: register_companion, is_recruited, get_companions,
## companion_count, MAX_PARTY_SIZE enforcement.
## Covers story-001 ACs: AC-1 through AC-5.
## AC-6 (scene persistence) is a manual playtest item — not automated.

var _party: PartyManager

func before_each() -> void:
	# load() avoids Autoload-name-shadowing: PartyManager as a class_name + Autoload means
	# PartyManager.new() would call .new() on the singleton instance, which fails.
	_party = load("res://src/core/party_manager.gd").new()

func after_each() -> void:
	# PartyManager extends Node, so queue_free() is correct here.
	_party.queue_free()

# ---------------------------------------------------------------------------
# AC-1: register_companion() → is_recruited() true
# ---------------------------------------------------------------------------

func test_register_companion_is_recruited_returns_true() -> void:
	_party.register_companion(&"aria")
	assert_true(_party.is_recruited(&"aria"))

func test_is_recruited_unregistered_returns_false() -> void:
	assert_false(_party.is_recruited(&"aria"))

# ---------------------------------------------------------------------------
# AC-2: companion_count matches registered count
# ---------------------------------------------------------------------------

func test_companion_count_zero_when_empty() -> void:
	assert_eq(_party.companion_count, 0)

func test_companion_count_one_after_single_register() -> void:
	_party.register_companion(&"aria")
	assert_eq(_party.companion_count, 1)

func test_companion_count_two_after_two_registers() -> void:
	_party.register_companion(&"aria")
	_party.register_companion(&"bran")
	assert_eq(_party.companion_count, 2)

func test_companion_count_three_at_max() -> void:
	_party.register_companion(&"aria")
	_party.register_companion(&"bran")
	_party.register_companion(&"ceri")
	assert_eq(_party.companion_count, 3)

# ---------------------------------------------------------------------------
# AC-3: duplicate registration is ignored
# ---------------------------------------------------------------------------

func test_duplicate_register_count_remains_one() -> void:
	_party.register_companion(&"aria")
	_party.register_companion(&"aria")
	assert_eq(_party.companion_count, 1)

func test_duplicate_register_is_recruited_still_true() -> void:
	_party.register_companion(&"aria")
	_party.register_companion(&"aria")
	assert_true(_party.is_recruited(&"aria"))

# ---------------------------------------------------------------------------
# AC-4: MAX_PARTY_SIZE (3) exceeded — 4th companion rejected
# ---------------------------------------------------------------------------

func test_fourth_companion_not_registered_when_full() -> void:
	_party.register_companion(&"aria")
	_party.register_companion(&"bran")
	_party.register_companion(&"ceri")
	_party.register_companion(&"deon")
	assert_false(_party.is_recruited(&"deon"))

func test_companion_count_stays_three_when_full() -> void:
	_party.register_companion(&"aria")
	_party.register_companion(&"bran")
	_party.register_companion(&"ceri")
	_party.register_companion(&"deon")
	assert_eq(_party.companion_count, 3)

func test_max_party_size_constant_is_three() -> void:
	assert_eq(PartyManager.MAX_PARTY_SIZE, 3)

# ---------------------------------------------------------------------------
# AC-5: get_companions() returns independent copy
# ---------------------------------------------------------------------------

func test_get_companions_append_does_not_affect_count() -> void:
	_party.register_companion(&"aria")
	var list := _party.get_companions()
	list.append(&"fake")
	assert_eq(_party.companion_count, 1)

func test_get_companions_append_fake_not_recruited() -> void:
	_party.register_companion(&"aria")
	var list := _party.get_companions()
	list.append(&"fake")
	assert_false(_party.is_recruited(&"fake"))

func test_get_companions_returns_correct_members() -> void:
	_party.register_companion(&"aria")
	_party.register_companion(&"bran")
	var list := _party.get_companions()
	assert_eq(list.size(), 2)
	assert_true(list.has(&"aria"))
	assert_true(list.has(&"bran"))

func test_get_companions_empty_when_no_members() -> void:
	var list := _party.get_companions()
	assert_eq(list.size(), 0)
