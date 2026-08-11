# CSG Union Demo — A ∪ B
#
# Two intersecting Godot CSG primitives (a box and a sphere) rendered with the union
# operation. Where they overlap, no seam — the union creates a single composite solid.
# A slow rotation orbits the camera so the player sees how the union flows around both.
#
# @identity
# essence: A ∪ B — the union operator. Two CSG primitives (box + sphere) fused into one seamless solid; where they overlap, no seam survives.
# desire: To show that joining is not stacking. The union is a single skin around two volumes, not two objects merely touching.
# critical_parameter: sphere_offset — how far the sphere sits from the box. Far apart = barely fused; overlapping = one blob. The overlap is where union does its work, and it is reachable from a map as `fusion`.
# triggers: Automatic — builds on _ready(), then slowly rotates so the player reads the fused surface from every angle.
# emerges: The intuition that "or" has a shape. Anything in A OR B belongs to the result.
# needs: Procedural CSG [has]. Missing: a before/after toggle that separates the two inputs back out — `fusion = distinct` is now that toggle.
# relationships: The most permissive of the three operators. Contrasts with csg_intersection_demo (strictest) and csg_difference_demo (subtractive). Introduced together at csg_compose_workbench.
# truth: Union is the generous operator. It keeps everything either shape claims.
# @qfep_term: F (pure composition, no entropy).

extends Node3D
class_name CSGUnionDemo

