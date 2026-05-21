extends Node3D
class_name BunsenBurner

# @identity
# essence: a heavy short base, a narrow tube rising vertically, a tapered flame on top — Black Mesa / chemistry vocabulary for "this is the energy source". Dark steel base, slim tube, an optional gas hose running into the side, and a flame whose color encodes its TEMPERATURE. In the lab's grammar, the bunsen burner is the SIMULATED-ANNEALING TEMPERATURE DIAL — the schedule made visible.
# desire: every search wants a temperature. The bunsen burner wants to BE that temperature — to assert, in the room, "right now the system is hot" or "right now the system is cold". It wants the flame's color to read as the current state of the cooling schedule.
# critical_parameter: flame_color + flame_height + valve_position — together these ARE the annealing temperature. Cool blue + low + closed = ground state (T → 0, exploitation only). Hot orange/yellow + tall + full = high-T exploration phase. Reading the flame reads the scheduler.
# triggers: _ready() builds base + tube + valve + optional gas line + flame (lower + bright tip) + accent stripe from exports; apply_grid_config rebuilds
# emerges: blue flame reads CALM / FINAL / DETERMINISTIC. Orange flame reads HOT / EARLY-RUN / EXPLORATORY. Flame off + closed valve reads FINISHED / CONVERGED. Same hardware, three phases of the same algorithm.
# needs: short cylindrical base [present]; tall narrow tube [present]; flame body (lower taper) and brighter tip (upper taper) when flame_visible [present]; optional gas hose at -X side [present]; valve handle disc [present]; accent stripe at base [present]
# relationships: peer to oscilloscope (both NAME an algorithmic control — burner names temperature, scope displays spectrum); cousin to fume_hood (the fume_hood EXTRACTS what the burner PRODUCES — they form a heat→exhaust pair); ancestor to vacuum_chamber (both can change LOCAL conditions in the room — chamber alters pressure, burner alters energy)
# truth: annealing says "start hot, end cold". The bunsen burner IS that rule in object form. The flame's color is the current value of T. When the flame turns blue and shrinks, the schedule is nearly done; when it is tall and orange, the schedule has just begun. The burner does not explain the algorithm — it ENACTS it.

## A bunsen burner — base + tube + tapered flame.
##
## Built procedurally from DNA exports. Origin is at the BOTTOM CENTER
## of the base, on the table. The tube rises in +Y. Optional gas hose
## enters from the -X side. The flame is a two-part taper above the tube.

# ── DNA ───────────────────────────────────────────────────────────────

@export_group("Base")
@export var base_radius: float = 0.05
@export var base_height: float = 0.03

@export_group("Tube")
@export var tube_height: float = 0.14
@export var tube_radius: float = 0.012

@export_group("Flame")
@export var flame_visible: bool = true
@export var flame_height: float = 0.10
@export var flame_width: float = 0.045
## Cool blue is the LOW-TEMP / late-anneal state.
@export var flame_color: Color = Color(0.40, 0.65, 1.0)

@export_group("Body")
@export var body_color: Color = Color(0.18, 0.18, 0.22)
@export var gas_line_visible: bool = true
## "closed" | "low" | "medium" | "full"
@export var valve_position: String = "medium"
@export var accent_color: Color = Color(1.0, 0.45, 0.10)

# ── Constants ─────────────────────────────────────────────────────────

const VALVE_RADIUS: float = 0.014
const VALVE_DEPTH: float = 0.008
const GAS_LINE_LENGTH: float = 0.10
const GAS_LINE_RADIUS: float = 0.008
const ACCENT_STRIP_HEIGHT: float = 0.006

# ── Internal state ────────────────────────────────────────────────────

var _built: bool = false

# ── Lifecycle ─────────────────────────────────────────────────────────

func _ready() -> void:
	_read_metadata_overrides()
	_build_burner()


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()
	if _built:
		_clear_built_children()
		_built = false
		_build_burner()


