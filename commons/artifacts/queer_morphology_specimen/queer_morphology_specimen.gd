# queer_morphology_specimen.gd
# The synthesis artifact — form that refuses fixed categories
# Soft body + fluid + QFEP responsiveness in a specimen jar
#
# λ (lambda) = edge of chaos: how close to phase transition
# φ (phi) = becoming: embracing vs resisting transformation
#
# "Queer morphology" — not a fixed thing but a process of becoming

extends Node3D

class_name QueerMorphologySpecimen

# @identity
# essence: soft_body(stiffness(lambda), damping(phi)) + fluid_shader(turbulence) -> specimen_in_jar
# desire: hold a creature that refuses to be one thing, watch it breathe between crystal and dissolution
# critical_parameter: lambda — edge of chaos dial that transitions specimen from crystalline to dissolving
# triggers: lambda shifts stiffness/pressure/color; phi shifts damping/drag/subsurface scatter; presets jump to named states
# emerges: the breathing motion at edge of chaos where pressure oscillates — the specimen appears alive
# needs: VR sliders for lambda and phi [has], preset buttons [has], soft body physics [has]
# relationships: synthesizes entire QFEP sequence; depends on lambda_slider, phi_slider; contrasts rigid_sculpture (frozen) vs fluid_form (flowing)
# truth: queer morphology is not a fixed form but a process of becoming — the specimen is the theory made flesh

## Jar dimensions
@export var jar_height: float = 0.4
@export var jar_radius: float = 0.15

## Stage-2 DNA axis — how far the specimen has travelled out of the container
## that classifies it. `becoming` is this file's own word for φ, and the jar is
## the claim the artifact exists to argue against: sealed under glass, breaching
## the seal, standing free of it, or no longer one body at all.
##
##   jarred   the shipped look — the 0.30 m x 0.40 m glass cylinder with its
##            0.03 m metal lid seated on top, fluid filling it, one 0.12 m soft
##            body suspended at mid-height on the 0.45 m museum pedestal
##   cracked  the lid is off and tipped on the pedestal 0.19 m to the right, the
##            top 0.06 m of glass is not built (an open rim), the body sits half
##            out of the mouth standing 0.05 m proud of it, and the fluid drops
##            to 0.28 m so the meniscus reads
##   escaped  no cylinder and no fluid at all — only the 0.36 m base ring and the
##            discarded lid are left, and the body is free-standing at 0.22 m
##            across with its subsurface scatter at full: the thing outside the
##            vitrine is bigger than the thing inside it
##   clouded  jar and lid stay sealed, but the single body is not built — 90
##            spheres of 0.012 m fill the full 0.27 m interior in the specimen's
##            own violet, so the volume is occupied and the individual is gone
##
## Read at the TOP of _ready() before the builders run, so setting the export and
## adding to the tree gives the right still on frame 1. Deliberately NOT routed
## through λ/φ physics: SoftBody3D deformation needs many physics frames to
## diverge, and a headless still taken near frame 1 would show four identical
## spheres. Every value here changes MESHES AND COUNTS at build time.
@export_enum("jarred", "cracked", "escaped", "clouded") var becoming: String = "jarred"

## Allow-list for the axis. A typo in a map token falls back to the shipped look
## rather than stranding a placement with a half-built vitrine.
const BECOMINGS: PackedStringArray = ["jarred", "cracked", "escaped", "clouded"]

## Top face of the museum pedestal (position -0.065, height 0.08) — the surface
## the jar base, and the displaced lid, actually rest on.
const PEDESTAL_TOP: float = -0.025

const CRACK_RIM_CUT: float = 0.06      # metres of glass not built at the mouth
const CRACK_LID_OFFSET: float = 0.19   # lid displaced this far +X along the pedestal
const CRACK_PROUD: float = 0.05        # specimen standing this far above the cut rim
const CRACK_FLUID_H: float = 0.28      # shortened fluid column — the meniscus shows
const ESCAPED_DIAMETER: float = 0.22   # free-standing body, nearly double
const CLOUD_COUNT: int = 90
const CLOUD_RADIUS: float = 0.012
const CLOUD_SEED: int = 20260729       # fixed — the same suspension every run

