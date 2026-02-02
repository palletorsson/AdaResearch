# GlassPipeSegments.gd
# Segment generation functions for glass pipe system
# Separated for clarity - used by GlassRackController
extends RefCounted
class_name GlassPipeSegments

# =============================================================================
# S-BEND SEGMENT
# =============================================================================

static func create_sbend(params: Dictionary, glass_mat: Material, liquid_mat: Material, show_liquid: bool) -> Node3D:
	var group = Node3D.new()
	var length = params.get("length", 0.3)
	var offset = params.get("offset", 0.1)  # Horizontal offset
	var tube_radius = params.get("tube_radius", 0.015)
	var resolution = params.get("resolution", 24)
	
	var mesh = _generate_sbend_mesh(length, offset, tube_radius, resolution)
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = mesh
	mesh_instance.material_override = glass_mat
	group.add_child(mesh_instance)
	
	if show_liquid:
		var liquid_mesh = _generate_sbend_mesh(length, offset, tube_radius * 0.7, resolution)
		var liquid_instance = MeshInstance3D.new()
		liquid_instance.mesh = liquid_mesh
		liquid_instance.material_override = liquid_mat
		group.add_child(liquid_instance)
	
	# Store exit offset for cursor advancement
	group.set_meta("exit_offset", Vector3(offset, 0, length))
	
	return group

static func _generate_sbend_mesh(length: float, offset: float, tube_radius: float, resolution: int) -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var tube_sides = 8
	var all_rings: Array = []
	
	# S-curve using smooth sine interpolation
	for i in range(resolution + 1):
		var t = float(i) / resolution
		var z = t * length
		# Smooth S-curve: offset * (0.5 - 0.5 * cos(PI * t))
		var x = offset * (0.5 - 0.5 * cos(PI * t))
		
		var center = Vector3(x, 0, z)
		
		# Calculate tangent for proper tube orientation
		var dz = length / resolution
		var dx = offset * 0.5 * PI * sin(PI * t) / resolution
		var tangent = Vector3(dx, 0, dz).normalized()
		
		var ring = _create_tube_ring(center, tangent, tube_radius, tube_sides)
		all_rings.append(ring)
	
	_add_tube_faces(st, all_rings, tube_sides)
	st.generate_normals()
	return st.commit()

# =============================================================================
# Y-PIPE SEGMENT
# =============================================================================

static func create_ypipe(params: Dictionary, glass_mat: Material, liquid_mat: Material, show_liquid: bool) -> Node3D:
	var group = Node3D.new()
	var length = params.get("length", 0.2)
	var spread_angle = params.get("spread_angle", 30.0)  # Degrees
	var tube_radius = params.get("tube_radius", 0.015)
	var branch_length = params.get("branch_length", 0.15)
	
	# Main inlet tube (short)
	var inlet_length = length * 0.3
	var inlet = _create_straight_tube(inlet_length, tube_radius, glass_mat)
	inlet.position.z = inlet_length / 2
	inlet.rotation.x = PI / 2
	group.add_child(inlet)
	
	if show_liquid:
		var inlet_liquid = _create_straight_tube(inlet_length, tube_radius * 0.7, liquid_mat)
		inlet_liquid.position = inlet.position
		inlet_liquid.rotation = inlet.rotation
		group.add_child(inlet_liquid)
	
	# Junction sphere
	var junction_pos = Vector3(0, 0, inlet_length)
	var junction = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = tube_radius * 1.8
	sphere.height = tube_radius * 3.6
	junction.mesh = sphere
	junction.material_override = glass_mat
	junction.position = junction_pos
	group.add_child(junction)
	
	# Two branch tubes
	var angle_rad = deg_to_rad(spread_angle)
	var branches = [
		{"angle": -angle_rad, "name": "out1"},
		{"angle": angle_rad, "name": "out2"}
	]
	
	for branch in branches:
		var branch_tube = _create_straight_tube(branch_length, tube_radius, glass_mat)
		branch_tube.position = junction_pos
		branch_tube.rotation.x = PI / 2
		branch_tube.rotation.y = branch.angle
		# Offset along the branch direction
		var dir = Vector3(sin(branch.angle), 0, cos(branch.angle))
		branch_tube.position += dir * branch_length / 2
		group.add_child(branch_tube)
		
		if show_liquid:
			var branch_liquid = _create_straight_tube(branch_length, tube_radius * 0.7, liquid_mat)
			branch_liquid.position = branch_tube.position
			branch_liquid.rotation = branch_tube.rotation
			group.add_child(branch_liquid)
	
	# Store port positions for connection system
	var exit_dist = inlet_length + branch_length
	group.set_meta("ports", {
		"in": {"position": Vector3.ZERO, "direction": Vector3.BACK},
		"out1": {"position": Vector3(-sin(angle_rad) * branch_length, 0, exit_dist * cos(angle_rad)), 
				 "direction": Vector3(-sin(angle_rad), 0, cos(angle_rad))},
		"out2": {"position": Vector3(sin(angle_rad) * branch_length, 0, exit_dist * cos(angle_rad)), 
				 "direction": Vector3(sin(angle_rad), 0, cos(angle_rad))}
	})
	
	return group

