extends Node3D
class_name FireExtinguisher

# @identity
# essence: a wall-mounted red cylinder — Half-Life / industrial-corridor vocabulary. Bright alarm-red body, narrower steel valve and pinch handle on top, a coiled black hose curving down one side, a small steel wall bracket holding the cylinder against the wall, a white accent band around the middle and a white "FIRE" Label3D on the front. The artifact does not promise safety; it promises that danger is anticipated
# desire: every lab corridor wants a single, unmistakable signal that says THE DANGER HERE IS NAMED. The extinguisher wants to be visible from across the room — a saturated red against neutral lab walls. Recognition before reading. The eye finds it before the mind interprets it
# critical_parameter: wall_bracket + hose_visible — bracket OFF + hose OFF reads as a free-standing emergency object on the floor. Bracket ON + hose ON reads as fully-mounted corridor infrastructure. Same cylinder, two very different rooms — one where the device has been deployed, one where it is permanently at-the-ready
# triggers: _ready() builds bracket + body + neck + valve + handle + hose segments + accent band + label from exports; apply_grid_config rebuilds
# emerges: bright red against pale walls = ALARM PRESENT. Coiled hose = USED OR MAINTAINED. Wall bracket = INSTITUTIONAL. Together they encode the lab's confession that fire is one of the things that can happen here
# needs: vertical cylinder body in alarm red [present]; narrow neck/valve on top [present]; pinch handle (small box) [present]; coiled black hose curving down to one side [present]; wall bracket box behind cylinder [present]; white accent band wrapping the middle [present]; "FIRE" Label3D on the front [present]
# relationships: peer to safety_shower (both = response-to-named-hazard, one for fire one for chemical); sibling to exit_sign (both = wall-mounted emergency vocabulary, one for ignition one for escape); cousin to emergency_button (the corridor's grammar of TROUBLE-IS-ANTICIPATED); the lab's quiet admission that its experiments can fail loudly
# truth: a fire extinguisher is the architectural form of NAMED DANGER. By placing it, the lab confesses what it fears. A space without one says either "nothing burns here" or "we have not thought about what burns here." A space WITH one says "we have thought about it; here is the answer." The red is not decorative — red is the colour of "you will see me before you need me"

## A wall-mounted red fire extinguisher.
##
## Built procedurally from DNA exports. Origin is at the bottom center of
## the cylinder body, on the floor (or on the mounting surface). The
## label faces +Z (the device reads from the +Z side). Wall bracket sits
## behind the cylinder along -Z.

# ── DNA ───────────────────────────────────────────────────────────────

@export_group("Dimensions")
@export var extinguisher_height: float = 0.55
@export var extinguisher_radius: float = 0.075

@export_group("Color")
## Alarm red — the canonical extinguisher body color.
@export var body_color: Color = Color(0.78, 0.08, 0.08)
@export var accent_color: Color = Color(0.96, 0.96, 0.96)        # white accent band
@export var label_color: Color = Color(0.98, 0.98, 0.98)         # white label

@export_group("Hardware")
@export var hose_visible: bool = true
@export var wall_bracket: bool = true

@export_group("Label")
@export var label_text: String = "FIRE"

# ── Constants ─────────────────────────────────────────────────────────

const NECK_HEIGHT_FACTOR: float = 0.085          # vs extinguisher_height
const NECK_RADIUS_FACTOR: float = 0.42           # vs extinguisher_radius
const VALVE_HEIGHT_FACTOR: float = 0.07
const VALVE_RADIUS_FACTOR: float = 0.55
const HANDLE_LENGTH_FACTOR: float = 1.2          # vs extinguisher_radius
const HANDLE_HEIGHT: float = 0.022
const HANDLE_DEPTH: float = 0.024
const ACCENT_BAND_HEIGHT: float = 0.022
const HOSE_SEGMENT_COUNT: int = 3
const HOSE_RADIUS: float = 0.011
const BRACKET_WIDTH_FACTOR: float = 1.6          # vs extinguisher_radius (wider than the cylinder)
const BRACKET_HEIGHT_FACTOR: float = 0.45        # vs extinguisher_height
const BRACKET_DEPTH: float = 0.035
const LABEL_PIXEL_SIZE: float = 0.0028
const LABEL_FONT_SIZE: int = 40

# ── Internal state ────────────────────────────────────────────────────

var _built: bool = false

# ── Lifecycle ─────────────────────────────────────────────────────────

func _ready() -> void:
	_read_metadata_overrides()
	_build_extinguisher()


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()
	if _built:
		_clear_built_children()
		_built = false
		_build_extinguisher()


