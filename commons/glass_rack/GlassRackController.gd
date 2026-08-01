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

@export_group("DNA")
## AXIS — WHAT THE GLASS ADMITS ABOUT ITSELF.
##
## Borosilicate is specified to be invisible: the whole point of the vessel is that you
## look THROUGH it at the reaction and never at it. It never manages this. There is always
## a rim, a meniscus, a reflection, a stain, a number scratched into the shoulder. This
## axis decides how much of that the apparatus is allowed to show, which is the same
## question as whether an instrument can be neutral.
##
##   none      the discipline's own picture of itself — clean glass, contents legible
##             straight through, nothing recording that a hand was ever here. The legacy
##             lineage, byte for byte.
##   bench     mid-job — a retort stand with two boss clamps gripping the column, marker
##             tape collars where somebody drew the level, a stirring rod, a scrawled
##             plate taped to the front. The instrument is visibly being USED by someone.
##   residue   the glass keeps the record — crust in every bottom, a tide ring at the old
##             fill line, drips down the outside, and an etched band that has gone opaque.
##             Transparency fails exactly where the work happened.
##   exhibit   racked as evidence — a seal over every mouth, a numbered tag wired to every
##             neck, a barcoded card on the front rail. Nobody is running this apparatus;
##             it is being HELD, and the labels have become the readable part.
##
## The etched band is the pivot. It is the only dressing that destroys the transparency
## the whole family is built on, which is why `residue` reads as an accusation and not as
## dirt. Shared word for word with [[chemicalapparatus]] and [[samplevialrack]] — one
## bench, one vocabulary, so a lab whose vials are sealed as evidence cannot have a
## distillation rack that still reads as pristine stock.
##
## NAMED `admission` AND NOT `witness`: [[lab_room]] already declares a `witness` axis and
## it means something else entirely — pane | none | port | sash, the aperture you look
## into the room THROUGH. Config keys are one flat global namespace, so a map placing a
## room and a rack and passing one word would be addressing two different arguments.
@export var admission: String = "none"
const ADMISSIONS: PackedStringArray = ["none", "bench", "residue", "exhibit"]

# Materials
var glass_material: StandardMaterial3D
var liquid_material: StandardMaterial3D

func _ready() -> void:
	# Set glass-appropriate defaults
	pipe_radius = 0.02
	segment_length = 0.3
	_setup_materials()
	super._ready()
	# ADMISSION dressing, appended after the apparatus exists so every node index and
	# transform above is untouched. "none" adds nothing at all and returns immediately.
	_read_admission_meta()
	_dress_admission()

func _setup_materials() -> void:
	# Glass material — enhanced borosilicate look
	glass_material = StandardMaterial3D.new()
	glass_material.albedo_color = glass_color
	glass_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass_material.metallic = 0.05
	glass_material.roughness = max(glass_roughness, 0.02)
	glass_material.specular = 0.8
	glass_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	glass_material.rim_enabled = true
	glass_material.rim = 0.3
	glass_material.rim_tint = 0.2
	if use_refraction:
		glass_material.refraction_enabled = true
		glass_material.refraction_scale = 0.08

	# Liquid material — vivid chemical glow
	liquid_material = StandardMaterial3D.new()
	liquid_material.albedo_color = liquid_color
	liquid_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	liquid_material.emission_enabled = true
	liquid_material.emission = liquid_color
	liquid_material.emission_energy_multiplier = 1.0
	liquid_material.rim_enabled = true
	liquid_material.rim = 0.15
	liquid_material.rim_tint = 0.5

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
	_command_handlers["beaker"] = _cmd_beaker
	
	# Branching commands (stack-based)
	_command_handlers["["] = _cmd_push
	_command_handlers["push"] = _cmd_push
	_command_handlers["]"] = _cmd_pop
	_command_handlers["pop"] = _cmd_pop

func _cmd_spiral() -> void:
	var spiral_height = segment_length * 2
	var spiral_radius = 0.08
	var segment = _create_segment("spiral", {"height": spiral_height, "spiral_radius": spiral_radius})
	if segment:
		_place_segment(segment)
		# Use port metadata for accurate cursor advancement
		_advance_cursor_from_segment(segment, {"height": spiral_height})

func _cmd_wobbly() -> void:
	var length = segment_length * 2
	var segment = _create_segment("wobbly", {"length": length})
	if segment:
		_place_segment(segment)
		_advance_cursor_forward(length)