## The museum plate. 0.30 m wide gives a 0.336 x 0.222 m board once TextScreen
## adds its 0.018 m bezel; centred at 0.63 it spans y 0.519–0.741, entirely above
## the 0.43 m lid, so a front-on camera sees plate, then air, then specimen.
const PLATE_WIDTH: float = 0.30
const PLATE_Y: float = 0.63

const TextScreenScript := preload("res://commons/ui/text_screen.gd")

## QFEP Parameters
@export_group("QFEP")
@export_range(0.0, 1.0) var lambda: float = 0.5:  # Edge of chaos
	set(value):
		lambda = clampf(value, 0.0, 1.0)
		_apply_lambda()
		_sync_lambda_slider()

@export_range(-1.0, 1.0) var phi: float = 0.0:  # Becoming
	set(value):
		phi = clampf(value, -1.0, 1.0)
		_apply_phi()
		_sync_phi_slider()

## Specimen properties
@export_group("Specimen")
@export var base_stiffness: float = 0.5
@export var base_pressure: float = 1.0
@export var base_damping: float = 0.05
@export var specimen_color: Color = Color(0.4, 0.2, 0.6, 0.85)

## Fluid properties
@export_group("Fluid")
@export var fluid_color: Color = Color(0.6, 0.8, 0.7, 0.3)
@export var fluid_turbulence: float = 0.5

var _jar_mesh: MeshInstance3D
var _fluid_mesh: MeshInstance3D
var _fluid_material: ShaderMaterial
var _soft_body: SoftBody3D
var _cloud: MultiMeshInstance3D
var _specimen_material: StandardMaterial3D
var _info_label: Label3D
var _state_label: Label3D
# Untyped on purpose: TextScreen's own properties (mode/width_m/set_text) are not
# on Node3D, and a statically-typed reference would refuse to compile against them.
var _text_screen = null

# VR Controls
var _lambda_slider: Node
var _phi_slider: Node
var _control_panel: Node3D

# Lifecycle. `_created` is every node THIS script added as a direct child — the
# rebuild frees only these, because the grid adds framing, plates and grounding
# of its own and get_children() would take those with it.
var _built: bool = false
var _created: Array[Node] = []
var _emissive: bool = true

# State descriptions for different parameter regions
const STATES = {
	"crystalline": "CRYSTALLINE\nRigid structure\nResisting change",
	"stable": "STABLE\nOrdered equilibrium\nMaintaining form",
	"edge": "EDGE OF CHAOS\nMaximal complexity\nWhere life emerges",
	"fluid": "FLUID\nDissipative flow\nContinuous becoming",
	"dissolving": "DISSOLVING\nEntropy wins\nForm releasing"
}


const FLUID_SHADER = """
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled;

uniform vec4 fluid_color : source_color = vec4(0.6, 0.8, 0.7, 0.3);
uniform float turbulence = 0.5;
uniform float time_scale = 1.0;
uniform float lambda = 0.5;
uniform float phi = 0.0;

float noise3d(vec3 p) {
	return fmod(sin(dot(p, vec3(12.9898, 78.233, 45.164, 1.0))) * 43758.5453);
}

float fbm(vec3 p) {
	float value = 0.0;
	float amplitude = 0.5;
	for (int i = 0; i < 4; i++) {
		value += amplitude * noise3d(p);
		p *= 2.0;
		amplitude *= 0.5;
	}
	return value;
}

void fragment() {
	vec3 world_pos = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float t = TIME * time_scale;
	
	// Fluid motion influenced by lambda (chaos) and phi (becoming)
	float chaos_factor = lambda * 2.0;
	float flow_factor = (phi + 1.0) / 2.0;
	
	vec3 flow = vec3(
		sin(t * 0.5 + world_pos.y * 3.0) * chaos_factor,
		cos(t * 0.3 + world_pos.x * 2.0) * flow_factor,
		sin(t * 0.4 + world_pos.z * 2.5) * turbulence
	);
	
	float noise = fbm(world_pos * 5.0 + flow + t * 0.2);
	
	// Color shifts with phi (negative = cold/rigid, positive = warm/fluid)
	vec3 color_shift = vec3(
		phi * 0.2,
		-abs(phi) * 0.1,
		-phi * 0.15
	);
	
	ALBEDO = fluid_color.rgb + color_shift + noise * 0.1;
	ALPHA = fluid_color.a * (0.8 + noise * 0.4);
	EMISSION = ALBEDO * lambda * 0.3;
}
"""

