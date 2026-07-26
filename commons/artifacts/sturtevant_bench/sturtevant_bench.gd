extends Node3D

## Sturtevant Bench — an artifact beside the same artifact rebuilt from its own words.
##
## @identity
## essence: code_form(artifact) vs prose_form(@identity of the same artifact) -> the gap between them is the exhibit
## desire: to catch a claim and its implementation standing next to each other, and to see which one is emptier
## critical_parameter: subject — whose claim is on trial. Every artifact in this project carries an @identity block asserting what it is; 817 of them do.
## triggers: the right-hand plinth compiles the subject's own description into form, with no access to its source; the readout counts what each side actually contains
## emerges: where the prose was vaguer than the code the twin comes out smooth, round and confident, and the number under it is small
## needs: a subject with an @identity block [has]; nothing else — the twin is built from the words alone
## relationships: the enforcement arm of the @identity convention, and kin to lineage_vitrine (that one shows what an object might have been; this one shows what it claims to be)
## truth: a copy is not the failure of an original — it is the test of whether the original was ever fully written down.
##
## Sturtevant remade other artists' works from memory. Memory is lossy, and the loss
## is the work. Here the "memory" is the artifact's own documentation, and the copyist
## is deliberately stupid: a deterministic reader that knows a small vocabulary of
## shapes and nothing else. It cannot see the source. It can only believe the label.
##
## So the twin is not an approximation that got worse with effort. It is exactly as
## rich as the sentence that described it — which is the measurement being taken.

const HangarKit = preload("res://commons/artifacts/_hangar/hangar_kit.gd")
const REGISTRY_DIR := "res://commons/artifacts/registry/"

## Whose claim is on trial.
@export var subject: String = "galton_board"
## Scale the real specimen down to bench size. The twin is built to match.
@export var subject_scale: float = 0.42
@export var deck_height: float = 0.94
@export var span: float = 1.30
@export var finish: String = "terminal"
@export var wear: float = 0.10
@export var unit_code: String = "SB-01"

# The copyist's entire vocabulary. If a word is not in here it contributes nothing to
# form — it only makes the twin vaguer. This shortness is deliberate and is the joke:
# a reader who knows twelve shapes is still a reader, and most claims are written as
# if the reader knew everything.
const VOCAB := {
	"grid": "grid", "lattice": "grid", "array": "grid", "matrix": "grid",
	"peg": "grid", "cell": "grid",
	"sphere": "ball", "ball": "ball", "point": "ball", "dot": "ball",
	"particle": "ball", "node": "ball",
	"arrow": "arrow", "vector": "arrow", "direction": "arrow", "force": "arrow",
	"curve": "curve", "bell": "curve", "gaussian": "curve", "distribution": "curve",
	"wave": "curve", "spectrum": "curve",
	"bar": "bar", "histogram": "bar", "bin": "bar", "column": "bar", "stack": "bar",
	"line": "line", "path": "line", "trace": "line", "walk": "line", "edge": "line",
	"screen": "panel", "readout": "panel", "display": "panel", "panel": "panel",
	"board": "panel", "label": "panel",
	"box": "box", "cabinet": "box", "case": "box", "housing": "box", "cube": "box",
	"light": "glow", "glow": "glow", "ember": "glow", "lit": "glow",
}
# Words that name a claim rather than a thing. They are why the twin goes smooth.
const HEDGE := ["emerges", "reveals", "becomes", "understanding", "realization",
	"relationship", "inevitable", "structure", "meaning", "experience", "sense",
	"convergence", "independence", "theory", "concept", "visible", "legible"]

var _cab: Node3D
var _code_count: int = 0
var _spec_count: int = 0
var _vagueness: float = 0.0
var _unrealised: Array[String] = []
# A scene the registry cannot resolve is NOT an empty artifact, and reporting it as
# "0 elements" would be the bench telling exactly the kind of confident lie it exists
# to catch. basis_vectors_rig reads 0/0 for this reason and not because it is bare.
var _resolved: bool = false


func _ready() -> void:
	_build_bench()
	var ident: Dictionary = _read_identity()
	_mount_code_side()
	_mount_spec_side(ident)
	_mount_readout(ident)


# ── the subject, as CODE ─────────────────────────────────────────────────────

