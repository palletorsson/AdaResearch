# seismograph.gd
# Drum-type chart recorder / seismograph
# Classic scientific instrument with rotating drum and pen arm
# Inspired by Half-Life 2 lab equipment aesthetic
extends Node3D

class_name Seismograph

## Dimensions (in meters, scaled to fit ~0.6m wide)
@export_group("Dimensions")
@export var base_width: float = 0.6
@export var base_depth: float = 0.4
@export var base_height: float = 0.18
@export var drum_radius: float = 0.12
@export var drum_width: float = 0.18

@export_group("Colors")
@export var base_color: Color = Color(0.76, 0.71, 0.63)  # Beige
@export var top_panel_color: Color = Color(0.15, 0.15, 0.17)  # Dark grey
@export var drum_color: Color = Color(0.25, 0.12, 0.12)  # Dark burgundy/brown
@export var paper_color: Color = Color(0.95, 0.93, 0.88)  # Off-white
@export var grid_color: Color = Color(0.6, 0.8, 0.7, 0.5)  # Light green
@export var trace_color: Color = Color(0.1, 0.5, 0.4)  # Teal/dark green

@export_group("Animation")
@export var drum_rotation_speed: float = 0.1  # Rotations per second
@export var trace_frequency: float = 3.0  # Wave frequency
@export var trace_amplitude: float = 0.02  # Wave amplitude
@export var noise_intensity: float = 0.5  # Random noise in trace
@export var auto_animate: bool = true

## Internal state
var time: float = 0.0
var drum_node: Node3D
var pen_arm_node: Node3D
var trace_mesh_instance: MeshInstance3D
var trace_data: Array[float] = []
var trace_resolution: int = 200

func _ready() -> void:
	_build_seismograph()

func _process(delta: float) -> void:
	if not auto_animate:
		return
	
	time += delta
	
	# Rotate drum
	if drum_node:
		drum_node.rotate_z(-drum_rotation_speed * delta * TAU)
	
	# Animate pen arm slightly
	if pen_arm_node:
		var pen_offset = _get_current_trace_value() * 0.5
		pen_arm_node.position.y = 0.02 + pen_offset * 0.1
	
	# Update trace periodically
	if Engine.get_frames_drawn() % 3 == 0:
		_update_trace()

func _build_seismograph() -> void:
	# Clear existing children
	for child in get_children():
		child.queue_free()
	
	_create_base()
	_create_top_panel()
	_create_drum()
	_create_paper_feed()
	_create_pen_assembly()
	_create_ventilation_grilles()
	_init_trace()

func _create_base() -> void:
	var mesh = BoxMesh.new()
	mesh.size = Vector3(base_width, base_height, base_depth)
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = base_color
	mat.roughness = 0.8
	mat.metallic = 0.0
	
	var instance = MeshInstance3D.new()
	instance.name = "Base"
	instance.mesh = mesh
	instance.material_override = mat
	instance.position = Vector3(0, base_height / 2, 0)
	add_child(instance)
	
	# Rounded corners effect - add small cylinders at edges
	_add_corner_trim(instance)

func _add_corner_trim(parent: Node3D) -> void:
	var corner_radius = 0.015
	var corners = [
		Vector3(-base_width/2 + corner_radius, 0, -base_depth/2 + corner_radius),
		Vector3(base_width/2 - corner_radius, 0, -base_depth/2 + corner_radius),
		Vector3(-base_width/2 + corner_radius, 0, base_depth/2 - corner_radius),
		Vector3(base_width/2 - corner_radius, 0, base_depth/2 - corner_radius),
	]
	
	var cyl_mesh = CylinderMesh.new()
	cyl_mesh.top_radius = corner_radius
	cyl_mesh.bottom_radius = corner_radius
	cyl_mesh.height = base_height
	cyl_mesh.radial_segments = 12
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = base_color.darkened(0.05)
	mat.roughness = 0.7
	
	for i in range(corners.size()):
		var corner = MeshInstance3D.new()
		corner.mesh = cyl_mesh
		corner.material_override = mat
		corner.position = corners[i]
		parent.add_child(corner)

func _create_top_panel() -> void:
	var panel_height = 0.04
	var mesh = BoxMesh.new()
	mesh.size = Vector3(base_width * 0.95, panel_height, base_depth * 0.7)
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = top_panel_color
	mat.roughness = 0.6
	mat.metallic = 0.1
	
	var instance = MeshInstance3D.new()
	instance.name = "TopPanel"
	instance.mesh = mesh
	instance.material_override = mat
	instance.position = Vector3(0, base_height + panel_height / 2, -base_depth * 0.1)
	add_child(instance)

