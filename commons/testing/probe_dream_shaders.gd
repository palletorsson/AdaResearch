extends SceneTree

## Does the gloss shader exist, and does anything actually reach it?
## (2026-09-03)
##
## A ShaderMaterial fails in two silent ways and the corpus has been bitten by
## the shape of both:
##
##   A UNIFORM NAME THAT IS NOT IN THE PROGRAM IS ACCEPTED AND DISCARDED.
##   `set_shader_parameter("filmscale", 2.2)` on a shader declaring `film_scale`
##   returns nothing, errors nothing, and reads BACK the value you stored — the
##   material keeps its own dictionary. So a read-back proves nothing here, the
##   way it does for a typed property; the only honest check is against the
##   shader's OWN declared uniform list. This is the same class as the typed
##   `set()` that is refused in silence, one layer further from the engine.
##
##   AN ENUM MAPPED BY HAND DRIFTS. `mode` is an int in the shader and a name in
##   GDScript, and the corpus's science_screen failure was exactly a hand-typed
##   value list that the code had never heard of. So the arrays are asserted to
##   be the shader's own index order, and every value is asserted to map to a
##   distinct int inside the declared range.
##
##   godot --headless --path . --xr-mode off --script res://commons/testing/probe_dream_shaders.gd

const Shaders := preload("res://commons/artifacts/dream_bodies/dream_shaders.gd")
const REPORT := "res://ada_run/dream_shaders_probe.txt"

## Every uniform dream_shaders.gd writes. If one of these is not in the program,
## that call is a no-op and the look it was buying never arrives.
const WRITES: Array[String] = ["mode", "harness", "base_color", "accent_color",
	"harness_color", "hardware_color", "seed_offset", "film_scale", "grating",
	"sheen", "glow", "harness_scale", "body_h"]

var _lines: Array[String] = []
var _fails: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var sh: Shader = Shaders.SHADER
	_check(sh != null, "the shader resource loads", "dream_gloss.gdshader did not load")
	if sh == null:
		_finish()
		return

	var declared: Array[String] = []
	for u in sh.get_shader_uniform_list():
		declared.append(String((u as Dictionary).get("name", "")))
	_check(declared.size() >= 10, "%d uniform(s) declared: %s" % [declared.size(), ", ".join(declared)],
		"the program declares almost nothing — it probably failed to compile")

	var missing: Array[String] = []
	for w in WRITES:
		if not declared.has(w):
			missing.append(w)
	_check(missing.is_empty(), "every uniform written by dream_shaders.gd is in the program",
		"written but NOT DECLARED (silently discarded): " + ", ".join(missing))

	# the name -> int mapping, asserted against the arrays that define it
	var seen_modes: Dictionary = {}
	for s in Shaders.SURFACES:
		var m: ShaderMaterial = Shaders.skin(String(s), "bare", Color(1, 0.2, 0.6), Color(0.2, 0.9, 0.9), 5)
		var v: int = int(m.get_shader_parameter("mode"))
		seen_modes[String(s)] = v
	var mode_ok: bool = seen_modes.size() == Shaders.SURFACES.size()
	for i in range(Shaders.SURFACES.size()):
		if int(seen_modes[String(Shaders.SURFACES[i])]) != i:
			mode_ok = false
	_check(mode_ok, "%d surfaces map to modes 0..%d in order" % [Shaders.SURFACES.size(), Shaders.SURFACES.size() - 1],
		"a surface name does not map to its own index: " + str(seen_modes))

	var seen_h: Dictionary = {}
	for h in Shaders.HARNESSES:
		var m2: ShaderMaterial = Shaders.skin("latex", String(h), Color(1, 0.2, 0.6), Color(0.2, 0.9, 0.9), 5)
		seen_h[String(h)] = int(m2.get_shader_parameter("harness"))
	var h_ok: bool = true
	for i2 in range(Shaders.HARNESSES.size()):
		if int(seen_h[String(Shaders.HARNESSES[i2])]) != i2:
			h_ok = false
	_check(h_ok, "%d harnesses map to 0..%d in order" % [Shaders.HARNESSES.size(), Shaders.HARNESSES.size() - 1],
		"a harness name does not map to its own index: " + str(seen_h))

	# AND AN UNKNOWN NAME MUST NOT LOOK LIKE A VALID ONE. A typo falling through
	# to index 0 is the documented fallback; a typo falling through to -1 would
	# set the uniform out of range and render whatever the last branch is.
	var junk: ShaderMaterial = Shaders.skin("chartreuse", "corset", Color.WHITE, Color.BLACK, 1)
	_check(int(junk.get_shader_parameter("mode")) == 0 and int(junk.get_shader_parameter("harness")) == 0,
		"an unknown name falls back to 0, not to -1",
		"an unknown name set the uniform out of range")

	# --- and the family that wears it ----------------------------------------
	var path := "res://commons/artifacts/dream_bodies/figures/fetish_idol.tscn"
	if ResourceLoader.exists(path):
		var n: Node = (load(path) as PackedScene).instantiate()
		n.set("surface", "oilslick")
		n.set("harness", "cage")
		n.set("seed", 4)
		root.add_child(n)
		var big: int = 0
		var box := AABB()
		var first: bool = true
		var shaded: int = 0
		for m3 in _meshes(n):
			if m3.mesh == null:
				continue
			if m3.material_override is ShaderMaterial:
				shaded += 1
			var tri: int = 0
			for s3 in range(m3.mesh.get_surface_count()):
				var a: Array = m3.mesh.surface_get_arrays(s3)
				if not a.is_empty():
					tri += (a[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() / 3
			big = maxi(big, tri)
			var wb: AABB = m3.global_transform * m3.mesh.get_aabb()
			box = wb if first else box.merge(wb)
			first = false
		_check(big > 4000, "the idol marches one body of %d triangles" % big,
			"the idol has no marched body (biggest mesh %d tri)" % big)
		_check(shaded >= 1, "%d mesh(es) carry a ShaderMaterial" % shaded,
			"nothing on the idol is wearing the shader")
		# the contract every dream body is held to
		_check(box.size.x <= 1.22 and box.size.z <= 1.22 and box.size.y <= 1.70,
			"it settles to %.2f x %.2f x %.2f m" % [box.size.x, box.size.y, box.size.z],
			"it does not fit the plinth: %.2f x %.2f x %.2f m" % [box.size.x, box.size.y, box.size.z])
		_check(absf(box.position.y) < 0.02, "it stands ON the floor (lowest y %.3f)" % box.position.y,
			"it floats or sinks: lowest y %.3f" % box.position.y)
		n.queue_free()
	else:
		_lines.append("[probe] fetish_idol.tscn not generated yet — run tools/dream_bodies_promote.py")
	_finish()


func _meshes(n: Node) -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	if n is MeshInstance3D:
		out.append(n)
	for c in n.get_children():
		out.append_array(_meshes(c))
	return out


func _finish() -> void:
	var ok: bool = _fails.is_empty()
	_lines.append("[probe] %s%s" % ["PASS" if ok else "FAIL", "" if ok else " — " + String(";  ").join(PackedStringArray(_fails))])
	var f := FileAccess.open(REPORT, FileAccess.WRITE)
	if f != null:
		f.store_string(String.chr(10).join(PackedStringArray(_lines)) + String.chr(10))
		f.close()
	for l in _lines:
		print(l)
	quit(0 if ok else 1)


func _check(ok: bool, line: String, why: String) -> void:
	_lines.append("[probe] %s  %s" % [line, "OK" if ok else "*** %s ***" % why])
	if not ok:
		_fails.append(why)
