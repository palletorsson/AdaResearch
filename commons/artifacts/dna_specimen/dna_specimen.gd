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

## AXIS — WHICH WAY THE LADDER TURNS. B-DNA, the form in every textbook and in all five
## existing placements, is a RIGHT-handed helix. Z-DNA is left-handed: not a stylistic flip
## but a different conformation the same sequence adopts under salt and strain. A specimen
## jar that can only hold one of them is making a claim about which DNA counts as DNA.
##
##   right   the shipped look — the angle advances with +i, exactly as doublehelix.gd has
##           always built it
##   left    the mirror image — the angle advances with -i. Same radius, same pitch, same
##           rung spacing, same colours; the twist runs the other way and a still shows it
@export_enum("right", "left") var handedness: String = "right"

## Allow-list. A typo in a map token falls back to the shipped look rather than stranding a
## placement with a half-built vitrine.
const BECOMINGS: PackedStringArray = ["jarred", "cracked", "escaped", "clouded"]
const HANDEDNESSES: PackedStringArray = ["right", "left"]

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

## True once _ready has built the specimen at least once. apply_grid_config must never
## rebuild before this, and never rebuild when nothing it reads has changed.
var _built: bool = false

func _ready() -> void:
	_cache_shipped()
	_setup_materials()
	_setup_helix()
	_apply_becoming()
	_built = true

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
		helix.set("handedness", _valid(handedness, HANDEDNESSES, "right"))


# --- becoming: the four rungs ------------------------------------------------------------
# Everything here is meshes and transforms resolved at build time. No rung depends on the
# rotation or the emission pulse, so one still frame is a complete account of the value.

func _valid(value: String, allowed: PackedStringArray, fallback: String) -> String:
	return value if allowed.has(value) else fallback

func _cache_shipped() -> void:
	# The shipped placement of everything a rung MOVES, so any rung can be left again.
	if _shipped_cached:
		return
	var lid: MeshInstance3D = get_node_or_null("Lid")
	if lid:
		_shipped_lid_xform = lid.transform
	var container: Node3D = get_node_or_null("HelixContainer")
	if container:
		_shipped_helix_xform = container.transform
	if fluid:
		_shipped_fluid_mesh = fluid.mesh
	_shipped_cached = true

func _restore_shipped() -> void:
	if _becoming_root and is_instance_valid(_becoming_root):
		_becoming_root.queue_free()
	_becoming_root = null
	var lid: MeshInstance3D = get_node_or_null("Lid")
	if lid:
		lid.transform = _shipped_lid_xform
		lid.visible = true
	var container: Node3D = get_node_or_null("HelixContainer")
	if container:
		container.transform = _shipped_helix_xform
	if jar:
		jar.visible = true
	if fluid:
		fluid.visible = true
		if _shipped_fluid_mesh:
			fluid.mesh = _shipped_fluid_mesh
	if helix:
		helix.visible = true

func _apply_becoming() -> void:
	_restore_shipped()
	match _valid(becoming, BECOMINGS, "jarred"):
		"cracked":
			_lay_lid_down()
			_set_fluid_column(0.24)
			_shift_helix(0.09)
		"escaped":
			_lay_lid_down()
			if jar:
				jar.visible = false
			if fluid:
				fluid.visible = false
			_free_the_helix()
			_add_extent_anchor()
		"clouded":
			if helix:
				helix.visible = false
			_grow_grains()
		_:
			# "jarred" — the shipped vitrine, restored above and touched no further.
			pass

func _lay_lid_down() -> void:
	# Off the jar and tipped on the base plate, 0.19 m to the right.
	var lid: MeshInstance3D = get_node_or_null("Lid")
	if not lid:
		return
	var basis_tipped: Basis = Basis(Vector3(0.0, 0.0, 1.0), 1.4)
	lid.transform = Transform3D(basis_tipped, Vector3(0.19, 0.062, 0.015))

func _set_fluid_column(column_height: float) -> void:
	# Drop the meniscus without moving the floor of the jar: the fluid's base stays at 0.05.
	if not fluid:
		return
	var shrunk: CylinderMesh = CylinderMesh.new()
	shrunk.top_radius = 0.11
	shrunk.bottom_radius = 0.11
	shrunk.height = column_height
	shrunk.radial_segments = 24
	fluid.mesh = shrunk
	fluid.position.y = 0.05 + column_height * 0.5

