# Science Glasses - Spiral and Wobbly Glass Tubes
# Laboratory glassware: condensers, distillation coils, experimental apparatus
# Algorithms: parametric helix, perlin noise displacement, tube extrusion
extends Node3D
class_name ScienceGlasses

@export_group("Spiral Tube")
@export var spiral_radius: float = 0.3
@export var spiral_height: float = 1.0
@export var spiral_turns: int = 5
@export var spiral_tube_radius: float = 0.02
@export var spiral_resolution: int = 32
@export var spiral_tube_sides: int = 12

@export_group("Wobbly Tube")
@export var wobbly_length: float = 1.0
@export var wobbly_tube_radius: float = 0.025
@export var wobbly_amplitude: float = 0.1
@export var wobbly_frequency: float = 3.0
@export var wobbly_resolution: int = 64
@export var wobbly_tube_sides: int = 12
@export var wobbly_noise_seed: int = 0

@export_group("Materials")
@export var glass_color: Color = Color(0.85, 0.92, 1.0, 0.3)
@export var glass_roughness: float = 0.0
@export var use_refraction: bool = true
@export var inner_liquid_color: Color = Color(0.2, 0.8, 0.4, 0.6)
@export var show_liquid: bool = true

var glass_material: StandardMaterial3D
var liquid_material: StandardMaterial3D
var noise: FastNoiseLite

func _ready() -> void:
	_setup_materials()
	_setup_noise()
	create_spiral_tube(Vector3.ZERO)
	create_wobbly_tube(Vector3(0.8, 0, 0))
	create_double_helix(Vector3(-0.8, 0, 0))
	create_condenser_assembly(Vector3(0, 0, 0.8))

func _setup_materials() -> void:
	# Glass material with transparency and refraction
	glass_material = StandardMaterial3D.new()
	glass_material.albedo_color = glass_color
	glass_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass_material.metallic = 0.0
	glass_material.roughness = glass_roughness
	glass_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	if use_refraction:
		glass_material.refraction_enabled = true
		glass_material.refraction_scale = 0.05

	# Liquid material (glowing)
	liquid_material = StandardMaterial3D.new()
	liquid_material.albedo_color = inner_liquid_color
	liquid_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	liquid_material.emission_enabled = true
	liquid_material.emission = inner_liquid_color
	liquid_material.emission_energy_multiplier = 0.5

func _setup_noise() -> void:
	noise = FastNoiseLite.new()
	noise.seed = wobbly_noise_seed
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.frequency = 0.5

# =============================================================================
# SPIRAL TUBE (Condenser Coil)
# =============================================================================

func create_spiral_tube(pos: Vector3) -> MeshInstance3D:
	var group = Node3D.new()
	group.name = "SpiralTube"
	group.position = pos
	add_child(group)

	var mesh = _generate_spiral_mesh()
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "SpiralGlass"
	mesh_instance.mesh = mesh
	mesh_instance.material_override = glass_material
	group.add_child(mesh_instance)

	# Inner liquid spiral (slightly smaller)
	if show_liquid:
		var liquid_mesh = _generate_spiral_mesh(spiral_tube_radius * 0.7)
		var liquid_instance = MeshInstance3D.new()
		liquid_instance.name = "SpiralLiquid"
		liquid_instance.mesh = liquid_mesh
		liquid_instance.material_override = liquid_material
		group.add_child(liquid_instance)

	return mesh_instance

