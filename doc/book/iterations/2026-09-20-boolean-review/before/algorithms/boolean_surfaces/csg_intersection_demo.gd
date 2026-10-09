# CSG Intersection Demo — A ∩ B
#
# Two intersecting primitives. Only the overlapping volume survives — what's in both A
# AND B. The result is a lens-shaped solid showing where two shapes agree.
#
# Intersection is the *strictest* of the three CSG operators. The result is always
# smaller than (or equal to) either input. Architecturally useful for "the part of the
# room that both ventilation diagrams agree exists."
#
# @identity
# essence: A ∩ B — the intersection operator. Only the volume present in BOTH primitives survives; the result is a lens where the two shapes agree.
# desire: To show that agreement has a shape, and that it is always smaller than either party brought to it.
# critical_parameter: sphere_offset — controls how much the primitives overlap. Small overlap = a sliver; full overlap = nearly a whole primitive; no overlap = nothing at all.
# triggers: Automatic — builds on _ready() and rotates so the lens of agreement is read from all sides.
# emerges: The feeling that "and" is restrictive. Intersection can only ever take away.
# needs: Procedural CSG [has]. A readout of the surviving volume as the overlap shrinks toward zero [has, 2026-08-11 — forfeit = numeral | gauge].
# relationships: The strictest of the three operators — opposite of csg_union_demo (most permissive). Sits beside csg_difference_demo at csg_compose_workbench.
# truth: Intersection is the shape of consensus. What both shapes agree on is always less than either alone.
# @qfep_term: F.

extends Node3D
class_name CSGIntersectionDemo

# --- DNA (stage 2, promoted 2026-08-11) -------------------------------------
# THE PROBLEM. This artifact's truth line is a QUANTITY CLAIM — "what both shapes
# agree on is always less than either alone" — and it has shipped that claim at
# exactly one overlap, ten times, with no way to see it hold anywhere else. Its
# own @identity already spells out the ladder it never got: "small overlap = a
# sliver; full overlap = nearly a whole primitive; no overlap = nothing at all."
# And it ends by naming what it is missing: "a readout of the surviving volume as
# the overlap shrinks toward zero." Both axes below are that sentence, built.
#
# consensus — HOW MUCH OF WHAT WAS BROUGHT SURVIVES. Resolved as scalar multiples
#   k of the SHIPPED sphere_offset (0.3, 0.2, 0.1), so the direction is constant
#   at |d| = 0.374 and the axis is pure magnitude, read against a box half-extent
#   of 0.4 and a sphere radius of 0.55.
#     unanimous  k = 0, concentric. Face distance 0.4 < r 0.55 < edge midpoint
#                0.566 < corner 0.693, so the survivor is A ITSELF with its twelve
#                edges shaved and its eight corners cut — roughly 95% of the box.
#                Agreement costing almost nothing.
#     broad      k = 1, SHIPPED, and a short-circuit: _cut_offset() returns
#                sphere_offset by a bare return. The lens.
#     narrow     k = 1.9. Centre (0.57, 0.38, 0.19); nearest point of the box is
#                (0.4, 0.38, 0.19) at 0.17, so the sphere penetrates 0.38 — a cap
#                on one face.
#     token      k = 2.6. Centre (0.78, 0.52, 0.26); nearest box point
#                (0.4, 0.4, 0.26) at 0.398, penetration 0.152 — a sliver at the
#                box's edge. Agreement in name only.
#   THE LADDER STOPS SHORT OF THE VANISHING POINT, deliberately. Solving
#   (0.3k - 0.4)² + (0.2k - 0.4)² = 0.55² puts the last surviving overlap at
#   k ≈ 3.03; past it the frame measures NO RENDER and the verdict becomes a fact
#   about the capture rather than about the operator. fontana_puncture stopped
#   `breach` short of 0.866 for exactly this reason and said so. The omission is
#   named here rather than tidied away.
#
# forfeit — WHETHER THE OBJECT WILL SAY WHAT AGREEMENT COST.
#     none     SHIPPED. The lens alone: you are handed the consensus and never
#              told its price. Builds nothing beyond the single CSGCombiner3D
#              named IntersectionRoot the artifact has always built.
#     numeral  a dark plate under the solid carrying |A|, |B|, |A ∩ B| and the two
#              percentages — the readout the @identity asked for, in words.
#     gauge    the same three volumes as three standing bars, tallest normalised
#              to 0.6 m. The third bar is ALWAYS the shortest, so the truth line
#              stops being a sentence and becomes a proportion you can see.
#     losses   the two discarded regions A − B and B − A put back as translucent
#              ghosts exactly where they were taken from, so the frame
#              reconstitutes A ∪ B around the solid survivor and you see the whole
#              of what both parties brought.
#
# WHAT IS DECLINED. `strike` (centred | raised | corner | grazing) is the family
# word — reused character for character across fontana_puncture,
# csg_difference_demo and csg_compose_workbench for the same export, sphere_offset
# — and it is REFUSED here. Its four values are LOCATIONS and its question is
# where the void struck; this artifact has no void, it has a survivor, and its own
# @identity converts the identical export into a MAGNITUDE ("small overlap = a
# sliver ... no overlap = nothing at all"). strike here would be four place-names
# standing in for four amounts. csg_compose_workbench is not a counter-example: the
# bench needs one placement of B to drive five operators at once, which is a
# question about the SET, and a single-operator demo has no set.
#
# Also declined: the empty rung. "No overlap = nothing at all" is the truest thing
# this operator can do and it cannot be photographed — an empty frame measures NO
# RENDER, which is a fact about the bench. See the vanishing point above.
#
# Also declined: `assay` (none | gauge | control | chart | vitrine, 19 artifacts).
# It is the softbody bench family's word for apparatus placed AROUND A SPECIMEN —
# petri_dish_worms defines `control` as "a second, identical, EMPTY dish" — and a
# Boolean demonstration has no specimen. Transplanting it would force `vitrine` to
# mean something here or force it to be dropped, and dropping a rung from a
# nineteen-artifact word is exactly the drift the corpus keeps catching. `readout`
# (18 artifacts) is refused for a mechanical reason: its members forward through
# XYZSliderPlate.readout_name() so their lists cannot drift, and this artifact has
# no such alias path.
const CONSENSUS: PackedStringArray = ["unanimous", "broad", "narrow", "token"]
const FORFEITS: PackedStringArray = ["none", "numeral", "gauge", "losses"]

