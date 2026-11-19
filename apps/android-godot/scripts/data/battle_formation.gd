extends RefCounted
class_name BattleFormation

## Fixed 5v5 side-view slots: 2 front + 3 back (BATTLE-001 B / DEC-005).
## Positions are world coords for 1080×1920 portrait. Facing is NOT encoded here —
## callers set battle_side + desired_facing from side / target.

const ARENA_CENTER_X := 540.0
const FRONT_Y := 1040.0
const BACK_Y := 900.0

## Local offsets from side anchor (positive X = toward arena center).
## Front row: two tanks/bruisers. Back row: three supports/DPS.
const FRONT_OFFSETS: Array[Vector2] = [
	Vector2(0, 0),
	Vector2(0, 95),
]
const BACK_OFFSETS: Array[Vector2] = [
	Vector2(-120, -35),
	Vector2(-135, 55),
	Vector2(-115, 145),
]

static func side_anchor_x(side_left: bool) -> float:
	return 260.0 if side_left else 820.0

static func slot_count_front() -> int:
	return FRONT_OFFSETS.size()

static func slot_count_back() -> int:
	return BACK_OFFSETS.size()

static func total_slots() -> int:
	return slot_count_front() + slot_count_back()

## index: 0..1 front, 2..4 back (canonical roster order).
static func position_for_index(side_left: bool, slot_index: int) -> Vector2:
	var idx := clampi(slot_index, 0, total_slots() - 1)
	var anchor_x := side_anchor_x(side_left)
	var toward_center := 1.0 if side_left else -1.0
	var off: Vector2
	if idx < slot_count_front():
		off = FRONT_OFFSETS[idx]
		return Vector2(anchor_x + toward_center * off.x, FRONT_Y + off.y)
	off = BACK_OFFSETS[idx - slot_count_front()]
	return Vector2(anchor_x + toward_center * off.x, BACK_Y + off.y)

static func is_front_slot(slot_index: int) -> bool:
	return slot_index < slot_count_front()

static func apply_to_fighter(f: Fighter, side_left: bool, slot_index: int) -> void:
	f.battle_side = Fighter.BattleSide.LEFT if side_left else Fighter.BattleSide.RIGHT
	f.is_front_row = is_front_slot(slot_index)
	f.global_position = position_for_index(side_left, slot_index)
	f.home_pos = f.global_position
	f.home_y = f.global_position.y
	f.default_side_facing()