# --- DNA (stage 2, promoted 2026-08-11) -------------------------------------
# THE PROBLEM. This artifact's own @identity states an AMOUNT and then makes it
# unreachable: "sphere_offset — far apart = barely fused; overlapping = one blob",
# and under it a single Vector3 export that no map token has ever set. Eleven
# placements, every one of them the same blob. Its own `needs` line names what is
# missing — "a before/after toggle that separates the two inputs back out" — and
# that toggle is not a new object, it is the far end of the amount the artifact
# already declares.
#
# fusion — HOW MANY BODIES THE RESULT READS AS. The word, the four values and
#   their order are taken CHARACTER FOR CHARACTER from implicit_surface_modeling,
#   metaballs and raymarched_metaballs, which hold it for a smoothed implicit
#   field. It transplants because fusion's values name STATES OF THE RESULT — how
#   many bodies you see — and not settings of a knob, which is why it survives
#   crossing from a smoothing parameter to a rigid offset.
#
#   Resolved here as scalar multiples k of the SHIPPED sphere_offset (0.4, 0.25,
#   0.0), |d| = 0.4717, so the direction never changes and the axis is pure
#   magnitude. Against box_size 0.7 (half-extent 0.35) and sphere_radius 0.5:
#     distinct  k = 2.3 — centre (0.92, 0.575, 0). The nearest point of the box is
#               (0.35, 0.35, 0) at distance 0.613, against a radius of 0.5: a
#               0.113 gap. TWO DISJOINT SOLIDS, still under OPERATION_UNION. This
#               is the before/after separation the @identity asks for, and it
#               argues the uncomfortable thing — a lawful union that looks like a
#               pile.
#     necked    k = 1.85 — centre (0.74, 0.4625, 0), nearest box point at 0.406,
#               so 0.094 of penetration across the box's +X/+Y edge. Connected
#               through a narrow waist.
#     lobed     SHIPPED, k = 1.0, and a SHORT-CIRCUIT: _fusion_offset() returns
#               sphere_offset untouched, not 1.0 * sphere_offset. Two readable
#               lobes under one skin.
#     single    k = 0 — concentric. Radius 0.5 against a half-extent of 0.35 and a
#               corner distance of 0.606, so the box vanishes inside the sphere
#               except for eight corner spikes. The union reads as one primitive
#               with defects.
#
#   WHAT DIFFERS FROM THE METABALL SIBLINGS, said plainly. There, smin(a, b, k)
#   "only acts where |a − b| < k", so `necked` is a smooth bridge produced by a
#   blend and the ladder is a continuum. CSG union has no k: it fuses absolutely
#   at first contact, so here `necked` is a CREASE with a discontinuous normal and
#   the ladder is a sequence of topological events. Same four states, two
#   ontologies of joining. And the shipped rung is not the same rung — over there
#   it is `distinct` and the ladder runs upward only; here it is `lobed` and the
#   ladder runs both ways from it, which is why the registry's derived value list
#   is default-first and therefore in a different ORDER from theirs. The word and
#   the four values are identical; the reading order records where each artifact
#   already stood.
#
# join — HOW MUCH OF THE JOIN THE FUSED SKIN WILL ADMIT. The registry's own
#   sentence about this token — "the gentlest Boolean, and the one that hides the
#   most... the seam between them dissolved into a single skin" — turned into a
#   knob. A ladder of disclosure depth, and three of its four rungs change nothing
#   but the skin.
#     flush     SHIPPED. One material_override on the root, one skin, nothing says
#               where A ends. Builds nothing beyond what always shipped.
#     seam      the intersection curve marked as a bright tube, built as
#               (sphere shell r ± 0.015) INTERSECT (box shell size ± 0.015), each
#               shell an outer primitive minus an inner one. Exact for any offset
#               and radius, no curve maths. Deliberately 0.015 proud of both
#               surfaces so the marker never lands coplanar with the skin it marks
#               — this sequence's own coincident_face is what happens when it does.
#               NOTE: at `distinct` the two shells do not meet, so there is no
#               tube; at `single` the marker survives only near the eight corners.
#               Both are truthful — there is no seam where nothing joined.
#     tinted    no root override. Per-primitive materials, so A's share of the skin
#               stays exactly body_color and B's share takes CUT_COLOR: the
#               provenance of every square centimetre of one continuous surface.
#     shared    A INTERSECT B ghosted inside the fused solid — the volume both
#               shapes claim and union counts once, which is
#               |A ∪ B| = |A| + |B| − |A ∩ B| rendered rather than asserted.
#
# WHAT IS DECLINED. strike (centred | raised | corner | grazing) — the family's
# most-shared word, carried character for character by fontana_puncture,
# csg_difference_demo and csg_compose_workbench, driven by the very export this
# artifact declares as its critical_parameter — is REFUSED, and the refusal is the
# finding. strike's four values are PLACES and its question is where the void
# struck. A union has no void; nothing strikes anything; and this artifact's
# @identity frames sphere_offset as a magnitude ("far apart / overlapping"), not a
# location. Taking the word would put four location names where four amounts
# belong, which is the exact fault exhibit_vitrine renamed regard→guard to fix —
# and these five CSG tokens literally stand in one room, all placed by the single
# curation_station in Curation_Bay_boolean_surfaces_0. subtraction_suite already
# set the precedent for refusing strike on argument. Declining leaves the family
# clean: strike = direction, for artifacts that place a void; fusion / breach /
# consensus = amount, for artifacts whose question is how much. Also refused: an
# axis over sphere_radius. It is a size, a size is legible as a number, and
# fontana_puncture's breach already owns amount-of-radius for a cube and a sphere.
#
# WHAT THE BENCH NEEDS, and it is not an axis. This artifact owns no
# MeshInstance3D, and capture_config_sweep measures MeshInstance3D — so every
# variant would be framed as a 1 m box at the origin. `capture_anchor` (default
# "off", switched on by dna.fixture and by nothing else) stands an unrendered box
# around the ladder so the camera is placed for the solid that is actually there.
# The word and the gate are csg_intersection_demo's, taken character for
# character. rotation_speed is pinned to 0.0 for the same reason the two siblings
# pin it: UnionRoot turns at 0.35 rad/s from the first frame, so an unpinned sweep
# measures yaw and calls it an axis.

const FUSIONS: PackedStringArray = ["distinct", "necked", "lobed", "single"]
const JOINS: PackedStringArray = ["flush", "seam", "tinted", "shared"]

## Scalar multiples of the SHIPPED sphere_offset — direction fixed, magnitude
## swept. "lobed" is recorded here for the ladder's sake and is never READ:
## _fusion_offset() short-circuits on it before this table is touched.
const FUSION_K := {"distinct": 2.3, "necked": 1.85, "lobed": 1.0, "single": 0.0}

@export_category("Union Settings")
@export_enum("distinct", "necked", "lobed", "single") var fusion: String = "lobed"
@export_enum("flush", "seam", "tinted", "shared") var join: String = "flush"
@export var body_color: Color = Color(0.55, 0.85, 1.0, 1.0)
@export var box_size: Vector3 = Vector3(0.7, 0.7, 0.7)
@export var sphere_radius: float = 0.5
## The shipped overlap. A placement that names this directly still WINS over
## fusion — the named axis is a vocabulary laid over the raw vector, never a
## replacement for it.
@export var sphere_offset: Vector3 = Vector3(0.4, 0.25, 0.0)
@export var rotation_speed: float = 0.35
## CAPTURE ONLY — see _build_capture_anchor(). Reachable by direct property
## assignment alone, which is what dna.fixture does before _ready. Deliberately
## NOT read by apply_grid_config, so no map token can switch it on. The word, the
## two values and the fixture key are csg_intersection_demo's, character for
## character.
@export var capture_anchor: String = "off"

