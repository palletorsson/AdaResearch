extends SceneTree

## Do the dream bodies build, stand on the floor, keep to their size, and differ
## by seed? (2026-08-29) Builders written by many hands against one contract;
## this is the contract's gate. For every family on disk, two seeds:
##   it builds without a script error, within the draw-call budget, and carries
##     enough geometry to be a body rather than a bare plinth
##   every mesh has a material
##   the merged AABB stands on y ~ 0 and is within the size the contract set
##   seed 1 and seed 2 differ (triangles, extent or layout) — a seed IS a statue
## then, once more, at every family's MARCHED value, where the mesh count
## collapses and the old floor used to fire on a correct body.
##
##   godot --headless --path . --xr-mode off --script res://commons/testing/probe_dream_bodies.gd

const BODIES := "res://commons/artifacts/dream_bodies/dream_bodies.tscn"
const BODY_DIR := "res://commons/artifacts/dream_bodies/bodies/"
const REPORT := "res://ada_run/dream_bodies_probe.txt"

## THE FAMILY LIST IS READ OFF DISK, NOT WRITTEN DOWN HERE (2026-09-03).
## This probe used to carry its own copy of the names — 37 of them — and so did
## dream_bodies.gd and probe_museum_sculptures.gd. Three transcriptions of one
## fact drift the moment a family is added, and they drift SILENTLY: a probe
## whose list is short does not fail, it just never looks at the new family, and
## reports PASS for the 37 it still knows. bodies/ is the truth. Adding a file
## there is adding a family, so the gate finds it on the next run with no edit
## here at all.
const MIN_FAMILIES := 40   # bodies/ held 42 on 2026-09-03; see _families()

## THE OLD BOUND WAS `n >= 40 and n <= 260` AND ITS FLOOR DIED ON 2026-09-03.
## It was right for what it was built on. Every dream body was a stack of
## primitives, so "fewer than 40 MeshInstance3D" could only mean the builder had
## thrown early and left the plinth bare — the exact failure this probe exists to
## catch, and it caught it.
##
## It stopped being right the day a body could be MARCHED. fetish_idol is ONE
## isosurface out of dream_iso.gd plus its own plinth slab: TWO meshes, 15,297
## triangles, 15,285 of them in the big one. The old floor failed it by 20x, and
## failed it for entirely the wrong reason — the body is correct.
##
## SO THE FLOOR SPLIT IN TWO. A body is MANY PARTS or ONE BIG SURFACE:
##   n <= MAX_MESHES                     unchanged — a real draw-call budget
##   tris >= MIN_TRIS                    no body in the corpus is thinner
##   n >= MIN_MESHES  OR  big >= MIN_BIG_MESH_TRIS
##   box.size.y >= min_h                 the merged AABB, unchanged, just below
##
## EVERY CONSTANT BELOW IS A MEASUREMENT, taken from the run of 2026-09-03 over
## all 42 families at two seeds plus 13 marched variants, and the run prints the
## two extremes on its last line so the next person can re-derive them rather
## than trust this comment.
##
## AN EMPTY PLINTH STILL FAILS, WHICH IS THE WHOLE POINT — widening the count to
## admit zero would have been one character and would have made this line unable
## to fail. fetish_idol's own slab is a 0.72 x 0.055 x 0.72 box: 1 mesh, 12
## triangles, 5.5 cm tall. It is 33x under MIN_TRIS, 30x under MIN_MESHES, 1274x
## under MIN_BIG_MESH_TRIS and 16x under min_h. All four fire.
##
## WHAT THE NEW BOUND CAN NO LONGER TELL APART, said plainly: a primitive family
## that built a handful of dense parts instead of ninety now clears the second
## arm if any ONE of them is big enough. MIN_BIG_MESH_TRIS is pinned between two
## measured numbers so that cannot happen with stock geometry — above the densest
## off-the-shelf primitive (a default SphereMesh is 4,224 triangles in Godot 4.6,
## measured by the negative test below) and below the thinnest marched body the
## museum is allowed to stand (fetish_idol at its clamp ceiling of cell 0.052 is
## 6,532, measured by the sweep below). A stub would still have to clear the
## height, width and seed checks too.
const MAX_MESHES := 260          # measured max: brass_stamen at 221
const MIN_MESHES := 30           # measured min for a primitive body: 42, vasarely_beast tube=fused
const MIN_TRIS := 400            # measured min for any body: 1,200, dubuffet — 94 boxes at 12 each
const MIN_BIG_MESH_TRIS := 5000  # between 4,224 (stock sphere) and 6,532 (coarsest marched body)

