extends Node3D
class_name Origin

# @identity
# essence: (0, 0, 0) — the reference from which all coordinates are measured, made visible as a black sphere glowing pink at the centre of a wireframe cube
# desire: learner viscerally locates themselves relative to the world's fixed anchor — understanding that "zero" is a name we agreed on
# critical_parameter: marker_size (how much of the cube the zero claims) and glow_color — the sphere is BLACK and the light around it is the only thing that is not
# triggers: none — the origin does not perform. It is the one object in the room that is simply THERE, and the glow is what makes a black thing visible at all
# emerges: understanding that "zero" is a choice, not a given — every coordinate system has an origin and they could have agreed on a different one
# needs: black sphere + pink glow [present, 2026-09-04]; the wireframe cube from cube_lines, captions off [present, 2026-09-04]; class_name Origin [present, 2026-05-19]; apply_grid_config [present, 2026-05-19]; VR controls [missing — atmospheric/reference object only]
# relationships: prerequisite for all spatial reasoning; the start-point of every CoordinateLine axis; the shared zero that CoordinateSystem3M assumes; visually distinct from point.gd (origin = THE origin, point = a movable position); paired with origin_test.tscn for the multi-origin demo
# truth: the origin is a convention, not a place — but every space must agree on one. A black sphere is the least a thing can look like and still be somewhere; the cube around it is the agreement, and it no longer needs to say its own length twelve times to be believed.

## AXIOM 0: The origin (0, 0, 0) is the reference point
## from which all positions are measured.

## The body and the light, shared with CoordinateSystem3M's floating point.
const DEFAULT_BODY := Color(0.035, 0.03, 0.04)
const DEFAULT_GLOW := Color(1.0, 0.22, 0.62)
const GLOW_STEPS: Array[Dictionary] = [
	{"r": 1.22, "a": 0.20},
	{"r": 1.55, "a": 0.11},
	{"r": 1.95, "a": 0.055},
	{"r": 2.45, "a": 0.025},
]

## The zero used to cycle thirteen names for itself. The names were the
## argument — that "zero" is a word we agreed on — but thirteen captions
## on a 5 cm marker inside a captioned cube made the room shout. The
## unnamed black sphere makes the same point by refusing to be labelled.
const ALIAS_NOTE := "origin / home / zero / (0,0,0) / Vector3.ZERO"

## Radius of the marker sphere, in metres. The cube around it is 1 m, so this
## is how much of that volume the zero claims.
@export var marker_size: float = 0.07
## The body. Near-black rather than pure black so the sphere still takes a
## highlight and reads as a solid and not a hole.
@export var marker_color: Color = DEFAULT_BODY
## The light around it, and the tint of the cube and the beam. Everything
## luminous in this artifact is this one colour.
@export var glow_color: Color = DEFAULT_GLOW
## How loud the glow is. Scales the halo and the lamp together; 0 leaves a
## plain black sphere in a pink cube.
@export var glow_strength: float = 1.0
## Twelve edges captioned "Length: 1.00m" is one sentence twelve times.
@export var edge_labels: bool = false
## Kept because 47 maps and their #rotation_speed configs still name it. A
## sphere cannot show rotation, so nothing turns any more.
@export var rotation_speed: float = 0.5

## Vertical beam rising from the origin (metres). 0 = no beam (default, so
## other maps are unaffected). In Point One the origin sits below the lab
## floor; a beam carries the eye up through the floor window into the room.
@export var beam_height: float = 0.0
## Radius of the beam cylinder.
@export var beam_radius: float = 0.012
## Text shown at the TOP of the beam (where it enters the room). Empty = none.
@export var beam_label: String = "(0, 0, 0)"

# The origin - the center of our 3D universe
var origin = Vector3(0, 0, 0)
var _marker: MeshInstance3D
var _halo: MeshInstance3D

## THE ZERO'S LOOK, PUBLISHED. CoordinateSystem3M's floating point wears the same
## one (Palle, 2026-09-04: "make the point the same black fetch sphere"), so it
## lives here once instead of being copied there and drifting the first time
## either is tuned.
##
## Two calls, because the body and the light are separate problems: emission on a
## near-black albedo repaints the sphere its own emission colour, and the black is
## the point. The light is made of things that make light.
static func zero_body_material(body: Color = DEFAULT_BODY) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = body
	mat.metallic = 0.10
	mat.roughness = 0.25
	return mat


## Concentric additive shells, drawn from the INSIDE so they never cover the core.
## One shell is a disc; the falloff is what reads as light. Alpha carries the
## brightness and nothing emits — on an unshaded surface emission is added after
## alpha and flattens the whole stack back into a disc.
static func add_glow_shells(host: Node3D, radius: float,
		glow: Color = DEFAULT_GLOW, strength: float = 1.0,
		with_lamp: bool = true) -> void:
	if host == null or strength <= 0.0:
		return
	for idx in range(GLOW_STEPS.size()):
		var step: Dictionary = GLOW_STEPS[idx]
		var shell_node := MeshInstance3D.new()
		shell_node.name = "ZeroGlow%d" % (idx + 1)
		var shell := SphereMesh.new()
		shell.radius = radius * float(step["r"])
		shell.height = radius * float(step["r"]) * 2.0
		shell.radial_segments = 24
		shell.rings = 12
		shell_node.mesh = shell
		var hmat := StandardMaterial3D.new()
		hmat.albedo_color = Color(glow.r, glow.g, glow.b,
				float(step["a"]) * strength)
		hmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		hmat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		hmat.cull_mode = BaseMaterial3D.CULL_FRONT
		hmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		hmat.disable_receive_shadows = true
		shell_node.material_override = hmat
		shell_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		host.add_child(shell_node)
	if not with_lamp:
		return
	var lamp := OmniLight3D.new()
	lamp.name = "ZeroLamp"
	lamp.light_color = glow
	lamp.light_energy = 1.1 * strength
	lamp.omni_range = maxf(0.6, radius * 16.0)
	lamp.shadow_enabled = false
	host.add_child(lamp)