func _entry() -> Dictionary:
	var dir := DirAccess.open(REGISTRY_DIR)
	if dir == null:
		return {}
	for f in dir.get_files():
		if not f.ends_with(".json"):
			continue
		var fa := FileAccess.open(REGISTRY_DIR + f, FileAccess.READ)
		if fa == null:
			continue
		var j := JSON.new()
		if j.parse(fa.get_as_text()) != OK:
			continue
		if typeof(j.data) != TYPE_DICTIONARY:
			continue
		var arts = (j.data as Dictionary).get("artifacts", j.data)
		if typeof(arts) == TYPE_DICTIONARY and (arts as Dictionary).has(subject):
			return (arts as Dictionary)[subject]
	return {}


func _mount_code_side() -> void:
	var e: Dictionary = _entry()
	var scene_path: String = str(e.get("scene", ""))
	if scene_path == "":
		return
	var ps: PackedScene = load(scene_path)
	if ps == null:
		return
	var inst: Node3D = ps.instantiate()
	_resolved = true
	_freeze(inst)
	var holder := Node3D.new()
	holder.name = "CodeSide"
	holder.position = Vector3(-span * 0.5, deck_height, 0)
	holder.scale = Vector3.ONE * subject_scale
	add_child(holder)
	holder.add_child(inst)
	_code_count = _count_meshes(inst)


## A bench specimen is still. Turn off whatever makes the subject run, so the two
## sides are compared as FORM and not as one of them being mid-animation.
func _freeze(n: Node) -> void:
	for prop in ["auto_drop", "auto_throw", "auto_spin", "auto_run", "animate",
			"rotation_enabled", "show_particles"]:
		if prop in n:
			n.set(prop, false)


func _count_meshes(n: Node) -> int:
	var c: int = 1 if n is MeshInstance3D else 0
	for k in n.get_children():
		c += _count_meshes(k)
	return c


# ── the subject, as PROSE ────────────────────────────────────────────────────

func _read_identity() -> Dictionary:
	var e: Dictionary = _entry()
	var scene_path: String = str(e.get("scene", ""))
	var gd: String = scene_path.replace(".tscn", ".gd")
	var out: Dictionary = {"raw": "", "fields": {}}
	if gd == "" or not FileAccess.file_exists(gd):
		return out
	var fa := FileAccess.open(gd, FileAccess.READ)
	if fa == null:
		return out
	var txt: String = fa.get_as_text()
	var lines: PackedStringArray = txt.split("\n")
	var raw: String = ""
	var fields: Dictionary = {}
	for l in lines:
		var s: String = l.strip_edges()
		if not s.begins_with("#"):
			continue
		s = s.lstrip("#").strip_edges()
		for key in ["essence", "desire", "emerges", "needs", "truth", "critical_parameter"]:
			if s.begins_with(key + ":"):
				var v: String = s.substr(key.length() + 1).strip_edges()
				fields[key] = v
				raw += " " + v
	out["raw"] = raw
	out["fields"] = fields
	return out


