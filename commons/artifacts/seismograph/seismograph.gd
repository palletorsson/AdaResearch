# seismograph.gd
# Drum-type chart recorder / seismograph
# Classic scientific instrument with rotating drum and pen arm
# Inspired by Half-Life 2 lab equipment aesthetic
extends Node3D

class_name Seismograph
## Simulates a drum-type seismograph that records waveform traces.
## A rotating drum with paper scrolls past a pen arm that draws a
## sine-based signal with configurable noise and random spike events.
## Key parameters: trace_frequency controls wave speed, noise_intensity
## adds randomness, trace_amplitude sets pen displacement range.

const CORNER_RADIUS := 0.015
const CORNER_SEGMENTS := 12
const DRUM_SEGMENTS := 32
const DRUM_PAPER_SEGMENTS := 64
const CAP_OVERHANG := 0.008
const CAP_HEIGHT := 0.012
const CAP_OFFSET := 0.006
const PAPER_SKIN_OFFSET := 0.002
const GRILLE_COUNT := 8
const GRILLE_HEIGHT := 0.006
const GRILLE_SPACING := 0.012
const GRILLE_DEPTH := 0.002
const PEN_TIP_SEGMENTS := 8
const SPIKE_CHANCE := 0.02
const TRACE_UPDATE_INTERVAL := 3
const TIME_WRAP := 1000.0

var SliderScene = preload("res://commons/interactables/slider_horizontal.tscn")

## Width of the instrument base in meters
@export_group("Dimensions")
@export_range(0.2, 1.5, 0.05) var base_width: float = 0.6
## Depth of the instrument base in meters
@export_range(0.1, 1.0, 0.05) var base_depth: float = 0.4
## Height of the instrument base in meters
@export_range(0.05, 0.5, 0.01) var base_height: float = 0.18
## Radius of the rotating drum cylinder
@export_range(0.03, 0.3, 0.01) var drum_radius: float = 0.12
## Width (axial length) of the rotating drum
@export_range(0.05, 0.4, 0.01) var drum_width: float = 0.18

@export_group("Colors")
## Main housing color
@export var base_color: Color = Color(0.76, 0.71, 0.63)
## Top instrument panel color
@export var top_panel_color: Color = Color(0.15, 0.15, 0.17)
## Rotating drum color
@export var drum_color: Color = Color(0.25, 0.12, 0.12)
## Paper color for drum wrap and feed strip
@export var paper_color: Color = Color(0.95, 0.93, 0.88)
## Background grid overlay color
@export var grid_color: Color = Color(0.6, 0.8, 0.7, 0.5)
## Pen trace line color
@export var trace_color: Color = Color(0.1, 0.5, 0.4)

@export_group("Animation")
## Drum rotations per second
@export_range(0.01, 2.0, 0.01) var drum_rotation_speed: float = 0.1
## Sine wave frequency of the seismic trace
@export_range(0.1, 20.0, 0.1) var trace_frequency: float = 3.0
## Maximum displacement of the trace pen
@export_range(0.001, 0.1, 0.001) var trace_amplitude: float = 0.02
## Amount of random noise added to the trace signal
@export_range(0.0, 2.0, 0.05) var noise_intensity: float = 0.5
## Whether the drum and trace animate automatically
@export var auto_animate: bool = true

## Internal state
var _time: float = 0.0
var _drum_node: Node3D
var _pen_arm_node: Node3D
var _trace_mesh_instance: MeshInstance3D
var _trace_data: Array[float] = []
var _trace_resolution: int = 200
var _st: SurfaceTool
var _paper_mat: StandardMaterial3D
var _noise_slider: Node3D
var _freq_slider: Node3D

func _ready() -> void:
	_st = SurfaceTool.new()
	_paper_mat = StandardMaterial3D.new()
	_paper_mat.albedo_color = paper_color
	_paper_mat.roughness = 0.95
	_paper_mat.metallic = 0.0
	_build_seismograph()
	_setup_controls()