func _ready():
	_build_all()
	_built = true


## SYNCHRONOUS build from the @export values alone. `becoming` is resolved here,
## at the top, before any builder runs — so a sweep that sets the export and adds
## the node to the tree photographs the right thing on frame 1. Nothing in this
## path waits for physics or for a deferred call.
func _build_all() -> void:
	becoming = _pick_axis(becoming, BECOMINGS, "jarred")
	_create_jar()
	_create_fluid()
	_create_specimen()
	_create_labels()
	_create_vr_controls()
	_apply_lambda()
	_apply_phi()


## add_child, and remember we did — see `_created`.
func _add_tracked(n: Node) -> void:
	add_child(n)
	_created.append(n)


func _create_jar():
	var lid_mat = StandardMaterial3D.new()
	lid_mat.albedo_color = Color(0.25, 0.22, 0.2)
	lid_mat.metallic = 0.8
	lid_mat.roughness = 0.4

	# `escaped` dismantles the vitrine: no glass cylinder is built at all.
	if becoming != "escaped":
		# Glass jar (cylinder with transparent material)
		_jar_mesh = MeshInstance3D.new()
		_jar_mesh.name = "JarGlass"

		# `cracked` does not build the top CRACK_RIM_CUT of glass — an open rim.
		var glass_h: float = jar_height
		if becoming == "cracked":
			glass_h = jar_height - CRACK_RIM_CUT

		var cylinder = CylinderMesh.new()
		cylinder.top_radius = jar_radius
		cylinder.bottom_radius = jar_radius * 1.05
		cylinder.height = glass_h
		cylinder.radial_segments = 32
		_jar_mesh.mesh = cylinder

		var glass_mat = StandardMaterial3D.new()
		glass_mat.albedo_color = Color(0.9, 0.95, 1.0, 0.15)
		glass_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		glass_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		glass_mat.metallic = 0.1
		glass_mat.roughness = 0.05
		glass_mat.refraction_enabled = true
		glass_mat.refraction_scale = 0.02
		_jar_mesh.material_override = glass_mat

		_jar_mesh.position = Vector3(0, glass_h / 2, 0)
		_add_tracked(_jar_mesh)

	# Jar lid — seated on the mouth while the seal holds, tipped onto its rim
	# beside the jar once it has been broken. The lid is always built: a
	# discarded lid is the evidence that there was a container.
	var lid = MeshInstance3D.new()
	var lid_cyl = CylinderMesh.new()
	lid_cyl.top_radius = jar_radius * 1.1
	lid_cyl.bottom_radius = jar_radius * 1.15
	lid_cyl.height = 0.03
	lid.mesh = lid_cyl
	lid.material_override = lid_mat

	if becoming == "cracked" or becoming == "escaped":
		lid.name = "JarLidDisplaced"
		# Lying on its side: the axis swung to +X, so the disc stands on its own
		# rim as a thin slab clear of the jar's footprint and inside the pedestal.
		lid.rotation_degrees = Vector3(0, 0, 90)
		lid.position = Vector3(CRACK_LID_OFFSET, PEDESTAL_TOP + jar_radius * 1.15, 0)
	else:
		lid.name = "JarLid"
		lid.position = Vector3(0, jar_height + 0.015, 0)
	_add_tracked(lid)

	# Jar base — the 0.36 m metal ring. Survives every value; in `escaped` it and
	# the discarded lid are all that is left of the apparatus.
	var base = MeshInstance3D.new()
	base.name = "JarBase"
	var base_cyl = CylinderMesh.new()
	base_cyl.top_radius = jar_radius * 1.2
	base_cyl.bottom_radius = jar_radius * 1.3
	base_cyl.height = 0.025
	base.mesh = base_cyl
	base.material_override = lid_mat
	base.position = Vector3(0, -0.0125, 0)
	_add_tracked(base)

	# Museum pedestal
	var pedestal = MeshInstance3D.new()
	pedestal.name = "Pedestal"
	var ped_box = BoxMesh.new()
	ped_box.size = Vector3(jar_radius * 3, 0.08, jar_radius * 3)
	pedestal.mesh = ped_box

	var ped_mat = StandardMaterial3D.new()
	ped_mat.albedo_color = Color(0.12, 0.12, 0.14)
	ped_mat.metallic = 0.5
	ped_mat.roughness = 0.6
	pedestal.material_override = ped_mat
	pedestal.position = Vector3(0, -0.065, 0)
	_add_tracked(pedestal)