## THE COPYIST. Reads the words, knows twelve shapes, has never seen the source.
## Concrete nouns become elements. Everything else becomes vagueness, and vagueness
## does not become nothing — it becomes SMOOTHNESS: bigger, rounder, fewer, calmer.
## That is the finding this bench exists to show, so it must be in the geometry and
## not in a caption.
func _mount_spec_side(ident: Dictionary) -> void:
	var holder := Node3D.new()
	holder.name = "SpecSide"
	holder.position = Vector3(span * 0.5, deck_height, 0)
	add_child(holder)

	var raw: String = str(ident.get("raw", "")).to_lower()
	if raw.strip_edges() == "":
		var none := Label3D.new()
		none.text = "no @identity —\nnothing was ever claimed"
		none.font_size = 22
		none.pixel_size = 0.001
		none.modulate = Color(0.92, 0.62, 0.12)
		none.position = Vector3(0, 0.34, 0)
		holder.add_child(none)
		return

	var words: PackedStringArray = raw.replace(",", " ").replace(".", " ") \
		.replace("—", " ").replace("(", " ").replace(")", " ").split(" ", false)
	var kinds: Dictionary = {}
	var concrete: int = 0
	var hedges: int = 0
	for w in words:
		var t: String = w.strip_edges().to_lower()
		if t == "":
			continue
		if VOCAB.has(t):
			var k: String = VOCAB[t]
			kinds[k] = int(kinds.get(k, 0)) + 1
			concrete += 1
		elif t in HEDGE:
			hedges += 1
	var total: int = maxi(words.size(), 1)
	# vagueness: how much of the claim named nothing you could build
	_vagueness = clampf(1.0 - (float(concrete) / float(maxi(total / 6, 1))), 0.0, 1.0)
	_vagueness = clampf(_vagueness * 0.65 + float(hedges) / float(total) * 3.0, 0.0, 1.0)

	var smooth: float = _vagueness
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	# The twin has no palette of its own. It is the colour of an unexamined claim:
	# clean, confident, and the same everywhere.
	mat.albedo_color = Color(0.86, 0.85, 0.82).lerp(Color(0.94, 0.94, 0.93), smooth)
	mat.roughness = lerpf(0.55, 0.12, smooth)
	mat.metallic = 0.0

	var order: Array = kinds.keys()
	order.sort()
	var i: int = 0
	for k in order:
		var n: int = mini(int(kinds[k]), 4)
		_emit_kind(holder, str(k), n, i, smooth, mat)
		i += 1
	_spec_count = _count_meshes(holder)

	# Claims that named nothing the copyist could build are listed, not silently lost.
	for key in ["essence", "emerges", "truth"]:
		var v: String = str(ident["fields"].get(key, "")).to_lower()
		if v == "":
			continue
		var hit: bool = false
		for w in v.replace(",", " ").split(" ", false):
			if VOCAB.has(str(w).strip_edges()):
				hit = true
				break
		if not hit:
			_unrealised.append(key)

	if kinds.is_empty():
		# A claim entirely of abstractions compiles to ONE smooth mass. This is the
		# strongest reading the bench can produce and it should not be softened.
		var blob := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.17
		sm.height = 0.34
		blob.mesh = sm
		blob.material_override = mat
		blob.position = Vector3(0, 0.20, 0)
		holder.add_child(blob)
		_spec_count = 1


func _emit_kind(host: Node3D, kind: String, n: int, slot: int, smooth: float,
		mat: StandardMaterial3D) -> void:
	var x: float = -0.16 + float(slot) * 0.11
	var round_up: float = lerpf(1.0, 2.2, smooth)   # vagueness inflates and merges
	match kind:
		"grid":
			for r in range(2):
				for c in range(mini(n + 1, 4)):
					host.add_child(_cube(Vector3(x + float(c) * 0.045, 0.06 + float(r) * 0.045, 0),
						0.030 * round_up, mat))
		"ball":
			for b in range(n):
				host.add_child(_sphere(Vector3(x, 0.10 + float(b) * 0.07, 0), 0.028 * round_up, mat))
		"bar":
			for b in range(mini(n + 2, 5)):
				var hgt: float = 0.06 + float(b) * 0.035
				host.add_child(_box(Vector3(x + float(b) * 0.042, hgt * 0.5, 0),
					Vector3(0.030, hgt, 0.030), mat))
		"arrow":
			for b in range(n):
				host.add_child(_box(Vector3(x, 0.14, float(b) * 0.05),
					Vector3(0.012 * round_up, 0.012 * round_up, 0.20), mat))
		"curve":
			for s in range(8):
				var t: float = float(s) / 7.0
				host.add_child(_sphere(Vector3(x + t * 0.26 - 0.13,
					0.16 + sin(t * PI) * 0.10, 0), 0.016 * round_up, mat))
		"line":
			for s in range(6):
				host.add_child(_cube(Vector3(x - 0.10 + float(s) * 0.04,
					0.08 + float(s) * 0.012, 0), 0.014 * round_up, mat))
		"panel":
			host.add_child(_box(Vector3(x, 0.20, 0), Vector3(0.20, 0.13, 0.010), mat))
		"box":
			host.add_child(_box(Vector3(x, 0.11, 0), Vector3(0.17, 0.22, 0.12), mat))
		"glow":
			var g := _sphere(Vector3(x, 0.30, 0), 0.026, mat)
			var em := StandardMaterial3D.new()
			em.albedo_color = Color(0.95, 0.93, 0.88)
			em.emission_enabled = true
			em.emission = Color(0.95, 0.93, 0.88)
			em.emission_energy_multiplier = 1.2
			g.material_override = em
			host.add_child(g)