func _process(delta: float) -> void:
	if not auto_animate:
		return

	_time = wrapf(_time + delta, 0.0, TIME_WRAP)

	# Rotate drum
	if _drum_node:
		_drum_node.rotate_z(-drum_rotation_speed * delta * TAU)

	# Animate pen arm slightly
	if _pen_arm_node:
		var pen_offset = _get_current_trace_value() * 0.5
		_pen_arm_node.position.y = 0.02 + pen_offset * 0.1

	# Update trace periodically
	if Engine.get_frames_drawn() % TRACE_UPDATE_INTERVAL == 0:
		_update_trace()

## Builds all visual components of the seismograph instrument.
func _build_seismograph() -> void:
	for child in get_children():
		child.queue_free()

	_create_base()
	_create_top_panel()
	_create_drum()
	_create_paper_feed()
	_create_pen_assembly()
	_create_ventilation_grilles()
	_init_trace()

## Creates the main rectangular housing.
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

	_add_corner_trim(instance)

## Adds decorative corner cylinders using MultiMesh.
func _add_corner_trim(parent: Node3D) -> void:
	var corners = [
		Vector3(-base_width / 2 + CORNER_RADIUS, 0, -base_depth / 2 + CORNER_RADIUS),
		Vector3(base_width / 2 - CORNER_RADIUS, 0, -base_depth / 2 + CORNER_RADIUS),
		Vector3(-base_width / 2 + CORNER_RADIUS, 0, base_depth / 2 - CORNER_RADIUS),
		Vector3(base_width / 2 - CORNER_RADIUS, 0, base_depth / 2 - CORNER_RADIUS),
	]

	var cyl_mesh := CylinderMesh.new()
	cyl_mesh.top_radius = CORNER_RADIUS
	cyl_mesh.bottom_radius = CORNER_RADIUS
	cyl_mesh.height = base_height
	cyl_mesh.radial_segments = CORNER_SEGMENTS

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = cyl_mesh
	mm.instance_count = corners.size()

	for i in corners.size():
		var xf := Transform3D()
		xf.origin = corners[i]
		mm.set_instance_transform(i, xf)

	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm

	var mat := StandardMaterial3D.new()
	mat.albedo_color = base_color.darkened(0.05)
	mat.roughness = 0.7
	mmi.material_override = mat

	parent.add_child(mmi)

## Creates the dark instrument panel on top of the base.
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

## Creates the rotating drum assembly with end caps.
func _create_drum() -> void:
	_drum_node = Node3D.new()
	_drum_node.name = "DrumAssembly"
	_drum_node.position = Vector3(base_width * 0.2, base_height + drum_radius + 0.02, -base_depth * 0.1)
	add_child(_drum_node)

	var drum_mesh = CylinderMesh.new()
	drum_mesh.top_radius = drum_radius
	drum_mesh.bottom_radius = drum_radius
	drum_mesh.height = drum_width
	drum_mesh.radial_segments = DRUM_SEGMENTS

	var drum_mat = StandardMaterial3D.new()
	drum_mat.albedo_color = drum_color
	drum_mat.roughness = 0.3
	drum_mat.metallic = 0.4

	var drum_instance = MeshInstance3D.new()
	drum_instance.name = "Drum"
	drum_instance.mesh = drum_mesh
	drum_instance.material_override = drum_mat
	drum_instance.rotation.x = PI / 2
	_drum_node.add_child(drum_instance)

	# Drum end caps (shared mesh and material)
	var cap_mesh = CylinderMesh.new()
	cap_mesh.top_radius = drum_radius + CAP_OVERHANG
	cap_mesh.bottom_radius = drum_radius + CAP_OVERHANG
	cap_mesh.height = CAP_HEIGHT
	cap_mesh.radial_segments = DRUM_SEGMENTS

	var cap_mat = StandardMaterial3D.new()
	cap_mat.albedo_color = top_panel_color
	cap_mat.roughness = 0.4
	cap_mat.metallic = 0.6

	for z_offset in [-drum_width / 2 - CAP_OFFSET, drum_width / 2 + CAP_OFFSET]:
		var cap = MeshInstance3D.new()
		cap.mesh = cap_mesh
		cap.material_override = cap_mat
		cap.rotation.x = PI / 2
		cap.position.z = z_offset
		_drum_node.add_child(cap)

	_create_drum_paper()

