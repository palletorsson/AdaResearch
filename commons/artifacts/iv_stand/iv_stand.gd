extends Node3D
class_name IVStand

# @identity
# essence: a wheeled medical IV pole with a hanging bag — hospital / clinic vocabulary. A round dark-steel base disc with 4-6 small caster wheels around its perimeter, a tall glossy-steel vertical pole rising from the base center, a small L-shaped hook at the top, an optional translucent IV bag hanging from the hook with amber fluid filling part of it, a small "IV" Label3D on the bag, and a Portal-orange accent ring around the base. The architectural form of MEDICATION-IN-MOTION
# desire: every clinic wants a way to keep a continuous drip BESIDE the body — to follow the patient between bed and chair and corridor without disconnecting the line. The IV stand wants to be the architectural form of MOBILE INFUSION. The wheels make it portable; the pole makes it tall; the hook makes it ready to receive a bag. It is gravity weaponised for medicine
# critical_parameter: bag_visible — TRUE reads as IN-USE (this stand is currently delivering, hooked to a patient). FALSE reads as STAGED-AND-WAITING (cleaned, parked, ready for the next bag). The bag is the difference between MEDICATION-IN-PROGRESS and EQUIPMENT-AT-REST. Same pole, two phases of the clinical cycle
# triggers: _ready() builds base disc + wheels + pole + L-hook + optional bag (translucent with internal fluid level) + Label3D + accent ring; apply_grid_config rebuilds
# emerges: bag with high bag_full_fraction = "just hung, full dose ahead". Bag near empty = "almost done, change soon". Bag invisible = "between patients". Wheels visible at base = "this can roll with the patient". Same script, four narratives of clinical use
# needs: round base disc [present]; wheel_count small caster wheels around the perimeter [present]; vertical pole from base center [present]; L-shaped hook at top of pole [present]; optional translucent bag hanging from hook [present]; bag content filling bag_full_fraction of the interior [present]; "IV" Label3D on the bag [present]; accent ring around the base [present]
# relationships: peer to safety_shower (both = wall-of-the-clinic safety-net equipment, but the shower is fixed and the stand is mobile — vocabularies of EMERGENCY vs CONTINUOUS-CARE). Sibling to chemistry_flask (both = container-of-fluid-with-label, but the flask is bench-top static and the stand is hospital-mobile). Cousin to autoclave + glove_box (the lab's medical-adjacent vocabulary of CARE-OF-BODIES through STERILE-INSTRUMENTS). The architectural admission that the clinic IS a moving choreography of held-fluids
# truth: an IV stand is the architectural form of THE BODY TETHERED TO ITS MEDICINE THROUGH GRAVITY. The pole's height matters: above the heart, so the drip flows down. The wheels matter: the patient must be able to walk to the bathroom without disconnecting. The L-hook matters: the bag must hang free, swinging slightly with motion, not pinned. The whole thing is a refusal to let the line be broken just because the body needs to move

## A wheeled medical IV pole with hanging bag.
##
## Built procedurally from DNA exports. Origin is at the bottom center
## of the base disc, on the floor. Pole rises in +Y. The L-shaped hook
## at the top extends in +X. The bag (when visible) hangs in -Y from
## the hook. The bag's label faces +Z (default Label3D orientation).

# ── DNA ───────────────────────────────────────────────────────────────

@export_group("Pole")
## Top of pole from the floor — total height of the stand.
@export var pole_height: float = 1.6
@export var pole_color: Color = Color(0.86, 0.86, 0.88)

@export_group("Base")
@export var base_radius: float = 0.25
@export_range(4, 6) var wheel_count: int = 5

@export_group("Hook")
@export var hook_color: Color = Color(0.20, 0.20, 0.24)

@export_group("Bag")
@export var bag_visible: bool = true
## Faint translucent — clinical bag plastic.
@export var bag_color: Color = Color(0.90, 0.95, 0.98, 0.55)
## IV fluid amber — saline/medication.
@export var bag_content_color: Color = Color(0.95, 0.80, 0.45, 0.92)
@export_range(0.0, 1.0) var bag_full_fraction: float = 0.75

