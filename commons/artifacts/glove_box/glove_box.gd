extends Node3D
class_name GloveBox

# @identity
# essence: a sealed handling chamber on four legs — Aperture / chemistry-lab vocabulary for "this work cannot be touched directly". A glossy white BoxMesh enclosure with a translucent glass top, an interior emissive ceiling plate, 1-3 black rubber glove ports on the front face (each port a small dark cylinder ringed by a TorusMesh cuff), a Portal-orange accent stripe across the front-top, and optional leg pillars. The architectural form of MEDIATED CONTACT.
# desire: the glove box wants to be the room's INSIDE-OUTSIDE — a contained atmosphere the experimenter reaches INTO without ENTERING. It wants the hands to be present but the bodies to be absent. The interior glow is the lab's confession that something LIVES in there.
# critical_parameter: glove_count — 1 reads as "single-operator, focused, surgical"; 2 reads as "standard two-handed work"; 3 reads as "collaborative, multi-person handling, or specimen-passing". Same enclosure, completely different work ritual.
# triggers: _ready() builds body + glass top + interior light plate + glove ports (cyl + torus cuff per port) + accent stripe + optional legs from exports; apply_grid_config rebuilds
# emerges: legs_visible=true + interior_light=true = "active handling station"; legs_visible=false = "bench-mounted, integrated into a counter"; interior_light=false = "decommissioned, dark, empty"; glove_count=3 = "team chamber, communal experiment"
# needs: glossy white BoxMesh body [present]; translucent glass top panel [present]; emissive interior ceiling plate [present]; circular glove ports on +Z face [present]; TorusMesh cuff around each port [present]; Portal-orange accent stripe [present]; optional 4 vertical leg pillars [present]
# relationships: sibling to fume_hood (both ENCLOSE handling, but the fume hood is open-front while the glove box is sealed — pressure vs. permeability); cousin to specimen_jar (the glove box is the WORKSPACE, the jar is the OUTCOME — handling produces specimens); peer to large_table (the glove box SITS ON or REPLACES a table — both load-bearing for the work surface)
# truth: a glove box is not just a sealed cabinet. It is the lab's argument that AIR ITSELF can be EVIDENCE. Inside, the atmosphere is controlled — inert, dry, sterile. The gloves are the membrane between two atmospheres. The chamber teaches: some boundaries are gas, not glass.

## A sealed handling chamber with 1-3 glove ports on the front face.
##
## Built procedurally from DNA. Origin is at floor level (bottom of legs
## if visible, otherwise bottom of body). The body faces +Z; gloves are
## on the +Z face.

# ── DNA ───────────────────────────────────────────────────────────────

@export_group("Dimensions")
@export var box_width: float = 1.0
@export var box_height: float = 0.75
@export var box_depth: float = 0.55

@export_group("Color")
@export var body_color: Color = Color(0.94, 0.94, 0.95)
@export var glass_color: Color = Color(0.78, 0.85, 0.92, 0.40)
@export var frame_color: Color = Color(0.18, 0.18, 0.22)
@export var accent_color: Color = Color(1.0, 0.45, 0.10)
@export var glove_color: Color = Color(0.10, 0.10, 0.12)
@export var light_color: Color = Color(0.92, 0.96, 1.0)

@export_group("Gloves")
@export_range(1, 3, 1) var glove_count: int = 2
@export var glove_radius: float = 0.07

@export_group("Interior")
@export var interior_light: bool = true

@export_group("Legs")
@export var legs_visible: bool = true
@export var leg_height: float = 0.85

# ── Constants ─────────────────────────────────────────────────────────

const WALL_THICKNESS: float = 0.025
const GLASS_THICKNESS: float = 0.025
const LEG_THICKNESS: float = 0.06
const CUFF_INNER_FACTOR: float = 1.0    # relative to glove_radius
const CUFF_OUTER_FACTOR: float = 1.22
const PORT_DISC_DEPTH: float = 0.012
const ACCENT_STRIP_HEIGHT: float = 0.014
const ACCENT_STRIP_DEPTH: float = 0.005
const LIGHT_PLATE_INSET: float = 0.04
const LIGHT_PLATE_THICKNESS: float = 0.012

# ── Internal state ────────────────────────────────────────────────────

var _built: bool = false

# ── Lifecycle ─────────────────────────────────────────────────────────

func _ready() -> void:
	_read_metadata_overrides()
	_build_glove_box()


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()
	if _built:
		_clear_built_children()
		_built = false
		_build_glove_box()