func _read_metadata_overrides() -> void:
	if has_meta("config_base_radius"):
		base_radius = float(String(get_meta("config_base_radius")))
	if has_meta("config_base_height"):
		base_height = float(String(get_meta("config_base_height")))
	if has_meta("config_tube_height"):
		tube_height = float(String(get_meta("config_tube_height")))
	if has_meta("config_tube_radius"):
		tube_radius = float(String(get_meta("config_tube_radius")))
	if has_meta("config_flame_visible"):
		var fv := String(get_meta("config_flame_visible")).to_lower()
		flame_visible = fv in ["true", "1", "yes", "on"]
	if has_meta("config_flame_height"):
		flame_height = float(String(get_meta("config_flame_height")))
	if has_meta("config_flame_width"):
		flame_width = float(String(get_meta("config_flame_width")))
	if has_meta("config_flame_color"):
		flame_color = _parse_color(String(get_meta("config_flame_color")), flame_color)
	if has_meta("config_body_color"):
		body_color = _parse_color(String(get_meta("config_body_color")), body_color)
	if has_meta("config_gas_line_visible"):
		var gv := String(get_meta("config_gas_line_visible")).to_lower()
		gas_line_visible = gv in ["true", "1", "yes", "on"]
	if has_meta("config_valve_position"):
		valve_position = String(get_meta("config_valve_position")).to_lower()
	if has_meta("config_accent_color"):
		accent_color = _parse_color(String(get_meta("config_accent_color")), accent_color)


func _clear_built_children() -> void:
	for c in get_children():
		c.queue_free()


# ── Build ─────────────────────────────────────────────────────────────

func _build_burner() -> void:
	_built = true
	_build_base()
	_build_tube()
	_build_valve_handle()
	if gas_line_visible:
		_build_gas_line()
	if flame_visible:
		_build_flame()
	_build_accent_strip()


func _build_base() -> void:
	var base := MeshInstance3D.new()
	base.name = "Base"
	var mesh := CylinderMesh.new()
	mesh.top_radius = base_radius * 0.92
	mesh.bottom_radius = base_radius
	mesh.height = base_height
	base.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = body_color
	mat.roughness = 0.45
	mat.metallic = 0.7
	base.material_override = mat
	base.position = Vector3(0.0, base_height * 0.5, 0.0)
	add_child(base)


func _build_tube() -> void:
	var tube := MeshInstance3D.new()
	tube.name = "Tube"
	var mesh := CylinderMesh.new()
	mesh.top_radius = tube_radius
	mesh.bottom_radius = tube_radius * 1.15
	mesh.height = tube_height
	tube.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = body_color.lerp(Color(0.30, 0.30, 0.33), 0.35)
	mat.roughness = 0.4
	mat.metallic = 0.75
	tube.material_override = mat
	tube.position = Vector3(0.0, base_height + tube_height * 0.5, 0.0)
	add_child(tube)


func _build_valve_handle() -> void:
	# Small disc protruding from the base on the +X side. The valve_position
	# rotates the disc to encode state ("closed" → 0°, "low" → 30°, …).
	var valve := MeshInstance3D.new()
	valve.name = "ValveHandle"
	var mesh := CylinderMesh.new()
	mesh.top_radius = VALVE_RADIUS
	mesh.bottom_radius = VALVE_RADIUS
	mesh.height = VALVE_DEPTH
	valve.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = body_color.lerp(Color(0.55, 0.55, 0.58), 0.5)
	mat.roughness = 0.4
	mat.metallic = 0.7
	valve.material_override = mat
	# Cylinder axis points along +X (so its flat face shows the rotation).
	valve.rotation = Vector3(0.0, 0.0, PI * 0.5)
	valve.position = Vector3(base_radius + VALVE_DEPTH * 0.5 + 0.001, base_height * 0.5, 0.0)
	add_child(valve)

	# Small accent tick on the valve face indicating its current position.
	var tick := MeshInstance3D.new()
	tick.name = "ValveTick"
	var tm := BoxMesh.new()
	tm.size = Vector3(0.0015, VALVE_RADIUS * 0.75, 0.001)
	tick.mesh = tm
	var tmat := StandardMaterial3D.new()
	tmat.albedo_color = accent_color
	tmat.emission_enabled = true
	tmat.emission = accent_color
	tmat.emission_energy_multiplier = 1.4
	tick.material_override = tmat
	var ang_deg: float = 0.0
	match valve_position:
		"closed":
			ang_deg = -90.0
		"low":
			ang_deg = -30.0
		"medium":
			ang_deg = 30.0
		"full":
			ang_deg = 90.0
		_:
			ang_deg = 0.0
	# Position the tick on the +X face of the disc and rotate around the disc axis (X).
	var pivot := Node3D.new()
	pivot.name = "ValvePivot"
	add_child(pivot)
	pivot.position = Vector3(base_radius + VALVE_DEPTH + 0.001, base_height * 0.5, 0.0)
	pivot.rotation = Vector3(deg_to_rad(ang_deg), 0.0, 0.0)
	tick.position = Vector3(0.0, VALVE_RADIUS * 0.4, 0.0)
	pivot.add_child(tick)


