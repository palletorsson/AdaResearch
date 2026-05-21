extends Node3D
class_name GasCanister

# @identity
# essence: a pressurised gas cylinder on a cradle — industrial-corridor / hospital-supply vocabulary. A tall teal cylinder with a tapered dark-steel shoulder cap on top, a small valve assembly (boxy housing + red wheel handle + angled spout) at the very top, a label naming the contained gas ("O₂") on the front, a small emissive pressure indicator beside the valve when pressurised, and a dark-steel cradle — either a vertical stand with a ring the canister sits in, or a horizontal cradle of two arched supports the canister lies across
# desire: every lab wants a way to make INVISIBLE FORCE visible. The canister wants to be the architectural form of HELD PRESSURE. Heavy, named, with a colour code for what is inside. The valve at the top is the threshold between contained and released — the place where the question of WHAT this gas IS becomes practical
# critical_parameter: cradle_style — "vertical" reads as RACK-STORED, AT-THE-READY (the canister waits for use). "horizontal" reads as IN-RESERVE, OFF-CIRCUIT (the canister is being kept until it is needed). Same canister, two different positions in the lab's economy of consumables
# triggers: _ready() builds cradle (vertical or horizontal) + canister body + shoulder cap + valve housing + red wheel + spout + label + pressure indicator; apply_grid_config rebuilds
# emerges: vertical-cradled canister reads ACTIVE, NEAR-USE. Horizontal-cradled canister reads STORED, COOLED, AWAITING. Pressure indicator on = "this one still has it". Off = "this one is spent — replace soon". Same shell, four states of being-stocked
# needs: cylindrical body in colour code [present]; tapered shoulder cap [present]; valve housing box [present]; red wheel handle [present]; angled spout [present]; label naming the gas [present]; cradle (vertical stand OR horizontal arched supports) [present]; optional emissive pressure dot [present]
# relationships: peer to fume_hood (canister = source of contained reactivity; hood = location of contained reactivity); sibling to fire_extinguisher (both = pressurised cylinders with red parts, but the extinguisher RELEASES, the canister SUPPLIES); cousin to specimen_jar (both encode contents through colour code and label — what is inside is given by what is outside); the lab's vocabulary of GAS PHASE INPUTS
# truth: a gas canister is the architectural form of CONTAINED PRESSURE WAITING TO ENTER THE WORK. The colour code names the gas; the valve names the threshold; the cradle names the patience. Without the canister, the lab pretends its inputs are all solid and liquid. WITH it, the lab admits that some of what it needs to think with arrives as gas — invisible, weight-less, requiring containment to even exist for the body

## A pressurised gas cylinder on a steel cradle.
##
## Built procedurally from DNA exports. Origin is at the bottom center
## of the cradle, on the floor. Body faces +Z (label readable from +Z).
## When `cradle_style == "horizontal"`, the canister lies on its side
## across two arched supports along the +X axis; when "vertical", the
## canister stands upright in a ring on a base plate.

# ── DNA ───────────────────────────────────────────────────────────────

@export_group("Dimensions")
@export var canister_height: float = 0.85
@export var canister_radius: float = 0.13

@export_group("Color")
## Light teal — the canonical oxygen / medical gas colour.
@export var body_color: Color = Color(0.20, 0.55, 0.65)
@export var cap_color: Color = Color(0.22, 0.22, 0.24)        # dark steel shoulder
@export var cradle_color: Color = Color(0.22, 0.22, 0.24)
@export var valve_handle_color: Color = Color(0.78, 0.08, 0.08)   # alarm red wheel
@export var label_color: Color = Color(0.98, 0.98, 0.98)

@export_group("Label")
@export var label_text: String = "O₂"

@export_group("Cradle")
## "vertical" — base plate + ring around bottom of canister (canister stands).
## "horizontal" — two arched supports the canister lies across.
@export var cradle_style: String = "vertical"

@export_group("Pressure")
@export var pressure_indicator: bool = true
## Safety green — canister has pressure.
@export var pressure_color: Color = Color(0.30, 0.85, 0.40)

# ── Constants ─────────────────────────────────────────────────────────

const CRADLE_BASE_HEIGHT: float = 0.04
const CRADLE_BASE_WIDTH_FACTOR: float = 1.9    # vs canister_radius
const CRADLE_RING_THICKNESS: float = 0.018
const CRADLE_RING_RADIUS_FACTOR: float = 1.18  # vs canister_radius
const SHOULDER_HEIGHT_FACTOR: float = 0.12      # vs canister_height
const SHOULDER_TOP_RADIUS_FACTOR: float = 0.55  # vs canister_radius
const VALVE_HOUSING_SIZE: Vector3 = Vector3(0.07, 0.06, 0.05)
const WHEEL_RADIUS: float = 0.035
const WHEEL_THICKNESS: float = 0.012
const SPOUT_LENGTH: float = 0.07
const SPOUT_RADIUS: float = 0.012
const PRESSURE_DOT_RADIUS: float = 0.011
const LABEL_PIXEL_SIZE: float = 0.0030
const LABEL_FONT_SIZE: int = 44
const HORIZONTAL_SUPPORT_WIDTH: float = 0.06
const HORIZONTAL_SUPPORT_HEIGHT_FACTOR: float = 1.1   # vs canister_radius
const HORIZONTAL_SUPPORT_DEPTH: float = 0.05

