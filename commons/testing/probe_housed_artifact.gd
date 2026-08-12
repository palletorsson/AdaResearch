extends SceneTree

## One artifact, fully housed, photographed — the spike across the four seams
## that stand between the museum we have and the museum we want.
##
## The building already reads close to AAA: pooled light, polished floor,
## travertine, trims. What stands in it are diagrams on bare ground. 69% of
## spine artifacts are diagram-like (doc/plans/the_museum_hangs_diagrams.md),
## so the HOUSING has to carry the AAA signal, and the housing is exactly what
## is unwired.
##
## Four seams crossed at once, each reusing what already exists rather than
## inventing a parallel:
##
##   1. the certified wall kit   museum_wall_piece.tscn — 23 variants, 11
##                               quality gates passing, and ZERO placements
##                               across 2417 maps
##   2. the plinth decision      em_plinths.measure() + plan_measured() — the
##                               same lift maths the Endless Museum already
##                               uses, called here from outside it for the
##                               first time
##   3. the caption              TextScreen, fed from the artifact's own
##                               registry description
##   4. the measured body        settled 0.5 s before measuring, because two
##                               process frames photograph scaffolding
##
##   godot --path . --xr-mode off --no-window \
##     --script res://commons/testing/probe_housed_artifact.gd -- \
##     --artifact=bias_visualizer --out=user://housed/bias_visualizer.png

const PLINTHS := preload("res://commons/scenes/em/em_plinths.gd")
const WALL_PIECE := preload("res://commons/artifacts/museum/museum_wall_piece.tscn")
const TextScreenRes = preload("res://commons/ui/text_screen.gd")
const REGISTRY_DIR := "res://commons/artifacts/registry"

#: The wall run behind the exhibit: service span, the protected artwork field,
#: service span. The kit's own семantics — `feature` means "protected artwork
#: field", `service` means "peripheral prop/services zone".
const RUN := [["service", 1], ["feature", 3], ["service", 1]]

#: The wall bands are READ, not copied. museum_contract_pilot.json is the
#: declaration; tools/wall_bands.py is its Python reader; this is its GDScript
#: one. A constant here would be a fourth opinion about eye height, and the
#: feature field's top moved from 2.7 m to 2.3 m the moment someone decided
#: signage keeps the upper band — a copy would not have moved with it.
const CONTRACT_PILOT := "res://commons/data/museum_contract_pilot.json"
var _feature_h := [0.20, 0.80]
var _feature_v := [1.1, 2.3]
var _upper_v := [2.3, 4.0]


func _load_bands() -> void:
	if not FileAccess.file_exists(CONTRACT_PILOT):
		return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(CONTRACT_PILOT))
	if not (parsed is Dictionary):
		return
	var ws = (parsed as Dictionary).get("wall_system", {})
	if not (ws is Dictionary):
		return
	var ff = (ws as Dictionary).get("feature_field", {})
	if ff is Dictionary:
		var h = (ff as Dictionary).get("horizontal_percent", [])
		var v = (ff as Dictionary).get("vertical_m", [])
		if h is Array and (h as Array).size() == 2:
			_feature_h = [float(h[0]) / 100.0, float(h[1]) / 100.0]
		if v is Array and (v as Array).size() == 2:
			_feature_v = [float(v[0]), float(v[1])]
	var up = (ws as Dictionary).get("upper_band_m", [])
	if up is Array and (up as Array).size() == 2:
		_upper_v = [float(up[0]), float(up[1])]

