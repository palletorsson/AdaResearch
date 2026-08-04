# CSG Difference Demo — A − B
#
# A solid box with a sphere subtracted from it. The sphere is invisible; only its
# *negative space* survives in the resulting solid. The box has a bite taken out.
#
# This is the operator that makes architecture: every cavity, every door, every
# window is a Boolean difference of a wall minus an opening.
#
# @identity
# essence: A − B — the difference operator. A solid box minus an invisible sphere; only the sphere's negative space survives, biting a cavity into the box.
# desire: To reveal that absence is constructive. The hole is not missing material — it is the operator's product.
# critical_parameter: sphere_offset — where the bite lands. Center = a clean internal void; edge = an open notch that breaks the silhouette.
# triggers: Automatic — builds on _ready() and rotates so the cavity reads as a deliberate carved form.
# emerges: The architectural intuition that every door, window, and room is a wall minus an opening.
# needs: Procedural CSG [has]. Missing: an order-sensitivity demo (A−B vs B−A) showing difference is non-commutative.
# relationships: The subtractive operator — the only non-commutative one of the three. Foundation for csg_architecture_cavity, which subtracts three openings from a wall. Grouped at csg_compose_workbench.
# truth: To make a room, subtract a void from a solid. Architecture is difference.
# @qfep_term: F.

extends Node3D
class_name CSGDifferenceDemo

# --- DNA (stage 2, promoted 2026-08-03) -------------------------------------
# THE PROBLEM, and why it is not the same problem as fontana_puncture's. Both are
# a cube minus a sphere. fontana_puncture is that operation performed as ART, and
# its promotion asked how far the void had eaten (breach) and where it struck
# (strike). This one is the same operation performed as a DEMONSTRATION — it
# carries a Label3D reading "A − B" and its own @identity ends by naming what it
# is missing: "an order-sensitivity demo (A−B vs B−A)". A demonstration's first
# question is therefore not how deep the cut is. It is how much of the operation
# it is willing to show. 27 placements, every one of them showing only the answer.
#
# workings — HOW MUCH OF THE OPERATION IS DRAWN. The word, the four values and
#   their order are taken CHARACTER FOR CHARACTER from geometric_transformations,
#   bounce_well, transform_composition_workbench and the vector_op console, so a
#   room cannot show a composed transform as a bare answer while showing a Boolean
#   as a full derivation. What the four mean for a Boolean:
#     outcome     SHIPPED. Only A − B. The sphere was never visible and the box it
#                 came out of is gone; you are handed the result and nothing else.
#     trace       the removed material — A ∩ B — put back as a translucent ghost
#                 exactly where it was taken from. The bite made visible AS a
#                 solid, which is the claim "absence is constructive" rendered.
#     operands    A and B themselves, faint and in place: the uncut box and the
#                 subtracting sphere around the surviving matter.
#     expression  the operands plus the operation written out — a rod from the
#                 box centre to the sphere centre (sphere_offset made a drawn
#                 thing, not a number) and both terms labelled.
#
# strike — WHERE THE VOID STRUCK. Reused from fontana_puncture: same word, same
#   four values, same question, and this artifact's own declared critical_parameter
#   ("sphere_offset — where the bite lands"). WHAT DIFFERS, said plainly: the
#   numbers are not fontana's and cannot be. Its sphere is 1.36 half-extents; this
#   one's is 1.10, so the same fraction cuts a different topology, and its "corner"
#   is a body diagonal while the value shipped here is an XZ diagonal sitting low
#   (0.3, 0.1, 0.3). The two artifacts agree on the word and the value list, and
#   each resolves it against its own geometry — which is what makes them comparable
#   rather than merely identical.
#     corner   SHIPPED, and a short-circuit: returns sphere_offset untouched.
#     centred  radius 0.55 against a half-extent of 0.5, so the void breaches all
#              six faces at once and the box survives as a frame — the "clean
#              internal void" its critical_parameter promises, at this radius.
#     raised   0.30 up: the top eaten and the cut still meeting the sides.
#     grazing  0.48 up, the sphere centre on the top face — the notch that breaks
#              the silhouette rather than a cavity inside it.
#
# WHAT IS DECLINED. breach — fontana's amount axis — is NOT promoted here. This
# artifact's radius is fixed at 0.55 against a 1.0 box and its own critical
# parameter is the offset, not the radius; a second amount axis would say the same
# thing twice across the family and add nothing a demo argues. The non-commutative
# B − A that the @identity asks for is a genuine third axis and belongs with a
# second object beside this one, not as a value of workings: B − A is not a
# different amount of showing, it is a different demonstration.
const WORKINGS: PackedStringArray = ["outcome", "trace", "operands", "expression"]
const STRIKES: PackedStringArray = ["centred", "raised", "corner", "grazing"]

