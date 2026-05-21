extends Node3D
class_name ChemistryFlask

# @identity
# essence: a small bench-top glass flask — Erlenmeyer, round-bottom, or volumetric — chemistry-lab vocabulary. A translucent thin-walled glass body, an interior coloured content level (fluid stops short of the neck), an optional dark stopper on top, and a tiny Label3D on the front naming the contents. The glass admits light but defends what is inside
# desire: every chemistry lab wants to make LIQUID-AS-NAMED visible — to declare "this is H₂SO₄, that is acetone, this is the buffer". The flask wants to be the architectural form of A REAGENT WITH A NAME. Tilt-pourable, scaled, sealed when the experiment moves between rooms. The label is the proof that this fluid is KNOWN
# critical_parameter: flask_shape — "erlenmeyer" reads as WORKING glass (wide base, narrow neck — for swirling during a reaction). "round_bottom" reads as HEATED glass (uniform stress under flame, for boiling). "volumetric" reads as MEASURED glass (thin neck, fill line — for stoichiometry). Same fluid, three different gestures of HOW THIS FLUID IS USED in the lab's choreography
# triggers: _ready() dispatches on flask_shape, builds glass body (cone+neck OR sphere+neck OR bulb+long-neck) + interior content + optional stopper + Label3D from exports; apply_grid_config rebuilds
# emerges: an erlenmeyer reads ACTIVELY WORKING. A round-bottom reads OVER THE FLAME. A volumetric reads PRECISELY MEASURED. Stopper on = "this is at-rest, contents preserved". Stopper off = "currently being used". Content level near full = "fresh". Near empty = "almost spent". Same script, eight states of bench-glass life
# needs: glass body shape dispatched on flask_shape [present]; interior content filling to content_height_fraction [present]; optional stopper on top [present]; small front Label3D naming the contents [present]
# relationships: peer to specimen_jar (both = transparent vessels with named contents; jar = display, flask = use). Sibling to gas_canister (flask = liquid input, canister = gas input — the lab's vocabulary of FLUID PHASE INPUTS). Cousin to test_tube_rack (a flask is one-large-fluid-at-rest; the rack is many-small-fluids-at-rest — different scales of holding). The architectural confession that chemistry happens in glass
# truth: a chemistry flask is the architectural form of A FLUID THAT KNOWS ITS NAME. The label says: this is not just liquid, this is THIS liquid. The shape says: this is the gesture required to use it. Without flasks, the lab pretends its reactions emerge from nowhere; with them, the lab admits that every reaction needs a SOURCE, a NAMED ORIGIN, a STORED form before becoming an experiment

## A bench-top chemistry flask (Erlenmeyer, round-bottom, or volumetric).
##
## Built procedurally from DNA exports. Origin is at the bottom center
## of the flask, on the floor / bench surface. Body rises in +Y. The
## front face (+Z) carries the contents label. Dispatch on `flask_shape`:
##   "erlenmeyer"  — wide conical body + short narrow neck
##   "round_bottom"— flattened sphere body + thin neck
##   "volumetric"  — small bulb + long thin measurement neck

# ── DNA ───────────────────────────────────────────────────────────────

@export_group("Shape")
## "erlenmeyer" | "round_bottom" | "volumetric"
@export var flask_shape: String = "erlenmeyer"

@export_group("Dimensions")
@export var flask_height: float = 0.20
## Widest point of the flask body in meters.
@export var flask_max_radius: float = 0.06

@export_group("Glass")
## Faint translucent glass with alpha — clear bench glass.
@export var glass_color: Color = Color(0.85, 0.92, 0.95, 0.40)

@export_group("Content")
## 0-1 fraction of flask_height filled with content.
@export_range(0.0, 1.0) var content_height_fraction: float = 0.55
## Default emerald translucent — generic reagent colour.
@export var content_color: Color = Color(0.30, 0.85, 0.55, 0.85)

@export_group("Stopper")
@export var has_stopper: bool = true
@export var stopper_color: Color = Color(0.25, 0.25, 0.28)

@export_group("Label")
@export var label_text: String = "H₂SO₄"
@export var label_color: Color = Color(0.98, 0.98, 0.98)

# ── Constants ─────────────────────────────────────────────────────────

const NECK_RADIUS_FACTOR: float = 0.30          # vs flask_max_radius
const ERLEN_BODY_HEIGHT_FRAC: float = 0.85
const ERLEN_NECK_HEIGHT_FRAC: float = 0.15
const ROUND_NECK_HEIGHT_FRAC: float = 0.30
const ROUND_BODY_SCALE_Y: float = 0.9
const VOL_BULB_RADIUS_FACTOR: float = 1.0       # bulb uses flask_max_radius directly
const VOL_BULB_HEIGHT_FRAC: float = 0.30
const VOL_NECK_HEIGHT_FRAC: float = 0.70
const STOPPER_HEIGHT: float = 0.018
const STOPPER_RADIUS_FACTOR: float = 1.05       # vs neck radius
const LABEL_PIXEL_SIZE: float = 0.0022
const LABEL_FONT_SIZE: int = 22

