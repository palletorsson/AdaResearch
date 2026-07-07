extends Node3D
class_name StreetSign

# @identity
# essence: a regulatory STREET SIGN — an octagonal STOP plate held aloft on a tall galvanized pole that stands on a small square foot plate bolted to the ground. Saturated red face with a white rim, "STOP" stencilled across it in white, a second smaller line beneath. The sign is the lab's confession that space is GOVERNED: that movement through a place is not free, that someone, somewhere, decided where you must halt. It is the street brought indoors — the bureaucracy of traffic standing in a room that has no traffic.
# desire: every road wants one unmistakable shape that means STOP before a single letter is read. The octagon is that shape — legible from behind, in fog, in the dark, when the paint has flaked off and only the silhouette remains. The sign wants to be obeyed before it is understood. Recognition first; reading second. It wants to be the one object in the room that has AUTHORITY over your feet.
# critical_parameter: sign_text + sign_sides + sign_color — together they decide WHICH sign this is. 8 sides + red + "STOP" = the octagonal command to halt. 4 sides + yellow + "SLOW" = a diamond warning. 3 sides + red border = a yield triangle. 32 sides ≈ a circle = a speed or prohibition disc. pole_height decides WHO it speaks to — eye-level (≈2.2m to the face) speaks to a person on foot; overhead speaks to a vehicle.
# triggers: _ready() builds base plate + corner bolts + pole + white octagon border + red octagon face + STOP Label3D + subtext from exports; apply_grid_config rebuilds when DNA changes.
# emerges: a single STOP sign in a sterile lab reads as RULE INTRUDING — the room has been zoned, claimed by an outside ordinance. A row of them reads as a JUNCTION, an intersection of paths. Change sign_sides and sign_color and the same pole grows a different law: warn, yield, prohibit. The sign is a small monument to the fact that every space is regulated by a logic written somewhere else.
# needs: tall galvanized pole [present]; square foot plate on the ground [present]; corner bolts [present]; octagonal white border plate [present]; smaller red octagonal face [present]; "STOP" Label3D on the face [present]; subtext line beneath [present]
# relationships: peer to exit_sign (both = wall/pole-mounted public instruction, one halts the feet, one guides them out); sibling to fire_extinguisher (both = saturated-red recognition-before-reading street/safety vocabulary); cousin to crate (both = the world-outside-the-lab brought in — the crate is the supply chain, the sign is the traffic code).
# truth: a STOP sign is the architectural form of an ORDER. By placing it, the space confesses it is not neutral ground — it is administered, divided into where-you-may-go and where-you-must-halt. The octagon is the rare shape reserved for a single word, so that even illiterate, even from behind, even ruined, it still commands. To put one in a lab is to say: this floor, too, has a law.

## A regulatory street sign — octagonal STOP plate on a tall pole.
##
## Built procedurally from DNA exports. Origin is at the BOTTOM CENTRE of
## the base plate, on the floor (the foot plate sits on the ground). The
## sign FACE points +Z (the sign reads from the +Z side). Default is the
## canonical red octagonal STOP at roughly eye height (~2.2m pole).
##
## Because the plate is a CylinderMesh with sign_sides segments, the same
## artifact makes other signs: 8 = octagon STOP, 4 = diamond warning,
## 3 = yield triangle, 32 ≈ a circular prohibition disc.

# ── DNA ───────────────────────────────────────────────────────────────

@export_group("Dimensions")
@export var pole_height: float = 2.2
@export var pole_radius: float = 0.03
@export var sign_radius: float = 0.28
## Number of sides on the sign plate. 8 = octagon (STOP), 4 = diamond
## (warning), 3 = triangle (yield), 32 ≈ circle (prohibition disc).
@export var sign_sides: int = 8

@export_group("Color")
@export var sign_color: Color = Color(0.82, 0.14, 0.14)          # red face
@export var border_color: Color = Color(0.95, 0.95, 0.95)        # white rim
@export var text_color: Color = Color(0.98, 0.98, 0.98)          # white text
@export var pole_color: Color = Color(0.62, 0.64, 0.66)          # galvanized gray