func _generate_spiral_mesh(tube_rad: float = -1.0) -> ArrayMesh:
	if tube_rad < 0:
		tube_rad = spiral_tube_radius

	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)

	var total_points: int = spiral_resolution * spiral_turns
	var angle_increment: float = TAU / spiral_resolution

	# Generate vertices along spiral path with tube cross-section
	var all_rings: Array = []

	for i in range(total_points + 1):
		var angle = angle_increment * i
		var t = float(i) / total_points

		# Spiral center point
		var center = Vector3(
			cos(angle) * spiral_radius,
			t * spiral_height,
			sin(angle) * spiral_radius
		)

		# Calculate tangent, normal, binormal (Frenet frame)
		var tangent = Vector3(
			-sin(angle) * spiral_radius,
			spiral_height / total_points,
			cos(angle) * spiral_radius
		).normalized()

		var up = Vector3.UP
		var binormal = tangent.cross(up).normalized()
		var normal = binormal.cross(tangent).normalized()

		# Generate ring of vertices around center
		var ring: Array = []
		for j in range(spiral_tube_sides):
			var tube_angle = TAU * j / spiral_tube_sides
			var offset = normal * cos(tube_angle) * tube_rad + binormal * sin(tube_angle) * tube_rad
			ring.append(center + offset)
		all_rings.append(ring)

	# Create faces between rings
	for i in range(all_rings.size() - 1):
		for j in range(spiral_tube_sides):
			var j_next = (j + 1) % spiral_tube_sides

			var v0 = all_rings[i][j]
			var v1 = all_rings[i][j_next]
			var v2 = all_rings[i + 1][j_next]
			var v3 = all_rings[i + 1][j]

			# Calculate normal for lighting
			var face_normal = (v1 - v0).cross(v3 - v0).normalized()

			# Triangle 1
			surface_tool.set_normal(face_normal)
			surface_tool.add_vertex(v0)
			surface_tool.set_normal(face_normal)
			surface_tool.add_vertex(v1)
			surface_tool.set_normal(face_normal)
			surface_tool.add_vertex(v2)

			# Triangle 2
			surface_tool.set_normal(face_normal)
			surface_tool.add_vertex(v0)
			surface_tool.set_normal(face_normal)
			surface_tool.add_vertex(v2)
			surface_tool.set_normal(face_normal)
			surface_tool.add_vertex(v3)

	surface_tool.generate_normals()
	return surface_tool.commit()

# =============================================================================
# WOBBLY TUBE (Perlin Noise Displaced)
# =============================================================================

func create_wobbly_tube(pos: Vector3) -> MeshInstance3D:
	var group = Node3D.new()
	group.name = "WobblyTube"
	group.position = pos
	add_child(group)

	var mesh = _generate_wobbly_mesh()
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "WobblyGlass"
	mesh_instance.mesh = mesh
	mesh_instance.material_override = glass_material
	group.add_child(mesh_instance)

	if show_liquid:
		var liquid_mesh = _generate_wobbly_mesh(wobbly_tube_radius * 0.7)
		var liquid_instance = MeshInstance3D.new()
		liquid_instance.name = "WobblyLiquid"
		liquid_instance.mesh = liquid_mesh
		liquid_instance.material_override = liquid_material
		group.add_child(liquid_instance)

	return mesh_instance

func _generate_wobbly_mesh(tube_rad: float = -1.0) -> ArrayMesh:
	if tube_rad < 0:
		tube_rad = wobbly_tube_radius

	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)

	var all_rings: Array = []

	for i in range(wobbly_resolution + 1):
		var t = float(i) / wobbly_resolution
		var y = t * wobbly_length

		# Base position along Y axis
		var center = Vector3(0, y, 0)

		# Apply sine wave wobble
		var sine_offset = sin(t * TAU * wobbly_frequency) * wobbly_amplitude
		center.x += sine_offset

		# Apply perlin noise for organic irregularity
		var noise_x = noise.get_noise_2d(t * 10.0, 0.0) * wobbly_amplitude * 0.5
		var noise_z = noise.get_noise_2d(t * 10.0, 100.0) * wobbly_amplitude * 0.5
		center.x += noise_x
		center.z += noise_z

		# Generate ring of vertices
		var ring: Array = []
		for j in range(wobbly_tube_sides):
			var tube_angle = TAU * j / wobbly_tube_sides
			var offset = Vector3(cos(tube_angle), 0, sin(tube_angle)) * tube_rad
			ring.append(center + offset)
		all_rings.append(ring)

	# Create faces
	for i in range(all_rings.size() - 1):
		for j in range(wobbly_tube_sides):
			var j_next = (j + 1) % wobbly_tube_sides

			var v0 = all_rings[i][j]
			var v1 = all_rings[i][j_next]
			var v2 = all_rings[i + 1][j_next]
			var v3 = all_rings[i + 1][j]

			var face_normal = (v1 - v0).cross(v3 - v0).normalized()

			surface_tool.set_normal(face_normal)
			surface_tool.add_vertex(v0)
			surface_tool.set_normal(face_normal)
			surface_tool.add_vertex(v1)
			surface_tool.set_normal(face_normal)
			surface_tool.add_vertex(v2)

			surface_tool.set_normal(face_normal)
			surface_tool.add_vertex(v0)
			surface_tool.set_normal(face_normal)
			surface_tool.add_vertex(v2)
			surface_tool.set_normal(face_normal)
			surface_tool.add_vertex(v3)

	surface_tool.generate_normals()
	return surface_tool.commit()

