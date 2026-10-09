# rigid_sculpture.gd
# QFEP φ < 0 Visualization - Rigid Sculpture
# Conservative: resists change, preserves pattern
# Static, frozen, crystalline structure

extends Node3D

class_name QFEPRigidSculpture

# @identity
# essence: octahedron_center + element_count prisms placed by `formation` + caps -> crystalline sculpture, no _process
# desire: confront a form that refuses to move — perfect geometry locked in metallic purple
# critical_parameter: formation — WHICH order the monument keeps. The absence of animation is the other half, and it is not a parameter: there is no _process to turn off
# triggers: nothing at runtime — the sculpture is immune to time; apply_grid_config re-lays the elements when formation, count, size or colour changes
# emerges: nothing emerges — and that absence is the lesson
# needs: no VR controls — rigidity is the interaction [has]
# relationships: contrasts fluid_form (phi>0 vs phi<0); paired with preserved_pattern; represents conservative resistance to change; shares the word `formation` with reactive_particle_field
# truth: negative phi crystallizes form into monument — the rigid sculpture is beautiful and dead

# --- STAGE-2 DNA (promoted 2026-08-04) ---------------------------------------
# formation: where the elements stand relative to one another — the order this
# monument defends. Same eight prisms every time; five accounts of what order is.
#   ring (shipped) one circle at radius size*0.6, each prism turned to face outward —
#                  a centre defended on all sides
#   lattice        a square grid with the core in the middle cell, every prism aligned —
#                  repetition without privilege, the bureaucratic order
#   shell          spread over a sphere on a golden-angle spiral, each pointing out —
#                  a reliquary, order closed in every direction
#   column         stacked on one vertical axis under a fixed quarter-turn screw —
#                  order as rank
#   drift          the ring displaced by a deterministic per-index jitter — a monument
#                  that has weathered and has not moved since
#
# THE WORD IS BORROWED, CHARACTER FOR CHARACTER. `formation` = lattice|shell|ring|
# column|drift is reactive_particle_field's axis (which four qfep registry tokens share
# from one scene) and delaunay_triangulation_3d_cell's. Same five words, same question:
# where a set of small elements stands relative to one another. Only the DEFAULT differs,
# because this artifact's shipped arrangement is the ring and theirs is the lattice — so
# this sculpture can be COMPARED with those five rather than merely contrasted.
#
# NOT `growth` (crystal_cluster's scatter|druse|lattice|vein), although that artifact is
# the nearest thing in the registry and was hand-promoted for the same reason. `growth`
# asks how a mineral GREW; its four values are mineralogical events. This is a made
# monument, not a specimen — it argues about imposed order, not deposition — and its
# shipped arrangement, a ring, is not among growth's four values. Different question,
# different word.
const FORMATIONS: PackedStringArray = ["lattice", "shell", "ring", "column", "drift"]

## Which order the monument keeps. `ring` is the shipped arrangement.
@export_enum("lattice", "shell", "ring", "column", "drift") var formation: String = "ring"

## Sculpture size
@export var size: float = 0.4

## Number of elements
@export var element_count: int = 8

## Conservative color (purple)
@export var rigid_color: Color = Color(0.6, 0.3, 0.7, 1.0)

# Internal
var _elements: Array[MeshInstance3D] = []
var _built: bool = false

func _ready() -> void:
	_read_dna_meta()
	_build_sculpture()
	_built = true

# GridInteractablesComponent sets `config_*` metadata BEFORE add_child, so this runs
# ahead of the build. An unknown word keeps the default: an axis must never be able to
# blank an artifact by typo.
func _read_dna_meta() -> void:
	if has_meta("config_formation"):
		var f_in: String = str(get_meta("config_formation")).strip_edges().to_lower()
		formation = f_in if FORMATIONS.has(f_in) else formation
	if has_meta("config_element_count"):
		element_count = maxi(1, int(str(get_meta("config_element_count"))))
	if has_meta("config_size"):
		size = float(str(get_meta("config_size")))

func _build_sculpture() -> void:
	# Create a crystalline structure - rigid, angular, frozen
	var mat = StandardMaterial3D.new()
	mat.albedo_color = rigid_color
	mat.emission_enabled = true
	mat.emission = rigid_color
	mat.emission_energy_multiplier = 0.3
	mat.metallic = 0.8
	mat.roughness = 0.2

	# Central octahedron
	var center = MeshInstance3D.new()
	var center_mesh = _create_octahedron(size * 0.5)
	center.mesh = center_mesh
	center.material_override = mat
	add_child(center)
	_elements.append(center)

	# Surrounding prisms - fixed positions, no variation
	for i in range(element_count):
		var element = MeshInstance3D.new()
		var prism = PrismMesh.new()
		prism.size = Vector3(size * 0.15, size * 0.4, size * 0.15)
		element.mesh = prism
		element.material_override = mat

		_place_element(element, i)

		add_child(element)
		_elements.append(element)

	# Top and bottom caps
	for y_mult in [-1, 1]:
		var cap = MeshInstance3D.new()
		var cap_mesh = _create_octahedron(size * 0.2)
		cap.mesh = cap_mesh
		cap.material_override = mat
		cap.position.y = size * 0.5 * y_mult
		add_child(cap)
		_elements.append(cap)