@export_category("Intersection Settings")
@export_enum("unanimous", "broad", "narrow", "token") var consensus: String = "broad"
@export_enum("none", "numeral", "gauge", "losses") var forfeit: String = "none"
@export var body_color: Color = Color(1.0, 0.55, 0.4, 1.0)
@export var box_size: Vector3 = Vector3(0.8, 0.8, 0.8)
@export var sphere_radius: float = 0.55
## The shipped overlap. A placement that names this directly still WINS over
## consensus — the named axis is a vocabulary laid over the raw vector, never a
## replacement.
@export var sphere_offset: Vector3 = Vector3(0.3, 0.2, 0.1)
@export var rotation_speed: float = 0.35
## CAPTURE ONLY — see _build_capture_anchor(). Reachable by direct property
## assignment alone, which is what dna.fixture does before _ready. Deliberately
## NOT read by apply_grid_config, so no map token can switch it on.
@export var capture_anchor: String = "off"

## The colour of what was given up. Cool against the warm body, so a ghost never
## reads as part of the survivor.
const LOSS_COLOR: Color = Color(0.42, 0.72, 1.0)
## Height the solid has always stood at. Was a literal on _root_csg.position.y.
const RIG_Y: float = 0.7
## Samples per axis for the volume integration. 48³ = 110,592 cell centres, walked
## once, only when forfeit asks for a number.
const LATTICE: int = 48

const PLATE_W: float = 0.9
const PLATE_H: float = 0.22
const PLATE_Y: float = 0.25
## Clear of the solid's swept silhouette: the box's rotated corner radius is
## 0.4·√2 = 0.566, so a plate at 0.62 is never pierced as the rig turns.
const PLATE_Z: float = 0.62
const GAUGE_X: float = 0.75
const GAUGE_H: float = 0.6

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
## changed. Of the ten placements, eight pass no keys at all and two forward
## {"emissive": false} from curation_station — a key no build path reads — so the
## guarded body stamps it, recomputes the signature, finds no change and returns
## before teardown.
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
		consensus, forfeit, sphere_radius, str(box_size),
		str(_cut_offset()), str(body_color), capture_anchor]


func _read_metadata_overrides() -> void:
	if has_meta("config_consensus"):
		var cv: String = str(get_meta("config_consensus")).strip_edges().to_lower()
		if CONSENSUS.has(cv):
			consensus = cv
	if has_meta("config_forfeit"):
		var fv: String = str(get_meta("config_forfeit")).strip_edges().to_lower()
		if FORFEITS.has(fv):
			forfeit = fv
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