# ── Internal state ────────────────────────────────────────────────────

var _built: bool = false

# ── Lifecycle ─────────────────────────────────────────────────────────

func _ready() -> void:
	_read_metadata_overrides()
	_build_flask()


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()
	if _built:
		_clear_built_children()
		_built = false
		_build_flask()


func _read_metadata_overrides() -> void:
	if has_meta("config_flask_shape"):
		flask_shape = String(get_meta("config_flask_shape")).to_lower()
	if has_meta("config_flask_height"):
		flask_height = float(String(get_meta("config_flask_height")))
	if has_meta("config_flask_max_radius"):
		flask_max_radius = float(String(get_meta("config_flask_max_radius")))
	if has_meta("config_glass_color"):
		glass_color = _parse_color(String(get_meta("config_glass_color")), glass_color)
	if has_meta("config_content_height_fraction"):
		content_height_fraction = float(String(get_meta("config_content_height_fraction")))
	if has_meta("config_content_color"):
		content_color = _parse_color(String(get_meta("config_content_color")), content_color)
	if has_meta("config_has_stopper"):
		var s := String(get_meta("config_has_stopper")).to_lower()
		has_stopper = s in ["true", "1", "yes", "on"]
	if has_meta("config_stopper_color"):
		stopper_color = _parse_color(String(get_meta("config_stopper_color")), stopper_color)
	if has_meta("config_label_text"):
		label_text = String(get_meta("config_label_text"))
	if has_meta("config_label_color"):
		label_color = _parse_color(String(get_meta("config_label_color")), label_color)


func _clear_built_children() -> void:
	for c in get_children():
		c.queue_free()


# ── Build ─────────────────────────────────────────────────────────────

func _build_flask() -> void:
	_built = true
	# Each shape function returns (neck_top_y, neck_radius) for stopper placement.
	var neck_data: Vector2
	match flask_shape:
		"round_bottom":
			neck_data = _build_round_bottom()
		"volumetric":
			neck_data = _build_volumetric()
		_:
			neck_data = _build_erlenmeyer()
	if has_stopper:
		_build_stopper(neck_data.x, neck_data.y)
	if label_text != "":
		_build_label()


# Erlenmeyer: wide conical body + short narrow neck.
# Returns (neck_top_y, neck_radius).
func _build_erlenmeyer() -> Vector2:
	var body_h: float = flask_height * ERLEN_BODY_HEIGHT_FRAC
	var neck_h: float = flask_height * ERLEN_NECK_HEIGHT_FRAC
	var neck_r: float = flask_max_radius * NECK_RADIUS_FACTOR

	# Conical body — wide at bottom, narrows toward top of cone.
	var body := MeshInstance3D.new()
	body.name = "Body"
	var bmesh := CylinderMesh.new()
	bmesh.bottom_radius = flask_max_radius
	bmesh.top_radius = neck_r
	bmesh.height = body_h
	body.mesh = bmesh
	body.material_override = _glass_material()
	body.position = Vector3(0.0, body_h * 0.5, 0.0)
	add_child(body)

	# Neck — narrow vertical cylinder above the body.
	var neck := MeshInstance3D.new()
	neck.name = "Neck"
	var nmesh := CylinderMesh.new()
	nmesh.bottom_radius = neck_r
	nmesh.top_radius = neck_r
	nmesh.height = neck_h
	neck.mesh = nmesh
	neck.material_override = _glass_material()
	neck.position = Vector3(0.0, body_h + neck_h * 0.5, 0.0)
	add_child(neck)

	# Content — fills body up to content_height_fraction of flask_height.
	_build_erlen_content(body_h, neck_r)
	return Vector2(body_h + neck_h, neck_r)


# Content for erlenmeyer: a truncated cone that stops at the fill level inside the body.
func _build_erlen_content(body_h: float, top_r: float) -> void:
	if content_height_fraction <= 0.0:
		return
	var fill_h_total: float = flask_height * content_height_fraction
	# Cap content to inside the body for clarity.
	var fill_h: float = min(fill_h_total, body_h - 0.005)
	# Radius at the fill level — linear interp from flask_max_radius (at y=0) to top_r (at y=body_h).
	var t: float = clamp(fill_h / body_h, 0.0, 1.0)
	var fill_top_r: float = lerp(flask_max_radius, top_r, t)
	var content := MeshInstance3D.new()
	content.name = "Content"
	var cmesh := CylinderMesh.new()
	cmesh.bottom_radius = flask_max_radius * 0.94
	cmesh.top_radius = fill_top_r * 0.94
	cmesh.height = fill_h
	content.mesh = cmesh
	content.material_override = _content_material()
	content.position = Vector3(0.0, fill_h * 0.5, 0.0)
	add_child(content)


