extends Node3D
class_name CoralTrialV1

# FUNGIA — a solitary mushroom / disc coral, after Ernst Haeckel's Hexacoralla plate.
#
# A slightly domed circular disc whose oral (top) face is covered in dense RADIAL
# SEPTA: thin tapered ridge-walls fanning from a central mouth out to the rim, in the
# classic coral septal orders — a TALL primary set (m-fold), shorter SECONDARY septa
# starting further out between the primaries, and shorter still TERTIARY septa between
# those. A small glowing oral groove sits at the centre; the underside is a smooth
# domed calice. The signature is the dense, fine, radial ribbing — a radial topology
# grammar built as genuine standing geometry, not a texture.
#
# Build strategy (warning-clean, deterministic from a local RNG seed):
#   - DOME : MorphoPrimitive.revolution of a low-dome profile (wide, shallow).
#   - SEPTA: each septum is a thin radial WALL of quads that follows the dome surface
#            from an inner start radius out to the rim, its top edge gently curved
#            (crest highest near the rim), tapering thinner toward the centre. Every
#            septum is oriented by a Basis (never look_at). ONE angular wedge of septa
#            (one primary + the secondaries/tertiaries flanking it) is generated, then
#            rotate-copied m-fold for clean radial symmetry — each copy batched into one
#            shared SurfaceTool ArrayMesh per material so the capture frames the form.
#   - MOUTH: a small oral depression + an unshaded glowing fluorescent boss at centre.
#
# Materials match the coral palette: SKELETON/septa pale calcite ivory with a faint
# emission floor (so the fine septa read against the dark capture, never black), TISSUE
# warm-coral subsurface-scattering flesh on the dome between the septa, and a green
# FLUORESCENT unshaded mouth glow.

# ── Palette ───────────────────────────────────────────────────────────
const COL_SKELETON := Color(0.90, 0.86, 0.78)   # color_b — pale calcite ivory
const COL_TISSUE := Color(0.95, 0.45, 0.35)     # color_a — living polyp tissue
const COL_FLUOR := Color(0.40, 1.00, 0.45)      # accent — polyp mouth fluorescence

# ── Form constants (native size; ~2.2 m across after final span scaling) ──
const DISC_RADIUS: float = 1.0
const DOME_HEIGHT: float = 0.30
const SEPTUM_THICKNESS: float = 0.018           # half-thickness of a septum wall
const SEPTUM_SIDES: int = 1                      # walls are flat strips (2 faces)
const TARGET_SPAN: float = 2.2                   # final across-span in meters

var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = 4242
	_build()


func apply_grid_config(_c: Dictionary) -> void:
	pass


# ── Build ──────────────────────────────────────────────────────────────

func _build() -> void:
	var body := Node3D.new()
	body.name = "Fungia"
	add_child(body)

	var complexity: int = 7

	_build_dome(body)
	_build_septa(body, complexity)
	_build_growth_ridges(body, complexity)
	_build_mouth(body)

	# Rest the disc on the floor with its oral (septate) face UP. The capture camera
	# looks down from ~40 deg elevation, so a near-flat disc presents the full radial
	# fan to it; a small lay-back toward the +X/+Z camera adds dimensionality without
	# going edge-on. A yaw spin just rotates which septa face front. Then scale to the
	# target span and centre horizontally.
	body.rotation = Vector3(deg_to_rad(-6.0), deg_to_rad(18.0), deg_to_rad(-4.0))
	_settle_to_span(body, TARGET_SPAN)


# ── Materials ──────────────────────────────────────────────────────────

## SKELETON / septa (color_b): pale calcite ivory. Faint emission FLOOR so the fine
## septa read against the dark capture and never collapse to black.
func _skeleton_mat() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = COL_SKELETON
	m.roughness = 0.7
	m.metallic = 0.0
	m.emission_enabled = true
	m.emission = COL_SKELETON * 0.4
	m.emission_energy_multiplier = 0.10
	return m


## TISSUE / polyp flesh (color_a): warm coral, soft subsurface scattering on the dome
## between the septa, faint own-tone emission.
func _tissue_mat() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = COL_TISSUE
	m.roughness = 0.6
	m.metallic = 0.0
	m.subsurf_scatter_enabled = true
	m.subsurf_scatter_strength = 0.25
	m.emission_enabled = true
	m.emission = COL_TISSUE * 0.5
	m.emission_energy_multiplier = 0.12
	return m


## FLUORESCENCE / oral mouth (accent): saturated unshaded bioluminescent green glow.
func _fluor_mat() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = COL_FLUOR
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.emission_enabled = true
	m.emission = COL_FLUOR
	m.emission_energy_multiplier = 3.0
	return m


# ── Dome base (the calice) ─────────────────────────────────────────────