func _cmd_flask() -> void:
	var flask_radius = segment_length * 0.5
	var neck_length = 0.1 * dimension_scale
	var segment = _create_segment("flask", {"radius": flask_radius, "neck_length": neck_length})
	if segment:
		_place_segment(segment)
		# Flask actual length: diameter + neck
		var total = flask_radius * 2 + neck_length
		_advance_cursor_forward(total)

func _cmd_junction() -> void:
	var length = segment_length * 0.5
	var segment = _create_segment("junction", {"length": length})
	if segment:
		_place_segment(segment)
		_advance_cursor_forward(length)

# New segment commands
func _cmd_sbend() -> void:
	var segment = _create_segment("sbend", {"length": segment_length, "offset": segment_length * 0.5})
	if segment:
		_place_segment(segment)
		_advance_cursor_from_segment(segment, {"length": segment_length})

func _cmd_ypipe() -> void:
	var segment = _create_segment("ypipe", {"length": segment_length, "branch_length": segment_length})
	if segment:
		_place_segment(segment)
		_advance_cursor_from_segment(segment, {"length": segment_length})

func _cmd_corner45() -> void:
	var segment = _create_segment("corner45", {"corner_radius": segment_length})
	if segment:
		_place_segment(segment)
		_advance_cursor_from_segment(segment, {"corner_radius": segment_length})

func _cmd_ubend() -> void:
	var segment = _create_segment("ubend", {"bend_radius": segment_length * 0.5})
	if segment:
		_place_segment(segment)
		_advance_cursor_from_segment(segment, {"bend_radius": segment_length * 0.5})

func _cmd_reducer() -> void:
	var length = segment_length * 0.5
	var segment = _create_segment("reducer", {"length": length, "radius_in": pipe_radius, "radius_out": pipe_radius * 0.6})
	if segment:
		_place_segment(segment)
		_advance_cursor_forward(length)
		pipe_radius = pipe_radius * 0.6

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
		_advance_cursor_from_segment(segment, {"arm_length": segment_length})

func _cmd_condenser() -> void:
	var length = segment_length * 3
	var segment = _create_segment("condenser", {"length": length, "inner_radius": pipe_radius * 0.5, "jacket_radius": pipe_radius * 2})
	if segment:
		_place_segment(segment)
		_advance_cursor_forward(length)

func _cmd_beaker() -> void:
	var beaker_radius = segment_length * 0.4
	var beaker_height = segment_length * 0.6
	var segment = _create_segment("beaker", {"radius": beaker_radius, "height": beaker_height})
	if segment:
		_place_segment(segment)
		# Beaker is terminal — no cursor advancement

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
		frame_material.albedo_color = Color(0.22, 0.22, 0.26, 1.0)
		frame_material.metallic = 0.85
		frame_material.roughness = 0.2
		frame_material.specular = 0.7
	
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

	if config.has("admission"):
		admission = _pick_admission(str(config["admission"]))

	# Call base class for path/config handling
	super.apply_grid_config(config)

	# Re-dress last, after any rebuild the base class may have run. Idempotent: the old
	# Admission node is dropped first, and "none" leaves nothing behind.
	_dress_admission()

func _get_config_directory() -> String:
	return "res://commons/glass_rack/configs"

# =============================================================================
# LEGACY COMPATIBILITY
# =============================================================================

## Build apparatus (legacy API - now calls generate_from_code)
func build_apparatus() -> void:
	# For backwards compatibility with old configs
	pass

# =============================================================================
# ADMISSION — what the glass admits about itself
# =============================================================================
# Everything below is APPENDED. It runs after the apparatus is built, adds one
# child named "Admission" and touches nothing that already exists. `admission ==
# "none"` returns before that child is even created, so the legacy build is
# reproduced node for node.

const ADMISSION_ROOT := "Admission"


func _read_admission_meta() -> void:
	## The grid stamps config_<key> metadata BEFORE add_child, so this is readable
	## from _ready(). An unknown word keeps the default rather than blanking the axis.
	if has_meta("config_admission"):
		admission = _pick_admission(str(get_meta("config_admission")))


func _pick_admission(raw: String) -> String:
	var w: String = raw.strip_edges().to_lower()
	return w if ADMISSIONS.has(w) else admission


