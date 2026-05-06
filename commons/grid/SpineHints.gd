extends RefCounted
class_name SpineHints

## Canonical reader for artifact spine_hints() declarations.
## See doc/SPINE_HINTS_CONTRACT.md for the full contract.
##
## Use `SpineHints.read(artifact_node)` to get a fully-populated dict
## with every key present (missing keys fall back to defaults). The
## generator and the audit tool both go through this reader so there
## is ONE place the defaults live.

const ROLE_PRIMARY := "primary"
const ROLE_SUPPORTING := "supporting"
const ROLE_REFLECTION := "reflection"
const ROLE_AMBIENT := "ambient"

const APPROACH_SOUTH := "south"
const APPROACH_ANY := "any"

const DEFAULTS := {
	"role":         "supporting",
	"footprint":    Vector2i(1, 1),
	"approach":     "any",
	"reading_dist": 1.0,
	"height":       0.0,
	"rotation_y":   -1,
	"budget_ms":    0.5,
	"tags":         [],
}


## Read hints from any node. Returns a dict with ALL contract keys
## present — missing keys are filled with defaults. Node may be null,
## in which case the full default dict is returned.
static func read(node: Node) -> Dictionary:
	var hints: Dictionary = {}
	if node != null and node.has_method("spine_hints"):
		var raw = node.call("spine_hints")
		if raw is Dictionary:
			hints = raw
	return _merge_with_defaults(hints)


## Same as read(), but the artifact is identified by lookup token and
## the scene has to be instantiated just to read the hints. Useful for
## the audit tool and the generator which work off token lists.
static func read_by_scene_path(scene_path: String) -> Dictionary:
	if not ResourceLoader.exists(scene_path):
		return _merge_with_defaults({})
	var scene: PackedScene = load(scene_path)
	if scene == null: return _merge_with_defaults({})
	var inst: Node = scene.instantiate()
	if inst == null: return _merge_with_defaults({})
	var out := read(inst)
	inst.queue_free()
	return out


## Validate a hints dict. Returns a list of warnings (empty = valid).
static func validate(hints: Dictionary) -> Array[String]:
	var warnings: Array[String] = []
	var role: String = str(hints.get("role", ""))
	if not [ROLE_PRIMARY, ROLE_SUPPORTING, ROLE_REFLECTION, ROLE_AMBIENT].has(role):
		warnings.append("unknown role '%s'" % role)

	var fp = hints.get("footprint", Vector2i(1, 1))
	if not (fp is Vector2i):
		warnings.append("footprint must be Vector2i, got %s" % typeof(fp))
	elif fp.x < 1 or fp.y < 1:
		warnings.append("footprint must be >= 1x1, got %s" % str(fp))
	elif fp.x > 8 or fp.y > 16:
		warnings.append("footprint exceeds corridor frame (8x16), got %s" % str(fp))

	var approach := str(hints.get("approach", ""))
	if not [APPROACH_SOUTH, APPROACH_ANY].has(approach):
		warnings.append("unknown approach '%s'" % approach)

	var rd: float = float(hints.get("reading_dist", 0.0))
	if rd < 0.0 or rd > 8.0:
		warnings.append("reading_dist out of range [0..8], got %.2f" % rd)

	var budget: float = float(hints.get("budget_ms", 0.0))
	if budget < 0.0 or budget > 11.0:
		warnings.append("budget_ms out of range [0..11], got %.2f" % budget)

	return warnings


## Does this artifact declare hints at all, or is it running on defaults?
static func has_hints(node: Node) -> bool:
	return node != null and node.has_method("spine_hints")


static func _merge_with_defaults(hints: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for k in DEFAULTS.keys():
		if hints.has(k):
			out[k] = hints[k]
		else:
			out[k] = DEFAULTS[k]
	# Preserve extra keys the artifact might have added
	for k in hints.keys():
		if not out.has(k):
			out[k] = hints[k]
	return out
