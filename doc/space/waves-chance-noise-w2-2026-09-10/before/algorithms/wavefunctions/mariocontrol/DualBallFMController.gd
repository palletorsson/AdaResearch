extends Node3D

## DualBall FM Sound Controller
## Two 3D balls control 6 FM synthesis parameters
## Ball 1 (Blue): Carrier - Frequency, Attack, Decay
## Ball 2 (Orange): Modulator - Ratio, Index, Mod Decay


# @identity
# essence: FM synthesis — carrier(t) * sin(mod_ratio * carrier * mod_index)
# desire: Grab two balls in VR to sculpt sound through frequency modulation
# critical_parameter: evidence — how much of the FM arithmetic the rig puts on the table.
#   One ordered ladder, monotone in disclosure: result (the colour cube alone, the legacy
#   default) < trace (the output waveform on a scope) < sources (the two operand oscillators,
#   modulator and bare carrier, without the answer) < longhand (both operands printed above a
#   rule with the output below as the sum). mod_index is still the parameter that makes the
#   sound; evidence is what the instrument is willing to show while it makes it.
# triggers: ball position changes map to carrier freq, attack, decay, mod ratio, mod index,
#   mod decay; _ready reads #evidence: and #regime:; apply_grid_config({evidence, regime}).
# emerges: bell tones, electric pianos, brass — all from one oscillator modulating another
# needs: VR grab for both balls [has], preset buttons [has]
# relationships: depends on AudioStreamPlayer3D; contrasts with MarioSoundController (FM vs
#   basic waveforms); unlocks timbre_sculptor. Carries the `evidence` ladder of
#   [[wave_interference_tank]] and [[sine_wave_controller]] and parses a token through that
#   family's one reader rather than keeping a second table.
# truth: All timbral complexity is phase modulation of simple oscillators.

# ─────────────────────────────────────────────────────────────────────────────
# STAGE-2 DNA PROMOTION (2026-08-03). This artifact had ZERO exports and a
# still-frame problem sharper than most: its whole subject is a SOUND, and the
# only thing it ever drew about that sound was a 25 cm cube whose hue is
# mod_ratio/8, saturation mod_index/10 and value carrier_freq/2000. Three of six
# parameters, encoded as a colour nobody can decode. The waveform itself —
#
#     m(t)   = I · e^(−t/τm) · sin(2π · R · fc · t)
#     out(t) = tanh( 0.8 · sin(2π · fc · t + m(t)) · env(t) ) · 0.5
#
# — is evaluated 88,200 times per press inside _generate_fm_sound(), packed into
# bytes, and never once shown. `evidence` builds a scope from that same
# expression, so the rig can argue phase modulation instead of asserting it.
#
# `regime` lifts four sets of numbers that were already hard-coded in this file
# and unreachable: set_bell_preset / set_electric_piano_preset / set_brass_preset
# / set_metallic_preset exist, are complete six-parameter states, and NOTHING in
# the repo calls them. The rig shipped permanently at the geometric midpoint of
# all six dials — 1050 Hz, ratio 4.25, index 5.0 — which is not a sound anyone
# designed but the average of a slider. `midpoint` is that state and is the
# default; the other four are the classic FM patches the code already knew.
#
# Deliberately NOT the axis: sound_duration, min_play_interval, movement_threshold
# or SAMPLE_RATE. All four are rates or durations, and a still photograph cannot
# see a rate — sweeping one produces a family of identical tiles.
#
# Deliberately NOT routed through evidence: the balls, the cages and the cube.
# Every rung leaves the shipped rig exactly as it is and adds a scope ABOVE it.
# ─────────────────────────────────────────────────────────────────────────────

## THE AXIS — how much of the FM arithmetic the rig puts on the table.
##   result (legacy default) < trace < sources < longhand
@export var evidence: String = "result"

