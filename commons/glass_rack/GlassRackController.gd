# GlassRackController.gd - Modular Glass Apparatus System
# Extends GlassRackPipeBase for turtle-graphics pipe building
# Specialized for laboratory glassware with transparency and liquid flow
extends GlassRackPipeBase
class_name GlassRackController

signal apparatus_built
signal liquid_flow_started
signal liquid_flow_stopped

@export_group("Glass Material")
@export var glass_color: Color = Color(0.85, 0.92, 1.0, 0.25)
@export var glass_roughness: float = 0.0
@export var use_refraction: bool = true

@export_group("Dimensions")
@export var dimension_scale: float = 1.0

@export_group("Liquid")
@export var liquid_color: Color = Color(0.2, 0.8, 0.4, 0.6)
@export var show_liquid: bool = true
@export var liquid_flow_speed: float = 1.0

# Materials
var glass_material: StandardMaterial3D
var liquid_material: StandardMaterial3D

func _ready() -> void:
	# Set glass-appropriate defaults
	pipe_radius = 0.02
	segment_length = 0.3
	_setup_materials()
	super._ready()

func _setup_materials() -> void:
	# Glass material
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
	liquid_material.albedo_color = liquid_color
	liquid_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	liquid_material.emission_enabled = true
	liquid_material.emission = liquid_color
	liquid_material.emission_energy_multiplier = 0.5

# =============================================================================
# COMMAND REGISTRATION
# =============================================================================

func _register_custom_commands() -> void:
	# Existing commands
	_command_handlers["spiral"] = _cmd_spiral
	_command_handlers["coil"] = _cmd_spiral
	_command_handlers["wobbly"] = _cmd_wobbly
	_command_handlers["wavy"] = _cmd_wobbly
	_command_handlers["flask"] = _cmd_flask
	_command_handlers["bulb"] = _cmd_flask
	_command_handlers["junction"] = _cmd_junction
	_command_handlers["t"] = _cmd_junction
	_command_handlers["tee"] = _cmd_junction
	
	# New segment commands
	_command_handlers["sbend"] = _cmd_sbend
	_command_handlers["s"] = _cmd_sbend
	_command_handlers["ypipe"] = _cmd_ypipe
	_command_handlers["y"] = _cmd_ypipe
	_command_handlers["corner45"] = _cmd_corner45
	_command_handlers["c45"] = _cmd_corner45
	_command_handlers["ubend"] = _cmd_ubend
	_command_handlers["u180"] = _cmd_ubend
	_command_handlers["reducer"] = _cmd_reducer
	_command_handlers["reduce"] = _cmd_reducer
	_command_handlers["cap"] = _cmd_cap
	_command_handlers["end"] = _cmd_cap
	_command_handlers["drip"] = _cmd_drip
	_command_handlers["cross"] = _cmd_cross
	_command_handlers["x"] = _cmd_cross
	_command_handlers["condenser"] = _cmd_condenser
	
	# Branching commands (stack-based)
	_command_handlers["["] = _cmd_push
	_command_handlers["push"] = _cmd_push
	_command_handlers["]"] = _cmd_pop
	_command_handlers["pop"] = _cmd_pop

func _cmd_spiral() -> void:
	var spiral_height = segment_length * 2
	var spiral_radius = 0.08  # Match the default in _create_spiral_segment
	var stub_length = spiral_radius * 0.5
	var segment = _create_segment("spiral", {"height": spiral_height, "spiral_radius": spiral_radius})
	if segment:
		_place_segment(segment)
		# Total height: spiral + exit curve + exit stub
		var exit_y = spiral_height + spiral_radius * 0.5 + stub_length
		cursor_pos += Vector3.UP * exit_y
		# Spiral changes direction from forward to up
		_rotate_cursor_pitch(-PI / 2)

func _cmd_wobbly() -> void:
	var segment = _create_segment("wobbly", {"length": segment_length * 2})
	if segment:
		_place_segment(segment)
		_advance_cursor_forward(segment_length * 2)

func _cmd_flask() -> void:
	var segment = _create_segment("flask", {"radius": segment_length * 0.5})
	if segment:
		_place_segment(segment)
		_advance_cursor_forward(segment_length)

func _cmd_junction() -> void:
	var segment = _create_segment("junction", {})
	if segment:
		_place_segment(segment)
		_advance_cursor_forward(segment_length)