# ── The overlap ───────────────────────────────────────────────────────

## consensus resolved to the vector the CSG has always used. "broad" returns
## sphere_offset by a BARE RETURN — not k = 1.0 multiplied through. The two are
## bit-identical for these floats, so the reason is not arithmetic: it is that the
## shipped vector must never travel the same code path as the derived ones, and a
## later edit to _consensus_scale() therefore cannot reach it at all.
func _cut_offset() -> Vector3:
	if _offset_explicit or consensus == "broad" or not CONSENSUS.has(consensus):
		return sphere_offset
	return sphere_offset * _consensus_scale(consensus)


## Multiples of the shipped offset, so the ladder is pure magnitude along one
## fixed direction. See the k values and their geometry in the DNA note above.
func _consensus_scale(which: String) -> float:
	match which:
		"unanimous":
			return 0.0
		"narrow":
			return 1.9
		"token":
			return 2.6
		_:
			return 1.0


# ── Build ─────────────────────────────────────────────────────────────

func _build() -> void:
	_built = true
	# The rig exists so the loss ghosts can rotate WITH the survivor. A
	# CSGCombiner3D nested inside another combiner is not a container, it is a
	# shape: parenting the ghosts to _root_csg would union them back into the very
	# solid they are meant to comment on. The rig is a plain Node3D at the origin,
	# and because _root_csg sits on the rotation axis (its offset is purely
	# vertical, x = z = 0), rotating the rig is the SAME world transform the old
	# _root_csg.rotation.y produced — translation along Y commutes with rotation
	# about Y. Auto-grounding is likewise untouched: _compute_local_aabb recurses
	# through Node3D children applying their transforms, so the merged box and its
	# min_y come out identical.
	_rig = Node3D.new()
	_rig.name = "Rig"
	add_child(_rig)

	_build_intersection()
	match forfeit:
		"numeral":
			_build_numeral()
		"gauge":
			_build_gauge()
		"losses":
			_build_losses()
	if capture_anchor == "on":
		_build_capture_anchor()
	_build_label()


func _build_intersection() -> void:
	_root_csg = CSGCombiner3D.new()
	_root_csg.name = "IntersectionRoot"
	_root_csg.position.y = RIG_Y
	var csg_box := CSGBox3D.new()
	csg_box.size = box_size
	csg_box.operation = CSGShape3D.OPERATION_UNION
	_root_csg.add_child(csg_box)
	var csg_sphere := CSGSphere3D.new()
	csg_sphere.radius = sphere_radius
	csg_sphere.position = _cut_offset()
	csg_sphere.operation = CSGShape3D.OPERATION_INTERSECTION
	_root_csg.add_child(csg_sphere)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = body_color
	mat.metallic = 0.3
	mat.roughness = 0.4
	mat.emission_enabled = true
	mat.emission = body_color
	mat.emission_energy_multiplier = 0.4
	_root_csg.material_override = mat
	_rig.add_child(_root_csg)


# ── What agreement cost ───────────────────────────────────────────────

## |A|, |B| and |A ∩ B|, integrated on a regular lattice of cell centres over the
## union AABB of the two primitives. NO RNG ANYWHERE — every sample point is a
## function of the geometry — so there is no seed to declare and no run-to-run
## question to answer. All three are measured by the SAME instrument on purpose:
## an analytic |A| against a sampled |A ∩ B| would make the percentages disagree
## with the bars beside them.
##
## Only forfeit = numeral and gauge ever call this. The default never runs one
## iteration of it.
func _volumes() -> Dictionary:
	var d: Vector3 = _cut_offset()
	var h: Vector3 = box_size * 0.5
	var lo: Vector3 = Vector3(
		minf(-h.x, d.x - sphere_radius),
		minf(-h.y, d.y - sphere_radius),
		minf(-h.z, d.z - sphere_radius))
	var hi: Vector3 = Vector3(
		maxf(h.x, d.x + sphere_radius),
		maxf(h.y, d.y + sphere_radius),
		maxf(h.z, d.z + sphere_radius))
	var cell: Vector3 = (hi - lo) / float(LATTICE)
	var cell_vol: float = cell.x * cell.y * cell.z
	var r2: float = sphere_radius * sphere_radius
	var n_a: int = 0
	var n_b: int = 0
	var n_both: int = 0
	for ix in LATTICE:
		var px: float = lo.x + (float(ix) + 0.5) * cell.x
		var dx: float = px - d.x
		var in_x: bool = absf(px) <= h.x
		for iy in LATTICE:
			var py: float = lo.y + (float(iy) + 0.5) * cell.y
			var dy: float = py - d.y
			var in_xy: bool = in_x and absf(py) <= h.y
			for iz in LATTICE:
				var pz: float = lo.z + (float(iz) + 0.5) * cell.z
				var dz: float = pz - d.z
				var in_a: bool = in_xy and absf(pz) <= h.z
				var in_b: bool = dx * dx + dy * dy + dz * dz <= r2
				if in_a:
					n_a += 1
				if in_b:
					n_b += 1
				if in_a and in_b:
					n_both += 1
	return {
		"a": float(n_a) * cell_vol,
		"b": float(n_b) * cell_vol,
		"both": float(n_both) * cell_vol,
	}