## The values at which a family stops stacking primitives and marches a field.
## Named here rather than a family list, because WHICH families march is read off
## disk below — a name is a fact about the vocabulary, a list is a fact that goes
## stale. "poured" also names three non-marching variants (botanic_mannequin,
## hadid_shell, panel_robot); building those costs one extra body each and checks
## something true anyway.
const ISO_VALUES := ["fused", "cast", "poured"]
const ISO_MARCHER := "dream_iso.gd"
## fetish_idol marches at EVERY value of both its axes, so it has no single value
## to name here and needs no entry in the sweep below — the default pass already
## walks it through the marcher.
const ALWAYS_MARCHED := ["fetish_idol"]

var _lines: Array[String] = []
var _fails: Array[String] = []
var _tightest: Dictionary = {"fig": "", "tris": 1 << 30}
var _fewest: Dictionary = {"fig": "", "n": 1 << 30, "big": 0}


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var ps: PackedScene = load(BODIES) as PackedScene
	var figures: Array[String] = _families()
	# A DIRECTORY READ HAS A FAILURE MODE A CONST DOES NOT: it can come back
	# EMPTY. A stale const under-reports; an unreadable res:// path reports
	# nothing at all, and a probe with nothing to check runs every assertion zero
	# times and prints PASS. So the list itself is the first assertion.
	_check(figures.size() >= MIN_FAMILIES,
		"%d families read from %s" % [figures.size(), BODY_DIR],
		"bodies/ yielded %d families, expected at least %d — DirAccess.get_files_at read nothing or the family files moved" % [figures.size(), MIN_FAMILIES])
	if figures.size() < MIN_FAMILIES:
		_finish()
		return

	for fig in figures:
		var stats: Array = []
		for sd in [1, 2]:
			var b: Node3D = ps.instantiate() as Node3D
			b.set("figure", fig)
			b.set("seed", sd)
			# READ THE ASSIGNMENT BACK. `figure` is an @export_enum String, and a
			# set() onto a typed property of the wrong type is refused in SILENCE
			# — the corpus has lost a whole measurement pass to exactly that. If
			# this ever slips, every family below would be photographing the
			# DEFAULT body while reporting the requested name.
			if String(b.get("figure")) != fig:
				_check(false, "%s: figure set" % fig,
					"%s: dream_bodies.figure refused the assignment (reads back %s) — the probe would test the default body under this family's name" % [fig, String(b.get("figure"))])
				b.queue_free()
				await process_frame
				continue
			get_root().add_child(b)
			await process_frame
			await process_frame
			stats.append(_measure(b))
			b.queue_free()
			await process_frame
		if stats.size() < 2:
			continue
		var s1: Dictionary = stats[0]
		var s2: Dictionary = stats[1]
		var n: int = int(s1["n"])
		var tris: int = int(s1["tris"])
		var box: AABB = s1["box"]
		var relief: bool = fig == "stella_wall"
		var max_w: float = 2.6 if relief else 1.3
		var max_h: float = 1.75
		var min_h: float = 0.9
		_note_extremes(fig, s1)
		_body_check(fig, s1)
		_check(int(s1["no_mat"]) == 0, "%s: %d without material" % [fig, int(s1["no_mat"])], "%s: bare mesh" % fig)
		var base_ok: bool = box.position.y > -0.03 and box.position.y < 0.25
		var h: float = box.size.y
		var w: float = maxf(box.size.x, box.size.z)
		_check(base_ok and h >= min_h and h <= max_h and w <= max_w,
			"%s: base y %.2f, %.2f m tall, %.2f m across (limits %.1f..%.2f tall, %.1f across)" % [fig, box.position.y, h, w, min_h, max_h, max_w],
			"%s: off the floor or out of size" % fig)
		var b2: AABB = s2["box"]
		# TRIANGLE COUNT JOINED THE FINGERPRINT because a marched family has only
		# two meshes to move: the mesh-origin sum below is a strong signal across
		# 40 stacked primitives and a weak one across two, while a field re-dealt
		# from a new seed almost never marches to the same triangle count.
		var differs: bool = int(s2["n"]) != n or int(s2["tris"]) != tris \
			or absf(float(s2["fp"]) - float(s1["fp"])) > 0.001 \
			or (b2.size - box.size).length() > 0.002 or (b2.position - box.position).length() > 0.002
		_check(differs, "%s: seed 2 differs from seed 1: %s" % [fig, str(differs)], "%s: seed ignored" % fig)

	await _sweep_marched(ps, figures)
	await _negative_test()
	# THE CONSTANTS ARE ONLY AS GOOD AS THEIR HEADROOM, so the run prints the two
	# bodies that come closest to each arm of the floor. If a family ever lands
	# within a whisker of a constant, this line says so before the constant fires
	# on a correct body — which is exactly how the old `n >= 40` died.
	_lines.append("[probe] tightest on triangles: %s at %d (floor %d, %.1fx). Fewest parts: %s at %d mesh(es), biggest %d (arms: %d meshes / %d triangles)"
		% [String(_tightest["fig"]), int(_tightest["tris"]), MIN_TRIS,
			float(int(_tightest["tris"])) / float(MIN_TRIS),
			String(_fewest["fig"]), int(_fewest["n"]), int(_fewest["big"]), MIN_MESHES, MIN_BIG_MESH_TRIS])
	_finish()


