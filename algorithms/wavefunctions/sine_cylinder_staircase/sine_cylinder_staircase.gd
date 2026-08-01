@tool
extends Node3D

# ----------------- Parameters -----------------

# @identity
# essence: r(theta) = base_radius + sine_mod * sin(mod_freq * theta), y = step_rise * i
# desire: Climb a helical staircase whose radius breathes with sine modulation as you ascend
# critical_parameter: SINE_MODULATION — amplitude of the radial sine wave that makes the staircase breathe
# triggers: _compute_samples() calculates each step position from modulated polar coordinates
# emerges: a walkable sine function wrapped into architecture — your body traces the wave by climbing
# needs: VR locomotion and collision [has], staircase physics [has]
# relationships: depends on polar-to-Cartesian conversion with sine modulation; contrasts with bernini_columns (staircase vs column spirals); unlocks wave-as-architecture
# truth: A spiral staircase with sine-modulated radius is a helix that breathes.

@export var STEP_COUNT: int = 80
@export var TOTAL_TURNS: float = 2.0
@export var BASE_RADIUS: float = 1.6
@export var WALKWAY_OFFSET: float = 0.9
@export var STEP_RISE: float = 0.10
@export var STEP_THICKNESS: float = 0.22
@export var STEP_WIDTH: float = 2.0
@export var MIN_STEP_DEPTH: float = 0.4
@export var WAVE_AMPLITUDE: float = 0.0   # set >0 for wavy path
@export var WAVE_FREQUENCY: float = 2.0
@export var COLLIDER_HEIGHT_OFFSET: float = 0.3 # small lift so it sits on the tread
@export var show_planes: bool = true   # visible bridge planes
@export var show_center_pole: bool = false
@export var debug: bool = false

## AXIS — WHAT THE STAIR PROVIDES so a body can use a formula.
##
## r(theta) = base + sine gives a helix of 80 sample points. It does not give a floor, a
## handhold or a support; those have to be invented, and the invention is where the artifact
## admits that a curve and a body want different things. Today's answer is the magenta
## bridge planes: translucent, unshaded, floating 0.3 m above the treads — a patch so
## obviously provisional that it reads as scaffolding left in place.
##
##   membrane   the legacy lineage, byte for byte — a translucent pink quad between each
##              pair of facing tread edges. The gap is admitted and covered in a material
##              nobody would build a stair from.
##   none       nothing added. Eighty separate treads climbing through air: the sampled
##              function, unassisted, and the gaps are simply the truth about sampling.
##   rail       a continuous handrail helix on the outer edge at hand height, with a
##              stanchion every sixth step. The stair is equipped rather than patched — the
##              second curve is for the hand, and it is the only value that answers the body
##              instead of the geometry.
##   posts      a rod from every tread down to the ground. The gap is left open and the
##              structure the helix would actually need is shown instead: the wave's own
##              shadow, cast as eighty vertical lines.
##
## The helix, the modulation and the treads are identical in all four. What changes is what
## the artifact is willing to add around a formula it cannot walk on.
@export_enum("membrane", "none", "rail", "posts") var provision: String = "membrane"
const PROVISIONS: PackedStringArray = ["membrane", "none", "rail", "posts"]

var _mat_step: StandardMaterial3D
var _mat_plane: StandardMaterial3D

func _ready() -> void:
	_read_dna_meta()
	_mat_step = _make_step_mat()
	_mat_plane = _make_plane_mat()
	_build()


## The grid sets `config_*` metadata BEFORE add_child, so this runs ahead of the build and an
## unknown word keeps the default. No metadata, no change.
func _read_dna_meta() -> void:
	if has_meta("config_provision"):
		var p: String = str(get_meta("config_provision")).strip_edges().to_lower()
		provision = p if PROVISIONS.has(p) else provision

