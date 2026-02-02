# samplevialrack.gd
# Sample vial rack demonstrating phase relationships
# Each vial pulses with phase offset - wave propagation visualization
extends Node3D

class_name LabSampleVialRack

@export_group("Wave Settings")
@export var wave_frequency: float = 0.5  # Hz
@export var phase_mode: int = 0  # 0=linear, 1=radial, 2=random
@export var glow_min: float = 0.2
@export var glow_max: float = 2.0

@export_group("Samples")
@export var num_vials: int = 6
@export var sample_colors: Array[Color] = [
	Color(0.0, 1.0, 1.0),   # Cyan
	Color(1.0, 1.0, 0.0),   # Yellow
	Color(1.0, 0.0, 1.0),   # Magenta
	Color(0.0, 1.0, 0.5),   # Mint
	Color(1.0, 0.3, 0.0),   # Orange
	Color(0.5, 0.0, 1.0),   # Purple
]

## Internal
var time: float = 0.0
var vial_meshes: Array[MeshInstance3D] = []
var liquid_meshes: Array[MeshInstance3D] = []
var phase_offsets: Array[float] = []
var rack_label: MeshInstance3D

func _ready() -> void:
	_calculate_phases()
	_build_rack()

func _process(delta: float) -> void:
	time += delta
	
	# Update each vial's glow based on sine wave with phase offset
	for i in range(liquid_meshes.size()):
		var liquid = liquid_meshes[i]
		if liquid and liquid.material_override:
			var phase = phase_offsets[i] if i < phase_offsets.size() else 0.0
			var wave = sin(time * wave_frequency * TAU + phase)
			var normalized = (wave + 1.0) / 2.0  # 0 to 1
			var glow = lerp(glow_min, glow_max, normalized)
			liquid.material_override.emission_energy_multiplier = glow
			
			# Subtle scale pulse
			var scale_factor = 0.9 + 0.2 * normalized
			liquid.scale.y = scale_factor

func _calculate_phases() -> void:
	phase_offsets.clear()
	
	match phase_mode:
		0:  # Linear - wave travels left to right
			for i in range(num_vials):
				phase_offsets.append(float(i) * TAU / float(num_vials))
		1:  # Radial - wave expands from center
			var center = float(num_vials - 1) / 2.0
			for i in range(num_vials):
				var dist = abs(float(i) - center)
				phase_offsets.append(dist * PI / center if center > 0 else 0.0)
		2:  # Random phases
			for i in range(num_vials):
				phase_offsets.append(randf() * TAU)

func _build_rack() -> void:
	for child in get_children():
		child.queue_free()
	vial_meshes.clear()
	liquid_meshes.clear()
	
	# Rack base
	var base = MeshInstance3D.new()
	base.name = "RackBase"
	var base_mesh = BoxMesh.new()
	var rack_width = 0.02 + num_vials * 0.022
	base_mesh.size = Vector3(rack_width, 0.015, 0.05)
	base.mesh = base_mesh
	base.position = Vector3(0, 0.0075, 0)
	var base_mat = StandardMaterial3D.new()
	base_mat.albedo_color = Color(0.7, 0.75, 0.8)
	base_mat.metallic = 0.4
	base_mat.roughness = 0.5
	base.material_override = base_mat
	add_child(base)
	
	# Top holder bar
	var holder = MeshInstance3D.new()
	holder.name = "Holder"
	var holder_mesh = BoxMesh.new()
	holder_mesh.size = Vector3(rack_width, 0.008, 0.03)
	holder.mesh = holder_mesh
	holder.position = Vector3(0, 0.045, 0)
	holder.material_override = base_mat
	add_child(holder)
	
	# Support posts
	for x_mult in [-1, 1]:
		var post = MeshInstance3D.new()
		var post_mesh = BoxMesh.new()
		post_mesh.size = Vector3(0.006, 0.04, 0.006)
		post.mesh = post_mesh
		post.position = Vector3(x_mult * (rack_width / 2.0 - 0.005), 0.03, 0.015)
		post.material_override = base_mat
		add_child(post)
	
	# Create vials
	var spacing = 0.022
	var start_x = -spacing * (num_vials - 1) / 2.0
	
	for i in range(num_vials):
		var vial_x = start_x + i * spacing
		var color = sample_colors[i % sample_colors.size()]
		_create_vial(Vector3(vial_x, 0.015, 0), i, color)
	
	# Label
	rack_label = MeshInstance3D.new()
	rack_label.name = "Label"
	var label_mesh = BoxMesh.new()
	label_mesh.size = Vector3(rack_width * 0.8, 0.008, 0.002)
	rack_label.mesh = label_mesh
	rack_label.position = Vector3(0, 0.005, 0.026)
	var label_mat = StandardMaterial3D.new()
	label_mat.albedo_color = Color(0.1, 0.4, 0.8)
	label_mat.emission_enabled = true
	label_mat.emission = Color(0.1, 0.3, 0.6)
	label_mat.emission_energy_multiplier = 0.5
	rack_label.material_override = label_mat
	add_child(rack_label)