# New segment commands
func _cmd_sbend() -> void:
	var segment = _create_segment("sbend", {"length": segment_length, "offset": segment_length * 0.5})
	if segment:
		_place_segment(segment)
		var exit_offset = segment.get_meta("exit_offset") if segment.has_meta("exit_offset") else Vector3(0, 0, segment_length)
		cursor_pos += cursor_forward * exit_offset.z + cursor_right * exit_offset.x

func _cmd_ypipe() -> void:
	var segment = _create_segment("ypipe", {"length": segment_length, "branch_length": segment_length})
	if segment:
		_place_segment(segment)
		# After Y-pipe, cursor continues on out1 (left branch)
		# Use push/pop to also build out2
		_advance_cursor_forward(segment_length * 1.5)

func _cmd_corner45() -> void:
	var segment = _create_segment("corner45", {"corner_radius": segment_length})
	if segment:
		_place_segment(segment)
		_rotate_cursor_yaw(PI / 4)
		_advance_cursor_forward(segment_length * 0.7)

func _cmd_ubend() -> void:
	var segment = _create_segment("ubend", {"bend_radius": segment_length * 0.5})
	if segment:
		_place_segment(segment)
		# U-bend reverses direction and offsets
		_rotate_cursor_yaw(PI)
		cursor_pos += cursor_right * segment_length

func _cmd_reducer() -> void:
	var segment = _create_segment("reducer", {"length": segment_length * 0.5, "radius_in": pipe_radius, "radius_out": pipe_radius * 0.6})
	if segment:
		_place_segment(segment)
		_advance_cursor_forward(segment_length * 0.5)
		pipe_radius = pipe_radius * 0.6  # Update radius for subsequent segments

func _cmd_cap() -> void:
	var segment = _create_segment("cap", {"tube_radius": pipe_radius})
	if segment:
		_place_segment(segment)
		# Cap is terminal - don't advance

func _cmd_drip() -> void:
	var segment = _create_segment("drip", {"tube_radius": pipe_radius, "tip_length": segment_length * 0.3})
	if segment:
		_place_segment(segment)
		_advance_cursor_forward(segment_length * 0.3)

func _cmd_cross() -> void:
	var segment = _create_segment("cross", {"tube_radius": pipe_radius, "arm_length": segment_length})
	if segment:
		_place_segment(segment)
		_advance_cursor_forward(segment_length)

func _cmd_condenser() -> void:
	var segment = _create_segment("condenser", {"length": segment_length * 3, "inner_radius": pipe_radius * 0.5, "jacket_radius": pipe_radius * 2})
	if segment:
		_place_segment(segment)
		_advance_cursor_forward(segment_length * 3)

# Stack-based branching
var _cursor_stack: Array = []

func _cmd_push() -> void:
	# Save current cursor state
	_cursor_stack.push_back({
		"pos": cursor_pos,
		"forward": cursor_forward,
		"up": cursor_up,
		"right": cursor_right,
		"radius": pipe_radius
	})

func _cmd_pop() -> void:
	# Restore saved cursor state
	if _cursor_stack.is_empty():
		push_warning("GlassRackController: Pop with empty stack")
		return
	var state = _cursor_stack.pop_back()
	cursor_pos = state["pos"]
	cursor_forward = state["forward"]
	cursor_up = state["up"]
	cursor_right = state["right"]
	pipe_radius = state["radius"]

# =============================================================================
# SEGMENT CREATION
# =============================================================================

func _create_segment(segment_type: String, params: Dictionary) -> Node3D:
	var scaled_params = _scale_params(params)
	scaled_params["tube_radius"] = scaled_params.get("tube_radius", pipe_radius)

	match segment_type:
		"straight":
			return _create_straight_segment(scaled_params)
		"spiral":
			return _create_spiral_segment(scaled_params)
		"wobbly":
			return _create_wobbly_segment(scaled_params)
		"flask":
			return _create_flask_segment(scaled_params)
		"beaker":
			return _create_beaker_segment(scaled_params)
		"junction":
			return _create_junction_segment(scaled_params)
		"corner":
			return _create_corner_segment(scaled_params)
		# New segments using GlassPipeSegments
		"sbend":
			return GlassPipeSegments.create_sbend(scaled_params, glass_material, liquid_material, show_liquid)
		"ypipe":
			return GlassPipeSegments.create_ypipe(scaled_params, glass_material, liquid_material, show_liquid)
		"corner45":
			return GlassPipeSegments.create_corner45(scaled_params, glass_material, liquid_material, show_liquid)
		"ubend":
			return GlassPipeSegments.create_ubend(scaled_params, glass_material, liquid_material, show_liquid)
		"reducer":
			return GlassPipeSegments.create_reducer(scaled_params, glass_material, liquid_material, show_liquid)
		"cap":
			return GlassPipeSegments.create_cap(scaled_params, glass_material, liquid_material, show_liquid)
		"drip":
			return GlassPipeSegments.create_drip(scaled_params, glass_material, liquid_material, show_liquid)
		"cross":
			return GlassPipeSegments.create_cross(scaled_params, glass_material, liquid_material, show_liquid)
		"condenser":
			return GlassPipeSegments.create_condenser(scaled_params, glass_material, liquid_material, show_liquid)
		_:
			push_warning("GlassRackController: Unknown segment type: %s" % segment_type)
			return null