func _create_fluid():
	# `escaped` has no medium: the vitrine and the fluid that preserved it are
	# both gone, and what is left is standing in air.
	if becoming == "escaped":
		return

	# Inner fluid volume (slightly smaller than jar)
	_fluid_mesh = MeshInstance3D.new()
	_fluid_mesh.name = "FluidVolume"

	# `cracked` drops the column to CRACK_FLUID_H — the surface falls 0.06 m below
	# the cut rim, so there is a visible meniscus instead of a filled jar.
	var fluid_h: float = jar_height * 0.85
	if becoming == "cracked":
		fluid_h = CRACK_FLUID_H

	var fluid_cyl = CylinderMesh.new()
	fluid_cyl.top_radius = jar_radius * 0.9
	fluid_cyl.bottom_radius = jar_radius * 0.9
	fluid_cyl.height = fluid_h
	_fluid_mesh.mesh = fluid_cyl

	_fluid_material = ShaderMaterial.new()
	var shader = Shader.new()
	shader.code = FLUID_SHADER
	_fluid_material.shader = shader
	_fluid_material.set_shader_parameter("fluid_color", fluid_color)
	_fluid_material.set_shader_parameter("turbulence", fluid_turbulence)
	_fluid_material.set_shader_parameter("lambda", lambda)
	_fluid_material.set_shader_parameter("phi", phi)
	
	_fluid_mesh.material_override = _fluid_material
	# Anchored by its BOTTOM, not its centre: at the shipped height this is
	# exactly jar_height / 2, and a shortened column then falls rather than
	# shrinking symmetrically around mid-jar.
	_fluid_mesh.position = Vector3(0, jar_height * 0.075 + fluid_h * 0.5, 0)
	_add_tracked(_fluid_mesh)

func _create_specimen():
	# `clouded` builds no individual at all — see _create_suspension.
	if becoming == "clouded":
		_create_suspension()
		_create_jar_collision()
		return

	# The morphing creature — a soft body sphere that deforms
	_soft_body = SoftBody3D.new()
	_soft_body.name = "Specimen"

	# `escaped` builds it at ESCAPED_DIAMETER — nearly double. The thing outside
	# the vitrine is bigger than the thing that was inside it.
	var body_radius: float = jar_radius * 0.4
	if becoming == "escaped":
		body_radius = ESCAPED_DIAMETER * 0.5

	# Use subdivided sphere for organic deformation
	var sphere = SphereMesh.new()
	sphere.radius = body_radius
	sphere.height = body_radius * 2.0
	sphere.radial_segments = 16
	sphere.rings = 12
	_soft_body.mesh = sphere

	# Physics
	_soft_body.simulation_precision = 8
	_soft_body.total_mass = 0.5
	_soft_body.linear_stiffness = base_stiffness
	_soft_body.pressure_coefficient = base_pressure
	_soft_body.damping_coefficient = base_damping
	_soft_body.drag_coefficient = 0.1
	
	# Collision
	_soft_body.collision_layer = 1
	_soft_body.collision_mask = 1
	
	# Material
	_specimen_material = _make_specimen_material()

	_soft_body.material_override = _specimen_material

	# Where the body sits relative to the container it is leaving.
	var body_y: float = jar_height * 0.5
	if becoming == "cracked":
		# Half out of the mouth, standing CRACK_PROUD above the cut rim.
		body_y = (jar_height - CRACK_RIM_CUT) + CRACK_PROUD - body_radius
	elif becoming == "escaped":
		# Free-standing on the base ring, no glass around it.
		body_y = body_radius
	_soft_body.position = Vector3(0, body_y, 0)

	_add_tracked(_soft_body)

	# Invisible boundary to keep specimen in jar
	_create_jar_collision()


