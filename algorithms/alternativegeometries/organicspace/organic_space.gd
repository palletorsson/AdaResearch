extends Node3D

class_name OrganicVRSpace

# @identity
# essence: CSG boolean(sphere, cylinder, box) + FastNoiseLite displacement -> organic cave interior with floating orbs
# desire: to step inside a living space where walls breathe, tunnels curve, and crystals grow from nothing — architecture without architects
# critical_parameter: organic_strength — controls how much noise deforms the base geometry; at 0 it is a sphere, at 1 it is a cave
# triggers: regenerate_space() creates a new random interior; interactive orbs float with tween-driven gentle oscillation
# emerges: CSG boolean subtraction of noisy spheres from the shell creates doorways and alcoves that feel intentional but are accidental
# needs: CSG-to-mesh baking [has]; floating orbs [has]; atmospheric lighting [has]; VR regenerate trigger [missing]
# relationships: paired with branching_growth_algorithm in PG_Branching_Growth; contrasts deterministic growth with noise-sculpted space
# truth: an organic space is not designed from outside — it is what remains after noise has eaten away at geometry from within

## Procedural organic interior space generator for Godot 4 VR
## Inspired by the "Octavia Diva" model interior visualization

@export var space_size: Vector3 = Vector3(20, 15, 20)
@export var detail_level: int = 2  # Lower = more detail
@export var organic_strength: float = 0.8
@export var tunnel_complexity: int = 5
@export var material_variety: int = 4

# ── DNA ───────────────────────────────────────────────────────────────
#
# formation — WHERE THE FORM CAME FROM. Every deformation sphere on the
# shell and every detail bump on a tunnel picks CSG UNION or SUBTRACTION,
# and that single coin flip is the whole argument of the piece: is an
# organic space what accumulated, or what was eaten away? The shipped code
# flips a coin (0.5 on the shell, 0.3 on the tunnel details) and so gets
# both at once, which is a position — it just was never a stated one.
#
#   chance    the shipped coin flip: some bulges, some hollows
#   erode     subtraction only — the truth line taken literally, form as
#             the residue of removal: doorways, alcoves, a chewed shell
#   accrete   union only — form as accumulation: a lumpy budding mass
#   alternate neither chance nor doctrine but rhythm: even index adds,
#             odd index carves, a shell that reads as patterned
#
# cast — WHO IS ON SHOW. The three surface-detail generators are three
# different claims about what "organic" means: membranes (soft sheets),
# crystals (mineral), growths (bulbous flesh). Shipped, all three run at
# once. Word and "all"-plus-one-each shape borrowed verbatim from
# particle_systems.cast, which asks the same question of its emitters.

## Where the form came from: chance / erosion / accretion / rhythm.
@export_enum("chance", "erode", "accrete", "alternate") var formation: String = "chance"
## Which family of natural form fills the space.
@export_enum("all", "membrane", "crystal", "growth") var cast: String = "all"
## Pins the generator. 0 = a fresh space every run — what every existing
## placement gets, and what the shipped code has always done.
@export var form_seed: int = 0

const FORMATIONS := ["chance", "erode", "accrete", "alternate"]
const CASTS := ["all", "membrane", "crystal", "growth"]

# Every draw in this file goes through here so a pinned form_seed makes the
# space reproducible. Unpinned it is randomize()d, which is exactly the
# global RNG's shipped behaviour.
var _rng := RandomNumberGenerator.new()
var _built: bool = false

# Components
var mesh_generator: OrganicMeshGenerator
var lighting_system: OrganicLighting
var material_manager: OrganicMaterials

# Main container for generated geometry
var environment_container: Node3D

func _ready() -> void:
	setup_components()
	generate_organic_space()

func setup_components() -> void:
	# Create main container
	environment_container = Node3D.new()
	environment_container.name = "OrganicEnvironment"
	add_child(environment_container)
	
	# Initialize systems
	mesh_generator = OrganicMeshGenerator.new()
	lighting_system = OrganicLighting.new()
	material_manager = OrganicMaterials.new()
	
	add_child(mesh_generator)
	add_child(lighting_system)
	add_child(material_manager)

func generate_organic_space() -> void:
	print("Generating organic VR space...")

	_seed_rng()

	# Generate base shell using marching cubes-style approach
	generate_base_shell()

	# Add organic tunnels and chambers
	generate_tunnel_system()

	# Create surface details and textures
	generate_surface_details()

	# Bake CSG to static meshes (CSG is expensive to keep at runtime)
	_bake_csg_to_meshes()

	# Add atmospheric lighting
	setup_atmospheric_lighting()

	# Add interactive elements
	generate_interactive_elements()

	_built = true