func _scale_params(params: Dictionary) -> Dictionary:
	# Apply a global dimension scale to geometry parameters.
	var scaled = params.duplicate()
	if is_equal_approx(dimension_scale, 1.0):
		return scaled
	
	for key in [
		"length", "height", "radius", "spiral_radius", "tube_radius",
		"corner_radius", "bend_radius", "branch_length", "tip_length",
		"arm_length", "offset", "inner_radius", "outer_radius",
		"jacket_radius", "neck_radius", "neck_length", "pole_radius",
		"width", "depth"
	]:
		if scaled.has(key):
			scaled[key] = float(scaled[key]) * dimension_scale
	
	for key in ["radius_in", "radius_out"]:
		if scaled.has(key):
			scaled[key] = maxf(0.0001, float(scaled[key]) * dimension_scale)
	
	return scaled

func _create_straight_segment(params: Dictionary) -> Node3D:
	var group = Node3D.new()
	var length = params.get("length", segment_length)
	var radius = params.get("radius", pipe_radius)

	var mesh_instance = MeshInstance3D.new()
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = radius
	cylinder.bottom_radius = radius
	cylinder.height = length
	mesh_instance.mesh = cylinder
	mesh_instance.material_override = glass_material
	mesh_instance.rotation.x = PI / 2  # Align with Z forward
	mesh_instance.position.z = length / 2
	group.add_child(mesh_instance)

	if show_liquid:
		var liquid = MeshInstance3D.new()
		var liquid_cyl = CylinderMesh.new()
		liquid_cyl.top_radius = radius * 0.7
		liquid_cyl.bottom_radius = radius * 0.7
		liquid_cyl.height = length
		liquid.mesh = liquid_cyl
		liquid.material_override = liquid_material
		liquid.rotation.x = PI / 2
		liquid.position.z = length / 2
		group.add_child(liquid)

	# Standardized ports
	GlassSegmentPorts.apply_standard_ports(group, radius, length)

	return group

func _create_spiral_segment(params: Dictionary) -> Node3D:
	var group = Node3D.new()
	var height = params.get("height", 0.5)
	var spiral_radius = params.get("spiral_radius", 0.08)
	var tube_radius = params.get("tube_radius", pipe_radius * 0.75)
	var turns = params.get("turns", 4)
	var resolution = params.get("resolution", 24)

	# Generate spiral with lead-in and lead-out for standard connection points
	var mesh = _generate_spiral_mesh_with_leads(height, spiral_radius, tube_radius, turns, resolution)
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = mesh
	mesh_instance.material_override = glass_material
	group.add_child(mesh_instance)

	if show_liquid:
		var liquid_mesh = _generate_spiral_mesh_with_leads(height, spiral_radius, tube_radius * 0.7, turns, resolution)
		var liquid_instance = MeshInstance3D.new()
		liquid_instance.mesh = liquid_mesh
		liquid_instance.material_override = liquid_material
		group.add_child(liquid_instance)

	# Ports match the stub positions
	var stub_length = spiral_radius * 0.5
	var exit_y = height + spiral_radius * 0.5 + stub_length
	GlassSegmentPorts.apply_ports(group, {
		"in": GlassSegmentPorts.create_port(Vector3(0, 0, -stub_length), Vector3.BACK, tube_radius),
		"out": GlassSegmentPorts.create_port(Vector3(0, exit_y, 0), Vector3.UP, tube_radius)
	})

	return group