@export_group("Text")
## Primary command — short, all caps reads best.
@export var sign_text: String = "STOP"
## Secondary line beneath (e.g. the Chinese stop character).
@export var subtext: String = "STOP"

# ── State ─────────────────────────────────────────────────────────────

var _built: bool = false


func _ready() -> void:
	_read_metadata_overrides()
	_build()


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()
	if _built:
		for c in get_children():
			remove_child(c)
			c.queue_free()
		_built = false
		_build()


func _read_metadata_overrides() -> void:
	if has_meta("config_pole_height"):
		pole_height = float(str(get_meta("config_pole_height")))
	if has_meta("config_pole_radius"):
		pole_radius = float(str(get_meta("config_pole_radius")))
	if has_meta("config_sign_radius"):
		sign_radius = float(str(get_meta("config_sign_radius")))
	if has_meta("config_sign_sides"):
		sign_sides = int(str(get_meta("config_sign_sides")))
	if has_meta("config_sign_color"):
		sign_color = _parse_color(str(get_meta("config_sign_color")), sign_color)
	if has_meta("config_border_color"):
		border_color = _parse_color(str(get_meta("config_border_color")), border_color)
	if has_meta("config_text_color"):
		text_color = _parse_color(str(get_meta("config_text_color")), text_color)
	if has_meta("config_pole_color"):
		pole_color = _parse_color(str(get_meta("config_pole_color")), pole_color)
	if has_meta("config_sign_text"):
		sign_text = str(get_meta("config_sign_text"))
	if has_meta("config_subtext"):
		subtext = str(get_meta("config_subtext"))


func _parse_color(raw: String, fallback: Color) -> Color:
	var parts := raw.split(",")
	if parts.size() >= 3:
		return Color(float(parts[0]), float(parts[1]), float(parts[2]),
			float(parts[3]) if parts.size() > 3 else 1.0)
	return fallback


# ── Build ─────────────────────────────────────────────────────────────

func _build() -> void:
	_built = true

	var sides: int = maxi(3, sign_sides)
	# Centre height of the sign plate — near the top of the pole.
	var sign_y: float = pole_height - sign_radius * 0.7

	_build_base_plate()
	_build_pole()
	# White octagonal border plate.
	_build_sign_plate("SignBorder", sign_radius, sides,
		border_color, sign_y, 0.0)
	# Smaller red face mounted just IN FRONT (+Z) so the white reads as a rim.
	var plate_thickness := 0.02
	_build_sign_plate("SignFace", sign_radius * 0.86, sides,
		sign_color, sign_y, plate_thickness * 0.6)
	# Text on the +Z face of the red plate.
	_build_labels(sign_y, plate_thickness)


func _build_base_plate() -> void:
	# A small square flat box on the ground — galvanized gray.
	var plate := MeshInstance3D.new()
	plate.name = "BasePlate"
	var bm := BoxMesh.new()
	var plate_w := 0.14
	var plate_h := 0.02
	bm.size = Vector3(plate_w, plate_h, plate_w)
	plate.mesh = bm
	plate.material_override = _make_metal_mat(pole_color)
	plate.position = Vector3(0.0, plate_h * 0.5, 0.0)
	add_child(plate)

	# Four tiny bolt cylinders at the corners.
	var bolt_inset := plate_w * 0.5 - 0.022
	var bolt_y := plate_h + 0.006
	var bolt_mat := _make_metal_mat(Color(0.40, 0.41, 0.43))
	var offsets := [
		Vector3(bolt_inset, bolt_y, bolt_inset),
		Vector3(-bolt_inset, bolt_y, bolt_inset),
		Vector3(bolt_inset, bolt_y, -bolt_inset),
		Vector3(-bolt_inset, bolt_y, -bolt_inset),
	]
	for i in range(offsets.size()):
		var bolt := MeshInstance3D.new()
		bolt.name = "Bolt%d" % i
		var cm := CylinderMesh.new()
		cm.top_radius = 0.008
		cm.bottom_radius = 0.009
		cm.height = 0.012
		cm.radial_segments = 6
		bolt.mesh = cm
		bolt.material_override = bolt_mat
		bolt.position = offsets[i]
		add_child(bolt)