## forfeit = numeral. The readout the @identity asked for and never had, hung
## under the solid as a museum label: all three volumes and the two percentages,
## so the price of agreement is a number and not an impression.
func _build_numeral() -> void:
	var v: Dictionary = _volumes()
	var va: float = float(v["a"])
	var vb: float = float(v["b"])
	var vo: float = float(v["both"])
	var pa: float = 0.0
	if va > 0.0:
		pa = vo / va * 100.0
	var pb: float = 0.0
	if vb > 0.0:
		pb = vo / vb * 100.0

	var plate := MeshInstance3D.new()
	plate.name = "ForfeitPlate"
	var pm := BoxMesh.new()
	pm.size = Vector3(PLATE_W, PLATE_H, 0.02)
	plate.mesh = pm
	plate.material_override = _panel_material(Color(0.07, 0.08, 0.10))
	plate.position = Vector3(0.0, PLATE_Y, PLATE_Z)
	add_child(plate)

	var lab := Label3D.new()
	lab.name = "ForfeitReadout"
	lab.text = "|A| %.3f     |B| %.3f\n|A ∩ B| %.3f\n%.1f%% of A     %.1f%% of B" % [
		va, vb, vo, pa, pb]
	lab.font_size = 40
	lab.pixel_size = 0.0016
	lab.outline_size = 0
	lab.modulate = Color(0.94, 0.94, 0.92)
	lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# Billboarding left DISABLED on purpose: LabelFramer only reframes hanging
	# labels, so a label that already lies on a panel keeps the panel it was given.
	lab.position = Vector3(0.0, PLATE_Y, PLATE_Z + 0.02)
	add_child(lab)


## forfeit = gauge. The same three volumes as three standing bars beside the
## solid, the tallest normalised to GAUGE_H. The third bar is ALWAYS the shortest,
## because |A ∩ B| ≤ min(|A|, |B|) is not a fact about this placement but about
## the operator — which is the truth line stated as geometry instead of prose.
func _build_gauge() -> void:
	var v: Dictionary = _volumes()
	var vals: Array = [float(v["a"]), float(v["b"]), float(v["both"])]
	var top: float = maxf(maxf(float(vals[0]), float(vals[1])), float(vals[2]))
	if top <= 0.0:
		return
	var cols: Array = [body_color, LOSS_COLOR, Color(1.0, 0.92, 0.62)]
	var names: Array = ["A", "B", "A∩B"]
	var base_top: float = RIG_Y - box_size.y * 0.5

	var base := MeshInstance3D.new()
	base.name = "GaugeBase"
	var bm := BoxMesh.new()
	bm.size = Vector3(0.44, 0.03, 0.16)
	base.mesh = bm
	base.material_override = _panel_material(Color(0.13, 0.13, 0.15))
	base.position = Vector3(GAUGE_X, base_top + 0.015, 0.0)
	add_child(base)

	for i in 3:
		var col: Color = cols[i]
		var frac: float = float(vals[i]) / top
		var bh: float = maxf(frac * GAUGE_H, 0.004)
		var bx: float = GAUGE_X + (float(i) - 1.0) * 0.13
		var bar := MeshInstance3D.new()
		bar.name = "GaugeBar%d" % int(i)
		var barmesh := BoxMesh.new()
		barmesh.size = Vector3(0.09, bh, 0.09)
		bar.mesh = barmesh
		bar.material_override = _emissive_material(col)
		bar.position = Vector3(bx, base_top + 0.03 + bh * 0.5, 0.0)
		add_child(bar)

		var tag := Label3D.new()
		tag.name = "GaugeTag%d" % int(i)
		tag.text = str(names[i])
		tag.font_size = 32
		tag.pixel_size = 0.0018
		tag.outline_size = 0
		tag.modulate = col
		tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tag.position = Vector3(bx, base_top - 0.045, 0.09)
		add_child(tag)