var _map: String = "Point_One"
var _token: String = "bias_visualizer"
var _out: String = "user://housed/probe.png"
var _settle: float = 0.5
var _chars: int = 420
## --lineage: hang the anchor's DNA run as a ROW of framed works along the wall,
## one span per value. The corpus offers 36 floor-slot series and 345 wall runs
## of 4 m or more, so a lineage is a wall proposition, not a floor one.
var _lineage: bool = false
## --precinct=<token>: cut a certified portal into the run and stand a precinct
## work beyond it, so the threshold is something you look THROUGH rather than a
## rectangle in a report.
var _precinct: String = ""
## --eye: stand where a visitor stands instead of framing the wall flat on.
var _eye: bool = false
var _values: Array = []
var _report: Dictionary = {}


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		var a := String(arg)
		if a.begins_with("--artifact="):
			_token = a.substr(11)
		elif a.begins_with("--out="):
			_out = a.substr(6)
		elif a.begins_with("--chars="):
			_chars = int(a.substr(8))
		elif a == "--lineage":
			_lineage = true
		elif a == "--eye":
			_eye = true
		elif a.begins_with("--precinct="):
			_precinct = a.substr(11)
		elif a.begins_with("--map="):
			_map = a.substr(6)
		elif a.begins_with("--settle="):
			_settle = float(a.substr(9))
	_load_bands()
	_run.call_deferred()


# ── registry ────────────────────────────────────────────────────────

func _entry() -> Dictionary:
	var dir := DirAccess.open(REGISTRY_DIR)
	if dir == null:
		return {}
	for f in dir.get_files():
		if not f.ends_with(".json"):
			continue
		var text := FileAccess.get_file_as_string("%s/%s" % [REGISTRY_DIR, f])
		var parsed = JSON.parse_string(text)
		if not (parsed is Dictionary):
			continue
		var arts = (parsed as Dictionary).get("artifacts", {})
		if arts is Dictionary and (arts as Dictionary).has(_token):
			return (arts as Dictionary)[_token]
		if arts is Dictionary:
			for k in (arts as Dictionary):
				var e = (arts as Dictionary)[k]
				if e is Dictionary and String((e as Dictionary).get("lookup_name", "")) == _token:
					return e
	return {}


func _entry_for(token: String) -> Dictionary:
	var keep := _token
	_token = token
	var e := _entry()
	_token = keep
	return e


# ── the room ────────────────────────────────────────────────────────

func _mat(c: Color, rough: float = 0.7) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = 0.0
	return m


func _box(parent: Node3D, pos: Vector3, size: Vector3, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)


func _build_room(root: Node3D, run_w: float) -> void:
	# A polished dark floor, because that is what the Endless Museum actually
	# has and the probe must be comparable to it.
	var floor_mat := _mat(Color(0.10, 0.10, 0.12), 0.18)
	floor_mat.metallic = 0.25
	_box(root, Vector3(0, -0.05, 2.0), Vector3(run_w + 8.0, 0.1, 12.0), floor_mat)
	# Side returns, so the span reads as a room rather than a flat.
	var stone := _mat(Color(0.78, 0.76, 0.71), 0.85)
	_box(root, Vector3(-run_w / 2.0 - 0.5, 2.0, 3.0), Vector3(0.3, 4.0, 6.0), stone)
	_box(root, Vector3(run_w / 2.0 + 0.5, 2.0, 3.0), Vector3(0.3, 4.0, 6.0), stone)
	_box(root, Vector3(0, 4.15, 3.0), Vector3(run_w + 1.6, 0.3, 6.6), stone)


## The anchor's widest declared DNA axis, as an ordered list of values.
func _dna_values() -> Array:
	var path := "res://commons/data/artifact_relations.json"
	if not FileAccess.file_exists(path):
		return []
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not (parsed is Dictionary):
		return []
	var rec = ((parsed as Dictionary).get("artifacts", {}) as Dictionary).get(_token, {})
	var axes = (rec as Dictionary).get("axes", {}) if rec is Dictionary else {}
	var best: Array = []
	var best_axis := ""
	for axis in (axes as Dictionary):
		var vals: Array = (axes as Dictionary)[axis]
		if vals.size() > best.size():
			best = vals
			best_axis = String(axis)
	_report["dna_axis"] = best_axis
	return best


func _run_spec() -> Array:
	"""A lineage wants one FEATURE span per value, shouldered by service spans."""
	if not _lineage:
		return RUN
	_values = _dna_values()
	if _values.size() < 2:
		return RUN
	var spec: Array = [["service", 1]]
	for _v in _values:
		spec.append(["feature", 1])
	# The threshold, in the run itself: a certified walk-through span. A
	# precinct work is not exhibited, it is entered, and the door is what the
	# museum owes it.
	if _precinct != "":
		spec.append(["portal", 2])
	spec.append(["service", 1])
	return spec