func _create_wobbly_segment(params: Dictionary) -> Node3D:
	var group = Node3D.new()
	var length = params.get("length", 0.5)
	var tube_radius = params.get("tube_radius", pipe_radius)
	var amplitude = params.get("amplitude", 0.05)
	var frequency = params.get("frequency", 3.0)

	var mesh = _generate_wobbly_mesh(length, tube_radius, amplitude, frequency)
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = mesh
	mesh_instance.material_override = glass_material
	group.add_child(mesh_instance)

	if show_liquid:
		var liquid_mesh = _generate_wobbly_mesh(length, tube_radius * 0.7, amplitude, frequency)
		var liquid_instance = MeshInstance3D.new()
		liquid_instance.mesh = liquid_mesh
		liquid_instance.material_override = liquid_material
		group.add_child(liquid_instance)

	# Wobbly is like straight but wiggly
	GlassSegmentPorts.apply_standard_ports(group, tube_radius, length)

	return group

func _create_flask_segment(params: Dictionary) -> Node3D:
	var group = Node3D.new()
	var flask_radius = params.get("radius", 0.08)
	var neck_radius = params.get("neck_radius", pipe_radius)
	var neck_length = params.get("neck_length", 0.1)

	# Flask body (sphere)
	var body = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = flask_radius
	sphere.height = flask_radius * 2
	body.mesh = sphere
	body.material_override = glass_material
	body.position.z = flask_radius
	group.add_child(body)

	# Flask neck (cylinder)
	var neck = MeshInstance3D.new()
	var neck_cyl = CylinderMesh.new()
	neck_cyl.top_radius = neck_radius
	neck_cyl.bottom_radius = neck_radius * 1.5
	neck_cyl.height = neck_length
	neck.mesh = neck_cyl
	neck.material_override = glass_material
	neck.rotation.x = PI / 2
	neck.position.z = flask_radius * 2 + neck_length / 2
	group.add_child(neck)

	if show_liquid:
		var liquid_body = MeshInstance3D.new()
		var liquid_sphere = SphereMesh.new()
		liquid_sphere.radius = flask_radius * 0.8
		liquid_sphere.height = flask_radius * 1.6
		liquid_body.mesh = liquid_sphere
		liquid_body.material_override = liquid_material
		liquid_body.position = body.position
		group.add_child(liquid_body)

	# Flask: input at base (bottom of sphere), output at neck end
	var total_length = flask_radius * 2 + neck_length
	GlassSegmentPorts.apply_ports(group, {
		"in": GlassSegmentPorts.create_port(Vector3.ZERO, Vector3.BACK, neck_radius * 1.5),
		"out": GlassSegmentPorts.create_port(Vector3(0, 0, total_length), Vector3.FORWARD, neck_radius)
	})

	return group

func _create_junction_segment(params: Dictionary) -> Node3D:
	var group = Node3D.new()
	var radius = params.get("radius", pipe_radius)
	var length = params.get("length", segment_length * 0.5)

	# Main tube (forward)
	var main_tube = MeshInstance3D.new()
	var main_cyl = CylinderMesh.new()
	main_cyl.top_radius = radius
	main_cyl.bottom_radius = radius
	main_cyl.height = length
	main_tube.mesh = main_cyl
	main_tube.material_override = glass_material
	main_tube.rotation.x = PI / 2
	main_tube.position.z = length / 2
	group.add_child(main_tube)

	# Branch tube (right)
	var branch_tube = MeshInstance3D.new()
	branch_tube.mesh = main_cyl.duplicate()
	branch_tube.material_override = glass_material
	branch_tube.rotation.z = PI / 2
	branch_tube.position.x = length / 2
	branch_tube.position.z = length / 2
	group.add_child(branch_tube)

	# Junction sphere - sized to smoothly join the tubes
	var junction_sphere = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = radius * 1.1  # Just slightly larger than tube radius
	sphere.height = radius * 2.2
	junction_sphere.mesh = sphere
	junction_sphere.material_override = glass_material
	junction_sphere.position.z = length / 2
	group.add_child(junction_sphere)

	# T-junction has 3 ports
	GlassSegmentPorts.apply_ports(group, {
		"in": GlassSegmentPorts.create_port(Vector3.ZERO, Vector3.BACK, radius),
		"out": GlassSegmentPorts.create_port(Vector3(0, 0, length), Vector3.FORWARD, radius),
		"branch": GlassSegmentPorts.create_port(Vector3(length, 0, length / 2), Vector3.RIGHT, radius)
	})

	return group