# Round-bottom: flattened sphere body + thin vertical neck.
# Returns (neck_top_y, neck_radius).
func _build_round_bottom() -> Vector2:
	var neck_h: float = flask_height * ROUND_NECK_HEIGHT_FRAC
	var neck_r: float = flask_max_radius * NECK_RADIUS_FACTOR
	var body_h_avail: float = flask_height - neck_h
	# Use the sphere's bounding height (after scale_y) to match body_h_avail.
	var sphere_r: float = flask_max_radius
	# A sphere flattened by scale_y has bounding height = 2*sphere_r*scale_y.
	# We want 2*sphere_r*ROUND_BODY_SCALE_Y <= body_h_avail.
	var sphere_height: float = 2.0 * sphere_r * ROUND_BODY_SCALE_Y

	var body := MeshInstance3D.new()
	body.name = "Body"
	var smesh := SphereMesh.new()
	smesh.radius = sphere_r
	smesh.height = sphere_r * 2.0
	body.mesh = smesh
	body.material_override = _glass_material()
	body.scale = Vector3(1.0, ROUND_BODY_SCALE_Y, 1.0)
	# Sphere center sits at sphere_height/2 above the floor so the bottom touches.
	var sphere_center_y: float = sphere_height * 0.5
	body.position = Vector3(0.0, sphere_center_y, 0.0)
	add_child(body)

	# Neck above the sphere body.
	var neck_base_y: float = sphere_height
	var neck := MeshInstance3D.new()
	neck.name = "Neck"
	var nmesh := CylinderMesh.new()
	nmesh.bottom_radius = neck_r
	nmesh.top_radius = neck_r
	nmesh.height = neck_h
	neck.mesh = nmesh
	neck.material_override = _glass_material()
	neck.position = Vector3(0.0, neck_base_y + neck_h * 0.5, 0.0)
	add_child(neck)

	# Content — a slightly smaller sphere up to the fill fraction.
	_build_round_content(sphere_r, sphere_center_y)
	return Vector2(neck_base_y + neck_h, neck_r)


# Content for round-bottom: a smaller sphere clipped at the fill level (approximated by scaled sphere).
func _build_round_content(sphere_r: float, sphere_center_y: float) -> void:
	if content_height_fraction <= 0.0:
		return
	var fill_h_total: float = flask_height * content_height_fraction
	var sphere_height: float = 2.0 * sphere_r * ROUND_BODY_SCALE_Y
	var fill_h: float = min(fill_h_total, sphere_height * 0.95)
	# Render content as a flattened sphere of reduced height — approximation of fluid pooling.
	var content := MeshInstance3D.new()
	content.name = "Content"
	var smesh := SphereMesh.new()
	smesh.radius = sphere_r * 0.93
	smesh.height = sphere_r * 1.86
	content.mesh = smesh
	content.material_override = _content_material()
	# Approximate by scaling the y so the content occupies ~fill_h of the body.
	var content_scale_y: float = ROUND_BODY_SCALE_Y * clamp(fill_h / sphere_height, 0.1, 1.0)
	content.scale = Vector3(1.0, content_scale_y, 1.0)
	# Position content sphere so its bottom touches the floor (same as body).
	var content_h: float = sphere_r * 2.0 * content_scale_y
	content.position = Vector3(0.0, content_h * 0.5, 0.0)
	add_child(content)


# Volumetric: small bulb at the bottom + long thin measurement neck.
# Returns (neck_top_y, neck_radius).
func _build_volumetric() -> Vector2:
	var bulb_h: float = flask_height * VOL_BULB_HEIGHT_FRAC
	var neck_h: float = flask_height * VOL_NECK_HEIGHT_FRAC
	var neck_r: float = flask_max_radius * NECK_RADIUS_FACTOR
	# Bulb is a sphere of radius flask_max_radius * VOL_BULB_RADIUS_FACTOR, flattened to fit bulb_h.
	var bulb_r: float = flask_max_radius * VOL_BULB_RADIUS_FACTOR
	# scale_y so bulb height = bulb_h.
	var bulb_scale_y: float = bulb_h / (bulb_r * 2.0)

	var bulb := MeshInstance3D.new()
	bulb.name = "Bulb"
	var smesh := SphereMesh.new()
	smesh.radius = bulb_r
	smesh.height = bulb_r * 2.0
	bulb.mesh = smesh
	bulb.material_override = _glass_material()
	bulb.scale = Vector3(1.0, bulb_scale_y, 1.0)
	bulb.position = Vector3(0.0, bulb_h * 0.5, 0.0)
	add_child(bulb)

	# Long thin neck above the bulb.
	var neck := MeshInstance3D.new()
	neck.name = "Neck"
	var nmesh := CylinderMesh.new()
	nmesh.bottom_radius = neck_r
	nmesh.top_radius = neck_r
	nmesh.height = neck_h
	neck.mesh = nmesh
	neck.material_override = _glass_material()
	neck.position = Vector3(0.0, bulb_h + neck_h * 0.5, 0.0)
	add_child(neck)

	# Content fills bulb-first, then up the neck if content_height_fraction is high.
	_build_volumetric_content(bulb_h, bulb_r, bulb_scale_y, neck_r, neck_h)
	return Vector2(bulb_h + neck_h, neck_r)