## Height of the dome surface at a normalized radius rn in [0,1]. A low dome that is
## highest at the centre and falls to a thin rim — the resting profile of a fungia.
func _dome_y(rn: float) -> float:
	var t: float = clampf(rn, 0.0, 1.0)
	# Smooth dome: cos-shaped fall from centre to rim.
	return DOME_HEIGHT * cos(t * PI * 0.5)


## A shallow domed disc as a surface of revolution. Top face is the dome; a thin lip
## wraps to a flat-ish underside so the disc reads as a solid resting object.
func _build_dome(parent: Node3D) -> void:
	var profile: Array[Vector2] = []
	var steps: int = 28
	# Top dome, centre -> rim (radius grows, height falls).
	for i: int in range(steps + 1):
		var rn: float = float(i) / float(steps)
		var r: float = rn * DISC_RADIUS
		profile.append(Vector2(maxf(r, 0.001), _dome_y(rn)))
	# Rim lip: drop down the outer edge.
	var rim_y: float = _dome_y(1.0)
	profile.append(Vector2(DISC_RADIUS, rim_y - 0.06))
	# Underside: smooth shallow concave sweep back to centre (the calice floor).
	for i: int in range(1, steps + 1):
		var rn: float = 1.0 - float(i) / float(steps)
		var r: float = rn * DISC_RADIUS * 0.985
		var under_y: float = (rim_y - 0.06) - (1.0 - rn) * 0.10
		profile.append(Vector2(maxf(r, 0.001), under_y))

	var mesh: Mesh = MorphoPrimitive.revolution(profile, 96)
	_add_mesh(parent, mesh, _tissue_mat(), Transform3D.IDENTITY, "Dome")


# ── Septa (the hero) ───────────────────────────────────────────────────

## Build the dense radial septa in three orders. Generate ONE angular wedge (the septa
## belonging to a single primary sector) then rotate-copy it m-fold around Y for clean
## radial symmetry. All septa batch into ONE ArrayMesh (one MeshInstance3D) so the
## capture frames the whole fan.
func _build_septa(parent: Node3D, complexity: int) -> void:
	# Primary fold count scales with complexity: 24..48, kept even.
	var m_fold: int = clampi(24 + complexity * 3, 24, 48)
	if m_fold % 2 == 1:
		m_fold += 1

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var wedge_angle: float = TAU / float(m_fold)

	# Generate the wedge's septa as angle offsets from the sector's primary (at 0).
	# Within one sector: 1 primary (centre), 2 secondary (the half-steps on each side,
	# shared with neighbours so we only emit the +half here), 2 tertiary (the quarter
	# steps). To avoid double-emitting shared septa we emit, per sector:
	#   primary at 0   (tall, from inner_p to rim)
	#   secondary at +1/2 wedge (shorter, starts further out)
	#   tertiary at +1/4 and +3/4 wedge (shortest, starts further out still)
	# Rotating the sector m_fold times tiles the full disc with no gaps or overlaps.

	# Per-order radial start (normalized) and crest height multipliers. The primaries
	# stop short of the dead centre so a clean oral FOSSA stays open around the mouth;
	# secondaries/tertiaries start progressively further out — the classic septal orders.
	var inner_primary: float = 0.16
	var inner_secondary: float = 0.36
	var inner_tertiary: float = 0.60

	for s: int in range(m_fold):
		var sector_base: float = float(s) * wedge_angle

		# PRIMARY septum (tallest, reaches nearest the central fossa).
		_emit_septum(st, sector_base + 0.0, inner_primary, 1.0, s, 0)

		# SECONDARY septum (half-step, distinctly shorter, starts further out).
		_emit_septum(st, sector_base + wedge_angle * 0.5, inner_secondary, 0.58, s, 1)

		# TERTIARY septa (quarter + three-quarter, shortest, start furthest out).
		_emit_septum(st, sector_base + wedge_angle * 0.25, inner_tertiary, 0.34, s, 2)
		_emit_septum(st, sector_base + wedge_angle * 0.75, inner_tertiary, 0.34, s, 2)

	st.generate_normals()
	_add_mesh(parent, st.commit(), _skeleton_mat(), Transform3D.IDENTITY, "Septa")


