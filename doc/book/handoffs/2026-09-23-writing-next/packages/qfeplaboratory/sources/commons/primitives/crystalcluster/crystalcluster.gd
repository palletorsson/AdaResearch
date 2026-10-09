# CrystalCluster.gd - Multiple small crystals arranged in a cluster
extends Node3D

# @identity
# essence: five hexagonal-prism crystals, each SurfaceTool triangles with face-center normals, scattered by a per-crystal seeded RNG (seed = i*42) so the "randomness" is identical every run; skinned with the SimpleGrid wireframe shader
# desire: to show that a cluster reads as organic even though every position and rotation is fixed — deterministic seeding makes chance repeatable
# critical_parameter: growth — HOW the five relate to each other. scatter is a frozen roll of the dice; lattice is the λ=0 claim taken literally; druse is a single event radiating from one nucleation point; vein is a seam. Same five crystals, four different accounts of what order is.
# triggers: create_crystal_cluster on _ready builds 5 crystals; each gets a fresh RandomNumberGenerator seeded by its index; apply_grid_config re-grows the cluster when growth or facet changes; set_base_color re-skins every child
# emerges: that "random arrangement" and "fixed arrangement" can be the same thing — a seed is a frozen roll of the dice; and that arrangement, not material, is what makes a pile of crystals read as ordered or found
# needs: 5 hex-prism crystals [has]; deterministic layout [has]; wireframe material [has]; apply_grid_config [has]; configurable crystal count [missing — hardcoded 5]
# relationships: sibling to crystal and diamond (single mesh primitives) — a cluster is what happens when you repeat a primitive under jitter; shares the SimpleGrid shader with the grid family
# truth: a seed turns chance into a decision you can repeat — the cluster looks scattered because it was told exactly how to scatter

# --- DNA (promoted 2026-07-29, stage 2) -------------------------------------
# growth: how the five crystals relate to one another — the macro order.
#   scatter (shipped) jittered position + free rotation, deterministic per index
#   druse    all five sprout outward from one nucleation point
#   lattice  an evenly spaced row, no rotation at all — pure order, stated plainly
#   vein     strung along a single seam, spun only about their own axis
# facet: the form of one crystal — the micro order.
#   taper (shipped) hex prism narrowing to 0.7 of its base
#   point    narrows almost to an apex — a terminated quartz point
#   column   no narrowing at all — a basalt column
#   blade    flattened on one axis — a bladed habit
const GROWTHS: Array = ["scatter", "druse", "lattice", "vein"]
const FACETS: Array = ["taper", "point", "column", "blade"]

@export_enum("scatter", "druse", "lattice", "vein") var growth: String = "scatter"
@export_enum("taper", "point", "column", "blade") var facet: String = "taper"

var base_color: Color = Color(0.0, 0.4, 1.0)  # Blue from pride colors

# Only nodes this script made — the scene also carries a Camera3D we must not touch.
var _owned: Array[Node] = []
var _built: bool = false

func _ready():
	create_crystal_cluster()
	_built = true

func create_crystal_cluster():
	# Create multiple small crystals
	for i in range(5):
		var crystal = create_single_crystal(randf_range(0.1, 0.25))
		var crystal_node = Node3D.new()
		crystal_node.name = "Crystal_%d" % i
		crystal_node.add_child(crystal)

		# Position crystals deterministically for consistency
		var rng = RandomNumberGenerator.new()
		rng.seed = i * 42  # Deterministic seeding

		_place_crystal(crystal_node, i, rng)

		apply_queer_material(crystal, base_color)
		_owned.append(crystal_node)
		add_child(crystal_node)

## The growth axis. `scatter` reproduces the shipped draw order exactly — same
## rng, same six calls, same values — so existing placements are untouched.
func _place_crystal(crystal_node: Node3D, i: int, rng: RandomNumberGenerator) -> void:
	match growth:
		"druse":
			# One nucleation point; every crystal leans away from it.
			var dir: Vector3 = Vector3(
				rng.randf_range(-1.0, 1.0),
				rng.randf_range(0.2, 1.0),
				rng.randf_range(-1.0, 1.0)
			).normalized()
			var ref: Vector3 = Vector3.RIGHT if abs(dir.x) < 0.9 else Vector3.FORWARD
			var x_axis: Vector3 = ref.cross(dir).normalized()
			var z_axis: Vector3 = x_axis.cross(dir).normalized()
			crystal_node.transform.basis = Basis(x_axis, dir, z_axis)
			crystal_node.position = dir * 0.12
		"lattice":
			# The λ=0 claim taken literally: evenly spaced, all facing the same way.
			crystal_node.position = Vector3((float(i) - 2.0) * 0.11, 0.0, 0.0)
			crystal_node.rotation_degrees = Vector3.ZERO
		"vein":
			# A seam through rock — strung on one line, spun only about their axis.
			var t: float = float(i) / 4.0
			var seam_x: float = -0.24 + 0.48 * t
			var seam_y: float = -0.08 + 0.16 * t
			crystal_node.position = Vector3(
				seam_x,
				seam_y,
				rng.randf_range(-0.03, 0.03)
			)
			crystal_node.rotation_degrees = Vector3(0.0, rng.randf_range(0, 360), 20.0)
		_:
			# scatter — the shipped path, byte for byte.
			crystal_node.position = Vector3(
				rng.randf_range(-0.2, 0.2),
				rng.randf_range(-0.1, 0.1),
				rng.randf_range(-0.2, 0.2)
			)
			crystal_node.rotation_degrees = Vector3(
				rng.randf_range(0, 360),
				rng.randf_range(0, 360),
				rng.randf_range(0, 360)
			)