# ── Internal state ────────────────────────────────────────────────────

var _built: bool = false

# ── Lifecycle ─────────────────────────────────────────────────────────

func _ready() -> void:
	_read_metadata_overrides()
	_build_canister()


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()
	if _built:
		_clear_built_children()
		_built = false
		_build_canister()


func _read_metadata_overrides() -> void:
	if has_meta("config_canister_height"):
		canister_height = float(String(get_meta("config_canister_height")))
	if has_meta("config_canister_radius"):
		canister_radius = float(String(get_meta("config_canister_radius")))
	if has_meta("config_body_color"):
		body_color = _parse_color(String(get_meta("config_body_color")), body_color)
	if has_meta("config_cap_color"):
		cap_color = _parse_color(String(get_meta("config_cap_color")), cap_color)
	if has_meta("config_cradle_color"):
		cradle_color = _parse_color(String(get_meta("config_cradle_color")), cradle_color)
	if has_meta("config_valve_handle_color"):
		valve_handle_color = _parse_color(String(get_meta("config_valve_handle_color")), valve_handle_color)
	if has_meta("config_label_color"):
		label_color = _parse_color(String(get_meta("config_label_color")), label_color)
	if has_meta("config_label_text"):
		label_text = String(get_meta("config_label_text"))
	if has_meta("config_cradle_style"):
		cradle_style = String(get_meta("config_cradle_style")).to_lower()
	if has_meta("config_pressure_indicator"):
		var pi := String(get_meta("config_pressure_indicator")).to_lower()
		pressure_indicator = pi in ["true", "1", "yes", "on"]
	if has_meta("config_pressure_color"):
		pressure_color = _parse_color(String(get_meta("config_pressure_color")), pressure_color)


func _clear_built_children() -> void:
	for c in get_children():
		c.queue_free()


# ── Build ─────────────────────────────────────────────────────────────

func _build_canister() -> void:
	_built = true
	match cradle_style:
		"horizontal":
			_build_horizontal_arrangement()
		_:
			_build_vertical_arrangement()


# Vertical arrangement: base + ring + standing canister + valve on top.
func _build_vertical_arrangement() -> void:
	# Cradle base plate.
	var base := MeshInstance3D.new()
	base.name = "CradleBase"
	var bm := BoxMesh.new()
	var bw: float = canister_radius * CRADLE_BASE_WIDTH_FACTOR
	bm.size = Vector3(bw, CRADLE_BASE_HEIGHT, bw)
	base.mesh = bm
	var bmat := StandardMaterial3D.new()
	bmat.albedo_color = cradle_color
	bmat.roughness = 0.5
	bmat.metallic = 0.5
	base.material_override = bmat
	base.position = Vector3(0.0, CRADLE_BASE_HEIGHT * 0.5, 0.0)
	add_child(base)

	# Cradle ring (TorusMesh) — sits on top of the base, canister bottom passes through.
	var ring := MeshInstance3D.new()
	ring.name = "CradleRing"
	var tm := TorusMesh.new()
	var ring_r: float = canister_radius * CRADLE_RING_RADIUS_FACTOR
	tm.inner_radius = ring_r - CRADLE_RING_THICKNESS
	tm.outer_radius = ring_r
	ring.mesh = tm
	ring.material_override = bmat
	ring.position = Vector3(0.0, CRADLE_BASE_HEIGHT + CRADLE_RING_THICKNESS * 0.5, 0.0)
	add_child(ring)

	# Canister body — bottom sits on the base.
	var canister_y0: float = CRADLE_BASE_HEIGHT
	_build_body(canister_y0, false)