func _read_metadata_overrides() -> void:
	if has_meta("config_box_width"):
		box_width = float(str(get_meta("config_box_width")))
	if has_meta("config_box_height"):
		box_height = float(str(get_meta("config_box_height")))
	if has_meta("config_box_depth"):
		box_depth = float(str(get_meta("config_box_depth")))
	if has_meta("config_body_color"):
		body_color = _parse_color(str(get_meta("config_body_color")), body_color)
	if has_meta("config_glass_color"):
		glass_color = _parse_color(str(get_meta("config_glass_color")), glass_color)
	if has_meta("config_frame_color"):
		frame_color = _parse_color(str(get_meta("config_frame_color")), frame_color)
	if has_meta("config_accent_color"):
		accent_color = _parse_color(str(get_meta("config_accent_color")), accent_color)
	if has_meta("config_glove_color"):
		glove_color = _parse_color(str(get_meta("config_glove_color")), glove_color)
	if has_meta("config_light_color"):
		light_color = _parse_color(str(get_meta("config_light_color")), light_color)
	if has_meta("config_glove_count"):
		glove_count = int(str(get_meta("config_glove_count")))
	if has_meta("config_glove_radius"):
		glove_radius = float(str(get_meta("config_glove_radius")))
	if has_meta("config_interior_light"):
		var vl := str(get_meta("config_interior_light")).to_lower()
		interior_light = vl in ["true", "1", "yes", "on"]
	if has_meta("config_legs_visible"):
		var vleg := str(get_meta("config_legs_visible")).to_lower()
		legs_visible = vleg in ["true", "1", "yes", "on"]
	if has_meta("config_leg_height"):
		leg_height = float(str(get_meta("config_leg_height")))


func _clear_built_children() -> void:
	for c in get_children():
		c.queue_free()


# ── Build ─────────────────────────────────────────────────────────────

func _build_glove_box() -> void:
	_built = true
	# Body bottom_y is leg_height when legs visible, else 0.
	var body_bottom_y: float = leg_height if legs_visible else 0.0

	if legs_visible:
		_build_legs(body_bottom_y)

	_build_body(body_bottom_y)
	_build_glass_top(body_bottom_y)
	if interior_light:
		_build_interior_light(body_bottom_y)
	_build_glove_ports(body_bottom_y)
	_build_accent_strip(body_bottom_y)


func _build_legs(body_bottom_y: float) -> void:
	var root := Node3D.new()
	root.name = "Legs"
	add_child(root)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = frame_color
	mat.roughness = 0.4
	mat.metallic = 0.7

	var x_inset: float = LEG_THICKNESS * 0.5 + 0.04
	var z_inset: float = LEG_THICKNESS * 0.5 + 0.04
	var corners := [
		Vector3(box_width * 0.5 - x_inset, 0.0, box_depth * 0.5 - z_inset),
		Vector3(-box_width * 0.5 + x_inset, 0.0, box_depth * 0.5 - z_inset),
		Vector3(box_width * 0.5 - x_inset, 0.0, -box_depth * 0.5 + z_inset),
		Vector3(-box_width * 0.5 + x_inset, 0.0, -box_depth * 0.5 + z_inset),
	]
	for i in range(corners.size()):
		var leg := MeshInstance3D.new()
		leg.name = "Leg_%d" % i
		var lm := BoxMesh.new()
		lm.size = Vector3(LEG_THICKNESS, body_bottom_y, LEG_THICKNESS)
		leg.mesh = lm
		leg.material_override = mat
		var c: Vector3 = corners[i]
		leg.position = Vector3(c.x, body_bottom_y * 0.5, c.z)
		root.add_child(leg)


func _build_body(body_bottom_y: float) -> void:
	# Single white BoxMesh as the enclosure. Glove ports cut visually with
	# dark disc decals, not real CSG holes — keeps geometry simple.
	var body := MeshInstance3D.new()
	body.name = "Body"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(box_width, box_height, box_depth)
	body.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = body_color
	mat.roughness = 0.3
	mat.metallic = 0.15
	body.material_override = mat
	body.position = Vector3(0.0, body_bottom_y + box_height * 0.5, 0.0)
	add_child(body)


func _build_glass_top(body_bottom_y: float) -> void:
	# Translucent glass panel inset slightly into the top face.
	var glass := MeshInstance3D.new()
	glass.name = "GlassTop"
	var w: float = box_width - 0.08
	var d: float = box_depth - 0.08
	var mesh := BoxMesh.new()
	mesh.size = Vector3(w, GLASS_THICKNESS, d)
	glass.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = glass_color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness = 0.05
	mat.metallic = 0.1
	mat.refraction_enabled = false
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	glass.material_override = mat
	# Sits flush with the body top (slightly above).
	var top_y: float = body_bottom_y + box_height + GLASS_THICKNESS * 0.5
	glass.position = Vector3(0.0, top_y, 0.0)
	add_child(glass)


