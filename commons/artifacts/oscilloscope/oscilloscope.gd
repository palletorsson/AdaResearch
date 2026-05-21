extends Node3D
class_name Oscilloscope

# @identity
# essence: a rectangular instrument body with a recessed phosphor screen — Black Mesa / mid-century scope vocabulary. Dark steel chassis, a dim green graticule grid, a glowing emissive trace drawing one chosen waveform (sine, square, sawtooth, triangle, or composite-Fourier), a row of small front knobs, and a single status LED. In the lab's grammar, the oscilloscope is the FOURIER DECOMPOSITION TABLE — the place where a signal becomes its shape.
# desire: every lab wants a window onto its own signals. The oscilloscope wants to be the screen that says "what you put in came out as THIS curve". It wants the player to read its trace as the answer to "what shape was the wave?"
# critical_parameter: waveform_shape — together with waveform_frequency, this IS the Fourier statement of the prop. "sine" is the atomic basis function; "composite" sums sin(f) + sin(3f)/2 + sin(5f)/3 (the textbook square-wave Fourier series, truncated) — a square wave decomposed into its odd harmonics, visible on the face of the prop. Reading the trace IS reading the decomposition.
# triggers: _ready() builds chassis + screen + graticule + waveform trace + knobs + LED from exports; apply_grid_config rebuilds
# emerges: a sine trace reads CLEAN / ATOMIC. A square reads STEP / DIGITAL. A composite reads ALMOST-SQUARE-BUT-WAVY — the visible truth that any periodic signal is a sum of sines. The screen becomes a Fourier proof
# needs: rectangular body [present]; recessed screen face [present]; emissive graticule when grid_visible [present]; emissive dot trace sampled along the waveform path [present]; row of knobs below the screen [present]; status LED at corner [present]; accent stripe along chassis edge [present]
# relationships: peer to bunsen_burner (both name an algorithmic CONTROL — the burner controls TEMPERATURE for annealing, the scope DISPLAYS the spectrum for Fourier); sibling to specimen_jar (both DISPLAY something — the jar contains a captured thing, the scope contains a captured WAVEFORM); cousin to control_board (both are CRT vocabulary, the scope is the single-purpose version)
# truth: a wave is a sum of sines. The oscilloscope is the lab's affirmation of that statement in object form. If the trace is shaped like a square, the Fourier series says it is still made of sines underneath. The screen does not LIE about that — it just SHOWS the sum.

## A bench oscilloscope — rectangular chassis with a phosphor screen.
##
## Built procedurally from DNA exports. Origin is at the BOTTOM CENTER
## of the chassis footprint, on the table. Screen face points +Z. The
## waveform is drawn as a string of small emissive dots sampled along the
## chosen shape's path; the grid is a dim graticule behind the trace.

# ── DNA ───────────────────────────────────────────────────────────────

@export_group("Dimensions")
@export var body_width: float = 0.45
@export var body_height: float = 0.25
@export var body_depth: float = 0.30
@export_range(0.3, 0.95) var screen_width_factor: float = 0.70
@export_range(0.3, 0.95) var screen_height_factor: float = 0.65

@export_group("Color")
@export var body_color: Color = Color(0.18, 0.18, 0.22)
@export var screen_bg_color: Color = Color(0.04, 0.06, 0.04)
@export_range(0.0, 3.0, 0.05) var screen_emission: float = 0.6
@export var waveform_color: Color = Color(0.40, 0.95, 0.55)
@export var grid_color: Color = Color(0.15, 0.35, 0.18)
@export var accent_color: Color = Color(1.0, 0.45, 0.10)

@export_group("Waveform")
## "sine" | "square" | "sawtooth" | "triangle" | "composite"
@export var waveform_shape: String = "sine"
@export_range(0.05, 1.0, 0.01) var waveform_amplitude: float = 0.7
@export_range(1, 12) var waveform_frequency: int = 3

@export_group("Controls")
@export var grid_visible: bool = true
@export_range(0, 8) var knob_count: int = 4

# ── Constants ─────────────────────────────────────────────────────────

const SCREEN_INSET: float = 0.012
const SCREEN_FACE_DEPTH: float = 0.010
const TRACE_SAMPLES: int = 36
const TRACE_DOT_RADIUS: float = 0.0045
const GRID_COLS: int = 8
const GRID_ROWS: int = 6
const GRID_THICKNESS: float = 0.0018
const KNOB_RADIUS: float = 0.018
const KNOB_DEPTH: float = 0.012
const KNOB_ROW_MARGIN: float = 0.022
const LED_RADIUS: float = 0.006
const LED_DEPTH: float = 0.005
const ACCENT_STRIP_HEIGHT: float = 0.010