@export_group("Accent")
@export var accent_color: Color = Color(0.95, 0.50, 0.10)

@export_group("Label")
@export var label_text: String = "IV"
@export var label_color: Color = Color(0.98, 0.98, 0.98)

# ── Constants ─────────────────────────────────────────────────────────

const BASE_DISC_HEIGHT: float = 0.03
const BASE_COLOR_DARK: Color = Color(0.20, 0.20, 0.24)
const WHEEL_RADIUS: float = 0.028
const WHEEL_THICKNESS: float = 0.018
const POLE_RADIUS: float = 0.011
const HOOK_ARM_LENGTH: float = 0.10
const HOOK_DROP_LENGTH: float = 0.05
const HOOK_THICKNESS: float = 0.010
const BAG_WIDTH: float = 0.14
const BAG_HEIGHT: float = 0.22
const BAG_DEPTH: float = 0.04
const ACCENT_STRIP_HEIGHT: float = 0.008
const ACCENT_STRIP_DEPTH: float = 0.005
const LABEL_PIXEL_SIZE: float = 0.0035
const LABEL_FONT_SIZE: int = 32

# ── Internal state ────────────────────────────────────────────────────

var _built: bool = false

# ── Lifecycle ─────────────────────────────────────────────────────────

func _ready() -> void:
	_read_metadata_overrides()
	_build_stand()


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()
	if _built:
		_clear_built_children()
		_built = false
		_build_stand()


func _read_metadata_overrides() -> void:
	if has_meta("config_pole_height"):
		pole_height = float(String(get_meta("config_pole_height")))
	if has_meta("config_base_radius"):
		base_radius = float(String(get_meta("config_base_radius")))
	if has_meta("config_wheel_count"):
		wheel_count = int(String(get_meta("config_wheel_count")))
	if has_meta("config_pole_color"):
		pole_color = _parse_color(String(get_meta("config_pole_color")), pole_color)
	if has_meta("config_bag_color"):
		bag_color = _parse_color(String(get_meta("config_bag_color")), bag_color)
	if has_meta("config_bag_content_color"):
		bag_content_color = _parse_color(String(get_meta("config_bag_content_color")), bag_content_color)
	if has_meta("config_bag_visible"):
		var b := String(get_meta("config_bag_visible")).to_lower()
		bag_visible = b in ["true", "1", "yes", "on"]
	if has_meta("config_bag_full_fraction"):
		bag_full_fraction = float(String(get_meta("config_bag_full_fraction")))
	if has_meta("config_hook_color"):
		hook_color = _parse_color(String(get_meta("config_hook_color")), hook_color)
	if has_meta("config_accent_color"):
		accent_color = _parse_color(String(get_meta("config_accent_color")), accent_color)
	if has_meta("config_label_text"):
		label_text = String(get_meta("config_label_text"))
	if has_meta("config_label_color"):
		label_color = _parse_color(String(get_meta("config_label_color")), label_color)


func _clear_built_children() -> void:
	for c in get_children():
		c.queue_free()


# ── Build ─────────────────────────────────────────────────────────────

func _build_stand() -> void:
	_built = true
	_build_base()
	_build_wheels()
	_build_accent_ring()
	_build_pole()
	_build_hook()
	if bag_visible:
		_build_bag()


func _build_base() -> void:
	var base := MeshInstance3D.new()
	base.name = "Base"
	var mesh := CylinderMesh.new()
	mesh.top_radius = base_radius
	mesh.bottom_radius = base_radius
	mesh.height = BASE_DISC_HEIGHT
	base.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = BASE_COLOR_DARK
	mat.roughness = 0.45
	mat.metallic = 0.55
	base.material_override = mat
	base.position = Vector3(0.0, BASE_DISC_HEIGHT * 0.5 + WHEEL_RADIUS, 0.0)
	add_child(base)