## THE SECOND AXIS — which named FM patch the rig is holding. `midpoint` is the
## shipped state: every ValueMapper3D ball parked at the centre of its own cage,
## which is where value_mapper_3d._create_point() puts it and where this artifact
## has always found it. The other four are this file's own preset functions.
@export var regime: String = "midpoint"

## Spellings that mean a patch already on the list.
const REGIME_ALIASES := {
	"none": "midpoint",
	"default": "midpoint",
	"centre": "midpoint",
	"center": "midpoint",
	"epiano": "electric_piano",
	"e_piano": "electric_piano",
	"piano": "electric_piano",
	"metal": "metallic",
	"harsh": "metallic",
}

static func regime_name(raw: String) -> String:
	var word: String = raw.strip_edges().to_lower()
	return str(REGIME_ALIASES.get(word, word))

# ── Apparatus built by the evidence axis. All null on the legacy default. ─────
const SCOPE_W: float = 1.36        # scope plate width (m)
const SCOPE_ROW_H: float = 0.16    # one waveform lane
const SCOPE_RULE_H: float = 0.05   # the lane the rule occupies in `longhand`
const SCOPE_X: float = 0.25        # centred over both cages, which span -0.5 … 1.0
const SCOPE_TOP: float = 1.05
# A short window densely sampled, not a long one coarsely. Under heavy modulation
# the output's instantaneous frequency reaches fc·(1 + I·R·e^(−t/τm)) — about 18×
# the carrier at the shipped midpoint — and at 4 periods / 400 points that aliases
# into noise, which would photograph as a different random smear for every variant.
const SCOPE_SAMPLES: int = 1200    # points per lane
const SCOPE_PERIODS: float = 2.0   # carrier periods in one window
const TRACE_THICK: float = 0.003   # ribbon half-thickness — 1 px lines vanish in a capture

var _evidence_root: Node3D         # every rung's geometry hangs here, and only here
var _rows: Array[String] = []
var _row_meshes: Array[ImmediateMesh] = []
var _row_y: Array[float] = []

@onready var carrier_mapper = $Ball1_Carrier
@onready var modulator_mapper = $Ball2_Modulator
@onready var audio_player = $AudioStreamPlayer3D

# FM Synthesis Parameters
# Ball 1 - Carrier (Blue)
var carrier_freq: float = 440.0  # Hz (100-2000)
var attack_time: float = 0.05   # seconds (0.01-0.5)
var decay_time: float = 1.0     # seconds (0.1-3.0)

# Ball 2 - Modulator (Orange)
var mod_ratio: float = 2.0      # × carrier freq (0.5-8.0)
var mod_index: float = 3.0      # depth (0.0-10.0)
var mod_decay: float = 0.5      # seconds (0.1-2.0)

# Audio settings
const SAMPLE_RATE = 44100
var sound_duration: float = 2.0

# Movement detection
var play_on_move: bool = true
var last_play_time: float = 0.0
var min_play_interval: float = 0.3
var last_carrier_pos: Vector3 = Vector3.ZERO
var last_mod_pos: Vector3 = Vector3.ZERO
var movement_threshold: float = 0.01

var preview_cube: MeshInstance3D
var carrier_ball: Node3D
var modulator_ball: Node3D
var title_label: Label3D

func _ready() -> void:
	_read_meta_overrides()
	_create_preview_cube()
	_create_title_label()
	_setup_carrier_mapper()
	_setup_modulator_mapper()
	
	# Connect signals
	if carrier_mapper:
		carrier_mapper.values_changed.connect(_on_carrier_changed)
		var initial = carrier_mapper.get_values()
		_on_carrier_changed(initial.x, initial.y, initial.z)
		carrier_ball = carrier_mapper.get_node_or_null("SpacePoint")
		if carrier_ball:
			last_carrier_pos = carrier_ball.global_position
			_color_ball(carrier_ball, Color(0.2, 0.4, 1.0))  # Blue
	
	if modulator_mapper:
		modulator_mapper.values_changed.connect(_on_modulator_changed)
		var initial = modulator_mapper.get_values()
		_on_modulator_changed(initial.x, initial.y, initial.z)
		modulator_ball = modulator_mapper.get_node_or_null("SpacePoint")
		if modulator_ball:
			last_mod_pos = modulator_ball.global_position
			_color_ball(modulator_ball, Color(1.0, 0.5, 0.1))  # Orange

	# Both mappers are wired before a patch is dealt, so the pull-back below runs
	# the same _on_*_changed path a hand on the ball would.
	_apply_regime()
	_build_evidence()

