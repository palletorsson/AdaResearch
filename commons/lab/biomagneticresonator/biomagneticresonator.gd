# biomagneticresonator.gd
# Biomagnetic resonator with pulsing field visualization
# Demonstrates standing waves and resonance phenomena
extends Node3D

class_name LabBiomagneticResonator

@export_group("Resonance")
@export var resonance_frequency: float = 1.0  # Hz
@export var field_strength: float = 1.0
@export var harmonic_count: int = 3  # Number of harmonic overtones

@export_group("Visuals")
@export var core_color: Color = Color(0.8, 0.2, 1.0)
@export var field_color: Color = Color(0.4, 0.8, 1.0)
@export var ring_count: int = 5

## Internal
var time: float = 0.0
var core_sphere: MeshInstance3D
var field_rings: Array[MeshInstance3D] = []
var energy_beams: Array[MeshInstance3D] = []
var core_light: OmniLight3D
var field_container: Node3D

func _ready() -> void:
	_build_resonator()

func _process(delta: float) -> void:
	time += delta
	
	# Core pulsing - fundamental frequency
	if core_sphere and core_sphere.material_override:
		var core_pulse = 0.5 + 0.5 * sin(time * resonance_frequency * TAU)
		core_sphere.material_override.emission_energy_multiplier = 1.0 + core_pulse * 2.0
		
		# Core scale breathes
		var scale = 1.0 + 0.1 * sin(time * resonance_frequency * TAU)
		core_sphere.scale = Vector3(scale, scale, scale)
	
	# Core light intensity
	if core_light:
		var light_pulse = field_strength * (0.5 + 0.5 * sin(time * resonance_frequency * TAU))
		core_light.light_energy = light_pulse * 2.0
	
	# Field rings - standing wave pattern with harmonics
	for i in range(field_rings.size()):
		var ring = field_rings[i]
		if ring and ring.material_override:
			var ring_phase = float(i) * PI / float(field_rings.size())
			
			# Superposition of fundamental and harmonics
			var wave: float = 0.0
			for h in range(1, harmonic_count + 1):
				var harmonic_amplitude = 1.0 / float(h)  # Harmonics decay
				wave += harmonic_amplitude * sin(time * resonance_frequency * float(h) * TAU + ring_phase * float(h))
			wave /= float(harmonic_count)  # Normalize
			
			var glow = 0.3 + 0.7 * (wave + 1.0) / 2.0
			ring.material_override.emission_energy_multiplier = glow * field_strength
			
			# Ring scale pulses
			var ring_scale = 1.0 + 0.05 * wave
			ring.scale.x = ring_scale
			ring.scale.z = ring_scale
	
	# Energy beams - rotating and pulsing
	if field_container:
		field_container.rotation.y += delta * 0.5
	
	for i in range(energy_beams.size()):
		var beam = energy_beams[i]
		if beam and beam.material_override:
			var beam_phase = float(i) * TAU / float(energy_beams.size())
			var beam_pulse = 0.3 + 0.7 * (0.5 + 0.5 * sin(time * resonance_frequency * 2.0 * TAU + beam_phase))
			beam.material_override.emission_energy_multiplier = beam_pulse * field_strength