# =============================================================================
# 45° CORNER SEGMENT
# =============================================================================

static func create_corner45(params: Dictionary, glass_mat: Material, liquid_mat: Material, show_liquid: bool) -> Node3D:
	var group = Node3D.new()
	var tube_radius = params.get("tube_radius", 0.015)
	var corner_radius = params.get("corner_radius", 0.1)
	
	var mesh = _generate_corner_mesh(tube_radius, corner_radius, PI / 4)  # 45 degrees
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = mesh
	mesh_instance.material_override = glass_mat
	group.add_child(mesh_instance)
	
	if show_liquid:
		var liquid_mesh = _generate_corner_mesh(tube_radius * 0.7, corner_radius, PI / 4)
		var liquid_instance = MeshInstance3D.new()
		liquid_instance.mesh = liquid_mesh
		liquid_instance.material_override = liquid_mat
		group.add_child(liquid_instance)
	
	return group

# =============================================================================
# U-BEND SEGMENT
# =============================================================================

static func create_ubend(params: Dictionary, glass_mat: Material, liquid_mat: Material, show_liquid: bool) -> Node3D:
	var group = Node3D.new()
	var tube_radius = params.get("tube_radius", 0.015)
	var bend_radius = params.get("bend_radius", 0.08)
	
	var mesh = _generate_corner_mesh(tube_radius, bend_radius, PI)  # 180 degrees
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = mesh
	mesh_instance.material_override = glass_mat
	group.add_child(mesh_instance)
	
	if show_liquid:
		var liquid_mesh = _generate_corner_mesh(tube_radius * 0.7, bend_radius, PI)
		var liquid_instance = MeshInstance3D.new()
		liquid_instance.mesh = liquid_mesh
		liquid_instance.material_override = liquid_mat
		group.add_child(liquid_instance)
	
	# U-bend reverses direction
	group.set_meta("reverses_direction", true)
	group.set_meta("exit_offset", Vector3(bend_radius * 2, 0, 0))
	
	return group

# =============================================================================
# REDUCER SEGMENT (diameter transition)
# =============================================================================

static func create_reducer(params: Dictionary, glass_mat: Material, liquid_mat: Material, show_liquid: bool) -> Node3D:
	var group = Node3D.new()
	var length = params.get("length", 0.1)
	var radius_in = params.get("radius_in", 0.02)
	var radius_out = params.get("radius_out", 0.012)
	
	var mesh_instance = MeshInstance3D.new()
	var cone = CylinderMesh.new()
	cone.top_radius = radius_out
	cone.bottom_radius = radius_in
	cone.height = length
	mesh_instance.mesh = cone
	mesh_instance.material_override = glass_mat
	mesh_instance.rotation.x = PI / 2
	mesh_instance.position.z = length / 2
	group.add_child(mesh_instance)
	
	if show_liquid:
		var liquid = MeshInstance3D.new()
		var liquid_cone = CylinderMesh.new()
		liquid_cone.top_radius = radius_out * 0.7
		liquid_cone.bottom_radius = radius_in * 0.7
		liquid_cone.height = length
		liquid.mesh = liquid_cone
		liquid.material_override = liquid_mat
		liquid.rotation.x = PI / 2
		liquid.position.z = length / 2
		group.add_child(liquid)
	
	group.set_meta("exit_radius", radius_out)
	
	return group

# =============================================================================
# CAP SEGMENT (sealed end)
# =============================================================================

