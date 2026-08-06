extends Node3D

## Synthesis Stand — every promoted family's one best public form, decided by measurement.
##
## @identity
## essence: the machine that turns a DNA family back into ONE artifact — a hero (the single variant the measurements argue for, pinned and stood up) or a series (the whole family in measured order of departure from the shipped default, because the progression IS the argument)
## desire: to close the loop promotion opened. 355 artifacts became families; a family is not placeable, a synthesis is
## critical_parameter: subject — which family; mode auto reads the measured verdict from commons/data/dna_synthesis.json rather than asking anyone's taste
## triggers: _ready builds from the verdict file; apply_grid_config({subject, mode}) rebuilds
## emerges: a hero plinth carries the variant and a plaque stating WHICH values and the measured departure that chose them; a series rail carries default-first-then-ascending, so walking the rail is walking away from the shipped form
## needs: commons/data/dna_synthesis.json (tools/synthesize_heroes.py), the artifact registry, HangarKit
## relationships: the placement-side sibling of [[lineage_vitrine]] — the vitrine shows what a subject might have been, this stand shows what the measurements say it should be; verdicts share the critic's focus metric so every plaque number is commensurable with the bite reports
## truth: a default is merely the branch that got walked. The hero is the branch the numbers argue for; the series is the family refusing to pick
##
## BORN DIFFERENT, the lineage_vitrine lesson: every axis value is set BEFORE add_child so
## _ready() builds that variant. A sibling edited afterwards is the default in a costume.

const ArtifactIdentity := preload("res://commons/grid/artifact_identity.gd")
const HangarKit := preload("res://commons/artifacts/_hangar/hangar_kit.gd")
const DATA_PATH := "res://commons/data/dna_synthesis.json"

## Which promoted family to synthesize. Free-form token — the verdict file is the allow-list.
@export var subject: String = "godel_statement_plaque"
## auto reads the measured verdict; hero/series force a form (a series of a hero-verdict
## subject shows its top evidence variants; a hero of a series-verdict subject pins the
## far end of the ladder).
@export_enum("auto", "hero", "series") var mode: String = "auto"
## Extra clear space between series instances, metres.
@export var spacing_margin: float = 0.45

var _verdict: Dictionary = {}


func _ready() -> void:
	_read_meta()
	_build()


func apply_grid_config(config_data: Dictionary) -> void:
	if not (config_data.has("subject") or config_data.has("mode")):
		return
	if config_data.has("subject"):
		subject = str(config_data["subject"]).strip_edges()
	if config_data.has("mode"):
		var m: String = str(config_data["mode"]).strip_edges().to_lower()
		if m in ["auto", "hero", "series"]:
			mode = m
	for c in get_children():
		c.queue_free()
	_build()


func _read_meta() -> void:
	if has_meta("config_subject"):
		subject = str(get_meta("config_subject")).strip_edges()
	if has_meta("config_mode"):
		var m: String = str(get_meta("config_mode")).strip_edges().to_lower()
		if m in ["auto", "hero", "series"]:
			mode = m


func _build() -> void:
	var verdicts: Dictionary = _load_verdicts()
	_verdict = verdicts.get(subject, {})
	if _verdict.is_empty():
		_plaque_line("NO VERDICT FOR " + subject.to_upper(), Vector3(0, 0.9, 0), 0.9, true)
		push_warning("synthesis_stand: no verdict for '%s' in %s" % [subject, DATA_PATH])
		return
	var entry: Dictionary = ArtifactIdentity.registry_entry(subject)
	var scene_path: String = str(entry.get("scene", ""))
	if scene_path == "" or not ResourceLoader.exists(scene_path):
		_plaque_line("NO SCENE FOR " + subject.to_upper(), Vector3(0, 0.9, 0), 0.9, true)
		return
	var packed: PackedScene = load(scene_path)
	if packed == null:
		return

	var form: String = mode
	if form == "auto":
		form = str(_verdict.get("verdict", "hero"))
		if form == "default" or form == "unmeasured":
			form = "hero"          # hero of a default-verdict subject = the default, stated

	if form == "series":
		_build_series(packed, entry)
	else:
		_build_hero(packed, entry)


func _load_verdicts() -> Dictionary:
	if not FileAccess.file_exists(DATA_PATH):
		return {}
	var f := FileAccess.open(DATA_PATH, FileAccess.READ)
	if f == null:
		return {}
	var j := JSON.new()
	if j.parse(f.get_as_text()) != OK or not (j.data is Dictionary):
		return {}
	var v: Variant = (j.data as Dictionary).get("verdicts", {})
	return v if v is Dictionary else {}


# ── hero: one pinned variant on a low slab, with the choice stated ───────────