func _color_ball(ball: Node3D, color: Color) -> void:
	# Find the MeshInstance3D in the ball and color it
	for child in ball.get_children():
		if child is MeshInstance3D:
			var mat = StandardMaterial3D.new()
			mat.albedo_color = color
			mat.emission_enabled = true
			mat.emission = color * 0.3
			child.material_override = mat
			break

func _setup_carrier_mapper() -> void:
	if not carrier_mapper:
		return
	
	# Ball 1: Carrier parameters
	carrier_mapper.label_x = "Carrier Hz"
	carrier_mapper.output_x_min = 100.0
	carrier_mapper.output_x_max = 2000.0
	
	carrier_mapper.label_y = "Attack"
	carrier_mapper.output_y_min = 0.01
	carrier_mapper.output_y_max = 0.5
	
	carrier_mapper.label_z = "Decay"
	carrier_mapper.output_z_min = 0.1
	carrier_mapper.output_z_max = 3.0
	
	# Blue axis colors for carrier
	carrier_mapper.axis_color_x = Color(0.3, 0.5, 1.0)
	carrier_mapper.axis_color_y = Color(0.4, 0.6, 1.0)
	carrier_mapper.axis_color_z = Color(0.5, 0.7, 1.0)

func _setup_modulator_mapper() -> void:
	if not modulator_mapper:
		return
	
	# Ball 2: Modulator parameters
	modulator_mapper.label_x = "Mod Ratio"
	modulator_mapper.output_x_min = 0.5
	modulator_mapper.output_x_max = 8.0
	
	modulator_mapper.label_y = "Mod Index"
	modulator_mapper.output_y_min = 0.0
	modulator_mapper.output_y_max = 10.0
	
	modulator_mapper.label_z = "Mod Decay"
	modulator_mapper.output_z_min = 0.1
	modulator_mapper.output_z_max = 2.0
	
	# Orange axis colors for modulator
	modulator_mapper.axis_color_x = Color(1.0, 0.5, 0.2)
	modulator_mapper.axis_color_y = Color(1.0, 0.6, 0.3)
	modulator_mapper.axis_color_z = Color(1.0, 0.7, 0.4)

func _process(_delta: float) -> void:
	if not play_on_move:
		return
	
	var should_play = false
	
	# Check carrier ball movement
	if carrier_ball:
		var current_pos = carrier_ball.global_position
		if current_pos.distance_to(last_carrier_pos) > movement_threshold:
			should_play = true
			last_carrier_pos = current_pos
	
	# Check modulator ball movement
	if modulator_ball:
		var current_pos = modulator_ball.global_position
		if current_pos.distance_to(last_mod_pos) > movement_threshold:
			should_play = true
			last_mod_pos = current_pos
	
	if should_play:
		var current_time = Time.get_ticks_msec() / 1000.0
		if current_time - last_play_time >= min_play_interval:
			play_sound()
			last_play_time = current_time

func _on_carrier_changed(x: float, y: float, z: float) -> void:
	carrier_freq = x
	attack_time = y
	decay_time = z
	_update_preview_cube()
	_refresh_evidence()

func _on_modulator_changed(x: float, y: float, z: float) -> void:
	mod_ratio = x
	mod_index = y
	mod_decay = z
	_update_preview_cube()
	_refresh_evidence()

func play_sound() -> void:
	var stream = _generate_fm_sound()
	audio_player.stream = stream
	audio_player.play()
	_pulse_preview_cube()

