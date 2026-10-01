extends SceneTree
## probe_mesh_grammar_presets.gd — does a placed mesh_grammar_<name> build its name?
##
## THE FAULT THIS GATES. commons/artifacts/registry/mesh_grammar.json carries 21
## names. Until 2026-10-01 every one of them had the same `scene` line — the bare
## MeshGrammarNode — and that node had no recipe table, so `mesh_grammar_lsystem_tree`
## in a map built the seed icosahedron, and so did the other eighteen. The recipes
## existed only inside mesh_grammar_demo.gd. Nothing failed: the scene loaded, the
## map validated, the capture photographed a tidy icosahedron.
##
## WHAT IT CHECKS, for every name in the registry file:
##   1. instantiates the registry's `scene`, lets it build, reads vertices, faces,
##      the rendered array length and the AABB;
##   2. builds the same recipe THE WAY THE DEMO DOES — by calling the demo's own
##      _build_specimen() — and compares. Settings, rule list and seed mesh must be
##      EQUAL for every recipe. Counts and AABB must be EQUAL for every recipe whose
##      rules are deterministic; for the unseeded ones (random selectors, scatter,
##      tube curves seed themselves from the clock) the counts differ run to run on
##      BOTH sides, so they are sampled and printed, not asserted;
##   3. NEGATIVE TEST — every name that is not the seed must differ from the bare
##      seed. Before the registry was repointed this failed for all nineteen;
##   4. a node with preset = "" is UNCHANGED: same counts and settings as measured
##      before the repair (BARE_BEFORE below).
## And beside those:
##   5. the demo gallery still holds twenty specimens, in order, by name, on the
##      shipped lattice;
##   6. the `preset` config key works through both handoffs — before the node is in
##      the tree (the museum lane) and after _ready (the grid lane, deferred) — is
##      not applied twice, and an unknown name leaves the bare seed;
##   7. RULE LIVENESS — each rule of each recipe is run alone and must change the
##      mesh. A rule that changes nothing is a recipe that does not build its
##      description. Three recipes carry such rules TODAY, in the demo as much as
##      in a map (KNOWN_DEAD); a NEW dead rule fails the gate.
##   8. OUTWARD — a recipe whose rules are meant to add something ON the seed
##      (extrude, bulge, branch, petal, scale, scatter, bead) must end up with a
##      body that reaches outside its seed's own box. Six do not, today
##      (KNOWN_INWARD); a NEW one fails the gate.
##
## Run (headless is enough — this reads meshes, it draws nothing):
##   godot --headless --path . --xr-mode off --log-file <log> \
##       --script res://commons/testing/probe_mesh_grammar_presets.gd -- --out=<file>
## --registry=<path> reads another copy of the registry file instead (the negative
## test: point it at `git show <commit-before-the-repair>:<registry>` and all
## nineteen names fail).
## Exit code = number of failed assertions.

const Presets = preload("res://commons/mesh_grammar/mesh_grammar_presets.gd")
const NodeScript = preload("res://commons/mesh_grammar/mesh_grammar_node.gd")

const REGISTRY: String = "res://commons/artifacts/registry/mesh_grammar.json"
const BARE_SCENE: String = "res://commons/mesh_grammar/mesh_grammar_node.tscn"
const DEMO_SCENE: String = "res://commons/mesh_grammar/mesh_grammar_demo.tscn"
const NODE_SCRIPT: String = "res://commons/mesh_grammar/mesh_grammar_node.gd"
const PREFIX: String = "mesh_grammar_"

## The global RNG is pinned before every build so NoiseDisplaceOp's `randi()` seed
## is the same on both sides. It does NOT reach the ops that own a
## RandomNumberGenerator and call randomize() on it.
const RNG_SEED: int = 12345
const SAMPLES: int = 5
const LIVENESS_TRIES: int = 8

## Names whose registry description IS the bare seed. They keep the bare scene.
const SEED_NAMES: PackedStringArray = ["mesh_grammar", "mesh_grammar_seed"]

