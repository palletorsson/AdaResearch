# @identity
# essence: wardrobe = a VIEW of MapProgressionManager, worn on the body
# desire: to hold no state of its own, so the costume can never disagree with the walk
# critical_parameter: which sequences are completed — everything else is derived from that
# triggers: sequence_completed; and a catch-up sweep on every launch
# emerges: put the headset on after a month away and the garment is already what you earned
# needs: MapProgressionManager [autoload]; an XROrigin3D to hang the costume on
# relationships: builds queer_costume, asks costume_trophies for the objects
# truth: a record that is saved separately from what it records will eventually lie about it.

extends Node
class_name CostumeWardrobe

## THE ACCRETION (2026-08-27, Palle: "attach beautiful thing to it as we go
## along the sequences").
##
## IT SAVES NOTHING. The obvious build is a second save file listing what you
## have been given — and a second save file is a second version of the truth,
## which drifts the first time a sequence is completed while it is not loaded.
## MapProgressionManager already knows which sequences are finished and already
## persists that. So the costume is recomputed from it at every launch and after
## every completion: the garment is a rendering of the progression, not a copy
## of it. Delete the costume and nothing is lost; delete the progression and the
## costume is honestly empty.
##
## The spine order matters, because the garment grows downward and outward: the
## nth completed sequence is the nth tier of the shift, whichever order they
## happened to be finished in.

## the twenty-two, in spine order (curriculum_spine.json § spine.sequences)
const SPINE := [
	"primitives", "transformation", "color", "change", "forces", "formfinding",
	"wavefunctions", "randomness", "noise", "cellularautomata", "fractals",
	"lsystems", "proceduralgeneration", "softbodies", "isosurfaces",
	"boolean_surfaces", "swarmintelligence", "machinelearning", "graphtheory",
	"foundationscrisis", "qfeplaboratory", "postfoundationscrisis",
]

## PRELOAD, NOT class_name. A global class resolves only once the editor has
## written the script-class cache, so a headless boot on a fresh checkout — which
## is every gate this repo runs — cannot see CostumeTrophies at all. Preload is
## resolved by the parser from the path and works everywhere.
const Trophies := preload("res://commons/player/costume_trophies.gd")
const Costume := preload("res://commons/player/queer_costume.gd")

signal costume_grew(sequence: String, stage: int)

@export var enabled: bool = true
## where to hang it — left empty it finds the XROrigin3D itself
@export var mount_path: NodePath
## WHICH PROGRESSION TO READ. Empty means the live autoload, which is what the
## game uses. A probe points this at a stub instead — the alternative is writing
## completions into the real save to see the restore work, and this repo has
## already learned what happens when a probe wears the player's shoes.
@export var manager_path: NodePath
## WHOSE HEAD TO WEAR IT ON. Empty means "find the XR rig", which is right in the
## game; the endless museum's desktop walker has no XR rig, so it passes its own
## camera here. Resolved relative to this node.
@export var head_path: NodePath

var costume: Node3D = null
var _given: Dictionary = {}          # sequence -> true, so a re-emit cannot double-pin
var _mount: Node3D = null


func _ready() -> void:
	if not enabled:
		return
	call_deferred("_start")


func _start() -> void:
	_mount = get_node_or_null(mount_path) as Node3D
	if _mount == null:
		_mount = _find_origin()
	if _mount == null:
		push_warning("wardrobe: no XROrigin3D to hang a costume on")
		return

	costume = Costume.new() as Node3D
	costume.name = "QueerCostume"
	_mount.add_child(costume)
	var head: Node3D = get_node_or_null(head_path) as Node3D if not head_path.is_empty() else null
	if head != null:
		costume.call("mount_on", head)
	elif costume.has_method("attach_to"):
		costume.call("attach_to", _mount)

	# THE SIGNAL FIRST, THEN THE CATCH-UP. The other order drops any completion
	# that lands during the sweep, which is a real window: the sweep touches
	# twenty-two sequences and the manager can emit inside it.
	var mgr: Node = _manager()
	if mgr != null and mgr.has_signal("sequence_completed"):
		if not mgr.is_connected("sequence_completed", Callable(self, "give")):
			mgr.connect("sequence_completed", Callable(self, "give"))
	else:
		push_warning("wardrobe: MapProgressionManager is not there — the costume cannot grow")
	catch_up()


func _find_origin() -> Node3D:
	var n: Node = get_parent()
	while n != null:
		if n is XROrigin3D:
			return n as Node3D
		n = n.get_parent()
	var tree := get_tree()
	if tree != null:
		for c in tree.root.find_children("*", "XROrigin3D", true, false):
			return c as Node3D
	return null


func _manager() -> Node:
	if not manager_path.is_empty():
		var m: Node = get_node_or_null(manager_path)
		if m != null:
			return m
	return get_node_or_null("/root/MapProgressionManager")


## Everything already finished, in spine order, silently — this is a restore,
## not twenty-two celebrations.
func catch_up() -> int:
	var mgr: Node = _manager()
	if mgr == null or not mgr.has_method("is_sequence_completed"):
		return 0
	var n := 0
	for seq in SPINE:
		if bool(mgr.call("is_sequence_completed", seq)):
			if give(seq, true):
				n += 1
	if n > 0:
		print("[wardrobe] restored %d sequence(s) onto the costume" % n)
	return n


## One sequence's worth of growth: the garment gains a tier, and that sequence's
## own object is hung on the body. Idempotent — a second emit changes nothing.
func give(sequence: String, quiet: bool = false) -> bool:
	if costume == null or not is_instance_valid(costume):
		return false
	if _given.has(sequence):
		return false
	_given[sequence] = true

	costume.call("grow")

	var trophy: Node3D = Trophies.make(sequence)
	if trophy != null:
		var slot: String = Trophies.slot_for(sequence)
		if not bool(costume.call("pin", trophy, slot)):
			trophy.queue_free()
		elif not quiet:
			print("[wardrobe] %s — a %s hung at the %s, stage %d"
				% [sequence, trophy.name, slot, int(costume.get("stage"))])
	emit_signal("costume_grew", sequence, int(costume.get("stage")))
	return true


func worn() -> Array:
	return _given.keys()