func _generate_fm_sound() -> AudioStreamWAV:
	# Use decay_time as base duration, but cap it
	var duration = min(decay_time * 1.2, 3.0)
	var sample_count = int(SAMPLE_RATE * duration)
	var data = PackedByteArray()
	
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		
		# Attack envelope (linear ramp up)
		var attack_env = 1.0
		if t < attack_time:
			attack_env = t / attack_time
		
		# Decay envelope (exponential decay after attack)
		var decay_env = 1.0
		if t > attack_time:
			decay_env = exp(-(t - attack_time) / decay_time)
		
		# Modulator envelope (exponential decay)
		var mod_env = exp(-t / mod_decay)
		
		# FM synthesis
		# Modulator: sin(2π × carrier_freq × mod_ratio × t) × mod_index × mod_env
		var modulator_freq = carrier_freq * mod_ratio
		var modulator = sin(2.0 * PI * modulator_freq * t) * mod_index * mod_env
		
		# Carrier with phase modulation
		var carrier_env = attack_env * decay_env
		var output = sin(2.0 * PI * carrier_freq * t + modulator) * carrier_env
		
		# Soft clipping to prevent harsh distortion at high mod index
		output = tanh(output * 0.8) * 0.5
		
		var sample_int = int(clamp(output, -1.0, 1.0) * 32767.0)
		data.append(sample_int & 0xFF)
		data.append((sample_int >> 8) & 0xFF)
	
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.data = data
	return stream

func _create_preview_cube() -> void:
	preview_cube = MeshInstance3D.new()
	preview_cube.name = "PreviewCube"
	var box = BoxMesh.new()
	box.size = Vector3(0.25, 0.25, 0.25)
	preview_cube.mesh = box
	preview_cube.position = Vector3(0, -0.8, 0)
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.5, 0.3, 0.8)
	mat.emission_enabled = true
	mat.emission = Color(0.3, 0.2, 0.5)
	preview_cube.material_override = mat
	
	add_child(preview_cube)

func _create_title_label() -> void:
	title_label = Label3D.new()
	title_label.name = "TitleLabel"
	title_label.text = "FM Synth"
	title_label.position = Vector3(0, -1.0, 0)
	title_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	title_label.font_size = 32
	title_label.modulate = Color(0.9, 0.9, 1.0)
	title_label.outline_size = 4
	title_label.outline_modulate = Color(0.0, 0.0, 0.0, 1.0)
	title_label.scale = Vector3.ONE * 0.08
	add_child(title_label)

func _update_preview_cube() -> void:
	if not preview_cube:
		return
	
	var mat = preview_cube.material_override as StandardMaterial3D
	if not mat:
		return
	
	# Color based on sound character:
	# - Hue shifts with mod_ratio (bell-like at integers)
	# - Saturation increases with mod_index
	# - Value tied to carrier frequency
	
	var hue = fmod(mod_ratio / 8.0, 1.0)
	var sat = clamp(mod_index / 10.0, 0.3, 1.0)
	var val = clamp(carrier_freq / 2000.0 * 0.5 + 0.5, 0.5, 1.0)
	
	var color = Color.from_hsv(hue, sat, val)
	mat.albedo_color = color
	mat.emission = color * (0.3 + mod_index * 0.05)

func _pulse_preview_cube() -> void:
	if not preview_cube:
		return
	
	var tween = create_tween()
	tween.tween_property(preview_cube, "scale", Vector3.ONE * 1.6, 0.08)
	tween.tween_property(preview_cube, "scale", Vector3.ONE, 0.5).set_ease(Tween.EASE_OUT)

# Preset methods for quick sound design
func set_bell_preset() -> void:
	# Classic bell: integer ratio, medium index
	if carrier_mapper:
		carrier_mapper.set_values(880.0, 0.01, 2.0)
	if modulator_mapper:
		modulator_mapper.set_values(3.0, 4.0, 1.0)

