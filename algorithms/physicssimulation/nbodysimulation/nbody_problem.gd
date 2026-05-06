extends Node3D

## N-Body Gravitational Simulation — 3D
## Bodies attract each other via Newton's gravity (F = G*M*m / r^2).
## Rendered with MultiMeshInstance3D for bodies, ImmediateMesh for force lines.
##
## @identity
## essence: F = G*m1*m2/r^2 for all pairs. O(n^2) pairwise gravity. Every body pulls every other. The computational cost of democracy.
## desire: To summon a miniature galaxy — 20 bodies collapsing, orbiting, scattering — and see the force lines connecting the strongest gravitational relationships.
## critical_parameter: g_constant (0.0001) — the universal coupling. Too high → everything collapses to a point. Too low → bodies drift apart. The sweet spot creates structure.
## triggers: Automatic — all pairs attract every frame, positions update, MultiMesh syncs, top-20 strongest force lines drawn as fading blue connections
## emerges: Clustering — bodies clumping into gravitational groups. Binary pairs forming and dissolving. The force line network revealing gravitational structure.
## needs: MultiMesh body rendering [has], force line visualization [has]. Missing: VR grabbable bodies, Barnes-Hut tree optimization, mass merging on collision.
## relationships: Scales up three_body_problem (3 → 20). The O(n^2) cost motivates Barnes-Hut trees. Lives in ForcesChaos. Force lines preview graph theory concepts (forcedirected3d).
## truth: Gravity is the simplest force and the hardest computation. N bodies, N^2 interactions. Complexity comes from counting, not from the law.

class_name GravitationalSimulation

# Simulation settings
@export var num_bodies: int = 20
@export var random_velocity_range: float = 0.002
@export var spawn_radius: float = 0.35

# Body properties
@export var min_mass: float = 0.005
@export var max_mass: float = 0.03
@export var g_constant: float = 0.0001  # Gravitational constant (scaled for 3D/meters)

# Data-driven bodies: Array of Dictionaries
# Each: { pos: Vector3, vel: Vector3, acc: Vector3, mass: float, radius: float, color: Color }
var bodies: Array[Dictionary] = []

# Rendering
var multi_mesh: MultiMesh
var multi_mesh_instance: MultiMeshInstance3D

var force_mesh: ImmediateMesh
var force_instance: MeshInstance3D
var force_material: StandardMaterial3D

var label: Label3D

func _ready() -> void:
	_build_force_lines()
	_build_label()
	_create_bodies()
	_build_multi_mesh()

func _build_force_lines() -> void:
	force_mesh = ImmediateMesh.new()
	force_instance = MeshInstance3D.new()
	force_instance.mesh = force_mesh
	force_material = StandardMaterial3D.new()
	force_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	force_material.vertex_color_use_as_albedo = true
	force_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	force_material.no_depth_test = true
	add_child(force_instance)

