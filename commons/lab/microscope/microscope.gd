# microscope.gd
# Laboratory microscope with pulsing illumination
# Light intensity follows sine wave for focus demonstration
extends Node3D

class_name LabMicroscope


# @identity
# essence: intensity(t) = min + (max-min) * (0.5 + 0.5 * sin(frequency * t * TAU))
# desire: Peer at a microscope whose illumination breathes with gentle sine-wave pulsing
# critical_parameter: light_frequency — controls the breathing rate of the stage illumination
# triggers: time drives sinusoidal light intensity modulation on stage and objective lights
# emerges: the feeling of a living instrument — breathing light suggests active observation
# needs: VR observation [has], focus knob interaction [missing]
# relationships: depends on sine-driven light animation; contrasts with holographicdisplay (optical vs holographic); unlocks lab instrument atmosphere
# truth: Illumination is oscillation made useful — the microscope tames light waves into vision.

@export_group("Illumination")
@export var light_frequency: float = 0.3  # Hz - slow breathing
@export var light_min: float = 0.3
@export var light_max: float = 1.5
@export var light_color: Color = Color(1.0, 0.98, 0.9)

@export_group("Focus")
@export var auto_focus: bool = true
@export var focus_frequency: float = 0.1  # Hz
@export var focus_range: float = 0.01  # Meters

## Internal
var time: float = 0.0
var stage_light: OmniLight3D
var objective_light: SpotLight3D
var focus_knob: Node3D
var stage_node: Node3D
var eyepiece_glow: MeshInstance3D

func _ready() -> void:
	_build_microscope()

func _process(delta: float) -> void:
	time += delta
	
	# Stage illumination - primary sine wave
	if stage_light:
		var intensity = light_min + (light_max - light_min) * (0.5 + 0.5 * sin(time * light_frequency * TAU))
		stage_light.light_energy = intensity
	
	# Objective lens subtle glow
	if objective_light:
		var obj_intensity = 0.3 + 0.2 * sin(time * light_frequency * TAU + PI / 2)
		objective_light.light_energy = obj_intensity
	
	# Auto-focus simulation - stage moves slightly
	if auto_focus and stage_node:
		var focus_offset = focus_range * sin(time * focus_frequency * TAU)
		stage_node.position.y = 0.15 + focus_offset
	
	# Focus knob rotation follows focus
	if focus_knob:
		focus_knob.rotation.z = time * focus_frequency * TAU * 0.5
	
	# Eyepiece glow
	if eyepiece_glow and eyepiece_glow.material_override:
		var glow = 0.3 + 0.3 * sin(time * light_frequency * TAU)
		eyepiece_glow.material_override.emission_energy_multiplier = glow