# ----------------- Build -----------------
func _build() -> void:
	# clear
	for c in get_children():
		c.queue_free()

	var data := _compute_samples()

	# keep roots & spans so we can bridge after we know both steps
	var roots: Array[Node3D] = []
	var spans: Array[float] = []

	var steps_root := Node3D.new()
	steps_root.name = "StairSteps"
	add_child(steps_root)

	for i in range(data.size()):
		var current = data[i]
		var prev = data[max(i - 1, 0)]
		var nxt = data[min(i + 1, data.size() - 1)]

		var current_pos: Vector3 = current.position
		var prev_pos: Vector3 = prev.position
		var nxt_pos: Vector3 = nxt.position

		var root := Node3D.new()
		root.name = "Step_%03d" % i
		root.position = current_pos

		# local axes: x = radial (width), y = up, z = tangent (depth)
		var radial := Vector3(current_pos.x, 0, current_pos.z).normalized()
		var tangent := (nxt_pos - prev_pos); tangent.y = 0.0
		if tangent.length() < 0.001:
			tangent = Vector3(-radial.z, 0, radial.x)
		tangent = tangent.normalized()
		root.basis = Basis(radial, Vector3.UP, tangent).orthonormalized()
		steps_root.add_child(root)

		# span (depth) around the helix; enforce minimum
		var forward_span := (nxt_pos - current_pos); forward_span.y = 0.0
		var backward_span := (current_pos - prev_pos); backward_span.y = 0.0
		var span := 0.5 * forward_span.length() + 0.5 * backward_span.length()
		if span < MIN_STEP_DEPTH:
			span = MIN_STEP_DEPTH

		# mesh
		var m := BoxMesh.new()
		m.size = Vector3(STEP_WIDTH, STEP_THICKNESS, span * 1.35)
		var mi := MeshInstance3D.new()
		mi.mesh = m
		mi.material_override = _mat_step
		root.add_child(mi)

		# collider
		var body := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		var bs := BoxShape3D.new(); bs.size = m.size
		cs.shape = bs
		body.add_child(cs)
		root.add_child(body)

		roots.append(root)
		spans.append(span)

		# when we have current & previous, add the plane bridge between their facing edges
		# (PROVISION gate: "membrane" is the default, so this condition is unchanged on the
		# legacy path — the other three values withhold the patch and add their own answer
		# in the appended block below.)
		if show_planes and provision == "membrane" and i > 0:
			_add_plane_bridge(roots[i - 1], spans[i - 1], roots[i], spans[i])

	if show_center_pole:
		_add_center_pole(float(STEP_COUNT - 1) * STEP_RISE + 1.0)

	# PROVISION dressing, appended LAST so every child index and position above is untouched
	# on the legacy path. "membrane" and "none" both fall through and add nothing at all —
	# the difference between them was already made by the gate on the bridge planes.
	match provision:
		"rail":
			for si in range(roots.size()):
				_provision_rail(roots[si], spans[si], si)
		"posts":
			for si in range(roots.size()):
				_provision_post(roots[si])
		_:
			pass

# ----------------- Plane bridge (edge-to-edge) -----------------
func _add_plane_bridge(a_root: Node3D, a_span: float, b_root: Node3D, b_span: float) -> void:
	# --- compute facing edges in WORLD space (unchanged logic) ---
	var b_world := b_root.global_transform.origin
	var a_dir_local := a_root.to_local(b_world)
	var a_sign := signf(a_dir_local.z); if a_sign == 0.0: a_sign = 1.0

	var a_edge_center := a_root.to_global(Vector3(0, STEP_THICKNESS * 0.5, a_sign * (a_span * 0.5)))
	var a_left  := a_edge_center + a_root.basis.x * (-STEP_WIDTH * 0.5)
	var a_right := a_edge_center + a_root.basis.x * ( STEP_WIDTH * 0.5)

	var a_world := a_root.global_transform.origin
	var b_dir_local := b_root.to_local(a_world)
	var b_sign := signf(b_dir_local.z); if b_sign == 0.0: b_sign = -1.0

	# near edge on B (opposite sign so it's the edge facing A)
	var b_edge_center := b_root.to_global(Vector3(0, STEP_THICKNESS * 0.5, -b_sign * (b_span * 0.5)))
	var b_left  := b_edge_center + b_root.basis.x * (-STEP_WIDTH * 0.5)
	var b_right := b_edge_center + b_root.basis.x * ( STEP_WIDTH * 0.5)

	# --- build quad (two tris) in WORLD space ---
	var verts_world := PackedVector3Array([a_left, a_right, b_right,  a_left, b_right, b_left])

	# --- convert verts to STAIRCASE-LOCAL space so children align with this node ---
	var to_local: Transform3D = self.global_transform.affine_inverse()
	var verts_local := PackedVector3Array()
	verts_local.resize(verts_world.size())
	for i in range(verts_world.size()):
		verts_local[i] = to_local * verts_world[i]
		verts_local[i].y += COLLIDER_HEIGHT_OFFSET  # lift a tad so it sits on the tread

	# --- visible plane (local space) ---
	var am := ArrayMesh.new()
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts_local
	var n := (verts_local[1] - verts_local[0]).cross(verts_local[5] - verts_local[0]).normalized()
	arr[Mesh.ARRAY_NORMAL] = PackedVector3Array([n, n, n, n, n, n])
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)

	var plane := MeshInstance3D.new()
	plane.name = "BridgePlane"
	plane.mesh = am
	plane.material_override = _mat_plane
	add_child(plane)

	# --- matching collider (same local verts) ---
	var body := StaticBody3D.new()
	body.name = "BridgeCollider"
	var col := CollisionShape3D.new()
	var shape := ConcavePolygonShape3D.new()
	shape.data = verts_local
	col.shape = shape
	body.add_child(col)
	add_child(body)

	if debug:
		print("Bridge plane added between:", a_root.name, " <-> ", b_root.name)


