extends Node3D
class_name StationGantry

const HangarKit := preload("res://commons/artifacts/_hangar/hangar_kit.gd")

# @identity
# essence: the OVERHEAD RIG that spans the air ABOVE a bay — one or two painted-metal legs rise from the floor and carry a horizontal top beam clear over the stage, with optional cross-bracing, a cable-carrier run along its back, a drop hoist / ring-light at the centre, and a lit strip underneath. It frames the space above a set without standing in it. Origin at the floor centre under the beam's mid-span; 1 cell = 1 m.
# desire: to claim the volume over a stage the way a surgical-light arm claims the air over a bed — to give a bay a ceiling-line of its own, hang light and tooling above the work, and read as "this is a serviced, presented station" — all without putting a single column where the artifact wants to be seen.
# critical_parameter: span_cells × leg_mode — how far the beam reaches and whether it is held at both ends (double_portal, a clean gate) or thrown out from one (single_cantilever, an arm reaching over). The composer matches span to the stage width.
# triggers: _ready/_read_metadata_overrides/_build from DNA; apply_grid_config rebuilds at a new span / height / mode.
# emerges: a bare portal reads "structure overhead"; a lit underside reads "lighting rig"; a centre hoist + ring reads "tooling drops here, work happens under this"; a cable carrier reads "powered, serviced"; caution-striped beam ends read "mind your head, this is plant".
# needs: a horizontal top beam [present]; at least one floor leg with base plate [present]; a clear span over the stage [present]; optional cross-struts [optional]; optional cable carrier [optional]; optional hoist disc + drop tube [optional]; optional underside light strip [optional].
# relationships: hangs OVER [[station_stage]] / [[station_bench]] the way [[station_pillar]] stands beside them; portal legs echo the [[station_pillar]] shaft; assembled into a bay by [[curation_station]]; shares the HangarKit / Dieter-Rams weathered-metal family look with the rest of the station kit.
# truth: a roof is the second thing a place gets after a floor. To span the air over a working stage — and hang light from it — is to admit the space above the work is part of the work. The rig says: look up, the room is finished overhead too.

@export_group("Span")
## Horizontal beam length in 1 m cells (X). Clamped 2..12.
@export var span_cells: int = 5
## Clear height to the underside of the beam (m). Clamped 2.0..4.0.
@export var height: float = 2.8
## "single_cantilever" (one leg, beam reaches out) | "double_portal" (two legs, a gate).
@export var leg_mode: String = "double_portal"

@export_group("Dimensions")
## Vertical thickness of the top beam (m).
@export var beam_depth: float = 0.26
## Square cross-section of each floor leg (m).
@export var leg_width: float = 0.30

@export_group("Fittings")
## A segmented cable-carrier run along the back-top of the beam.
@export var with_cable_carrier: bool = true
## Diagonal cross-struts bracing leg(s) to the beam.
@export var with_struts: bool = true
## A drop tube + ring-light disc hanging from the beam centre.
@export var with_hoist: bool = true
## An emissive light strip under the full length of the beam.
@export var with_lights: bool = true

@export_group("Surface")
@export var stencil_text: String = "GANTRY-01"
@export var wear: float = 0.10
@export var grime: bool = true

@export_group("Color")
@export var body_color: Color = Color(0.81, 0.79, 0.75)
@export var panel_color: Color = Color(0.70, 0.68, 0.64)
@export var accent_color: Color = Color(0.86, 0.34, 0.11)

const CELL := 1.0
const BASE_H := 0.10           # leg base plate thickness
const BEAM_OVERHANG := 0.30    # how far the beam runs past the outer legs

var _built := false


func _ready() -> void:
	_read_metadata_overrides()
	_build()


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()
	if _built:
		for c in get_children():
			c.queue_free()
		_built = false
		_build()