func _read_metadata_overrides() -> void:
	if has_meta("config_extinguisher_height"):
		extinguisher_height = float(String(get_meta("config_extinguisher_height")))
	if has_meta("config_extinguisher_radius"):
		extinguisher_radius = float(String(get_meta("config_extinguisher_radius")))
	if has_meta("config_body_color"):
		body_color = _parse_color(String(get_meta("config_body_color")), body_color)
	if has_meta("config_accent_color"):
		accent_color = _parse_color(String(get_meta("config_accent_color")), accent_color)
	if has_meta("config_label_color"):
		label_color = _parse_color(String(get_meta("config_label_color")), label_color)
	if has_meta("config_hose_visible"):
		var hv := String(get_meta("config_hose_visible")).to_lower()
		hose_visible = hv in ["true", "1", "yes", "on"]
	if has_meta("config_wall_bracket"):
		var wb := String(get_meta("config_wall_bracket")).to_lower()
		wall_bracket = wb in ["true", "1", "yes", "on"]
	if has_meta("config_label_text"):
		label_text = String(get_meta("config_label_text"))


func _clear_built_children() -> void:
	for c in get_children():
		c.queue_free()


# ── Build ─────────────────────────────────────────────────────────────

func _build_extinguisher() -> void:
	_built = true
	if wall_bracket:
		_build_bracket()
	_build_body()
	_build_neck_and_valve()
	_build_handle()
	_build_accent_band()
	if hose_visible:
		_build_hose()
	_build_label()


func _build_bracket() -> void:
	# A simple steel mounting bracket behind the cylinder on -Z.
	var bracket := MeshInstance3D.new()
	bracket.name = "Bracket"
	var mesh := BoxMesh.new()
	var bw: float = extinguisher_radius * BRACKET_WIDTH_FACTOR
	var bh: float = extinguisher_height * BRACKET_HEIGHT_FACTOR
	mesh.size = Vector3(bw, bh, BRACKET_DEPTH)
	bracket.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.32, 0.32, 0.34)
	mat.roughness = 0.55
	mat.metallic = 0.55
	bracket.material_override = mat
	# Centered on cylinder midpoint along Y, behind on -Z.
	var by: float = extinguisher_height * 0.5
	var bz: float = -extinguisher_radius - BRACKET_DEPTH * 0.5
	bracket.position = Vector3(0.0, by, bz)
	add_child(bracket)


func _build_body() -> void:
	var body := MeshInstance3D.new()
	body.name = "Body"
	var mesh := CylinderMesh.new()
	mesh.top_radius = extinguisher_radius
	mesh.bottom_radius = extinguisher_radius * 1.02
	mesh.height = extinguisher_height
	body.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = body_color
	mat.roughness = 0.35
	mat.metallic = 0.3
	body.material_override = mat
	body.position = Vector3(0.0, extinguisher_height * 0.5, 0.0)
	add_child(body)


func _build_neck_and_valve() -> void:
	# Narrower cylinder above the body (the neck), then a small dark valve cap.
	var neck := MeshInstance3D.new()
	neck.name = "Neck"
	var nm := CylinderMesh.new()
	var neck_h: float = extinguisher_height * NECK_HEIGHT_FACTOR
	var neck_r: float = extinguisher_radius * NECK_RADIUS_FACTOR
	nm.top_radius = neck_r * 0.9
	nm.bottom_radius = neck_r
	nm.height = neck_h
	neck.mesh = nm
	var nmat := StandardMaterial3D.new()
	nmat.albedo_color = Color(0.20, 0.20, 0.22)
	nmat.roughness = 0.45
	nmat.metallic = 0.7
	neck.material_override = nmat
	neck.position = Vector3(0.0, extinguisher_height + neck_h * 0.5, 0.0)
	add_child(neck)

	# Valve cap (slightly wider disc) on top of the neck.
	var valve := MeshInstance3D.new()
	valve.name = "Valve"
	var vm := CylinderMesh.new()
	var valve_h: float = extinguisher_height * VALVE_HEIGHT_FACTOR
	var valve_r: float = extinguisher_radius * VALVE_RADIUS_FACTOR
	vm.top_radius = valve_r
	vm.bottom_radius = valve_r * 1.05
	vm.height = valve_h
	valve.mesh = vm
	var vmat := StandardMaterial3D.new()
	vmat.albedo_color = Color(0.18, 0.18, 0.20)
	vmat.roughness = 0.5
	vmat.metallic = 0.6
	valve.material_override = vmat
	valve.position = Vector3(0.0, extinguisher_height + neck_h + valve_h * 0.5, 0.0)
	add_child(valve)


func _build_handle() -> void:
	# A small horizontal box across the top of the valve — the pinch handle.
	var handle := MeshInstance3D.new()
	handle.name = "Handle"
	var hm := BoxMesh.new()
	var hw: float = extinguisher_radius * HANDLE_LENGTH_FACTOR
	hm.size = Vector3(hw, HANDLE_HEIGHT, HANDLE_DEPTH)
	handle.mesh = hm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.18, 0.18, 0.20)
	mat.roughness = 0.45
	mat.metallic = 0.7
	handle.material_override = mat
	# Slight rotation around Z so it tilts up like a pinch lever.
	handle.rotation = Vector3(0.0, 0.0, deg_to_rad(-8.0))
	var neck_h: float = extinguisher_height * NECK_HEIGHT_FACTOR
	var valve_h: float = extinguisher_height * VALVE_HEIGHT_FACTOR
	var y: float = extinguisher_height + neck_h + valve_h + HANDLE_HEIGHT * 0.55
	handle.position = Vector3(0.0, y, 0.0)
	add_child(handle)