func _build_wall_run(root: Node3D) -> float:
	"""Instantiate the certified kit, span by span. First call in the tree."""
	var plan_spec: Array = _run_spec()
	var total := 0.0
	for spec in plan_spec:
		total += float(spec[1])
	var x := -total / 2.0
	for spec in plan_spec:
		var kind := String(spec[0])
		var cells := int(spec[1])
		var piece := WALL_PIECE.instantiate() as Node3D
		piece.set("kind", kind)
		piece.set("width_cells", cells)
		piece.set("height", 4.0)
		piece.set("quality_tier", "aaa")
		piece.set("lod_level", 0)
		piece.position = Vector3(x + cells / 2.0, 0.0, 0.0)
		root.add_child(piece)
		x += float(cells)
	return total


func _light(root: Node3D, pos: Vector3, target: Vector3, energy: float) -> void:
	var l := SpotLight3D.new()
	l.position = pos
	l.look_at_from_position(pos, target, Vector3.UP)
	l.light_energy = energy
	l.spot_range = 12.0
	l.spot_angle = 38.0
	l.light_color = Color(1.0, 0.96, 0.90)
	l.shadow_enabled = true
	root.add_child(l)


## The reserved artwork field, FILLED.
##
## The kit's `feature` span means "protected artwork field" and every span the
## probe has hung so far rendered as a black void — the field is reserved and
## nothing puts anything in it. That void is the same gap as em_detail's 52-60
## blank showings per segment: correctly placed, correctly sized, empty.
##
## What belongs there, per the design: the CURRENT MAP's text, shown as a work
## rather than a label. So this hangs the map's own blurb.md in the field the
## kit already reserved, at the height the contract already declared.
func _hang_feature_work(root: Node3D, run_w: float) -> Dictionary:
	if _lineage and _values.size() >= 2:
		return _hang_lineage(root, run_w)
	# Where the feature span sits in the run.
	var x := -run_w / 2.0
	var span_x := 0.0
	var span_w := 0.0
	for spec in RUN:
		var cells := float(spec[1])
		if String(spec[0]) == "feature":
			span_x = x + cells / 2.0
			span_w = cells
			break
		x += cells
	if span_w <= 0.0:
		return {"hung": false, "why": "this run has no feature span"}

	var field_w: float = span_w * (_feature_h[1] - _feature_h[0])
	var v_centre: float = (_feature_v[0] + _feature_v[1]) / 2.0

	var blurb := ""
	var path := "res://commons/maps/%s/blurb.md" % _map
	if FileAccess.file_exists(path):
		blurb = FileAccess.get_file_as_string(path).strip_edges()

	var work := TextScreenRes.new()
	work.mode = TextScreenRes.Mode.SCREEN       # a framed panel, wall-hung
	work.title = _map.replace("_", " ").to_upper()
	# HOW MUCH text, not just which text. TextScreen's layout is tuned for a
	# 0.46 m caption; the whole 655-character blurb on a 1.8 m wall work renders
	# Raw text, unwrapped, on purpose. TextScreen owns legibility now — it wraps
	# to its own width and truncates rather than shrinking below a readable
	# glyph. The probe pre-wrapping to 34 columns was a workaround for a
	# convention that lived only in callers' heads; passing the paragraph
	# straight through is the test that the workaround is no longer needed.
	var shown := blurb.left(_chars)
	work.body = shown
	work.width_m = field_w
	work.position = Vector3(span_x, v_centre, 0.14)
	root.add_child(work)
	return {
		"hung": true, "span_w_m": span_w, "field_w_m": field_w,
		"centre_v_m": v_centre, "map": _map,
		"text_source": "commons/maps/%s/blurb.md" % _map,
		"text_chars_available": blurb.length(),
		"text_chars_shown": shown.length(),
		"chars_per_metre": int(round(float(shown.length()) / maxf(field_w, 0.01))),
	}


