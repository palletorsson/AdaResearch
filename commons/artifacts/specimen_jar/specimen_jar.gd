extends Node3D
class_name SpecimenJar

const BakedText := preload("res://commons/utils/baked_text_albedo.gd")

# @identity
# essence: a cylindrical glass containment vessel on a rectangular plinth — Aperture / Black Mesa specimen-room vocabulary. A translucent jar with a slight inner glow, a small dark cap, an interior content (blob / tendrils / crystal / empty), an emissive accent stripe wrapping the top of the plinth, and a small amber Label3D on the front face naming the specimen. Looks innocuous; reads as ominous
# desire: every lab wants a way to display its captives — what it has caught, isolated, contained. The jar wants to be the architectural form of HAVING-CAPTURED. Visible, but separated by glass. The viewer can look but not touch
# critical_parameter: content_shape — "blob" (organic mass), "tendrils" (radial filaments), "crystal" (geometric fragments), "empty" (the void of having released or never having captured) are four very different presences from the same script. The jar's shape is constant; the content is the punctum
# triggers: _ready() builds plinth + jar cylinder + cap + interior content + accent stripe + Label3D from exports; apply_grid_config rebuilds
# emerges: a blob jar reads ALIVE. A tendril jar reads ALIEN. A crystal jar reads MINERAL. An empty jar reads RECENTLY-OPENED. Same shape, four narratives. The specimen LABEL ('λ-S', 'Δ-Iπ') ties it into the QFEP curriculum without saying so
# needs: rectangular plinth at the bottom [present]; translucent cylindrical jar with slight emission [present]; small dark cap [present]; interior content per content_shape [present]; baked amber label panel on front face of plinth [present]; emissive accent at top of plinth [present]
# relationships: peer to microscope (jar = thing-being-looked-at; microscope = act-of-looking); sibling to small_containment (both are display vessels — jar = passive, containment = active); cousin to exit_sign + safety_shower (the lab's vocabulary of CONTROLLED THINGS); the QFEP's confession that some questions are kept behind glass
# truth: a specimen jar is the only artifact that EXPLICITLY contains something. A table holds (transparently). A door opens (transparently). A jar contains-and-displays — the glass admits the asymmetry of seeing without reaching. It is the architectural form of CURATED DISTANCE. The label says: this is named, this is bounded, this is mine

## A cylindrical specimen jar on a rectangular plinth.
##
## Built procedurally from DNA exports. Origin is at the bottom-center
## of the plinth, on the floor. Faces +Z (the label sits on the +Z face
## of the plinth). The jar's interior content is procedural and varies
## with content_shape: "blob", "tendrils", "crystal", or "empty".

# ── DNA ───────────────────────────────────────────────────────────────

@export_group("Dimensions")
@export_range(0.25, 1.5) var jar_height: float = 0.55
@export var jar_radius: float = 0.14
@export var plinth_height: float = 0.20
@export var plinth_width: float = 0.42

@export_group("Color")
## Faint blue-tinted translucent glass with alpha.
@export var glass_color: Color = Color(0.65, 0.78, 0.88, 0.35)
## Sickly emerald default for the contained matter.
@export var content_color: Color = Color(0.4, 0.85, 0.55, 0.85)
@export var cap_color: Color = Color(0.15, 0.15, 0.17)        # dark steel cap
@export var label_color: Color = Color(0.95, 0.65, 0.10)      # hazard amber

@export_group("Content")
## "blob" | "tendrils" | "crystal" | "empty"
@export var content_shape: String = "blob"
@export var label_text: String = "SPECIMEN λ-S/Δ"
@export_range(0.0, 2.0) var content_glow: float = 0.8

# ── Constants ─────────────────────────────────────────────────────────