@export_category("Difference Settings")
@export_enum("outcome", "trace", "operands", "expression") var workings: String = "outcome"
@export_enum("centred", "raised", "corner", "grazing") var strike: String = "corner"
@export var body_color: Color = Color(0.7, 0.6, 0.95, 1.0)
@export var box_size: Vector3 = Vector3(1.0, 1.0, 1.0)
@export var sphere_radius: float = 0.55
## The shipped bite. A placement that names this directly still WINS over strike —
## the named axis is a vocabulary laid over the raw vector, never a replacement.
@export var sphere_offset: Vector3 = Vector3(0.3, 0.1, 0.3)
@export var rotation_speed: float = 0.35

## Colour of the ghosted operands and of the removed material.
const CUT_COLOR: Color = Color(1.0, 0.55, 0.35)
## Height the whole rig has always stood at. Was a literal on _root_csg.position.
const RIG_Y: float = 0.7

var _rig: Node3D = null
var _root_csg: CSGCombiner3D
var _t: float = 0.0
var _built: bool = false
var _offset_explicit: bool = false


func _ready() -> void:
	_read_metadata_overrides()
	_build()


## Guarded. The old body assigned body_color and did nothing else — a knob with no
## rebuild behind it, which worked only because config always arrives before
## _ready. It now rebuilds when, and only when, a value the build reads actually
## changed. All 27 placements pass no keys at all, so none of them is touched.
func apply_grid_config(config_data: Dictionary) -> void:
	var before: String = _config_signature()
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()
	if not _built:
		return
	if _config_signature() == before:
		return
	for c in get_children():
		c.queue_free()
	_built = false
	_rig = null
	_root_csg = null
	_build()


func _config_signature() -> String:
	return "%s|%s|%.4f|%s|%s|%s" % [
		workings, strike, sphere_radius, str(box_size),
		str(_cut_offset()), str(body_color)]


func _read_metadata_overrides() -> void:
	if has_meta("config_workings"):
		var w: String = str(get_meta("config_workings")).strip_edges().to_lower()
		if WORKINGS.has(w):
			workings = w
	if has_meta("config_strike"):
		var s: String = str(get_meta("config_strike")).strip_edges().to_lower()
		if STRIKES.has(s):
			strike = s
	if has_meta("config_sphere_radius"):
		sphere_radius = float(str(get_meta("config_sphere_radius")))
	if has_meta("config_rotation_speed"):
		rotation_speed = float(str(get_meta("config_rotation_speed")))
	if has_meta("config_sphere_offset"):
		var o = get_meta("config_sphere_offset")
		if o is Vector3:
			sphere_offset = o
		else:
			var parts: PackedStringArray = str(o).split(",")
			if parts.size() >= 3:
				sphere_offset = Vector3(float(parts[0]), float(parts[1]), float(parts[2]))
		_offset_explicit = true
	if has_meta("config_body_color"):
		var c = get_meta("config_body_color")
		if c is Color:
			body_color = c
		else:
			body_color = _parse_color(str(c), body_color)


func _parse_color(raw: String, fallback: Color) -> Color:
	var parts: PackedStringArray = raw.split(",")
	if parts.size() >= 3:
		var a: float = 1.0
		if parts.size() > 3:
			a = float(parts[3])
		return Color(float(parts[0]), float(parts[1]), float(parts[2]), a)
	return fallback


func _process(delta: float) -> void:
	_t += delta * rotation_speed
	if is_instance_valid(_rig):
		_rig.rotation.y = _t


# ── The cut ───────────────────────────────────────────────────────────

## strike resolved to the vector the CSG has always used. "corner" returns
## sphere_offset UNTOUCHED rather than recomputing a fraction of box_size: at the
## shipped box_size of 1.0 the two are bit-identical anyway, but a placement that
## overrode box_size alone would silently have its bite rescaled by the ratio
## path, and the guarantee should not depend on nobody doing that.
func _cut_offset() -> Vector3:
	if _offset_explicit or strike == "corner" or not STRIKES.has(strike):
		return sphere_offset
	return _strike_fraction(strike) * box_size


## Fractions of box_size, so the wound tracks the box it is in.
func _strike_fraction(which: String) -> Vector3:
	match which:
		"raised":
			return Vector3(0.0, 0.30, 0.0)
		"grazing":
			return Vector3(0.0, 0.48, 0.0)
		_:
			return Vector3.ZERO


# ── Build ─────────────────────────────────────────────────────────────

func _build() -> void:
	_built = true
	# The rig exists so the ghosts can rotate WITH the result. A CSGCombiner3D
	# nested inside another combiner is not a container, it is a shape: parenting
	# the ghosts to _root_csg would union them back into the very solid they are
	# meant to comment on. The rig is a plain Node3D, and because the old rotation
	# axis passed through a purely-vertical offset, rotating it is the same world
	# transform the old _root_csg.rotation.y produced.
	_rig = Node3D.new()
	_rig.name = "Rig"
	add_child(_rig)

	_build_difference()
	if workings == "trace":
		_build_removed()
	elif workings == "operands" or workings == "expression":
		_build_operands()
	if workings == "expression":
		_build_expression()
	_build_label()