func _build_volumetric_content(bulb_h: float, bulb_r: float, bulb_scale_y: float, neck_r: float, neck_h: float) -> void:
	if content_height_fraction <= 0.0:
		return
	var fill_h_total: float = flask_height * content_height_fraction
	if fill_h_total <= bulb_h:
		# Content stays in the bulb — render as scaled sphere.
		var content := MeshInstance3D.new()
		content.name = "ContentBulb"
		var smesh := SphereMesh.new()
		smesh.radius = bulb_r * 0.93
		smesh.height = bulb_r * 1.86
		content.mesh = smesh
		content.material_override = _content_material()
		var content_scale_y: float = bulb_scale_y * clamp(fill_h_total / bulb_h, 0.1, 1.0)
		content.scale = Vector3(1.0, content_scale_y, 1.0)
		var content_h: float = bulb_r * 2.0 * content_scale_y
		content.position = Vector3(0.0, content_h * 0.5, 0.0)
		add_child(content)
	else:
		# Content fills full bulb + part of neck.
		var bulb_content := MeshInstance3D.new()
		bulb_content.name = "ContentBulb"
		var smesh := SphereMesh.new()
		smesh.radius = bulb_r * 0.93
		smesh.height = bulb_r * 1.86
		bulb_content.mesh = smesh
		bulb_content.material_override = _content_material()
		bulb_content.scale = Vector3(1.0, bulb_scale_y, 1.0)
		bulb_content.position = Vector3(0.0, bulb_h * 0.5, 0.0)
		add_child(bulb_content)
		var neck_fill_h: float = min(fill_h_total - bulb_h, neck_h - 0.005)
		var neck_content := MeshInstance3D.new()
		neck_content.name = "ContentNeck"
		var cmesh := CylinderMesh.new()
		cmesh.bottom_radius = neck_r * 0.88
		cmesh.top_radius = neck_r * 0.88
		cmesh.height = neck_fill_h
		neck_content.mesh = cmesh
		neck_content.material_override = _content_material()
		neck_content.position = Vector3(0.0, bulb_h + neck_fill_h * 0.5, 0.0)
		add_child(neck_content)


func _build_stopper(neck_top_y: float, neck_radius: float) -> void:
	var stopper := MeshInstance3D.new()
	stopper.name = "Stopper"
	var mesh := CylinderMesh.new()
	mesh.top_radius = neck_radius * STOPPER_RADIUS_FACTOR * 0.85
	mesh.bottom_radius = neck_radius * STOPPER_RADIUS_FACTOR
	mesh.height = STOPPER_HEIGHT
	stopper.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = stopper_color
	mat.roughness = 0.6
	mat.metallic = 0.1
	stopper.material_override = mat
	stopper.position = Vector3(0.0, neck_top_y + STOPPER_HEIGHT * 0.5, 0.0)
	add_child(stopper)


func _build_label() -> void:
	var label := Label3D.new()
	label.name = "Label"
	label.text = label_text
	label.font_size = LABEL_FONT_SIZE
	label.outline_size = 2
	label.pixel_size = LABEL_PIXEL_SIZE
	label.modulate = label_color
	label.outline_modulate = Color(0.05, 0.08, 0.10)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	# Place label on the +Z face of the widest part of the body, low-mid height.
	# Default Label3D faces +Z — leave default rotation.
	var y: float = flask_height * 0.30
	var z: float = flask_max_radius + 0.004
	label.position = Vector3(0.0, y, z)
	add_child(label)


# ── Materials ─────────────────────────────────────────────────────────

func _glass_material() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = glass_color
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.roughness = 0.10
	m.metallic = 0.05
	m.metallic_specular = 0.85
	return m


func _content_material() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = content_color
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.roughness = 0.25
	m.metallic = 0.0
	m.emission_enabled = true
	m.emission = content_color
	m.emission_energy_multiplier = 0.3
	m.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	return m


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