func _build_gas_line() -> void:
	# Thin horizontal cylinder from the -X side of the base. Axis along -X.
	var hose := MeshInstance3D.new()
	hose.name = "GasLine"
	var mesh := CylinderMesh.new()
	mesh.top_radius = GAS_LINE_RADIUS
	mesh.bottom_radius = GAS_LINE_RADIUS
	mesh.height = GAS_LINE_LENGTH
	hose.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.10, 0.10, 0.12)
	mat.roughness = 0.7
	mat.metallic = 0.1
	hose.material_override = mat
	# Lay the cylinder along the X axis (default along Y).
	hose.rotation = Vector3(0.0, 0.0, PI * 0.5)
	# Bottom of hose meets the -X side of the base at base_radius distance.
	hose.position = Vector3(-base_radius - GAS_LINE_LENGTH * 0.5 - 0.002, base_height * 0.5, 0.0)
	add_child(hose)


func _build_flame() -> void:
	# Two-stack tapered flame above the tube tip.
	var root := Node3D.new()
	root.name = "Flame"
	add_child(root)

	var tube_top_y: float = base_height + tube_height

	# Lower flame body — wider, slightly less bright.
	var lower_h: float = flame_height * 0.6
	var lower := MeshInstance3D.new()
	lower.name = "FlameBody"
	var lm := CylinderMesh.new()
	lm.top_radius = flame_width * 0.20
	lm.bottom_radius = flame_width
	lm.height = lower_h
	lower.mesh = lm
	var lmat := StandardMaterial3D.new()
	lmat.albedo_color = flame_color
	lmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	lmat.albedo_color.a = 0.85
	lmat.emission_enabled = true
	lmat.emission = flame_color
	lmat.emission_energy_multiplier = 2.6
	lmat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	lmat.cull_mode = BaseMaterial3D.CULL_DISABLED
	lower.material_override = lmat
	lower.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	lower.position = Vector3(0.0, tube_top_y + lower_h * 0.5, 0.0)
	root.add_child(lower)

	# Brighter inner tip — narrower, more intense.
	var tip_h: float = flame_height * 0.4
	var tip := MeshInstance3D.new()
	tip.name = "FlameTip"
	var tm := CylinderMesh.new()
	tm.top_radius = flame_width * 0.05
	tm.bottom_radius = flame_width * 0.40
	tm.height = tip_h
	tip.mesh = tm
	var tmat := StandardMaterial3D.new()
	# Brighten the inner taper slightly toward white.
	var inner_color: Color = flame_color.lerp(Color(1.0, 1.0, 1.0), 0.35)
	tmat.albedo_color = inner_color
	tmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	tmat.albedo_color.a = 0.95
	tmat.emission_enabled = true
	tmat.emission = inner_color
	tmat.emission_energy_multiplier = 4.0
	tmat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	tmat.cull_mode = BaseMaterial3D.CULL_DISABLED
	tip.material_override = tmat
	tip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	tip.position = Vector3(0.0, tube_top_y + lower_h + tip_h * 0.5, 0.0)
	root.add_child(tip)


func _build_accent_strip() -> void:
	# Thin emissive ring around the top edge of the base.
	var strip := MeshInstance3D.new()
	strip.name = "AccentStrip"
	var mesh := CylinderMesh.new()
	mesh.top_radius = base_radius * 0.98
	mesh.bottom_radius = base_radius * 0.98
	mesh.height = ACCENT_STRIP_HEIGHT
	strip.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = accent_color
	mat.emission_enabled = true
	mat.emission = accent_color
	mat.emission_energy_multiplier = 1.6
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	strip.material_override = mat
	strip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	strip.position = Vector3(0.0, base_height - ACCENT_STRIP_HEIGHT * 0.5 - 0.002, 0.0)
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