## A lineage as a ROW: one framed work per DNA value, evenly spaced along the
## wall — which is what em_sets already means by `sibling -> row`, and what the
## kit's repeated `feature` spans are for.
##
## The reason this is a wall proposition and not a floor one is a measured
## scarcity: 481 anchors declare a DNA run, the corpus offers 36 floor-slot
## series and 18 of its 30 museums offer none at all — while the same 30
## museums carry 345 wall runs of 4 m or more, in 27 of them. The floor cannot
## host the lineages. The wall can, ten times over.
func _hang_lineage(root: Node3D, run_w: float) -> Dictionary:
	var n := _values.size()
	var first_x := -run_w / 2.0 + 1.0            # past the opening service span
	var v_centre: float = (_feature_v[0] + _feature_v[1]) / 2.0
	var field_w: float = 1.0 * (_feature_h[1] - _feature_h[0])
	for i in range(n):
		var work := TextScreenRes.new()
		work.mode = TextScreenRes.Mode.SCREEN
		work.title = String(_values[i]).replace("_", " ").to_upper()
		work.body = ""
		work.width_m = field_w
		work.position = Vector3(first_x + float(i) + 0.5, v_centre, 0.14)
		root.add_child(work)
	return {
		"hung": true, "mode": "lineage_row", "works": n,
		"axis": String(_report.get("dna_axis", "")),
		"values": _values,
		"span_each_m": 1.0, "field_w_m": field_w, "centre_v_m": v_centre,
	}


# ── the run ─────────────────────────────────────────────────────────