func _seed_rng() -> void:
	if form_seed != 0:
		_rng.seed = form_seed
	else:
		_rng.randomize()


# UNION or SUBTRACTION for one deformation, under the declared formation.
# `coin_bias` is the shipped threshold at this call site, so "chance"
# reproduces the old expression exactly.
func _op_for(index: int, coin_bias: float) -> int:
	match formation:
		"erode":
			return CSGShape3D.OPERATION_SUBTRACTION
		"accrete":
			return CSGShape3D.OPERATION_UNION
		"alternate":
			return CSGShape3D.OPERATION_UNION if index % 2 == 0 else CSGShape3D.OPERATION_SUBTRACTION
		_:
			return CSGShape3D.OPERATION_UNION if _rng.randf() > coin_bias else CSGShape3D.OPERATION_SUBTRACTION

func generate_base_shell() -> void:
	"""Create the main hollow shell using CSG operations"""
	var outer_shell = CSGSphere3D.new()
	outer_shell.radius = space_size.x * 0.5
	outer_shell.material = material_manager.get_base_material()
	
	var inner_cavity = CSGSphere3D.new()
	inner_cavity.radius = space_size.x * 0.4
	inner_cavity.operation = CSGShape3D.OPERATION_SUBTRACTION
	
	# Add organic deformation using noise
	apply_organic_deformation(outer_shell)
	apply_organic_deformation(inner_cavity)
	
	outer_shell.add_child(inner_cavity)
	environment_container.add_child(outer_shell)

func apply_organic_deformation(shape: CSGShape3D) -> void:
	"""Apply procedural deformation to create organic feel"""
	var noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.frequency = 0.1
	noise.seed = _rng.randi()

	# Create displacement using vertex shader if available
	# For now, use multiple CSG operations to approximate
	for i in range(tunnel_complexity):
		var deform_sphere = CSGSphere3D.new()
		var angle = i * TAU / tunnel_complexity
		var offset = Vector3(
			cos(angle) * space_size.x * 0.3,
			sin(i * 0.7) * space_size.y * 0.2,
			sin(angle) * space_size.z * 0.3
		)
		
		deform_sphere.position = offset
		deform_sphere.radius = _rng.randf_range(2.0, 4.0)
		deform_sphere.operation = _op_for(i, 0.5)

		shape.add_child(deform_sphere)

func generate_tunnel_system() -> void:
	"""Create interconnected organic tunnels"""
	var tunnel_points = generate_tunnel_path()
	
	for i in range(tunnel_points.size() - 1):
		create_tunnel_segment(tunnel_points[i], tunnel_points[i + 1], i)

func generate_tunnel_path() -> Array[Vector3]:
	"""Generate organic path using 3D noise"""
	var points: Array[Vector3] = []
	var noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = 0.05
	
	var steps = tunnel_complexity * 3
	for i in range(steps):
		var t = float(i) / float(steps - 1)
		var base_pos = Vector3(
			lerp(-space_size.x * 0.3, space_size.x * 0.3, t),
			0,
			0
		)
		
		# Add organic deviation
		var noise_offset = Vector3(
			noise.get_noise_3d(i * 10, 0, 0) * space_size.x * 0.2,
			noise.get_noise_3d(0, i * 10, 0) * space_size.y * 0.3,
			noise.get_noise_3d(0, 0, i * 10) * space_size.z * 0.2
		)
		
		points.append(base_pos + noise_offset)
	
	return points

func create_tunnel_segment(start: Vector3, end: Vector3, index: int) -> void:
	"""Create a single tunnel segment with organic shape"""
	var tunnel = CSGCylinder3D.new()
	tunnel.height = start.distance_to(end)
	tunnel.radius = _rng.randf_range(1.5, 3.0)
	
	# Position and orient tunnel
	tunnel.position = (start + end) * 0.5
	tunnel.look_at_from_position(tunnel.position, end, Vector3.UP)
	tunnel.rotate_object_local(Vector3.RIGHT, PI * 0.5)
	
	# Apply organic material
	tunnel.material = material_manager.get_tunnel_material(index)
	
	# Add surface details
	add_tunnel_details(tunnel, index)
	
	environment_container.add_child(tunnel)