## The violet the specimen is made of. Shared by the single body and by the
## `clouded` suspension, so λ's hue shift and φ's scatter still drive both.
func _make_specimen_material() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = specimen_color
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.emission_enabled = _emissive
	m.emission = specimen_color
	m.emission_energy_multiplier = 0.2 if _emissive else 0.0
	m.roughness = 0.3
	m.metallic = 0.1
	m.subsurf_scatter_enabled = true
	m.subsurf_scatter_strength = 0.5
	return m


## `clouded` — the body has stopped being one body. CLOUD_COUNT spheres of
## CLOUD_RADIUS fill the full 0.27 m interior width of the sealed jar in the
## specimen's own violet: the volume is still occupied, the individual is gone.
## One MultiMesh, one fixed seed — the same suspension every run.
func _create_suspension() -> void:
	_specimen_material = _make_specimen_material()

	var sphere := SphereMesh.new()
	sphere.radius = CLOUD_RADIUS
	sphere.height = CLOUD_RADIUS * 2.0
	sphere.radial_segments = 8
	sphere.rings = 6

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = sphere
	mm.instance_count = CLOUD_COUNT

	var rng := RandomNumberGenerator.new()
	rng.seed = CLOUD_SEED
	var inner: float = jar_radius * 0.9 - CLOUD_RADIUS
	var y_lo: float = CLOUD_RADIUS * 2.0
	var y_hi: float = jar_height - CLOUD_RADIUS * 2.0
	for i in range(CLOUD_COUNT):
		var a: float = rng.randf() * TAU
		var rr: float = sqrt(rng.randf()) * inner   # sqrt = even fill, not a core clump
		var yy: float = rng.randf_range(y_lo, y_hi)
		mm.set_instance_transform(i,
			Transform3D(Basis.IDENTITY, Vector3(cos(a) * rr, yy, sin(a) * rr)))

	_cloud = MultiMeshInstance3D.new()
	_cloud.name = "SpecimenSuspension"
	_cloud.multimesh = mm
	_cloud.material_override = _specimen_material
	_add_tracked(_cloud)

func _create_jar_collision():
	# Cylinder collision to contain soft body
	var area = Area3D.new()
	area.name = "JarBoundary"
	
	# Bottom
	var bottom = StaticBody3D.new()
	var bottom_shape = CollisionShape3D.new()
	var bottom_box = BoxShape3D.new()
	bottom_box.size = Vector3(jar_radius * 2, 0.02, jar_radius * 2)
	bottom_shape.shape = bottom_box
	bottom.add_child(bottom_shape)
	bottom.position = Vector3(0, 0.01, 0)
	_add_tracked(bottom)