func _build_accent_band() -> void:
	# A white band wrapping the middle of the cylinder body.
	var band := MeshInstance3D.new()
	band.name = "AccentBand"
	var mesh := CylinderMesh.new()
	mesh.top_radius = extinguisher_radius * 1.015
	mesh.bottom_radius = extinguisher_radius * 1.015
	mesh.height = ACCENT_BAND_HEIGHT
	band.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = accent_color
	mat.roughness = 0.45
	mat.metallic = 0.15
	band.material_override = mat
	band.position = Vector3(0.0, extinguisher_height * 0.55, 0.0)
	add_child(band)


func _build_hose() -> void:
	# Approximated coiled hose: a few short cylinder segments hanging down
	# the side, each rotated to form a gentle curve toward -X.
	var root := Node3D.new()
	root.name = "Hose"
	add_child(root)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.07, 0.07, 0.08)
	mat.roughness = 0.6
	mat.metallic = 0.0

	var neck_h: float = extinguisher_height * NECK_HEIGHT_FACTOR
	var valve_h: float = extinguisher_height * VALVE_HEIGHT_FACTOR
	# Anchor near the valve, +X side.
	var start: Vector3 = Vector3(
		extinguisher_radius * 0.6,
		extinguisher_height + neck_h + valve_h * 0.4,
		0.0
	)

	# Three segments swooping outward then down.
	var seg_count: int = HOSE_SEGMENT_COUNT
	var seg_len: float = extinguisher_height * 0.32
	var current: Vector3 = start
	for i in range(seg_count):
		var seg := MeshInstance3D.new()
		seg.name = "HoseSeg_%d" % i
		var cm := CylinderMesh.new()
		cm.top_radius = HOSE_RADIUS
		cm.bottom_radius = HOSE_RADIUS
		cm.height = seg_len
		seg.mesh = cm
		seg.material_override = mat
		seg.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

		# Direction: rotates from outward+slightly-down to mostly-down to inward+down.
		var t: float = float(i) / float(seg_count - 1)
		# Angle from +X axis (in XY plane), rotating toward -Y.
		var ang_deg: float = lerp(80.0, 260.0, t)   # start nearly +Y-ish, swing to -X & down
		var ang: float = deg_to_rad(ang_deg)
		var dir: Vector3 = Vector3(cos(ang), sin(ang), 0.0)
		# Build basis where local +Y points along dir.
		var up: Vector3 = dir.normalized()
		var ref: Vector3 = Vector3(0.0, 0.0, 1.0)
		if abs(up.dot(ref)) > 0.95:
			ref = Vector3(1.0, 0.0, 0.0)
		var side: Vector3 = up.cross(ref).normalized()
		var fwd: Vector3 = side.cross(up).normalized()
		var basis := Basis(side, up, fwd)
		seg.transform.basis = basis
		# Place center of segment at current + 0.5*seg_len*up.
		var mid: Vector3 = current + up * (seg_len * 0.5)
		seg.position = mid
		root.add_child(seg)
		# Advance current to end of this segment for the next one to start from.
		current = current + up * seg_len

	# Small nozzle at the end.
	var nozzle := MeshInstance3D.new()
	nozzle.name = "HoseNozzle"
	var nzm := CylinderMesh.new()
	nzm.top_radius = HOSE_RADIUS * 0.9
	nzm.bottom_radius = HOSE_RADIUS * 1.4
	nzm.height = 0.04
	nozzle.mesh = nzm
	var nzmat := StandardMaterial3D.new()
	nzmat.albedo_color = Color(0.20, 0.20, 0.22)
	nzmat.roughness = 0.4
	nzmat.metallic = 0.7
	nozzle.material_override = nzmat
	nozzle.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	nozzle.position = current
	root.add_child(nozzle)


func _build_label() -> void:
	if label_text == "":
		return
	var label := Label3D.new()
	label.name = "Label"
	label.text = label_text
	label.font_size = LABEL_FONT_SIZE
	label.outline_size = 4
	label.pixel_size = LABEL_PIXEL_SIZE
	label.modulate = label_color
	label.outline_modulate = Color(0.08, 0.0, 0.0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.no_depth_test = false
	# Label3D in Godot 4 defaults to facing +Z (readable from +Z viewers).
	label.position = Vector3(0.0, extinguisher_height * 0.50, extinguisher_radius + 0.004)
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