## The bare node, measured twice at HEAD 9eebe2e14 before `preset` existed.
const BARE_BEFORE: Dictionary = {
	"verts": 12, "faces": 20, "arr": 120, "aabb": Vector3(0.8507, 0.8507, 0.8507),
	"seed_type": "icosahedron", "seed_scale": 0.5, "generations": 2,
	"color": Color(0.6, 0.75, 0.85), "rules": 0,
}

## Rules that change NOTHING, by recipe id -> rule indices. EMPTY since the repair of
## 2026-10-01; a rule that goes dead now fails the gate. Until then three sphere
## recipes were listed here (budding, riveted, ca_growth): ExtrudeFaceOp skips any
## face under min_area = 0.01 m2 and the largest triangle of the 0.35 m sphere seed
## is 0.0062 m2, so every extrude on a sphere selected faces and skipped them all.
## The three rules now name MeshGrammarPresets.SPHERE_MIN_AREA; the op's default is
## unchanged.
const KNOWN_DEAD: Dictionary = {}

## Recipes whose additions never leave the seed's own bounding box. EMPTY since the
## same repair. Six were listed (nodule_sphere, coral_fingers, budding, scale_armor,
## ca_growth, blooming_bulge) for one cause: MeshData.create_sphere() wound every
## face so that get_face_normal() pointed at the CENTRE (0 of 352 away), so every
## op along the normal worked inward and "up" picked the underside. create_sphere
## is wound outward now and is a closed surface (one vertex per pole, no seam).
const KNOWN_INWARD: PackedStringArray = []
## Ops that are supposed to put something ON the seed.
const PROTRUDING_OPS: PackedStringArray = [
	"extrude", "bulge", "tube_branch", "petal_splay", "scale_tile", "edge_decorate",
	"scatter", "lsystem_branch",
]

var _fails: int = 0
var _lines: PackedStringArray = []


func _initialize() -> void:
	_run.call_deferred()


func _say(s: String) -> void:
	_lines.append(s)
	print(s)


func _fail(s: String) -> void:
	_fails += 1
	_say("  FAIL  " + s)


# ---------------------------------------------------------------------------
# Reading a built node
# ---------------------------------------------------------------------------

func _rule_sig(g: Variant) -> Array:
	var out: Array = []
	if g == null:
		return out
	for r in g.rules:
		out.append("%s%s" % [String(r.get_script().resource_path.get_file().get_basename()), var_to_str(r.params)])
	return out


func _facts(n: Node, ms: float) -> Dictionary:
	var d: Dictionary = {
		"ok": false, "ms": ms, "verts": -1, "faces": -1, "arr": -1, "aabb": Vector3.ZERO,
		"seed_type": "", "seed_scale": 0.0, "generations": -1, "color": Color.BLACK,
		"rules": [], "seed_verts": -1, "seed_faces": -1, "is_seed_body": false,
		"seed_aabb": Vector3.ZERO,
		"preset": "", "script": "",
	}
	if n == null:
		return d
	var sc: Variant = n.get_script()
	d["script"] = String(sc.resource_path) if sc != null else ""
	var g: Variant = n.get("grammar")
	if g == null or g.current_mesh == null:
		return d
	d["ok"] = true
	d["preset"] = str(n.get("preset")) if n.get("preset") != null else ""
	d["seed_type"] = str(n.get("seed_type"))
	d["seed_scale"] = float(n.get("seed_scale"))
	d["generations"] = int(n.get("generations"))
	d["color"] = n.get("base_color")
	d["rules"] = _rule_sig(g)
	d["verts"] = g.current_mesh.vertex_count()
	d["faces"] = g.current_mesh.face_count()
	d["seed_verts"] = g.seed_mesh.vertex_count()
	d["seed_faces"] = g.seed_mesh.face_count()
	d["seed_aabb"] = g.seed_mesh.get_bounding_box().size
	d["is_seed_body"] = (g.current_mesh.vertices == g.seed_mesh.vertices
		and hash(g.current_mesh.faces) == hash(g.seed_mesh.faces))
	var mi: MeshInstance3D = n.get_node_or_null("GrammarMesh") as MeshInstance3D
	if mi != null and mi.mesh != null and mi.mesh.get_surface_count() > 0:
		d["arr"] = mi.mesh.surface_get_array_len(0)
		d["aabb"] = mi.get_aabb().size
	return d


