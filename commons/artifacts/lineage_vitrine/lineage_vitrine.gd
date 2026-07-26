extends Node3D

## Lineage Vitrine — an object shown beside the siblings it did not become.
##
## @identity
## essence: one template, N values on one axis -> N siblings; exactly one is realised and the rest are ghosts
## desire: to see that the object in front of you is not a thing but a POSITION IN A FAMILY, and that the position can move
## critical_parameter: axis_index — which sibling is currently real. Nothing about the family changes when it moves; only which member got to be solid.
## triggers: step the axis and the solidity travels down the rank — the realised one takes its true materials, the one it replaced goes pale
## emerges: the default stops looking inevitable. The shipped artifact is just the branch that happened to get walked, and its unrealised kin are standing right there.
## needs: a subject artifact with a declared dna.axes block in the registry [has]; VR step buttons [has]
## relationships: the first artifact whose subject is the DNA SYSTEM ITSELF — it reads what request_note and its kin were promoted into. Kin to bias_visualizer (taxonomy vitrine) in body, opposite in content: that one shows a space of words, this one shows a space of versions.
## truth: a prefab object cannot remember, but it can descend. Its history is not biography, it is lineage — and a form with a lineage is no longer an ideal, it is a family with no privileged member.
##
## Bachelard's drawer holds YOUR history; a prefab object placed 716 times holds
## none. So the poetics moves from memory to descent: not "what happened in this
## object" but "what this object came from and what it might have been instead."
## The vitrine makes the second question physical. The realised sibling is solid; the
## rest are pale, present, and one button away from being the real one.

const HangarKit = preload("res://commons/artifacts/_hangar/hangar_kit.gd")
const REGISTRY_DIR := "res://commons/artifacts/registry/"

## Which artifact's lineage is on display. Needs a `dna.axes` block in its registry
## entry — the thing stage-2 promotion produces.
@export var subject: String = "request_note"
## Which declared axis to rank along. Empty = the first one declared.
@export var axis: String = ""
## Which sibling is currently REAL. The whole point of the artifact is that this
## moves, and that nothing else changes when it does.
@export var axis_index: int = 0
## Max siblings to instantiate — a rank of five reads; a rank of twelve is a shelf.
@export var max_siblings: int = 5
## Spacing between siblings, metres.
@export var spacing: float = 0.62
@export var deck_height: float = 0.92
@export var finish: String = "terminal"
@export var wear: float = 0.10
@export var unit_code: String = "LV-01"

var _values: Array = []
var _axis_name: String = ""
var _instances: Array[Node3D] = []
var _original_overrides: Array[Dictionary] = []
var _cab: Node3D
var _marker: MeshInstance3D
var _readout: Label3D


func _ready() -> void:
	_resolve_axis()
	_build_case()
	_build_rank()
	_apply_realisation()


# ── the family, read from the registry ───────────────────────────────────────

func _resolve_axis() -> void:
	var entry: Dictionary = _registry_entry(subject)
	var dna: Dictionary = entry.get("dna", {}) if entry else {}
	var axes: Dictionary = dna.get("axes", {}) if dna else {}
	if axes.is_empty():
		# No declared lineage: the subject has not been promoted. Say so rather than
		# inventing a family, because a fabricated lineage is exactly the lie this
		# artifact exists to expose.
		_axis_name = "unpromoted"
		_values = []
		return
	var pick: String = axis
	if pick == "" or not axes.has(pick):
		pick = str(axes.keys()[0])
	_axis_name = pick
	var vals: Array = axes[pick]
	_values = vals.slice(0, mini(max_siblings, vals.size()))


func _registry_entry(token: String) -> Dictionary:
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
		var data = j.data
		if typeof(data) != TYPE_DICTIONARY:
			continue
		var arts = (data as Dictionary).get("artifacts", data)
		if typeof(arts) == TYPE_DICTIONARY and (arts as Dictionary).has(token):
			return (arts as Dictionary)[token]
	return {}


func _subject_scene() -> String:
	var e: Dictionary = _registry_entry(subject)
	return str(e.get("scene", "")) if e else ""


# ── the rank ─────────────────────────────────────────────────────────────────

func _build_rank() -> void:
	var scene_path: String = _subject_scene()
	if scene_path == "" or _values.is_empty():
		return
	var ps: PackedScene = load(scene_path)
	if ps == null:
		return
	var n: int = _values.size()
	var x0: float = -spacing * float(n - 1) * 0.5
	for i in range(n):
		var inst: Node3D = ps.instantiate()
		# Set the axis param BEFORE add_child so _ready() builds that sibling — the
		# same trick the DNA sweep uses. A sibling has to be born different; it
		# cannot be edited into difference after the fact.
		inst.set(_axis_name, _values[i])
		var holder := Node3D.new()
		holder.name = "Sibling_%d" % i
		holder.position = Vector3(x0 + spacing * float(i), deck_height, 0.0)
		add_child(holder)
		holder.add_child(inst)
		_instances.append(inst)
		_original_overrides.append(_snapshot_overrides(inst))
		_value_plate(Vector3(x0 + spacing * float(i), deck_height - 0.055, 0.20), str(_values[i]))


## Remember each mesh's own material BEFORE ghosting, so realisation can restore the
## sibling's true surfaces. Clearing the override instead would strip the colours our
## artifacts set in code and every sibling would come back grey.
func _snapshot_overrides(root: Node) -> Dictionary:
	var out: Dictionary = {}
	_walk_meshes(root, out)
	return out


func _walk_meshes(n: Node, out: Dictionary) -> void:
	if n is MeshInstance3D:
		out[n] = (n as MeshInstance3D).material_override
	for c in n.get_children():
		_walk_meshes(c, out)