const CAP_HEIGHT: float = 0.025
const CAP_RADIUS_FACTOR: float = 1.12   # slightly larger than jar
const ACCENT_STRIP_HEIGHT: float = 0.012
const ACCENT_STRIP_DEPTH: float = 0.005
const LABEL_PIXEL_SIZE: float = 0.003
const LABEL_FONT_SIZE: int = 28
const TENDRIL_COUNT: int = 6
const CRYSTAL_FRAGMENTS: int = 2

# ── Internal state ────────────────────────────────────────────────────

var _built: bool = false

# ── Lifecycle ─────────────────────────────────────────────────────────

func _ready() -> void:
	_read_metadata_overrides()
	_build_specimen_jar()


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()
	if _built:
		_clear_built_children()
		_built = false
		_build_specimen_jar()


func _read_metadata_overrides() -> void:
	if has_meta("config_jar_height"):
		jar_height = float(str(get_meta("config_jar_height")))
	if has_meta("config_jar_radius"):
		jar_radius = float(str(get_meta("config_jar_radius")))
	if has_meta("config_plinth_height"):
		plinth_height = float(str(get_meta("config_plinth_height")))
	if has_meta("config_plinth_width"):
		plinth_width = float(str(get_meta("config_plinth_width")))
	if has_meta("config_glass_color"):
		glass_color = _parse_color(str(get_meta("config_glass_color")), glass_color)
	if has_meta("config_content_color"):
		content_color = _parse_color(str(get_meta("config_content_color")), content_color)
	if has_meta("config_cap_color"):
		cap_color = _parse_color(str(get_meta("config_cap_color")), cap_color)
	if has_meta("config_label_color"):
		label_color = _parse_color(str(get_meta("config_label_color")), label_color)
	if has_meta("config_content_shape"):
		content_shape = str(get_meta("config_content_shape")).to_lower()
	if has_meta("config_label_text"):
		label_text = str(get_meta("config_label_text"))
	if has_meta("config_content_glow"):
		content_glow = float(str(get_meta("config_content_glow")))


func _clear_built_children() -> void:
	for c in get_children():
		c.queue_free()


# ── Build ─────────────────────────────────────────────────────────────

func _build_specimen_jar() -> void:
	_built = true
	_build_plinth()
	_build_jar()
	_build_cap()
	_build_content()
	_build_label()
	_build_accent_strip()


func _build_plinth() -> void:
	var plinth := MeshInstance3D.new()
	plinth.name = "Plinth"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(plinth_width, plinth_height, plinth_width)
	plinth.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = cap_color.lerp(Color(0.25, 0.25, 0.27), 0.4)
	mat.roughness = 0.55
	mat.metallic = 0.4
	plinth.material_override = mat
	plinth.position = Vector3(0.0, plinth_height * 0.5, 0.0)
	add_child(plinth)


func _build_jar() -> void:
	# Translucent cylinder sitting on top of the plinth.
	var jar := MeshInstance3D.new()
	jar.name = "Jar"
	var mesh := CylinderMesh.new()
	mesh.top_radius = jar_radius
	mesh.bottom_radius = jar_radius
	mesh.height = jar_height
	jar.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = glass_color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness = 0.15
	mat.metallic = 0.0
	mat.emission_enabled = true
	mat.emission = Color(glass_color.r, glass_color.g, glass_color.b)
	mat.emission_energy_multiplier = 0.15
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	mat.cull_mode = BaseMaterial3D.CULL_BACK
	jar.material_override = mat
	jar.position = Vector3(0.0, plinth_height + jar_height * 0.5, 0.0)
	add_child(jar)


func _build_cap() -> void:
	var cap := MeshInstance3D.new()
	cap.name = "Cap"
	var mesh := CylinderMesh.new()
	mesh.top_radius = jar_radius * CAP_RADIUS_FACTOR
	mesh.bottom_radius = jar_radius * (CAP_RADIUS_FACTOR - 0.04)
	mesh.height = CAP_HEIGHT
	cap.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = cap_color
	mat.roughness = 0.45
	mat.metallic = 0.7
	cap.material_override = mat
	cap.position = Vector3(0.0, plinth_height + jar_height + CAP_HEIGHT * 0.5, 0.0)
	add_child(cap)