## Wraps paper texture around the drum surface.
func _create_drum_paper() -> void:
	var paper_mesh = CylinderMesh.new()
	paper_mesh.top_radius = drum_radius + PAPER_SKIN_OFFSET
	paper_mesh.bottom_radius = drum_radius + PAPER_SKIN_OFFSET
	paper_mesh.height = drum_width - 0.01
	paper_mesh.radial_segments = DRUM_PAPER_SEGMENTS

	var paper_instance = MeshInstance3D.new()
	paper_instance.name = "DrumPaper"
	paper_instance.mesh = paper_mesh
	paper_instance.material_override = _paper_mat
	paper_instance.rotation.x = PI / 2
	_drum_node.add_child(paper_instance)

## Creates the flat paper strip extending from the drum.
func _create_paper_feed() -> void:
	var paper_length = base_width * 0.4
	var paper_mesh = BoxMesh.new()
	paper_mesh.size = Vector3(paper_length, 0.002, drum_width - 0.02)

	var paper_instance = MeshInstance3D.new()
	paper_instance.name = "PaperFeed"
	paper_instance.mesh = paper_mesh
	paper_instance.material_override = _paper_mat
	paper_instance.position = Vector3(
		-base_width * 0.15,
		base_height + drum_radius * 2 + 0.025,
		-base_depth * 0.1
	)
	add_child(paper_instance)

	_create_trace_on_paper(paper_instance)

## Adds the trace line mesh on top of the paper feed.
func _create_trace_on_paper(paper_parent: Node3D) -> void:
	_trace_mesh_instance = MeshInstance3D.new()
	_trace_mesh_instance.name = "TraceLine"
	_trace_mesh_instance.position = Vector3(0, 0.002, 0)
	paper_parent.add_child(_trace_mesh_instance)

	var mat = StandardMaterial3D.new()
	mat.albedo_color = trace_color
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.emission_enabled = true
	mat.emission = trace_color
	mat.emission_energy_multiplier = 0.5
	_trace_mesh_instance.material_override = mat

## Initializes the trace data array with zeros.
func _init_trace() -> void:
	_trace_data.clear()
	_trace_data.resize(_trace_resolution)
	for i in _trace_resolution:
		_trace_data[i] = 0.0
	_update_trace_mesh()

## Computes the current trace value from sine wave, noise, and random spikes.
func _get_current_trace_value() -> float:
	var base_wave = sin(_time * trace_frequency * TAU)
	var noise = (randf() - 0.5) * noise_intensity
	var spike = 0.0
	if randf() < SPIKE_CHANCE:
		spike = (randf() - 0.5) * 2.0
	return (base_wave + noise + spike) * trace_amplitude

## Shifts trace data left and appends a new sample.
func _update_trace() -> void:
	for i in range(_trace_resolution - 1):
		_trace_data[i] = _trace_data[i + 1]
	_trace_data[_trace_resolution - 1] = _get_current_trace_value()

	_update_trace_mesh()

## Rebuilds the trace line mesh from current data using cached SurfaceTool.
func _update_trace_mesh() -> void:
	if not _trace_mesh_instance:
		return

	_st.clear()
	_st.begin(Mesh.PRIMITIVE_LINE_STRIP)

	var paper_length = base_width * 0.4
	var step = paper_length / float(_trace_resolution - 1)

	for i in range(_trace_resolution):
		var x = -paper_length / 2 + i * step
		var z = _trace_data[i]
		_st.add_vertex(Vector3(x, 0, z))

	_trace_mesh_instance.mesh = _st.commit()

