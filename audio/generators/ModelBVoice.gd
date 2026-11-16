extends RefCounted
## MODEL B'S VOICE IN GDSCRIPT, LEARNED FROM THE RUST ENGINE (Palle, 2026-11-16: "we have to learn from the rust
## project and improve the godot voice")
##
## The kit's approved voice is the Chimera engine: a physical airway model in Rust, far too many operations a
## sample for GDScript. What can be carried over is what its source code says about HOW that voice sings, and the
## numbers its approved settings come to. This renderer keeps the kit's robot articulation (which formants a
## phoneme has, how consonant noise is made: RobotVoiceGenerator.gd, unchanged) and replaces everything else:
##
##   THE SOURCE (vendor/chimera/src/sources/glottis.rs, voice/human_voice.rs). Not a sawtooth: the engine's own
##   glottal pulse - a raised-cosine opening and closing of the folds with an open quotient, a skew and a closure
##   sharpness - and the approved settings put through the engine's own formulas: tension 0.28 and pressure 7
##   give an open quotient of 0.70, brightness 0.12 a closure sharpness of 0.01 (the folds close softly: that is
##   the warmth), skew 0.58; roughness 0.01 gives 0.24 % jitter and 2.2 % shimmer, a cycle at a time. What is
##   heard is the slope of that pulse, as at the lips. Breath: noise that follows the opening of the folds, over
##   a leak that never closes (breathiness 0.18).
##   THE PITCH (phonetics/sing.rs). An onset consonant already has the new note; the pitch glides with a 30 ms
##   time constant; vibrato comes only on held vowels, 0.22 s after the vowel begins, growing over 0.3 s, 5.3 Hz;
##   a slow drift of 2 cents; the vibrato's own rate wanders with the drift.
##   THE BREATH (native/chimera-original/src/lib.rs). One breath a phrase, not a gate a word: pressure
##   (0.60 + 0.40 x the syllable's weight) x an arc over the phrase, rising in 55 ms and released in 25. Between
##   words the voice goes on if the sounds either side are voiced.
##   THE TRACT. Five resonators one after another (a cascade), not five side by side: the levels of the formants
##   then come from the tube, as in a throat, instead of from a table. A female body (the engine's scale 0.9):
##   the formants 1.12 times the robot's.
##
## Measured against the kit's own recordings of the approved voice with tools/probes/voice_compare.py; the numbers
## are in the commit that added this file. It is still a formant voice, not the airway model: nobody should expect
## it to be the same voice.
##
## render_phrase(plan, options): the same plan the robot takes. Options (all optional): formant_ratio 0.8-1.3,
## transpose (semitones), gain, seed; tension, breathiness, brightness, roughness 0-1; pressure (cmH2O);
## vibrato_depth_cents, vibrato_rate, drift_cents, glide_s.
const Robot := preload("res://audio/generators/RobotVoiceGenerator.gd")
const SR := 44100
const BLOCK := 32
const DEFAULTS := {"formant_ratio": 1.12, "transpose": 0.0, "gain": 1.0, "seed": 7241,
	"tension": 0.28, "breathiness": 0.18, "brightness": 0.12, "roughness": 0.01, "pressure": 7.0,
	"vibrato_depth_cents": 12.0, "vibrato_rate": 5.3, "drift_cents": 2.0, "glide_s": 0.03,
	"flow_skew": 0.17, "flow_sharpness": 0.45, "air": 0.62, "vibrato_reach": 1.4, "f2_lift": 0.3, "upper_damping": 2.0}
const RANGES := {"tension": [0.0, 1.0], "breathiness": [0.0, 1.0], "brightness": [0.0, 1.0], "roughness": [0.0, 1.0], "pressure": [0.0, 20.0],
	"vibrato_depth_cents": [0.0, 100.0], "vibrato_rate": [0.0, 12.0], "drift_cents": [0.0, 50.0], "glide_s": [0.001, 0.3],
	"flow_skew": [0.0, 0.3], "flow_sharpness": [0.0, 1.0], "air": [0.0, 1.0], "vibrato_reach": [0.5, 3.0], "f2_lift": [0.0, 0.8], "upper_damping": [0.5, 4.0]}