## Append one radial septum WALL to `st`. The wall is a vertical thin strip of quads
## following the dome surface from `inner_rn` (normalized inner radius) out to the rim,
## standing on the dome top. Its crest (top edge) rises above the dome, highest toward
## the rim, tapering to nothing at the inner tip and at the outer rim — a fin profile.
## Oriented purely by trig in the X/Z plane (radial direction) — no look_at.
func _emit_septum(st: SurfaceTool, angle: float, inner_rn: float,
		height_mul: float, sector: int, order: int) -> void:
	# Deterministic per-septum jitter so the fan reads organic, not mechanical.
	var jseed: int = sector * 131 + order * 17 + int(round(angle * 1000.0))
	_rng.seed = 4242 + jseed
	var h_jit: float = lerpf(0.86, 1.12, _rng.randf())
	var ang_jit: float = (_rng.randf() - 0.5) * 0.012
	var a: float = angle + ang_jit

	var radial := Vector3(cos(a), 0.0, sin(a))           # outward direction in XZ
	var tangent := Vector3(-sin(a), 0.0, cos(a))         # wall thickness direction

	var segs: int = 26
	var thick: float = SEPTUM_THICKNESS * lerpf(0.85, 1.0, height_mul)
	# Crest height of this septal order, relative to the dome. Kept modest so the disc
	# reads as a domed plate carrying dense FINE ribbing, not a tall scallop.
	var crest: float = DOME_HEIGHT * 0.42 * height_mul * h_jit

	# Walk from inner to rim; build a ribbon of quads (two walls + a thin top cap).
	# All "prev_*" carriers are LOCAL so each septum starts fresh (no bridging to the
	# previous septum's last segment).
	var prev_valid: bool = false
	var prev_in := Vector3.ZERO    # base, inner-thickness side
	var prev_out := Vector3.ZERO   # base, outer-thickness side
	var prev_tin := Vector3.ZERO   # crest, inner-thickness side
	var prev_tout := Vector3.ZERO  # crest, outer-thickness side

	for i: int in range(segs + 1):
		var f: float = float(i) / float(segs)
		var rn: float = lerpf(inner_rn, 0.995, f)
		var r: float = rn * DISC_RADIUS
		var base_y: float = _dome_y(rn) + 0.004        # sit just above the dome skin
		var center := radial * r + Vector3(0.0, base_y, 0.0)

		# Crest profile along the septum: rises quickly from the inner tip, holds a
		# broad plateau across the mid/outer disc (so the ridge reads as a continuous
		# radial wall, not a single fin), then eases down to meet the rim cleanly.
		var rise: float = smoothstep(0.0, 0.22, f)        # quick ramp up from inner tip
		var fall: float = 1.0 - smoothstep(0.86, 1.0, f)  # ease down into the rim
		var swell: float = 0.80 + 0.20 * sin(clampf(f, 0.0, 1.0) * PI)  # gentle mid bulge
		var wall_h: float = crest * rise * fall * swell
		var top := center + Vector3(0.0, wall_h, 0.0)

		# Thin thickness, slightly narrower toward the crest (tapered wall).
		var base_off: Vector3 = tangent * thick
		var top_off: Vector3 = tangent * (thick * 0.55)

		var b_in: Vector3 = center - base_off
		var b_out: Vector3 = center + base_off
		var t_in: Vector3 = top - top_off
		var t_out: Vector3 = top + top_off

		if prev_valid:
			# Side wall A (inner-thickness side): prev(base,crest) -> cur(base,crest)
			_quad(st, prev_in, b_in, t_in, prev_tin)
			# Side wall B (outer-thickness side)
			_quad(st, b_out, prev_out, prev_tout, t_out)
			# Thin top cap ridge connecting the two crest edges.
			_quad(st, prev_tin, t_in, t_out, prev_tout)

		prev_in = b_in
		prev_out = b_out
		prev_tin = t_in
		prev_tout = t_out
		prev_valid = true


## Add a quad (two triangles) with CCW winding a->b->c, a->c->d. Normals generated
## later by SurfaceTool.generate_normals().
func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	st.add_vertex(a); st.add_vertex(b); st.add_vertex(c)
	st.add_vertex(a); st.add_vertex(c); st.add_vertex(d)


# ── Concentric growth ridges (fine rings crossing the septa) ───────────

## A few faint concentric rings sitting on the dome, crossing the septa — the coral's
## incremental growth bands. Thin tori batched into one ArrayMesh.
func _build_growth_ridges(parent: Node3D, complexity: int) -> void:
	var ring_count: int = clampi(complexity - 2, 3, 6)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for k: int in range(ring_count):
		var rn: float = lerpf(0.34, 0.92, float(k) / float(maxi(ring_count - 1, 1)))
		var ring_r: float = rn * DISC_RADIUS
		var y: float = _dome_y(rn) + 0.012
		_emit_ring(st, ring_r, y, 0.010, 64)
	st.generate_normals()
	_add_mesh(parent, st.commit(), _skeleton_mat(), Transform3D.IDENTITY, "GrowthRidges")