func _create_corner_segment(params: Dictionary) -> Node3D:
	var group = Node3D.new()
	var radius = params.get("radius", pipe_radius)
	var corner_radius = params.get("corner_radius", segment_length)

	var mesh = _generate_corner_mesh(radius, corner_radius)
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = mesh
	mesh_instance.material_override = glass_material
	group.add_child(mesh_instance)

	if show_liquid:
		var liquid_mesh = _generate_corner_mesh(radius * 0.7, corner_radius)
		var liquid_instance = MeshInstance3D.new()
		liquid_instance.mesh = liquid_mesh
		liquid_instance.material_override = liquid_material
		group.add_child(liquid_instance)

	# 90° corner - exit is at corner_radius on X, corner_radius on Z, facing right
	var exit_pos = Vector3(corner_radius, 0, corner_radius)
	GlassSegmentPorts.apply_ports(group, {
		"in": GlassSegmentPorts.create_port(Vector3.ZERO, Vector3.BACK, radius),
		"out": GlassSegmentPorts.create_port(exit_pos, Vector3.RIGHT, radius)
	})

	return group

# =============================================================================
# MESH GENERATION
# =============================================================================

func _generate_spiral_mesh_with_leads(height: float, spiral_radius: float, tube_radius: float, turns: int, resolution: int) -> ArrayMesh:
	## Generates a clean spiral condenser coil
	## Entry: (0, 0, 0) facing BACK (-Z)  
	## Exit: (0, height, 0) facing UP (+Y)
	## Spiral is offset so entry/exit are centered
	
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var tube_sides = 8
	var all_rings: Array = []
	
	var total_points = resolution * turns
	var height_per_point = height / float(total_points)
	
	# Offset spiral so it's centered - spiral will be shifted by -spiral_radius on X
	var x_offset = -spiral_radius
	
	# === ENTRY STUB: Short straight section at bottom ===
	var stub_length = spiral_radius * 0.5
	for i in range(4):
		var t = float(i) / 3.0
		var center = Vector3(0, 0, -stub_length * (1.0 - t))  # From -stub to 0
		var tangent = Vector3.FORWARD
		var ring = _create_tube_ring_oriented(center, tangent, tube_radius, tube_sides)
		all_rings.append(ring)
	
	# === ENTRY CURVE: Quarter turn from +Z to spiral tangent ===
	var curve_res = 8
	for i in range(curve_res):
		var t = float(i) / float(curve_res)
		var angle = t * PI / 2
		# Curve from (0,0,0) going +Z to (0,0,spiral_radius) going tangent to spiral
		var center = Vector3(
			x_offset * (1.0 - cos(angle)),  # 0 to x_offset
			0,
			spiral_radius * sin(angle)  # 0 to spiral_radius
		)
		# Blend tangent from +Z to spiral start tangent
		var tangent = Vector3(
			sin(angle) * 0.5,
			t * height_per_point * 0.1,
			cos(angle)
		).normalized()
		var ring = _create_tube_ring_oriented(center, tangent, tube_radius, tube_sides)
		all_rings.append(ring)
	
	# === MAIN SPIRAL (offset so center is at x=0) ===
	for i in range(total_points + 1):
		var t = float(i) / float(total_points)
		var angle = t * TAU * turns

		var center = Vector3(
			cos(angle) * spiral_radius + x_offset,  # Offset so spiral crosses x=0
			t * height,
			sin(angle) * spiral_radius
		)

		var tangent = Vector3(
			-sin(angle) * spiral_radius,
			height_per_point,
			cos(angle) * spiral_radius
		).normalized()

		var ring = _create_tube_ring_oriented(center, tangent, tube_radius, tube_sides)
		all_rings.append(ring)
	
	# === EXIT CURVE: From spiral end to vertical ===
	var end_x = cos(turns * TAU) * spiral_radius + x_offset
	var end_z = sin(turns * TAU) * spiral_radius
	
	for i in range(1, curve_res + 1):
		var t = float(i) / float(curve_res)
		var angle = t * PI / 2
		var center = Vector3(
			end_x * (1.0 - t),  # Blend to x=0
			height + spiral_radius * 0.5 * sin(angle),
			end_z * (1.0 - t)   # Blend to z=0
		)
		var tangent = Vector3(
			-end_x * (1.0 - t) * 0.5,
			cos(angle) + 0.5,
			-end_z * (1.0 - t) * 0.5
		).normalized()
		var ring = _create_tube_ring_oriented(center, tangent, tube_radius, tube_sides)
		all_rings.append(ring)
	
	# === EXIT STUB: Short vertical section at top ===
	var exit_y = height + spiral_radius * 0.5
	for i in range(1, 4):
		var t = float(i) / 3.0
		var center = Vector3(0, exit_y + stub_length * t, 0)
		var tangent = Vector3.UP
		var ring = _create_tube_ring_oriented(center, tangent, tube_radius, tube_sides)
		all_rings.append(ring)
	
	_add_tube_faces(surface_tool, all_rings, tube_sides)
	surface_tool.generate_normals()
	return surface_tool.commit()

