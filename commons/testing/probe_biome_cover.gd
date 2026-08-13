extends SceneTree

## probe_biome_cover.gd — the VR budget gate for halo/edge ground cover.
##
## Cover is the biome's largest visible surface by a wide margin: 241 halo cells
## across 13 shipped maps against 116 seeds. It is also the cheapest thing to make
## accidentally expensive, because every recipe is instanced tens of times per cell
## and the count is invisible at the call site — you write `SphereMesh.new()` and
## a rings/segments default decides your triangle bill.
##
## So the rule this gate enforces is per-RECIPE, not per-frame: no cover mesh may
## exceed TRI_CAP triangles, and the projected worst case for a real map must stay
## under WORST_CASE_TRIS. Both are checked against the actual meshes the component
## builds, not against a table someone maintained by hand.
##
## Run:  <godot> --headless --path . --xr-mode off --script res://commons/testing/probe_biome_cover.gd

const ComponentScript = preload("res://commons/grid/GridBiomeComponent.gd")

const KINGDOMS: Array = ["flora", "fungus", "fauna", "mineral", "water", "meta", "?"]
const TRI_CAP: int = 48
# The heaviest shipped halo map, measured: 241 cells corpus-wide, and _spawn_halo
# targets lerp(10,50,density) instances per band with up to 2 bands on a corner.
const WORST_CELLS: int = 241
const WORST_PER_CELL: int = 50
const WORST_CASE_TRIS: int = 900000

const REPORT: String = "res://doc/reports/biome_cover_budget.txt"

var _failures: int = 0
var _lines: PackedStringArray = []
var _log: FileAccess = null


# stdout is not a reliable channel here: the v4.6 non-console exe swallows it, and
# the autoload banner buries it in the console build. The report file is the one
# the watchdog can wait on and a later session can diff.
#
# It is written INCREMENTALLY and flushed. A SceneTree script that hits a runtime
# error before reaching quit() does not crash — it spins forever with no output,
# which is indistinguishable from a hang and cost this probe two watchdog kills
# before the file told me which mesh it died on.
func _say(s: String) -> void:
	print(s)
	_lines.append(s)
	if _log != null:
		_log.store_line(s)
		_log.flush()


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://doc/reports"))
	_log = FileAccess.open(REPORT, FileAccess.WRITE)
	var comp = ComponentScript.new()
	_say("── probe_biome_cover ──")
	_say("%-9s %-12s %6s %6s %8s" % ["kingdom", "recipe", "verts", "tris", "fraction"])
	var worst_weighted: float = 0.0
	for kingdom in KINGDOMS:
		var recipes: Array = comp._build_halo_recipes(kingdom)
		var weighted: float = 0.0
		for r in recipes:
			_say("  ... building %s/%s" % [kingdom, String(r["name"])])
			var mesh: Mesh = r["mesh"]
			var counts: Array = _count(mesh)
			var tris: int = counts[1]
			var frac: float = float(r.get("fraction", 1.0))
			weighted += float(tris) * frac
			var flag: String = ""
			if tris > TRI_CAP:
				flag = "  <- OVER CAP %d" % TRI_CAP
				_failures += 1
			_say("%-9s %-12s %6d %6d %8.2f%s"
				% [kingdom, String(r["name"]), counts[0], tris, frac, flag])
		# an instance is ONE recipe drawn once; fractions sum to 1 across a kingdom,
		# so the weighted mean is the true per-instance triangle cost.
		_say("%-9s %-12s %6s %6.1f  (mean per instance)" % [kingdom, "", "", weighted])
		worst_weighted = maxf(worst_weighted, weighted)
	var projected: int = int(worst_weighted * float(WORST_CELLS) * float(WORST_PER_CELL))
	_say("")
	_say("worst kingdom mean = %.1f tris/instance" % worst_weighted)
	_say("projected worst-case map = %d cells x %d instances = %d tris"
		% [WORST_CELLS, WORST_PER_CELL, projected])
	if projected > WORST_CASE_TRIS:
		_say("  <- OVER BUDGET %d" % WORST_CASE_TRIS)
		_failures += 1
	comp.free()
	_say("")
	_say("FAIL (%d)" % _failures if _failures > 0 else "PASS")
	var f := FileAccess.open(REPORT, FileAccess.WRITE)
	if f != null:
		f.store_string("\n".join(_lines) + "\n")
		f.close()
	quit(1 if _failures > 0 else 0)


func _count(mesh: Mesh) -> Array:
	# Primitive meshes generate their arrays on the CPU, so this is valid headless
	# — unlike MultiMesh instance data, which the dummy renderer silently drops.
	if mesh == null or mesh.get_surface_count() == 0:
		return [0, 0]
	var arrays: Array = mesh.surface_get_arrays(0)
	if arrays.is_empty():
		return [0, 0]
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	# ARRAY_INDEX is NIL on an unindexed surface, and assigning nil to a typed
	# PackedInt32Array throws. Every primitive mesh is indexed, so the first
	# version of this ran clean against the old recipes and died on the first
	# SurfaceTool mesh — with no output at all, because the error left the
	# SceneTree spinning short of quit(). Read it untyped, then decide.
	var raw_idx: Variant = arrays[Mesh.ARRAY_INDEX]
	var idx_count: int = (raw_idx as PackedInt32Array).size() if raw_idx != null else 0
	var tris: int = (idx_count / 3) if idx_count > 0 else (verts.size() / 3)
	return [verts.size(), tris]
