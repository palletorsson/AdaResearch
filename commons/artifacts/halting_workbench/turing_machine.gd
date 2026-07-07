extends RefCounted
class_name TuringMachine

## Step-by-step simulator for a single-tape, single-head, binary-alphabet Turing
## machine. Mirrors the simulator embedded in
##   res://commons/testing/capture_halting_bench_gallery.gd
## so the workbench and the gallery share a single source of truth for what
## "halts" means.
##
## A machine spec is a Dictionary:
##   {
##     "id":           String,
##     "name":         String,
##     "rules":        Dictionary { "STATE|READ" -> [WRITE, MOVE, NEXT_STATE] }
##     "halt_state":   String,    # canonical "H"
##     "step_budget":  int,       # upper bound for the workbench's auto-run
##     "expected_halt": bool,
##     "category":     "halts" | "never_halts" | "unknown",
##     "notes":        String,
##   }
##
## Rule semantics (matching capture_halting_bench_gallery.gd):
##   read tape at head -> look up "STATE|READ" -> write back, move ±1, switch state.
##   Missing transition -> halt by convention (we set state := halt_state).
##   Reaching halt_state stops stepping; further calls become no-ops.
##
## Tape is sparse: Dictionary { position:int -> "0"/"1" }. Cells unseen are "0".


var spec: Dictionary = {}
var tape: Dictionary = {}     # int -> "0" or "1"
var head: int = 0
var state: String = "A"
var halt_state: String = "H"
var steps: int = 0
var halted: bool = false
var ones_written: int = 0


# ── Lifecycle ─────────────────────────────────────────────────────────

func load_spec(s: Dictionary) -> void:
	spec = s
	reset()


func reset() -> void:
	tape = {}
	head = 0
	state = "A"
	halt_state = spec.get("halt_state", "H")
	steps = 0
	halted = false
	ones_written = 0


# ── Stepping ──────────────────────────────────────────────────────────

func step() -> bool:
	# Returns true if a step actually occurred. Returns false if the machine
	# is already halted (or undefined-transitioned itself into halt).
	if halted:
		return false
	if state == halt_state:
		halted = true
		return false

	var rules: Dictionary = spec.get("rules", {})
	var read_symbol: String = "0"
	if tape.has(head):
		read_symbol = tape[head]
	var key: String = "%s|%s" % [state, read_symbol]
	if not rules.has(key):
		# Undefined transition -> conventional halt.
		state = halt_state
		halted = true
		return false

	var rule: Array = rules[key]
	var write_symbol: String = str(rule[0])
	# Track ones_written: only count "1"s currently on the tape.
	# Easier to recount than to track deltas if we ever erase.
	tape[head] = write_symbol
	head += int(rule[1])
	state = str(rule[2])
	steps += 1

	if state == halt_state:
		halted = true

	# Recount ones (cheap for the BB tape sizes we ever reach).
	ones_written = 0
	for k in tape.keys():
		if tape[k] == "1":
			ones_written += 1

	return true


func run_until(target_steps: int) -> void:
	# Step until either we reach target_steps OR the machine halts.
	# Cheaply re-entrant: a second call with the same target is a no-op.
	# Capped at spec.step_budget to keep the workbench responsive — auto-run
	# is for surveying behaviour, not for proving non-halting.
	var budget: int = int(spec.get("step_budget", 200))
	var cap: int = min(target_steps, budget)
	while steps < cap and not halted:
		if not step():
			break


# ── Tape rendering helpers ────────────────────────────────────────────

func tape_window(visible: int) -> PackedStringArray:
	# Return TAPE_VISIBLE symbols centered on the head: out[0] is leftmost,
	# out[center] is the head cell, out[-1] is rightmost. Symbols are "0"/"1".
	var out := PackedStringArray()
	out.resize(visible)
	var half: int = visible / 2  # rounds down — for odd 'visible' the head sits at index half
	for i in range(visible):
		var pos: int = head + (i - half)
		out[i] = str(tape.get(pos, "0"))
	return out
