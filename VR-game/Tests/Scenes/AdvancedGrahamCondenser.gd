extends Node3D

# A more advanced implementation for creating Graham condensers with custom meshes
# This creates accurate spiral tubes and bulged outer tubes using Godot's SurfaceTool

class_name AdvancedGrahamCondenser

# Parameters for condenser customization
@export var condenser_height: float = 1.0
@export var condenser_radius: float = 0.05
@export var tube_radius: float = 0.008
@export var spiral_loops: int = 12
@export var spiral_radius: float = 0.03
@export var spiral_pitch: float = 0.06
@export var has_bulges: bool = false
@export var num_bulges: int = 5  # Number of bulges if using bulged style
@export var bulge_factor: float = 1.3  # How pronounced the bulges are
@export var side_arm_angle: float = 110.0  # Degrees

# Material properties
@export var glass_transparency: float = 0.2
@export var glass_roughness: float = 0.05

# Internal variables
var _glass_material: StandardMaterial3D

func _ready():
	create_materials()
	if has_bulges:
		create_bulged_condenser()
	else:
		create_straight_condenser()

func create_materials():
	# Create glass material
	_glass_material = StandardMaterial3D.new()
	_glass_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_glass_material.albedo_color = Color(1.0, 1.0, 1.0, glass_transparency)
	_glass_material.roughness = glass_roughness
	_glass_material.metallic_specular = 0.9
	_glass_material.cull_mode = BaseMaterial3D.CULL_DISABLED  # Double-sided glass

func create_straight_condenser():
	# Create outer tube
	var outer_tube = create_cylinder_mesh(condenser_radius, condenser_height, 32, 1)
	add_mesh_instance("OuterTube", outer_tube, _glass_material)
	
	# Create inner tube (to hollow out the outer tube)
	var inner_radius = condenser_radius - 0.005  # Thickness of glass
	var inner_tube = create_cylinder_mesh(inner_radius, condenser_height + 0.01, 32, 1)
	
	# Create the hollowed tube using CSG
	var csg_container = CSGCombiner3D.new()
	csg_container.name = "HollowTube"
	add_child(csg_container)
	
	var csg_outer = CSGMesh3D.new()
	csg_outer.mesh = outer_tube
	csg_outer.material_override = _glass_material
	csg_container.add_child(csg_outer)
	
	var csg_inner = CSGMesh3D.new()
	csg_inner.mesh = inner_tube
	csg_inner.operation = CSGShape3D.OPERATION_SUBTRACTION
	csg_container.add_child(csg_inner)
	
	# Create spiral tube
	create_spiral_tube()
	
	# Create side arms
	create_side_arms()
	
	# Create ground glass joints
	create_joints()

func create_bulged_condenser():
	# Create outer tube with bulges
	var outer_tube = create_bulged_cylinder_mesh(
		condenser_radius, 
		condenser_height, 
		num_bulges,
		bulge_factor,
		32, 
		num_bulges * 4
	)
	add_mesh_instance("OuterBulgedTube", outer_tube, _glass_material)
	
	# Create inner tube (to hollow out the outer tube)
	var inner_radius = condenser_radius - 0.005  # Thickness of glass
	var inner_tube = create_bulged_cylinder_mesh(
		inner_radius, 
		condenser_height + 0.01, 
		num_bulges,
		bulge_factor,
		32, 
		num_bulges * 4
	)
	
	# Create the hollowed tube using CSG
	var csg_container = CSGCombiner3D.new()
	csg_container.name = "HollowBulgedTube"
	add_child(csg_container)
	
	var csg_outer = CSGMesh3D.new()
	csg_outer.mesh = outer_tube
	csg_outer.material_override = _glass_material
	csg_container.add_child(csg_outer)
	
	var csg_inner = CSGMesh3D.new()
	csg_inner.mesh = inner_tube
	csg_inner.operation = CSGShape3D.OPERATION_SUBTRACTION
	csg_container.add_child(csg_inner)
	
	# Create spiral tube
	create_spiral_tube()
	
	# Create side arms
	create_side_arms()
	
	# Create ground glass joints
	create_joints()

