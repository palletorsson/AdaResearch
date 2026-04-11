# dna_specimen.gd
# DNA Double Helix in a glass specimen jar
# The helix slowly rotates, suspended in luminescent fluid
# Demonstrates biological oscillation and helical waveforms
extends Node3D

class_name DNASpecimen

## Helix parameters

# @identity
# essence: helix(t) = (r*cos(theta+t), h*t, r*sin(theta+t)) with pulsing emission
# desire: Observe a rotating double helix specimen in a glowing fluid-filled jar
# critical_parameter: rotation_speed — controls the mesmerizing spin that reveals helical structure
# triggers: time drives rotation and emission pulsing; glow_intensity modulates luminescence
# emerges: the specimen-as-meditation — continuous rotation reveals what static display cannot
# needs: VR observation [has], label customization [has]
# relationships: depends on double helix mesh; contrasts with double_helix_scene (specimen vs construction); unlocks biological oscillation appreciation
# truth: DNA is a double wave frozen in molecular form — information stored as a helix.

@export var rotation_speed: float = 0.2
@export var helix_color_a: Color = Color(0.2, 0.6, 1.0)  # Blue strand
@export var helix_color_b: Color = Color(1.0, 0.4, 0.6)  # Pink strand
@export var fluid_color: Color = Color(0.1, 0.4, 0.3, 0.3)  # Green tint
@export var glow_intensity: float = 1.5

## References
@onready var helix: Node3D = $HelixContainer/DoubleHelix
@onready var jar: MeshInstance3D = $Jar
@onready var fluid: MeshInstance3D = $Fluid
@onready var base: MeshInstance3D = $Base
@onready var label: Label3D = $Label

## Animation state
var time: float = 0.0
var pulse_phase: float = 0.0

func _ready() -> void:
	_setup_materials()
	_setup_helix()

func _setup_materials() -> void:
	# Jar glass material
	if jar:
		var jar_mat = StandardMaterial3D.new()
		jar_mat.albedo_color = Color(0.85, 0.92, 1.0, 0.12)
		jar_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		jar_mat.roughness = 0.05
		jar_mat.metallic = 0.1
		jar_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		jar.material_override = jar_mat
	
	# Fluid material
	if fluid:
		var fluid_mat = StandardMaterial3D.new()
		fluid_mat.albedo_color = fluid_color
		fluid_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		fluid_mat.emission_enabled = true
		fluid_mat.emission = Color(fluid_color.r, fluid_color.g, fluid_color.b)
		fluid_mat.emission_energy_multiplier = 0.3
		fluid.material_override = fluid_mat
	
	# Base material
	if base:
		var base_mat = StandardMaterial3D.new()
		base_mat.albedo_color = Color(0.15, 0.15, 0.18)
		base_mat.metallic = 0.7
		base_mat.roughness = 0.3
		base.material_override = base_mat

func _setup_helix() -> void:
	# Helix parameters are set in the .tscn instance
	# Just pass colors through if helix exists
	if helix and helix.has_method("set"):
		helix.set("strand_color_a", helix_color_a)
		helix.set("strand_color_b", helix_color_b)
		helix.set("glow_energy", glow_intensity)

func _process(delta: float) -> void:
	time += delta
	pulse_phase += delta * 2.0
	
	# Rotate helix slowly
	if helix:
		helix.rotation.y += delta * rotation_speed
	
	# Pulse the fluid glow
	if fluid and fluid.material_override:
		var pulse = 0.2 + sin(pulse_phase) * 0.1
		fluid.material_override.emission_energy_multiplier = pulse

func set_specimen_label(text: String) -> void:
	if label:
		label.text = text

func apply_grid_config(config_data: Dictionary):
	for key in config_data:
		if key in self:
			set(key, config_data[key])