func _read_metadata_overrides() -> void:
	if has_meta("config_span_cells"): span_cells = int(str(get_meta("config_span_cells")))
	if has_meta("config_height"): height = float(str(get_meta("config_height")))
	if has_meta("config_leg_mode"): leg_mode = str(get_meta("config_leg_mode")).to_lower()
	if has_meta("config_beam_depth"): beam_depth = float(str(get_meta("config_beam_depth")))
	if has_meta("config_leg_width"): leg_width = float(str(get_meta("config_leg_width")))
	if has_meta("config_with_cable_carrier"): with_cable_carrier = _b(get_meta("config_with_cable_carrier"))
	if has_meta("config_with_struts"): with_struts = _b(get_meta("config_with_struts"))
	if has_meta("config_with_hoist"): with_hoist = _b(get_meta("config_with_hoist"))
	if has_meta("config_with_lights"): with_lights = _b(get_meta("config_with_lights"))
	if has_meta("config_stencil_text"): stencil_text = str(get_meta("config_stencil_text"))
	if has_meta("config_wear"): wear = float(str(get_meta("config_wear")))
	if has_meta("config_grime"): grime = _b(get_meta("config_grime"))
	if has_meta("config_body_color"): body_color = _pc(str(get_meta("config_body_color")), body_color)
	if has_meta("config_panel_color"): panel_color = _pc(str(get_meta("config_panel_color")), panel_color)
	if has_meta("config_accent_color"): accent_color = _pc(str(get_meta("config_accent_color")), accent_color)


func _build() -> void:
	_built = true
	var span: float = float(clampi(span_cells, 2, 12)) * CELL
	var h: float = clampf(height, 2.0, 4.0)
	var bd: float = clampf(beam_depth, 0.12, 0.5)
	var lw: float = clampf(leg_width, 0.18, 0.6)
	var cantilever: bool = leg_mode == "single_cantilever"

	var body_mat := _mat(body_color)
	var trim_mat := _mat(panel_color.darkened(0.04))
	var dark_mat := HangarKit.worn_metal(panel_color)

	# Leg X positions. Portal = legs near each end of the span; cantilever = single leg at -X end.
	var leg_x: Array = []
	if cantilever:
		leg_x = [-span * 0.5 + lw * 0.5]
	else:
		var inset: float = lw * 0.5
		leg_x = [-span * 0.5 + inset, span * 0.5 - inset]

	# Beam runs the full span; in portal mode it overhangs the outer legs a little.
	var beam_len: float = span + (0.0 if cantilever else BEAM_OVERHANG * 2.0)
	var beam_cx: float = 0.0
	if cantilever:
		# beam cantilevers FROM the single leg across the span toward +X.
		beam_len = span + BEAM_OVERHANG
		beam_cx = -span * 0.5 + lw * 0.5 + beam_len * 0.5 - lw * 0.5
	var beam_cy: float = h + bd * 0.5

	# ── Floor legs (base plate + shaft + capital), echoing the pillar ──
	for lx in leg_x:
		_build_leg(float(lx), h, lw, body_mat, trim_mat, dark_mat)

	# ── Top beam ──
	var beam_w: float = lw * 0.92
	add_child(_box(Vector3(beam_cx, beam_cy, 0.0), Vector3(beam_len, bd, beam_w), body_mat))
	# A slim trim cap along the top of the beam, and bolted seam plates at leg junctions.
	add_child(_box(Vector3(beam_cx, beam_cy + bd * 0.5 - 0.02, 0.0), Vector3(beam_len, 0.04, beam_w * 0.6), trim_mat))
	for lx in leg_x:
		add_child(_box(Vector3(float(lx), beam_cy, 0.0), Vector3(lw * 0.5, bd + 0.04, beam_w + 0.04), dark_mat))
		var b := HangarKit.bolts(
			Vector3(float(lx) - lw * 0.18, beam_cy + bd * 0.32, beam_w * 0.5 + 0.02),
			Vector3(float(lx) + lw * 0.18, beam_cy + bd * 0.32, beam_w * 0.5 + 0.02),
			3, 0.018, dark_mat)
		add_child(b)

	# ── Cross-struts: diagonal braces from each leg up to the beam ──
	if with_struts:
		var strut_mat := dark_mat
		for lx in leg_x:
			# brace reaches toward mid-span (inboard).
			var dir: float = 1.0 if float(lx) < 0.0 else -1.0
			if cantilever:
				dir = 1.0
			var foot := Vector3(float(lx) + dir * lw * 0.5, h - 0.55, 0.0)
			var head := Vector3(float(lx) + dir * 0.62, beam_cy - bd * 0.5, 0.0)
			add_child(_strut(foot, head, 0.05, strut_mat))
			# a small gusset plate at the knee.
			add_child(_box(Vector3(float(lx), beam_cy - bd * 0.5 - 0.06, 0.0), Vector3(lw * 0.9, 0.12, beam_w * 0.5), trim_mat))

	# ── Cable carrier: a segmented run along the back-top edge of the beam ──
	if with_cable_carrier:
		_build_cable_carrier(beam_cx, beam_len, beam_cy + bd * 0.18, -beam_w * 0.5 - 0.04, dark_mat)

	# ── Underside light strip ──
	if with_lights:
		var lit := _emi(Color(1.0, 0.97, 0.9), 1.4)
		add_child(_box(Vector3(beam_cx, h - 0.015, 0.0), Vector3(beam_len * 0.94, 0.03, beam_w * 0.45), lit))
		# warm accent pin-lights at the beam ends.
		for sx in [-1.0, 1.0]:
			add_child(_box(Vector3(beam_cx + sx * beam_len * 0.46, h - 0.02, 0.0), Vector3(0.06, 0.04, beam_w * 0.5), _emi(accent_color, 1.2)))

	# ── Centre hoist: drop tube + ring-light disc ──
	if with_hoist:
		_build_hoist(beam_cx, h, beam_cy - bd * 0.5, dark_mat)

	# ── Caution stripes on the beam ends ──
	for sx in [-1.0, 1.0]:
		add_child(_box(Vector3(beam_cx + sx * (beam_len * 0.5 - 0.08), beam_cy, beam_w * 0.5 + 0.006),
			Vector3(0.16, bd * 0.8, 0.02), HangarKit.striped_mat()))

	# ── Surface detail ──
	if grime:
		for lx in leg_x:
			var g := HangarKit.grime_band(lw + 0.16, 0.05, lw * 0.5 + 0.006, body_color)
			g.position.x = float(lx)
			add_child(g)
	if stencil_text.strip_edges() != "":
		var q: MeshInstance3D = HangarKit.stencil(stencil_text, Vector2(minf(beam_len * 0.22, 0.7), bd * 0.55))
		if q:
			q.position = Vector3(beam_cx, beam_cy, beam_w * 0.5 + 0.012)
			add_child(q)