## The formation axis. The `_:` branch is `ring` — the shipped arrangement, line for
## line, same angle, same radius, same outward turn — so the existing placement in
## QFEP_Phi_Term is vertex-for-vertex unchanged.
func _place_element(element: MeshInstance3D, i: int) -> void:
	match formation:
		"lattice":
			var cols: int = int(ceil(sqrt(float(element_count + 1))))
			if cols < 2:
				cols = 2
			var step: float = size * 0.6
			var half: float = (float(cols) - 1.0) * 0.5
			var slot: int = i
			# Leave the middle cell to the central octahedron.
			if cols % 2 == 1 and slot >= (cols * cols - 1) / 2:
				slot += 1
			element.position = Vector3(
				(float(slot % cols) - half) * step,
				0.0,
				(float(slot / cols) - half) * step
			)
			element.rotation = Vector3.ZERO
		"shell":
			var n: float = float(maxi(element_count, 1))
			var yy: float = 1.0 - (float(i) + 0.5) * 2.0 / n
			var r_xz: float = sqrt(maxf(0.0, 1.0 - yy * yy))
			var theta: float = float(i) * 2.3999632297
			_aim_outward(element, Vector3(cos(theta) * r_xz, yy, sin(theta) * r_xz), size * 0.6)
		"column":
			var span: float = float(maxi(element_count - 1, 1))
			element.position = Vector3(0.0, (float(i) / span - 0.5) * size * 2.0, 0.0)
			element.rotation = Vector3(0.0, float(i) * PI * 0.25, 0.0)
		"drift":
			# Deterministic per index — the shipped code contains no randomness at all,
			# and an unseeded draw here would make five variants of five objects.
			var rng := RandomNumberGenerator.new()
			rng.seed = i * 137 + 11
			var a_d: float = (float(i) / element_count) * TAU
			var r_d: float = size * 0.6
			element.position = Vector3(
				cos(a_d) * r_d + rng.randf_range(-0.18, 0.18) * size,
				rng.randf_range(-0.3, 0.3) * size,
				sin(a_d) * r_d + rng.randf_range(-0.18, 0.18) * size
			)
			element.rotation = Vector3(
				rng.randf_range(-0.5, 0.5),
				-a_d + rng.randf_range(-0.7, 0.7),
				rng.randf_range(-0.5, 0.5)
			)
		_:
			# ring — the shipped path.
			var angle: float = (float(i) / element_count) * TAU
			var radius: float = size * 0.6
			element.position = Vector3(
				cos(angle) * radius,
				0,
				sin(angle) * radius
			)
			# Point outward
			element.rotation.y = -angle

## Stand a prism at `dist` along `dir` with its long (+Y) axis pointing outward.
func _aim_outward(node: Node3D, dir: Vector3, dist: float) -> void:
	var d: Vector3 = dir.normalized()
	if d.length_squared() < 0.0001:
		node.position = Vector3.ZERO
		return
	var ref: Vector3 = Vector3.RIGHT if abs(d.x) < 0.9 else Vector3.FORWARD
	var x_axis: Vector3 = ref.cross(d).normalized()
	var z_axis: Vector3 = x_axis.cross(d).normalized()
	node.transform.basis = Basis(x_axis, d, z_axis)
	node.position = d * dist

func _create_octahedron(s: float) -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Vertices of octahedron
	var top = Vector3(0, s, 0)
	var bottom = Vector3(0, -s, 0)
	var front = Vector3(0, 0, s)
	var back = Vector3(0, 0, -s)
	var left = Vector3(-s, 0, 0)
	var right = Vector3(s, 0, 0)

	# Top 4 faces
	_add_triangle(st, top, front, right)
	_add_triangle(st, top, right, back)
	_add_triangle(st, top, back, left)
	_add_triangle(st, top, left, front)

	# Bottom 4 faces
	_add_triangle(st, bottom, right, front)
	_add_triangle(st, bottom, back, right)
	_add_triangle(st, bottom, left, back)
	_add_triangle(st, bottom, front, left)

	st.generate_normals()
	return st.commit()

func _add_triangle(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	st.add_vertex(a)
	st.add_vertex(b)
	st.add_vertex(c)

# --- Grid config -------------------------------------------------------------

## Grid hook. There was none before, so the axis would have been unreachable from a map
## token — GridInteractablesComponent calls this on the ROOT and fell through to "no
## configuration method found".
##
## GATED BY DATA, TWICE. A config carrying none of these keys returns before touching
## anything, and even a config that carries them rebuilds only when a value actually
## CHANGED and only after _ready has built once. An unguarded rebuild here would wipe
## the shipped placement on the first config call.
func apply_grid_config(config_data: Dictionary) -> void:
	var before_formation: String = formation
	var before_count: int = element_count
	var before_size: float = size
	var before_color: Color = rigid_color

	if config_data.has("formation"):
		var f_in: String = str(config_data["formation"]).strip_edges().to_lower()
		if FORMATIONS.has(f_in):
			formation = f_in
	if config_data.has("element_count"):
		element_count = maxi(1, int(str(config_data["element_count"])))
	if config_data.has("size"):
		size = float(str(config_data["size"]))
	if config_data.has("rigid_color"):
		var c = config_data["rigid_color"]
		if c is Color:
			rigid_color = c
		elif c is String and Color.html_is_valid(str(c)):
			rigid_color = Color.html(str(c))

	if not _built:
		return
	if formation == before_formation \
			and element_count == before_count \
			and is_equal_approx(size, before_size) \
			and rigid_color == before_color:
		return
	_rebuild_now()

func _rebuild_now() -> void:
	for e in _elements:
		if is_instance_valid(e):
			remove_child(e)
			e.queue_free()
	_elements.clear()
	_build_sculpture()

# Rigid sculpture doesn't animate - that's the point!
# It resists change.