## TEXT — two bare Label3Ds promoted onto one museum plate.
##
## WAS: InfoLabel hanging at (0, 0.52, 0), a live λ/φ readout floating in air
## over the lid with nothing behind it; and StateLabel at (0, -0.15, 0.23) —
## 0.15 m BELOW the ground plane and 0.045 m under the bottom of the pedestal,
## occluded by the floor in every placement it has ever stood in. Both sat at
## Godot's billboard default (DISABLED), so LabelFramer skipped both: neither was
## ever given a body, and the state description has never been read by anybody.
## Neither would have covered geometry if it HAD been framed — the fix here is
## legibility and burial, not occlusion.
##
## NOW: one TextScreen (SCREEN mode, PLATE_WIDTH wide → a 0.336 x 0.222 m board
## spanning y 0.519–0.741) standing clear above the lid at (0, PLATE_Y, -0.01),
## facing +Z toward the approach side and the control rack at (0, 0.05, 0.35).
## The board is entirely above the 0.43 m lid, so it never enters the viewing
## corridor between a front-on camera and the specimen.
##
## Both Label3D nodes SURVIVE, reparented under the plate — _update_state_label
## still writes to them, any external reader still reads them, and the framer
## still skips them.
func _create_labels():
	_text_screen = TextScreenScript.new()
	_text_screen.name = "SpecimenPlate"
	_text_screen.mode = 0                    # TextScreen.Mode.SCREEN
	_text_screen.width_m = PLATE_WIDTH
	_text_screen.position = Vector3(0, PLATE_Y, -0.01)
	_add_tracked(_text_screen)

	# Title
	_info_label = Label3D.new()
	_info_label.name = "InfoLabel"
	_info_label.pixel_size = 0.002
	_info_label.font_size = 20
	_info_label.text = "QUEER MORPHOLOGY\nSPECIMEN"
	_retire_glyphs(_info_label)
	_text_screen.add_child(_info_label)

	# State description (changes with parameters)
	_state_label = Label3D.new()
	_state_label.name = "StateLabel"
	_state_label.pixel_size = 0.0015
	_state_label.font_size = 16
	_state_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_retire_glyphs(_state_label)
	_text_screen.add_child(_state_label)


## The label keeps its .text — the plate reads from it, and so can anything else.
## Only its glyphs stop drawing. Billboard stays DISABLED so LabelFramer treats it
## as already integrated and never bolts a second, competing panel behind it.
func _retire_glyphs(label: Label3D) -> void:
	label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	label.visible = false
	label.scale = Vector3(0.001, 0.001, 0.001)

func _create_vr_controls():
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	_control_panel = RackTpl.create_panel("MORPHOLOGY", [
		[
			{"type": "slider_h", "label": "LAMBDA", "default": lambda},
			{"type": "slider_h", "label": "PHI", "default": (phi + 1.0) / 2.0},
		],
		[
			{"type": "button", "label": "CRYST"},
			{"type": "button", "label": "EDGE"},
			{"type": "button", "label": "FLUID"},
		],
	])
	_control_panel.position = Vector3(0, 0.05, jar_radius + 0.2)
	_control_panel.rotation_degrees = Vector3(-25, 0, 0)
	_add_tracked(_control_panel)

	_lambda_slider = _control_panel.find_child("Param_0", true, false)
	if _lambda_slider and _lambda_slider.has_signal("slider_moved"):
		_lambda_slider.slider_moved.connect(_on_lambda_slider_moved)

	_phi_slider = _control_panel.find_child("Param_1", true, false)
	if _phi_slider and _phi_slider.has_signal("slider_moved"):
		_phi_slider.slider_moved.connect(_on_phi_slider_moved)

	var preset_data := [[0.1, -0.8], [0.5, 0.0], [0.8, 0.6]]
	for i in range(preset_data.size()):
		var btn: Node = _control_panel.find_child("Btn_%d" % i, true, false)
		if btn:
			var l: float = preset_data[i][0]
			var p: float = preset_data[i][1]
			var area: Node = btn.get_node_or_null("InteractableAreaButton")
			if area:
				area.button_pressed.connect(func(_b): _apply_preset(l, p))

	call_deferred("_sync_sliders_deferred")

func _sync_sliders_deferred():
	_sync_lambda_slider()
	_sync_phi_slider()

func _sync_lambda_slider():
	if _lambda_slider and _lambda_slider.has_method("set_normalized_value"):
		_lambda_slider.set_normalized_value(lambda)

func _sync_phi_slider():
	if _phi_slider and _phi_slider.has_method("set_normalized_value"):
		_phi_slider.set_normalized_value((phi + 1.0) / 2.0)

func _on_lambda_slider_moved(_position):
	if _lambda_slider and _lambda_slider.has_method("get_normalized_value"):
		lambda = _lambda_slider.get_normalized_value()