# Horizontal arrangement: two arched supports along +X, canister lies on its side.
func _build_horizontal_arrangement() -> void:
	var support_h: float = canister_radius * HORIZONTAL_SUPPORT_HEIGHT_FACTOR
	var supports_root := Node3D.new()
	supports_root.name = "Supports"
	add_child(supports_root)

	var smat := StandardMaterial3D.new()
	smat.albedo_color = cradle_color
	smat.roughness = 0.5
	smat.metallic = 0.5

	# Two supports — one near each end of the canister along the X axis (length = canister_height).
	var spacing: float = canister_height * 0.55
	for sign_x in [-1, 1]:
		var sup := MeshInstance3D.new()
		sup.name = "Support_%d" % sign_x
		var box := BoxMesh.new()
		box.size = Vector3(HORIZONTAL_SUPPORT_WIDTH, support_h, HORIZONTAL_SUPPORT_DEPTH)
		sup.mesh = box
		sup.material_override = smat
		sup.position = Vector3(spacing * 0.5 * float(sign_x), support_h * 0.5, 0.0)
		supports_root.add_child(sup)

		# A small cradle arch on top of each support — narrow torus piece visually approximated by a thin ring.
		var arch := MeshInstance3D.new()
		arch.name = "Arch_%d" % sign_x
		var tm := TorusMesh.new()
		tm.inner_radius = canister_radius * 0.95
		tm.outer_radius = canister_radius * 1.10
		arch.mesh = tm
		arch.material_override = smat
		# Tilt torus so it sits like a saddle (rotation around X by 90°).
		arch.rotation = Vector3(deg_to_rad(90.0), 0.0, 0.0)
		arch.position = Vector3(spacing * 0.5 * float(sign_x), support_h, 0.0)
		supports_root.add_child(arch)

	# Canister body — laid on its side along +X. Bottom of canister at support_h.
	var canister_center_y: float = support_h + canister_radius * 0.0
	_build_body(canister_center_y, true)