func _build_content() -> void:
	# Interior content varies by content_shape. Skip for "empty".
	var shape := content_shape
	if shape == "empty":
		return
	var root := Node3D.new()
	root.name = "Content"
	add_child(root)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = content_color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA if content_color.a < 0.99 else BaseMaterial3D.TRANSPARENCY_DISABLED
	mat.roughness = 0.35
	mat.metallic = 0.1
	mat.emission_enabled = true
	mat.emission = content_color
	mat.emission_energy_multiplier = content_glow
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL

	# Center for content inside the jar.
	var center_y := plinth_height + jar_height * 0.5
	# Inner radius the content should respect (a bit smaller than jar interior).
	var inner_r := jar_radius * 0.78

	match shape:
		"blob":
			_build_blob(root, center_y, inner_r, mat)
		"tendrils":
			_build_tendrils(root, center_y, inner_r, mat)
		"crystal":
			_build_crystal(root, center_y, inner_r, mat)
		_:
			# Unknown shape — default to blob.
			_build_blob(root, center_y, inner_r, mat)


func _build_blob(parent: Node3D, cy: float, r_in: float, mat: StandardMaterial3D) -> void:
	var blob := MeshInstance3D.new()
	blob.name = "Blob"
	var mesh := SphereMesh.new()
	mesh.radius = r_in * 0.85
	mesh.height = r_in * 1.4   # squashed
	blob.mesh = mesh
	blob.material_override = mat
	blob.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	blob.position = Vector3(0.0, cy - jar_height * 0.18, 0.0)
	# Slight scale stretch to feel less perfect-spherical.
	blob.scale = Vector3(1.0, 0.85, 1.05)
	parent.add_child(blob)


func _build_tendrils(parent: Node3D, cy: float, r_in: float, mat: StandardMaterial3D) -> void:
	# Several thin cylinder rods radiating from center, tilted upward.
	var hub := MeshInstance3D.new()
	hub.name = "Hub"
	var sm := SphereMesh.new()
	sm.radius = r_in * 0.25
	sm.height = r_in * 0.5
	hub.mesh = sm
	hub.material_override = mat
	hub.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	hub.position = Vector3(0.0, cy - jar_height * 0.18, 0.0)
	parent.add_child(hub)

	var tendril_len := jar_height * 0.55
	for i in range(TENDRIL_COUNT):
		var ang := TAU * float(i) / float(TENDRIL_COUNT)
		var tendril := MeshInstance3D.new()
		tendril.name = "Tendril_%d" % i
		var cm := CylinderMesh.new()
		cm.top_radius = 0.008
		cm.bottom_radius = 0.016
		cm.height = tendril_len
		tendril.mesh = cm
		tendril.material_override = mat
		tendril.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		# Each tendril leans outward+upward. Default axis = +Y; rotate to tilt.
		var lean := deg_to_rad(35.0)
		var basis := Basis()
		basis = basis.rotated(Vector3(0.0, 1.0, 0.0), ang)
		basis = basis.rotated(Vector3(0.0, 0.0, 1.0), -lean)
		tendril.transform.basis = basis
		# Position the tendril so its bottom is at the hub; lift by half-length along its new +Y.
		var local_up := basis.y.normalized()
		var hub_y := cy - jar_height * 0.18
		tendril.position = Vector3(0.0, hub_y, 0.0) + local_up * (tendril_len * 0.5)
		parent.add_child(tendril)