func set_electric_piano_preset() -> void:
	# E-piano: ratio ~1, moderate index with fast mod decay
	if carrier_mapper:
		carrier_mapper.set_values(440.0, 0.01, 1.5)
	if modulator_mapper:
		modulator_mapper.set_values(1.0, 3.5, 0.3)

func set_brass_preset() -> void:
	# Brass-like: higher ratio, slow attack
	if carrier_mapper:
		carrier_mapper.set_values(220.0, 0.15, 1.0)
	if modulator_mapper:
		modulator_mapper.set_values(1.0, 5.0, 0.8)

func set_metallic_preset() -> void:
	# Metallic/harsh: non-integer ratio, high index
	if carrier_mapper:
		carrier_mapper.set_values(300.0, 0.01, 2.0)
	if modulator_mapper:
		modulator_mapper.set_values(1.414, 8.0, 0.15)

func get_current_params() -> Dictionary:
	return {
		"carrier_freq": carrier_freq,
		"attack_time": attack_time,
		"decay_time": decay_time,
		"mod_ratio": mod_ratio,
		"mod_index": mod_index,
		"mod_decay": mod_decay
	}

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


## LATENT BUG, FIXED HERE. This method existed as `pass`: the artifact advertised a
## configuration hook and silently discarded every key handed to it. It now stores
## the config as metadata in the family's shape and re-reads.
func apply_grid_config(config: Dictionary) -> void:
	for k in config.keys():
		set_meta("config_%s" % str(k), config[k])
	var was_evidence: String = evidence
	var was_regime: String = regime
	_read_meta_overrides()
	# Config can arrive either side of _ready — GridInteractablesComponent defers
	# this call, the sweep sets the export before add_child. Rebuild ONLY when a
	# word actually changed AND _ready has already built once, so a shipped
	# placement carrying no token is never touched.
	if not is_node_ready():
		return
	if regime != was_regime:
		_apply_regime()
	if evidence != was_evidence:
		_teardown_evidence()
		_build_evidence()

func _read_meta_overrides() -> void:
	if has_meta("config_evidence"):
		# The family's one reader — see wave_interference_tank.gd. There must be
		# exactly one place a word is turned into a rung, and it is not this file.
		evidence = WaveInterferenceTank.evidence_name(str(get_meta("config_evidence")))
	if has_meta("config_regime"):
		regime = regime_name(str(get_meta("config_regime")))

# ═════════════════════════════════════════════════════════════════════
# REGIME — which patch the rig is holding
#
# `midpoint` has an explicit, empty case rather than living in the `_:`
# fallthrough: the shipped state is a deliberate rung of this family, not the
# leftovers. Every other rung is one of this file's own preset functions,
# unchanged — the numbers are not re-typed here, they are called.
# ═════════════════════════════════════════════════════════════════════

func _apply_regime() -> void:
	match regime:
		"midpoint":
			return                       # balls where the mapper parked them — untouched
		"bell":
			set_bell_preset()
		"electric_piano":
			set_electric_piano_preset()
		"brass":
			set_brass_preset()
		"metallic":
			set_metallic_preset()
		_:
			return                       # an unrecognised word is the shipped state
	# ValueMapper3D.set_values() moves the point but does not emit values_changed
	# (its _process notices the move a frame later). Pull the values through now so
	# the cube, the scope and the audio agree on this frame, not the next one.
	if carrier_mapper:
		var cv: Vector3 = carrier_mapper.get_values()
		_on_carrier_changed(cv.x, cv.y, cv.z)
	if modulator_mapper:
		var mv: Vector3 = modulator_mapper.get_values()
		_on_modulator_changed(mv.x, mv.y, mv.z)

# ═════════════════════════════════════════════════════════════════════
# EVIDENCE — the ladder of disclosure
#
#   result  <  trace  <  sources  <  longhand
#
# Every rung above `result` builds one scope above the rig and fills its lanes
# from _fm_sample(), which is _generate_fm_sound()'s inner loop with the byte
# packing removed. The arithmetic is not restated here — it is the same
# expression, so a lane cannot drift from the sound it claims to be.
# ═════════════════════════════════════════════════════════════════════