func create_cylinder_mesh(radius: float, height: float, radial_segments: int = 32, rings: int = 1) -> Mesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var half_height = height / 2.0
	
	# Add vertices for each ring
	for j in range(rings + 1):
		var v = float(j) / float(rings)
		var y = -half_height + height * v
		
		for i in range(radial_segments + 1):
			var u = float(i) / float(radial_segments)
			var angle = u * 2.0 * PI
			
			var x = radius * cos(angle)
			var z = radius * sin(angle)
			
			var vertex = Vector3(x, y, z)
			var normal = Vector3(x, 0, z).normalized()
			var uv = Vector2(u, v)
			
			st.set_normal(normal)
			st.set_uv(uv)
			st.add_vertex(vertex)
	
	# Create triangles
	for j in range(rings):
		for i in range(radial_segments):
			var current = j * (radial_segments + 1) + i
			var next = current + 1
			var current_below = (j + 1) * (radial_segments + 1) + i
			var next_below = current_below + 1
			
			# First triangle
			st.add_index(current)
			st.add_index(next_below)
			st.add_index(next)
			
			# Second triangle
			st.add_index(current)
			st.add_index(current_below)
			st.add_index(next_below)
	
	st.generate_normals()
	return st.commit()
	
func create_side_arms():
	# Create side arms (inlet/outlet tubes)
	var arm_positions = [
		Vector3(0, condenser_height * 0.35, 0),
		Vector3(0, -condenser_height * 0.35, 0)
	]
	
	for i in range(2):
		create_side_arm(arm_positions[i], i)

func create_side_arm(position: Vector3, index: int):
	# Create a bent side arm tube
	var arm_radius = tube_radius * 1.5
	var arm_length = condenser_radius * 3.0
	
	# Create points for a bent path
	var path = []
	var segments = 10
	
	# Start inside the main tube
	path.append(Vector3(-condenser_radius * 0.5, position.y, 0))
	
	# Add points along a curved path
	for i in range(1, segments + 1):
		var t = float(i) / float(segments)
		var angle = t * deg_to_rad(side_arm_angle)
		
		var x = condenser_radius + (arm_length - condenser_radius) * t
		var y = position.y + condenser_radius * 0.5 * sin(angle)
		path.append(Vector3(x, y, 0))
	
	# Create tube along the path
	var arm_mesh = create_tube_along_path(path, arm_radius, 12)
	add_mesh_instance("SideArm_" + str(index), arm_mesh, _glass_material)

func create_joints():
	# Create standard taper ground glass joints
	var joint_positions = [
		Vector3(0, condenser_height * 0.5, 0),
		Vector3(0, -condenser_height * 0.5, 0)
	]
	
	for i in range(2):
		create_ground_glass_joint(joint_positions[i], i == 0)