func _dress_admission() -> void:
	var old: Node = get_node_or_null(ADMISSION_ROOT)
	if old:
		remove_child(old)
		old.queue_free()
	if admission == "none":
		return

	var boxes: Array = _admission_vessel_boxes()
	var whole: AABB = _admission_subtree_box(self)
	if boxes.is_empty() or whole.size.length() < 0.001:
		return

	var root := Node3D.new()
	root.name = ADMISSION_ROOT
	add_child(root)

	match admission:
		"bench":
			_admission_bench(root, boxes, whole)
		"residue":
			_admission_residue(root, boxes)
		"exhibit":
			_admission_exhibit(root, boxes, whole)
		_:
			pass


## BENCH — the apparatus mid-job. A stand and two clamps hold the column from the
## right, tape collars mark the levels somebody was watching, a rod stands in the
## bottom vessel and a scrawled plate is taped to the front rail.
func _admission_bench(root: Node3D, boxes: Array, whole: AABB) -> void:
	var steel: StandardMaterial3D = _admission_mat(Color(0.60, 0.62, 0.66), 0.35, 0.85)
	var tape: StandardMaterial3D = _admission_mat(Color(0.94, 0.92, 0.84), 0.85, 0.0)
	var ink: StandardMaterial3D = _admission_mat(Color(0.10, 0.10, 0.13), 0.8, 0.0)

	var y0: float = whole.position.y
	var h: float = maxf(whole.size.y, 0.05)
	var sx: float = whole.position.x + whole.size.x * 0.94
	var sz: float = whole.get_center().z
	var rod_r: float = maxf(h * 0.010, 0.003)

	# Stand: a weighted base plate and a full-height rod at the right of the rack.
	_admission_box(root, Vector3(sx - h * 0.03, y0 + h * 0.011, sz),
		Vector3(h * 0.17, h * 0.022, h * 0.13), steel)
	_admission_cyl(root, Vector3(sx, y0 + h * 0.5, sz), rod_r, h * 0.97, steel)

	# Two boss clamps reaching in along -X to grip the vessel column. The reach is read
	# off the vessels themselves, not guessed: the turtle builds some segments off-centre.
	var reach: float = whole.position.x
	for b0 in boxes:
		var eb: AABB = b0
		reach = maxf(reach, eb.end.x)
	reach = minf(reach + h * 0.012, sx - h * 0.03)
	for clamp_i in range(2):
		var cy: float = y0 + h * (0.34 + 0.38 * float(clamp_i))
		_admission_box(root, Vector3(sx, cy, sz), Vector3(rod_r * 4.0, h * 0.045, rod_r * 4.0), steel)
		var arm_len: float = maxf(sx - reach, h * 0.04)
		_admission_cyl_x(root, Vector3(sx - arm_len * 0.5, cy, sz), rod_r * 0.75, arm_len, steel)
		# jaw — two short pads closing on the vessel
		for jaw_i in range(2):
			var jz: float = -1.0 + 2.0 * float(jaw_i)
			_admission_box(root, Vector3(reach, cy, sz + jz * h * 0.045),
				Vector3(h * 0.03, h * 0.020, h * 0.030), steel)

	# Marker tape where somebody drew the level, on the two widest vessels.
	var wide: Array = _admission_widest(boxes, 2)
	for b in wide:
		var vb: AABB = b
		var r: float = _admission_radius(vb)
		_admission_cyl(root, Vector3(vb.get_center().x, vb.position.y + vb.size.y * 0.58, vb.get_center().z),
			r + maxf(r * 0.06, 0.0015), maxf(vb.size.y * 0.035, 0.004), tape)

	# A stirring rod standing in the lowest vessel, leaning out of it.
	var low: AABB = _admission_lowest(boxes)
	var rod: MeshInstance3D = _admission_cyl(root,
		Vector3(low.get_center().x - h * 0.02, low.position.y + h * 0.13, low.get_center().z),
		rod_r * 0.55, h * 0.30, tape)
	rod.rotation_degrees = Vector3(0, 0, 14.0)

	# A scrawled plate taped to the front rail: pale card, two ink lines.
	var cz: float = whole.end.z + h * 0.006
	var cy2: float = y0 + h * 0.50
	var cx: float = whole.position.x + whole.size.x * 0.20
	_admission_box(root, Vector3(cx, cy2, cz), Vector3(h * 0.15, h * 0.10, h * 0.006), tape)
	for i in range(2):
		_admission_box(root, Vector3(cx, cy2 + h * (0.018 - 0.030 * float(i)), cz + h * 0.005),
			Vector3(h * 0.11, h * 0.010, h * 0.003), ink)