## B's share of the skin under join = tinted, and the shared volume under
## join = shared. The same triple csg_difference_demo uses for the subtrahend, so
## the family says "this part came from the sphere" in one colour.
const CUT_COLOR: Color = Color(1.0, 0.55, 0.35)
## Height the solid has always stood at. Was a literal on _root_csg.position.
const RIG_Y: float = 0.7
## Half-thickness of the seam shells. The marker is 0.015 outside the skin and
## 0.015 inside it, so no face of it is ever coplanar with a face of the solid.
const SEAM_PROUD: float = 0.015

var _rig: Node3D = null
var _root_csg: CSGCombiner3D
var _t: float = 0.0
var _built: bool = false
var _offset_explicit: bool = false


func _ready() -> void:
	_read_metadata_overrides()
	_build()


## Guarded. The old body assigned body_color, box_size and sphere_radius and had
## no rebuild behind it — three knobs that could only ever take effect because
## config happens to arrive before _ready. It now rebuilds when, and only when, a
## value the build actually reads has changed.
##
## The two curation_station reach-paths (Corridor_Boolean_Union,
## Curation_Bay_boolean_surfaces_0) call this directly with {"emissive": false},
## a key no build path reads: the stamp lands in metadata, the signature comes
## back identical, and the method returns before anything is torn down.
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
	return "%s|%s|%.4f|%s|%s|%s|%s" % [
		fusion, join, sphere_radius, str(box_size),
		str(_fusion_offset()), str(body_color), capture_anchor]


func _read_metadata_overrides() -> void:
	if has_meta("config_fusion"):
		var f: String = str(get_meta("config_fusion")).strip_edges().to_lower()
		if FUSIONS.has(f):
			fusion = f
	if has_meta("config_join"):
		var j: String = str(get_meta("config_join")).strip_edges().to_lower()
		if JOINS.has(j):
			join = j
	if has_meta("config_sphere_radius"):
		sphere_radius = float(str(get_meta("config_sphere_radius")))
	if has_meta("config_rotation_speed"):
		rotation_speed = float(str(get_meta("config_rotation_speed")))
	if has_meta("config_box_size"):
		box_size = _parse_vec3(get_meta("config_box_size"), box_size)
	if has_meta("config_sphere_offset"):
		sphere_offset = _parse_vec3(get_meta("config_sphere_offset"), sphere_offset)
		_offset_explicit = true
	if has_meta("config_body_color"):
		var c = get_meta("config_body_color")
		if c is Color:
			body_color = c
		else:
			body_color = _parse_color(str(c), body_color)


func _parse_vec3(raw, fallback: Vector3) -> Vector3:
	if raw is Vector3:
		return raw as Vector3
	if raw is Array and (raw as Array).size() >= 3:
		var a: Array = raw
		return Vector3(float(a[0]), float(a[1]), float(a[2]))
	var parts: PackedStringArray = str(raw).split(",")
	if parts.size() >= 3:
		return Vector3(float(parts[0]), float(parts[1]), float(parts[2]))
	if parts.size() == 1 and str(raw).strip_edges().is_valid_float():
		return Vector3.ONE * float(str(raw))
	return fallback


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


# ── The overlap ───────────────────────────────────────────────────────────

## fusion resolved to the vector the CSG has always used. "lobed" returns
## sphere_offset UNTOUCHED — a bare return, not a multiply by 1.0 — so the shipped
## solid is not recomputed and cannot drift by a float. A placement that named
## sphere_offset itself keeps winning over the axis.
func _fusion_offset() -> Vector3:
	if _offset_explicit or fusion == "lobed" or not FUSIONS.has(fusion):
		return sphere_offset
	return float(FUSION_K.get(fusion, 1.0)) * sphere_offset


## The same resolution asked of a rung other than the current one. Used ONLY to
## size the capture anchor over the whole ladder, never by a build path.
func _offset_for(which: String) -> Vector3:
	if which == "lobed":
		return sphere_offset
	return float(FUSION_K.get(which, 1.0)) * sphere_offset


# ── Build ─────────────────────────────────────────────────────────────────

