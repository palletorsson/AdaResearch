extends Node3D
class_name Microscope

# @identity
# essence: a bench-top optical microscope — Half-Life lab vocabulary. Heavy dark steel base, a curved/angled column rising up, a white glossy stage with two specimen clamps at mid-height, an objective turret carrying four short lenses, a small emissive bulb illuminator under the stage, one or two tilted eyepieces at the top. Small, dense, undeniably an instrument
# desire: every lab wants a thing the player KNOWS is an instrument the moment they see it. The microscope is the universal lab silhouette — heavy base, angled column, two eyepieces, stage clamps. Recognition is the whole point
# critical_parameter: eyepiece_count + light_on — monocular vs. binocular is a clear age/era cue (monocular = old-school, binocular = modern), and light_on changes the bulb from "tool at rest" to "instrument in use". Same shape, different state of being-used
# triggers: _ready() builds base + column + stage + clamps + turret + objective lenses + eyepieces + illuminator + accent strip; apply_grid_config rebuilds
# emerges: a quiet microscope says "this lab does specimen work". An illuminated, binocular microscope says "someone is HERE, looking at something tiny right now". The artifact carries different presences
# needs: heavy base [present]; angled column [present]; white stage with clamps [present]; objective turret + N lenses [present]; eyepieces tilted toward viewer [present]; optional bulb under stage [present]; accent ring around base [present]
# relationships: peer to specimen_jar (microscope = the act of looking; jar = the thing looked at); sibling to data_tablet (one reads, one records); cousin to robotarm (both are precision instruments — one for the hand, one for the eye); the lab's gesture of attention focused-small
# truth: a microscope is the architectural form of LOOKING-CLOSER. It implies that something matters at scales the body cannot reach. Its presence promises that the small is consequential. Without it, the lab might be studying weather; WITH it, the lab is studying cells, crystals, microbes — the world below the threshold of touch

## A bench-top optical microscope.
##
## Built procedurally from DNA exports. Origin is at the bottom center
## of the base footprint, faces +Z (eyepieces angle slightly toward the
## viewer at +Z). The whole instrument fits inside a roughly base_width
## × base_width × body_height footprint, with eyepieces extending above.

# ── DNA ───────────────────────────────────────────────────────────────

@export_group("Dimensions")
@export var body_height: float = 0.38
@export var base_width: float = 0.22

@export_group("Color")
@export var body_color: Color = Color(0.20, 0.20, 0.22)        # dark steel
@export var stage_color: Color = Color(0.94, 0.94, 0.95)       # glossy white
@export var accent_color: Color = Color(0.95, 0.55, 0.0)       # Portal orange

@export_group("Optics")
## 1 = monocular, 2 = binocular (typical).
@export_range(1, 3) var eyepiece_count: int = 2
## Number of objective lenses on the turret.
@export_range(1, 6) var objective_count: int = 4

@export_group("Illumination")
@export var light_on: bool = true
@export var light_color: Color = Color(1.0, 0.92, 0.78)        # warm white

# ── Constants ─────────────────────────────────────────────────────────

const BASE_HEIGHT_FACTOR: float = 0.18
const STAGE_THICKNESS: float = 0.012
const STAGE_WIDTH_FACTOR: float = 0.65
const STAGE_DEPTH_FACTOR: float = 0.6
const STAGE_HEIGHT_FACTOR: float = 0.45   # vs body_height
const COLUMN_WIDTH_FACTOR: float = 0.20
const COLUMN_DEPTH_FACTOR: float = 0.30
const COLUMN_TILT_RAD: float = 0.12       # ~7° tilt forward (-Z toward +Z)
const TURRET_RADIUS_FACTOR: float = 0.10  # vs body_height
const TURRET_THICKNESS: float = 0.025
const OBJECTIVE_RADIUS: float = 0.012
const OBJECTIVE_LENGTH: float = 0.035
const EYEPIECE_RADIUS: float = 0.018
const EYEPIECE_LENGTH: float = 0.07
const EYEPIECE_TILT_RAD: float = 0.26     # ~15° toward +Z
const BULB_RADIUS: float = 0.022
const BULB_HEIGHT: float = 0.018
const CLAMP_SIZE: Vector3 = Vector3(0.015, 0.012, 0.05)
const ACCENT_STRIP_HEIGHT: float = 0.006
const ACCENT_STRIP_DEPTH: float = 0.003