func _build_difference() -> void:
	_root_csg = CSGCombiner3D.new()
	_root_csg.name = "DifferenceRoot"
	_root_csg.position.y = RIG_Y
	var csg_box := CSGBox3D.new()
	csg_box.size = box_size
	csg_box.operation = CSGShape3D.OPERATION_UNION
	_root_csg.add_child(csg_box)
	var csg_sphere := CSGSphere3D.new()
	csg_sphere.radius = sphere_radius
	csg_sphere.position = _cut_offset()
	csg_sphere.operation = CSGShape3D.OPERATION_SUBTRACTION
	_root_csg.add_child(csg_sphere)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = body_color
	mat.metallic = 0.3
	mat.roughness = 0.5
	mat.emission_enabled = true
	mat.emission = body_color
	mat.emission_energy_multiplier = 0.3
	_root_csg.material_override = mat
	_rig.add_child(_root_csg)


## workings = trace. The removed material itself: A ∩ B, the exact solid the
## difference threw away, put back as a ghost in the cavity it left.
func _build_removed() -> void:
	var comb := CSGCombiner3D.new()
	comb.name = "RemovedTrace"
	comb.position.y = RIG_Y
	var box := CSGBox3D.new()
	box.size = box_size
	box.operation = CSGShape3D.OPERATION_UNION
	comb.add_child(box)
	var sph := CSGSphere3D.new()
	sph.radius = sphere_radius
	sph.radial_segments = 24
	sph.rings = 12
	sph.position = _cut_offset()
	sph.operation = CSGShape3D.OPERATION_INTERSECTION
	comb.add_child(sph)
	comb.material_override = _ghost_material(CUT_COLOR, 0.42)
	_rig.add_child(comb)


## workings = operands. A and B, faint and in place, around what survived.
func _build_operands() -> void:
	var a := MeshInstance3D.new()
	a.name = "OperandA"
	var bm := BoxMesh.new()
	bm.size = box_size
	a.mesh = bm
	a.material_override = _ghost_material(body_color, 0.16)
	a.position = Vector3(0.0, RIG_Y, 0.0)
	_rig.add_child(a)

	var b := MeshInstance3D.new()
	b.name = "OperandB"
	var sm := SphereMesh.new()
	sm.radius = sphere_radius
	sm.height = sphere_radius * 2.0
	sm.radial_segments = 24
	sm.rings = 12
	b.mesh = sm
	b.material_override = _ghost_material(CUT_COLOR, 0.22)
	b.position = Vector3(0.0, RIG_Y, 0.0) + _cut_offset()
	_rig.add_child(b)


## workings = expression. The operation written out: the offset drawn as a rod
## between the two centres, and both terms named.
func _build_expression() -> void:
	var d: Vector3 = _cut_offset()
	if d.length() > 0.001:
		var rod := MeshInstance3D.new()
		rod.name = "OffsetRod"
		var cm := CylinderMesh.new()
		cm.top_radius = 0.014
		cm.bottom_radius = 0.014
		cm.height = d.length()
		cm.radial_segments = 10
		rod.mesh = cm
		rod.material_override = _ghost_material(Color(1.0, 0.95, 0.65), 0.9)
		rod.position = Vector3(0.0, RIG_Y, 0.0) + d * 0.5
		_rig.add_child(rod)
		# CylinderMesh runs along +Y. Aim it down the offset; when the offset IS
		# vertical (raised, grazing) the cross product vanishes and it is already
		# pointing the right way.
		var up: Vector3 = Vector3(0.0, 1.0, 0.0)
		var dir: Vector3 = d.normalized()
		var axis: Vector3 = up.cross(dir)
		if axis.length() > 0.0001:
			rod.rotate(axis.normalized(), up.angle_to(dir))

	_term_label("A", Vector3(-box_size.x * 0.78, RIG_Y + box_size.y * 0.62, 0.0), body_color)
	_term_label("B", Vector3(0.0, RIG_Y, 0.0) + d + Vector3(0.0, sphere_radius * 0.95, 0.0),
		CUT_COLOR)


func _term_label(txt: String, pos: Vector3, col: Color) -> void:
	var lab := Label3D.new()
	lab.text = txt
	lab.font_size = 30
	lab.outline_size = 6
	lab.modulate = col
	lab.position = pos
	lab.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_rig.add_child(lab)


func _ghost_material(col: Color, alpha: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(col.r, col.g, col.b, alpha)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.emission_enabled = true
	m.emission = col
	m.emission_energy_multiplier = 0.35
	return m


func _build_label() -> void:
	var label := Label3D.new()
	label.text = "A − B"
	label.font_size = 48
	label.outline_size = 8
	label.modulate = body_color
	label.position = Vector3(0, 1.7, 0.5)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)