func _on_phi_slider_moved(_position):
	if _phi_slider and _phi_slider.has_method("get_normalized_value"):
		var norm = _phi_slider.get_normalized_value()
		phi = norm * 2.0 - 1.0

func _apply_preset(l: float, p: float):
	lambda = l
	phi = p

func _apply_lambda():
	# Guarded per-target rather than with a single early return: under
	# `clouded` there is no soft body, but the suspension still carries the
	# specimen material and the plate still has to update.
	if _soft_body:
		# Low lambda: rigid, crystalline structure
		# High lambda: fluid, chaotic, near phase transition

		# Stiffness: high when ordered, low when chaotic
		_soft_body.linear_stiffness = lerpf(0.9, 0.1, lambda)

		# Pressure: increases at edge, specimen "breathes"
		var edge_boost = 1.0 - abs(lambda - 0.5) * 2.0  # Peaks at 0.5
		_soft_body.pressure_coefficient = base_pressure * (1.0 + edge_boost * 0.5)

	# Update fluid shader
	if _fluid_material:
		_fluid_material.set_shader_parameter("lambda", lambda)
	
	# Color shift: blue/cold when ordered, warm when chaotic
	if _specimen_material:
		var hue_shift = lambda * 0.15  # Shift toward warm
		var color = specimen_color
		color.h = fmod(color.h + hue_shift, 1.0)
		color.s = lerpf(0.3, 0.8, lambda)
		_specimen_material.albedo_color = color
		_specimen_material.emission = color
		_specimen_material.emission_enabled = _emissive
		_specimen_material.emission_energy_multiplier = lerpf(0.1, 0.4, lambda) if _emissive else 0.0

	_update_state_label()

func _apply_phi():
	if _soft_body:
		# Negative phi: resists change, high damping
		# Positive phi: embraces transformation, low damping

		# Damping: high when resisting, low when flowing
		_soft_body.damping_coefficient = lerpf(0.2, 0.001, (phi + 1.0) / 2.0)

		# Drag: resisting = more drag
		_soft_body.drag_coefficient = lerpf(0.3, 0.0, (phi + 1.0) / 2.0)

	# Update fluid shader
	if _fluid_material:
		_fluid_material.set_shader_parameter("phi", phi)

	# Subsurface scatter: more when becoming
	if _specimen_material:
		if becoming == "escaped":
			# Out of the jar and at full scatter — the light goes through it.
			_specimen_material.subsurf_scatter_strength = 1.0
		else:
			_specimen_material.subsurf_scatter_strength = lerpf(0.2, 0.8, (phi + 1.0) / 2.0)

	_update_state_label()

func _update_state_label():
	var state: String

	if lambda < 0.2:
		state = "crystalline" if phi < 0 else "stable"
	elif lambda < 0.4:
		state = "stable"
	elif lambda < 0.6:
		state = "edge"
	elif lambda < 0.8:
		state = "fluid"
	else:
		state = "dissolving" if phi > 0 else "fluid"
	
	var body: String = STATES.get(state, "")
	var head: String = "QUEER MORPHOLOGY  λ=%.2f φ=%+.2f" % [lambda, phi]

	# The retired labels stay the text SOURCE — same assignments as before, so
	# anything reading .text off this artifact keeps working.
	if _state_label:
		_state_label.text = body
	if _info_label:
		# Also update title with current values
		_info_label.text = "QUEER MORPHOLOGY\nλ=%.2f φ=%+.2f" % [lambda, phi]

	# ...and both land on the one plate that is actually readable.
	if is_instance_valid(_text_screen) and _text_screen.has_method("set_text"):
		_text_screen.set_text(head, body)