func _note_extremes(tag: String, st: Dictionary) -> void:
	if int(st["tris"]) < int(_tightest["tris"]):
		_tightest = {"fig": tag, "tris": int(st["tris"])}
	if int(st["n"]) < int(_fewest["n"]):
		_fewest = {"fig": tag, "n": int(st["n"]), "big": int(st["big"])}


## THE LOW-MESH CASE HAS TO BE TESTED WHERE IT ACTUALLY LIVES (2026-09-03).
## Eleven families preload dream_iso.gd and march at exactly ONE value of one of
## their axes; at their DEFAULT value they are primitives. So the pass above
## never reaches the marched branch for any of them — the same blind spot that
## let the old mesh-count floor look healthy while the museum, which deals axis
## values per hall since 2026-09-03, was already standing marched bodies in real
## halls. This sweep is deliberately narrower than the pass above: budget, floor
## and materials only. Size and seed-response are invariants of the FAMILY and
## are proved at its default; what is new at a marched value is the geometry.
func _sweep_marched(ps: PackedScene, figures: Array[String]) -> void:
	var found: int = 0
	for fig in figures:
		var src: String = FileAccess.get_file_as_string(BODY_DIR + fig + ".gd")
		var marches: bool = src.contains(ISO_MARCHER)
		var pair: Array = _iso_value(fig)
		# A FAMILY THAT MARCHES BUT NAMES ITS VALUE SOMETHING ELSE IS A HOLE THE
		# PROBE CANNOT SEE. It would march in the museum at a value this sweep
		# never builds, so the floor would go untested on the one path it was
		# rewritten for. Fail here rather than quietly skipping it.
		if marches and pair.is_empty() and not ALWAYS_MARCHED.has(fig):
			_check(false, "%s: marches a field" % fig,
				"%s preloads %s but offers no value in %s — the marched branch is unreachable from this probe; add its value to ISO_VALUES" % [fig, ISO_MARCHER, str(ISO_VALUES)])
			continue
		if pair.is_empty():
			continue
		found += 1
		var axis: String = String(pair[0])
		var value: String = String(pair[1])
		var b: Node3D = ps.instantiate() as Node3D
		b.set("figure", fig)
		b.set("seed", 1)
		# Set the opts bag DIRECTLY rather than through apply_grid_config: that
		# entry point filters `figure` against dream_bodies.FIGURES, a const this
		# probe deliberately no longer trusts (see _families). Going straight to
		# the property means this sweep measures the BUILDER, not the filter.
		b.set("_opts", {axis: value})
		get_root().add_child(b)
		await process_frame
		await process_frame
		var st: Dictionary = _measure(b)
		var tag: String = "%s %s=%s" % [fig, axis, value]
		_note_extremes(tag, st)
		_body_check(tag, st)
		_check(int(st["no_mat"]) == 0, "%s: %d without material" % [tag, int(st["no_mat"])], "%s: bare mesh" % tag)
		b.queue_free()
		await process_frame
	# Same reason as the family count: a vocabulary change that empties this
	# sweep must say so, not pass silently having built nothing.
	_check(found >= 12, "%d families swept at a marched value" % found,
		"only %d families offered a value in %s — the marched sweep tested almost nothing" % [found, str(ISO_VALUES)])

	# THE COARSEST BODY THE MUSEUM CAN STAND, measured rather than predicted.
	# fetish_idol clamps its cell to [CELL, 0.052] and the museum hands it one out
	# of em_layout (sculptures.cell), so the thinnest marched body that can ever
	# reach a hall is the one at the clamp ceiling. MIN_BIG_MESH_TRIS has to sit
	# under THAT, not under the bench body — and probe_museum_sculptures.gd shares
	# the constant, so this is where the number it depends on gets taken.
	for fig in ALWAYS_MARCHED:
		if not figures.has(fig):
			continue
		var b2: Node3D = ps.instantiate() as Node3D
		b2.set("figure", fig)
		b2.set("seed", 1)
		b2.set("_opts", {"cell": 1.0})   # above the clamp: lands on the ceiling
		get_root().add_child(b2)
		await process_frame
		await process_frame
		var st2: Dictionary = _measure(b2)
		_body_check("%s at its coarsest cell" % fig, st2)
		_check(int(st2["big"]) >= MIN_BIG_MESH_TRIS,
			"%s at its coarsest cell: biggest mesh %d, %.1fx the marched arm (%d)"
				% [fig, int(st2["big"]), float(int(st2["big"])) / float(MIN_BIG_MESH_TRIS), MIN_BIG_MESH_TRIS],
			"%s at its coarsest cell marches only %d triangles into one mesh, under the %d-triangle marched arm — a correct body in a hall would read as an empty plinth" % [fig, int(st2["big"]), MIN_BIG_MESH_TRIS])
		b2.queue_free()
		await process_frame