func _build_label() -> void:
	label = Label3D.new()
	label.text = "N-Body Gravity"
	label.font_size = 32
	label.pixel_size = 0.001
	label.position = Vector3(0.0, 0.5, 0.0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color(1.0, 1.0, 1.0, 0.9)
	label.no_depth_test = true
	add_child(label)

func _create_bodies() -> void:
	bodies.clear()
	for i in range(num_bodies):
		var pos := Vector3(
			randf_range(-spawn_radius, spawn_radius),
			randf_range(-spawn_radius, spawn_radius),
			randf_range(-spawn_radius, spawn_radius)
		)
		var vel := Vector3(
			randf_range(-random_velocity_range, random_velocity_range),
			randf_range(-random_velocity_range, random_velocity_range),
			randf_range(-random_velocity_range, random_velocity_range)
		)
		var mass := randf_range(min_mass, max_mass)
		var radius := sqrt(mass) * 0.15
		# Color based on mass: lighter = more massive
		var t := (mass - min_mass) / maxf(max_mass - min_mass, 0.001)
		var color := Color(0.4 + t * 0.5, 0.5 + t * 0.3, 0.9 - t * 0.3, 0.85)
		bodies.append({
			"pos": pos,
			"vel": vel,
			"acc": Vector3.ZERO,
			"mass": mass,
			"radius": radius,
			"color": color,
		})

func _build_multi_mesh() -> void:
	var sphere := SphereMesh.new()
	sphere.radius = 1.0
	sphere.height = 2.0
	sphere.radial_segments = 10
	sphere.rings = 6

	multi_mesh = MultiMesh.new()
	multi_mesh.transform_format = MultiMesh.TRANSFORM_3D
	multi_mesh.use_colors = true
	multi_mesh.mesh = sphere
	multi_mesh.instance_count = num_bodies

	# Material
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.emission = Color(0.5, 0.6, 0.8)
	mat.emission_energy_multiplier = 0.4
	sphere.material = mat

	multi_mesh_instance = MultiMeshInstance3D.new()
	multi_mesh_instance.multimesh = multi_mesh
	add_child(multi_mesh_instance)

	_sync_multimesh()

func _process(_delta: float) -> void:
	# Apply gravitational attraction between all pairs
	for i in range(bodies.size()):
		for j in range(bodies.size()):
			if i != j:
				_attract(bodies[i], bodies[j])

	# Update positions
	for body in bodies:
		body["vel"] += body["acc"]
		body["pos"] += body["vel"]
		body["acc"] = Vector3.ZERO

	_sync_multimesh()
	_draw_force_lines()

func _attract(attractor: Dictionary, body: Dictionary) -> void:
	# Gravitational force: attractor pulls body toward it
	var force_dir: Vector3 = attractor["pos"] - body["pos"]
	var distance: float = force_dir.length()
	# Clamp distance to avoid extreme forces (scaled for 3D meter space)
	distance = clampf(distance, 0.01, 0.15)
	# F = G * M * m / r²
	var strength: float = (g_constant * attractor["mass"] * body["mass"]) / (distance * distance)
	var force: Vector3 = force_dir.normalized() * strength
	# a = F / m
	body["acc"] += force / body["mass"]

func _sync_multimesh() -> void:
	if not multi_mesh:
		return
	for i in range(mini(bodies.size(), multi_mesh.instance_count)):
		var body: Dictionary = bodies[i]
		var t := Transform3D()
		var r: float = body["radius"]
		t = t.scaled(Vector3(r, r, r))
		t.origin = body["pos"]
		multi_mesh.set_instance_transform(i, t)
		multi_mesh.set_instance_color(i, body["color"])

func _draw_force_lines() -> void:
	force_mesh.clear_surfaces()
	var n := bodies.size()
	if n < 2:
		return

	# Collect all pair forces, pick top 20 strongest
	var pairs: Array[Dictionary] = []
	for i in range(n):
		for j in range(i + 1, n):
			var diff: Vector3 = bodies[i]["pos"] - bodies[j]["pos"]
			var dist: float = maxf(diff.length(), 0.01)
			var strength: float = (g_constant * bodies[i]["mass"] * bodies[j]["mass"]) / (dist * dist)
			pairs.append({"i": i, "j": j, "s": strength})

	# Sort descending by strength
	pairs.sort_custom(func(a, b): return a["s"] > b["s"])

	var draw_count := mini(pairs.size(), 20)

	force_mesh.surface_begin(Mesh.PRIMITIVE_LINES, force_material)
	for k in range(draw_count):
		var pair: Dictionary = pairs[k]
		var alpha: float = lerpf(0.4, 0.08, float(k) / maxf(float(draw_count - 1), 1.0))
		var c := Color(0.5, 0.7, 1.0, alpha)
		force_mesh.surface_set_color(c)
		force_mesh.surface_add_vertex(bodies[pair["i"]]["pos"])
		force_mesh.surface_set_color(c)
		force_mesh.surface_add_vertex(bodies[pair["j"]]["pos"])
	force_mesh.surface_end()

func _exit_tree() -> void:
	bodies.clear()
	if force_mesh:
		force_mesh.clear_surfaces()
	if multi_mesh:
		multi_mesh.instance_count = 0

func apply_grid_config(config: Dictionary) -> void:
	pass