func _build() -> void:
	_built = true
	# The rig exists so the seam marker and the shared ghost rotate WITH the
	# result. A CSGCombiner3D nested inside another combiner is not a container,
	# it is a shape: parenting either of them to _root_csg would fuse them back
	# into the very solid they are meant to comment on. The rig is a plain Node3D
	# at the origin, and because the solid's own offset is purely vertical,
	# rotating the rig produces the identical world transform the old
	# _root_csg.rotation.y did — Translate(0, 0.7, 0) * Rot_y(t) either way.
	_rig = Node3D.new()
	_rig.name = "Rig"
	add_child(_rig)

	_build_union()
	if join == "seam":
		_build_seam()
	elif join == "shared":
		_build_shared()
	if capture_anchor == "on":
		_build_capture_anchor()
	_build_label()


func _build_union() -> void:
	_root_csg = CSGCombiner3D.new()
	_root_csg.name = "UnionRoot"
	_root_csg.position.y = RIG_Y
	# The box.
	var csg_box := CSGBox3D.new()
	csg_box.size = box_size
	csg_box.operation = CSGShape3D.OPERATION_UNION
	_root_csg.add_child(csg_box)
	# The sphere — also union, additive.
	var csg_sphere := CSGSphere3D.new()
	csg_sphere.radius = sphere_radius
	csg_sphere.position = _fusion_offset()
	csg_sphere.operation = CSGShape3D.OPERATION_UNION
	_root_csg.add_child(csg_sphere)
	if join == "tinted":
		# NO material_override. A root override paints every surface of the
		# resolved solid; leaving it unset lets each primitive's own `material`
		# travel with the faces that primitive contributed, which is the whole
		# claim of this rung — one continuous skin, two provenances.
		csg_box.material = _solid_material(body_color)
		csg_sphere.material = _solid_material(CUT_COLOR)
	else:
		# Material on the root. The shipped path, byte for byte.
		var mat := StandardMaterial3D.new()
		mat.albedo_color = body_color
		mat.metallic = 0.3
		mat.roughness = 0.4
		mat.emission_enabled = true
		mat.emission = body_color
		mat.emission_energy_multiplier = 0.3
		_root_csg.material_override = mat
	_rig.add_child(_root_csg)


## join = seam. The intersection curve of the two surfaces, marked. Built as the
## INTERSECTION of two shells rather than from curve maths, so it is exact for any
## radius, any box and any offset — including the offsets at which it is empty.
func _build_seam() -> void:
	var marker := CSGCombiner3D.new()
	marker.name = "SeamMarker"
	marker.position.y = RIG_Y

	var shell_s := CSGCombiner3D.new()
	shell_s.name = "SphereShell"
	shell_s.operation = CSGShape3D.OPERATION_UNION
	var o: Vector3 = _fusion_offset()
	shell_s.add_child(_shell_sphere(sphere_radius + SEAM_PROUD, o,
		CSGShape3D.OPERATION_UNION))
	shell_s.add_child(_shell_sphere(maxf(sphere_radius - SEAM_PROUD, 0.001), o,
		CSGShape3D.OPERATION_SUBTRACTION))
	marker.add_child(shell_s)

	var shell_b := CSGCombiner3D.new()
	shell_b.name = "BoxShell"
	shell_b.operation = CSGShape3D.OPERATION_INTERSECTION
	var grow: Vector3 = Vector3.ONE * (SEAM_PROUD * 2.0)
	shell_b.add_child(_shell_box(box_size + grow, CSGShape3D.OPERATION_UNION))
	shell_b.add_child(_shell_box(Vector3(
		maxf(box_size.x - grow.x, 0.001),
		maxf(box_size.y - grow.y, 0.001),
		maxf(box_size.z - grow.z, 0.001)), CSGShape3D.OPERATION_SUBTRACTION))
	marker.add_child(shell_b)

	marker.material_override = _seam_material()
	_rig.add_child(marker)


func _shell_sphere(r: float, pos: Vector3, op: int) -> CSGSphere3D:
	var s := CSGSphere3D.new()
	s.radius = r
	s.radial_segments = 32
	s.rings = 16
	s.position = pos
	s.operation = op
	return s


func _shell_box(size: Vector3, op: int) -> CSGBox3D:
	var b := CSGBox3D.new()
	b.size = size
	b.operation = op
	return b