func _build_evidence() -> void:
	var lanes: Array[String] = []
	match evidence:
		"result":
			return                                      # the colour cube alone — shipped, untouched
		"trace":
			lanes.assign(["output"])
		"sources":
			lanes.assign(["modulator", "carrier"])
		"longhand":
			lanes.assign(["modulator", "carrier", "rule", "output"])
		_:
			return                                      # an unrecognised word is the bare outcome
	_build_scope(lanes)

## Only reachable through apply_grid_config; on the default path this never runs.
func _teardown_evidence() -> void:
	if is_instance_valid(_evidence_root):
		_evidence_root.queue_free()
	_evidence_root = null
	_rows.clear()
	_row_meshes.clear()
	_row_y.clear()

func _build_scope(rows: Array[String]) -> void:
	_rows = rows
	_row_meshes.clear()
	_row_y.clear()

	var total: float = 0.0
	for r in rows:
		total += (SCOPE_RULE_H if r == "rule" else SCOPE_ROW_H)
	var plate_h: float = total + 0.06

	_evidence_root = Node3D.new()
	_evidence_root.name = "Evidence"
	add_child(_evidence_root)

	var plate := MeshInstance3D.new()
	plate.name = "ScopePlate"
	var box := BoxMesh.new()
	box.size = Vector3(SCOPE_W + 0.06, plate_h, 0.004)
	plate.mesh = box
	var pm := StandardMaterial3D.new()
	pm.albedo_color = Color(0.05, 0.055, 0.075)
	pm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	plate.material_override = pm
	plate.position = Vector3(SCOPE_X, SCOPE_TOP - plate_h * 0.5, 0.0)
	_evidence_root.add_child(plate)

	var cursor: float = SCOPE_TOP - 0.03
	for r in rows:
		var h: float = (SCOPE_RULE_H if r == "rule" else SCOPE_ROW_H)
		var mid: float = cursor - h * 0.5
		cursor -= h
		_row_y.append(mid)

		var mi := MeshInstance3D.new()
		mi.name = "Lane_%s" % r
		var im := ImmediateMesh.new()
		mi.mesh = im
		var lm := StandardMaterial3D.new()
		lm.vertex_color_use_as_albedo = true
		lm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		lm.cull_mode = BaseMaterial3D.CULL_DISABLED
		mi.material_override = lm
		_evidence_root.add_child(mi)
		_row_meshes.append(im)

		if r != "rule":
			var cap := Label3D.new()
			cap.name = "Cap_%s" % r
			cap.text = _lane_caption(r)
			cap.font_size = 22
			cap.outline_size = 4
			cap.outline_modulate = Color(0, 0, 0, 1)
			cap.modulate = _lane_color(r)
			cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			cap.scale = Vector3.ONE * 0.055
			cap.position = Vector3(SCOPE_X - SCOPE_W * 0.5, mid + h * 0.5 - 0.018, 0.006)
			_evidence_root.add_child(cap)

	_refresh_evidence()

## The terms, written the way the generator writes them. `longhand` earns its name
## from these strings as much as from the curves.
func _lane_caption(kind: String) -> String:
	match kind:
		"modulator":
			return "m(t) = I · e^(−t/τm) · sin(2π · R · fc · t)"
		"carrier":
			return "sin(2π · fc · t)          [unmodulated]"
		"output":
			return "out(t) = sin(2π · fc · t + m(t)) · env(t)"
	return ""

func _lane_color(kind: String) -> Color:
	match kind:
		"modulator":
			return Color(1.0, 0.5, 0.1)     # the modulator ball's own orange
		"carrier":
			return Color(0.3, 0.5, 1.0)     # the carrier ball's own blue
		"output":
			# The output lane is drawn in the timbre colour the preview cube shows,
			# which is what ties every upper rung back to `result`.
			return Color.from_hsv(
				fmod(mod_ratio / 8.0, 1.0),
				clamp(mod_index / 10.0, 0.3, 1.0),
				clamp(carrier_freq / 2000.0 * 0.5 + 0.5, 0.5, 1.0))
	return Color(0.8, 0.82, 0.9)

