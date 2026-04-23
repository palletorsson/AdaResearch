# GrammarOperationsManager.gd
# Runtime consumer of commons/artifacts/grammar_operations.json.
#
# grammar_operations.json declares 80 operations across 19 sequences, each producing
# a form_type (atom, segment, wave, field, automaton, fractal, growth, swarm, ...).
# This manager reads that declaration and gates runtime systems — primarily the
# biome — so forms do not manifest until the player has walked the sequence that
# teaches them.
#
# Example: the "tree" foliage type requires the "growth" form_type (L-systems,
# sequence 11). In sequences 1–10 the biome may support trees by density/kingdom
# rules, but trees will not spawn because the grammar has not unlocked branching.
#
# Consumers query:
#   GrammarOperationsManager.is_form_type_unlocked("growth")
#   GrammarOperationsManager.get_unlocked_form_types()
#   GrammarOperationsManager.filter_foliage_types(["grass", "tree", "mushroom"])
#
# Progression is read from EcosystemManager.get_current_stage_order().

extends Node

const GRAMMAR_FILE := "res://commons/artifacts/grammar_operations.json"

# Map foliage kind (from BiomeRingComponent.KINGDOM_FOLIAGE) to the form_type
# that must be unlocked before it can spawn. Foliage not listed is always allowed.
const FOLIAGE_GRAMMAR_GATE: Dictionary = {
	"tree": "growth",       # L-systems unlocks recursive branching (seq 11)
	"bush": "growth",       # same
	"mushroom": "automaton",# CA-like proliferation from locality (seq 8)
	"creature": "swarm",    # swarm intelligence (seq 13)
	"reed": "wave",         # wave-swaying grass stalks (seq 5)
}

var _sequences: Dictionary = {}       # seq_name -> { order: int, operations: { op_name -> {output, ...} } }
var _form_types: Dictionary = {}      # form_type -> emerges_in sequence
var _form_type_order: Dictionary = {} # form_type -> min sequence order required


func _ready() -> void:
	_load_grammar()
	_index_form_type_orders()
	print("GrammarOperationsManager: Loaded %d sequences, %d form types" % [
		_sequences.size(), _form_types.size()
	])


# ─────────────────────────────────────────────────────────────
# Public API
# ─────────────────────────────────────────────────────────────

## Minimum sequence order at which a form_type is producible.
## Returns -1 if unknown.
func get_form_type_order(form_type: String) -> int:
	return _form_type_order.get(form_type, -1)

## True if the player has progressed far enough for this form_type to exist.
func is_form_type_unlocked(form_type: String) -> bool:
	var required: int = get_form_type_order(form_type)
	if required < 0:
		return true  # Unknown form types pass through (no gate)
	return _current_order() >= required

## All form_types the current progression has unlocked.
func get_unlocked_form_types() -> Array[String]:
	var unlocked: Array[String] = []
	var order: int = _current_order()
	for ft in _form_type_order.keys():
		if _form_type_order[ft] <= order:
			unlocked.append(str(ft))
	return unlocked

## All operations the current progression has unlocked (names only).
func get_unlocked_operations() -> Array[String]:
	var ops: Array[String] = []
	var order: int = _current_order()
	for seq_name in _sequences.keys():
		var seq = _sequences[seq_name]
		if int(seq.get("order", 999)) > order:
			continue
		for op_name in seq.get("operations", {}).keys():
			ops.append(str(op_name))
	return ops

## Filter a list of foliage types by what the grammar currently allows.
## Used by BiomeRingComponent to drop tree/bush/creature before grammar unlocks them.
func filter_foliage_types(types: Array) -> Array[String]:
	var result: Array[String] = []
	for t in types:
		var key: String = str(t)
		var required_form: String = FOLIAGE_GRAMMAR_GATE.get(key, "")
		if required_form == "" or is_form_type_unlocked(required_form):
			result.append(key)
	return result


# ─────────────────────────────────────────────────────────────
# Internal
# ─────────────────────────────────────────────────────────────

func _current_order() -> int:
	var eco = get_node_or_null("/root/EcosystemManager")
	if eco and eco.has_method("get_current_stage_order"):
		return int(eco.get_current_stage_order())
	return 0

func _load_grammar() -> void:
	if not FileAccess.file_exists(GRAMMAR_FILE):
		push_error("GrammarOperationsManager: Not found: " + GRAMMAR_FILE)
		return
	var file := FileAccess.open(GRAMMAR_FILE, FileAccess.READ)
	if not file:
		return
	var text := file.get_as_text()
	file.close()
	var json := JSON.new()
	if json.parse(text) != OK or not json.data is Dictionary:
		push_error("GrammarOperationsManager: Parse error")
		return
	var data: Dictionary = json.data
	_sequences = data.get("sequences", {})
	_form_types = data.get("form_types", {})

## For each form_type, find the minimum sequence order in which an operation
## PRODUCES that form_type. That's the unlock threshold.
func _index_form_type_orders() -> void:
	_form_type_order.clear()
	for seq_name in _sequences.keys():
		var seq: Dictionary = _sequences[seq_name]
		var order: int = int(seq.get("order", 999))
		for op_name in seq.get("operations", {}).keys():
			var op: Dictionary = seq["operations"][op_name]
			var output = op.get("output", null)
			if output == null:
				continue
			var form: String = str(output)
			var existing: int = _form_type_order.get(form, 999)
			if order < existing:
				_form_type_order[form] = order