## The one bound, in one place, so the family pass, the marched sweep and the
## negative test below cannot drift apart. See the constants block at the top.
func _is_body(st: Dictionary) -> bool:
	return int(st["n"]) <= MAX_MESHES and int(st["tris"]) >= MIN_TRIS \
		and (int(st["n"]) >= MIN_MESHES or int(st["big"]) >= MIN_BIG_MESH_TRIS)


## THE FLOOR HAS TO BE ABLE TO FAIL (2026-09-03). The old `n >= 40` carried this
## proof implicitly — anything that threw early landed at nought — and the wider
## bound that replaced it must not lose it. So it is fired at five things that
## are not bodies, and has to reject all five.
##
## These are assembled here rather than by wrecking a real builder because
## fetish_idol now clamps its own cell to a measured range (bodies/fetish_idol.gd
## — "a coarser cell is an amputation and it is silent"), so the family cannot be
## degraded from outside any more. That is right for the family and useless for a
## gate, hence a synthetic ladder. Only the COUNTS matter to the predicate; the
## slab is sized like fetish_idol's own plinth so the numbers read as themselves.
func _negative_test() -> void:
	var cases: Array = [
		[0, "empty", "nothing at all — the builder threw before its first mesh"],
		[1, "box", "one bare plinth slab, which is what an empty plinth IS"],
		[29, "box", "a builder that threw a third of the way through its parts"],
		[40, "empty", "40 MeshInstance3D with no mesh assigned — clears the parts arm, carries no geometry"],
		[4, "sphere", "four stock spheres — dense, but no single one is a marched surface"],
	]
	for c_v in cases:
		var c: Array = c_v
		var host := Node3D.new()
		for i in range(int(c[0])):
			var mi := MeshInstance3D.new()
			if String(c[1]) == "box":
				var bm := BoxMesh.new()
				bm.size = Vector3(0.72, 0.055, 0.72)
				mi.mesh = bm
			elif String(c[1]) == "sphere":
				mi.mesh = SphereMesh.new()      # stock defaults, on purpose
			host.add_child(mi)
		get_root().add_child(host)
		await process_frame
		var st: Dictionary = _measure(host)
		# The fifth case is also the assertion behind MIN_BIG_MESH_TRIS: it is set
		# above the densest stock primitive so that no off-the-shelf mesh can pass
		# for a marched surface. If Godot ever ships a denser default SphereMesh,
		# this is where that lands, loudly, instead of in a false PASS a year on.
		_check(not _is_body(st),
			"rejected: %s (%d mesh(es), %d triangles, biggest %d)" % [String(c[2]), int(st["n"]), int(st["tris"]), int(st["big"])],
			"THE FLOOR NO LONGER BITES — it accepted %s (%d mesh(es), %d triangles, biggest %d). The bound was widened until it could not fail." % [String(c[2]), int(st["n"]), int(st["tris"]), int(st["big"])])
		host.queue_free()
		await process_frame


