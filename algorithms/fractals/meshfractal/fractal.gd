# fractal.gd - Organic fractal generator with animation
extends Node3D

@export_range(3, 8) var depth: int = 6
@export var branch_mesh: Mesh
@export var leaf_mesh: Mesh
@export var material: Material

# Color gradients
@export var gradient_a: Gradient
@export var gradient_b: Gradient
@export var leaf_color_a: Color = Color(0.2, 0.8, 0.3, 0.5)
@export var leaf_color_b: Color = Color(0.1, 0.6, 0.2, 0.9)

# Sagging (gravity effect)
@export_range(0.0, 90.0) var max_sag_angle_a: float = 15.0
@export_range(0.0, 90.0) var max_sag_angle_b: float = 25.0

# Spin animation
@export_range(0.0, 90.0) var spin_speed_a: float = 20.0
@export_range(0.0, 90.0) var spin_speed_b: float = 25.0
@export_range(0.0, 1.0) var reverse_spin_chance: float = 0.25

# Internal data
var parts: Array = []  # Array of FractalPart structs
var multi_mesh_instances: Array = []  # MultiMeshInstance3D nodes

# Part directions and rotations
const DIRECTIONS = [
	Vector3.UP,
	Vector3.RIGHT,
	Vector3.LEFT,
	Vector3.FORWARD,
	Vector3.BACK
]

const ROTATIONS = [
	Quaternion.IDENTITY,
	Quaternion(Vector3.FORWARD, -PI * 0.5),
	Quaternion(Vector3.FORWARD, PI * 0.5),
	Quaternion(Vector3.RIGHT, PI * 0.5),
	Quaternion(Vector3.RIGHT, -PI * 0.5)
]

func _ready():
	generate_fractal()

func generate_fractal():
	clear_fractal()
	
	# Initialize parts arrays for each level
	parts.resize(depth)
	var length = 1
	for i in range(depth):
		parts[i] = []
		parts[i].resize(length)
		length *= 5
	
	# Create root part
	parts[0][0] = create_part(0)
	
	# Create all other parts
	for li in range(1, depth):
		var level_parts = parts[li]
		for fpi in range(0, level_parts.size(), 5):
			for ci in range(5):
				level_parts[fpi + ci] = create_part(ci)
	
	# Create MultiMesh instances for rendering
	create_multi_mesh_instances()

func create_part(child_index: int) -> Dictionary:
	return {
		"rotation": ROTATIONS[child_index],
		"world_rotation": Quaternion.IDENTITY,
		"world_position": Vector3.ZERO,
		"spin_angle": 0.0,
		"spin_velocity": (1.0 if randf() >= reverse_spin_chance else -1.0) * 
			deg_to_rad(randf_range(spin_speed_a, spin_speed_b)),
		"max_sag_angle": deg_to_rad(randf_range(max_sag_angle_a, max_sag_angle_b))
	}

func create_multi_mesh_instances():
	multi_mesh_instances.clear()
	
	for i in range(depth):
		var multi_mesh = MultiMesh.new()
		multi_mesh.transform_format = MultiMesh.TRANSFORM_3D
		multi_mesh.instance_count = parts[i].size()
		
		# Use leaf mesh for last level, branch mesh for others
		if i == depth - 1:
			multi_mesh.mesh = leaf_mesh
		else:
			multi_mesh.mesh = branch_mesh
		
		var mmi = MultiMeshInstance3D.new()
		mmi.multimesh = multi_mesh
		mmi.material_override = material
		add_child(mmi)
		multi_mesh_instances.append(mmi)

func _process(delta: float):
	update_fractal(delta)

func update_fractal(delta: float):
	# Update root part
	var root_part = parts[0][0]
	root_part.spin_angle += root_part.spin_velocity * delta
	root_part.world_rotation = global_transform.basis.get_rotation_quaternion() * 		root_part.rotation * Quaternion(Vector3.UP, root_part.spin_angle)
	root_part.world_position = global_position
	parts[0][0] = root_part
	
	# Set root transform
	var root_scale = global_transform.basis.get_scale().x
	multi_mesh_instances[0].multimesh.set_instance_transform(0, 
		Transform3D(Basis(root_part.world_rotation).scaled(Vector3.ONE * root_scale), 
		root_part.world_position))
	
	# Update all other levels
	var scale = root_scale
	for li in range(1, depth):
		scale *= 0.5
		var parent_parts = parts[li - 1]
		var level_parts = parts[li]
		var multi_mesh = multi_mesh_instances[li].multimesh
		
		for fpi in range(level_parts.size()):
			var parent = parent_parts[fpi / 5]
			var part = level_parts[fpi]
			
			# Update spin
			part.spin_angle += part.spin_velocity * delta
			
			# Calculate sagging (gravity effect)
			var up_axis = parent.world_rotation * part.rotation * Vector3.UP
			var sag_axis = Vector3.UP.cross(up_axis)
			var sag_magnitude = sag_axis.length()
			
			var base_rotation: Quaternion
			if sag_magnitude > 0.0:
				sag_axis = sag_axis.normalized()
				var sag_rotation = Quaternion(sag_axis, part.max_sag_angle * sag_magnitude)
				base_rotation = sag_rotation * parent.world_rotation
			else:
				base_rotation = parent.world_rotation
			
			# Apply rotation
			part.world_rotation = base_rotation * part.rotation * 				Quaternion(Vector3.UP, part.spin_angle)
			
			# Apply position
			part.world_position = parent.world_position + 				part.world_rotation * Vector3(0, 1.5 * scale, 0)
			
			level_parts[fpi] = part
			
			# Set transform in multimesh
			multi_mesh.set_instance_transform(fpi, 
				Transform3D(Basis(part.world_rotation).scaled(Vector3.ONE * scale), 
				part.world_position))
	
	# Update colors
	update_colors()

func update_colors():
	if not material:
		return
	
	for i in range(depth):
		var multi_mesh = multi_mesh_instances[i].multimesh
		var is_leaf = (i == depth - 1)
		
		for j in range(parts[i].size()):
			var color: Color
			
			if is_leaf:
				# Leaf colors
				var t = fract(j * 0.381 + 0.618)
				color = leaf_color_a.lerp(leaf_color_b, t)
			else:
				# Gradient colors
				var gradient_t = float(i) / float(depth - 2)
				var color_a = gradient_a.sample(gradient_t) if gradient_a else Color.WHITE
				var color_b = gradient_b.sample(gradient_t) if gradient_b else Color.WHITE
				var t = fract(j * 0.381 + i * 0.618)
				color = color_a.lerp(color_b, t)
			
			# Set color for this instance
			multi_mesh.set_instance_color(j, color)

func fract(value: float) -> float:
	return value - floor(value)

func clear_fractal():
	for mmi in multi_mesh_instances:
		mmi.queue_free()
	multi_mesh_instances.clear()
	parts.clear()

func _exit_tree():
	clear_fractal()