# ── Internal state ────────────────────────────────────────────────────

var _built: bool = false

# ── Lifecycle ─────────────────────────────────────────────────────────

func _ready() -> void:
	_read_metadata_overrides()
	_build_oscilloscope()


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()
	if _built:
		_clear_built_children()
		_built = false
		_build_oscilloscope()


func _read_metadata_overrides() -> void:
	if has_meta("config_body_width"):
		body_width = float(String(get_meta("config_body_width")))
	if has_meta("config_body_height"):
		body_height = float(String(get_meta("config_body_height")))
	if has_meta("config_body_depth"):
		body_depth = float(String(get_meta("config_body_depth")))
	if has_meta("config_screen_width_factor"):
		screen_width_factor = float(String(get_meta("config_screen_width_factor")))
	if has_meta("config_screen_height_factor"):
		screen_height_factor = float(String(get_meta("config_screen_height_factor")))
	if has_meta("config_body_color"):
		body_color = _parse_color(String(get_meta("config_body_color")), body_color)
	if has_meta("config_screen_bg_color"):
		screen_bg_color = _parse_color(String(get_meta("config_screen_bg_color")), screen_bg_color)
	if has_meta("config_screen_emission"):
		screen_emission = float(String(get_meta("config_screen_emission")))
	if has_meta("config_waveform_color"):
		waveform_color = _parse_color(String(get_meta("config_waveform_color")), waveform_color)
	if has_meta("config_grid_color"):
		grid_color = _parse_color(String(get_meta("config_grid_color")), grid_color)
	if has_meta("config_accent_color"):
		accent_color = _parse_color(String(get_meta("config_accent_color")), accent_color)
	if has_meta("config_waveform_shape"):
		waveform_shape = String(get_meta("config_waveform_shape")).to_lower()
	if has_meta("config_waveform_amplitude"):
		waveform_amplitude = float(String(get_meta("config_waveform_amplitude")))
	if has_meta("config_waveform_frequency"):
		waveform_frequency = int(String(get_meta("config_waveform_frequency")))
	if has_meta("config_grid_visible"):
		var gv := String(get_meta("config_grid_visible")).to_lower()
		grid_visible = gv in ["true", "1", "yes", "on"]
	if has_meta("config_knob_count"):
		knob_count = int(String(get_meta("config_knob_count")))


func _clear_built_children() -> void:
	for c in get_children():
		c.queue_free()


# ── Build ─────────────────────────────────────────────────────────────

func _build_oscilloscope() -> void:
	_built = true
	_build_chassis()
	_build_screen_face()
	if grid_visible:
		_build_graticule()
	_build_waveform_trace()
	_build_knobs()
	_build_status_led()
	_build_accent_strip()


func _build_chassis() -> void:
	var chassis := MeshInstance3D.new()
	chassis.name = "Chassis"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(body_width, body_height, body_depth)
	chassis.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = body_color
	mat.roughness = 0.55
	mat.metallic = 0.45
	chassis.material_override = mat
	chassis.position = Vector3(0.0, body_height * 0.5, 0.0)
	add_child(chassis)


func _build_screen_face() -> void:
	# Inset rectangular dark screen panel on +Z face. Slightly recessed.
	var screen_w: float = body_width * screen_width_factor
	var screen_h: float = body_height * screen_height_factor
	var screen := MeshInstance3D.new()
	screen.name = "ScreenFace"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(screen_w, screen_h, SCREEN_FACE_DEPTH)
	screen.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = screen_bg_color
	mat.roughness = 0.25
	mat.metallic = 0.0
	mat.emission_enabled = true
	mat.emission = Color(screen_bg_color.r + 0.05, screen_bg_color.g + 0.08, screen_bg_color.b + 0.05)
	mat.emission_energy_multiplier = screen_emission * 0.25
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	screen.material_override = mat
	# Slightly above center, vertically shifted up to leave room for knobs below.
	var screen_y: float = body_height * 0.5 + (body_height * 0.5 - screen_h * 0.5 - KNOB_ROW_MARGIN) * 0.0
	# Center the screen with room for knobs in the lower band.
	var center_y: float = body_height - screen_h * 0.5 - 0.020
	screen.position = Vector3(0.0, center_y, body_depth * 0.5 + SCREEN_FACE_DEPTH * 0.5 - SCREEN_INSET)
	add_child(screen)