# Build the canister body (and cap + valve + label + pressure dot) given a base y and orientation.
# When `horizontal` is true, the canister axis runs along +X; otherwise along +Y.
func _build_body(y_base: float, horizontal: bool) -> void:
	# Body cylinder.
	var body := MeshInstance3D.new()
	body.name = "Body"
	var bm := CylinderMesh.new()
	bm.top_radius = canister_radius
	bm.bottom_radius = canister_radius * 1.005
	bm.height = canister_height
	body.mesh = bm
	var bmat := StandardMaterial3D.new()
	bmat.albedo_color = body_color
	bmat.roughness = 0.32
	bmat.metallic = 0.45
	body.material_override = bmat

	# Shoulder cap — tapered cylinder above the body, with smaller top radius.
	var cap := MeshInstance3D.new()
	cap.name = "Cap"
	var cm := CylinderMesh.new()
	var shoulder_h: float = canister_height * SHOULDER_HEIGHT_FACTOR
	cm.top_radius = canister_radius * SHOULDER_TOP_RADIUS_FACTOR
	cm.bottom_radius = canister_radius
	cm.height = shoulder_h
	cap.mesh = cm
	var cmat := StandardMaterial3D.new()
	cmat.albedo_color = cap_color
	cmat.roughness = 0.4
	cmat.metallic = 0.7
	cap.material_override = cmat

	# Valve housing — small box atop the shoulder cap.
	var valve_box := MeshInstance3D.new()
	valve_box.name = "ValveHousing"
	var vbm := BoxMesh.new()
	vbm.size = VALVE_HOUSING_SIZE
	valve_box.mesh = vbm
	var vbmat := StandardMaterial3D.new()
	vbmat.albedo_color = cap_color
	vbmat.roughness = 0.45
	vbmat.metallic = 0.65
	valve_box.material_override = vbmat

	# Wheel handle — thin torus rotated to lie flat.
	var wheel := MeshInstance3D.new()
	wheel.name = "ValveWheel"
	var wtm := TorusMesh.new()
	wtm.inner_radius = WHEEL_RADIUS - WHEEL_THICKNESS
	wtm.outer_radius = WHEEL_RADIUS
	wheel.mesh = wtm
	var wmat := StandardMaterial3D.new()
	wmat.albedo_color = valve_handle_color
	wmat.roughness = 0.42
	wmat.metallic = 0.3
	wheel.material_override = wmat

	# Spout — angled cylinder.
	var spout := MeshInstance3D.new()
	spout.name = "ValveSpout"
	var sm := CylinderMesh.new()
	sm.top_radius = SPOUT_RADIUS * 0.7
	sm.bottom_radius = SPOUT_RADIUS
	sm.height = SPOUT_LENGTH
	spout.mesh = sm
	var smat := StandardMaterial3D.new()
	smat.albedo_color = cap_color.lerp(Color(0.55, 0.55, 0.58), 0.2)
	smat.roughness = 0.4
	smat.metallic = 0.75
	spout.material_override = smat

	# Pressure indicator (small emissive sphere).
	var dot: MeshInstance3D = null
	if pressure_indicator:
		dot = MeshInstance3D.new()
		dot.name = "PressureDot"
		var sphm := SphereMesh.new()
		sphm.radius = PRESSURE_DOT_RADIUS
		sphm.height = PRESSURE_DOT_RADIUS * 2.0
		dot.mesh = sphm
		var dmat := StandardMaterial3D.new()
		dmat.albedo_color = pressure_color
		dmat.emission_enabled = true
		dmat.emission = pressure_color
		dmat.emission_energy_multiplier = 2.2
		dmat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
		dot.material_override = dmat
		dot.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	# Label.
	var label: Label3D = null
	if label_text != "":
		label = Label3D.new()
		label.name = "Label"
		label.text = label_text
		label.font_size = LABEL_FONT_SIZE
		label.outline_size = 4
		label.pixel_size = LABEL_PIXEL_SIZE
		label.modulate = label_color
		label.outline_modulate = Color(0.05, 0.10, 0.13)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	if horizontal:
		# Canister axis runs along +X — rotate body and cap 90° around Z.
		var z_rot: float = deg_to_rad(90.0)

		body.rotation = Vector3(0.0, 0.0, z_rot)
		body.position = Vector3(0.0, y_base, 0.0)
		add_child(body)

		# Cap at +X end of the body. Local cylinder's +Y -> world +X when rotated 90° around Z.
		cap.rotation = Vector3(0.0, 0.0, z_rot)
		cap.position = Vector3(canister_height * 0.5 + shoulder_h * 0.5, y_base, 0.0)
		add_child(cap)

		# Valve assembly extends further along +X from the cap.
		var top_x: float = canister_height * 0.5 + shoulder_h
		valve_box.position = Vector3(top_x + VALVE_HOUSING_SIZE.x * 0.5, y_base, 0.0)
		add_child(valve_box)

		# Wheel on top of valve box (in horizontal mode, "top" = +Y).
		wheel.rotation = Vector3(deg_to_rad(90.0), 0.0, 0.0)
		wheel.position = Vector3(
			top_x + VALVE_HOUSING_SIZE.x * 0.5,
			y_base + VALVE_HOUSING_SIZE.y * 0.5 + WHEEL_THICKNESS * 0.5,
			0.0
		)
		add_child(wheel)

		# Spout angles down-and-forward off the valve box (toward +Z, slight -Y).
		var spout_rot: float = deg_to_rad(35.0)
		spout.rotation = Vector3(spout_rot, 0.0, 0.0)
		spout.position = Vector3(
			top_x + VALVE_HOUSING_SIZE.x * 0.5,
			y_base + VALVE_HOUSING_SIZE.y * 0.1,
			VALVE_HOUSING_SIZE.z * 0.5 + SPOUT_LENGTH * 0.35
		)
		add_child(spout)

		# Pressure dot near valve, on the +Z side.
		if dot:
			dot.position = Vector3(
				top_x + VALVE_HOUSING_SIZE.x * 0.25,
				y_base + VALVE_HOUSING_SIZE.y * 0.45,
				VALVE_HOUSING_SIZE.z * 0.5 + PRESSURE_DOT_RADIUS * 0.9
			)
			add_child(dot)

		# Label on the +Z side of the body.
		if label:
			label.position = Vector3(0.0, y_base, canister_radius + 0.004)
			add_child(label)

	else:
		# Vertical: canister stands upright along +Y.
		body.position = Vector3(0.0, y_base + canister_height * 0.5, 0.0)
		add_child(body)

		cap.position = Vector3(0.0, y_base + canister_height + shoulder_h * 0.5, 0.0)
		add_child(cap)

		var top_y: float = y_base + canister_height + shoulder_h
		valve_box.position = Vector3(0.0, top_y + VALVE_HOUSING_SIZE.y * 0.5, 0.0)
		add_child(valve_box)

		# Wheel on +X side of valve box (rotated so it points outward).
		wheel.rotation = Vector3(0.0, 0.0, deg_to_rad(90.0))
		wheel.position = Vector3(
			VALVE_HOUSING_SIZE.x * 0.5 + WHEEL_THICKNESS * 0.5,
			top_y + VALVE_HOUSING_SIZE.y * 0.5,
			0.0
		)
		add_child(wheel)

		# Spout angles up-and-forward (+Z) from the valve box.
		var spout_rot: float = deg_to_rad(35.0)
		spout.rotation = Vector3(spout_rot, 0.0, 0.0)
		spout.position = Vector3(
			0.0,
			top_y + VALVE_HOUSING_SIZE.y * 0.6,
			VALVE_HOUSING_SIZE.z * 0.5 + SPOUT_LENGTH * 0.35
		)
		add_child(spout)

		# Pressure dot near valve on the +Z side.
		if dot:
			dot.position = Vector3(
				-VALVE_HOUSING_SIZE.x * 0.2,
				top_y + VALVE_HOUSING_SIZE.y * 0.6,
				VALVE_HOUSING_SIZE.z * 0.5 + PRESSURE_DOT_RADIUS * 0.9
			)
			add_child(dot)

		# Label on the +Z face of the body, mid-height.
		if label:
			label.position = Vector3(0.0, y_base + canister_height * 0.55, canister_radius + 0.004)
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