## _generate_fm_sound()'s inner loop, minus the byte packing. Deliberately spelled
## `2.0 * PI * …` rather than TAU so the two readings of the same expression sit
## character for character beside each other.
func _fm_sample(t: float, kind: String) -> float:
	var mod_env: float = exp(-t / maxf(mod_decay, 0.0001))
	var modulator_freq: float = carrier_freq * mod_ratio
	var m: float = sin(2.0 * PI * modulator_freq * t) * mod_index * mod_env
	match kind:
		"modulator":
			return m / maxf(mod_index, 0.001)
		"carrier":
			return sin(2.0 * PI * carrier_freq * t)
		"output":
			var attack_env: float = 1.0
			if t < attack_time:
				attack_env = t / maxf(attack_time, 0.0001)
			var decay_env: float = 1.0
			if t > attack_time:
				decay_env = exp(-(t - attack_time) / maxf(decay_time, 0.0001))
			var o: float = sin(2.0 * PI * carrier_freq * t + m) * attack_env * decay_env
			# ×2 undoes the generator's ×0.5 headroom so the lane is drawn full-height.
			return tanh(o * 0.8) * 0.5 * 2.0
	return 0.0

func _refresh_evidence() -> void:
	if _row_meshes.is_empty():
		return
	# One scope window, taken at the top of the attack — before that instant every
	# lane is multiplied by a ramp and a still would photograph a flat line.
	var t0: float = attack_time
	var window: float = SCOPE_PERIODS / maxf(carrier_freq, 1.0)

	for i in _rows.size():
		var kind: String = _rows[i]
		var im: ImmediateMesh = _row_meshes[i]
		var y: float = _row_y[i]
		im.clear_surfaces()

		if kind == "rule":
			var bar: Array[Vector3] = [
				Vector3(SCOPE_X - SCOPE_W * 0.5, y, 0.006),
				Vector3(SCOPE_X + SCOPE_W * 0.5, y, 0.006)]
			_ribbon(im, bar, Color(0.86, 0.87, 0.92), 0.0018)
			continue

		var zero: Array[Vector3] = [
			Vector3(SCOPE_X - SCOPE_W * 0.5, y, 0.005),
			Vector3(SCOPE_X + SCOPE_W * 0.5, y, 0.005)]
		_ribbon(im, zero, Color(0.30, 0.32, 0.38), 0.0012)

		var pts: Array[Vector3] = []
		var gain: float = SCOPE_ROW_H * 0.40
		for s in SCOPE_SAMPLES:
			var f: float = float(s) / float(SCOPE_SAMPLES - 1)
			var v: float = _fm_sample(t0 + f * window, kind)
			pts.append(Vector3(
				SCOPE_X + (f - 0.5) * SCOPE_W,
				y + clampf(v, -1.0, 1.0) * gain,
				0.007))
		_ribbon(im, pts, _lane_color(kind), TRACE_THICK)

## A polyline drawn as a flat ribbon in the plate plane. A 1 px LINE_STRIP is
## invisible in a capture at any sane framing, which is how an axis that genuinely
## moves gets reported inert.
func _ribbon(im: ImmediateMesh, pts: Array[Vector3], col: Color, half_thick: float) -> void:
	if pts.size() < 2:
		return
	im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in pts.size() - 1:
		var a: Vector3 = pts[i]
		var b: Vector3 = pts[i + 1]
		var d: Vector3 = b - a
		if d.length() < 0.000001:
			continue
		var n: Vector3 = Vector3(-d.y, d.x, 0.0).normalized() * half_thick
		var quad: Array[Vector3] = [a + n, b + n, b - n, a + n, b - n, a - n]
		for p in quad:
			im.surface_set_color(col)
			im.surface_add_vertex(p)
	im.surface_end()