func _cube(p: Vector3, s: float, m: Material) -> MeshInstance3D:
	return _box(p, Vector3(s, s, s), m)


func _box(p: Vector3, s: Vector3, m: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = s
	mi.mesh = b
	mi.material_override = m
	mi.position = p
	return mi


func _sphere(p: Vector3, r: float, m: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	mi.mesh = s
	mi.material_override = m
	mi.position = p
	return mi


# ── the bench ────────────────────────────────────────────────────────────────

func _build_bench() -> void:
	var pal: Dictionary = HangarKit.finish_palette(finish)
	var col_body: Color = pal["body"]
	var col_accent: Color = pal["accent"]
	var shell: StandardMaterial3D = HangarKit.finish_body(finish, col_body, wear)
	var steel: StandardMaterial3D = HangarKit.worn_metal(col_body.lightened(0.10))
	var accent: StandardMaterial3D = HangarKit.emissive(col_accent, 2.2)

	var cab := Node3D.new()
	cab.name = "Cabinet"
	cab.set_meta("housing", true)
	add_child(cab)
	_cab = cab

	var w: float = span + 0.72
	var d: float = 0.56
	cab.add_child(HangarKit.box(Vector3(0, deck_height - 0.03, 0), Vector3(w, 0.06, d), shell))
	var p: Node3D = HangarKit.plinth(w - 0.12, d - 0.06, deck_height - 0.06,
		finish, wear, col_accent, unit_code)
	if p:
		p.position.y = deck_height - 0.06
		cab.add_child(p)
	cab.add_child(HangarKit.box(Vector3(0, deck_height - 0.004, d * 0.5 - 0.012),
		Vector3(w * 0.97, 0.006, 0.006), accent))

	# TWO IDENTICAL PLINTHS, identically lit. Nothing about the furniture may hint
	# which side is the original — that judgement has to come from looking.
	for sx in [-1.0, 1.0]:
		cab.add_child(HangarKit.box(
			Vector3(sx * span * 0.5, deck_height + 0.012, 0),
			Vector3(0.44, 0.024, 0.44), steel))

	var sign: MeshInstance3D = HangarKit.stencil(
		"CLAIM vs CODE · " + subject.to_upper(), Vector2(minf(w * 0.60, 0.78), 0.030),
		col_accent.lightened(0.35))
	if sign:
		sign.position = Vector3(0, deck_height - 0.078, d * 0.5 + 0.004)
		cab.add_child(sign)

	for pair in [[-1.0, "CODE"], [1.0, "FROM ITS OWN WORDS"]]:
		var lbl: MeshInstance3D = HangarKit.stencil(
			str(pair[1]), Vector2(0.34, 0.020), Color(0.72, 0.73, 0.78))
		if lbl:
			lbl.position = Vector3(float(pair[0]) * span * 0.5, deck_height - 0.135,
				d * 0.5 + 0.004)
			cab.add_child(lbl)


func _mount_readout(_ident: Dictionary) -> void:
	var pal: Dictionary = HangarKit.finish_palette(finish)
	var l := Label3D.new()
	l.name = "DivergenceReadout"
	l.font_size = 26
	l.pixel_size = 0.001
	l.modulate = pal["text"]
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var missing: String = ", ".join(_unrealised) if not _unrealised.is_empty() else "none"
	if not _resolved:
		l.modulate = Color(0.92, 0.62, 0.12)
		l.text = "%s: no scene the registry can resolve.\nNothing to hold a claim against." % subject
	else:
		l.text = "code %d elements    words %d elements\nvagueness %d%%    unrealised claims: %s" % [
			_code_count, _spec_count, int(round(_vagueness * 100.0)), missing]
	l.position = Vector3(0, deck_height + 0.62, 0.10)
	add_child(l)


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("subject"):
		subject = str(config_data["subject"])
	if config_data.has("subject_scale"):
		subject_scale = float(config_data["subject_scale"])
	if config_data.has("span"):
		span = float(config_data["span"])