func add_tunnel_details(tunnel: CSGCylinder3D, index: int) -> void:
	"""Add organic surface details to tunnels"""
	var detail_count = _rng.randi_range(3, 8)

	for i in range(detail_count):
		var detail = CSGSphere3D.new()
		detail.radius = _rng.randf_range(0.3, 0.8)

		# Random position around tunnel surface
		var angle = _rng.randf() * TAU
		var height = _rng.randf_range(-tunnel.height * 0.4, tunnel.height * 0.4)
		var radius_offset = tunnel.radius * _rng.randf_range(0.8, 1.2)
		
		detail.position = Vector3(
			cos(angle) * radius_offset,
			height,
			sin(angle) * radius_offset
		)
		
		detail.operation = _op_for(i, 0.3)
		detail.material = material_manager.get_detail_material(_rng.randi())
		
		tunnel.add_child(detail)

func generate_surface_details() -> void:
	"""Add fine surface details and textures.

	`cast` decides who is on show. "all" runs the three generators together,
	which is the shipped composition; each other value gives the space over
	to one claim about what organic form is."""
	# Create membrane-like structures
	if cast == "all" or cast == "membrane":
		create_membrane_surfaces()

	# Add crystalline formations
	if cast == "all" or cast == "crystal":
		create_crystal_formations()

	# Generate organic growths
	if cast == "all" or cast == "growth":
		create_organic_growths()

func create_membrane_surfaces() -> void:
	"""Create thin membrane surfaces spanning spaces"""
	for i in range(_rng.randi_range(3, 6)):
		var membrane = CSGCylinder3D.new()
		membrane.height = 0.1  # Very thin
		membrane.radius = _rng.randf_range(3.0, 6.0)

		# Random position and orientation
		membrane.position = Vector3(
			_rng.randf_range(-space_size.x * 0.3, space_size.x * 0.3),
			_rng.randf_range(-space_size.y * 0.3, space_size.y * 0.3),
			_rng.randf_range(-space_size.z * 0.3, space_size.z * 0.3)
		)
		membrane.rotation = Vector3(
			_rng.randf() * TAU,
			_rng.randf() * TAU,
			_rng.randf() * TAU
		)
		
		membrane.material = material_manager.get_membrane_material()
		environment_container.add_child(membrane)

func create_crystal_formations() -> void:
	"""Add crystalline geometric structures"""
	for i in range(_rng.randi_range(5, 10)):
		var crystal = CSGBox3D.new()
		crystal.size = Vector3(
			_rng.randf_range(0.5, 2.0),
			_rng.randf_range(2.0, 5.0),
			_rng.randf_range(0.5, 2.0)
		)
		
		# Cluster around certain points
		var cluster_center = Vector3(
			cos(i * 1.3) * space_size.x * 0.25,
			sin(i * 0.8) * space_size.y * 0.25,
			sin(i * 1.1) * space_size.z * 0.25
		)
		
		crystal.position = cluster_center + Vector3(
			_rng.randf_range(-2, 2),
			_rng.randf_range(-2, 2),
			_rng.randf_range(-2, 2)
		)
		crystal.rotation = Vector3(
			_rng.randf() * TAU,
			_rng.randf() * TAU,
			_rng.randf() * TAU
		)
		
		crystal.material = material_manager.get_crystal_material()
		environment_container.add_child(crystal)

func create_organic_growths() -> void:
	"""Add bulbous organic formations"""
	for i in range(_rng.randi_range(8, 15)):
		var growth = CSGSphere3D.new()
		growth.radius = _rng.randf_range(0.8, 2.5)

		# Attach to walls/surfaces
		var surface_normal = Vector3(
			_rng.randf_range(-1, 1),
			_rng.randf_range(-1, 1),
			_rng.randf_range(-1, 1)
		).normalized()

		growth.position = surface_normal * space_size.x * _rng.randf_range(0.3, 0.45)
		growth.material = material_manager.get_organic_material()

		# Add smaller sub-growths
		for j in range(_rng.randi_range(2, 5)):
			var sub_growth = CSGSphere3D.new()
			sub_growth.radius = growth.radius * _rng.randf_range(0.3, 0.7)
			sub_growth.position = Vector3(
				_rng.randf_range(-1, 1),
				_rng.randf_range(-1, 1),
				_rng.randf_range(-1, 1)
			).normalized() * growth.radius * 1.2
			sub_growth.material = material_manager.get_organic_material()
			growth.add_child(sub_growth)
		
		environment_container.add_child(growth)

