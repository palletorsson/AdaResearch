# ElphabaDress - Mathematical wave dress that follows a rigged skeleton
# Inspired by Elphaba from Wicked - a flowing dress made of sine waves
# Attaches to skeleton bones and generates parametric fabric

extends Node3D

@export_group("Dress Shape")
@export var waist_radius: float = 0.15
@export var hem_radius: float = 0.4  # Bottom of dress
@export var dress_length: float = 0.8
@export var u_steps: int = 48  # Vertical resolution
@export var v_steps: int = 32  # Circular resolution

@export_group("Wave Parameters")
@export var wave_amplitude: float = 0.03
@export var wave_frequency: float = 5.0
@export var vertical_waves: float = 3.0
@export var animation_speed: float = 2.0
@export var flutter_intensity: float = 0.02

@export_group("Colors - Elphaba Style")
@export var primary_color: Color = Color(0.0, 0.3, 0.1)  # Dark emerald green
@export var secondary_color: Color = Color(0.0, 0.5, 0.2)  # Bright green
@export var wireframe_color: Color = Color(0.0, 1.0, 0.4)  # Glowing green wireframe
@export var emission_strength: float = 1.5

@export_group("Skeleton Binding")
@export var follow_skeleton: bool = true
@export var spine_bone_name: String = "spine"
@export var hip_bone_name: String = "hips"

var mesh_instance: MeshInstance3D
var _time: float = 0.0
var _skeleton: Skeleton3D
var _spine_bone_idx: int = -1
var _hip_bone_idx: int = -1
var _base_vertices: Array = []  # Store original vertices for animation
var _initialized: bool = false  # Prevent animation before mesh is ready

func _ready():
	call_deferred("_initialize")

func _initialize():
	# Try to find skeleton in parent hierarchy
	if follow_skeleton:
		_find_skeleton()

	create_dress_mesh()

func _find_skeleton():
	var parent = get_parent()
	while parent:
		_skeleton = _find_skeleton_recursive(parent)
		if _skeleton:
			break
		parent = parent.get_parent()

	if _skeleton:
		_spine_bone_idx = _skeleton.find_bone(spine_bone_name)
		_hip_bone_idx = _skeleton.find_bone(hip_bone_name)

		# Try alternative bone names
		if _spine_bone_idx < 0:
			_spine_bone_idx = _skeleton.find_bone("Spine")
		if _hip_bone_idx < 0:
			_hip_bone_idx = _skeleton.find_bone("Hips")

		print("ElphabaDress: Found skeleton, spine=%d, hip=%d" % [_spine_bone_idx, _hip_bone_idx])

func _find_skeleton_recursive(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node
	for child in node.get_children():
		var result = _find_skeleton_recursive(child)
		if result:
			return result
	return null

func create_dress_mesh():
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)

	_base_vertices.clear()

	# Generate dress as a flared cone with wave modulation
	for i in range(u_steps + 1):
		var row = []
		var u = float(i) / float(u_steps)  # 0 to 1, top to bottom

		for j in range(v_steps + 1):
			var v = float(j) / float(v_steps)  # 0 to 1, around circle
			var angle = v * TAU

			# Radius expands from waist to hem (flared skirt shape)
			var flare = ease(u, 0.7)  # Ease function for natural flare
			var radius = lerp(waist_radius, hem_radius, flare)

			# Add wave modulation for fabric ripples
			var wave_u = sin(u * vertical_waves * TAU) * wave_amplitude * u
			var wave_v = sin(angle * wave_frequency) * wave_amplitude * (0.5 + u * 0.5)
			radius += wave_u + wave_v

			# Additional flowing waves (Dini-like surface influence)
			var flow_wave = sin(angle * 3.0 + u * TAU) * wave_amplitude * 0.5 * u
			radius += flow_wave

			# Calculate position
			var x = radius * cos(angle)
			var z = radius * sin(angle)
			var y = -u * dress_length  # Negative Y = downward

			# Add slight vertical wave for flowing effect
			y += sin(angle * wave_frequency * 0.5) * wave_amplitude * 0.3 * u

			row.append(Vector3(x, y, z))
		_base_vertices.append(row)

	# Create faces
	_build_mesh_faces(surface_tool, _base_vertices)

	# Generate and apply mesh
	surface_tool.generate_normals()
	var generated_mesh = surface_tool.commit()

	if mesh_instance:
		mesh_instance.queue_free()

	mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = generated_mesh
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	add_child(mesh_instance)

	apply_material()

	_initialized = true
	print("ElphabaDress: Mesh created with %d vertex rows" % _base_vertices.size())

