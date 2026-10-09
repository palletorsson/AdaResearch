## Editorial audit copy: seed expectations independently recounted; deferred until SceneTree initializes.
## probe_chroma2.gd — the negative tests the chroma2 spec asks for, in one boot.
##
##   godot --headless --path . --xr-mode off --script res://commons/testing/probe_chroma2.gd
##
## Reads back the REAL objects (never the scripts' own bookkeeping):
##   chroma_filter  — Pane_0's surface material under mix=filter is a true filter
##                    (TRANSPARENCY_ALPHA + BLEND_MODE_MUL + UNSHADED + cast_shadow OFF +
##                    CULL_BACK); an unknown triad word falls back to paint (cyan pane 0).
##   chroma_life    — the live cell SETS and neighbour counts for seed / crowd / field match
##                    the spec's transcription of the R-pentomino run; fixture cells stay dead.
##   chroma_drum    — mesh counts per value and a constant AABB across all six values.
## Prints PASS/FAIL lines; the summary line is the last thing printed before quit().
extends SceneTree

const FILTER := "res://commons/artifacts/chroma_filter/chroma_filter.tscn"
const LIFE := "res://commons/artifacts/chroma_life/chroma_life.tscn"
const DRUM := "res://commons/artifacts/chroma_drum/chroma_drum.tscn"

# (r, c): live neighbour count, from the spec's negative-test lists (bounded 8x8, B3/S23,
# R = (3,5),(3,6),(4,4),(4,5),(5,5); row 0 north, col 0 west).
const EXPECT := {
	"seed": {"3,5": 3, "3,6": 2, "4,4": 3, "4,5": 4, "5,5": 2},
	"crowd": {"1,4": 4, "1,5": 5, "1,6": 3, "2,3": 4, "2,4": 5, "2,5": 6, "2,6": 5, "3,2": 3, "3,3": 4,
		"3,6": 5, "3,7": 3, "4,3": 3, "4,5": 5, "4,6": 5, "5,4": 4, "5,5": 5, "5,6": 4, "6,5": 3},
	"field": {"1,1": 3, "1,2": 2, "2,0": 2, "2,2": 2, "3,0": 3, "4,0": 2, "4,1": 3, "4,2": 2, "4,5": 2,
		"5,3": 4, "5,4": 4, "5,6": 2, "6,3": 3, "6,4": 4, "6,6": 2, "7,5": 2},
}
const FIXTURE_CELLS := ["0,6", "0,7", "7,6", "7,7", "1,7", "6,7"]

var _pass := 0
var _fail := 0


func _check(ok: bool, what: String) -> void:
	if ok:
		_pass += 1
		print("PASS  " + what)
	else:
		_fail += 1
		print("FAIL  " + what)


func _spawn(path: String, meta: Dictionary) -> Node3D:
	var inst: Node3D = load(path).instantiate()
	for k in meta.keys():
		inst.set_meta("config_%s" % k, meta[k])   # the museum's way: config BEFORE _ready
	get_root().add_child(inst)
	return inst