const PEAK := 0.5                         # every phrase leaves the renderer at this peak, times `gain`


## "" when the plan and the options can be rendered, otherwise why not.
static func validate_plan(plan: Dictionary, options: Dictionary = {}) -> String:
	var robot_options := {}
	for key in ["formant_ratio", "transpose", "seed"]:
		if options.has(key): robot_options[key] = options[key]
	var wrong: String = Robot.validate_plan(plan, robot_options)
	if not wrong.is_empty(): return wrong
	for key in options:
		if RANGES.has(key):
			var value: Variant = options[key]
			if not (value is float or value is int) or float(value) < float(RANGES[key][0]) or float(value) > float(RANGES[key][1]):
				return "%s must be between %s and %s" % [key, str(RANGES[key][0]), str(RANGES[key][1])]
		elif not DEFAULTS.has(key):
			return "unknown option: " + str(key)
	if options.has("gain") and (float(options.gain) <= 0.0 or float(options.gain) > 2.0): return "gain must be between 0 and 2"
	return ""


## The engine's formulas for the folds, from the settings (voice/human_voice.rs).
static func folds(o: Dictionary) -> Dictionary:
	var effort: float = clampf((float(o.pressure) - 3.0) / 10.0, 0.0, 1.0)
	var bright: float = float(o.brightness) - 0.25
	var tension: float = float(o.tension)
	return {"open_quotient": clampf(0.78 - 0.36 * tension - 0.18 * (effort - 0.5), 0.25, 0.98),
		"sharpness": clampf(0.4 * tension + 1.375 * maxf(0.0, tension - 0.6) + 0.8 * bright, 0.0, 1.0),
		"skew": clampf(0.56 + 0.16 * tension + 0.2 * bright, 0.3, 0.9),
		"jitter": 0.0021 + 0.0245 * float(o.roughness), "shimmer": 0.02 + 0.22 * float(o.roughness),
		"leak": (0.008 + 0.03 * float(o.breathiness)) / (0.16 * (0.45 + 0.75 * effort)), "effort": effort}