func _create_vial(pos: Vector3, index: int, color: Color) -> void:
	# Glass vial
	var vial = MeshInstance3D.new()
	vial.name = "Vial_%d" % index
	var vial_mesh = CylinderMesh.new()
	vial_mesh.top_radius = 0.007
	vial_mesh.bottom_radius = 0.007
	vial_mesh.height = 0.055
	vial_mesh.radial_segments = 12
	vial.mesh = vial_mesh
	vial.position = pos + Vector3(0, 0.0275, 0)
	var vial_mat = StandardMaterial3D.new()
	vial_mat.albedo_color = Color(0.9, 0.95, 1.0, 0.3)
	vial_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	vial_mat.roughness = 0.0
	vial_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	vial.material_override = vial_mat
	add_child(vial)
	vial_meshes.append(vial)
	
	# Rubber stopper
	var stopper = MeshInstance3D.new()
	var stopper_mesh = CylinderMesh.new()
	stopper_mesh.top_radius = 0.008
	stopper_mesh.bottom_radius = 0.007
	stopper_mesh.height = 0.008
	stopper.mesh = stopper_mesh
	stopper.position = pos + Vector3(0, 0.059, 0)
	var stopper_mat = StandardMaterial3D.new()
	stopper_mat.albedo_color = Color(0.3, 0.1, 0.1)
	stopper_mat.roughness = 0.9
	stopper.material_override = stopper_mat
	add_child(stopper)
	
	# Liquid sample
	var liquid = MeshInstance3D.new()
	liquid.name = "Liquid_%d" % index
	var liquid_mesh = CylinderMesh.new()
	liquid_mesh.top_radius = 0.005
	liquid_mesh.bottom_radius = 0.005
	var fill_height = 0.02 + randf() * 0.02  # Random fill level
	liquid_mesh.height = fill_height
	liquid.mesh = liquid_mesh
	liquid.position = pos + Vector3(0, 0.005 + fill_height / 2.0, 0)
	var liquid_mat = StandardMaterial3D.new()
	liquid_mat.albedo_color = Color(color.r, color.g, color.b, 0.8)
	liquid_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	liquid_mat.emission_enabled = true
	liquid_mat.emission = color
	liquid_mat.emission_energy_multiplier = glow_min
	liquid.material_override = liquid_mat
	add_child(liquid)
	liquid_meshes.append(liquid)

## Public API
func set_wave_frequency(freq: float) -> void:
	wave_frequency = freq

func set_phase_mode(mode: int) -> void:
	phase_mode = mode
	_calculate_phases()

func trigger_wave_pulse() -> void:
	# Reset time to create a clean wave from the start
	time = 0.0

func get_phase_at_vial(index: int) -> float:
	if index >= 0 and index < phase_offsets.size():
		return phase_offsets[index]
	return 0.0