# ── Internal state ────────────────────────────────────────────────────

var _built: bool = false

# ── Lifecycle ─────────────────────────────────────────────────────────

func _ready() -> void:
	_read_metadata_overrides()
	_build_microscope()


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()
	if _built:
		_clear_built_children()
		_built = false
		_build_microscope()


func _read_metadata_overrides() -> void:
	if has_meta("config_body_height"):
		body_height = float(str(get_meta("config_body_height")))
	if has_meta("config_base_width"):
		base_width = float(str(get_meta("config_base_width")))
	if has_meta("config_body_color"):
		body_color = _parse_color(str(get_meta("config_body_color")), body_color)
	if has_meta("config_stage_color"):
		stage_color = _parse_color(str(get_meta("config_stage_color")), stage_color)
	if has_meta("config_accent_color"):
		accent_color = _parse_color(str(get_meta("config_accent_color")), accent_color)
	if has_meta("config_eyepiece_count"):
		eyepiece_count = int(str(get_meta("config_eyepiece_count")))
	if has_meta("config_objective_count"):
		objective_count = int(str(get_meta("config_objective_count")))
	if has_meta("config_light_on"):
		var v := str(get_meta("config_light_on")).to_lower()
		light_on = v in ["true", "1", "yes", "on"]
	if has_meta("config_light_color"):
		light_color = _parse_color(str(get_meta("config_light_color")), light_color)


func _clear_built_children() -> void:
	for c in get_children():
		c.queue_free()


# ── Build ─────────────────────────────────────────────────────────────

func _build_microscope() -> void:
	_built = true
	_build_base()
	_build_column()
	_build_stage()
	_build_stage_clamps()
	_build_objective_turret_and_lenses()
	_build_eyepieces()
	_build_illuminator()
	_build_accent_strip()


func _build_base() -> void:
	var base := MeshInstance3D.new()
	base.name = "Base"
	var mesh := BoxMesh.new()
	var h := body_height * BASE_HEIGHT_FACTOR
	mesh.size = Vector3(base_width, h, base_width)
	base.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = body_color
	mat.roughness = 0.4
	mat.metallic = 0.6
	base.material_override = mat
	base.position = Vector3(0.0, h * 0.5, 0.0)
	add_child(base)


func _build_column() -> void:
	# A tilted box rising from the back-half of the base up to where
	# the eyepieces will sit. Tilts slightly toward +Z (toward viewer).
	var col := MeshInstance3D.new()
	col.name = "Column"
	var base_h := body_height * BASE_HEIGHT_FACTOR
	var col_h := body_height - base_h
	var mesh := BoxMesh.new()
	mesh.size = Vector3(base_width * COLUMN_WIDTH_FACTOR, col_h, base_width * COLUMN_DEPTH_FACTOR)
	col.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = body_color
	mat.roughness = 0.45
	mat.metallic = 0.55
	col.material_override = mat
	col.rotation = Vector3(-COLUMN_TILT_RAD, 0.0, 0.0)
	# Position the column's base at the back of the base plate.
	var z_back := -base_width * 0.5 + (base_width * COLUMN_DEPTH_FACTOR) * 0.5 + 0.005
	col.position = Vector3(0.0, base_h + col_h * 0.5, z_back)
	add_child(col)