func _build_interior_light(body_bottom_y: float) -> void:
	# Emissive box just under the inside of the top face.
	var plate := MeshInstance3D.new()
	plate.name = "InteriorLight"
	var w: float = box_width - LIGHT_PLATE_INSET * 2.0
	var d: float = box_depth - LIGHT_PLATE_INSET * 2.0
	var mesh := BoxMesh.new()
	mesh.size = Vector3(w, LIGHT_PLATE_THICKNESS, d)
	plate.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = light_color
	mat.emission_enabled = true
	mat.emission = light_color
	mat.emission_energy_multiplier = 2.0
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	plate.material_override = mat
	plate.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Just below the interior ceiling.
	var y: float = body_bottom_y + box_height - WALL_THICKNESS - LIGHT_PLATE_THICKNESS * 0.5 - 0.005
	plate.position = Vector3(0.0, y, 0.0)
	add_child(plate)


func _build_glove_ports(body_bottom_y: float) -> void:
	# 1-3 glove ports on the +Z face. Distribute them evenly across the
	# width at ~45% height of the body.
	var count: int = clamp(glove_count, 1, 3)
	var root := Node3D.new()
	root.name = "GlovePorts"
	add_child(root)

	var port_mat := StandardMaterial3D.new()
	port_mat.albedo_color = glove_color
	port_mat.roughness = 0.85
	port_mat.metallic = 0.05

	var cuff_mat := StandardMaterial3D.new()
	cuff_mat.albedo_color = frame_color
	cuff_mat.roughness = 0.4
	cuff_mat.metallic = 0.55

	# Distribute X positions: 1 port = center; 2 = ±W*0.22; 3 = -W*0.30, 0, +W*0.30.
	var xs: Array = []
	match count:
		1:
			xs = [0.0]
		2:
			xs = [-box_width * 0.22, box_width * 0.22]
		3:
			xs = [-box_width * 0.30, 0.0, box_width * 0.30]
		_:
			xs = [0.0]

	var port_y: float = body_bottom_y + box_height * 0.45
	var port_z: float = box_depth * 0.5 + PORT_DISC_DEPTH * 0.5

	for i in range(xs.size()):
		var xv: float = float(xs[i])
		# Black disc (the glove opening).
		var disc := MeshInstance3D.new()
		disc.name = "Port_%d_Disc" % i
		var dm := CylinderMesh.new()
		dm.top_radius = glove_radius
		dm.bottom_radius = glove_radius
		dm.height = PORT_DISC_DEPTH
		disc.mesh = dm
		disc.material_override = port_mat
		# Lay along +Z (face the front).
		disc.rotation = Vector3(deg_to_rad(90.0), 0.0, 0.0)
		disc.position = Vector3(xv, port_y, port_z)
		root.add_child(disc)

		# Cuff (TorusMesh ring) around the disc.
		var cuff := MeshInstance3D.new()
		cuff.name = "Port_%d_Cuff" % i
		var tm := TorusMesh.new()
		tm.inner_radius = glove_radius * CUFF_INNER_FACTOR
		tm.outer_radius = glove_radius * CUFF_OUTER_FACTOR
		cuff.mesh = tm
		cuff.material_override = cuff_mat
		# TorusMesh axis default = Y; rotate to align ring around the Z axis.
		cuff.rotation = Vector3(deg_to_rad(90.0), 0.0, 0.0)
		cuff.position = Vector3(xv, port_y, box_depth * 0.5 + 0.001)
		root.add_child(cuff)


func _build_accent_strip(body_bottom_y: float) -> void:
	# Across the front-top of the body.
	var strip := MeshInstance3D.new()
	strip.name = "AccentStrip"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(box_width * 0.92, ACCENT_STRIP_HEIGHT, ACCENT_STRIP_DEPTH)
	strip.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = accent_color
	mat.emission_enabled = true
	mat.emission = accent_color
	mat.emission_energy_multiplier = 1.6
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	strip.material_override = mat
	strip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Just below the top of the body, on the +Z face.
	var y: float = body_bottom_y + box_height - 0.04
	var z: float = box_depth * 0.5 + ACCENT_STRIP_DEPTH * 0.5
	strip.position = Vector3(0.0, y, z)
	add_child(strip)


# ── Helpers ───────────────────────────────────────────────────────────

func _parse_color(s: String, fallback: Color) -> Color:
	var parts := s.split(",")
	if parts.size() < 3:
		return fallback
	var r := float(parts[0])
	var g := float(parts[1])
	var b := float(parts[2])
	var a := 1.0
	if parts.size() >= 4:
		a = float(parts[3])
	return Color(r, g, b, a)