func _build_wheels() -> void:
	var wheels_root := Node3D.new()
	wheels_root.name = "Wheels"
	add_child(wheels_root)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.10, 0.10, 0.12)
	mat.roughness = 0.65
	mat.metallic = 0.25
	# Place wheels evenly around the base perimeter, inset slightly.
	var wheel_ring_r: float = base_radius - WHEEL_RADIUS * 0.5
	for i in range(wheel_count):
		var angle: float = TAU * float(i) / float(wheel_count)
		var wheel := MeshInstance3D.new()
		wheel.name = "Wheel_%d" % i
		var mesh := CylinderMesh.new()
		mesh.top_radius = WHEEL_RADIUS
		mesh.bottom_radius = WHEEL_RADIUS
		mesh.height = WHEEL_THICKNESS
		wheel.mesh = mesh
		wheel.material_override = mat
		# Cylinder default axis is +Y; rotate so axis points tangentially to the ring (rolls forward).
		# The wheel's axis should be perpendicular to the radial vector from center.
		# A wheel at angle theta has radial direction (cos, sin); the rolling axis is perpendicular: (-sin, cos).
		# Rotate the cylinder so its +Y points along that perpendicular vector in the XZ plane.
		# Tilt: first rotate around Z by 90° to lay flat (axis -> +X), then rotate around Y by angle so axis aligns.
		wheel.rotation = Vector3(0.0, angle, deg_to_rad(90.0))
		wheel.position = Vector3(
			cos(angle) * wheel_ring_r,
			WHEEL_RADIUS,
			sin(angle) * wheel_ring_r
		)
		wheels_root.add_child(wheel)


func _build_accent_ring() -> void:
	# Thin emissive ring around the top edge of the base disc.
	var ring := MeshInstance3D.new()
	ring.name = "AccentRing"
	var mesh := TorusMesh.new()
	mesh.inner_radius = base_radius * 0.95
	mesh.outer_radius = base_radius * 0.99
	ring.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = accent_color
	mat.emission_enabled = true
	mat.emission = accent_color
	mat.emission_energy_multiplier = 1.5
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	ring.material_override = mat
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Sit on top of the base disc (torus default lies in XY plane; needs rotation around X by 90° to lie flat in XZ).
	ring.rotation = Vector3(deg_to_rad(90.0), 0.0, 0.0)
	ring.position = Vector3(0.0, BASE_DISC_HEIGHT + WHEEL_RADIUS + 0.004, 0.0)
	add_child(ring)


func _build_pole() -> void:
	# Pole runs from top of base disc up to pole_height.
	var pole_base_y: float = BASE_DISC_HEIGHT + WHEEL_RADIUS
	var pole_len: float = pole_height - pole_base_y
	if pole_len <= 0.0:
		return
	var pole := MeshInstance3D.new()
	pole.name = "Pole"
	var mesh := CylinderMesh.new()
	mesh.top_radius = POLE_RADIUS
	mesh.bottom_radius = POLE_RADIUS
	mesh.height = pole_len
	pole.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = pole_color
	mat.roughness = 0.30
	mat.metallic = 0.80
	pole.material_override = mat
	pole.position = Vector3(0.0, pole_base_y + pole_len * 0.5, 0.0)
	add_child(pole)