func _ghost_material() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.72, 0.74, 0.80, 0.16)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


## THE ONLY THING THAT MOVES. Solidity travels along the rank; the family is
## unchanged. What was real goes pale, what was pale takes its own materials back.
func _apply_realisation() -> void:
	if _instances.is_empty():
		return
	axis_index = clampi(axis_index, 0, _instances.size() - 1)
	var ghost: StandardMaterial3D = _ghost_material()
	for i in range(_instances.size()):
		var real: bool = (i == axis_index)
		var saved: Dictionary = _original_overrides[i]
		for mesh in saved.keys():
			var mi: MeshInstance3D = mesh
			if not is_instance_valid(mi):
				continue
			mi.material_override = saved[mesh] if real else ghost
	if _marker:
		var n: int = _instances.size()
		var x0: float = -spacing * float(n - 1) * 0.5
		_marker.position.x = x0 + spacing * float(axis_index)
	if _readout:
		_readout.text = "%s = %s" % [_axis_name, str(_values[axis_index])]


func step(delta_i: int) -> void:
	if _instances.is_empty():
		return
	axis_index = wrapi(axis_index + delta_i, 0, _instances.size())
	_apply_realisation()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_BRACKETLEFT:
			step(-1)
		elif event.keycode == KEY_BRACKETRIGHT:
			step(1)


# ── the case ─────────────────────────────────────────────────────────────────

func _build_case() -> void:
	var pal: Dictionary = HangarKit.finish_palette(finish)
	var col_body: Color = pal["body"]
	var col_accent: Color = pal["accent"]
	var shell: StandardMaterial3D = HangarKit.finish_body(finish, col_body, wear)
	var steel: StandardMaterial3D = HangarKit.worn_metal(col_body.lightened(0.10))
	var dark: StandardMaterial3D = HangarKit.painted_metal(Color(0.07, 0.075, 0.09), wear, 0.35, 0.55)
	var accent: StandardMaterial3D = HangarKit.emissive(col_accent, 2.2)

	var n: int = maxi(_values.size(), 1)
	var w: float = spacing * float(n) + 0.28
	var d: float = 0.52

	var cab := Node3D.new()
	cab.name = "Cabinet"
	cab.set_meta("housing", true)
	add_child(cab)
	_cab = cab

	# deck the rank stands on, on a plinth that reaches the floor
	cab.add_child(HangarKit.box(Vector3(0, deck_height - 0.03, 0), Vector3(w, 0.06, d), shell))
	var p: Node3D = HangarKit.plinth(w - 0.10, d - 0.06, deck_height - 0.06, finish, wear, col_accent, unit_code)
	if p:
		p.position.y = deck_height - 0.06
		cab.add_child(p)
	# ember line along the deck's near lip
	cab.add_child(HangarKit.box(Vector3(0, deck_height - 0.004, d * 0.5 - 0.012),
		Vector3(w * 0.97, 0.006, 0.006), accent))

	# THE AXIS RAIL — the one thing you can touch. A machined groove with a detent
	# under each sibling, so the family reads as positions on a single measure.
	cab.add_child(HangarKit.box(Vector3(0, deck_height + 0.004, d * 0.5 - 0.075),
		Vector3(w * 0.86, 0.010, 0.030), dark))
	var x0: float = -spacing * float(n - 1) * 0.5
	for i in range(n):
		cab.add_child(HangarKit.box(
			Vector3(x0 + spacing * float(i), deck_height + 0.010, d * 0.5 - 0.075),
			Vector3(0.014, 0.012, 0.040), steel))
	_marker = HangarKit.box(Vector3(x0, deck_height + 0.016, d * 0.5 - 0.075),
		Vector3(0.030, 0.014, 0.052), accent)
	_marker.name = "RealisationMarker"
	cab.add_child(_marker)

	# sign band: whose lineage this is
	var sign: MeshInstance3D = HangarKit.stencil(
		"LINEAGE · " + subject.to_upper(), Vector2(minf(w * 0.62, 0.72), 0.030),
		col_accent.lightened(0.35))
	if sign:
		sign.position = Vector3(0, deck_height - 0.075, d * 0.5 + 0.004)
		cab.add_child(sign)

	_readout = Label3D.new()
	_readout.name = "AxisReadout"
	_readout.font_size = 28
	_readout.pixel_size = 0.001
	_readout.modulate = pal["text"]
	_readout.text = "%s = ?" % _axis_name
	_readout.position = Vector3(0, deck_height - 0.135, d * 0.5 + 0.012)
	cab.add_child(_readout)

	if _values.is_empty():
		var warn := Label3D.new()
		warn.font_size = 24
		warn.pixel_size = 0.001
		warn.modulate = Color(0.92, 0.62, 0.12)
		warn.text = "%s has no declared DNA —\nnothing to descend from" % subject
		warn.position = Vector3(0, deck_height + 0.30, 0)
		cab.add_child(warn)


## A small plate under each sibling carrying the value that made it that sibling.
func _value_plate(pos: Vector3, label: String) -> void:
	var l := Label3D.new()
	l.font_size = 22
	l.pixel_size = 0.001
	l.modulate = Color(0.82, 0.83, 0.86)
	l.text = label
	l.position = pos
	add_child(l)


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("subject"):
		subject = str(config_data["subject"])
	if config_data.has("axis"):
		axis = str(config_data["axis"])
	if config_data.has("axis_index"):
		axis_index = int(config_data["axis_index"])
	if config_data.has("spacing"):
		spacing = float(config_data["spacing"])