## forfeit = losses. The two regions the operator threw away — A − B and B − A —
## put back as translucent ghosts exactly where they were taken from, so the frame
## reconstitutes A ∪ B around the solid survivor.
##
## This is NOT csg_compose_workbench's `atoms`. atoms puts the three disjoint
## regions on three SEPARATE benches to argue that the regions are primitive and
## the operators are not; this reassembles two of them IN PLACE around the
## survivor to argue what THIS one operation cost.
func _build_losses() -> void:
	_ghost_region("LossFromA", true)
	_ghost_region("LossFromB", false)


## A − B when a_minus_b, else B − A. The FIRST child of a CSGCombiner3D is the
## base solid and every later child operates on it, so the order of add_child is
## the order of the expression.
func _ghost_region(nm: String, a_minus_b: bool) -> void:
	var comb := CSGCombiner3D.new()
	comb.name = nm
	comb.position.y = RIG_Y
	var box := CSGBox3D.new()
	box.size = box_size
	var sph := CSGSphere3D.new()
	sph.radius = sphere_radius
	sph.radial_segments = 24
	sph.rings = 12
	sph.position = _cut_offset()
	if a_minus_b:
		box.operation = CSGShape3D.OPERATION_UNION
		sph.operation = CSGShape3D.OPERATION_SUBTRACTION
		comb.add_child(box)
		comb.add_child(sph)
		comb.material_override = _ghost_material(body_color, 0.20)
	else:
		sph.operation = CSGShape3D.OPERATION_UNION
		box.operation = CSGShape3D.OPERATION_SUBTRACTION
		comb.add_child(sph)
		comb.add_child(box)
		comb.material_override = _ghost_material(LOSS_COLOR, 0.26)
	_rig.add_child(comb)


# ── Capture ───────────────────────────────────────────────────────────

## CAPTURE ONLY, and the reason it has to exist. capture_config_sweep frames its
## camera on a union AABB built from MeshInstance3D nodes; a CSG solid is a
## CSGShape3D and a Label3D is not a mesh either, so at forfeit = none this
## artifact's ONLY measurable body is the plate LabelFramer builds behind the
## "A ∩ B" caption at y 1.7. Every rung of consensus would be photographed with
## the camera fitted to the caption and the survivor below the frame — four tiles
## that measure a fact about the bench. This is A, the primitive every survivor is
## a subset of, as an invisible box: layers = 0 is per-instance, so it is drawn by
## no camera and casts no shadow, and it keeps its AABB. Sized to A exactly, which
## is the whole extent worth framing and not one centimetre more.
##
## GATED SO THE WORLD NEVER SEES IT. capture_anchor is reachable ONLY by a direct
## property assignment — what dna.fixture does before _ready — and
## apply_grid_config deliberately does not read it, so no map token and no
## registry default_params can turn it on. That gate is load-bearing rather than
## tidy: auto-grounding (GridInteractablesComponent._compute_local_aabb) measures
## CSGShape3D as well as MeshInstance3D and snaps the artifact's lowest point to
## the cell surface, so an anchor reaching 0.05 m below the survivor's own base
## would silently drop all ten placements by that much.
func _build_capture_anchor() -> void:
	var mi := MeshInstance3D.new()
	mi.name = "CaptureAnchor"
	var bm := BoxMesh.new()
	bm.size = box_size
	mi.mesh = bm
	mi.layers = 0
	mi.position = Vector3(0.0, RIG_Y, 0.0)
	add_child(mi)


# ── Materials and chrome ──────────────────────────────────────────────

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


func _panel_material(col: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.metallic = 0.0
	m.roughness = 0.55
	return m


func _emissive_material(col: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.metallic = 0.2
	m.roughness = 0.45
	m.emission_enabled = true
	m.emission = col
	m.emission_energy_multiplier = 0.35
	return m


func _build_label() -> void:
	var label := Label3D.new()
	label.text = "A ∩ B"
	label.font_size = 48
	label.outline_size = 8
	label.modulate = body_color
	label.position = Vector3(0, 1.7, 0.5)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)