func create_ground_glass_joint(position: Vector3, is_top: bool):
	# Create a standard taper ground glass joint
	var joint_length = condenser_radius * 3.0
	var taper_factor = 0.8  # Ratio of small end to large end
	
	var large_radius = condenser_radius
	var small_radius = large_radius * taper_factor
	
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var segments = 32
	var rings = 8
	
	# For frosted glass appearance
	var noise = FastNoiseLite.new()
	noise.seed = randi()
	noise.frequency = 0.8
	
	# Create rings of vertices
	for j in range(rings + 1):
		var v = float(j) / float(rings)
		
		# Calculate position and radius based on joint position
		var y_offset
		var radius
		
		if is_top:
			y_offset = position.y + v * joint_length
			radius = lerp(large_radius, small_radius, v)
		else:
			y_offset = position.y - v * joint_length
			radius = lerp(large_radius, small_radius, v)
		
		# Create vertices around the ring
		for i in range(segments + 1):
			var u = float(i) / float(segments)
			var angle = u * 2.0 * PI
			
			var x = radius * cos(angle)
			var z = radius * sin(angle)
			
			# Add small noise to create ground glass appearance
			# Only for the middle portion where the ground glass would be
			var noise_factor = 0.0005
			if v > 0.1 and v < 0.9:
				var noise_val = noise.get_noise_3d(x * 100, y_offset * 100, z * 100)
				x += noise_val * noise_factor
				z += noise_val * noise_factor
			
			var vertex = Vector3(x, y_offset, z)
			var normal = Vector3(x, 0, z).normalized()
			var uv = Vector2(u, v)
			
			st.set_normal(normal)
			st.set_uv(uv)
			st.add_vertex(vertex)
	
	# Create triangles
	for j in range(rings):
		for i in range(segments):
			var current = j * (segments + 1) + i
			var next = current + 1
			var current_below = (j + 1) * (segments + 1) + i
			var next_below = current_below + 1
			
			# First triangle
			st.add_index(current)
			st.add_index(next_below)
			st.add_index(next)
			
			# Second triangle
			st.add_index(current)
			st.add_index(current_below)
			st.add_index(next_below)
	
	
	var joint_mesh = st.commit()
	var joint_name = "TopJoint" if is_top else "BottomJoint"
	add_mesh_instance(joint_name, joint_mesh, _glass_material)

func add_mesh_instance(name: String, mesh: Mesh, material: Material) -> MeshInstance3D:
	var instance = MeshInstance3D.new()
	instance.name = name
	instance.mesh = mesh
	instance.material_override = material
	add_child(instance)
	return instance

func create_bulged_cylinder_mesh(radius: float, height: float, num_bulges: int, 
								bulge_factor: float, radial_segments: int = 32, 
								rings: int = 16) -> Mesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var half_height = height / 2.0
	
	# Add vertices for each ring
	for j in range(rings + 1):
		var v = float(j) / float(rings)
		var y = -half_height + height * v
		
		# Calculate bulge at this height
		var bulge_radius = radius
		if num_bulges > 0:
			var bulge_wave = sin(v * PI * num_bulges)
			bulge_radius = radius * (1.0 + (bulge_factor - 1.0) * max(0, bulge_wave))
		
		for i in range(radial_segments + 1):
			var u = float(i) / float(radial_segments)
			var angle = u * 2.0 * PI
			
			var x = bulge_radius * cos(angle)
			var z = bulge_radius * sin(angle)
			
			var vertex = Vector3(x, y, z)
			var normal = Vector3(x, 0, z).normalized()
			var uv = Vector2(u, v)
			
			st.set_normal(normal)
			st.set_uv(uv)
			st.add_vertex(vertex)
	
	# Create triangles
	for j in range(rings):
		for i in range(radial_segments):
			var current = j * (radial_segments + 1) + i
			var next = current + 1
			var current_below = (j + 1) * (radial_segments + 1) + i
			var next_below = current_below + 1
			
			# First triangle
			st.add_index(current)
			st.add_index(next_below)
			st.add_index(next)
			
			# Second triangle
			st.add_index(current)
			st.add_index(current_below)
			st.add_index(next_below)
	
	st.generate_normals()
	return st.commit()

func create_spiral_tube():
	# Generate points along spiral path
	var spiral_points = generate_spiral_points()
	
	# Create a tube mesh following these points
	var spiral_mesh = create_tube_along_path(spiral_points, tube_radius, 8)
	add_mesh_instance("SpiralTube", spiral_mesh, _glass_material)

func generate_spiral_points() -> Array:
	var points = []
	var segments_per_loop = 16
	var total_points = spiral_loops * segments_per_loop
	
	# Starting slightly inside the tube
	var start_y = condenser_height / 2 - 0.1
	var end_y = -condenser_height / 2 + 0.1
	
	for i in range(total_points + 1):
		var fraction = float(i) / float(total_points)
		var angle = fraction * spiral_loops * 2.0 * PI
		var y = start_y - fraction * (start_y - end_y)
		
		var x = spiral_radius * cos(angle)
		var z = spiral_radius * sin(angle)
		
		points.append(Vector3(x, y, z))
	
	return points

