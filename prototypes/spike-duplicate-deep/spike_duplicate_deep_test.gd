extends GutTest

# Spike: duplicate_deep() — NPCRegistry 스냅샷 무결성
# ADR-0001: get_snapshot()은 deep copy 배열을 반환해야 한다.

func _make_record(id: StringName, hp: int) -> SpikeRecord:
	var stats := SpikeStats.new()
	stats.hp = hp
	var rec := SpikeRecord.new()
	rec.npc_id = id
	rec.stats = stats
	return rec

# --- 단일 레코드 deep copy ---

func test_duplicate_true_creates_independent_stats() -> void:
	var original := _make_record(&"npc_01", 100)
	var copy: SpikeRecord = original.duplicate(true)

	original.stats.hp = 999

	assert_eq(copy.stats.hp, 100,
		"duplicate(true) 후 원본 stats 변경이 복사본에 영향을 주지 않아야 한다")

func test_duplicate_true_stats_is_different_object() -> void:
	var original := _make_record(&"npc_01", 100)
	var copy: SpikeRecord = original.duplicate(true)

	assert_ne(original.stats, copy.stats,
		"duplicate(true) 후 stats가 다른 객체여야 한다")

func test_duplicate_false_stats_is_same_object() -> void:
	var original := _make_record(&"npc_01", 100)
	var copy: SpikeRecord = original.duplicate(false)

	assert_eq(original.stats, copy.stats,
		"duplicate(false) 는 shallow copy — stats가 동일 객체여야 한다")

# --- 배열 스냅샷 ---

func test_array_snapshot_independence() -> void:
	var records: Array[SpikeRecord] = []
	records.append(_make_record(&"npc_01", 100))
	records.append(_make_record(&"npc_02", 200))

	# get_snapshot() 모사: 배열 각 원소를 duplicate(true)
	var snapshot: Array[SpikeRecord] = []
	for rec: SpikeRecord in records:
		snapshot.append(rec.duplicate(true) as SpikeRecord)

	# 원본 변경
	records[0].stats.hp = 999
	records[1].stats.hp = 888

	assert_eq(snapshot[0].stats.hp, 100,
		"스냅샷[0] hp가 원본 변경 후에도 100이어야 한다")
	assert_eq(snapshot[1].stats.hp, 200,
		"스냅샷[1] hp가 원본 변경 후에도 200이어야 한다")

func test_snapshot_count_matches_original() -> void:
	var records: Array[SpikeRecord] = []
	for i in range(5):
		records.append(_make_record(StringName("npc_%02d" % i), i * 10))

	var snapshot: Array[SpikeRecord] = []
	for rec: SpikeRecord in records:
		snapshot.append(rec.duplicate(true) as SpikeRecord)

	assert_eq(snapshot.size(), 5, "스냅샷 원소 수가 원본과 같아야 한다")

func test_modifying_snapshot_does_not_affect_original() -> void:
	var original := _make_record(&"npc_01", 100)
	var copy: SpikeRecord = original.duplicate(true)

	copy.stats.hp = 42

	assert_eq(original.stats.hp, 100,
		"복사본 변경이 원본에 영향을 주지 않아야 한다")