func _build_mesh_faces(surface_tool: SurfaceTool, vertices: Array):
	for i in range(u_steps):
		for j in range(v_steps):
			var v0 = vertices[i][j]
			var v1 = vertices[i + 1][j]
			var v2 = vertices[i + 1][j + 1]
			var v3 = vertices[i][j + 1]

			# Calculate normal
			var edge1 = v1 - v0
			var edge2 = v3 - v0
			var normal = edge1.cross(edge2).normalized()

			# UV coordinates for potential texture mapping
			var uv0 = Vector2(float(j) / v_steps, float(i) / u_steps)
			var uv1 = Vector2(float(j) / v_steps, float(i + 1) / u_steps)
			var uv2 = Vector2(float(j + 1) / v_steps, float(i + 1) / u_steps)
			var uv3 = Vector2(float(j + 1) / v_steps, float(i) / u_steps)

			# First triangle
			surface_tool.set_normal(normal)
			surface_tool.set_uv(uv0)
			surface_tool.add_vertex(v0)
			surface_tool.set_normal(normal)
			surface_tool.set_uv(uv1)
			surface_tool.add_vertex(v1)
			surface_tool.set_normal(normal)
			surface_tool.set_uv(uv2)
			surface_tool.add_vertex(v2)

			# Second triangle
			surface_tool.set_normal(normal)
			surface_tool.set_uv(uv0)
			surface_tool.add_vertex(v0)
			surface_tool.set_normal(normal)
			surface_tool.set_uv(uv2)
			surface_tool.add_vertex(v2)
			surface_tool.set_normal(normal)
			surface_tool.set_uv(uv3)
			surface_tool.add_vertex(v3)

func apply_material():
	if not mesh_instance:
		return

	var material = ShaderMaterial.new()
	var shader = load("res://commons/resourses/shaders/SimpleGrid.gdshader")

	if shader:
		material.shader = shader
		material.set_shader_parameter("modelColor", primary_color)
		material.set_shader_parameter("wireframeColor", wireframe_color)
		material.set_shader_parameter("emissionColor", secondary_color)
		material.set_shader_parameter("width", 1.5)
		material.set_shader_parameter("emission_strength", emission_strength)
		mesh_instance.material_override = material
	else:
		# Fallback material
		var standard_material = StandardMaterial3D.new()
		standard_material.albedo_color = primary_color
		standard_material.emission_enabled = true
		standard_material.emission = secondary_color
		standard_material.emission_energy_multiplier = emission_strength
		standard_material.metallic = 0.3
		standard_material.roughness = 0.6
		standard_material.cull_mode = BaseMaterial3D.CULL_DISABLED  # Double-sided
		mesh_instance.mesh.surface_set_material(0, standard_material)

func _process(delta):
	_time += delta * animation_speed

	# Animate the dress with flowing waves
	_animate_dress()

	# Follow skeleton if available
	if follow_skeleton and _skeleton and mesh_instance:
		_follow_skeleton_position()

func _animate_dress():
	# Safety checks
	if not _initialized:
		return
	if _base_vertices.is_empty() or not mesh_instance:
		return
	if _base_vertices.size() < u_steps + 1:
		return

	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)

	var animated_vertices = []

	for i in range(u_steps + 1):
		if i >= _base_vertices.size():
			break
		var row = []
		var u = float(i) / float(u_steps)

		for j in range(v_steps + 1):
			if j >= _base_vertices[i].size():
				break
			var base_pos = _base_vertices[i][j]
			var v = float(j) / float(v_steps)
			var angle = v * TAU

			# Animated wave offset
			var time_wave = sin(_time + angle * wave_frequency + u * TAU) * flutter_intensity * u
			var secondary_wave = cos(_time * 0.7 + angle * 3.0) * flutter_intensity * 0.5 * u

			# Apply animation
			var animated_pos = base_pos
			animated_pos.x += time_wave * cos(angle)
			animated_pos.z += time_wave * sin(angle)
			animated_pos.y += secondary_wave * 0.3

			# Swaying motion (like wind)
			var sway = sin(_time * 0.5) * flutter_intensity * u * 2.0
			animated_pos.x += sway

			row.append(animated_pos)
		animated_vertices.append(row)

	# Verify we have enough vertices before building
	if animated_vertices.size() < u_steps or animated_vertices[0].size() < v_steps:
		return

	# Rebuild mesh with animated vertices
	_build_mesh_faces(surface_tool, animated_vertices)
	surface_tool.generate_normals()

	var new_mesh = surface_tool.commit()
	if new_mesh and new_mesh.get_surface_count() > 0:
		var old_material = mesh_instance.material_override
		mesh_instance.mesh = new_mesh
		mesh_instance.material_override = old_material

func _follow_skeleton_position():
	if not _skeleton:
		return

	# Get attachment point from skeleton
	var attach_transform = Transform3D.IDENTITY

	if _hip_bone_idx >= 0:
		var bone_pose = _skeleton.get_bone_global_pose(_hip_bone_idx)
		attach_transform = _skeleton.global_transform * bone_pose
	elif _spine_bone_idx >= 0:
		var bone_pose = _skeleton.get_bone_global_pose(_spine_bone_idx)
		attach_transform = _skeleton.global_transform * bone_pose

	# Position dress at waist/hip level
	global_position = attach_transform.origin

	# Optionally rotate with the skeleton
	# global_rotation = attach_transform.basis.get_euler()

# Public API to change dress appearance at runtime
func set_colors(primary: Color, secondary: Color, wireframe: Color = Color.WHITE):
	primary_color = primary
	secondary_color = secondary
	wireframe_color = wireframe
	apply_material()

func set_wave_intensity(amplitude: float, flutter: float):
	wave_amplitude = amplitude
	flutter_intensity = flutter
	create_dress_mesh()  # Regenerate with new parameters
