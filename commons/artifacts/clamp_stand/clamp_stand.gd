extends Node3D
class_name ClampStand

# @identity
# essence: a bench retort stand — chemistry-lab vocabulary. A heavy rectangular cast-iron base, a thin vertical pole rising off-center from the base, 0-3 horizontal clamp arms at evenly-spaced heights, each ending in a 2-prong gripper, an optional small Erlenmeyer-style flask held by the topmost clamp, and a Portal-orange accent stripe around the base. The architectural form of HOLDING-IN-MIDAIR
# desire: every bench wants a way to suspend things off the surface — to keep a flask above a flame, a thermometer in a beaker, a burette over a collection vessel. The clamp stand wants to be the architectural form of HANDS THAT DO NOT TIRE. The vertical pole says "the air above this point is reserved for what we are holding"
# critical_parameter: clamp_count — 0 reads as INERT FURNITURE (the bench is over-equipped). 1 reads as A FOCUSED EXPERIMENT (one thing held). 2-3 reads as A LAYERED SETUP (a stack of held things, condensers + flasks + thermometers, the choreography of distillation). Same pole, three different intensities of WORK-IN-PROGRESS
# triggers: _ready() builds base + pole + clamp_count clamp arms at evenly-spaced heights + optional held flask in top clamp + accent stripe; apply_grid_config rebuilds
# emerges: 0 clamps + base only = "fresh, awaiting setup". 1 clamp = "single-stage experiment". 2-3 clamps = "complex apparatus, midway through a procedure". Holding_flask on = "this stand is in active use". Off = "set up but not yet running". Same script, six narratives of bench occupancy
# needs: heavy rectangular cast-iron base [present]; thin vertical pole, offset toward -X from base center [present]; 0-3 clamp arms extending in +X from the pole [present]; 2-prong gripper at the end of each arm [present]; optional small flask held by top clamp when holding_flask=true [present]; accent stripe around the base [present]
# relationships: peer to lab_stool (the stand holds the apparatus; the stool holds the body — together they choreograph the chemist at work). Sibling to large_table (the table is the horizontal substrate; the stand is the vertical substrate — both are about HEIGHT-OF-WORK). Cousin to chemistry_flask + test_tube_rack (the stand HOLDS what the flask CONTAINS — held containers in chemistry's vocabulary of suspension). The lab's confession that gravity is the constant adversary of careful work
# truth: a clamp stand is the architectural form of MID-AIR ATTENTION. Without it, every reaction would have to happen on the bench surface — flat, splashed, vulnerable. WITH it, the lab can suspend its work in space, free the bench for instruments, free the hands for tools. The pole is not just metal — it is the lab's refusal to let everything fall

## A bench retort stand with parametric clamps.
##
## Built procedurally from DNA exports. Origin is at the bottom center
## of the base (which is also where the pole's foot sits — the pole is
## offset relative to the base center toward -X, so the base extends
## further in +X to balance). Pole rises in +Y; clamps extend in +X.
## When `holding_flask` is true, a stylised small flask is rendered in
## the top clamp's gripper (NOT a full ChemistryFlask instance — a tiny
## representation built inline).

# ── DNA ───────────────────────────────────────────────────────────────

@export_group("Base")
@export var base_width: float = 0.16
@export var base_depth: float = 0.16
@export var base_height: float = 0.02
@export var base_color: Color = Color(0.18, 0.18, 0.20)

@export_group("Pole")
@export var pole_height: float = 0.55
@export var pole_radius: float = 0.008
@export var pole_color: Color = Color(0.80, 0.82, 0.84)

@export_group("Clamps")
## How many clamp arms on the pole (0-3).
@export_range(0, 3) var clamp_count: int = 1
@export var clamp_color: Color = Color(0.28, 0.28, 0.32)

@export_group("Accent")
@export var accent_color: Color = Color(0.95, 0.50, 0.10)

@export_group("Held")
## When true, render a tiny stylised flask held in the topmost clamp.
@export var holding_flask: bool = false

# ── Constants ─────────────────────────────────────────────────────────

const POLE_X_OFFSET_FACTOR: float = 0.30           # vs base_width — pole offset from base center toward -X
const CLAMP_ARM_LENGTH: float = 0.10
const CLAMP_ARM_THICKNESS: float = 0.012
const CLAMP_ARM_HEIGHT: float = 0.012
const CLAMP_JAW_LENGTH: float = 0.04
const CLAMP_JAW_THICKNESS: float = 0.008
const CLAMP_JAW_HEIGHT: float = 0.024
const CLAMP_JAW_GAP: float = 0.026                 # space between the two prong fingers
const ACCENT_STRIP_HEIGHT: float = 0.005
const ACCENT_STRIP_DEPTH: float = 0.004
const HELD_FLASK_BODY_RADIUS: float = 0.022
const HELD_FLASK_BODY_HEIGHT: float = 0.045
const HELD_FLASK_NECK_RADIUS: float = 0.008
const HELD_FLASK_NECK_HEIGHT: float = 0.012