# =============================================================================
# DOUBLE HELIX (DNA-style intertwined spirals)
# =============================================================================

func create_double_helix(pos: Vector3) -> Node3D:
	var group = Node3D.new()
	group.name = "DoubleHelix"
	group.position = pos
	add_child(group)

	# Create two intertwined spirals offset by PI
	for helix_idx in range(2):
		var phase_offset = helix_idx * PI
		var mesh = _generate_helix_strand(phase_offset)
		var mesh_instance = MeshInstance3D.new()
		mesh_instance.name = "HelixStrand" + str(helix_idx)
		mesh_instance.mesh = mesh
		mesh_instance.material_override = glass_material
		group.add_child(mesh_instance)

	# Add connecting rungs
	_add_helix_rungs(group)

	return group

func _generate_helix_strand(phase: float) -> ArrayMesh:
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)

	var helix_radius = spiral_radius * 0.5
	var tube_rad = spiral_tube_radius * 0.6
	var total_points = spiral_resolution * spiral_turns

	var all_rings: Array = []

	for i in range(total_points + 1):
		var t = float(i) / total_points
		var angle = t * TAU * spiral_turns + phase

		var center = Vector3(
			cos(angle) * helix_radius,
			t * spiral_height,
			sin(angle) * helix_radius
		)

		var tangent = Vector3(
			-sin(angle) * helix_radius,
			spiral_height / total_points,
			cos(angle) * helix_radius
		).normalized()

		var binormal = tangent.cross(Vector3.UP).normalized()
		var normal = binormal.cross(tangent).normalized()

		var ring: Array = []
		for j in range(8):  # Fewer sides for smaller tubes
			var tube_angle = TAU * j / 8
			var offset = normal * cos(tube_angle) * tube_rad + binormal * sin(tube_angle) * tube_rad
			ring.append(center + offset)
		all_rings.append(ring)

	# Create faces
	for i in range(all_rings.size() - 1):
		for j in range(8):
			var j_next = (j + 1) % 8
			var v0 = all_rings[i][j]
			var v1 = all_rings[i][j_next]
			var v2 = all_rings[i + 1][j_next]
			var v3 = all_rings[i + 1][j]

			var face_normal = (v1 - v0).cross(v3 - v0).normalized()

			surface_tool.set_normal(face_normal)
			surface_tool.add_vertex(v0)
			surface_tool.set_normal(face_normal)
			surface_tool.add_vertex(v1)
			surface_tool.set_normal(face_normal)
			surface_tool.add_vertex(v2)

			surface_tool.set_normal(face_normal)
			surface_tool.add_vertex(v0)
			surface_tool.set_normal(face_normal)
			surface_tool.add_vertex(v2)
			surface_tool.set_normal(face_normal)
			surface_tool.add_vertex(v3)

	surface_tool.generate_normals()
	return surface_tool.commit()