## Add a node, let it build, read it, drop it.
func _measure(n: Node, t0_usec: int) -> Dictionary:
	root.add_child(n)
	var ms: float = float(Time.get_ticks_usec() - t0_usec) / 1000.0
	await process_frame
	await process_frame
	var d: Dictionary = _facts(n, ms)
	n.queue_free()
	await process_frame
	return d


func _build_scene(scene_path: String) -> Dictionary:
	if scene_path == "" or not ResourceLoader.exists(scene_path):
		return _facts(null, 0.0)
	var ps: PackedScene = load(scene_path) as PackedScene
	if ps == null:
		return _facts(null, 0.0)
	seed(RNG_SEED)
	var t0: int = Time.get_ticks_usec()
	var n: Node = ps.instantiate()
	return await _measure(n, t0)


## THE WAY THE DEMO DOES: its own _build_specimen, called on a live demo instance.
func _build_demo(demo: Node, spec: Dictionary) -> Dictionary:
	seed(RNG_SEED)
	var t0: int = Time.get_ticks_usec()
	var n: Node = demo.call("_build_specimen", spec)
	return await _measure(n, t0)


func _near(a: Vector3, b: Vector3, eps: float = 0.0005) -> bool:
	return absf(a.x - b.x) <= eps and absf(a.y - b.y) <= eps and absf(a.z - b.z) <= eps


func _same_body(a: Dictionary, b: Dictionary) -> bool:
	return a["verts"] == b["verts"] and a["faces"] == b["faces"] and a["arr"] == b["arr"] \
		and _near(a["aabb"], b["aabb"])


func _v(v: Vector3) -> String:
	return "%.3f x %.3f x %.3f" % [v.x, v.y, v.z]


## True when a recipe's COUNTS are not reproducible: some rule seeds itself from the
## clock. Derived from the recipe, so a new recipe is classed without a second list.
func _unseeded(spec: Dictionary) -> bool:
	for rdef in spec.get("rules", []):
		var sel: String = String(rdef.get("selector", "all"))
		var op: String = String(rdef.get("op", ""))
		var params: Dictionary = rdef.get("params", {})
		if sel.begins_with("random:") or sel == "up_random":
			return true
		if op == "tube_branch":
			return true
		if (op == "scatter" or op == "cellular") and int(params.get("seed_value", -1)) < 0:
			return true
	return false


func _protrudes(spec: Dictionary) -> bool:
	for rdef in spec.get("rules", []):
		if PROTRUDING_OPS.has(String(rdef.get("op", ""))):
			return true
	return false


## True when a body reaches outside its seed's box on some axis by more than
## OUTSIDE_MARGIN. The margin is not arbitrary: over repeated builds the inward
## recipes never exceeded +0.012 m (a petal tip of blooming_bulge poking through a
## pole), and the smallest honest protrusion is riveted's seam beads at +0.040 m.
const OUTSIDE_MARGIN: float = 0.03

func _outside_seed(aabb: Vector3, seed_aabb: Vector3) -> bool:
	return aabb.x > seed_aabb.x + OUTSIDE_MARGIN or aabb.y > seed_aabb.y + OUTSIDE_MARGIN \
		or aabb.z > seed_aabb.z + OUTSIDE_MARGIN


# ---------------------------------------------------------------------------
# Rule liveness
# ---------------------------------------------------------------------------

func _mesh_hash(m: Variant) -> Array:
	return [m.vertices.size(), m.faces.size(), hash(m.vertices), hash(m.faces), hash(m.face_tags)]