# ── Internal state ────────────────────────────────────────────────────

var _built: bool = false

# ── Lifecycle ─────────────────────────────────────────────────────────

func _ready() -> void:
	_read_metadata_overrides()
	_build_clamp_stand()


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()
	if _built:
		_clear_built_children()
		_built = false
		_build_clamp_stand()


func _read_metadata_overrides() -> void:
	if has_meta("config_base_width"):
		base_width = float(String(get_meta("config_base_width")))
	if has_meta("config_base_depth"):
		base_depth = float(String(get_meta("config_base_depth")))
	if has_meta("config_base_height"):
		base_height = float(String(get_meta("config_base_height")))
	if has_meta("config_base_color"):
		base_color = _parse_color(String(get_meta("config_base_color")), base_color)
	if has_meta("config_pole_height"):
		pole_height = float(String(get_meta("config_pole_height")))
	if has_meta("config_pole_radius"):
		pole_radius = float(String(get_meta("config_pole_radius")))
	if has_meta("config_pole_color"):
		pole_color = _parse_color(String(get_meta("config_pole_color")), pole_color)
	if has_meta("config_clamp_count"):
		clamp_count = int(String(get_meta("config_clamp_count")))
	if has_meta("config_clamp_color"):
		clamp_color = _parse_color(String(get_meta("config_clamp_color")), clamp_color)
	if has_meta("config_accent_color"):
		accent_color = _parse_color(String(get_meta("config_accent_color")), accent_color)
	if has_meta("config_holding_flask"):
		var h := String(get_meta("config_holding_flask")).to_lower()
		holding_flask = h in ["true", "1", "yes", "on"]


func _clear_built_children() -> void:
	for c in get_children():
		c.queue_free()


# ── Build ─────────────────────────────────────────────────────────────

func _build_clamp_stand() -> void:
	_built = true
	# The pole sits at a position offset toward -X from origin; the base
	# is centered on origin and balances the pole's overhang.
	var pole_x: float = -base_width * POLE_X_OFFSET_FACTOR
	_build_base()
	_build_pole(pole_x)
	_build_accent_strip()
	_build_clamps(pole_x)


func _build_base() -> void:
	var base := MeshInstance3D.new()
	base.name = "Base"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(base_width, base_height, base_depth)
	base.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = base_color
	mat.roughness = 0.55
	mat.metallic = 0.45
	base.material_override = mat
	base.position = Vector3(0.0, base_height * 0.5, 0.0)
	add_child(base)


func _build_pole(pole_x: float) -> void:
	var pole := MeshInstance3D.new()
	pole.name = "Pole"
	var mesh := CylinderMesh.new()
	mesh.top_radius = pole_radius
	mesh.bottom_radius = pole_radius
	mesh.height = pole_height
	pole.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = pole_color
	mat.roughness = 0.35
	mat.metallic = 0.75
	pole.material_override = mat
	pole.position = Vector3(pole_x, base_height + pole_height * 0.5, 0.0)
	add_child(pole)


func _build_accent_strip() -> void:
	# Thin accent stripe wrapping the front +Z edge of the base.
	var strip := MeshInstance3D.new()
	strip.name = "AccentStrip"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(base_width * 0.92, ACCENT_STRIP_HEIGHT, ACCENT_STRIP_DEPTH)
	strip.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = accent_color
	mat.emission_enabled = true
	mat.emission = accent_color
	mat.emission_energy_multiplier = 1.6
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	strip.material_override = mat
	strip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Wrap around the +Z edge of the base, near the top of the base.
	var y: float = base_height - ACCENT_STRIP_HEIGHT * 0.5
	var z: float = base_depth * 0.5 + ACCENT_STRIP_DEPTH * 0.5
	strip.position = Vector3(0.0, y, z)
	add_child(strip)


func _build_clamps(pole_x: float) -> void:
	if clamp_count <= 0:
		return
	# Evenly space clamps along the upper 2/3 of the pole.
	# Top clamp gets the held flask if holding_flask=true.
	var spacing_low: float = pole_height * 0.35
	var spacing_high: float = pole_height * 0.92
	for i in range(clamp_count):
		var t: float
		if clamp_count == 1:
			t = 0.75
		else:
			t = float(i) / float(clamp_count - 1)
		var clamp_y: float = base_height + lerp(spacing_low, spacing_high, t)
		var is_top: bool = (i == clamp_count - 1)
		_build_single_clamp(pole_x, clamp_y, is_top and holding_flask)


