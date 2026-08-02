extends Node3D

## Universal Sound Controller
## Generalized version of MarioSoundController supporting multiple sound modes
## Controls various synthesis parameters via a 3D ball (ValueMapper3D)

# Load PickupCube class to access static functions for Mario mode compatibility

# @identity
# essence: waveform(t) = generator(p1, p2, p3, t) where generator in {sweep, noise, square, FM}
# desire: Grab a ball in VR and hear game sound effects respond to your hand position
# critical_parameter: mode — switches between Mario jump, coin, laser, explosion, powerup generators
# triggers: ball movement maps 3D position to three synthesis parameters per mode
# emerges: retro game audio vocabulary from basic waveform mathematics
# needs: VR ball grab [has], mode switching [has]
# relationships: depends on AudioStreamPlayer3D; contrasts with DualBallFMController (preset modes vs free FM); unlocks game audio literacy
# truth: Every game sound is a parametric function of time with at most three degrees of freedom.

const PickupCube = preload("res://commons/scenes/mapobjects/pick_up_cube.gd")

enum SoundMode { MARIO, SINE_BELL, LASER_ZAP, TECHNO_KICK, NOISE_BURST }

@export var mode: SoundMode = SoundMode.MARIO:
	set(v):
		mode = v
		if is_inside_tree():
			_update_mapper_config()

## AXIS — HOW MUCH APPARATUS THIS ADMITS EXISTS BEHIND THE HAND. Not which sound, not the
## generator, not the ranges: those are what the thing TEACHES and they are gameplay here,
## bound to a grabbed ball. What the controller SHOWS is whether a synthesiser is a set of
## three numbers you reach into, or a machine that happens to expose three of them.
##
## Adopted word for word from the seven promoted audio racks (RackMario, RackSineBasic,
## Rack303Acid and the rest, all in this same registry), because this is the same claim
## pointed at a different interface: a 3D mapping volume instead of a panel of sliders.
## Same word, same five moments, so a room holding a rack and this controller cannot have
## one of them admitting a circuit and the other insisting there is no machine.
##
##   none     the legacy lineage, byte for byte — three coloured axes and a ball floating
##            in empty space with nothing behind them. The claim: there is no machine. The
##            sound IS the coordinate, and everything else is furniture.
##   plate    one dark panel behind the volume, edge-lipped, a lit strip along the foot.
##            The machine is admitted as a SURFACE: there is a front, and therefore a back
##            you are not shown. Sound arrives from somewhere.
##   vacancy  the plate plus blanking covers over nine of twelve panel positions, standing
##            proud in lighter metal with a screw at each end, three left open for the
##            three axes this mode maps. The machine is admitted as a FORMAT with slots,
##            most of them closed: what your hand reaches is the small fitted subset of
##            what the frame would accept.
##   frame    no panel at all — two punched rails and two cross members standing around
##            the floating volume, the room visible straight through the middle. The
##            machine is admitted as INSTALLED EQUIPMENT: one unit among many, replaceable.
##   works    no panel either — boards on standoffs, component blocks and wire runs open
##            behind the volume. The machine is admitted as CIRCUITRY, and the ball is
##            revealed as the near end of something soldered.
##
## STRICTLY ADDITIVE. "none" builds nothing at all and is the default, so all eleven
## existing placements render exactly as before. Nothing here touches the ValueMapper3D,
## the ball, the ranges, the labels or the generator — the body is staged AROUND the
## control and stops there.
@export_enum("none", "plate", "vacancy", "frame", "works") var machinery: String = "none"
const MACHINERIES: PackedStringArray = ["none", "plate", "vacancy", "frame", "works"]

@onready var value_mapper = $ValueMapper3D
@onready var audio_player = $AudioStreamPlayer3D

# Internal parameters (names adapted per mode)
var p1: float = 440.0 # Typically Freq/Start
var p2: float = 880.0 # Typically End/Mod
var p3: float = 8.0   # Typically Decay/Speed

# Audio settings
const SAMPLE_RATE = 44100
var sound_duration: float = 0.5

# Continuous playback settings
var play_on_move: bool = true
var last_play_time: float = 0.0
var min_play_interval: float = 0.6
var last_ball_position: Vector3 = Vector3.ZERO
var movement_threshold: float = 0.01

# Auto-save settings
var auto_save_timer: Timer
var save_interval: float = 3.0

var preview_cube: MeshInstance3D
var grab_sphere: Node3D