func _build_resonator() -> void:
	for child in get_children():
		child.queue_free()
	field_rings.clear()
	energy_beams.clear()
	
	# Base housing
	var base = MeshInstance3D.new()
	base.name = "Base"
	var base_mesh = CylinderMesh.new()
	base_mesh.top_radius = 0.12
	base_mesh.bottom_radius = 0.14
	base_mesh.height = 0.04
	base_mesh.radial_segments = 32
	base.mesh = base_mesh
	base.position = Vector3(0, 0.02, 0)
	var base_mat = StandardMaterial3D.new()
	base_mat.albedo_color = Color(0.12, 0.1, 0.15)
	base_mat.metallic = 0.7
	base_mat.roughness = 0.3
	base.material_override = base_mat
	add_child(base)
	
	# Control ring
	var control_ring = MeshInstance3D.new()
	control_ring.name = "ControlRing"
	var ctrl_mesh = TorusMesh.new()
	ctrl_mesh.inner_radius = 0.1
	ctrl_mesh.outer_radius = 0.12
	control_ring.mesh = ctrl_mesh
	control_ring.position = Vector3(0, 0.045, 0)
	control_ring.rotation.x = PI / 2
	var ctrl_mat = StandardMaterial3D.new()
	ctrl_mat.albedo_color = Color(0.2, 0.15, 0.25)
	ctrl_mat.metallic = 0.8
	control_ring.material_override = ctrl_mat
	add_child(control_ring)
	
	# Core sphere
	core_sphere = MeshInstance3D.new()
	core_sphere.name = "Core"
	var core_mesh = SphereMesh.new()
	core_mesh.radius = 0.04
	core_mesh.height = 0.08
	core_mesh.radial_segments = 32
	core_mesh.rings = 16
	core_sphere.mesh = core_mesh
	core_sphere.position = Vector3(0, 0.12, 0)
	var core_mat = StandardMaterial3D.new()
	core_mat.albedo_color = core_color
	core_mat.emission_enabled = true
	core_mat.emission = core_color
	core_mat.emission_energy_multiplier = 2.0
	core_sphere.material_override = core_mat
	add_child(core_sphere)
	
	# Core light
	core_light = OmniLight3D.new()
	core_light.name = "CoreLight"
	core_light.position = Vector3(0, 0.12, 0)
	core_light.light_color = core_color
	core_light.light_energy = 1.0
	core_light.omni_range = 0.5
	add_child(core_light)
	
	# Field rings (horizontal, at different heights)
	for i in range(ring_count):
		var ring = MeshInstance3D.new()
		ring.name = "FieldRing_%d" % i
		var ring_mesh = TorusMesh.new()
		var radius = 0.06 + float(i) * 0.015
		ring_mesh.inner_radius = radius - 0.003
		ring_mesh.outer_radius = radius
		ring.mesh = ring_mesh
		ring.position = Vector3(0, 0.08 + float(i) * 0.02, 0)
		ring.rotation.x = PI / 2
		var ring_mat = StandardMaterial3D.new()
		ring_mat.albedo_color = Color(field_color.r, field_color.g, field_color.b, 0.6)
		ring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		ring_mat.emission_enabled = true
		ring_mat.emission = field_color
		ring_mat.emission_energy_multiplier = 0.5
		ring.material_override = ring_mat
		add_child(ring)
		field_rings.append(ring)
	
	# Energy beam container
	field_container = Node3D.new()
	field_container.name = "BeamContainer"
	field_container.position = Vector3(0, 0.12, 0)
	add_child(field_container)
	
	# Vertical energy beams
	var beam_count = 6
	for i in range(beam_count):
		var angle = float(i) * TAU / float(beam_count)
		var x = cos(angle) * 0.08
		var z = sin(angle) * 0.08
		
		var beam = MeshInstance3D.new()
		beam.name = "Beam_%d" % i
		var beam_mesh = CylinderMesh.new()
		beam_mesh.top_radius = 0.004
		beam_mesh.bottom_radius = 0.004
		beam_mesh.height = 0.1
		beam.mesh = beam_mesh
		beam.position = Vector3(x, 0, z)
		var beam_mat = StandardMaterial3D.new()
		beam_mat.albedo_color = Color(field_color.r, field_color.g, field_color.b, 0.4)
		beam_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		beam_mat.emission_enabled = true
		beam_mat.emission = field_color
		beam_mat.emission_energy_multiplier = 0.5
		beam.material_override = beam_mat
		field_container.add_child(beam)
		energy_beams.append(beam)
		
		# Beam cap
		var cap = MeshInstance3D.new()
		var cap_mesh = SphereMesh.new()
		cap_mesh.radius = 0.006
		cap_mesh.height = 0.012
		cap.mesh = cap_mesh
		cap.position = Vector3(0, 0.05, 0)
		cap.material_override = beam_mat
		beam.add_child(cap)
	
	# Status indicators
	var indicator_angles = [0.0, TAU/3, 2*TAU/3]
	var indicator_colors = [Color.GREEN, Color.CYAN, Color.MAGENTA]
	
	for i in range(3):
		var angle = indicator_angles[i]
		var ind = MeshInstance3D.new()
		var ind_mesh = SphereMesh.new()
		ind_mesh.radius = 0.008
		ind_mesh.height = 0.016
		ind.mesh = ind_mesh
		ind.position = Vector3(cos(angle) * 0.11, 0.045, sin(angle) * 0.11)
		var ind_mat = StandardMaterial3D.new()
		ind_mat.albedo_color = indicator_colors[i]
		ind_mat.emission_enabled = true
		ind_mat.emission = indicator_colors[i]
		ind_mat.emission_energy_multiplier = 0.8
		ind.material_override = ind_mat
		add_child(ind)

## Public API
func set_resonance_frequency(freq: float) -> void:
	resonance_frequency = freq

func set_field_strength(strength: float) -> void:
	field_strength = clamp(strength, 0.0, 2.0)

func set_harmonics(count: int) -> void:
	harmonic_count = clamp(count, 1, 8)

func trigger_resonance_burst() -> void:
	var original_strength = field_strength
	field_strength = 2.0
	await get_tree().create_timer(0.5).timeout
	field_strength = original_strength