func _create_tube_ring_oriented(center: Vector3, tangent: Vector3, radius: float, sides: int) -> Array:
	var up = Vector3.UP
	if abs(tangent.dot(up)) > 0.99:
		up = Vector3.RIGHT
	var binormal = tangent.cross(up).normalized()
	var normal = binormal.cross(tangent).normalized()
	
	var ring: Array = []
	for j in range(sides):
		var tube_angle = TAU * j / sides
		var offset = normal * cos(tube_angle) * radius + binormal * sin(tube_angle) * radius
		ring.append(center + offset)
	return ring

func _generate_spiral_mesh(height: float, spiral_radius: float, tube_radius: float, turns: int, resolution: int) -> ArrayMesh:
	# Legacy spiral without leads (kept for reference)
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)

	var total_points = resolution * turns
	var tube_sides = 8
	var all_rings: Array = []

	for i in range(total_points + 1):
		var t = float(i) / total_points
		var angle = t * TAU * turns

		var center = Vector3(
			cos(angle) * spiral_radius,
			t * height,
			sin(angle) * spiral_radius
		)

		var tangent = Vector3(
			-sin(angle) * spiral_radius,
			height / total_points,
			cos(angle) * spiral_radius
		).normalized()

		var binormal = tangent.cross(Vector3.UP).normalized()
		var normal = binormal.cross(tangent).normalized()

		var ring: Array = []
		for j in range(tube_sides):
			var tube_angle = TAU * j / tube_sides
			var offset = normal * cos(tube_angle) * tube_radius + binormal * sin(tube_angle) * tube_radius
			ring.append(center + offset)
		all_rings.append(ring)

	_add_tube_faces(surface_tool, all_rings, tube_sides)
	surface_tool.generate_normals()
	return surface_tool.commit()

func _generate_wobbly_mesh(length: float, tube_radius: float, amplitude: float, frequency: float) -> ArrayMesh:
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)

	var resolution = 48
	var tube_sides = 8
	var all_rings: Array = []

	for i in range(resolution + 1):
		var t = float(i) / resolution
		var z = t * length

		var center = Vector3(
			sin(t * TAU * frequency) * amplitude,
			cos(t * TAU * frequency * 0.7) * amplitude * 0.5,
			z
		)

		var ring: Array = []
		for j in range(tube_sides):
			var tube_angle = TAU * j / tube_sides
			var offset = Vector3(cos(tube_angle), sin(tube_angle), 0) * tube_radius
			ring.append(center + offset)
		all_rings.append(ring)

	_add_tube_faces(surface_tool, all_rings, tube_sides)
	surface_tool.generate_normals()
	return surface_tool.commit()

func _generate_corner_mesh(tube_radius: float, corner_radius: float) -> ArrayMesh:
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)

	var resolution = 16
	var tube_sides = 8
	var all_rings: Array = []

	for i in range(resolution + 1):
		var t = float(i) / resolution
		var angle = t * PI / 2

		var center = Vector3(
			corner_radius * (1.0 - cos(angle)),
			0,
			corner_radius * sin(angle)
		)

		var tangent = Vector3(sin(angle), 0, cos(angle)).normalized()
		var binormal = Vector3(0, 1, 0)
		var normal = binormal.cross(tangent).normalized()

		var ring: Array = []
		for j in range(tube_sides):
			var tube_angle = TAU * j / tube_sides
			var offset = normal * cos(tube_angle) * tube_radius + binormal * sin(tube_angle) * tube_radius
			ring.append(center + offset)
		all_rings.append(ring)

	_add_tube_faces(surface_tool, all_rings, tube_sides)
	surface_tool.generate_normals()
	return surface_tool.commit()