func _mat(n: Node) -> StandardMaterial3D:
	var mi := n as MeshInstance3D
	if mi == null:
		return null
	return mi.get_surface_override_material(0) as StandardMaterial3D


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	# ---------------- chroma_filter ----------------
	var f := _spawn(FILTER, {"mix": "filter", "triad": "paint"})
	var m := _mat(f.get_node_or_null("Pane_0"))
	_check(m != null, "filter: Pane_0 carries a StandardMaterial3D surface override")
	if m != null:
		_check(m.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA, "filter: transparency is TRANSPARENCY_ALPHA (transparent pass)")
		_check(m.blend_mode == BaseMaterial3D.BLEND_MODE_MUL, "filter: blend_mode is MUL")
		_check(m.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED, "filter: unshaded")
		_check(m.cull_mode == BaseMaterial3D.CULL_BACK, "filter: cull_mode is CULL_BACK (one multiply per pane)")
		var mi0 := f.get_node("Pane_0") as MeshInstance3D
		_check(mi0.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "filter: pane casts no shadow")
		_check(m.albedo_color.b > 0.8 and m.albedo_color.r < 0.4, "filter: pane 0 is cyan under triad=paint")
	var aabb_f := _aabb(f)
	_check(absf(aabb_f.size.y - 4.40) < 0.05, "filter: height 4.40 (got %.2f)" % aabb_f.size.y)
	_check(absf(aabb_f.position.y) < 0.01, "filter: min y is 0 (got %.3f)" % aabb_f.position.y)
	f.queue_free()
	var f2 := _spawn(FILTER, {"mix": "veil", "triad": "cmy"})   # unknown triad word -> paint
	var m2 := _mat(f2.get_node_or_null("Pane_0"))
	_check(m2 != null and m2.blend_mode == BaseMaterial3D.BLEND_MODE_MIX and absf(m2.albedo_color.a - 0.5) < 0.01, "veil: MIX at alpha 0.5")
	_check(m2 != null and m2.albedo_color.b > 0.8, "unknown triad 'cmy' fell back to paint (cyan pane 0)")
	f2.queue_free()

	# ---------------- chroma_life ----------------
	for run in ["seed", "crowd", "field"]:
		var l := _spawn(LIFE, {"run": run, "paint": "age"})
		var got := {}
		for ch in l.get_children():
			if ch.name.begins_with("Column_"):
				var parts: PackedStringArray = String(ch.name).split("_")
				var mi := ch as MeshInstance3D
				var h: float = (mi.mesh as BoxMesh).size.y
				var n := int(roundf((h - 0.45) / 0.65))
				got["%s,%s" % [parts[1], parts[2]]] = n
		var exp: Dictionary = EXPECT[run]
		var same := got.size() == exp.size()
		for k in exp.keys():
			if not got.has(k) or got[k] != exp[k]:
				same = false
		_check(same, "life %s: live set and neighbour counts match the spec (%d columns, expected %d)" % [run, got.size(), exp.size()])
		var fixtures_dead := true
		for k in FIXTURE_CELLS:
			if got.has(k):
				fixtures_dead = false
		_check(fixtures_dead, "life %s: the six fixture cells are dead" % run)
		var a := _aabb(l)
		_check(absf(a.position.y) < 0.01, "life %s: min y 0" % run)
		l.queue_free()

	# ---------------- chroma_drum ----------------
	var sizes := []
	for face in ["shingle", "fin"]:
		for grain in ["coarse", "medium", "fine"]:
			var d := _spawn(DRUM, {"face": face, "grain": grain})
			var meshes := 0
			for ch in d.get_children():
				if ch is MeshInstance3D:
					meshes += 1
			var units: int = {"coarse": 16, "medium": 48, "fine": 192}[grain]
			var expect_meshes: int = (units if face == "shingle" else 2 * units) + 3 + 1   # base, core, cap, mount (plate is its own node)
			_check(meshes >= expect_meshes - 1 and meshes <= expect_meshes + 2, "drum %s/%s: %d MeshInstance3D children (expected about %d)" % [face, grain, meshes, expect_meshes])
			var a := _aabb(d)
			sizes.append(a.size)
			d.queue_free()
	var constant := true
	for s in sizes:
		if (s - sizes[0]).length() > 0.05:
			constant = false
	_check(constant, "drum: AABB constant across all six values (%s)" % str(sizes[0]))

	print("SUMMARY probe_chroma2: %d pass, %d fail" % [_pass, _fail])
	quit(0 if _fail == 0 else 1)


func _aabb(n: Node3D) -> AABB:
	var box := AABB()
	var first := true
	var stack: Array = [n]
	while not stack.is_empty():
		var cur: Node = stack.pop_back()
		if cur is MeshInstance3D and (cur as VisualInstance3D).layers != 0 and (cur as MeshInstance3D).mesh != null:
			var mi := cur as MeshInstance3D
			var local := mi.mesh.get_aabb()
			var xf: Transform3D = n.global_transform.affine_inverse() * mi.global_transform
			var b := xf * local
			if first:
				box = b
				first = false
			else:
				box = box.merge(b)
		for ch in cur.get_children():
			stack.append(ch)
	return box