## Append a thin horizontal ring (a torus tube) of radius `ring_r` at height `y` with
## tube radius `tube_r`. Built from oriented segments — pure trig, no look_at.
func _emit_ring(st: SurfaceTool, ring_r: float, y: float, tube_r: float, segs: int) -> void:
	var sides: int = 5
	var prev_loop: Array[Vector3] = []
	for i: int in range(segs + 1):
		var a: float = TAU * float(i) / float(segs)
		var center := Vector3(cos(a) * ring_r, y, sin(a) * ring_r)
		var radial := Vector3(cos(a), 0.0, sin(a))     # points outward
		var up := Vector3.UP
		var loop: Array[Vector3] = []
		for sjj: int in range(sides):
			var ang: float = TAU * float(sjj) / float(sides)
			var off: Vector3 = (radial * cos(ang) + up * sin(ang)) * tube_r
			loop.append(center + off)
		if not prev_loop.is_empty():
			for sjj: int in range(sides):
				var njj: int = (sjj + 1) % sides
				_quad(st, prev_loop[sjj], prev_loop[njj], loop[njj], loop[sjj])
		prev_loop = loop


# ── Central mouth ──────────────────────────────────────────────────────

## A small oral depression at the centre with a glowing fluorescent boss — the polyp
## mouth. A dark ivory rim ring frames a sunken green glow.
func _build_mouth(parent: Node3D) -> void:
	var center_y: float = _dome_y(0.0)

	# Sunken oral groove: an inverted-cone depression in ivory filling the central
	# fossa left open by the primary septa.
	var groove := SurfaceTool.new()
	groove.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rim_r: float = 0.155
	var depth: float = 0.11
	var seg: int = 40
	var rim_top := Vector3(0.0, center_y + 0.01, 0.0)
	var bottom := Vector3(0.0, center_y - depth, 0.0)
	for i: int in range(seg):
		var a0: float = TAU * float(i) / float(seg)
		var a1: float = TAU * float(i + 1) / float(seg)
		var p0 := Vector3(cos(a0) * rim_r, rim_top.y, sin(a0) * rim_r)
		var p1 := Vector3(cos(a1) * rim_r, rim_top.y, sin(a1) * rim_r)
		# Cone wall down to the bottom.
		groove.add_vertex(p0); groove.add_vertex(bottom); groove.add_vertex(p1)
	groove.generate_normals()
	_add_mesh(parent, groove.commit(), _skeleton_mat(), Transform3D.IDENTITY, "OralGroove")

	# Glowing oral mouth: a flattened fluorescent boss filling the fossa, elongated into
	# the characteristic fungia central SLIT and sitting just below the rim so the green
	# reads clearly from the overhead camera without poking above the septa crowns.
	var glow_mesh: Mesh = MorphoPrimitive.sphere(0.11, 24, 14)
	var glow_xform := Transform3D(Basis().scaled(Vector3(1.45, 0.5, 0.7)),
		Vector3(0.0, center_y - depth * 0.12, 0.0))
	_add_mesh(parent, glow_mesh, _fluor_mat(), glow_xform, "MouthGlow")


# ── Utilities ──────────────────────────────────────────────────────────

## Wrap a Mesh in a MeshInstance3D with material + local transform, parented to `parent`.
func _add_mesh(parent: Node3D, mesh: Mesh, mat: Material,
		xform: Transform3D, node_name: String) -> MeshInstance3D:
	if mesh == null:
		return null
	var mi := MeshInstance3D.new()
	mi.name = node_name
	mi.mesh = mesh
	mi.material_override = mat
	mi.transform = xform
	parent.add_child(mi)
	return mi


## AABB of a node subtree in `node`'s LOCAL space (accumulates each MeshInstance3D's
## AABB through the chain of local transforms). Independent of global tree state.
func _subtree_aabb(node: Node3D) -> AABB:
	var total := AABB()
	var first: bool = true
	var stack: Array = [[node, Transform3D.IDENTITY]]
	while not stack.is_empty():
		var entry: Array = stack.pop_back()
		var current: Node = entry[0]
		var accum: Transform3D = entry[1]
		if current is MeshInstance3D and (current as MeshInstance3D).mesh != null:
			var mi := current as MeshInstance3D
			var a: AABB = accum * mi.get_aabb()
			if first:
				total = a
				first = false
			else:
				total = total.merge(a)
		for child: Node in current.get_children():
			if child is Node3D:
				stack.append([child, accum * (child as Node3D).transform])
			else:
				stack.append([child, accum])
	return total


## Scale `body` so its across-span (max of x/z) fills `target_span`, rest it on the
## floor (lowest point to y=0), and centre it horizontally at the origin.
func _settle_to_span(body: Node3D, target_span: float) -> void:
	var raw: AABB = _subtree_aabb(body)
	var span_xz: float = maxf(maxf(raw.size.x, raw.size.z), 0.001)
	var k: float = target_span / span_xz
	body.scale = Vector3(k, k, k)

	var aabb: AABB = _subtree_aabb(body)
	if aabb.size == Vector3.ZERO:
		return
	var centre: Vector3 = aabb.get_center()
	body.position += Vector3(-centre.x, -aabb.position.y, -centre.z)