# Build a single clamp at (pole_x, clamp_y) extending in +X.
# If hold_flask is true, add the stylised flask in the gripper.
func _build_single_clamp(pole_x: float, clamp_y: float, hold_flask: bool) -> void:
	var clamp_root := Node3D.new()
	clamp_root.name = "Clamp"
	clamp_root.position = Vector3(pole_x, clamp_y, 0.0)
	add_child(clamp_root)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = clamp_color
	mat.roughness = 0.45
	mat.metallic = 0.55

	# Arm — horizontal bar extending in +X from the pole.
	var arm := MeshInstance3D.new()
	arm.name = "Arm"
	var arm_mesh := BoxMesh.new()
	arm_mesh.size = Vector3(CLAMP_ARM_LENGTH, CLAMP_ARM_HEIGHT, CLAMP_ARM_THICKNESS)
	arm.mesh = arm_mesh
	arm.material_override = mat
	# Position so the arm starts at the pole surface and extends in +X.
	arm.position = Vector3(pole_radius + CLAMP_ARM_LENGTH * 0.5, 0.0, 0.0)
	clamp_root.add_child(arm)

	# Two parallel jaw fingers at the end of the arm — gripper.
	var jaw_x: float = pole_radius + CLAMP_ARM_LENGTH + CLAMP_JAW_LENGTH * 0.5
	var jaw_offsets := [CLAMP_JAW_GAP * 0.5, -CLAMP_JAW_GAP * 0.5]
	for j in range(2):
		var jaw := MeshInstance3D.new()
		jaw.name = "Jaw_%d" % j
		var jmesh := BoxMesh.new()
		jmesh.size = Vector3(CLAMP_JAW_LENGTH, CLAMP_JAW_HEIGHT, CLAMP_JAW_THICKNESS)
		jaw.mesh = jmesh
		jaw.material_override = mat
		jaw.position = Vector3(jaw_x, 0.0, jaw_offsets[j])
		clamp_root.add_child(jaw)

	# Optional held flask between the two jaws.
	if hold_flask:
		_build_held_flask(clamp_root, jaw_x)


# A tiny stylised Erlenmeyer flask: small cone-like cylinder body + tiny neck.
# Sized to fit between the jaws of the gripper.
func _build_held_flask(parent: Node3D, jaw_x: float) -> void:
	# Glass material, slightly tinted.
	var glass_mat := StandardMaterial3D.new()
	glass_mat.albedo_color = Color(0.85, 0.92, 0.95, 0.50)
	glass_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass_mat.roughness = 0.15
	glass_mat.metallic = 0.05

	# Body — tapered cylinder.
	var body := MeshInstance3D.new()
	body.name = "HeldFlaskBody"
	var bmesh := CylinderMesh.new()
	bmesh.bottom_radius = HELD_FLASK_BODY_RADIUS
	bmesh.top_radius = HELD_FLASK_NECK_RADIUS
	bmesh.height = HELD_FLASK_BODY_HEIGHT
	body.mesh = bmesh
	body.material_override = glass_mat
	# Centered between the jaws (y=0), hanging slightly below the clamp arm.
	# Place so the flask body center is at y = -HELD_FLASK_BODY_HEIGHT*0.5 (hangs down).
	body.position = Vector3(jaw_x, -HELD_FLASK_BODY_HEIGHT * 0.5 - 0.005, 0.0)
	parent.add_child(body)

	# Neck — small cylinder above the body (between the jaws).
	var neck := MeshInstance3D.new()
	neck.name = "HeldFlaskNeck"
	var nmesh := CylinderMesh.new()
	nmesh.top_radius = HELD_FLASK_NECK_RADIUS
	nmesh.bottom_radius = HELD_FLASK_NECK_RADIUS
	nmesh.height = HELD_FLASK_NECK_HEIGHT
	neck.mesh = nmesh
	neck.material_override = glass_mat
	neck.position = Vector3(jaw_x, HELD_FLASK_NECK_HEIGHT * 0.5 - 0.005, 0.0)
	parent.add_child(neck)

	# A small bit of content in the body — emerald.
	var content := MeshInstance3D.new()
	content.name = "HeldFlaskContent"
	var cmesh := CylinderMesh.new()
	cmesh.bottom_radius = HELD_FLASK_BODY_RADIUS * 0.90
	cmesh.top_radius = HELD_FLASK_BODY_RADIUS * 0.55
	cmesh.height = HELD_FLASK_BODY_HEIGHT * 0.55
	content.mesh = cmesh
	var cmat := StandardMaterial3D.new()
	cmat.albedo_color = Color(0.30, 0.85, 0.55, 0.85)
	cmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	cmat.roughness = 0.25
	cmat.emission_enabled = true
	cmat.emission = Color(0.30, 0.85, 0.55)
	cmat.emission_energy_multiplier = 0.3
	cmat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	content.material_override = cmat
	# Position content at the bottom of the body.
	var content_center_y: float = -HELD_FLASK_BODY_HEIGHT - 0.005 + HELD_FLASK_BODY_HEIGHT * 0.55 * 0.5
	content.position = Vector3(jaw_x, content_center_y, 0.0)
	parent.add_child(content)


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