func _add_tube_faces(st: SurfaceTool, rings: Array, sides: int) -> void:
	for i in range(rings.size() - 1):
		for j in range(sides):
			var j_next = (j + 1) % sides
			var v0 = rings[i][j]
			var v1 = rings[i][j_next]
			var v2 = rings[i + 1][j_next]
			var v3 = rings[i + 1][j]

			var face_normal = (v1 - v0).cross(v3 - v0).normalized()

			st.set_normal(face_normal)
			st.add_vertex(v0)
			st.set_normal(face_normal)
			st.add_vertex(v1)
			st.set_normal(face_normal)
			st.add_vertex(v2)

			st.set_normal(face_normal)
			st.add_vertex(v0)
			st.set_normal(face_normal)
			st.add_vertex(v2)
			st.set_normal(face_normal)
			st.add_vertex(v3)

# =============================================================================
# BEAKER SEGMENT
# =============================================================================

func _create_beaker_segment(params: Dictionary) -> Node3D:
	var group = Node3D.new()
	var radius = params.get("radius", 0.04)
	var height = params.get("height", 0.08)
	var wall_thickness = params.get("wall_thickness", 0.003)
	
	# Beaker outer wall (cylinder)
	var outer = MeshInstance3D.new()
	var outer_cyl = CylinderMesh.new()
	outer_cyl.top_radius = radius
	outer_cyl.bottom_radius = radius * 0.95
	outer_cyl.height = height
	outer.mesh = outer_cyl
	outer.material_override = glass_material
	outer.position.y = height / 2
	group.add_child(outer)
	
	# Beaker bottom (disk)
	var bottom = MeshInstance3D.new()
	var bottom_cyl = CylinderMesh.new()
	bottom_cyl.top_radius = radius * 0.95 - wall_thickness
	bottom_cyl.bottom_radius = radius * 0.95 - wall_thickness
	bottom_cyl.height = wall_thickness
	bottom.mesh = bottom_cyl
	bottom.material_override = glass_material
	bottom.position.y = wall_thickness / 2
	group.add_child(bottom)
	
	# Liquid inside
	if show_liquid:
		var liquid = MeshInstance3D.new()
		var liquid_cyl = CylinderMesh.new()
		liquid_cyl.top_radius = radius * 0.9
		liquid_cyl.bottom_radius = radius * 0.85
		liquid_cyl.height = height * 0.6
		liquid.mesh = liquid_cyl
		liquid.material_override = liquid_material
		liquid.position.y = height * 0.3
		group.add_child(liquid)
	
	# Beaker is terminal - open vessel, only has input at top
	GlassSegmentPorts.apply_ports(group, {
		"in": GlassSegmentPorts.create_port(Vector3(0, height, 0), Vector3.UP, radius)
	}, true)  # is_terminal = true
	
	return group

# =============================================================================
# FRAME / RACK STRUCTURE
# =============================================================================

var frame_material: StandardMaterial3D

func _build_frame(frame_config: Dictionary) -> void:
	if not frame_config.get("enabled", false):
		return
	
	var frame_root = Node3D.new()
	frame_root.name = "Frame"
	add_child(frame_root)
	
	# Frame material
	frame_material = StandardMaterial3D.new()
	if frame_config.has("material"):
		var mat = frame_config["material"]
		if mat.has("color") and mat["color"] is Array:
			var c = mat["color"]
			frame_material.albedo_color = Color(c[0], c[1], c[2], c[3] if c.size() > 3 else 1.0)
		frame_material.metallic = mat.get("metallic", 0.8)
		frame_material.roughness = mat.get("roughness", 0.3)
	else:
		frame_material.albedo_color = Color(0.3, 0.3, 0.35, 1.0)
		frame_material.metallic = 0.8
		frame_material.roughness = 0.3
	
	var height = frame_config.get("height", 0.8)
	var width = frame_config.get("width", 0.4)
	var depth = frame_config.get("depth", 0.3)
	var pole_radius = frame_config.get("pole_radius", 0.008)
	var levels = frame_config.get("levels", 3)
	
	# Corner positions
	var corners = [
		Vector3(-width/2, 0, -depth/2),
		Vector3(width/2, 0, -depth/2),
		Vector3(width/2, 0, depth/2),
		Vector3(-width/2, 0, depth/2)
	]
	
	# Vertical poles
	for corner in corners:
		var pole = _create_pole(pole_radius, height)
		pole.position = corner + Vector3(0, height/2, 0)
		frame_root.add_child(pole)
	
	# Horizontal bars at each level
	for level in range(levels + 1):
		var y = (float(level) / levels) * height
		
		# Front and back bars
		for z in [-depth/2, depth/2]:
			var bar = _create_pole(pole_radius * 0.7, width)
			bar.position = Vector3(0, y, z)
			bar.rotation.z = PI / 2
			frame_root.add_child(bar)
		
		# Side bars
		for x in [-width/2, width/2]:
			var bar = _create_pole(pole_radius * 0.7, depth)
			bar.position = Vector3(x, y, 0)
			bar.rotation.x = PI / 2
			frame_root.add_child(bar)