## RESIDUE — the glass keeps the record. Crust in every bottom, a tide ring at the
## old fill line, drips down the outside, and an etched band that has gone opaque:
## the transparency fails exactly where the work happened.
func _admission_residue(root: Node3D, boxes: Array) -> void:
	var crust: StandardMaterial3D = _admission_mat(Color(0.22, 0.17, 0.09), 0.97, 0.0)
	var tide: StandardMaterial3D = _admission_mat(Color(0.38, 0.30, 0.16), 0.92, 0.0)
	var frost: StandardMaterial3D = _admission_mat(Color(0.80, 0.82, 0.79), 1.0, 0.0)

	for i in range(boxes.size()):
		var b: AABB = boxes[i]
		var r: float = _admission_radius(b)
		var c: Vector3 = b.get_center()
		var bh: float = maxf(b.size.y, 0.004)

		# Dried crust settled in the bottom.
		_admission_cyl(root, Vector3(c.x, b.position.y + bh * 0.055, c.z),
			r * 0.84, bh * 0.11, crust)

		# The tide line — where the level stood before it evaporated. Staggered per
		# vessel so the rack reads as a history rather than a single event.
		var tide_y: float = b.position.y + bh * (0.40 + 0.11 * float(i % 3))
		_admission_cyl(root, Vector3(c.x, tide_y, c.z), r + maxf(r * 0.05, 0.0012),
			maxf(bh * 0.028, 0.003), tide)

		# The etched band: opaque, matte, and sitting on the widest part of the vessel.
		# This is the value's whole argument — the instrument stops being see-through.
		_admission_cyl(root, Vector3(c.x, c.y, c.z), r + maxf(r * 0.02, 0.0006),
			bh * 0.24, frost)

		# Drips running down the outside from the tide line to the foot.
		var drop: float = tide_y - b.position.y
		for d in range(2):
			var a: float = 0.55 + 1.9 * float(d)
			_admission_box(root, Vector3(c.x + cos(a) * r * 1.02, b.position.y + drop * 0.5,
				c.z + sin(a) * r * 1.02), Vector3(r * 0.16, drop, r * 0.16), tide)


## EXHIBIT — racked as evidence. A seal over every mouth, a numbered tag wired to
## every neck, and a barcoded card on the front rail. The labels become the readable
## part and the contents stop mattering.
func _admission_exhibit(root: Node3D, boxes: Array, whole: AABB) -> void:
	var card: StandardMaterial3D = _admission_mat(Color(0.91, 0.89, 0.81), 0.85, 0.0)
	var ink: StandardMaterial3D = _admission_mat(Color(0.09, 0.09, 0.12), 0.8, 0.0)
	var wire: StandardMaterial3D = _admission_mat(Color(0.58, 0.58, 0.62), 0.4, 0.8)
	var seal: StandardMaterial3D = _admission_mat(Color(0.82, 0.30, 0.14), 0.7, 0.0)

	for i in range(boxes.size()):
		var b: AABB = boxes[i]
		var r: float = _admission_radius(b)
		var c: Vector3 = b.get_center()
		var bh: float = maxf(b.size.y, 0.004)
		var top: float = b.end.y

		# Seal band over the mouth — this vessel is not to be opened.
		_admission_cyl(root, Vector3(c.x, top - bh * 0.03, c.z), r * 0.42 + maxf(r * 0.05, 0.002),
			maxf(bh * 0.05, 0.004), seal)

		# Tag on a wire off the neck, hung on the +X side and facing the room.
		var tw: float = maxf(r * 1.05, bh * 0.24)
		var th: float = tw * 0.62
		var tx: float = c.x + r + tw * 0.62
		var ty: float = top - bh * 0.20
		_admission_cyl_x(root, Vector3((c.x + r * 0.5 + tx) * 0.5, top - bh * 0.06, c.z),
			maxf(r * 0.035, 0.0007), maxf(tx - c.x - r * 0.5, 0.004), wire)
		_admission_box(root, Vector3(tx, ty, c.z), Vector3(tw, th, maxf(r * 0.06, 0.0015)), card)
		for k in range(2):
			_admission_box(root, Vector3(tx, ty + th * (0.22 - 0.42 * float(k)),
				c.z + maxf(r * 0.05, 0.0012)),
				Vector3(tw * 0.66, th * 0.13, maxf(r * 0.03, 0.0008)), ink)

	# The accession card on the front rail, with its barcode.
	var h: float = maxf(whole.size.y, 0.05)
	var cz: float = whole.end.z + h * 0.006
	var cy: float = whole.position.y + h * 0.44
	_admission_box(root, Vector3(whole.get_center().x, cy, cz),
		Vector3(h * 0.30, h * 0.11, h * 0.006), card)
	for k in range(9):
		var bx: float = whole.get_center().x + h * (-0.115 + 0.029 * float(k))
		_admission_box(root, Vector3(bx, cy - h * 0.012, cz + h * 0.005),
			Vector3(h * (0.006 if k % 2 == 0 else 0.012), h * 0.055, h * 0.003), ink)


