extends RefCounted
## One card selects twelve hooks for one pick. No colour is encoded by a hole.
const THREADS := 12
const SLOTS := 8
const LIMIT := 128
var deck: Array = []
var history: Array = []
var cursor := 0
var active: Dictionary = {}

func _init() -> void:
	deck.resize(SLOTS)
	deck.fill(null)

static func preset(kind: String, row: int) -> Array:
	var bits: Array = []
	for col in range(THREADS):
		var on := (col + row) % 2 == 0
		if kind == "twill": on = posmod(col - row, 4) < 2
		elif kind == "diamond":
			var shift := row % 8 if row % 8 < 4 else 7 - row % 8
			on = posmod(col - shift, 4) < 2
		elif kind == "chevron":
			# Pointed draft, 0..6..1. The twill meets at a continuous turn.
			var step := col if col <= 6 else 12 - col
			on = posmod(step - row, 4) < 2
		elif kind == "herringbone":
			# Six ends each way, offset two phases at both reversing seams.
			var step := col if col < 6 else 13 - col
			on = posmod(step - row, 4) < 2
		bits.append(1 if on else 0)
	return bits

func put(slot: int, id: int, bits: Array) -> bool:
	if slot < 0 or slot >= SLOTS or bits.size() != THREADS: return false
	for bit in bits:
		if not (bit is int) or (bit != 0 and bit != 1): return false
	if deck[slot] != null and int(deck[slot].id) != id: return false
	remove(id)
	deck[slot] = {"id": id, "bits": bits.duplicate()}
	return true

func remove(id: int) -> void:
	for slot in range(SLOTS):
		if deck[slot] != null and int(deck[slot].id) == id: deck[slot] = null

func next_slot() -> int:
	for offset in range(SLOTS):
		var slot := (cursor + offset) % SLOTS
		if deck[slot] != null: return slot
	return -1

func begin(warp: Array = [], weft: String = "e84b7e") -> bool:
	if not active.is_empty() or history.size() >= LIMIT: return false
	var slot := next_slot()
	if slot < 0: return false
	active = deck[slot].duplicate(true)
	active["slot"] = slot
	var colours: Array = warp.duplicate()
	if colours.is_empty():
		colours.resize(THREADS); colours.fill("f3e6c8")
	# Colour order need not have the same period as the twelve-hook lift.
	if colours.size()>96:
		active.clear(); return false
	active["warp_colors"] = colours
	active["weft_color"] = weft
	return true

func commit() -> bool:
	if active.is_empty(): return false
	history.append(active.duplicate(true))
	cursor = (int(active.slot) + 1) % SLOTS
	active.clear()
	return true

func reset() -> void:
	history.clear()
	active.clear()
	cursor = 0

func snapshot() -> Array:
	return history.duplicate(true)