func _create_drum() -> void:
	drum_node = Node3D.new()
	drum_node.name = "DrumAssembly"
	drum_node.position = Vector3(base_width * 0.2, base_height + drum_radius + 0.02, -base_depth * 0.1)
	add_child(drum_node)
	
	# Main drum cylinder
	var drum_mesh = CylinderMesh.new()
	drum_mesh.top_radius = drum_radius
	drum_mesh.bottom_radius = drum_radius
	drum_mesh.height = drum_width
	drum_mesh.radial_segments = 32
	
	var drum_mat = StandardMaterial3D.new()
	drum_mat.albedo_color = drum_color
	drum_mat.roughness = 0.3
	drum_mat.metallic = 0.4
	
	var drum_instance = MeshInstance3D.new()
	drum_instance.name = "Drum"
	drum_instance.mesh = drum_mesh
	drum_instance.material_override = drum_mat
	drum_instance.rotation.x = PI / 2  # Rotate so it spins on Z axis
	drum_node.add_child(drum_instance)
	
	# Drum end caps (slightly larger)
	var cap_mesh = CylinderMesh.new()
	cap_mesh.top_radius = drum_radius + 0.008
	cap_mesh.bottom_radius = drum_radius + 0.008
	cap_mesh.height = 0.012
	cap_mesh.radial_segments = 32
	
	var cap_mat = StandardMaterial3D.new()
	cap_mat.albedo_color = top_panel_color
	cap_mat.roughness = 0.4
	cap_mat.metallic = 0.6
	
	for z_offset in [-drum_width/2 - 0.006, drum_width/2 + 0.006]:
		var cap = MeshInstance3D.new()
		cap.mesh = cap_mesh
		cap.material_override = cap_mat
		cap.rotation.x = PI / 2
		cap.position.z = z_offset
		drum_node.add_child(cap)
	
	# Paper wrapped around drum
	_create_drum_paper()

func _create_drum_paper() -> void:
	var paper_mesh = CylinderMesh.new()
	paper_mesh.top_radius = drum_radius + 0.002
	paper_mesh.bottom_radius = drum_radius + 0.002
	paper_mesh.height = drum_width - 0.01
	paper_mesh.radial_segments = 64
	
	var paper_mat = StandardMaterial3D.new()
	paper_mat.albedo_color = paper_color
	paper_mat.roughness = 0.95
	paper_mat.metallic = 0.0
	
	var paper_instance = MeshInstance3D.new()
	paper_instance.name = "DrumPaper"
	paper_instance.mesh = paper_mesh
	paper_instance.material_override = paper_mat
	paper_instance.rotation.x = PI / 2
	drum_node.add_child(paper_instance)

func _create_paper_feed() -> void:
	# Flat paper extending from drum across the top
	var paper_length = base_width * 0.4
	var paper_mesh = BoxMesh.new()
	paper_mesh.size = Vector3(paper_length, 0.002, drum_width - 0.02)
	
	var paper_mat = StandardMaterial3D.new()
	paper_mat.albedo_color = paper_color
	paper_mat.roughness = 0.95
	
	var paper_instance = MeshInstance3D.new()
	paper_instance.name = "PaperFeed"
	paper_instance.mesh = paper_mesh
	paper_instance.material_override = paper_mat
	paper_instance.position = Vector3(
		-base_width * 0.15,
		base_height + drum_radius * 2 + 0.025,
		-base_depth * 0.1
	)
	add_child(paper_instance)
	
	# Create trace line on paper
	_create_trace_on_paper(paper_instance)

func _create_trace_on_paper(paper_parent: Node3D) -> void:
	trace_mesh_instance = MeshInstance3D.new()
	trace_mesh_instance.name = "TraceLine"
	trace_mesh_instance.position = Vector3(0, 0.002, 0)
	paper_parent.add_child(trace_mesh_instance)
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = trace_color
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.emission_enabled = true
	mat.emission = trace_color
	mat.emission_energy_multiplier = 0.5
	trace_mesh_instance.material_override = mat

func _init_trace() -> void:
	trace_data.clear()
	for i in range(trace_resolution):
		trace_data.append(0.0)
	_update_trace_mesh()