## The facet axis, as (top radius ratio, width scale on X).
## taper returns (0.7, 1.0) — the shipped hex prism.
func _facet_profile() -> Vector2:
	match facet:
		"point":
			return Vector2(0.06, 1.0)
		"column":
			return Vector2(1.0, 1.0)
		"blade":
			return Vector2(0.5, 0.35)
		_:
			return Vector2(0.7, 1.0)

func create_single_crystal(size: float) -> MeshInstance3D:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Hexagonal prism crystal
	var vertices = []
	var height: float = size * 1.5
	var profile: Vector2 = _facet_profile()
	var top_ratio: float = profile.x
	var flatten: float = profile.y

	# Bottom hex
	for i in range(6):
		var angle: float = i * PI / 3.0
		vertices.append(Vector3(cos(angle) * size * flatten, -height/2, sin(angle) * size))

	# Top hex
	for i in range(6):
		var angle: float = i * PI / 3.0
		vertices.append(Vector3(cos(angle) * size * top_ratio * flatten, height/2, sin(angle) * size * top_ratio))

	# Create faces
	# Bottom
	for i in range(4):
		add_triangle_with_normal(st, vertices, [0, i + 1, i + 2])

	# Top
	for i in range(4):
		add_triangle_with_normal(st, vertices, [6, 7 + i, 8 + i])

	# Sides
	for i in range(6):
		var next_i = (i + 1) % 6
		add_triangle_with_normal(st, vertices, [i, next_i, 6 + next_i])
		add_triangle_with_normal(st, vertices, [i, 6 + next_i, 6 + i])

	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = st.commit()
	mesh_instance.name = "SingleCrystal"
	return mesh_instance

# Helper function to add triangle with calculated normal
func add_triangle_with_normal(st: SurfaceTool, vertices: Array, face: Array):
	var v0 = vertices[face[0]]
	var v1 = vertices[face[1]]
	var v2 = vertices[face[2]]

	var face_center = (v0 + v1 + v2) / 3.0
	var normal = face_center.normalized()

	st.set_normal(normal)
	st.add_vertex(v0)
	st.set_normal(normal)
	st.add_vertex(v1)
	st.set_normal(normal)
	st.add_vertex(v2)

func apply_queer_material(mesh_instance: MeshInstance3D, color: Color):
	# Create shader material using the solid wireframe shader
	var material = ShaderMaterial.new()
	var shader = load("res://commons/resourses/shaders/SimpleGrid.gdshader")
	if shader:
		material.shader = shader

		# Set shader parameters
		material.set_shader_parameter("base_color", color)
		material.set_shader_parameter("edge_color", Color.WHITE)
		material.set_shader_parameter("edge_width", 1.5)
		material.set_shader_parameter("edge_sharpness", 2.0)
		material.set_shader_parameter("emission_strength", 1.0)

		mesh_instance.material_override = material
	else:
		# Fallback to standard material if shader not found
		var standard_material = StandardMaterial3D.new()
		standard_material.albedo_color = color
		standard_material.emission_enabled = true
		standard_material.emission = color * 0.3
		mesh_instance.material_override = standard_material

func set_base_color(color: Color):
	base_color = color
	# Apply to all child crystals this script made
	for child in _owned:
		if not is_instance_valid(child):
			continue
		if child.get_child_count() == 0:
			continue
		var crystal_mesh = child.get_child(0) as MeshInstance3D
		if crystal_mesh:
			apply_queer_material(crystal_mesh, base_color)

# --- Grid config ------------------------------------------------------------

## Grid hook. Rebuilds ONLY when an axis actually changed and only after _ready
## has grown the cluster once — an unguarded rebuild here would wipe the
## shipped placements on the first config call.
func apply_grid_config(config_data: Dictionary) -> void:
	var before_growth: String = growth
	var before_facet: String = facet

	if config_data.has("growth"):
		growth = _pick_axis(str(config_data["growth"]), GROWTHS, growth)
	if config_data.has("facet"):
		facet = _pick_axis(str(config_data["facet"]), FACETS, facet)

	if not _built:
		return
	if growth == before_growth and facet == before_facet:
		return
	_rebuild_now()

## Accept an axis value only if it names something we actually build.
func _pick_axis(raw: String, allowed: Array, fallback: String) -> String:
	var v: String = raw.strip_edges().to_lower()
	for a in allowed:
		if str(a).to_lower() == v:
			return str(a)
	return fallback

func _rebuild_now() -> void:
	for c in _owned:
		if is_instance_valid(c):
			remove_child(c)
			c.queue_free()
	_owned.clear()
	create_crystal_cluster()