func _build_crystal(parent: Node3D, cy: float, r_in: float, mat: StandardMaterial3D) -> void:
	# 1-2 PrismMesh fragments, slightly rotated.
	var n = max(1, CRYSTAL_FRAGMENTS)
	for i in range(n):
		var frag := MeshInstance3D.new()
		frag.name = "Crystal_%d" % i
		var pm := PrismMesh.new()
		pm.size = Vector3(r_in * 0.9, jar_height * 0.55, r_in * 0.6)
		pm.left_to_right = 0.5
		frag.mesh = pm
		frag.material_override = mat
		frag.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var ang := TAU * float(i) / float(n) + 0.4
		var tilt := deg_to_rad(15.0) * (1.0 if i % 2 == 0 else -1.0)
		frag.rotation = Vector3(tilt, ang, 0.0)
		# Offset toward center, slight lateral shift so two crystals interlock.
		var ox := cos(ang) * r_in * 0.18
		var oz := sin(ang) * r_in * 0.18
		var cy_offset := jar_height * (0.05 if i == 0 else -0.05)
		frag.position = Vector3(ox, cy + cy_offset, oz)
		parent.add_child(frag)


func _build_label() -> void:
	if label_text == "":
		return
	# Baked panel: amber background + dark text, printed onto the plinth front face.
	# World size: 82 % of plinth width × ~55 % of plinth height (matches old Label3D footprint).
	var w: float = plinth_width * 0.82
	var h: float = plinth_height * 0.55
	var quad: MeshInstance3D = BakedText.make_panel_mesh(
		label_text,
		label_color,                    # amber background
		Color(0.07, 0.05, 0.02),        # dark brown text (matches old outline_modulate)
		Vector2(w, h)
	)
	if quad:
		quad.name = "Label"
		# Position at the same spot the Label3D was: centred on the plinth front face,
		# proud by 0.006 m so it sits on the surface.
		quad.position = Vector3(0.0, plinth_height * 0.6, plinth_width * 0.5 + 0.006)
		add_child(quad)


func _build_accent_strip() -> void:
	# Emissive band wrapping the top of the plinth (4 box pieces).
	var root := Node3D.new()
	root.name = "AccentStrip"
	add_child(root)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = label_color
	mat.emission_enabled = true
	mat.emission = label_color
	mat.emission_energy_multiplier = 1.5
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL

	var y := plinth_height - ACCENT_STRIP_HEIGHT * 0.5 - 0.003
	var half := plinth_width * 0.5

	# Front (+Z)
	var f := MeshInstance3D.new()
	f.name = "Front"
	var fm := BoxMesh.new()
	fm.size = Vector3(plinth_width + 0.005, ACCENT_STRIP_HEIGHT, ACCENT_STRIP_DEPTH)
	f.mesh = fm
	f.material_override = mat
	f.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	f.position = Vector3(0.0, y, half + ACCENT_STRIP_DEPTH * 0.5)
	root.add_child(f)

	# Back
	var b := MeshInstance3D.new()
	b.name = "Back"
	var bm := BoxMesh.new()
	bm.size = Vector3(plinth_width + 0.005, ACCENT_STRIP_HEIGHT, ACCENT_STRIP_DEPTH)
	b.mesh = bm
	b.material_override = mat
	b.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	b.position = Vector3(0.0, y, -half - ACCENT_STRIP_DEPTH * 0.5)
	root.add_child(b)

	# Left
	var l := MeshInstance3D.new()
	l.name = "Left"
	var lm := BoxMesh.new()
	lm.size = Vector3(ACCENT_STRIP_DEPTH, ACCENT_STRIP_HEIGHT, plinth_width + 0.005)
	l.mesh = lm
	l.material_override = mat
	l.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	l.position = Vector3(-half - ACCENT_STRIP_DEPTH * 0.5, y, 0.0)
	root.add_child(l)

	# Right
	var r := MeshInstance3D.new()
	r.name = "Right"
	var rm := BoxMesh.new()
	rm.size = Vector3(ACCENT_STRIP_DEPTH, ACCENT_STRIP_HEIGHT, plinth_width + 0.005)
	r.mesh = rm
	r.material_override = mat
	r.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	r.position = Vector3(half + ACCENT_STRIP_DEPTH * 0.5, y, 0.0)
	root.add_child(r)


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