func _get_current_trace_value() -> float:
	var base_wave = sin(time * trace_frequency * TAU)
	var noise = (randf() - 0.5) * noise_intensity
	var spike = 0.0
	if randf() < 0.02:  # Occasional spike
		spike = (randf() - 0.5) * 2.0
	return (base_wave + noise + spike) * trace_amplitude

func _update_trace() -> void:
	# Shift trace data left and add new value
	for i in range(trace_resolution - 1):
		trace_data[i] = trace_data[i + 1]
	trace_data[trace_resolution - 1] = _get_current_trace_value()
	
	_update_trace_mesh()

func _update_trace_mesh() -> void:
	if not trace_mesh_instance:
		return
	
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_LINE_STRIP)
	
	var paper_length = base_width * 0.4
	var step = paper_length / float(trace_resolution - 1)
	
	for i in range(trace_resolution):
		var x = -paper_length / 2 + i * step
		var z = trace_data[i]
		st.add_vertex(Vector3(x, 0, z))
	
	trace_mesh_instance.mesh = st.commit()

func _create_pen_assembly() -> void:
	pen_arm_node = Node3D.new()
	pen_arm_node.name = "PenAssembly"
	pen_arm_node.position = Vector3(
		-base_width * 0.05,
		base_height + drum_radius * 2 + 0.04,
		-base_depth * 0.1
	)
	add_child(pen_arm_node)
	
	# Pen housing block
	var housing_mesh = BoxMesh.new()
	housing_mesh.size = Vector3(0.06, 0.03, 0.05)
	
	var housing_mat = StandardMaterial3D.new()
	housing_mat.albedo_color = top_panel_color
	housing_mat.roughness = 0.5
	housing_mat.metallic = 0.3
	
	var housing = MeshInstance3D.new()
	housing.name = "PenHousing"
	housing.mesh = housing_mesh
	housing.material_override = housing_mat
	housing.position = Vector3(0.08, 0.02, 0)
	pen_arm_node.add_child(housing)
	
	# Pen arm
	var arm_mesh = BoxMesh.new()
	arm_mesh.size = Vector3(0.1, 0.004, 0.006)
	
	var arm_mat = StandardMaterial3D.new()
	arm_mat.albedo_color = Color(0.2, 0.2, 0.22)
	arm_mat.roughness = 0.4
	arm_mat.metallic = 0.7
	
	var arm = MeshInstance3D.new()
	arm.name = "PenArm"
	arm.mesh = arm_mesh
	arm.material_override = arm_mat
	arm.position = Vector3(0.02, 0, 0)
	pen_arm_node.add_child(arm)
	
	# Pen tip
	var tip_mesh = CylinderMesh.new()
	tip_mesh.top_radius = 0.002
	tip_mesh.bottom_radius = 0.004
	tip_mesh.height = 0.015
	tip_mesh.radial_segments = 8
	
	var tip_mat = StandardMaterial3D.new()
	tip_mat.albedo_color = trace_color.darkened(0.3)
	tip_mat.roughness = 0.3
	tip_mat.metallic = 0.5
	
	var tip = MeshInstance3D.new()
	tip.name = "PenTip"
	tip.mesh = tip_mesh
	tip.material_override = tip_mat
	tip.position = Vector3(-0.03, -0.008, 0)
	pen_arm_node.add_child(tip)

func _create_ventilation_grilles() -> void:
	var grille_count = 8
	var grille_width = base_width * 0.6
	var grille_height = 0.006
	var grille_spacing = 0.012
	var start_y = base_height * 0.2
	
	var grille_mesh = BoxMesh.new()
	grille_mesh.size = Vector3(grille_width, grille_height, 0.002)
	
	var grille_mat = StandardMaterial3D.new()
	grille_mat.albedo_color = base_color.darkened(0.3)
	grille_mat.roughness = 0.7
	
	for i in range(grille_count):
		var grille = MeshInstance3D.new()
		grille.mesh = grille_mesh
		grille.material_override = grille_mat
		grille.position = Vector3(
			0,
			start_y + i * grille_spacing,
			base_depth / 2 + 0.001
		)
		add_child(grille)

## Public API

func set_trace_intensity(value: float) -> void:
	"""Set trace amplitude from external source (0.0 - 1.0)"""
	trace_amplitude = value * 0.05

func add_seismic_event(intensity: float = 1.0) -> void:
	"""Trigger a seismic spike"""
	for i in range(min(20, trace_resolution)):
		var idx = trace_resolution - 1 - i
		if idx >= 0:
			trace_data[idx] += intensity * trace_amplitude * 3.0 * (1.0 - i / 20.0)