func _build_hero(packed: PackedScene, entry: Dictionary) -> void:
	var values: Dictionary = _verdict.get("hero", {})
	if values.is_empty() and _verdict.get("verdict") == "series":
		# Forced hero of a series subject: pin the far end of the measured ladder.
		var order: Array = _verdict.get("order", [])
		if order.size() > 0:
			values = {str(_verdict.get("axis", "")): str(order[order.size() - 1])}
	var inst: Node = _born(packed, values)
	var ext: Vector3 = _extent(entry)
	# The slab sits UNDER the subject and never competes with it: 6 cm tall, terminal
	# finish, sized to the footprint plus a hand's width.
	var slab_w: float = maxf(ext.x, ext.z) + 0.5
	add_child(HangarKit.box(Vector3(0, 0.03, 0), Vector3(slab_w, 0.06, slab_w),
		HangarKit.finish_body("terminal", Color(0.16, 0.165, 0.18), 0.2)))
	inst.position = Vector3(0, 0.06, 0)
	add_child(inst)
	var line: String = subject
	if not values.is_empty():
		var parts: PackedStringArray = []
		for k in values:
			parts.append("%s=%s" % [k, values[k]])
		line += "  " + "  ".join(parts)
	var score: float = float(_verdict.get("score", 0.0))
	if score > 0.0:
		line += "   %.0f%%" % (score * 100.0)
	elif _verdict.get("verdict") == "default":
		line += "   THE SHIPPED FORM STANDS"
	_plaque_line(line, Vector3(0, 0.02, slab_w * 0.5 + 0.16), slab_w, false)


# ── series: the family on one rail, default first, then measured ascent ──────

func _build_series(packed: PackedScene, entry: Dictionary) -> void:
	var axis: String = str(_verdict.get("axis", ""))
	var order: Array = _verdict.get("order", [])
	if axis == "" or order.is_empty():
		_build_hero(packed, entry)
		return
	var ext: Vector3 = _extent(entry)
	var step: float = maxf(ext.x, ext.z) + spacing_margin
	var span: float = step * float(order.size() - 1)
	# The rail: one continuous bar the family stands on, so the eye reads a sequence
	# rather than a scatter. It also carries the ordering claim on its plaque.
	add_child(HangarKit.box(Vector3(0, 0.025, 0), Vector3(span + step * 0.8, 0.05, maxf(ext.z, 0.6) + 0.4),
		HangarKit.finish_body("terminal", Color(0.16, 0.165, 0.18), 0.2)))
	for i in range(order.size()):
		var val: String = str(order[i])
		var inst: Node = _born(packed, {axis: val})
		inst.position = Vector3(-span * 0.5 + step * float(i), 0.05, 0)
		add_child(inst)
		var tag: String = val
		if i == 0:
			tag += "  (shipped)"
		_plaque_line(tag, Vector3(-span * 0.5 + step * float(i), 0.01,
			maxf(ext.z, 0.6) * 0.5 + 0.32), step * 0.9, i == 0)
	_plaque_line("%s . %s . ordered by measured departure" % [subject, axis],
		Vector3(0, 0.01, -(maxf(ext.z, 0.6) * 0.5 + 0.34)), span + step * 0.6, false)


# ── shared ───────────────────────────────────────────────────────────────────

## Instantiate the subject WITH its values already set — before add_child, so _ready()
## builds that member. The value lands on whichever descendant actually owns the property
## (breadth-first, the sweep's own rule), and the identity stamp makes one-scene-many-names
## subjects build the right body.
func _born(packed: PackedScene, values: Dictionary) -> Node:
	var inst: Node = packed.instantiate()
	ArtifactIdentity.stamp(inst, subject, ArtifactIdentity.registry_entry(subject))
	for k in values:
		var holder: Node = _holder_of(inst, str(k))
		if holder == null:
			push_warning("synthesis_stand: %s has no property '%s'" % [subject, str(k)])
			continue
		var cur: Variant = holder.get(str(k))
		var v: Variant = values[k]
		match typeof(cur):
			TYPE_INT:
				v = int(str(v))
			TYPE_FLOAT:
				v = float(str(v))
			TYPE_BOOL:
				v = str(v).to_lower() == "true"
			_:
				v = str(v)
		holder.set(str(k), v)
	return inst


func _holder_of(node: Node, key: String) -> Node:
	var queue: Array = [node]
	while not queue.is_empty():
		var n: Node = queue.pop_front()
		if key in n:
			return n
		for c in n.get_children():
			queue.append(c)
	return null


func _extent(entry: Dictionary) -> Vector3:
	var m: Variant = entry.get("measurements", {})
	if m is Dictionary and (m as Dictionary).has("aabb_size"):
		var s: Variant = (m as Dictionary)["aabb_size"]
		if s is Array and (s as Array).size() == 3:
			var v := Vector3(float(s[0]), float(s[1]), float(s[2]))
			if v.length() > 0.05:
				return v
	return Vector3(1.2, 1.0, 1.2)


func _plaque_line(text: String, pos: Vector3, max_w: float, bright: bool) -> void:
	var q: MeshInstance3D = HangarKit.stencil(text,
		Vector2(clampf(max_w, 0.4, 2.6), 0.055),
		Color(0.92, 0.86, 0.55) if bright else Color(0.62, 0.66, 0.62))
	if q:
		q.position = pos
		q.rotation_degrees.x = -90.0
		add_child(q)