## join = shared. A ∩ B — the volume both shapes claim, which the union counts
## once. Drawn WITHOUT depth test on purpose: unlike csg_difference_demo's
## `trace`, which sits in an open cavity, this solid is entirely enclosed by the
## fused skin (∂(A ∩ B) lies strictly inside A ∪ B, never coplanar with it), so a
## depth-tested ghost would be invisible in every frame. The rung is an x-ray of
## the inclusion–exclusion term, not a surface decoration.
func _build_shared() -> void:
	var comb := CSGCombiner3D.new()
	comb.name = "SharedVolume"
	comb.position.y = RIG_Y
	var box := CSGBox3D.new()
	box.size = box_size
	box.operation = CSGShape3D.OPERATION_UNION
	comb.add_child(box)
	var sph := CSGSphere3D.new()
	sph.radius = sphere_radius
	sph.radial_segments = 24
	sph.rings = 12
	sph.position = _fusion_offset()
	sph.operation = CSGShape3D.OPERATION_INTERSECTION
	comb.add_child(sph)
	var m: StandardMaterial3D = _ghost_material(CUT_COLOR, 0.5)
	m.no_depth_test = true
	comb.material_override = m
	_rig.add_child(comb)


# ── Materials ─────────────────────────────────────────────────────────────

## The shipped surface, in whatever colour it is asked for. Identical settings to
## the root override, so tinted differs from flush in hue alone.
func _solid_material(col: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.metallic = 0.3
	m.roughness = 0.4
	m.emission_enabled = true
	m.emission = col
	m.emission_energy_multiplier = 0.3
	return m


func _seam_material() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(1.0, 0.95, 0.65)
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.emission_enabled = true
	m.emission = Color(1.0, 0.95, 0.65)
	m.emission_energy_multiplier = 1.4
	return m


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


# ── The measured box ──────────────────────────────────────────────────────

## Stand an INVISIBLE box (layers = 0, so it renders nothing and casts nothing)
## around the whole fusion ladder — the union of every rung's extent, not this
## variant's.
##
## WHY IT IS NEEDED. THIS ARTIFACT OWNS NO MeshInstance3D AT ALL.
## capture_config_sweep._subtree_aabb counts MeshInstance3D, falls back to
## MultiMeshInstance3D, and otherwise returns a 1 m box at the origin — so a
## pure-CSG body measures as a unit cube centred on the floor while the solid it
## is meant to frame reaches x 1.42 and y 1.775. Every rung of both axes would be
## photographed against a camera placed for a shape that is not there. layers = 0
## and never visible = false: Godot visibility is hierarchical and would take the
## solid with it, while the render-layer mask is per-instance and leaves the AABB
## walk untouched.
##
## WHY IT IS GATED OFF. GridInteractablesComponent._compute_local_aabb walks
## CSGShape3D as well as MeshInstance3D and hands the result to
## _auto_ground_artifact, which drops the artifact by its own min_y. An anchor
## built in a map would therefore not be inert: sized over the ladder it reaches
## 0.15 below the box floor (at `single` the sphere is concentric, so it hangs to
## -0.5 where the box stops at -0.35), and every bare-token placement would rise
## by exactly that much. `capture_anchor` defaults to "off" and is readable only
## by direct property assignment — which is what dna.fixture does and what no map
## token can do — so the eleven placements never build this node at all.
##
## Sized over the LADDER, not the current value, so the camera is identical for
## all sixteen combinations whether or not the sweep's fixed-camera pre-pass runs.
## Fixed by construction rather than measured from the built scene: a box measured
## per value would be a different box per value, which is the failure it exists to
## prevent.
func _build_capture_anchor() -> void:
	var lo: Vector3 = box_size * -0.5
	var hi: Vector3 = box_size * 0.5
	var offs: Array[Vector3] = []
	if _offset_explicit:
		offs.append(sphere_offset)
	else:
		for i in FUSIONS.size():
			offs.append(_offset_for(FUSIONS[i]))
	for i in offs.size():
		var o: Vector3 = offs[i]
		lo.x = minf(lo.x, o.x - sphere_radius)
		lo.y = minf(lo.y, o.y - sphere_radius)
		lo.z = minf(lo.z, o.z - sphere_radius)
		hi.x = maxf(hi.x, o.x + sphere_radius)
		hi.y = maxf(hi.y, o.y + sphere_radius)
		hi.z = maxf(hi.z, o.z + sphere_radius)
	var anchor := MeshInstance3D.new()
	anchor.name = "CaptureAnchor"
	var bm := BoxMesh.new()
	bm.size = hi - lo
	anchor.mesh = bm
	anchor.position = Vector3(0.0, RIG_Y, 0.0) + (lo + hi) * 0.5
	anchor.layers = 0
	add_child(anchor)


func _build_label() -> void:
	var label := Label3D.new()
	label.text = "A ∪ B"
	label.font_size = 48
	label.outline_size = 8
	label.modulate = body_color
	label.position = Vector3(0, 1.7, 0.5)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)