func _bake_csg_to_meshes() -> void:
	"""Replace CSG nodes with baked static meshes for runtime performance.
	CSG boolean operations are expensive to keep alive; baking converts
	the computed geometry into lightweight MeshInstance3D nodes."""
	var csg_roots: Array[CSGShape3D] = []
	for child in environment_container.get_children():
		if child is CSGShape3D:
			csg_roots.append(child)

	for csg_root in csg_roots:
		# Force CSG to compute its final mesh
		csg_root._update_shape()  # Ensure boolean tree is resolved
		var baked_meshes := csg_root.get_meshes()
		if baked_meshes.size() >= 2:
			# get_meshes() returns [Transform3D, Mesh, Transform3D, Mesh, ...]
			var mesh_node := MeshInstance3D.new()
			mesh_node.transform = csg_root.transform * (baked_meshes[0] as Transform3D)
			mesh_node.mesh = baked_meshes[1] as Mesh
			# Preserve material from the CSG root if set
			if csg_root.material:
				mesh_node.material_override = csg_root.material
			environment_container.add_child(mesh_node)
		# Remove the CSG tree — no longer needed
		csg_root.queue_free()

func setup_atmospheric_lighting() -> void:
	"""Create atmospheric lighting effects"""
	lighting_system.setup_organic_lighting(environment_container, space_size)

func generate_interactive_elements() -> void:
	"""Add interactive elements for the space"""
	# Create floating orbs that can be interacted with
	for i in range(_rng.randi_range(3, 7)):
		var orb = create_interactive_orb()
		orb.position = Vector3(
			_rng.randf_range(-space_size.x * 0.2, space_size.x * 0.2),
			_rng.randf_range(-space_size.y * 0.2, space_size.y * 0.2),
			_rng.randf_range(-space_size.z * 0.2, space_size.z * 0.2)
		)
		environment_container.add_child(orb)

func create_interactive_orb() -> RigidBody3D:
	"""Create interactive floating orb"""
	var orb = RigidBody3D.new()
	orb.gravity_scale = 0  # Float in space
	
	var mesh_instance = MeshInstance3D.new()
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 0.5
	sphere_mesh.height = 1.0
	mesh_instance.mesh = sphere_mesh
	mesh_instance.material_override = material_manager.get_interactive_material()
	
	var collision_shape = CollisionShape3D.new()
	var sphere_shape = SphereShape3D.new()
	sphere_shape.radius = 0.5
	collision_shape.shape = sphere_shape
	
	orb.add_child(mesh_instance)
	orb.add_child(collision_shape)
	
	# Add gentle floating motion
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(orb, "position", orb.position + Vector3(0, 2, 0), 3.0)
	tween.tween_property(orb, "position", orb.position, 3.0)
	
	return orb



func regenerate_space() -> void:
	"""Regenerate the entire space with new parameters.

	The container has to come BACK. The old body freed it and then called
	generate_organic_space(), which adds every shape to
	environment_container — a freed node. Nothing shipped ever called this
	(the @identity line still reads "VR regenerate trigger [missing]"), so
	the bug was never hit; it would be hit the moment a map handed over a
	formation or cast, which is exactly what apply_grid_config now does."""
	# Clear existing environment
	if is_instance_valid(environment_container):
		environment_container.queue_free()

	# Regenerate with new seed
	await get_tree().process_frame
	environment_container = Node3D.new()
	environment_container.name = "OrganicEnvironment"
	add_child(environment_container)
	generate_organic_space()

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	"""Map-token config. Guarded on both sides: an unknown or unchanged value
	is a no-op, and the rebuild only fires once the space has been built. The
	thirteen maps that place this artifact pass no DNA keys at all, so they
	take the early exit and get the space they have always had."""
	var changed: bool = false

	if config.has("formation"):
		var want_formation: String = str(config["formation"])
		if want_formation in FORMATIONS and want_formation != formation:
			formation = want_formation
			changed = true

	if config.has("cast"):
		var want_cast: String = str(config["cast"])
		if want_cast in CASTS and want_cast != cast:
			cast = want_cast
			changed = true

	if config.has("form_seed"):
		var want_seed: int = int(config["form_seed"])
		if want_seed != form_seed:
			form_seed = want_seed
			changed = true

	if changed and _built:
		regenerate_space()