# ── Admission geometry helpers ──────────────────────────────────────────────────

func _admission_mat(c: Color, rough: float, metal: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	return m


func _admission_box(parent: Node3D, center: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = center
	parent.add_child(mi)
	return mi


func _admission_cyl(parent: Node3D, center: Vector3, radius: float, height: float, mat: Material) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = maxf(radius, 0.0004)
	mesh.bottom_radius = maxf(radius, 0.0004)
	mesh.height = maxf(height, 0.0006)
	mesh.radial_segments = 16
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = center
	parent.add_child(mi)
	return mi


func _admission_cyl_x(parent: Node3D, center: Vector3, radius: float, length: float, mat: Material) -> MeshInstance3D:
	var mi: MeshInstance3D = _admission_cyl(parent, center, radius, length, mat)
	mi.rotation_degrees = Vector3(0, 0, 90)
	return mi


## The radius a collar has to be to WRAP this vessel — the SMALLER horizontal extent,
## not the larger. A flask segment is built with its neck lying along Z, so its box is
## 0.12 x 0.16 and the larger extent describes the neck, not the belly: collars sized
## from it stood off the glass as free-floating discs instead of banding it.
func _admission_radius(b: AABB) -> float:
	return maxf(minf(b.size.x, b.size.z) * 0.5, 0.002)


func _admission_widest(boxes: Array, count: int) -> Array:
	var pool: Array = boxes.duplicate()
	var out: Array = []
	while out.size() < count and not pool.is_empty():
		var best: int = 0
		for i in range(pool.size()):
			var a: AABB = pool[i]
			var b: AABB = pool[best]
			if _admission_radius(a) > _admission_radius(b):
				best = i
		out.append(pool[best])
		pool.remove_at(best)
	return out


func _admission_lowest(boxes: Array) -> AABB:
	var best: AABB = boxes[0]
	for b in boxes:
		var vb: AABB = b
		if vb.position.y < best.position.y:
			best = vb
	return best


## One AABB per placed vessel/segment, in this node's own space. Works for both the
## vessels-array configs and the turtle-path ones — both fill _segments_root.
func _admission_vessel_boxes() -> Array:
	var boxes: Array = []
	if _segments_root == null:
		return boxes
	for child in _segments_root.get_children():
		if child is Node3D:
			var b: AABB = _admission_subtree_box(child as Node3D)
			if b.size.length() > 0.0008:
				boxes.append(b)
	return boxes


func _admission_subtree_box(from_node: Node3D) -> AABB:
	var acc := AABB()
	var have: bool = false
	var stack: Array = [from_node]
	while not stack.is_empty():
		var cur = stack.pop_back()
		if cur is MeshInstance3D:
			var mi := cur as MeshInstance3D
			if mi.mesh != null:
				var wb: AABB = _admission_local_xform(mi) * mi.mesh.get_aabb()
				acc = wb if not have else acc.merge(wb)
				have = true
		for ch in cur.get_children():
			stack.append(ch)
	return acc if have else AABB()


## Transform of a descendant relative to THIS node, walked by hand so it is valid
## during _ready() regardless of where the rack sits in the world.
func _admission_local_xform(n: Node3D) -> Transform3D:
	var t := Transform3D.IDENTITY
	var cur: Node = n
	while cur != null and cur != self:
		if cur is Node3D:
			t = (cur as Node3D).transform * t
		cur = cur.get_parent()
	return t