func _create_pole(radius: float, length: float) -> MeshInstance3D:
	var pole = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = radius
	cyl.bottom_radius = radius
	cyl.height = length
	cyl.radial_segments = 12
	pole.mesh = cyl
	pole.material_override = frame_material
	return pole

# =============================================================================
# VESSELS ARRAY BUILDING
# =============================================================================

func _build_vessels(vessels: Array) -> void:
	for vessel_data in vessels:
		if not vessel_data is Dictionary:
			continue
		
		var vessel_type = vessel_data.get("type", "flask")
		var params = vessel_data.get("params", {})
		var pos_array = vessel_data.get("position", [0, 0, 0])
		var position = Vector3(pos_array[0], pos_array[1], pos_array[2])
		
		var vessel: Node3D = null
		match vessel_type:
			"flask":
				vessel = _create_flask_segment(params)
			"beaker":
				vessel = _create_beaker_segment(params)
			"spiral":
				vessel = _create_spiral_segment(params)
			"straight":
				vessel = _create_straight_segment(params)
			"wobbly":
				vessel = _create_wobbly_segment(params)
			"junction":
				vessel = _create_junction_segment(params)
		
		if vessel:
			vessel.name = vessel_data.get("id", "Vessel")
			vessel.position = position
			if not _segments_root:
				_segments_root = Node3D.new()
				_segments_root.name = "Segments"
				add_child(_segments_root)
			_segments_root.add_child(vessel)

# =============================================================================
# CONFIG OVERRIDE
# =============================================================================

func load_config_from_dict(data: Dictionary) -> void:
	# Apply materials from config
	if data.has("materials"):
		var mats = data["materials"]
		if mats.has("glass_color") and mats["glass_color"] is Array:
			var c = mats["glass_color"]
			glass_color = Color(c[0], c[1], c[2], c[3] if c.size() > 3 else 0.25)
		if mats.has("liquid_color") and mats["liquid_color"] is Array:
			var c = mats["liquid_color"]
			liquid_color = Color(c[0], c[1], c[2], c[3] if c.size() > 3 else 0.6)
		if mats.has("show_liquid"):
			show_liquid = mats["show_liquid"]
		_setup_materials()
	
	# Build frame if specified
	if data.has("frame"):
		_build_frame(data["frame"])
	
	# Build vessels if specified
	if data.has("vessels"):
		_build_vessels(data["vessels"])
	elif data.has("path") or data.has("segments"):
		# Fall back to base class handling
		super.load_config_from_dict(data)
	
	apparatus_built.emit()

# =============================================================================
# LIQUID ANIMATION
# =============================================================================

func start_liquid_flow() -> void:
	liquid_flow_started.emit()

func stop_liquid_flow() -> void:
	liquid_flow_stopped.emit()

# =============================================================================
# GRID SYSTEM INTEGRATION
# =============================================================================

func apply_grid_config(config: Dictionary) -> void:
	# Handle glass-specific config first
	if config.has("glass_color") and config["glass_color"] is Array:
		var c = config["glass_color"]
		glass_color = Color(c[0], c[1], c[2], c[3] if c.size() > 3 else 0.25)
		_setup_materials()

	if config.has("liquid_color") and config["liquid_color"] is Array:
		var c = config["liquid_color"]
		liquid_color = Color(c[0], c[1], c[2], c[3] if c.size() > 3 else 0.6)
		_setup_materials()

	if config.has("show_liquid"):
		show_liquid = config["show_liquid"]

	# Call base class for path/config handling
	super.apply_grid_config(config)

func _get_config_directory() -> String:
	return "res://commons/glass_rack/configs"

# =============================================================================
# LEGACY COMPATIBILITY
# =============================================================================

## Build apparatus (legacy API - now calls generate_from_code)
func build_apparatus() -> void:
	# For backwards compatibility with old configs
	pass