func _build_graticule() -> void:
	# Dim emissive grid lines on the screen face. 8 vertical + 6 horizontal.
	var root := Node3D.new()
	root.name = "Graticule"
	add_child(root)

	var screen_w: float = body_width * screen_width_factor
	var screen_h: float = body_height * screen_height_factor
	var center_y: float = body_height - screen_h * 0.5 - 0.020
	var face_z: float = body_depth * 0.5 + SCREEN_FACE_DEPTH * 0.5 - SCREEN_INSET + SCREEN_FACE_DEPTH * 0.5 + 0.0006

	var mat := StandardMaterial3D.new()
	mat.albedo_color = grid_color
	mat.emission_enabled = true
	mat.emission = grid_color
	mat.emission_energy_multiplier = 0.9
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL

	# Vertical lines (GRID_COLS dividers means GRID_COLS-1 interior lines + 2 edges).
	for i in range(GRID_COLS + 1):
		var t: float = float(i) / float(GRID_COLS)
		var x: float = (t - 0.5) * screen_w
		var bar := MeshInstance3D.new()
		bar.name = "GridV_%d" % i
		var bm := BoxMesh.new()
		bm.size = Vector3(GRID_THICKNESS, screen_h, 0.0015)
		bar.mesh = bm
		bar.material_override = mat
		bar.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		bar.position = Vector3(x, center_y, face_z)
		root.add_child(bar)

	# Horizontal lines.
	for j in range(GRID_ROWS + 1):
		var t2: float = float(j) / float(GRID_ROWS)
		var y: float = center_y + (t2 - 0.5) * screen_h
		var bar2 := MeshInstance3D.new()
		bar2.name = "GridH_%d" % j
		var bm2 := BoxMesh.new()
		bm2.size = Vector3(screen_w, GRID_THICKNESS, 0.0015)
		bar2.mesh = bm2
		bar2.material_override = mat
		bar2.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		bar2.position = Vector3(0.0, y, face_z)
		root.add_child(bar2)


func _build_waveform_trace() -> void:
	var root := Node3D.new()
	root.name = "WaveformTrace"
	add_child(root)

	var screen_w: float = body_width * screen_width_factor
	var screen_h: float = body_height * screen_height_factor
	var center_y: float = body_height - screen_h * 0.5 - 0.020
	var face_z: float = body_depth * 0.5 + SCREEN_FACE_DEPTH * 0.5 - SCREEN_INSET + SCREEN_FACE_DEPTH * 0.5 + 0.001

	var mat := StandardMaterial3D.new()
	mat.albedo_color = waveform_color
	mat.emission_enabled = true
	mat.emission = waveform_color
	mat.emission_energy_multiplier = 2.4
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL

	# Use the EFFECTIVE amplitude: scaled to fill at most half-screen height.
	var amp_eff: float = clampf(waveform_amplitude, 0.0, 1.0)
	var freq_eff: int = max(1, waveform_frequency)
	var samples_n: int = TRACE_SAMPLES

	for i in range(samples_n):
		var t: float = float(i) / float(max(1, samples_n - 1))   # 0..1 across screen
		var y_norm: float = _evaluate_waveform(t, freq_eff)        # -1..1
		var x: float = (t - 0.5) * screen_w
		var y: float = center_y + y_norm * (screen_h * 0.5) * amp_eff

		var dot := MeshInstance3D.new()
		dot.name = "WaveDot_%d" % i
		var sm := SphereMesh.new()
		sm.radius = TRACE_DOT_RADIUS
		sm.height = TRACE_DOT_RADIUS * 2.0
		sm.radial_segments = 8
		sm.rings = 4
		dot.mesh = sm
		dot.material_override = mat
		dot.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		dot.position = Vector3(x, y, face_z)
		root.add_child(dot)