func _ready() -> void:
	_create_preview_cube()
	_setup_auto_save_timer()
	_update_mapper_config()

	if value_mapper:
		value_mapper.values_changed.connect(_on_values_changed)
		var initial = value_mapper.get_values()
		_on_values_changed(initial.x, initial.y, initial.z)
		
		grab_sphere = value_mapper.get_node_or_null("SpacePoint")
		if grab_sphere:
			last_ball_position = grab_sphere.global_position

	# DNA, LAST: the machinery body is appended after every legacy child exists, so no
	# node above it changes index, position or parent. "none" builds nothing at all.
	var _m: String = str(machinery).strip_edges().to_lower()
	machinery = _m if MACHINERIES.has(_m) else "none"
	_build_machinery()

func _process(_delta: float) -> void:
	if not play_on_move or not grab_sphere:
		return

	var current_pos = grab_sphere.global_position
	if current_pos.distance_to(last_ball_position) > movement_threshold:
		var current_time = Time.get_ticks_msec() / 1000.0
		if current_time - last_play_time >= min_play_interval:
			play_sound()
			last_play_time = current_time
		last_ball_position = current_pos

func _update_mapper_config() -> void:
	if not value_mapper: return
	
	match mode:
		SoundMode.MARIO:
			value_mapper.label_x = "Freq Start"; value_mapper.output_x_min = 200; value_mapper.output_x_max = 800
			value_mapper.label_y = "Freq End"; value_mapper.output_y_min = 400; value_mapper.output_y_max = 1200
			value_mapper.label_z = "Decay Rate"; value_mapper.output_z_min = 2.0; value_mapper.output_z_max = 12.0
		SoundMode.SINE_BELL:
			value_mapper.label_x = "Base Freq"; value_mapper.output_x_min = 100; value_mapper.output_x_max = 2000
			value_mapper.label_y = "Hardness"; value_mapper.output_y_min = 0.0; value_mapper.output_y_max = 1.0
			value_mapper.label_z = "Ring Time"; value_mapper.output_z_min = 0.5; value_mapper.output_z_max = 5.0
		SoundMode.LASER_ZAP:
			value_mapper.label_x = "Pitch"; value_mapper.output_x_min = 400; value_mapper.output_x_max = 3000
			value_mapper.label_y = "Drop"; value_mapper.output_y_min = 50;  value_mapper.output_y_max = 500
			value_mapper.label_z = "Speed"; value_mapper.output_z_min = 5.0; value_mapper.output_z_max = 30.0
		SoundMode.TECHNO_KICK:
			value_mapper.label_x = "Bass Freq"; value_mapper.output_x_min = 40;  value_mapper.output_x_max = 100
			value_mapper.label_y = "Punch"; value_mapper.output_y_min = 0.1; value_mapper.output_y_max = 2.0
			value_mapper.label_z = "Thump"; value_mapper.output_z_min = 2.0; value_mapper.output_z_max = 20.0
		SoundMode.NOISE_BURST:
			value_mapper.label_x = "Tone"; value_mapper.output_x_min = 100; value_mapper.output_x_max = 5000
			value_mapper.label_y = "Harshness"; value_mapper.output_y_min = 0.1; value_mapper.output_y_max = 1.0
			value_mapper.label_z = "Length"; value_mapper.output_z_min = 0.05; value_mapper.output_z_max = 0.5

	if value_mapper.has_method("update_labels"):
		value_mapper.call("update_labels")
	else:
		# Fallback: Manually update labels if method missing
		var x_l = value_mapper.get_node_or_null("XLabel")
		var y_l = value_mapper.get_node_or_null("YLabel")
		var z_l = value_mapper.get_node_or_null("ZLabel")
		if x_l: x_l.text = value_mapper.label_x
		if y_l: y_l.text = value_mapper.label_y
		if z_l: z_l.text = value_mapper.label_z
	
	# Force an update of the output text
	if value_mapper.has_method("_update_output"):
		value_mapper.call("_update_output")

func apply_grid_config(data: Dictionary) -> void:
	print("UniversalSound: Config received: %s" % data)
	if data.has("mode"):
		var m_str = data.mode.to_upper()
		if SoundMode.has(m_str): mode = SoundMode[m_str]
	if data.has("freq_start"): p1 = float(data.freq_start)
	if data.has("freq_end"): p2 = float(data.freq_end)
	if data.has("decay"): p3 = float(data.decay)
	_update_mapper_config()
	# An unknown word keeps the standing value; a config without the key is left alone,
	# because composers hand this dictionary round wholesale.
	if data.has("machinery"):
		var want: String = str(data["machinery"]).strip_edges().to_lower()
		if MACHINERIES.has(want) and want != machinery:
			machinery = want
			_build_machinery()

