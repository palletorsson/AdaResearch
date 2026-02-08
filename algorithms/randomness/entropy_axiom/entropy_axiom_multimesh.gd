extends Node3D

# Entropy Visualization: Order → Chaos (MultiMesh Version)
# Static visualization - much more efficient than individual instances
# 10x10x40 grid = 4000 instances in a single draw call

@export var grid_size_x: int = 10
@export var grid_size_y: int = 10
@export var grid_size_z: int = 40
@export var base_spacing: float = 0.2
@export var max_randomness: float = 0.5
@export var min_randomness: float = 0.0
@export var point_radius: float = 0.018
@export var show_bounds_frame: bool = true
@export var frame_thickness: float = 0.012
@export var frame_padding: float = 0.05
@export var frame_color: Color = Color(0.95, 0.98, 1.0, 0.8)
@export var frame_emission_color: Color = Color(0.6, 0.8, 1.0, 1.0)
@export var frame_emission_energy: float = 1.6

var multimesh_instance: MultiMeshInstance3D
var frame_root: Node3D

func _ready():
	create_multimesh()
	generate_entropy_grid()
	create_bounds_frame()

func create_multimesh():
	# Create MultiMeshInstance3D node
	multimesh_instance = MultiMeshInstance3D.new()
	add_child(multimesh_instance)

	# Create MultiMesh resource
	var multimesh = MultiMesh.new()
	multimesh_instance.multimesh = multimesh

	# IMPORTANT: Set transform format to 3D BEFORE setting instance count
	multimesh.transform_format = MultiMesh.TRANSFORM_3D

	# Enable per-instance colors BEFORE setting instance count
	multimesh.use_colors = true

	# Create sphere mesh
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = point_radius
	sphere_mesh.height = point_radius * 2.0
	sphere_mesh.radial_segments = 16
	sphere_mesh.rings = 8

	# Assign mesh to multimesh
	multimesh.mesh = sphere_mesh

	# Set instance count (must be done AFTER transform_format and use_colors)
	var total_instances = grid_size_x * grid_size_y * grid_size_z
	multimesh.instance_count = total_instances

	# Create emissive material for visibility
	var material = StandardMaterial3D.new()
	material.emission_enabled = true
	material.emission_energy_multiplier = 0.8
	multimesh_instance.material_override = material

func generate_entropy_grid():
	var multimesh = multimesh_instance.multimesh
	var instance_index = 0

	for z in range(grid_size_z):
		for y in range(grid_size_y):
			for x in range(grid_size_x):
				# Calculate entropy factor (0.0 at z=0, 1.0 at z=max)
				var entropy_factor = float(z) / float(grid_size_z - 1)

				# Apply exponential curve for dramatic increase toward the end
				var curved_entropy = pow(entropy_factor, 2.0)

				# Base grid position
				var base_x = (x - grid_size_x / 2.0) * base_spacing
				var base_y = (y - grid_size_y / 2.0) * base_spacing
				var base_z = z * base_spacing

				# Randomness scales from 0 (perfect order) to max (chaos)
				var randomness_amount = lerp(min_randomness, max_randomness, curved_entropy)
				var random_offset_x = randf_range(-randomness_amount, randomness_amount)
				var random_offset_y = randf_range(-randomness_amount, randomness_amount)

				# Final position
				var position = Vector3(
					base_x + random_offset_x,
					base_y + random_offset_y,
					base_z
				)

				# Create transform for this instance
				var transform = Transform3D()
				transform.origin = position
				multimesh.set_instance_transform(instance_index, transform)

				# Set color for this instance
				var color = get_entropy_color(curved_entropy)
				multimesh.set_instance_color(instance_index, color)

				instance_index += 1

func get_entropy_color(entropy_factor: float) -> Color:
	# Color gradient representing entropy increase
	# Low entropy (0.0) = Blue (cold, ordered, low energy)
	# Mid entropy (0.5) = Magenta (transition)
	# High entropy (1.0) = Red (hot, chaotic, high energy)

	# Use HSV: Hue from 240° (blue) through 300° (magenta) to 0° (red)
	var hue = lerp(0.66, 0.0, entropy_factor)  # 0.66 = blue, 0.0 = red
	var saturation = 1.0
	var value = 1.0

	return Color.from_hsv(hue, saturation, value)