func _build_stage() -> void:
	# White glossy stage extending forward (+Z) from the column.
	var stage := MeshInstance3D.new()
	stage.name = "Stage"
	var w := base_width * STAGE_WIDTH_FACTOR
	var d := base_width * STAGE_DEPTH_FACTOR
	var mesh := BoxMesh.new()
	mesh.size = Vector3(w, STAGE_THICKNESS, d)
	stage.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = stage_color
	mat.roughness = 0.2
	mat.metallic = 0.05
	stage.material_override = mat
	var y := body_height * STAGE_HEIGHT_FACTOR
	# Slightly forward of center so it reads as "extending from column".
	var z := d * 0.15
	stage.position = Vector3(0.0, y, z)
	add_child(stage)


func _build_stage_clamps() -> void:
	# Two small dark clamps on top of the stage.
	var clamps_root := Node3D.new()
	clamps_root.name = "Clamps"
	add_child(clamps_root)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = body_color
	mat.roughness = 0.5
	mat.metallic = 0.5

	var w := base_width * STAGE_WIDTH_FACTOR
	var d := base_width * STAGE_DEPTH_FACTOR
	var y_stage_top := body_height * STAGE_HEIGHT_FACTOR + STAGE_THICKNESS * 0.5
	var z_stage_center := d * 0.15
	# Two clamps offset along X, sitting on top of the stage near the back of stage.
	for sign_x in [1, -1]:
		var clamp := MeshInstance3D.new()
		clamp.name = "Clamp_%d" % sign_x
		var m := BoxMesh.new()
		m.size = CLAMP_SIZE
		clamp.mesh = m
		clamp.material_override = mat
		clamp.position = Vector3(
			(w * 0.30) * float(sign_x),
			y_stage_top + CLAMP_SIZE.y * 0.5,
			z_stage_center - d * 0.15
		)
		clamps_root.add_child(clamp)


func _build_objective_turret_and_lenses() -> void:
	# Turret disc just above the stage, with N short cylinder objectives hanging from it.
	var turret_root := Node3D.new()
	turret_root.name = "Turret"
	add_child(turret_root)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = body_color
	mat.roughness = 0.45
	mat.metallic = 0.65

	var turret_radius := body_height * TURRET_RADIUS_FACTOR
	var stage_top := body_height * STAGE_HEIGHT_FACTOR + STAGE_THICKNESS * 0.5
	var d := base_width * STAGE_DEPTH_FACTOR
	var z_stage_center := d * 0.15
	# Turret sits above the stage, centered above it.
	var turret_y := stage_top + 0.08

	# Turret disc.
	var disc := MeshInstance3D.new()
	disc.name = "TurretDisc"
	var dm := CylinderMesh.new()
	dm.top_radius = turret_radius
	dm.bottom_radius = turret_radius
	dm.height = TURRET_THICKNESS
	disc.mesh = dm
	disc.material_override = mat
	disc.position = Vector3(0.0, turret_y, z_stage_center)
	turret_root.add_child(disc)

	# Objective lenses radiating around the disc, hanging down.
	var lens_mat := StandardMaterial3D.new()
	lens_mat.albedo_color = body_color.lerp(Color(0.9, 0.9, 0.95), 0.15)
	lens_mat.roughness = 0.3
	lens_mat.metallic = 0.85

	var n = max(1, objective_count)
	for i in range(n):
		var ang := TAU * float(i) / float(n)
		var lens := MeshInstance3D.new()
		lens.name = "Objective_%d" % i
		var cm := CylinderMesh.new()
		cm.top_radius = OBJECTIVE_RADIUS
		cm.bottom_radius = OBJECTIVE_RADIUS * 0.85
		cm.height = OBJECTIVE_LENGTH
		lens.mesh = cm
		lens.material_override = lens_mat
		var lx := cos(ang) * turret_radius * 0.6
		var lz := sin(ang) * turret_radius * 0.6 + z_stage_center
		lens.position = Vector3(lx, turret_y - TURRET_THICKNESS * 0.5 - OBJECTIVE_LENGTH * 0.5, lz)
		turret_root.add_child(lens)