func _on_values_changed(x: float, y: float, z: float) -> void:
	p1 = x; p2 = y; p3 = z
	if preview_cube:
		var mat = preview_cube.material_override as StandardMaterial3D
		if mat:
			var hue = 0.0
			match mode:
				SoundMode.MARIO: hue = 0.1 # Orange
				SoundMode.SINE_BELL: hue = 0.6 # Blue
				SoundMode.LASER_ZAP: hue = 0.8 # Purple
				SoundMode.TECHNO_KICK: hue = 0.0 # Red
				SoundMode.NOISE_BURST: hue = 0.3 # Green
			mat.albedo_color = Color.from_hsv(hue, 0.7, 0.9)
			mat.emission = mat.albedo_color * 0.5

func play_sound() -> void:
	var stream = _generate_sound()
	audio_player.stream = stream
	audio_player.play()
	_pulse_preview_cube()

func _generate_sound() -> AudioStreamWAV:
	var duration = sound_duration
	if mode == SoundMode.SINE_BELL: duration = p3
	elif mode == SoundMode.NOISE_BURST: duration = p3
	
	var sample_count = int(SAMPLE_RATE * duration)
	var data = PackedByteArray()

	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		var sample_value = 0.0

		match mode:
			SoundMode.MARIO:
				var freq = p1 + ((p2 - p1) * progress)
				var env = exp(-progress * p3)
				sample_value = (1.0 if sin(2.0 * PI * freq * t) > 0 else -1.0) * env * 0.3
			
			SoundMode.SINE_BELL:
				var freq = p1
				var env = exp(-progress * (5.0 / p3)) # Z maps to Ring Time
				# Add subtle harmonic based on p2 (Hardness)
				sample_value = sin(2.0 * PI * freq * t) * env * 0.4
				if p2 > 0.1:
					sample_value += sin(4.0 * PI * freq * t) * env * p2 * 0.2
			
			SoundMode.LASER_ZAP:
				var freq = p1 * exp(-progress * p3) # Exponential drop
				sample_value = (2.0 * (freq * t - floor(freq * t + 0.5))) * 0.3 # Sawtooth
			
			SoundMode.TECHNO_KICK:
				var freq = p1 * exp(-progress * p3) + 20.0
				var env = pow(1.0 - progress, p2) # Punch defines curve
				sample_value = sin(2.0 * PI * freq * t) * env * 0.6
			
			SoundMode.NOISE_BURST:
				var raw_noise = randf_range(-1.0, 1.0)
				# Simple low-pass like effect using p1 (Tone)
				var env = 1.0 - progress
				sample_value = raw_noise * env * 0.5

		var sample_int = int(clamp(sample_value, -1.0, 1.0) * 32767.0)
		data.append(sample_int & 0xFF)
		data.append((sample_int >> 8) & 0xFF)

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.data = data
	return stream