func create_bounds_frame():
	if not show_bounds_frame:
		return

	frame_root = Node3D.new()
	frame_root.name = "EntropyBoundsFrame"
	add_child(frame_root)

	var min_corner = _get_bounds_min()
	var max_corner = _get_bounds_max()
	_build_frame_edges(min_corner, max_corner)

func _get_bounds_min() -> Vector3:
	var min_x = (0.0 - grid_size_x / 2.0) * base_spacing - max_randomness - point_radius - frame_padding
	var min_y = (0.0 - grid_size_y / 2.0) * base_spacing - max_randomness - point_radius - frame_padding
	var min_z = -point_radius - frame_padding
	return Vector3(min_x, min_y, min_z)

func _get_bounds_max() -> Vector3:
	var max_x = ((grid_size_x - 1) - grid_size_x / 2.0) * base_spacing + max_randomness + point_radius + frame_padding
	var max_y = ((grid_size_y - 1) - grid_size_y / 2.0) * base_spacing + max_randomness + point_radius + frame_padding
	var max_z = (grid_size_z - 1) * base_spacing + point_radius + frame_padding
	return Vector3(max_x, max_y, max_z)

func _build_frame_edges(min_corner: Vector3, max_corner: Vector3):
	var thickness = max(frame_thickness, 0.001)
	var size_x = max(max_corner.x - min_corner.x, thickness)
	var size_y = max(max_corner.y - min_corner.y, thickness)
	var size_z = max(max_corner.z - min_corner.z, thickness)

	var edge_mesh = BoxMesh.new()
	edge_mesh.size = Vector3.ONE

	var material = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = frame_color
	material.emission_enabled = true
	material.emission = frame_emission_color
	material.emission_energy_multiplier = frame_emission_energy
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	if frame_color.a < 1.0:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	var cx = (min_corner.x + max_corner.x) * 0.5
	var cy = (min_corner.y + max_corner.y) * 0.5
	var cz = (min_corner.z + max_corner.z) * 0.5

	# 4 edges along X
	_add_frame_edge(edge_mesh, material, Vector3(cx, min_corner.y, min_corner.z), Vector3(size_x, thickness, thickness))
	_add_frame_edge(edge_mesh, material, Vector3(cx, min_corner.y, max_corner.z), Vector3(size_x, thickness, thickness))
	_add_frame_edge(edge_mesh, material, Vector3(cx, max_corner.y, min_corner.z), Vector3(size_x, thickness, thickness))
	_add_frame_edge(edge_mesh, material, Vector3(cx, max_corner.y, max_corner.z), Vector3(size_x, thickness, thickness))

	# 4 edges along Y
	_add_frame_edge(edge_mesh, material, Vector3(min_corner.x, cy, min_corner.z), Vector3(thickness, size_y, thickness))
	_add_frame_edge(edge_mesh, material, Vector3(min_corner.x, cy, max_corner.z), Vector3(thickness, size_y, thickness))
	_add_frame_edge(edge_mesh, material, Vector3(max_corner.x, cy, min_corner.z), Vector3(thickness, size_y, thickness))
	_add_frame_edge(edge_mesh, material, Vector3(max_corner.x, cy, max_corner.z), Vector3(thickness, size_y, thickness))

	# 4 edges along Z
	_add_frame_edge(edge_mesh, material, Vector3(min_corner.x, min_corner.y, cz), Vector3(thickness, thickness, size_z))
	_add_frame_edge(edge_mesh, material, Vector3(min_corner.x, max_corner.y, cz), Vector3(thickness, thickness, size_z))
	_add_frame_edge(edge_mesh, material, Vector3(max_corner.x, min_corner.y, cz), Vector3(thickness, thickness, size_z))
	_add_frame_edge(edge_mesh, material, Vector3(max_corner.x, max_corner.y, cz), Vector3(thickness, thickness, size_z))

func _add_frame_edge(mesh: Mesh, material: Material, center: Vector3, size: Vector3):
	var edge = MeshInstance3D.new()
	edge.mesh = mesh
	edge.material_override = material
	edge.position = center
	edge.scale = size
	frame_root.add_child(edge)