static func render_phrase(plan: Dictionary, options: Dictionary = {}) -> PackedFloat32Array:
	var wrong := validate_plan(plan, options)
	if not wrong.is_empty():
		push_error(wrong)
		return PackedFloat32Array()
	var o: Dictionary = DEFAULTS.duplicate()
	o.merge(options, true)
	var c: Dictionary = Robot.build_controls(plan, {"formant_ratio": float(o.formant_ratio), "transpose": float(o.transpose)})
	if c.has("error"):
		push_error(c.error)
		return PackedFloat32Array()
	var n := int(plan.frames)
	var syllables: Array = plan.syllables
	var phones: Array = plan.phones
	var f: Dictionary = folds(o)
	var oq: float = f.open_quotient
	# The engine computes the FLOW through the folds from their opening (Bernoulli, and the inertia of the air above
	# them): the flow lags the opening and stops more abruptly than the folds close. Here that is two numbers, set
	# by measuring against the recordings of the approved voice, not by the physics.
	var skew: float = clampf(float(f.skew) + float(o.flow_skew), 0.3, 0.92)
	var sharp: float = clampf(float(f.sharpness) + float(o.flow_sharpness), 0.0, 1.0)
	var rng := posmod(int(o.seed), 2147483646) + 1

	# --- consonant noise, as the robot makes it ---
	var noise := PackedFloat64Array()
	noise.resize(n)
	var robot_rng: Array = [rng]
	for p in phones:
		if p.kind == "consonant":
			var hz := 440.0 * pow(2.0, (float(p.midi) + float(o.transpose) - 69.0) / 12.0)
			var part: PackedFloat64Array = Robot._consonant(p.phoneme, int(p.end) - int(p.start), hz, robot_rng)
			var at := int(p.start)
			for i in part.size(): noise[at + i] += part[i]

	# --- how much the folds sound, phone by phone; a gap between two voiced sounds stays voiced ---
	var voiced := PackedFloat32Array()
	voiced.resize(n)
	for k in phones.size():
		var p: Dictionary = phones[k]
		var level: float = Robot._voice_level(p)
		for i in range(int(p.start), int(p.end)): voiced[i] = level
		if k + 1 < phones.size() and int(phones[k + 1].start) > int(p.end):
			var across: float = minf(level, Robot._voice_level(phones[k + 1]))
			for i in range(int(p.end), int(phones[k + 1].start)): voiced[i] = across

	# --- the breath: one pressure a phrase, a target a syllable ---
	var count := syllables.size()
	var breath_target := PackedFloat32Array()
	breath_target.resize(n)
	var note := PackedFloat32Array()         # the written note at every frame: an onset consonant has the new one
	note.resize(n)
	var vib := PackedFloat32Array()          # how much of the vibrato a frame gets, 0..1
	vib.resize(n)
	var phrase_from := int(syllables[0].start)
	var phrase_to := int(syllables[count - 1].end)
	for k in count:
		var s: Dictionary = syllables[k]
		var from := 0 if k == 0 else int(s.start)
		var to := n if k == count - 1 else int(syllables[k + 1].start)
		var progress: float = float(k) / float(maxi(count, 2) - 1)
		var pressure: float = (0.60 + 0.40 * float(s.gain)) * (0.94 + 0.06 * sin(PI * progress))
		var midi: float = float(s.midi) + float(o.transpose)
		for i in range(from, to):
			note[i] = midi
			breath_target[i] = pressure if i >= phrase_from and i < phrase_to - int(0.025 * SR) else 0.0
		# vibrato on a held vowel only: after 0.22 s, growing over 0.3 s, let go over the last 0.06 s
		var v0 := int(s.vowel)
		var v1 := int(s.end)
		if float(v1 - v0) / SR >= 0.34:
			var begin := v0 + int(0.22 * SR)
			var grow := int(0.3 * SR)
			var let_go := int(0.06 * SR)
			for i in range(begin, v1):
				vib[i] = minf(minf(1.0, float(i - begin) / grow), minf(1.0, float(v1 - i) / let_go))

	# --- the sound, a sample at a time ---
	var out := PackedFloat32Array()
	out.resize(n)
	var semitone := float(note[0])
	var glide: float = 1.0 - exp(-float(BLOCK) / (float(o.glide_s) * SR))
	var depth: float = float(o.vibrato_depth_cents) * float(o.vibrato_reach)      # the engine's 12 cents measure 16.8 in its recordings
	var rate: float = float(o.vibrato_rate)
	var drift_cents: float = float(o.drift_cents)
	var drift := 0.0
	var drift_step: float = 1.0 - exp(-TAU * 0.3 * BLOCK / SR)
	var vib_phase := 0.0
	var step := 0.0
	var step_slope := 0.0
	var phase := 0.0
	var period_scale := 1.0
	var cycle_amp := 1.0
	var last_flow := 0.0
	var breath := 0.0
	var rise: float = 1.0 - exp(-1.0 / (0.018 * SR))
	var fall: float = 1.0 - exp(-1.0 / (0.010 * SR))
	var voice_now := 0.0
	var voice_step: float = 1.0 - exp(-1.0 / (0.006 * SR))
	var breathiness: float = float(o.breathiness)
	var air: float = float(o.air)
	var f2_lift: float = float(o.f2_lift)
	var upper_damping: float = float(o.upper_damping)
	var leak: float = f.leak
	var asp_last := 0.0
	var asp_low := 0.0
	# the tract: five resonators in a row, their coefficients moved a block at a time
	var a0 := [0.0, 0.0, 0.0, 0.0, 0.0]
	var c1 := [0.0, 0.0, 0.0, 0.0, 0.0]
	var c2 := [0.0, 0.0, 0.0, 0.0, 0.0]
	var y1 := [0.0, 0.0, 0.0, 0.0, 0.0]
	var y2 := [0.0, 0.0, 0.0, 0.0, 0.0]
	var dc_x := 0.0
	var dc_y := 0.0
	var peak := 0.0
	var jitter: float = f.jitter
	var shimmer: float = f.shimmer
	var s_open: float = skew
	var s_close: float = 1.0 - skew
	for i in n:
		if i % BLOCK == 0:
			semitone += glide * (float(note[i]) - semitone)
			rng = (rng * 48271) % 2147483647
			drift += drift_step * ((float(rng) / 2147483647.0 * 2.0 - 1.0) * 26.0 - drift)
			vib_phase = fposmod(vib_phase + rate * BLOCK / SR * (1.0 + 0.04 * drift), 1.0)
			var cents: float = depth * float(vib[i]) * sin(TAU * vib_phase) + drift_cents * drift
			var next_step: float = 440.0 * pow(2.0, (semitone + cents / 100.0 - 69.0) / 12.0) / SR
			if i == 0: step = next_step
			step_slope = (next_step - step) / BLOCK
			var tract: Array = Robot.tract_at(c, i)
			for k in 5:
				# a shorter throat lifts a LOW second formant (the back vowels: aw, o, u) more than the first; a high
				# one (i, e) stays; the upper formants are damped more
				var hz: float = float(tract[0][k])
				if k == 1: hz *= 1.0 + f2_lift * clampf((1700.0 - hz) / 800.0, 0.0, 1.0)
				hz = minf(hz, SR * 0.45)
				var r: float = exp(-PI * float(tract[1][k]) * (upper_damping if k >= 2 else 1.0) / SR)
				c1[k] = 2.0 * r * cos(TAU * hz / SR)
				c2[k] = -r * r
				a0[k] = 1.0 - c1[k] - c2[k]
		step += step_slope
		phase += step / period_scale
		if phase >= 1.0:
			phase -= 1.0
			# a cycle at a time: the period and the size of the pulse are never quite the same twice
			rng = (rng * 48271) % 2147483647
			var u1: float = float(rng) / 2147483647.0
			rng = (rng * 48271) % 2147483647
			var u2: float = float(rng) / 2147483647.0
			rng = (rng * 48271) % 2147483647
			var u3: float = float(rng) / 2147483647.0
			var gauss: float = (u1 + u2 + u3 - 1.5) * 2.0
			period_scale = clampf(1.0 + jitter * gauss, 0.55, 1.8)
			cycle_amp = maxf(0.12, 1.0 + shimmer * (u1 - u3) * 2.45)
		# the engine's pulse: how far the folds are open at this point of the cycle
		var flow := 0.0
		if phase < oq:
			var t: float = phase / oq
			if t < s_open:
				flow = 0.5 - 0.5 * cos(PI * t / s_open)
			else:
				var u: float = (t - s_open) / s_close
				var soft: float = 0.5 + 0.5 * cos(PI * u)
				flow = soft + (cos(0.5 * PI * u) - soft) * sharp
		flow *= cycle_amp
		# what is heard is its slope, as at the lips
		var pulse: float = (flow - last_flow) / maxf(step, 0.0005)
		last_flow = flow
		# breath: noise that follows the opening of the folds, over a leak that never closes
		rng = (rng * 48271) % 2147483647
		var white: float = float(rng) / 1073741823.5 - 1.0
		asp_low += 0.5 * (white - asp_low)
		var aspiration: float = (white - asp_low) * (leak * 2.0 + flow) * breathiness * 1.9
		asp_last = white
		var target: float = breath_target[i]
		breath += (rise if target > breath else fall) * (target - breath)
		voice_now += voice_step * (float(voiced[i]) - voice_now)
		var x: float = (pulse * 0.16 + aspiration) * voice_now * breath
		for k in 5:
			var y: float = a0[k] * x + c1[k] * y1[k] + c2[k] * y2[k]
			y2[k] = y1[k]
			y1[k] = y
			x = y
		# the breath is also heard as it is, not only through the throat: turbulence is made all along the tract
		x += noise[i] * 0.42 * breath + aspiration * air * voice_now * breath
		# nothing below the voice
		var y_out: float = x - dc_x + 0.995 * dc_y
		dc_x = x
		dc_y = y_out
		out[i] = y_out
		peak = maxf(peak, absf(y_out))
	if peak <= 0.0: return out
	var gain: float = PEAK * float(o.gain) / peak
	var edge := int(0.005 * SR)
	for i in n:
		out[i] = clampf(out[i] * gain * minf(1.0, float(mini(i, n - 1 - i)) / edge), -1.0, 1.0)
	return out
