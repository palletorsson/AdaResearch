@tool
extends RefCounted
class_name NeedsModel

## What an artifact NEEDS to live (life-support) + how it loads the structure.
##
## The compression seed for "logical" map generation: declare what each artifact needs, and the
## building can be DERIVED from it — structure (what must be supported), systems (what must be
## routed from a source), and packaging (how it sits). Without needs the generator can only PACK;
## with needs it can REASON about why every wall, pipe and empty space is there.
##
## Needs are INFERRED from an artifact's tags / category / lookup_name (so the whole catalogue
## gets sensible defaults for free); an explicit `spatial_needs.needs` dict overrides per artifact.

## Life-support systems that must REACH the artifact (a source -> a routed edge -> this sink).
const LIFE := ["power", "fluid", "data", "vent", "waste"]
## Structural: load 0 (light) · 1 (normal) · 2 (heavy → needs a supported slab); hangs (needs a ceiling).

const _POWER := ["screen", "readout", "monitor", "display", "console", "light", "lamp", "panel",
	"terminal", "meter", "gauge", "scanner", "machine", "reactor", "server", "computer", "motor"]
const _DATA := ["screen", "readout", "monitor", "display", "console", "data", "server", "computer",
	"terminal", "network", "scanner", "compute"]
const _FLUID := ["sink", "wash", "fluid", "water", "coolant", "pump", "tank", "drain", "hydro", "bath"]
const _HEAVY := ["machine", "reactor", "engine", "server", "cabinet", "furnace", "burner", "motor",
	"generator", "compressor", "fume", "autoclave", "press", "forge", "tank"]
const _HANGS := ["lamp", "light", "vent", "duct", "fan", "sign", "banner", "rail", "gantry"]


## Returns { power, fluid, data, vent, waste : bool ; load : int(0..2) ; hangs : bool }.
static func infer(tags: Array, category: String, lookup: String, spatial_needs: Dictionary = {}) -> Dictionary:
	var n := {"power": false, "fluid": false, "data": false, "vent": false, "waste": false, "load": 0, "hangs": false}
	var s := (" ".join(PackedStringArray(tags)) + " " + str(category) + " " + str(lookup)).to_lower()

	if _has(s, _POWER): n["power"] = true
	if _has(s, _DATA): n["data"] = true
	if _has(s, _FLUID): n["fluid"] = true; n["waste"] = true
	if _has(s, _HEAVY): n["power"] = true; n["vent"] = true; n["load"] = 2
	if _has(s, _HANGS): n["hangs"] = true

	# structural load also follows footprint size (a big thing is heavy / needs support)
	var fp := int(spatial_needs.get("footprint_cells", 1))
	if fp >= 6: n["load"] = maxi(int(n["load"]), 2)
	elif fp >= 3: n["load"] = maxi(int(n["load"]), 1)

	# explicit per-artifact override wins
	var ex = spatial_needs.get("needs")
	if ex is Dictionary:
		for k in ex.keys():
			n[k] = ex[k]
	return n


## The systems this artifact draws (the LIFE keys that are true) — the edges to route to it.
static func systems_for(need: Dictionary) -> Array:
	var out: Array = []
	for k in LIFE:
		if bool(need.get(k, false)):
			out.append(k)
	return out


static func _has(s: String, kws: Array) -> bool:
	for k in kws:
		if str(k) in s:
			return true
	return false