static func create_cap(params: Dictionary, glass_mat: Material, _liquid_mat: Material, _show_liquid: bool) -> Node3D:
	var group = Node3D.new()
	var tube_radius = params.get("tube_radius", 0.015)
	
	# Hemispherical cap
	var cap = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = tube_radius
	sphere.height = tube_radius * 2
	sphere.is_hemisphere = true
	cap.mesh = sphere
	cap.material_override = glass_mat
	cap.rotation.x = -PI / 2
	group.add_child(cap)
	
	# Short tube stub
	var stub = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = tube_radius
	cyl.bottom_radius = tube_radius
	cyl.height = tube_radius * 2
	stub.mesh = cyl
	stub.material_override = glass_mat
	stub.rotation.x = PI / 2
	stub.position.z = -tube_radius
	group.add_child(stub)
	
	group.set_meta("is_terminal", true)
	
	return group

# =============================================================================
# DRIP TIP SEGMENT
# =============================================================================

static func create_drip(params: Dictionary, glass_mat: Material, liquid_mat: Material, show_liquid: bool) -> Node3D:
	var group = Node3D.new()
	var tube_radius = params.get("tube_radius", 0.015)
	var tip_length = params.get("tip_length", 0.05)
	
	# Tapered tip
	var tip = MeshInstance3D.new()
	var cone = CylinderMesh.new()
	cone.top_radius = tube_radius * 0.3
	cone.bottom_radius = tube_radius
	cone.height = tip_length
	tip.mesh = cone
	tip.material_override = glass_mat
	tip.rotation.x = PI / 2
	tip.position.z = tip_length / 2
	group.add_child(tip)
	
	if show_liquid:
		# Drip droplet
		var drop = MeshInstance3D.new()
		var drop_mesh = SphereMesh.new()
		drop_mesh.radius = tube_radius * 0.4
		drop_mesh.height = tube_radius * 0.8
		drop.mesh = drop_mesh
		drop.material_override = liquid_mat
		drop.position.z = tip_length + tube_radius * 0.3
		group.add_child(drop)
	
	group.set_meta("is_terminal", true)
	
	return group

# =============================================================================
# CROSS JUNCTION (4-way)
# =============================================================================

static func create_cross(params: Dictionary, glass_mat: Material, liquid_mat: Material, show_liquid: bool) -> Node3D:
	var group = Node3D.new()
	var tube_radius = params.get("tube_radius", 0.015)
	var arm_length = params.get("arm_length", 0.1)
	
	# Central sphere
	var center = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = tube_radius * 2.0
	center.mesh = sphere
	center.material_override = glass_mat
	group.add_child(center)
	
	# Four arms: forward, back, left, right
	var directions = [
		{"dir": Vector3.FORWARD, "name": "out"},
		{"dir": Vector3.BACK, "name": "in"},
		{"dir": Vector3.LEFT, "name": "left"},
		{"dir": Vector3.RIGHT, "name": "right"}
	]
	
	for arm_data in directions:
		var arm = _create_straight_tube(arm_length, tube_radius, glass_mat)
		arm.position = arm_data.dir * arm_length / 2
		if arm_data.dir.x != 0:
			arm.rotation.z = PI / 2
		else:
			arm.rotation.x = PI / 2
		group.add_child(arm)
		
		if show_liquid:
			var liquid_arm = _create_straight_tube(arm_length, tube_radius * 0.7, liquid_mat)
			liquid_arm.position = arm.position
			liquid_arm.rotation = arm.rotation
			group.add_child(liquid_arm)
	
	return group

# =============================================================================
# CONDENSER (jacketed tube - tube within tube)
# =============================================================================