func _body_check(tag: String, st: Dictionary) -> void:
	var n: int = int(st["n"])
	var tris: int = int(st["tris"])
	var big: int = int(st["big"])
	# which arm carried it — printed because a family that silently swaps arms
	# between seeds is a family whose builder changed shape under everyone
	var arm: String = "many parts" if n >= MIN_MESHES else (
		"one marched surface" if big >= MIN_BIG_MESH_TRIS else "NEITHER ARM")
	_check(_is_body(st),
		"%s: %d mesh(es), %d triangles, biggest %d — %s" % [tag, n, tris, big, arm],
		("%s: %d mesh(es), %d triangles, biggest mesh %d — this is not a body. "
			+ "Budget %d meshes; floor %d triangles; and either %d+ meshes or a single "
			+ "mesh of %d+ triangles. A bare plinth slab is 1 mesh and 12 triangles.")
			% [tag, n, tris, big, MAX_MESHES, MIN_TRIS, MIN_MESHES, MIN_BIG_MESH_TRIS])


## bodies/ is the family list. Reads .gd and, so an exported build measures the
## same corpus as a run from source, .gd.remap — in a .pck the script itself is
## packed and only the remap stub is visible to DirAccess.
func _families() -> Array[String]:
	var out: Array[String] = []
	for f in DirAccess.get_files_at(BODY_DIR):
		var n: String = String(f)
		if n.ends_with(".gd.remap"):
			n = n.substr(0, n.length() - 6)
		if not n.ends_with(".gd"):
			continue      # skips the .gd.uid siblings, which do not end in .gd
		out.append(n.substr(0, n.length() - 3))
	out.sort()
	return out


## The family's own axes(), read off its script — [axis, value] for the first
## value it declares that is in ISO_VALUES, or [] if it declares none.
func _iso_value(fig: String) -> Array:
	var s: Script = load(BODY_DIR + fig + ".gd") as Script
	if s == null or not s.has_method("axes"):
		return []
	var ax: Variant = s.call("axes")
	if not (ax is Dictionary):
		return []
	for k in (ax as Dictionary):
		var vals: Variant = (ax as Dictionary)[k]
		if not (vals is Array):
			continue
		for v in (vals as Array):
			if ISO_VALUES.has(String(v)):
				return [String(k), String(v)]
	return []


func _measure(b: Node3D) -> Dictionary:
	var meshes: Array = []
	_collect(b, meshes)
	var no_mat: int = 0
	var tris: int = 0
	var big: int = 0
	var box := AABB()
	var first: bool = true
	for mi_v in meshes:
		var mi: MeshInstance3D = mi_v
		if mi.material_override == null and (mi.mesh == null or mi.mesh.surface_get_material(0) == null):
			no_mat += 1
		if mi.mesh == null:
			continue
		# get_faces() triangulates every surface and hands back its corners, so
		# it counts the same whether the family used SurfaceTool, a PrimitiveMesh
		# or the marcher — and a surface that is NOT triangles counts zero, which
		# is the right answer: a body that came back as loose lines is not a body.
		var t: int = mi.mesh.get_faces().size() / 3
		tris += t
		big = maxi(big, t)   # the marched arm of the floor asks for ONE big mesh
		var a: AABB = mi.global_transform * mi.get_aabb()
		if first:
			box = a
			first = false
		else:
			box = box.merge(a)
	# A FINGERPRINT, not a bounding box. batik_beast draws its whole pose from the
	# seed and still measured "identical" to a 2 cm box test: a body whose
	# silhouette is nearly normalised moves its parts without moving its extents.
	# So: the sum of every mesh origin, weighted by its index, which a millimetre
	# anywhere changes.
	var fp: float = 0.0
	for mi_i in range(meshes.size()):
		var mo: Vector3 = (meshes[mi_i] as MeshInstance3D).global_transform.origin
		fp += (mo.x * 1.7 + mo.y * 2.3 + mo.z * 3.1) * float(mi_i + 1)
	return {"n": meshes.size(), "no_mat": no_mat, "tris": tris, "big": big, "box": box, "fp": fp}


func _finish() -> void:
	var ok: bool = _fails.is_empty()
	_lines.append("[probe] %s%s" % ["PASS" if ok else "FAIL", "" if ok else " — " + ", ".join(_fails)])
	var f := FileAccess.open(REPORT, FileAccess.WRITE)
	if f != null:
		f.store_string(String.chr(10).join(PackedStringArray(_lines)) + String.chr(10))
		f.close()
	for l in _lines:
		print(l)
	quit(0 if ok else 1)


func _collect(n: Node, out: Array) -> void:
	if n is MeshInstance3D:
		out.append(n)
	for c in n.get_children():
		_collect(c, out)


func _check(ok: bool, line: String, why: String) -> void:
	_lines.append("[probe] %s  %s" % [line, "OK" if ok else "*** %s ***" % why])
	if not ok:
		_fails.append(why)