func _add_helix_rungs(parent: Node3D) -> void:
	var helix_radius = spiral_radius * 0.5
	var rung_count = spiral_turns * 2

	for i in range(rung_count):
		var t = float(i) / rung_count
		var angle = t * TAU * spiral_turns
		var y = t * spiral_height

		var p1 = Vector3(cos(angle) * helix_radius, y, sin(angle) * helix_radius)
		var p2 = Vector3(cos(angle + PI) * helix_radius, y, sin(angle + PI) * helix_radius)

		var rung = _create_cylinder_between(p1, p2, spiral_tube_radius * 0.4)
		rung.name = "Rung" + str(i)
		rung.material_override = glass_material
		parent.add_child(rung)

func _create_cylinder_between(p1: Vector3, p2: Vector3, radius: float) -> MeshInstance3D:
	var mesh_instance = MeshInstance3D.new()
	var length = p1.distance_to(p2)

	var cylinder = CylinderMesh.new()
	cylinder.top_radius = radius
	cylinder.bottom_radius = radius
	cylinder.height = length
	mesh_instance.mesh = cylinder

	# Position at midpoint
	mesh_instance.position = (p1 + p2) / 2.0

	# Rotate to align with direction
	var direction = (p2 - p1).normalized()
	if direction != Vector3.UP and direction != Vector3.DOWN:
		mesh_instance.look_at(mesh_instance.position + direction, Vector3.UP)
		mesh_instance.rotate_object_local(Vector3.RIGHT, PI/2)

	return mesh_instance

# =============================================================================
# CONDENSER ASSEMBLY (Complete lab apparatus)
# =============================================================================

func create_condenser_assembly(pos: Vector3) -> Node3D:
	var group = Node3D.new()
	group.name = "CondenserAssembly"
	group.position = pos
	add_child(group)

	# Outer jacket (straight tube)
	var jacket = _create_straight_tube(Vector3.ZERO, spiral_height, spiral_radius * 0.4, spiral_tube_radius * 1.5)
	jacket.name = "OuterJacket"
	jacket.material_override = glass_material
	group.add_child(jacket)

	# Inner spiral condenser
	var inner_spiral = _generate_spiral_mesh(spiral_tube_radius * 0.8)
	var spiral_instance = MeshInstance3D.new()
	spiral_instance.name = "InnerSpiral"
	spiral_instance.mesh = inner_spiral
	spiral_instance.material_override = glass_material
	spiral_instance.scale = Vector3(0.3, 1.0, 0.3)  # Narrower spiral inside jacket
	group.add_child(spiral_instance)

	# Inlet/outlet tubes
	var inlet = _create_bent_tube(Vector3(spiral_radius * 0.4, spiral_height * 0.8, 0), Vector3.RIGHT, 0.15, spiral_tube_radius)
	inlet.name = "Inlet"
	group.add_child(inlet)

	var outlet = _create_bent_tube(Vector3(spiral_radius * 0.4, spiral_height * 0.2, 0), Vector3.RIGHT, 0.15, spiral_tube_radius)
	outlet.name = "Outlet"
	group.add_child(outlet)

	return group

func _create_straight_tube(pos: Vector3, height: float, radius: float, _wall_thickness: float) -> MeshInstance3D:
	var mesh_instance = MeshInstance3D.new()

	var cylinder = CylinderMesh.new()
	cylinder.top_radius = radius
	cylinder.bottom_radius = radius
	cylinder.height = height
	mesh_instance.mesh = cylinder
	mesh_instance.position = pos + Vector3(0, height / 2, 0)

	return mesh_instance

func _create_bent_tube(pos: Vector3, direction: Vector3, length: float, radius: float) -> MeshInstance3D:
	var mesh_instance = MeshInstance3D.new()

	var cylinder = CylinderMesh.new()
	cylinder.top_radius = radius
	cylinder.bottom_radius = radius
	cylinder.height = length
	mesh_instance.mesh = cylinder

	mesh_instance.position = pos + direction * (length / 2)
	mesh_instance.rotation.z = PI / 2  # Horizontal
	mesh_instance.material_override = glass_material

	return mesh_instance