func _evaluate_waveform(t: float, freq: int) -> float:
	# t in [0,1]. Output in [-1,1]. Frequency = full cycles across t.
	var x: float = t * float(freq)
	match waveform_shape:
		"sine":
			return sin(TAU * x)
		"square":
			return signf(sin(TAU * x))
		"sawtooth":
			var s: float = fposmod(x, 1.0)
			return s * 2.0 - 1.0
		"triangle":
			var u: float = fposmod(x, 1.0) - 0.5
			# 0 at u=±0.5; 1 at u=0; -1 at u=±0.5 — actually we want a true triangle wave
			# tri = 2 * abs(2 * (x - floor(x+0.5))) - 1
			var p: float = x - floor(x + 0.5)
			return 2.0 * absf(2.0 * p) - 1.0
		"composite":
			# Square-wave Fourier truncation: sin(2π f x) + sin(2π·3f x)/3 + sin(2π·5f x)/5,
			# scaled to fit roughly within [-1,1].
			var v: float = sin(TAU * x) + sin(TAU * x * 3.0) / 3.0 + sin(TAU * x * 5.0) / 5.0
			# Empirical normalisation — leading partial sum peaks near 1.05; clamp gently.
			return clampf(v / 1.1, -1.0, 1.0)
		_:
			return sin(TAU * x)


func _build_knobs() -> void:
	if knob_count <= 0:
		return
	var root := Node3D.new()
	root.name = "Knobs"
	add_child(root)

	var screen_h: float = body_height * screen_height_factor
	var screen_top: float = body_height - 0.020
	var screen_bottom: float = screen_top - screen_h
	var knob_y: float = screen_bottom * 0.5 + 0.012

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.30, 0.30, 0.34)
	mat.roughness = 0.4
	mat.metallic = 0.6

	# Distribute knobs across the lower band on the +Z face.
	var span: float = body_width * 0.70
	var n: int = knob_count
	for i in range(n):
		var t: float = 0.0
		if n > 1:
			t = float(i) / float(n - 1)
		var x: float = (t - 0.5) * span
		var knob := MeshInstance3D.new()
		knob.name = "Knob_%d" % i
		var cm := CylinderMesh.new()
		cm.top_radius = KNOB_RADIUS
		cm.bottom_radius = KNOB_RADIUS * 1.05
		cm.height = KNOB_DEPTH
		knob.mesh = cm
		knob.material_override = mat
		# Lay flat against the +Z face (cylinder axis along Z, default along Y).
		knob.rotation = Vector3(PI * 0.5, 0.0, 0.0)
		knob.position = Vector3(x, knob_y, body_depth * 0.5 + KNOB_DEPTH * 0.5 - 0.002)
		root.add_child(knob)

		# Small accent indicator line on the knob face.
		var ind := MeshInstance3D.new()
		ind.name = "KnobInd_%d" % i
		var im := BoxMesh.new()
		im.size = Vector3(0.0015, KNOB_RADIUS * 0.75, 0.0010)
		ind.mesh = im
		var im_mat := StandardMaterial3D.new()
		im_mat.albedo_color = accent_color
		im_mat.emission_enabled = true
		im_mat.emission = accent_color
		im_mat.emission_energy_multiplier = 1.4
		ind.material_override = im_mat
		ind.position = Vector3(x, knob_y + KNOB_RADIUS * 0.4, body_depth * 0.5 + KNOB_DEPTH + 0.0010)
		root.add_child(ind)


func _build_status_led() -> void:
	# Small emissive disc at top-right corner of the chassis front face.
	var led := MeshInstance3D.new()
	led.name = "StatusLED"
	var cm := CylinderMesh.new()
	cm.top_radius = LED_RADIUS
	cm.bottom_radius = LED_RADIUS
	cm.height = LED_DEPTH
	led.mesh = cm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = accent_color
	mat.emission_enabled = true
	mat.emission = accent_color
	mat.emission_energy_multiplier = 2.2
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	led.material_override = mat
	led.rotation = Vector3(PI * 0.5, 0.0, 0.0)
	var corner_x: float = body_width * 0.5 - 0.020
	var corner_y: float = body_height - 0.014
	led.position = Vector3(corner_x, corner_y, body_depth * 0.5 + LED_DEPTH * 0.5 - 0.001)
	add_child(led)


func _build_accent_strip() -> void:
	# Thin emissive strip along the front bottom edge of the chassis.
	var strip := MeshInstance3D.new()
	strip.name = "AccentStrip"
	var bm := BoxMesh.new()
	bm.size = Vector3(body_width, ACCENT_STRIP_HEIGHT, 0.004)
	strip.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = accent_color
	mat.emission_enabled = true
	mat.emission = accent_color
	mat.emission_energy_multiplier = 1.5
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	strip.material_override = mat
	strip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	strip.position = Vector3(0.0, ACCENT_STRIP_HEIGHT * 0.5 + 0.001, body_depth * 0.5 + 0.002)
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