func _process(_delta):
	# Gentle oscillation to keep specimen alive
	if _soft_body and is_inside_tree():
		# Breathing motion influenced by lambda
		var breathe_speed = lerpf(0.5, 2.0, lambda)
		var breathe_amp = lerpf(0.02, 0.1, lambda)
		var breathe = sin(Time.get_ticks_msec() * 0.001 * breathe_speed) * breathe_amp
		
		# Apply subtle force (only when at edge of chaos)
		if lambda > 0.3 and lambda < 0.7:
			_soft_body.pressure_coefficient = base_pressure * (1.0 + breathe)

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_LEFT:
				lambda = maxf(0, lambda - 0.05)
			KEY_RIGHT:
				lambda = minf(1, lambda + 0.05)
			KEY_DOWN:
				phi = maxf(-1, phi - 0.1)
			KEY_UP:
				phi = minf(1, phi + 0.1)
			KEY_1:
				_apply_preset(0.1, -0.8)  # Crystalline
			KEY_2:
				_apply_preset(0.5, 0.0)   # Edge
			KEY_3:
				_apply_preset(0.8, 0.6)   # Fluid

## External API
func set_lambda(value: float):
	lambda = value

func set_phi(value: float):
	phi = value

func get_state() -> String:
	if lambda < 0.3:
		return "ordered"
	elif lambda < 0.7:
		return "edge"
	else:
		return "chaotic"

# ═══════════════════════════════════════════════════════════════════
# GRID CONFIG INTEGRATION
# ═══════════════════════════════════════════════════════════════════

## Reached by GridInteractablesComponent via call_deferred, AFTER _ready() and
## FIRST in the deferred queue — ahead of label framing and auto-grounding. So a
## rebuild here has to be synchronous (a deferred one would leave grounding to
## measure a zero AABB and bail) and must free only what this script built.
##
## curation_station.gd calls this with {"emissive": false} one line after framing
## labels and making the instance inert. An unconditional rebuild there would
## discard that work, so geometry is rebuilt ONLY when a geometry key actually
## changed — and `emissive`, which changes no geometry, is applied IN PLACE
## before every early return rather than silently accepted and dropped.
func apply_grid_config(config_data: Dictionary):
	var before_becoming: String = becoming
	var before_height: float = jar_height
	var before_radius: float = jar_radius

	# The legacy blind copy, kept: λ, φ, colours and turbulence all apply in
	# place through their own setters. `becoming` is excluded and resolved
	# through the allow-list below instead.
	for key in config_data:
		if key == "becoming":
			continue
		if key in self:
			set(key, config_data[key])

	# Stage-2 DNA axis — #becoming:escaped
	if config_data.has("becoming"):
		becoming = _pick_axis(str(config_data["becoming"]), BECOMINGS, becoming)

	if config_data.has("emissive"):
		var raw = config_data["emissive"]
		if raw is String:
			_emissive = not (str(raw).to_lower().strip_edges() in ["false", "0", "off", "no"])
		else:
			_emissive = bool(raw)
		_apply_emissive()

	if not _built:
		return
	if becoming == before_becoming \
			and is_equal_approx(jar_height, before_height) \
			and is_equal_approx(jar_radius, before_radius):
		return

	_rebuild_now()
	print("[QueerMorphologySpecimen] Config applied — becoming=%s" % [becoming])


## Accept an axis value only if it names something we actually build. A typo in a
## map token falls back to the shipped look rather than half-building a vitrine.
func _pick_axis(raw: String, allowed: PackedStringArray, fallback: String) -> String:
	var v: String = raw.to_lower().strip_edges()
	return v if allowed.has(v) else fallback


## `emissive` applied in place — no rebuild, so the framing and grounding the
## grid applied moments earlier survive.
func _apply_emissive() -> void:
	if not _specimen_material:
		return
	_specimen_material.emission_enabled = _emissive
	_specimen_material.emission_energy_multiplier = lerpf(0.1, 0.4, lambda) if _emissive else 0.0


## Synchronous rebuild. Frees ONLY the nodes this script added as direct
## children — get_children() would take the grid's own plates, framing and
## grounding with it.
func _rebuild_now() -> void:
	for c in _created:
		if is_instance_valid(c):
			remove_child(c)
			c.queue_free()
	_created.clear()

	_jar_mesh = null
	_fluid_mesh = null
	_fluid_material = null
	_soft_body = null
	_cloud = null
	_specimen_material = null
	_info_label = null
	_state_label = null
	_text_screen = null
	_lambda_slider = null
	_phi_slider = null
	_control_panel = null

	_build_all()