## Builds the pen arm assembly with housing, arm, and tip.
func _create_pen_assembly() -> void:
	_pen_arm_node = Node3D.new()
	_pen_arm_node.name = "PenAssembly"
	_pen_arm_node.position = Vector3(
		-base_width * 0.05,
		base_height + drum_radius * 2 + 0.04,
		-base_depth * 0.1
	)
	add_child(_pen_arm_node)

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
	_pen_arm_node.add_child(housing)

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
	_pen_arm_node.add_child(arm)

	var tip_mesh = CylinderMesh.new()
	tip_mesh.top_radius = 0.002
	tip_mesh.bottom_radius = 0.004
	tip_mesh.height = 0.015
	tip_mesh.radial_segments = PEN_TIP_SEGMENTS

	var tip_mat = StandardMaterial3D.new()
	tip_mat.albedo_color = trace_color.darkened(0.3)
	tip_mat.roughness = 0.3
	tip_mat.metallic = 0.5

	var tip = MeshInstance3D.new()
	tip.name = "PenTip"
	tip.mesh = tip_mesh
	tip.material_override = tip_mat
	tip.position = Vector3(-0.03, -0.008, 0)
	_pen_arm_node.add_child(tip)

## Creates ventilation grille slats on the front face using MultiMesh.
func _create_ventilation_grilles() -> void:
	var grille_width = base_width * 0.6
	var start_y = base_height * 0.2

	var grille_mesh := BoxMesh.new()
	grille_mesh.size = Vector3(grille_width, GRILLE_HEIGHT, GRILLE_DEPTH)

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = grille_mesh
	mm.instance_count = GRILLE_COUNT

	for i in GRILLE_COUNT:
		var xf := Transform3D()
		xf.origin = Vector3(0, start_y + i * GRILLE_SPACING, base_depth / 2 + 0.001)
		mm.set_instance_transform(i, xf)

	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm

	var mat := StandardMaterial3D.new()
	mat.albedo_color = base_color.darkened(0.3)
	mat.roughness = 0.7
	mmi.material_override = mat

	add_child(mmi)

## Sets up VR interaction sliders for noise and frequency control.
func _setup_controls() -> void:
	_noise_slider = SliderScene.instantiate()
	_noise_slider.position = Vector3(-base_width * 0.3, base_height + 0.02, base_depth / 2 + 0.08)
	_noise_slider.set_param_name("Noise")
	_noise_slider.set_normalized_value(noise_intensity / 2.0)
	_noise_slider.slider_moved.connect(_on_noise_changed)
	add_child(_noise_slider)

	_freq_slider = SliderScene.instantiate()
	_freq_slider.position = Vector3(base_width * 0.3, base_height + 0.02, base_depth / 2 + 0.08)
	_freq_slider.set_param_name("Frequency")
	_freq_slider.set_normalized_value(trace_frequency / 20.0)
	_freq_slider.slider_moved.connect(_on_freq_changed)
	add_child(_freq_slider)

func _on_noise_changed() -> void:
	noise_intensity = _noise_slider.get_normalized_value() * 2.0

func _on_freq_changed() -> void:
	trace_frequency = _freq_slider.get_normalized_value() * 20.0

## Public API

## Sets trace amplitude from an external source (0.0 - 1.0).
func set_trace_intensity(value: float) -> void:
	trace_amplitude = value * 0.05

## Triggers a seismic spike of the given intensity.
func add_seismic_event(intensity: float = 1.0) -> void:
	for i in range(mini(20, _trace_resolution)):
		var idx = _trace_resolution - 1 - i
		if idx >= 0:
			_trace_data[idx] += intensity * trace_amplitude * 3.0 * (1.0 - i / 20.0)

func apply_grid_config(config_data: Dictionary) -> void:
	pass