func _build_hook() -> void:
	# L-shape: a horizontal arm extending in +X from the top of the pole,
	# then a short vertical drop pointing down -Y from the arm's tip.
	var hook_root := Node3D.new()
	hook_root.name = "Hook"
	hook_root.position = Vector3(0.0, pole_height, 0.0)
	add_child(hook_root)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = hook_color
	mat.roughness = 0.40
	mat.metallic = 0.70

	# Horizontal arm.
	var arm := MeshInstance3D.new()
	arm.name = "Arm"
	var amesh := BoxMesh.new()
	amesh.size = Vector3(HOOK_ARM_LENGTH, HOOK_THICKNESS, HOOK_THICKNESS)
	arm.mesh = amesh
	arm.material_override = mat
	arm.position = Vector3(HOOK_ARM_LENGTH * 0.5, -HOOK_THICKNESS * 0.5, 0.0)
	hook_root.add_child(arm)

	# Vertical drop at the +X tip of the arm, pointing down.
	var drop := MeshInstance3D.new()
	drop.name = "Drop"
	var dmesh := BoxMesh.new()
	dmesh.size = Vector3(HOOK_THICKNESS, HOOK_DROP_LENGTH, HOOK_THICKNESS)
	drop.mesh = dmesh
	drop.material_override = mat
	drop.position = Vector3(HOOK_ARM_LENGTH - HOOK_THICKNESS * 0.5, -HOOK_DROP_LENGTH * 0.5, 0.0)
	hook_root.add_child(drop)


func _build_bag() -> void:
	# The bag hangs below the hook's drop, centered along the hook arm's tip.
	# Hook tip world position: (HOOK_ARM_LENGTH - HOOK_THICKNESS*0.5, pole_height - HOOK_DROP_LENGTH, 0).
	var bag_top_y: float = pole_height - HOOK_DROP_LENGTH - HOOK_THICKNESS * 0.5
	var bag_center_x: float = HOOK_ARM_LENGTH - HOOK_THICKNESS * 0.5
	var bag_center_y: float = bag_top_y - BAG_HEIGHT * 0.5
	var bag_z: float = 0.0

	# Bag shell — translucent BoxMesh.
	var bag := MeshInstance3D.new()
	bag.name = "Bag"
	var bmesh := BoxMesh.new()
	bmesh.size = Vector3(BAG_WIDTH, BAG_HEIGHT, BAG_DEPTH)
	bag.mesh = bmesh
	var bmat := StandardMaterial3D.new()
	bmat.albedo_color = bag_color
	bmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bmat.roughness = 0.20
	bmat.metallic = 0.0
	bag.material_override = bmat
	bag.position = Vector3(bag_center_x, bag_center_y, bag_z)
	add_child(bag)

	# Content inside the bag — smaller BoxMesh filling bag_full_fraction of the interior height,
	# settled at the bottom.
	if bag_full_fraction > 0.0:
		var inner_w: float = BAG_WIDTH * 0.86
		var inner_d: float = BAG_DEPTH * 0.55
		var inner_max_h: float = BAG_HEIGHT * 0.92
		var content_h: float = inner_max_h * bag_full_fraction
		var content := MeshInstance3D.new()
		content.name = "BagContent"
		var cmesh := BoxMesh.new()
		cmesh.size = Vector3(inner_w, content_h, inner_d)
		content.mesh = cmesh
		var cmat := StandardMaterial3D.new()
		cmat.albedo_color = bag_content_color
		cmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		cmat.roughness = 0.30
		cmat.emission_enabled = true
		cmat.emission = bag_content_color
		cmat.emission_energy_multiplier = 0.25
		cmat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
		content.material_override = cmat
		# Content settles at the bottom of the bag interior.
		var content_bottom: float = bag_center_y - BAG_HEIGHT * 0.46
		content.position = Vector3(bag_center_x, content_bottom + content_h * 0.5, bag_z)
		add_child(content)

	# Label on the +Z face of the bag, default Label3D rotation (faces +Z).
	if label_text != "":
		var label := Label3D.new()
		label.name = "BagLabel"
		label.text = label_text
		label.font_size = LABEL_FONT_SIZE
		label.outline_size = 3
		label.pixel_size = LABEL_PIXEL_SIZE
		label.modulate = label_color
		label.outline_modulate = Color(0.10, 0.06, 0.04)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.position = Vector3(bag_center_x, bag_center_y + BAG_HEIGHT * 0.25, bag_z + BAG_DEPTH * 0.5 + 0.005)
		add_child(label)


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
