extends Node
# ExamGate — the wire from a chapter's prove-it puzzle to progression.
#
# The baselines give every chapter a "prove it" beat (snap the tetrahedron,
# balance the stack, match the target). Those puzzles emit a solve-signal when
# passed — but nothing was connected to it, so the exams existed and were not
# gates. This autoload IS that connection, and it is deliberately the ONE place
# it lives: it watches every node that enters the tree, and if the node carries
# a known solve-signal, it wires that signal to complete the CURRENT map in
# MapProgressionManager. No puzzle file is touched; new puzzles are gated for
# free the moment they emit any of the canonical signals below.
#
# Canonical convention for future puzzles: emit `exam_passed` (0 args) on solve.

# Solve-signals this gate recognizes, across the heterogeneous prove-it family.
const SOLVE_SIGNALS := [
	"exam_passed",              # canonical (new puzzles should emit this)
	"puzzle_solved",            # SnapPointPuzzleBase (tetra / snap family)
	"transformation_complete",  # balance_puzzle (stack goes still)
	"puzzle_completed",
	"target_completed",
	"proof_complete",
]

var _wired: Dictionary = {}   # instance_id -> true (guard against double-wire)
var _passed_this_map: bool = false

signal exam_gated(map_name: String)   # fires when a map is completed by its exam

func _gm() -> Node:
	return get_node_or_null("/root/GameManager")

func _mpm() -> Node:
	return get_node_or_null("/root/MapProgressionManager")

func _ready() -> void:
	# catch every node that ever enters the scene, wherever a map spawns it
	get_tree().node_added.connect(_on_node_added)
	# reset the per-map guard when the map changes
	var gm := _gm()
	if gm and gm.has_signal("current_map_changed"):
		gm.current_map_changed.connect(func(_m): _passed_this_map = false)
	# wire anything already in the tree (map may have loaded before us)
	call_deferred("_scan_existing")

func _scan_existing() -> void:
	# out-of-tree guard: get_tree() is null once a map is torn down
	if not is_inside_tree():
		return
	_walk(get_tree().root)

func _walk(n: Node) -> void:
	_on_node_added(n)
	for c in n.get_children():
		_walk(c)

func _on_node_added(node: Node) -> void:
	var id := node.get_instance_id()
	if _wired.has(id):
		return
	for sig in SOLVE_SIGNALS:
		if node.has_signal(sig):
			# bind the source name so we can log which exam gated the map
			node.connect(sig, _on_exam_passed.bind(node.name), CONNECT_DEFERRED)
			_wired[id] = true
			return

func _on_exam_passed(_a = null, _b = null, _c = null, _d = null, source: String = "") -> void:
	# tolerate solve-signals that carry payload args (points[], etc.); the last
	# bound arg is the source name. Godot appends bound args after signal args,
	# so pull source from whichever slot holds a non-null String we recognize.
	var src := source
	for v in [_d, _c, _b, _a]:
		if typeof(v) == TYPE_STRING and src == "":
			src = str(v)
			break
	if _passed_this_map:
		return
	var gm := _gm()
	var mpm := _mpm()
	var map_name := ""
	if gm and gm.has_method("get_current_map"):
		map_name = str(gm.get_current_map())
	if map_name == "" and mpm:
		map_name = str(mpm.current_map)
	if map_name == "":
		print("[ExamGate] exam passed (%s) but no current map known — not gated" % src)
		return
	_passed_this_map = true
	if mpm and mpm.has_method("complete_map"):
		var unlocked = mpm.complete_map(map_name)
		print("[ExamGate] '%s' passed (%s) -> map complete; unlocked %s" % [map_name, src, str(unlocked)])
	exam_gated.emit(map_name)

# public: any puzzle can call this directly instead of emitting a signal
func pass_exam(source: String = "manual") -> void:
	_on_exam_passed(null, null, null, null, source)