func _shift_helix(delta_y: float) -> void:
	var container: Node3D = get_node_or_null("HelixContainer")
	if not container:
		return
	container.position.y = _shipped_helix_xform.origin.y + delta_y

func _free_the_helix() -> void:
	# Twice the scale, standing on the base ring with no vitrine around it: 0.15 m radius,
	# 0.60 m tall, against a jar that was 0.12 m by 0.45 m.
	var container: Node3D = get_node_or_null("HelixContainer")
	if not container:
		return
	container.scale = Vector3.ONE * 0.30
	container.position.y = 0.35

func _add_extent_anchor() -> void:
	# The helix draws its strands with MultiMeshInstance3D, which the capture AABB does not
	# count, and `escaped` hides the jar and the fluid — the two MeshInstance3D bodies that
	# gave the specimen its height. Without this the framing camera fits a 0.15 m base plate
	# and clips the 0.60 m helix standing on it. layers = 0: measured, never rendered.
	var holder: Node3D = Node3D.new()
	holder.name = "BecomingExtent"
	add_child(holder)
	_becoming_root = holder

	var box: BoxMesh = BoxMesh.new()
	box.size = Vector3(0.30, 0.62, 0.30)
	var anchor: MeshInstance3D = MeshInstance3D.new()
	anchor.name = "ExtentAnchor"
	anchor.mesh = box
	anchor.layers = 0
	anchor.position = Vector3(0.0, 0.35, 0.0)
	holder.add_child(anchor)

func _grow_grains() -> void:
	# The jar is sealed and full and the sequence is gone. 220 grains on a golden-angle
	# spiral — deterministic, so the same still comes back every capture.
	var grains: Node3D = Node3D.new()
	grains.name = "BecomingClouded"
	add_child(grains)
	_becoming_root = grains

	var grain_mesh: SphereMesh = SphereMesh.new()
	grain_mesh.radius = BC_GRAIN_R
	grain_mesh.height = BC_GRAIN_R * 2.0
	grain_mesh.radial_segments = 8
	grain_mesh.rings = 4

	var mat_a: StandardMaterial3D = _grain_material(helix_color_a)
	var mat_b: StandardMaterial3D = _grain_material(helix_color_b)

	for i in range(BC_GRAIN_COUNT):
		var t: float = (float(i) + 0.5) / float(BC_GRAIN_COUNT)
		var angle: float = float(i) * BC_GOLDEN
		var radius: float = 0.095 * sqrt(fmod(float(i) * 0.7548776662, 1.0))
		var y: float = 0.07 + t * 0.34
		var grain: MeshInstance3D = MeshInstance3D.new()
		grain.mesh = grain_mesh
		grain.material_override = mat_a if i % 2 == 0 else mat_b
		grain.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		grain.position = Vector3(cos(angle) * radius, y, sin(angle) * radius)
		grains.add_child(grain)

func _grain_material(color: Color) -> StandardMaterial3D:
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = 0.1
	mat.roughness = 0.5
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = glow_intensity * 0.4
	return mat

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
	# GUARDED. Config can arrive before _ready (GridInteractablesComponent stamps it on the
	# node it is about to add) and it can arrive after. Plain assignment is always safe;
	# rebuilding is only safe once _ready has built, and only when a value actually moved.
	# Every existing placement passes neither axis, so none of them is touched here.
	var becoming_changed: bool = false
	var handedness_changed: bool = false
	for key in config_data:
		if key == "becoming":
			var b: String = _valid(str(config_data[key]).to_lower(), BECOMINGS, becoming)
			if b != becoming:
				becoming = b
				becoming_changed = true
		elif key == "handedness":
			var h: String = _valid(str(config_data[key]).to_lower(), HANDEDNESSES, handedness)
			if h != handedness:
				handedness = h
				handedness_changed = true
		elif key in self:
			set(key, config_data[key])
	if not _built:
		return
	if handedness_changed and helix:
		helix.set("handedness", handedness)
	if becoming_changed:
		_apply_becoming()