func _build_pole() -> void:
	# Tall thin vertical cylinder, bottom resting on the base plate.
	var pole := MeshInstance3D.new()
	pole.name = "Pole"
	var cm := CylinderMesh.new()
	cm.top_radius = pole_radius
	cm.bottom_radius = pole_radius
	cm.height = pole_height
	cm.radial_segments = 12
	pole.mesh = cm
	pole.material_override = _make_metal_mat(pole_color)
	pole.position = Vector3(0.0, pole_height * 0.5, 0.0)
	add_child(pole)


# Build one flat polygonal sign plate as a thin CylinderMesh prism whose
# FACE points +Z. radial_segments = sides gives the polygon (8 = octagon).
# z_extra pushes the plate forward of the pole/border along +Z.
func _build_sign_plate(plate_name: String, radius: float, sides: int,
		color: Color, center_y: float, z_extra: float) -> void:
	var plate := MeshInstance3D.new()
	plate.name = plate_name
	var cm := CylinderMesh.new()
	cm.top_radius = radius
	cm.bottom_radius = radius
	cm.height = 0.02
	cm.radial_segments = sides
	plate.mesh = cm
	plate.material_override = _make_sign_mat(color)
	# CylinderMesh axis is local +Y. Rotate +90° about X so the face
	# points +Z. Then spin about that facing axis (now local Y, world Z)
	# by half a segment so an 8-gon has flat TOP and BOTTOM edges — a
	# regular STOP octagon orientation. For odd counts (triangle) this
	# also lands a flat edge at the bottom point-up.
	var spin: float = PI / float(sides)
	plate.rotation = Vector3(deg_to_rad(90.0), 0.0, 0.0)
	# Apply the in-plane spin about the (now) facing axis. After the
	# +90° X rotation the local Y axis points along world +Z, so spin
	# is the plate's Z-rotation in its own frame — set via rotate_object_local.
	plate.rotate_object_local(Vector3(0, 1, 0), spin)
	# A plate rotated to face +Z is centred on the pole; nudge forward by
	# z_extra and clear of the pole's front surface.
	plate.position = Vector3(0.0, center_y, pole_radius + 0.012 + z_extra)
	add_child(plate)


func _build_labels(center_y: float, plate_thickness: float) -> void:
	# Front (+Z) surface of the red face, a hair proud of the plate.
	var face_z: float = pole_radius + 0.012 + plate_thickness * 0.6 + 0.012

	if sign_text.strip_edges().length() > 0:
		var lbl := Label3D.new()
		lbl.name = "SignText"
		lbl.text = sign_text
		lbl.font_size = 64
		lbl.outline_size = 0
		lbl.pixel_size = sign_radius * 0.0085
		lbl.modulate = text_color
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.billboard = BaseMaterial3D.BILLBOARD_DISABLED
		lbl.no_depth_test = false
		lbl.position = Vector3(0.0, center_y + sign_radius * 0.12, face_z)
		add_child(lbl)

	if subtext.strip_edges().length() > 0:
		var sub := Label3D.new()
		sub.name = "SubText"
		sub.text = subtext
		sub.font_size = 40
		sub.outline_size = 0
		sub.pixel_size = sign_radius * 0.0050
		sub.modulate = text_color
		sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sub.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		sub.billboard = BaseMaterial3D.BILLBOARD_DISABLED
		sub.no_depth_test = false
		sub.position = Vector3(0.0, center_y - sign_radius * 0.34, face_z)
		add_child(sub)


# ── Helpers ───────────────────────────────────────────────────────────

func _make_metal_mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.5
	m.metallic = 0.5
	return m


func _make_sign_mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.4
	m.metallic = 0.1
	return m
