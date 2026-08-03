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
#   Kin on the `becoming` axis to [[queer_morphology_specimen]], which sits in this same registry
#   and carries the same four rungs. That artifact is a soft body arguing with its jar; this one
#   is the jar's oldest and most obedient occupant, which is exactly why it is worth asking the
#   same question of it.
# truth: DNA is a double wave frozen in molecular form — information stored as a helix.
#
# DNA AXIS — becoming: how far the specimen has travelled out of the container that classifies
#   it. The word and its four values are taken character for character from
#   [[queer_morphology_specimen]]; a private synonym would have split one question in two.
# emerges: at `jarred` the helix is a fact under glass. At `escaped` it is standing on the base
#   at twice the size with nothing around it, and the same geometry stops reading as evidence and
#   starts reading as a body. At `clouded` the jar is intact and the helix is simply GONE — the
#   volume is full, the order is not — which is the only rung that argues with the truth line
#   above rather than illustrating it.

@export var rotation_speed: float = 0.2
@export var helix_color_a: Color = Color(0.2, 0.6, 1.0)  # Blue strand
@export var helix_color_b: Color = Color(1.0, 0.4, 0.6)  # Pink strand
@export var fluid_color: Color = Color(0.1, 0.4, 0.3, 0.3)  # Green tint
@export var glow_intensity: float = 1.5

## AXIS — HOW FAR OUT OF THE JAR the specimen has come. Every rung is built from meshes and
## counts at build time, never from a running animation, so a still can hold it.
##
##   jarred   the shipped look — 0.12 m glass cylinder from y 0.05 to 0.50, metal lid seated
##            at 0.515, fluid to 0.43, the 0.30 m helix suspended at mid-height. 5 rooms,
##            byte for byte
##   cracked  the lid is off and lying tipped on the base 0.19 m to the right; the fluid drops
##            from 0.38 m to 0.24 m of column so a meniscus reads across the glass; the helix
##            rises 0.09 m so its top stands proud of the jar mouth
##   escaped  no jar and no fluid at all — only the 0.15 m base ring and the discarded lid are
##            left, and the helix is free-standing at twice its scale (0.15 m radius, 0.60 m
##            tall): the thing outside the vitrine is bigger than the thing inside it
##   clouded  jar, fluid and lid all stay sealed, but the helix is not shown — 220 grains of
##            0.011 m radius fill the whole interior column in the two strand colours, so the
##            volume is occupied and the sequence is gone
@export_enum("jarred", "cracked", "escaped", "clouded") var becoming: String = "jarred"

## Allow-list. A typo in a map token falls back to the shipped look rather than stranding a
## placement with a half-built vitrine.
const BECOMINGS: PackedStringArray = ["jarred", "cracked", "escaped", "clouded"]

const BC_GRAIN_COUNT := 220
const BC_GRAIN_R := 0.011
const BC_GOLDEN := 2.399963229728653   # golden angle, radians — the grains' only "randomness"

# Everything a rung adds hangs here; everything a rung MOVES is restored from these caches, so
# a token arriving through apply_grid_config can put the specimen back before rebuilding.
var _becoming_root: Node3D
var _shipped_lid_xform: Transform3D
var _shipped_helix_xform: Transform3D
var _shipped_fluid_mesh: Mesh
var _shipped_cached: bool = false

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