func _ready():
	create_origin_marker()
	_dress_cube()


## The wireframe cube is a child scene (cube_lines), and its twelve edges are
## line_static instances that caption themselves. A child's _ready runs first,
## so this is an override after the fact, not configuration before it.
func _dress_cube() -> void:
	var cube := get_node_or_null("CubeLines")
	if cube == null:
		return
	if "edge_labels" in cube:
		cube.edge_labels = edge_labels
	if "tint_override" in cube:
		cube.tint_override = glow_color
	if cube.has_method("setup_cube"):
		cube.setup_cube()


func create_origin_marker():
	"""A black sphere at (0,0,0) with a pink halo around it. Black so it is the
	least a thing can look like and still be somewhere; the halo so it is
	findable across a room, which a black sphere on its own is not."""
	_marker = MeshInstance3D.new()
	_marker.name = "OriginSphere"
	var sphere := SphereMesh.new()
	sphere.radius = marker_size
	sphere.height = marker_size * 2.0
	sphere.radial_segments = 32
	sphere.rings = 16
	_marker.mesh = sphere
	_marker.position = origin

	_marker.material_override = zero_body_material(marker_color)
	add_child(_marker)

	# the halo and the lamp, from the same pair the floating point uses
	add_glow_shells(self, marker_size, glow_color, glow_strength)
	_halo = get_node_or_null("ZeroGlow1")

	# Optional vertical beam rising from the origin (e.g. up through the lab
	# floor window into the room). Built here so apply_grid_config's rebuild
	# re-creates it.
	if beam_height > 0.0:
		_build_beam()


func _build_beam() -> void:
	# Emissive cylinder from the origin straight up beam_height metres.
	var beam := MeshInstance3D.new()
	beam.name = "OriginBeam"
	var cyl := CylinderMesh.new()
	cyl.top_radius = beam_radius
	cyl.bottom_radius = beam_radius
	cyl.height = beam_height
	cyl.radial_segments = 12
	beam.mesh = cyl
	var bmat := StandardMaterial3D.new()
	bmat.albedo_color = glow_color
	bmat.emission_enabled = true
	bmat.emission = glow_color
	bmat.emission_energy_multiplier = 1.6
	bmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bmat.albedo_color.a = 0.7
	beam.material_override = bmat
	# Cylinder origin is its centre, so lift it half its height to start at 0.
	beam.position = Vector3(0, beam_height * 0.5, 0)
	add_child(beam)

	# Label at the TOP of the beam (where it meets the room).
	if beam_label != "":
		var top_label := Label3D.new()
		top_label.name = "OriginBeamLabel"
		top_label.text = beam_label
		top_label.position = Vector3(0, beam_height + 0.12, 0)
		top_label.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		top_label.pixel_size = 0.0015
		top_label.font_size = 64
		top_label.outline_size = 8
		top_label.modulate = glow_color
		top_label.outline_modulate = Color(0, 0, 0, 0.8)
		top_label.no_depth_test = true
		add_child(top_label)

## Called by the grid system to apply per-cell configuration. Keys honoured:
##   "size" / "octahedron_size" / "marker_size" — float, sphere radius
##   "color" / "marker_color"    — Color or [r,g,b], the sphere's body
##   "glow" / "glow_color"       — Color or [r,g,b], halo, cube and beam
##   "glow_strength"             — float, how loud the halo and lamp are
##   "edge_labels"               — bool, put the cube's twelve captions back
##   "beam_height" / "beam_radius" / "beam_label"
## The old key names still work: 47 maps place this artifact and some of them
## configure it, so "size" and "color" cannot simply be renamed away.
func apply_grid_config(config_data: Dictionary) -> void:
	for k in ["size", "octahedron_size", "marker_size"]:
		if config_data.has(k):
			marker_size = float(config_data[k])
	for k in ["color", "marker_color"]:
		if config_data.has(k):
			marker_color = _as_color(config_data[k], marker_color)
	for k in ["glow", "glow_color"]:
		if config_data.has(k):
			glow_color = _as_color(config_data[k], glow_color)
	if config_data.has("glow_strength"):
		glow_strength = float(config_data["glow_strength"])
	if config_data.has("edge_labels"):
		edge_labels = bool(config_data["edge_labels"])
	if config_data.has("rotation_speed"):
		rotation_speed = float(config_data["rotation_speed"])
	if config_data.has("beam_height"):
		beam_height = float(config_data["beam_height"])
	if config_data.has("beam_radius"):
		beam_radius = float(config_data["beam_radius"])
	if config_data.has("beam_label"):
		beam_label = str(config_data["beam_label"])
	# Rebuild if already constructed
	if _marker:
		for c in get_children():
			if c is Timer or c.name == "CubeLines" or c.name == "CubeCollider":
				# everything else — sphere, shells, lamp, beam — is rebuilt below
				continue
			c.queue_free()
		_marker = null
		_halo = null
		create_origin_marker()
		_dress_cube()


func _as_color(v, fallback: Color) -> Color:
	if v is Color:
		return v
	if v is Array and v.size() >= 3:
		return Color(float(v[0]), float(v[1]), float(v[2]))
	if v is String and str(v) != "":
		return Color(str(v))
	return fallback