func _build_leg(lx: float, h: float, lw: float, body_mat: Material, trim_mat: Material, dark_mat: Material) -> void:
	# Base plate.
	add_child(_box(Vector3(lx, BASE_H * 0.5, 0.0), Vector3(lw + 0.16, BASE_H, lw + 0.16), trim_mat))
	# Anchor bolts at the base corners.
	var bm := dark_mat
	add_child(HangarKit.bolts(
		Vector3(lx - lw * 0.5, BASE_H + 0.005, lw * 0.5 + 0.03),
		Vector3(lx + lw * 0.5, BASE_H + 0.005, lw * 0.5 + 0.03), 2, 0.02, bm))
	# Shaft.
	var shaft_h: float = maxf(h - BASE_H, 0.4)
	add_child(_box(Vector3(lx, BASE_H + shaft_h * 0.5, 0.0), Vector3(lw, shaft_h, lw), body_mat))
	# Recessed face panels on the front and back of the leg.
	var pmat := _mat(panel_color)
	for sz in [1.0, -1.0]:
		add_child(_box(Vector3(lx, BASE_H + shaft_h * 0.5, sz * (lw * 0.5 + 0.01)),
			Vector3(lw * 0.6, shaft_h * 0.84, 0.02), pmat))
	# Lit accent groove up the front of each leg.
	add_child(_box(Vector3(lx, BASE_H + shaft_h * 0.5, lw * 0.5 + 0.018),
		Vector3(0.035, shaft_h * 0.7, 0.02), _emi(accent_color, 0.7)))