func _create_preview_cube() -> void:
	preview_cube = MeshInstance3D.new()
	preview_cube.mesh = BoxMesh.new(); preview_cube.mesh.size = Vector3(0.2, 0.2, 0.2)
	preview_cube.position = Vector3(0, -0.5, 0)
	preview_cube.material_override = StandardMaterial3D.new()
	preview_cube.material_override.emission_enabled = true
	add_child(preview_cube)
	
	var label = Label3D.new()
	label.text = "Universal Sound"; label.position = Vector3(0, -0.65, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED; label.font_size = 24
	label.scale = Vector3.ONE * 0.08
	add_child(label)

func _pulse_preview_cube() -> void:
	if not preview_cube: return
	var tween = create_tween()
	tween.tween_property(preview_cube, "scale", Vector3.ONE * 1.5, 0.1)
	tween.tween_property(preview_cube, "scale", Vector3.ONE, 0.4)

func _setup_auto_save_timer() -> void:
	auto_save_timer = Timer.new()
	auto_save_timer.wait_time = save_interval; auto_save_timer.autostart = true
	auto_save_timer.timeout.connect(_on_auto_save_timeout)
	add_child(auto_save_timer)

func _on_auto_save_timeout() -> void:
	if mode == SoundMode.MARIO:
		PickupCube.set_shared_mario_parameters(p1, p2, p3, sound_duration)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


# ── MACHINERY ─────────────────────────────────────────────────────────────────
# One axis, five moments, shared word for word with the promoted audio racks in
# addons/element_editor/element_layout_node.gd. Everything below runs AFTER the legacy
# _ready() body and lives inside one host node, so removing it restores the legacy scene
# exactly. Nothing here reads or writes p1/p2/p3, the mode, or the mapper's ranges.

const MACH_HOST := "SoundMachinery"
const MACH_BACK := 0.055    # air between the mapping volume's z = 0 face and the body
const MACH_PLATE := 0.016   # panel thickness
const MACH_COVER := 0.010   # blanking cover thickness, standing proud of the panel
## How far the body oversails the 0.6 m mapping volume on each side. Sized up from the
## rack's own margins on purpose: the sweep frames this artifact by its AABB diagonal
## (0.76 x 1.26 x 0.76, so a 3.1 m field of view), and a body that only just cleared the
## volume would have been about 5% of the frame — inside the range where a real axis reads
## as noise. At 0.14 the panel is a clear eighth of the picture.
const MACH_MARGIN := 0.14


func _build_machinery() -> void:
	var old: Node = get_node_or_null(MACH_HOST)
	if old != null:
		remove_child(old)
		old.queue_free()
	if machinery == "none" or not MACHINERIES.has(machinery):
		return                       # the legacy lineage builds nothing at all
	var host := Node3D.new()
	host.name = MACH_HOST
	add_child(host)

	var space: Vector3 = Vector3(0.6, 0.6, 0.6)
	if value_mapper != null and value_mapper.get("space_size") != null:
		space = value_mapper.space_size
	var w: float = space.x + MACH_MARGIN * 2.0
	var h: float = space.y + MACH_MARGIN * 2.0
	var cx: float = space.x * 0.5
	var cy: float = space.y * 0.5
	var back: float = -MACH_BACK

	match machinery:
		"plate":
			_machinery_plate(host, cx, cy, w, h, back)
		"vacancy":
			_machinery_plate(host, cx, cy, w, h, back)
			_machinery_vacancy(host, cx, cy, w, h, back)
		"frame":
			_machinery_frame(host, cx, cy, w, h)
		"works":
			_machinery_works(host, cx, cy, w, h, back)
		_:
			pass


## PLATE — the machine as a SURFACE. One dark panel filling the space behind the volume, a
## lip standing past its edge, a lit strip along the foot. The controller acquires a front,
## and therefore a back you are not shown.
func _machinery_plate(host: Node3D, cx: float, cy: float, w: float, h: float, back: float) -> void:
	var shell: StandardMaterial3D = _mach_mat(Color(0.125, 0.130, 0.150), 0.72, 0.25)
	var lip: StandardMaterial3D = _mach_mat(Color(0.075, 0.078, 0.092), 0.62, 0.45)
	_mach_box(host, Vector3(cx, cy, back - MACH_PLATE * 0.5), Vector3(w, h, MACH_PLATE), shell)
	_mach_box(host, Vector3(cx, cy, back - MACH_PLATE - 0.004),
		Vector3(w + 0.026, h + 0.026, 0.008), lip)
	# The only emissive surface on the body, so it owns the brightest pixels in any frame
	# the controller appears in — "there is a machine, and it is powered" from across a room.
	_mach_box(host, Vector3(cx, cy - h * 0.5 + 0.028, back + 0.004),
		Vector3(w * 0.66, 0.007, 0.006), _mach_lit(Color(0.20, 0.85, 1.0)))


## VACANCY — the machine as a FORMAT. Twelve panel positions in a 4 x 3 field; the three in
## the left-hand column stay open for the three axes this mode maps, and the other nine take
## blanking covers in lighter metal with a screw at each end. What your hand can reach is
## shown as the small fitted subset of what the frame would accept.
func _machinery_vacancy(host: Node3D, cx: float, cy: float, w: float, h: float, back: float) -> void:
	var cover: StandardMaterial3D = _mach_mat(Color(0.215, 0.225, 0.250), 0.55, 0.38)
	var screw: StandardMaterial3D = _mach_mat(Color(0.42, 0.43, 0.46), 0.35, 0.75)
	var cols: int = 4
	var rows: int = 3
	var gap: float = 0.010
	var cw: float = w / float(cols)
	var ch: float = h / float(rows)
	var cn: float = back + MACH_COVER * 0.5
	for gx in range(cols):
		for gy in range(rows):
			if gx == 0:
				continue            # the three mapped axes keep their positions open
			var u: float = cx - w * 0.5 + (float(gx) + 0.5) * cw
			var v: float = cy - h * 0.5 + (float(gy) + 0.5) * ch
			_mach_box(host, Vector3(u, v, cn), Vector3(cw - gap, ch - gap, MACH_COVER), cover)
			for sx in [-1.0, 1.0]:
				var sf: float = float(sx)
				_mach_box(host, Vector3(u + sf * maxf(cw * 0.5 - gap - 0.012, 0.006), v,
					cn + MACH_COVER * 0.5), Vector3(0.008, 0.008, 0.005), screw)


## FRAME — the machine as INSTALLED EQUIPMENT. Two punched rails and two cross members stand
## around the volume and the middle stays open, so the room shows through where a panel would
## be. One unit among many, rackable, made to be pulled and replaced.
func _machinery_frame(host: Node3D, cx: float, cy: float, w: float, h: float) -> void:
	var rail: StandardMaterial3D = _mach_mat(Color(0.300, 0.310, 0.340), 0.42, 0.68)
	var hole: StandardMaterial3D = _mach_mat(Color(0.045, 0.045, 0.055), 0.85, 0.10)
	var rail_w: float = 0.042
	var depth: float = 0.070
	var cn: float = -0.030
	for sx in [-1.0, 1.0]:
		var sf: float = float(sx)
		var ru: float = cx + sf * (w * 0.5 + rail_w * 0.5 + 0.006)
		_mach_box(host, Vector3(ru, cy, cn), Vector3(rail_w, h + 0.09, depth), rail)
		for k in range(7):
			var hv: float = cy - h * 0.5 + (float(k) + 0.5) * (h / 7.0)
			_mach_box(host, Vector3(ru, hv, cn + depth * 0.5 - 0.004),
				Vector3(0.014, 0.014, 0.009), hole)
	var span: float = w + 2.0 * (rail_w + 0.012)
	for sy in [-1.0, 1.0]:
		var sg: float = float(sy)
		_mach_box(host, Vector3(cx, cy + sg * (h * 0.5 + 0.034), cn),
			Vector3(span, 0.034, depth * 0.85), rail)


## WORKS — the machine as CIRCUITRY. Three boards on standoffs behind the volume, component
## blocks on their faces, wire runs crossing between them, side posts holding the stack. No
## panel at all: the ball stops pretending the sound comes from nowhere.
func _machinery_works(host: Node3D, cx: float, cy: float, w: float, h: float, back: float) -> void:
	var board: StandardMaterial3D = _mach_mat(Color(0.085, 0.230, 0.155), 0.62, 0.15)
	var stand: StandardMaterial3D = _mach_mat(Color(0.380, 0.390, 0.420), 0.40, 0.72)
	var part: StandardMaterial3D = _mach_mat(Color(0.100, 0.100, 0.120), 0.70, 0.20)
	var wire: StandardMaterial3D = _mach_mat(Color(0.620, 0.360, 0.160), 0.55, 0.45)
	var bn: float = back - 0.052
	var bw: float = w * 0.27
	var bh: float = h * 0.64
	for i in range(3):
		var off: float = -0.02
		if i == 1:
			off = 0.06
		var bu: float = cx + w * (-0.315 + 0.315 * float(i))
		var bv: float = cy + h * off
		_mach_box(host, Vector3(bu, bv, bn), Vector3(bw, bh, 0.006), board)
		for sx in [-1.0, 1.0]:
			for sy in [-1.0, 1.0]:
				var fx: float = float(sx)
				var fy: float = float(sy)
				_mach_box(host, Vector3(bu + fx * (bw * 0.5 - 0.016),
					bv + fy * (bh * 0.5 - 0.016), bn + 0.022),
					Vector3(0.011, 0.011, 0.044), stand)
		for k in range(3):
			var kv: float = bv + bh * (0.28 - 0.28 * float(k))
			_mach_box(host, Vector3(bu - bw * 0.16 + bw * 0.16 * float(k), kv, bn + 0.013),
				Vector3(bw * 0.34, h * 0.055, 0.019), part)
	for wk in range(5):
		var wv: float = cy - h * 0.5 + h * (0.13 + 0.185 * float(wk))
		_mach_box(host, Vector3(cx, wv, bn + 0.036), Vector3(w * 0.92, 0.006, 0.006), wire)
	for px in [-1.0, 1.0]:
		var pf: float = float(px)
		_mach_box(host, Vector3(cx + pf * (w * 0.5 + 0.014), cy, bn + 0.028),
			Vector3(0.017, h * 0.92, 0.056), stand)


# ── machinery helpers ─────────────────────────────────────────────────────────

func _mach_box(host: Node3D, centre: Vector3, size: Vector3, mat: Material) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = centre
	host.add_child(mi)


func _mach_mat(c: Color, rough: float, metal: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	return m


func _mach_lit(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = 2.4
	return m