func _run() -> void:
	var root := Node3D.new()
	get_root().add_child(root)

	var entry := _entry()
	var scene_path := String(entry.get("scene", ""))
	if scene_path == "" or not ResourceLoader.exists(scene_path):
		push_error("probe_housed_artifact: no scene for '%s'" % _token)
		quit(2)
		return

	var run_w := _build_wall_run(root)
	_build_room(root, run_w)
	var feature := _hang_feature_work(root, run_w)

	# The artifact, in the tree and SETTLED before anything measures it.
	var artifact := (load(scene_path) as PackedScene).instantiate() as Node3D
	root.add_child(artifact)
	await process_frame
	await process_frame
	await create_timer(_settle).timeout

	var m: Dictionary = PLINTHS.measure(artifact)
	var h := float(m.get("height_m", 0.0))
	var b := float(m.get("base_m", 0.0))
	var thin := float(m.get("thin_m", 0.0))

	# The Endless Museum's own plinth decision, called from outside it.
	var plan: Dictionary = PLINTHS.plan_measured(_token, {}, h, b, thin)
	var plinth_token := String(plan.get("plinth", ""))
	# The plan names it artifact_y, not lift — reading the wrong key left
	# chladni_plate sitting on the floor beside its own micropod.
	var lift := float(plan.get("artifact_y", 0.0))
	var plinth_scene := String(plan.get("scene", ""))

	var housed := false
	if plinth_scene != "" and ResourceLoader.exists(plinth_scene):
		var plinth := (load(plinth_scene) as PackedScene).instantiate() as Node3D
		for k in (plan.get("config", {}) as Dictionary):
			plinth.set_meta("config_%s" % str(k), (plan["config"] as Dictionary)[k])
		root.add_child(plinth)
		housed = true
	if lift > 0.0:
		artifact.position.y = lift
	artifact.position.z = 0.9          # off the wall face, on the plinth line

	# The caption, from the artifact's own description.
	var caption := TextScreenRes.new()
	caption.title = String(entry.get("name", _token)).to_upper()
	caption.body = String(entry.get("description", "")).left(150)
	caption.width_m = 0.42
	caption.position = Vector3(run_w / 2.0 - 0.9, 1.15, 0.55)
	root.add_child(caption)

	# The PRECINCT beyond the door: the body the building was never going to
	# contain, standing on open ground and visible through the portal.
	if _precinct != "":
		var pe := _entry_for(_precinct)
		var pscene := String(pe.get("scene", ""))
		if pscene != "" and ResourceLoader.exists(pscene):
			var pw := (load(pscene) as PackedScene).instantiate() as Node3D
			root.add_child(pw)
			await process_frame
			var pm: Dictionary = PLINTHS.measure(pw)
			# Beyond the portal, which sits at the right-hand end of the run.
			pw.position = Vector3(run_w / 2.0 - 1.0, 0.0, -7.0)
			_report["precinct"] = {
				"token": _precinct,
				"height_m": snappedf(float(pm.get("height_m", 0.0)), 0.01),
				"base_m": snappedf(float(pm.get("base_m", 0.0)), 0.01),
				"stands": "on open ground beyond the portal",
			}
			# Daylight out there, so the door reads as a way out.
			var sky := DirectionalLight3D.new()
			sky.rotation_degrees = Vector3(-42, 155, 0)
			sky.light_energy = 1.1
			sky.light_color = Color(0.86, 0.90, 1.0)
			root.add_child(sky)
			_box(root, Vector3(run_w / 2.0 - 1.0, -0.06, -8.0),
				Vector3(22.0, 0.1, 20.0), _mat(Color(0.20, 0.21, 0.19), 0.95))

	# SIGNAGE, in the upper band the feature field just gave back. The whole
	# point of stopping the artwork field at 2.3 m is that this plate has
	# somewhere uncontested to live.
	var sign := TextScreenRes.new()
	sign.mode = TextScreenRes.Mode.SCREEN
	sign.title = _map.replace("_", " ").to_upper()
	sign.body = ""
	sign.width_m = 1.4
	# Over the far end of the run, in the upper band the feature field gave
	# back — not over the artwork it would otherwise crowd.
	sign.position = Vector3(run_w * 0.5 - 2.6, _upper_v[0] + 0.45, 0.14)
	root.add_child(sign)

	_light(root, Vector3(0, 3.6, 3.2), Vector3(0, lift + h * 0.5, 0.6), 6.0)
	_light(root, Vector3(0, 3.9, 1.6), Vector3(0, _upper_v[0] + 0.4, 0.1), 2.6)
	_light(root, Vector3(-2.4, 3.4, 2.4), Vector3(-1.2, 1.4, 0.2), 2.2)

	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.05, 0.05, 0.07)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.32, 0.32, 0.36)
	e.ambient_light_energy = 0.55
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment = e
	root.add_child(env)

	# Eye height, standing where a visitor would stop to look.
	var cam := Camera3D.new()
	if _eye:
		# Standing where a visitor stands: off the axis, a little back, eye at
		# 1.65 m — the height the whole band system is written around.
		# Inside the room, not inside its return wall: the returns run from
		# z=0 to z=6, so a camera at 6.4 was standing in masonry.
		cam.position = Vector3(-run_w * 0.16, 1.65, 4.6)
		cam.look_at(Vector3(run_w * 0.20, 1.75, 0.2), Vector3.UP)
		cam.fov = 74.0
	else:
		cam.position = Vector3(0.0, 1.65, 5.2)
		cam.look_at(Vector3(0.0, maxf(1.2, lift + h * 0.45), 0.4), Vector3.UP)
		cam.fov = 55.0
	root.add_child(cam)
	cam.make_current()

	await process_frame
	await process_frame
	await create_timer(0.4).timeout

	var img := get_root().get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(_out.get_base_dir()))
	img.save_png(_out)

	_report = {
		"artifact": _token,
		"measured": {"height_m": h, "base_m": b, "thin_m": thin,
					 "meshes": int(m.get("meshes", 0))},
		"plinth": {"token": plinth_token, "scene": plinth_scene,
				   "lift_m": lift, "housed": housed,
			   "plinth_height": float(plan.get("plinth_height", 0.0)),
				   "why": String(plan.get("why", ""))},
		"wall_run": {"spans": RUN.size(), "width_m": run_w,
					 "kit": "museum_wall_piece"},
		"caption_chars": String(entry.get("description", "")).length(),
		"feature_field": feature,
		"shot": _out,
	}
	print("[housed] %s" % JSON.stringify(_report, "  "))
	quit(0)