func _build_cable_carrier(beam_cx: float, beam_len: float, cy: float, cz: float, dark_mat: Material) -> void:
	# A chain of small box links running along the back-top of the beam.
	var run: float = beam_len * 0.9
	var seg: float = 0.16
	var n: int = maxi(int(run / seg), 4)
	var link_mat := dark_mat
	var inner := _mat(panel_color.darkened(0.12))
	for i in range(n):
		var t: float = (float(i) + 0.5) / float(n)
		var x: float = beam_cx - run * 0.5 + run * t
		add_child(_box(Vector3(x, cy, cz), Vector3(seg * 0.82, 0.08, 0.07), link_mat))
		add_child(_box(Vector3(x, cy, cz - 0.005), Vector3(seg * 0.5, 0.045, 0.045), inner))


func _build_hoist(cx: float, h: float, beam_underside: float, dark_mat: Material) -> void:
	# Drop tube from the beam underside down to the disc.
	var drop_top: float = beam_underside
	var disc_y: float = h - 0.55
	add_child(_pipe(Vector3(cx, drop_top, 0.0), Vector3(cx, disc_y + 0.06, 0.0), 0.045, dark_mat))
	# A small carriage block where the tube meets the beam.
	add_child(_box(Vector3(cx, drop_top - 0.05, 0.0), Vector3(0.22, 0.12, 0.22), _mat(panel_color)))
	# Ring-light disc: an emissive torus + a dark hub.
	var ring := TorusMesh.new()
	ring.inner_radius = 0.22
	ring.outer_radius = 0.32
	ring.rings = 24
	ring.ring_segments = 12
	var ring_mi := MeshInstance3D.new()
	ring_mi.mesh = ring
	ring_mi.material_override = _emi(Color(1.0, 0.98, 0.92), 2.0)
	ring_mi.position = Vector3(cx, disc_y, 0.0)
	add_child(ring_mi)
	# Dark hub plate behind the ring.
	add_child(_cyl(Vector3(cx, disc_y, 0.0), 0.20, 0.05, _mat(panel_color.darkened(0.1))))
	# A warm accent pip at the hub centre.
	add_child(_cyl(Vector3(cx, disc_y - 0.01, 0.0), 0.05, 0.06, _emi(accent_color, 1.4)))


# ── helpers ──
func _mat(c: Color) -> StandardMaterial3D:
	return HangarKit.rams_body(c, wear)


func _emi(c: Color, energy: float) -> StandardMaterial3D:
	return HangarKit.emissive(c, energy)


func _box(center: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = center
	return mi


func _cyl(center: Vector3, radius: float, height_y: float, mat: Material) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height_y
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = center
	return mi


# A box stretched/rotated between two points (a strut), thickness `t` square cross-section.
func _strut(a: Vector3, b: Vector3, t: float, mat: Material) -> MeshInstance3D:
	var ln: float = maxf(a.distance_to(b), 0.001)
	var mesh := BoxMesh.new()
	mesh.size = Vector3(t, ln, t)
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	var yv: Vector3 = (b - a).normalized()
	var ref: Vector3 = Vector3.UP if absf(yv.dot(Vector3.UP)) < 0.985 else Vector3.RIGHT
	var xv: Vector3 = ref.cross(yv).normalized()
	var zv: Vector3 = xv.cross(yv).normalized()
	mi.transform = Transform3D(Basis(xv, yv, zv), (a + b) * 0.5)
	return mi


func _pipe(a: Vector3, b: Vector3, r: float, mat: Material) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = r
	mesh.bottom_radius = r
	mesh.height = maxf(a.distance_to(b), 0.001)
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	var yv: Vector3 = (b - a).normalized()
	var ref: Vector3 = Vector3.UP if absf(yv.dot(Vector3.UP)) < 0.985 else Vector3.RIGHT
	var xv: Vector3 = ref.cross(yv).normalized()
	var zv: Vector3 = xv.cross(yv).normalized()
	mi.transform = Transform3D(Basis(xv, yv, zv), (a + b) * 0.5)
	return mi


func _b(v) -> bool:
	return str(v).to_lower() in ["true", "1", "yes", "on"]


func _pc(s: String, fallback: Color) -> Color:
	var p := s.split(",")
	if p.size() < 3:
		return fallback
	return Color(float(p[0]), float(p[1]), float(p[2]), 1.0 if p.size() < 4 else float(p[3]))