func calculate_frames(path_points: Array) -> Array:
	# Calculate coordinate frames along path using Parallel Transport
	var frames = []
	
	# Initial frame - using the first segment as initial tangent
	var tangent = (path_points[1] - path_points[0]).normalized()
	
	# Find a perpendicular vector for initial normal
	var normal
	if abs(tangent.y) < 0.9:
		normal = Vector3(0, 1, 0).cross(tangent).normalized()
	else:
		normal = Vector3(1, 0, 0).cross(tangent).normalized()
	
	# Binormal completes the right-handed system
	var binormal = tangent.cross(normal).normalized()
	
	frames.append([tangent, normal, binormal])
	
	# Compute remaining frames
	for i in range(1, path_points.size()):
		if i < path_points.size() - 1:
			# Compute tangent as direction to next point
			tangent = (path_points[i+1] - path_points[i]).normalized()
		
		# Previous frame
		var prev_tangent = frames[i-1][0]
		var prev_normal = frames[i-1][1]
		var prev_binormal = frames[i-1][2]
		
		# Compute rotation from previous tangent to current tangent
		var rotation_axis
		var dot_product = prev_tangent.dot(tangent)
		
		if dot_product > 0.99999:
			# Tangents almost same direction - no rotation needed
			normal = prev_normal
			binormal = prev_binormal
		elif dot_product < -0.99999:
			# Tangents almost opposite - rotate 180° around an arbitrary perpendicular axis
			normal = prev_normal * -1
			binormal = prev_binormal
		else:
			# General case - use rotation axis perpendicular to both tangents
			rotation_axis = prev_tangent.cross(tangent).normalized()
			var rotation_angle = acos(dot_product)
			
			# Rotate previous frame's normal and binormal
			normal = prev_normal.rotated(rotation_axis, rotation_angle)
			binormal = tangent.cross(normal).normalized()
		
		frames.append([tangent, normal, binormal])
	
	return frames

func create_tube_along_path(path_points: Array, tube_radius: float, segments: int):
	if path_points.size() < 2:
		return null
		
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# We need a frame (coordinate system) at each point
	var frames = calculate_frames(path_points)
	
	# Generate vertices
	var verts = []
	for i in range(path_points.size()):
		var circle_verts = []
		var point = path_points[i]
		var tangent = frames[i][0]
		var normal = frames[i][1]
		var binormal = frames[i][2]
		
		for j in range(segments):
			var angle = j * 2.0 * PI / segments
			var x = cos(angle)
			var y = sin(angle)
			
			var offset = normal * x * tube_radius + binormal * y * tube_radius
			circle_verts.append(point + offset)
		
		verts.append(circle_verts)
	
	# Generate triangles between circles
	for i in range(path_points.size() - 1):
		var ring1 = verts[i]
		var ring2 = verts[i+1]
		
		for j in range(segments):
			var j_next = (j + 1) % segments
			
			# Calculate normal
			var current_point = ring1[j]
			var normal = (current_point - path_points[i]).normalized()
			
			# Triangle 1
			st.set_normal(normal)
			st.add_vertex(ring1[j])
			
			normal = (ring2[j] - path_points[i+1]).normalized()
			st.set_normal(normal)
			st.add_vertex(ring2[j])
			
			normal = (ring1[j_next] - path_points[i]).normalized()
			st.set_normal(normal)
			st.add_vertex(ring1[j_next])
			
			# Triangle 2
			st.set_normal(normal)
			st.add_vertex(ring1[j_next])
			
			normal = (ring2[j] - path_points[i+1]).normalized()
			st.set_normal(normal)
			st.add_vertex(ring2[j])
			
			normal = (ring2[j_next] - path_points[i+1]).normalized()
			st.set_normal(normal)
			st.add_vertex(ring2[j_next])