## Indices of rules that changed nothing in EVERY try. A rule behind a random
## selector can pick no face by chance, so those are retried.
func _dead_rules(spec: Dictionary) -> Array:
	var rule_count: int = (spec.get("rules", []) as Array).size()
	var alive: Array = []
	alive.resize(rule_count)
	alive.fill(false)
	var tries: int = LIVENESS_TRIES if _unseeded(spec) else 1
	for _t in range(tries):
		var n: Variant = NodeScript.new()
		n.apply_spec(spec)
		n._ensure_grammar()
		n._create_seed()
		var g: Variant = n.grammar
		for _gen in range(maxi(int(n.generations), 0)):
			for i in range(g.rules.size()):
				var before: Array = _mesh_hash(g.current_mesh)
				g.rules[i].apply(g.current_mesh)
				if _mesh_hash(g.current_mesh) != before:
					alive[i] = true
		n.free()
		if not alive.has(false):
			break
	var dead: Array = []
	for i in range(rule_count):
		if not alive[i]:
			dead.append(i)
	return dead


# ---------------------------------------------------------------------------
# The run
# ---------------------------------------------------------------------------

func _run() -> void:
	var out_path: String = ""
	var registry_path: String = REGISTRY
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out_path = a.substr(6)
		elif a.begins_with("--registry="):
			registry_path = a.substr(11)   # another copy of the file, e.g. `git show HEAD:...`

	_say("probe_mesh_grammar_presets — %s" % Time.get_datetime_string_from_system())
	_say("registry: %s" % registry_path)

	# --- 4. the bare node is unchanged -------------------------------------
	var bare: Dictionary = await _build_scene(BARE_SCENE)
	_say("")
	_say("[4] bare node, preset = \"\": verts=%d faces=%d arr=%d aabb=%s seed=%s scale=%.2f gens=%d rules=%d" % [
		bare["verts"], bare["faces"], bare["arr"], _v(bare["aabb"]), bare["seed_type"],
		bare["seed_scale"], bare["generations"], (bare["rules"] as Array).size()])
	if not bare["ok"]:
		_fail("the bare node built nothing")
	else:
		if bare["verts"] != BARE_BEFORE["verts"] or bare["faces"] != BARE_BEFORE["faces"] \
				or bare["arr"] != BARE_BEFORE["arr"] or not _near(bare["aabb"], BARE_BEFORE["aabb"]):
			_fail("bare node body changed: was %d/%d/%d %s" % [BARE_BEFORE["verts"], BARE_BEFORE["faces"],
				BARE_BEFORE["arr"], _v(BARE_BEFORE["aabb"])])
		if bare["seed_type"] != BARE_BEFORE["seed_type"] or not is_equal_approx(bare["seed_scale"], BARE_BEFORE["seed_scale"]) \
				or bare["generations"] != BARE_BEFORE["generations"] or (bare["rules"] as Array).size() != BARE_BEFORE["rules"] \
				or not (bare["color"] as Color).is_equal_approx(BARE_BEFORE["color"]) or bare["preset"] != "":
			_fail("bare node settings changed")

	# --- 5. the demo gallery ------------------------------------------------
	var demo_ps: PackedScene = load(DEMO_SCENE) as PackedScene
	seed(RNG_SEED)
	var demo_t0: int = Time.get_ticks_usec()
	var demo: Node = demo_ps.instantiate()
	root.add_child(demo)
	var demo_ms: float = float(Time.get_ticks_usec() - demo_t0) / 1000.0
	for _i in range(3):
		await process_frame
	var all_specs: Array[Dictionary] = Presets.specs()
	var gallery: Node = demo.get_node_or_null("Gallery")
	_say("")
	_say("[5] demo gallery: built in %.0f ms" % demo_ms)
	if gallery == null:
		_fail("the demo built no Gallery")
	else:
		var bodies: Array = []
		var labels: Array = []
		for c in gallery.get_children():
			if c is Label3D:
				labels.append(c)
			elif c.get_script() == NodeScript:
				bodies.append(c)
		if bodies.size() != 20 or labels.size() != 20 or all_specs.size() != 20:
			_fail("demo gallery holds %d bodies, %d labels; table holds %d recipes (want 20/20/20)" % [
				bodies.size(), labels.size(), all_specs.size()])
		else:
			var bad: int = 0
			for i in range(20):
				var want_pos: Vector3 = Vector3((float(i % 4) - 1.5) * 1.2, 0.8, (float(i / 4) - 1.0) * 1.44)
				var name_ok: bool = (labels[i] as Label3D).text == String(all_specs[i]["name"])
				var pos_ok: bool = _near((bodies[i] as Node3D).position, want_pos)
				var col_ok: bool = (bodies[i].base_color as Color).is_equal_approx(all_specs[i]["color"])
				if not (name_ok and pos_ok and col_ok):
					bad += 1
					_fail("demo specimen %d: name %s, position %s, colour %s" % [i, name_ok, pos_ok, col_ok])
			if bad == 0:
				_say("      20 specimens, names in table order, on the shipped 4-wide lattice, in their colours")

	# --- 1, 2, 3, 7: every registry name -----------------------------------
	var reg_text: String = FileAccess.get_file_as_string(registry_path)
	var reg: Variant = JSON.parse_string(reg_text)
	if not (reg is Dictionary) or not ((reg as Dictionary).get("artifacts") is Dictionary):
		_fail("registry does not parse: %s" % registry_path)
		_finish(out_path)
		return
	var artifacts: Dictionary = reg["artifacts"]
	_say("")
	_say("[1,2,3] %d registry names" % artifacts.size())
	_say("%-30s %-9s %6s %6s %7s  %-21s %7s | %-13s %s" % [
		"name", "scene", "verts", "faces", "arr", "aabb (m)", "ms", "demo v/f", "verdict"])

	var costs: Array = []
	var stayed_seed: PackedStringArray = []
	var covered_ids: Dictionary = {}

	for name_v in artifacts.keys():
		var lookup: String = String(name_v)
		var entry: Dictionary = artifacts[name_v]
		var scene_path: String = String(entry.get("scene", ""))
		var scene_kind: String = "bare" if scene_path == BARE_SCENE else ("preset" if scene_path.contains("/presets/") else "other")
		var s: Dictionary = await _build_scene(scene_path)
		var notes: PackedStringArray = []
		var before_fails: int = _fails

		if not s["ok"]:
			_say("%-30s %-9s  — the registry scene built nothing: %s" % [lookup, scene_kind, scene_path])
			_fail("%s: scene missing or built nothing" % lookup)
			continue

		# The two names whose description is the seed itself.
		if SEED_NAMES.has(lookup):
			stayed_seed.append(lookup)
			if scene_path != BARE_SCENE or not _same_body(s, bare):
				_fail("%s: description is the bare seed but the scene builds something else" % lookup)
			_say("%-30s %-9s %6d %6d %7d  %-21s %7.1f | %-13s %s" % [
				lookup, scene_kind, s["verts"], s["faces"], s["arr"], _v(s["aabb"]), s["ms"], "-",
				"SEED by description" if _fails == before_fails else "FAIL"])
			continue

		var id: String = lookup.trim_prefix(PREFIX)
		var spec: Dictionary = Presets.spec(id)
		if spec.is_empty():
			_say("%-30s %-9s %6d %6d %7d  %-21s %7.1f | %-13s %s" % [
				lookup, scene_kind, s["verts"], s["faces"], s["arr"], _v(s["aabb"]), s["ms"], "-", "FAIL"])
			_fail("%s: no recipe carries the id '%s'" % [lookup, id])
			continue
		covered_ids[id] = true
		var random_counts: bool = _unseeded(spec)

		# 1. the scene is the node, with the script on the ROOT and the right preset.
		if s["script"] != NODE_SCRIPT:
			_fail("%s: scene root does not carry %s" % [lookup, NODE_SCRIPT])
		if s["preset"] != id:
			_fail("%s: scene preset is '%s', want '%s'" % [lookup, s["preset"], id])

		# 2. the demo's way.
		var d: Dictionary = await _build_demo(demo, spec)
		if s["seed_type"] != d["seed_type"] or not is_equal_approx(s["seed_scale"], d["seed_scale"]) \
				or s["generations"] != d["generations"] \
				or not (s["color"] as Color).is_equal_approx(d["color"]):
			_fail("%s: settings differ from the demo's (seed %s/%s scale %.2f/%.2f gens %d/%d)" % [
				lookup, s["seed_type"], d["seed_type"], s["seed_scale"], d["seed_scale"],
				s["generations"], d["generations"]])
		if s["rules"] != d["rules"]:
			_fail("%s: rule list differs from the demo's (%d rules against %d)" % [
				lookup, (s["rules"] as Array).size(), (d["rules"] as Array).size()])
		if s["seed_verts"] != d["seed_verts"] or s["seed_faces"] != d["seed_faces"]:
			_fail("%s: seed mesh differs from the demo's (%d/%d against %d/%d)" % [
				lookup, s["seed_verts"], s["seed_faces"], d["seed_verts"], d["seed_faces"]])
		if random_counts:
			notes.append("UNSEEDED")
		elif not _same_body(s, d):
			_fail("%s: body differs from the demo's — %d/%d/%d %s against %d/%d/%d %s" % [
				lookup, s["verts"], s["faces"], s["arr"], _v(s["aabb"]),
				d["verts"], d["faces"], d["arr"], _v(d["aabb"])])

		# 3. the negative test: not the bare seed.
		if _same_body(s, bare):
			_fail("%s: builds the bare seed" % lookup)

		# 7. rule liveness.
		var dead: Array = _dead_rules(spec)
		var known: Array = KNOWN_DEAD.get(id, [])
		for i in dead:
			if not known.has(i):
				_fail("%s: rule %d (%s) changes nothing" % [lookup, i, String((spec["rules"][i] as Dictionary).get("op", "?"))])
		for i in known:
			if not dead.has(i):
				notes.append("rule %d listed in KNOWN_DEAD is ALIVE now — delete it from the list" % i)
		if not dead.is_empty():
			notes.append("DEAD RULES %s" % str(dead))
		if s["is_seed_body"]:
			notes.append("BODY == ITS OWN %s SEED" % String(s["seed_type"]).to_upper())

		# Unseeded recipes: what CAN be compared is the spread, on both sides.
		var ms_all: Array = [s["ms"]]
		var faces_all: Array = [s["faces"]]
		var aabb_max: Vector3 = s["aabb"]
		var spread: String = ""
		if random_counts and scene_kind == "preset":
			var sf: Array = [s["faces"]]
			var df: Array = [d["faces"]]
			for _k in range(SAMPLES):
				var s2: Dictionary = await _build_scene(scene_path)
				var d2: Dictionary = await _build_demo(demo, spec)
				sf.append(s2["faces"])
				df.append(d2["faces"])
				ms_all.append(s2["ms"])
				faces_all.append(s2["faces"])
				aabb_max = Vector3(maxf(aabb_max.x, s2["aabb"].x), maxf(aabb_max.y, s2["aabb"].y), maxf(aabb_max.z, s2["aabb"].z))
			spread = "%-30s           faces over %d builds: scene %d..%d   demo %d..%d   largest aabb %s" % [
				"", SAMPLES + 1, sf.min(), sf.max(), df.min(), df.max(), _v(aabb_max)]

		# 8. outward: additions must leave the seed's own box (largest body seen).
		if _protrudes(spec) and scene_kind == "preset":
			var outside: bool = _outside_seed(aabb_max, s["seed_aabb"])
			if not outside:
				notes.append("NOTHING OUTSIDE ITS %s SEED (%s)" % [String(s["seed_type"]).to_upper(), _v(s["seed_aabb"])])
				if not KNOWN_INWARD.has(id):
					_fail("%s: adds geometry but nothing reaches outside its seed" % lookup)
			elif KNOWN_INWARD.has(id):
				notes.append("listed in KNOWN_INWARD but reaches OUTSIDE its seed now — delete it from the list")

		var verdict: String = "ok" if _fails == before_fails else "FAIL"
		if not notes.is_empty():
			verdict += "  [" + "; ".join(notes) + "]"
		_say("%-30s %-9s %6d %6d %7d  %-21s %7.1f | %6d/%-6d %s" % [
			lookup, scene_kind, s["verts"], s["faces"], s["arr"], _v(s["aabb"]), s["ms"],
			d["verts"], d["faces"], verdict])
		if spread != "":
			_say(spread)
		costs.append({"name": lookup, "ms": ms_all.max(), "faces": faces_all.max(), "aabb": aabb_max})

	# Every recipe except the seed should be reachable from some registry name.
	for sp in all_specs:
		var sid: String = String(sp["id"])
		if sid != "seed" and not covered_ids.has(sid):
			_fail("recipe '%s' has no registry name" % sid)

	# --- 6. the config key, through both handoffs --------------------------
	_say("")
	_say("[6] the `preset` config key")
	var ref: Dictionary = await _build_demo(demo, Presets.spec("extruded_spire"))
	var bare_ps: PackedScene = load(BARE_SCENE) as PackedScene

	# museum lane: apply_grid_config BEFORE the node is in the tree.
	var m: Node = bare_ps.instantiate()
	m.call("apply_grid_config", {"preset": "extruded_spire"})
	var md: Dictionary = await _measure(m, Time.get_ticks_usec())
	if _same_body(md, ref) and (md["rules"] as Array).size() == 2:
		_say("      before the tree (museum handoff): %d/%d, 2 rules — the spire" % [md["verts"], md["faces"]])
	else:
		_fail("preset key before the tree: %d/%d with %d rules, want %d/%d with 2" % [
			md["verts"], md["faces"], (md["rules"] as Array).size(), ref["verts"], ref["faces"]])

	# grid lane: add, _ready builds the seed, then the deferred apply_grid_config — twice.
	var gn: Node = bare_ps.instantiate()
	root.add_child(gn)
	await process_frame
	gn.call("apply_grid_config", {"preset": "extruded_spire"})
	gn.call("apply_grid_config", {"preset": "extruded_spire"})
	await process_frame
	var gd: Dictionary = _facts(gn, 0.0)
	gn.queue_free()
	await process_frame
	if _same_body(gd, ref) and (gd["rules"] as Array).size() == 2:
		_say("      after _ready, handed over twice (grid handoff): %d/%d, 2 rules — the spire, not doubled" % [gd["verts"], gd["faces"]])
	else:
		_fail("preset key after _ready: %d/%d with %d rules, want %d/%d with 2" % [
			gd["verts"], gd["faces"], (gd["rules"] as Array).size(), ref["verts"], ref["faces"]])

	# a token may still override what the recipe set.
	var on: Node = bare_ps.instantiate()
	on.call("apply_grid_config", {"preset": "extruded_spire", "color": Color(1, 0, 0)})
	var od: Dictionary = await _measure(on, Time.get_ticks_usec())
	if (od["color"] as Color).is_equal_approx(Color(1, 0, 0)) and _same_body(od, ref):
		_say("      preset + color: the token's colour wins, the body is the spire")
	else:
		_fail("preset + color: colour %s, body %d/%d" % [str(od["color"]), od["verts"], od["faces"]])

	# an unknown name is the bare seed (and a warning in the log), never another recipe.
	var un: Node = bare_ps.instantiate()
	un.call("apply_grid_config", {"preset": "no_such_recipe"})
	var ud: Dictionary = await _measure(un, Time.get_ticks_usec())
	if _same_body(ud, bare) and (ud["rules"] as Array).is_empty():
		_say("      unknown name: the bare seed (one warning expected in the log)")
	else:
		_fail("unknown preset name built %d/%d, want the bare seed" % [ud["verts"], ud["faces"]])

	# --- cost ---------------------------------------------------------------
	_say("")
	_say("cost — the three most expensive registry scenes (slowest build seen)")
	costs.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["ms"]) > float(b["ms"]))
	for i in range(mini(3, costs.size())):
		_say("      %-30s %7.1f ms  %6d faces  aabb %s" % [costs[i]["name"], costs[i]["ms"], costs[i]["faces"], _v(costs[i]["aabb"])])
	_say("stayed on the bare seed, by description: %s" % ", ".join(stayed_seed))

	demo.queue_free()
	await process_frame
	_finish(out_path)


func _finish(out_path: String) -> void:
	_say("")
	_say("RESULT: %d failed assertion(s)" % _fails)
	if out_path != "":
		var f := FileAccess.open(out_path, FileAccess.WRITE)
		if f != null:
			f.store_string("\n".join(_lines) + "\n")
			f.close()
	quit(mini(_fails, 125))