# ----------------- Helpers -----------------
class StepSample:
	var position: Vector3
	func _init(p: Vector3) -> void:
		position = p

func _compute_samples() -> Array:
	var out: Array = []
	var denom = max(1, STEP_COUNT - 1)
	for i in range(STEP_COUNT):
		var t := float(i) / float(denom)
		var ang := t * TOTAL_TURNS * TAU
		var wave := sin(ang * WAVE_FREQUENCY) * WAVE_AMPLITUDE
		var r := BASE_RADIUS + WALKWAY_OFFSET + wave
		var top := float(i) * STEP_RISE
		var center_y := top - STEP_THICKNESS * 0.5
		out.append(StepSample.new(Vector3(cos(ang) * r, center_y, sin(ang) * r)))
	return out

func _add_center_pole(h: float) -> void:
	var m := CylinderMesh.new()
	m.top_radius = BASE_RADIUS
	m.bottom_radius = BASE_RADIUS
	m.height = h
	var mi := MeshInstance3D.new()
	mi.mesh = m
	mi.position.y = h * 0.5
	add_child(mi)

	# collider
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = BASE_RADIUS
	shape.height = h
	cs.shape = shape
	body.add_child(cs)
	body.position = mi.position
	add_child(body)

func _make_step_mat() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.85, 0.85, 0.85)
	m.roughness = 0.6
	return m

func _make_plane_mat() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(1.0, 0.2, 1.0, 0.25)  # pink, semi-transparent
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_ALWAYS
	m.render_priority = 1
	return m

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	# Only the DNA axis is read here; every other key is ignored exactly as before. The grid
	# calls this deferred, after _ready, so _read_dna_meta has normally applied the same
	# value already and the guard below makes this a no-op. _mat_step is the proof that
	# _ready has run — rebuilding before it would build the stair with a null material.
	if config.has("provision"):
		var p: String = str(config["provision"]).strip_edges().to_lower()
		var picked: String = p if PROVISIONS.has(p) else provision
		if picked != provision:
			provision = picked
			if _mat_step != null:
				_build()


# ── PROVISION ────────────────────────────────────────────────────────────────────────────
# Appended LAST. Both new values build in STAIRCASE-LOCAL space from the tread roots the
# main loop already produced, so they cannot disturb the helix itself.

## RAIL — a handrail segment on the outer edge of each tread at hand height, parented to the
## tread root so it inherits the tread's radial/tangent basis and the segments chain into one
## continuous curve. Every sixth tread also gets a stanchion, which is what makes it read as
## a built handrail rather than a floating second helix.
func _provision_rail(root: Node3D, span: float, index: int) -> void:
	var out_x: float = STEP_WIDTH * 0.5 - 0.10
	var bar := BoxMesh.new()
	bar.size = Vector3(0.09, 0.09, maxf(span * 1.6, 0.2))
	var mi := MeshInstance3D.new()
	mi.name = "RailSegment"
	mi.mesh = bar
	mi.material_override = _mat_step
	mi.position = Vector3(out_x, 0.95, 0.0)
	root.add_child(mi)
	if index % 6 == 0:
		var stanchion := BoxMesh.new()
		stanchion.size = Vector3(0.06, 0.95, 0.06)
		var sm := MeshInstance3D.new()
		sm.name = "RailStanchion"
		sm.mesh = stanchion
		sm.material_override = _mat_step
		sm.position = Vector3(out_x, 0.475, 0.0)
		root.add_child(sm)


## POSTS — a rod from each tread down to the ground plane of the first tread. Added to the
## staircase itself rather than to the tread root, because a post must stand vertical while
## the tread is banked to the helix.
func _provision_post(root: Node3D) -> void:
	var base: float = -STEP_THICKNESS * 0.5
	var h: float = maxf(root.position.y - base, 0.04)
	var rod := BoxMesh.new()
	rod.size = Vector3(0.10, h, 0.10)
	var mi := MeshInstance3D.new()
	mi.name = "ProvisionPost"
	mi.mesh = rod
	mi.material_override = _mat_step
	mi.position = Vector3(root.position.x, base + h * 0.5, root.position.z)
	add_child(mi)