func _build_microscope() -> void:
	for child in get_children():
		child.queue_free()
	
	# Base
	var base = MeshInstance3D.new()
	base.name = "Base"
	var base_mesh = BoxMesh.new()
	base_mesh.size = Vector3(0.15, 0.02, 0.2)
	base.mesh = base_mesh
	base.position = Vector3(0, 0.01, 0)
	var base_mat = StandardMaterial3D.new()
	base_mat.albedo_color = Color(0.15, 0.15, 0.18)
	base_mat.metallic = 0.7
	base_mat.roughness = 0.3
	base.material_override = base_mat
	add_child(base)
	
	# Arm/pillar
	var arm = MeshInstance3D.new()
	arm.name = "Arm"
	var arm_mesh = BoxMesh.new()
	arm_mesh.size = Vector3(0.04, 0.35, 0.04)
	arm.mesh = arm_mesh
	arm.position = Vector3(0, 0.195, -0.07)
	arm.material_override = base_mat
	add_child(arm)
	
	# Stage
	stage_node = Node3D.new()
	stage_node.name = "StagePivot"
	stage_node.position = Vector3(0, 0.15, 0.02)
	add_child(stage_node)
	
	var stage = MeshInstance3D.new()
	stage.name = "Stage"
	var stage_mesh = CylinderMesh.new()
	stage_mesh.top_radius = 0.055
	stage_mesh.bottom_radius = 0.055
	stage_mesh.height = 0.01
	stage_mesh.radial_segments = 32
	stage.mesh = stage_mesh
	var stage_mat = StandardMaterial3D.new()
	stage_mat.albedo_color = Color(0.2, 0.2, 0.22)
	stage_mat.metallic = 0.6
	stage.material_override = stage_mat
	stage_node.add_child(stage)
	
	# Stage glass (sample area)
	var glass = MeshInstance3D.new()
	glass.name = "StageGlass"
	var glass_mesh = CylinderMesh.new()
	glass_mesh.top_radius = 0.015
	glass_mesh.bottom_radius = 0.015
	glass_mesh.height = 0.002
	glass.mesh = glass_mesh
	glass.position = Vector3(0, 0.006, 0)
	var glass_mat = StandardMaterial3D.new()
	glass_mat.albedo_color = Color(0.9, 0.95, 1.0, 0.3)
	glass_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.material_override = glass_mat
	stage_node.add_child(glass)
	
	# Stage illumination (from below)
	stage_light = OmniLight3D.new()
	stage_light.name = "StageLight"
	stage_light.position = Vector3(0, -0.03, 0)
	stage_light.light_color = light_color
	stage_light.light_energy = light_min
	stage_light.omni_range = 0.15
	stage_node.add_child(stage_light)
	
	# Objective turret
	var turret = MeshInstance3D.new()
	turret.name = "Turret"
	var turret_mesh = CylinderMesh.new()
	turret_mesh.top_radius = 0.025
	turret_mesh.bottom_radius = 0.03
	turret_mesh.height = 0.02
	turret.mesh = turret_mesh
	turret.position = Vector3(0, 0.22, 0.02)
	turret.material_override = base_mat
	add_child(turret)
	
	# Objective lenses
	var objectives = [
		{"offset": 0.0, "length": 0.04, "color": Color(0.8, 0.2, 0.2)},
		{"offset": TAU/3, "length": 0.05, "color": Color(0.8, 0.8, 0.2)},
		{"offset": 2*TAU/3, "length": 0.06, "color": Color(0.2, 0.2, 0.8)},
	]
	
	for obj in objectives:
		var lens = MeshInstance3D.new()
		var lens_mesh = CylinderMesh.new()
		lens_mesh.top_radius = 0.008
		lens_mesh.bottom_radius = 0.01
		lens_mesh.height = obj.length
		lens.mesh = lens_mesh
		var x = cos(obj.offset) * 0.018
		var z = sin(obj.offset) * 0.018
		lens.position = Vector3(x, 0.21 - obj.length / 2, 0.02 + z)
		var lens_mat = StandardMaterial3D.new()
		lens_mat.albedo_color = obj.color
		lens_mat.metallic = 0.8
		lens.material_override = lens_mat
		add_child(lens)
		
		# Color ring
		var ring = MeshInstance3D.new()
		var ring_mesh = TorusMesh.new()
		ring_mesh.inner_radius = 0.007
		ring_mesh.outer_radius = 0.01
		ring.mesh = ring_mesh
		ring.position = Vector3(x, 0.21, 0.02 + z)
		ring.rotation.x = PI / 2
		ring.material_override = lens_mat
		add_child(ring)
	
	# Objective light (pointing down)
	objective_light = SpotLight3D.new()
	objective_light.name = "ObjectiveLight"
	objective_light.position = Vector3(0, 0.19, 0.02)
	objective_light.rotation.x = PI
	objective_light.light_color = Color(0.8, 0.9, 1.0)
	objective_light.light_energy = 0.3
	objective_light.spot_range = 0.1
	objective_light.spot_angle = 30.0
	add_child(objective_light)
	
	# Eyepiece tube
	var tube = MeshInstance3D.new()
	tube.name = "EyepieceTube"
	var tube_mesh = CylinderMesh.new()
	tube_mesh.top_radius = 0.018
	tube_mesh.bottom_radius = 0.02
	tube_mesh.height = 0.12
	tube.mesh = tube_mesh
	tube.position = Vector3(0, 0.31, -0.02)
	tube.rotation.x = 0.3
	tube.material_override = base_mat
	add_child(tube)
	
	# Eyepiece
	var eyepiece = MeshInstance3D.new()
	eyepiece.name = "Eyepiece"
	var eye_mesh = CylinderMesh.new()
	eye_mesh.top_radius = 0.022
	eye_mesh.bottom_radius = 0.018
	eye_mesh.height = 0.03
	eyepiece.mesh = eye_mesh
	eyepiece.position = Vector3(0, 0.065, 0)
	var eye_mat = StandardMaterial3D.new()
	eye_mat.albedo_color = Color(0.1, 0.1, 0.12)
	eye_mat.roughness = 0.9
	eyepiece.material_override = eye_mat
	tube.add_child(eyepiece)
	
	# Eyepiece lens glow
	eyepiece_glow = MeshInstance3D.new()
	eyepiece_glow.name = "EyepieceGlow"
	var glow_mesh = CylinderMesh.new()
	glow_mesh.top_radius = 0.015
	glow_mesh.bottom_radius = 0.015
	glow_mesh.height = 0.003
	eyepiece_glow.mesh = glow_mesh
	eyepiece_glow.position = Vector3(0, 0.016, 0)
	var glow_mat = StandardMaterial3D.new()
	glow_mat.albedo_color = Color(0.8, 0.9, 1.0, 0.5)
	glow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glow_mat.emission_enabled = true
	glow_mat.emission = Color(0.9, 0.95, 1.0)
	glow_mat.emission_energy_multiplier = 0.3
	eyepiece_glow.material_override = glow_mat
	eyepiece.add_child(eyepiece_glow)
	
	# Focus knobs
	focus_knob = Node3D.new()
	focus_knob.name = "FocusKnobPivot"
	focus_knob.position = Vector3(0.05, 0.18, -0.07)
	add_child(focus_knob)
	
	var knob = MeshInstance3D.new()
	var knob_mesh = CylinderMesh.new()
	knob_mesh.top_radius = 0.02
	knob_mesh.bottom_radius = 0.02
	knob_mesh.height = 0.015
	knob.mesh = knob_mesh
	knob.rotation.z = PI / 2
	var knob_mat = StandardMaterial3D.new()
	knob_mat.albedo_color = Color(0.25, 0.25, 0.28)
	knob_mat.metallic = 0.5
	knob.material_override = knob_mat
	focus_knob.add_child(knob)
	
	# Fine focus knob (smaller)
	var fine_knob = knob.duplicate()
	fine_knob.scale = Vector3(0.6, 0.6, 0.6)
	fine_knob.position.x = 0.02
	focus_knob.add_child(fine_knob)

## Public API
func set_light_intensity(intensity: float) -> void:
	light_max = intensity

func set_auto_focus(enabled: bool) -> void:
	auto_focus = enabled

func pulse_light() -> void:
	if stage_light:
		stage_light.light_energy = light_max * 2.0
		var tween = create_tween()
		tween.tween_property(stage_light, "light_energy", light_max, 0.5)