static func create_condenser(params: Dictionary, glass_mat: Material, liquid_mat: Material, show_liquid: bool) -> Node3D:
	var group = Node3D.new()
	var length = params.get("length", 0.4)
	var inner_radius = params.get("inner_radius", 0.01)
	var outer_radius = params.get("outer_radius", 0.025)
	var jacket_radius = params.get("jacket_radius", 0.035)
	
	# Outer jacket
	var jacket = MeshInstance3D.new()
	var jacket_cyl = CylinderMesh.new()
	jacket_cyl.top_radius = jacket_radius
	jacket_cyl.bottom_radius = jacket_radius
	jacket_cyl.height = length * 0.8
	jacket.mesh = jacket_cyl
	jacket.material_override = glass_mat
	jacket.rotation.x = PI / 2
	jacket.position.z = length / 2
	group.add_child(jacket)
	
	# Inner tube (runs full length)
	var inner = MeshInstance3D.new()
	var inner_cyl = CylinderMesh.new()
	inner_cyl.top_radius = inner_radius
	inner_cyl.bottom_radius = inner_radius
	inner_cyl.height = length
	inner.mesh = inner_cyl
	inner.material_override = glass_mat
	inner.rotation.x = PI / 2
	inner.position.z = length / 2
	group.add_child(inner)
	
	if show_liquid:
		# Coolant in jacket space
		var coolant = MeshInstance3D.new()
		var cool_cyl = CylinderMesh.new()
		cool_cyl.top_radius = jacket_radius * 0.85
		cool_cyl.bottom_radius = jacket_radius * 0.85
		cool_cyl.height = length * 0.75
		coolant.mesh = cool_cyl
		coolant.material_override = liquid_mat
		coolant.rotation.x = PI / 2
		coolant.position.z = length / 2
		group.add_child(coolant)
		
		# Inner flow
		var inner_liquid = MeshInstance3D.new()
		var inner_liq_cyl = CylinderMesh.new()
		inner_liq_cyl.top_radius = inner_radius * 0.7
		inner_liq_cyl.bottom_radius = inner_radius * 0.7
		inner_liq_cyl.height = length
		inner_liquid.mesh = inner_liq_cyl
		# Different color for inner flow
		var hot_mat = liquid_mat.duplicate()
		hot_mat.albedo_color = Color(1.0, 0.4, 0.2, 0.6)
		hot_mat.emission = Color(1.0, 0.3, 0.1)
		inner_liquid.material_override = hot_mat
		inner_liquid.rotation.x = PI / 2
		inner_liquid.position.z = length / 2
		group.add_child(inner_liquid)
	
	# Side ports for coolant
	var port_positions = [
		Vector3(0, jacket_radius, length * 0.2),
		Vector3(0, -jacket_radius, length * 0.8)
	]
	for pos in port_positions:
		var port = MeshInstance3D.new()
		var port_cyl = CylinderMesh.new()
		port_cyl.top_radius = inner_radius
		port_cyl.bottom_radius = inner_radius
		port_cyl.height = jacket_radius * 0.5
		port.mesh = port_cyl
		port.material_override = glass_mat
		port.position = pos
		if pos.y > 0:
			port.rotation.x = 0
		else:
			port.rotation.x = PI
		group.add_child(port)
	
	return group

# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

static func _create_straight_tube(length: float, radius: float, material: Material) -> MeshInstance3D:
	var tube = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = radius
	cyl.bottom_radius = radius
	cyl.height = length
	tube.mesh = cyl
	tube.material_override = material
	return tube

static func _create_tube_ring(center: Vector3, tangent: Vector3, radius: float, sides: int) -> Array:
	var ring: Array = []
	
	# Find perpendicular vectors
	var up = Vector3.UP
	if abs(tangent.dot(up)) > 0.99:
		up = Vector3.RIGHT
	var binormal = tangent.cross(up).normalized()
	var normal = binormal.cross(tangent).normalized()
	
	for j in range(sides):
		var angle = TAU * j / sides
		var offset = normal * cos(angle) * radius + binormal * sin(angle) * radius
		ring.append(center + offset)
	
	return ring

static func _generate_corner_mesh(tube_radius: float, corner_radius: float, bend_angle: float) -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var resolution = int(16 * bend_angle / (PI / 2))  # Scale resolution with angle
	var tube_sides = 8
	var all_rings: Array = []
	
	for i in range(resolution + 1):
		var t = float(i) / resolution
		var angle = t * bend_angle
		
		var center = Vector3(
			corner_radius * (1.0 - cos(angle)),
			0,
			corner_radius * sin(angle)
		)
		
		var tangent = Vector3(sin(angle), 0, cos(angle)).normalized()
		var ring = _create_tube_ring(center, tangent, tube_radius, tube_sides)
		all_rings.append(ring)
	
	_add_tube_faces(st, all_rings, tube_sides)
	st.generate_normals()
	return st.commit()

static func _add_tube_faces(st: SurfaceTool, rings: Array, sides: int) -> void:
	for i in range(rings.size() - 1):
		for j in range(sides):
			var j_next = (j + 1) % sides
			var v0 = rings[i][j]
			var v1 = rings[i][j_next]
			var v2 = rings[i + 1][j_next]
			var v3 = rings[i + 1][j]
			
			st.add_vertex(v0)
			st.add_vertex(v1)
			st.add_vertex(v2)
			
			st.add_vertex(v0)
			st.add_vertex(v2)
			st.add_vertex(v3)