func _build_eyepieces() -> void:
	# 1-3 eyepieces angled slightly toward +Z, sitting at top of column.
	var eye_root := Node3D.new()
	eye_root.name = "Eyepieces"
	add_child(eye_root)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = body_color
	mat.roughness = 0.35
	mat.metallic = 0.7

	# Top of column accounting for tilt.
	var base_h := body_height * BASE_HEIGHT_FACTOR
	var col_h := body_height - base_h
	var z_back := -base_width * 0.5 + (base_width * COLUMN_DEPTH_FACTOR) * 0.5 + 0.005
	# Tilt rotates column around X; top of column is offset from z_back by col_h * sin(tilt).
	var top_y := base_h + col_h * cos(COLUMN_TILT_RAD)
	var top_z := z_back + col_h * sin(COLUMN_TILT_RAD)

	var n = clampi(eyepiece_count, 1, 3)
	var x_spacing := 0.025
	for i in range(n):
		var idx := float(i) - float(n - 1) * 0.5
		var eye := MeshInstance3D.new()
		eye.name = "Eyepiece_%d" % i
		var cm := CylinderMesh.new()
		cm.top_radius = EYEPIECE_RADIUS * 0.85
		cm.bottom_radius = EYEPIECE_RADIUS
		cm.height = EYEPIECE_LENGTH
		eye.mesh = cm
		eye.material_override = mat
		# Tilt forward toward +Z: rotate around X so the cylinder tube tips toward +Z.
		eye.rotation = Vector3(EYEPIECE_TILT_RAD, 0.0, 0.0)
		# Eyepiece is centered on the column top, offset along X for binocular spacing.
		var dy := -cos(EYEPIECE_TILT_RAD) * EYEPIECE_LENGTH * 0.4
		var dz := sin(EYEPIECE_TILT_RAD) * EYEPIECE_LENGTH * 0.5
		eye.position = Vector3(idx * x_spacing, top_y + EYEPIECE_LENGTH * 0.5 + dy, top_z + dz)
		eye_root.add_child(eye)


func _build_illuminator() -> void:
	# Small emissive bulb cylinder under the stage, sitting on the base.
	var bulb := MeshInstance3D.new()
	bulb.name = "Illuminator"
	var cm := CylinderMesh.new()
	cm.top_radius = BULB_RADIUS
	cm.bottom_radius = BULB_RADIUS
	cm.height = BULB_HEIGHT
	bulb.mesh = cm
	var mat := StandardMaterial3D.new()
	if light_on:
		mat.albedo_color = light_color
		mat.emission_enabled = true
		mat.emission = light_color
		mat.emission_energy_multiplier = 2.2
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	else:
		mat.albedo_color = light_color.darkened(0.5)
		mat.roughness = 0.6
		mat.metallic = 0.2
	bulb.material_override = mat
	bulb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Position: between base top and stage bottom, centered under the stage center.
	var base_h := body_height * BASE_HEIGHT_FACTOR
	var stage_y := body_height * STAGE_HEIGHT_FACTOR - STAGE_THICKNESS * 0.5
	var bulb_y: float = lerp(base_h, stage_y, 0.5)
	var d := base_width * STAGE_DEPTH_FACTOR
	bulb.position = Vector3(0.0, bulb_y, d * 0.15)
	add_child(bulb)


func _build_accent_strip() -> void:
	# Thin emissive ring/box around the front edge of the base.
	var strip := MeshInstance3D.new()
	strip.name = "AccentStrip"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(base_width * 0.92, ACCENT_STRIP_HEIGHT, ACCENT_STRIP_DEPTH)
	strip.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = accent_color
	mat.emission_enabled = true
	mat.emission = accent_color
	mat.emission_energy_multiplier = 1.5
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	strip.material_override = mat
	strip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var base_h := body_height * BASE_HEIGHT_FACTOR
	strip.position = Vector3(0.0, base_h * 0.6, base_width * 0.5 + ACCENT_STRIP_DEPTH * 0.5)
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
