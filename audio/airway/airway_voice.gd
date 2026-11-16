extends RefCounted
## A human voice made of air: lungs push air through folds that open and close, into a throat and mouth
## that move, and what leaves the lips and nose is the sound. The folds give an AREA in time; the flow
## through them comes from the air column, so the tilt of the pulse, the ripple of the first formant and
## the voice dying under a closed mouth come out of the physics. The air column is stepped above the
## output rate and brought down by a filter.
##
## Each control step (64 output samples): the gestures of the score are blended, the articulators follow
## their targets as critically damped masses, the head's geometry gives the passage areas, the tongue is
## kept out of the palate, the breath and the pitch glide toward theirs.
##
## A GDScript port of Chimera's human voice, parametric glottis and articulator dynamics, (c) 2026 Jameson
## Hodge, MIT licence (audio/airway/LICENSE.chimera). No native code.

const Net := preload("res://audio/airway/airway_network.gd")
const Tract := preload("res://audio/airway/human_tract.gd")
const Airway := preload("res://audio/airway/human_airway.gd")
const Score := preload("res://audio/airway/gesture_score.gd")
const M32 := 0xFFFFFFFF
const CM_H2O := 980.665
const DEFAULT_SOURCE := {"f0": 110.0, "glide": 0.06, "pressure": 8.0, "breathiness": 0.15, "tension": 0.5, "fry": 0.0, "roughness": 0.1,
	"vibratoDepth": 0.0, "vibratoRate": 6.0, "drift": 5.0, "voiced": true, "brightness": 0.25}
## Each articulator's least, most, and natural frequency (Hz), in the tract's order.
const ARTIC_SPECS := [[-0.1, 2.6, 10.0], [1.0, 4.8, 12.0], [4.8, 9.2, 12.0], [3.5, 8.0, 13.0], [5.0, 10.8, 13.0], [0.0, 1.0, 9.0], [-1.0, 1.0, 9.0],
	[-0.4, 2.4, 11.0], [-0.2, 1.5, 11.0], [0.0, 1.0, 11.0], [0.0, 1.0, 10.0], [-0.25, 1.4, 12.0], [-1.6, 1.6, 8.0], [0.0, 1.0, 6.0], [0.0, 1.0, 6.0],
	[0.0, 1.0, 10.0], [0.0, 1.0, 9.0]]


## The engine's generator (mulberry32), uniform in [0, 1).
class Rng:
	var s := 1

	func _init(seed_value: int) -> void:
		s = 1 if seed_value == 0 else seed_value

	func next() -> float:
		s = (s + 0x6d2b79f5) & 0xFFFFFFFF
		var q := s
		var x1 := q ^ (q >> 15)
		var y1 := q | 1
		q = ((x1 & 0xFFFF) * y1 + ((((x1 >> 16) * y1) & 0xFFFF) << 16)) & 0xFFFFFFFF
		var x2 := q ^ (q >> 7)
		var y2 := q | 61
		q = q ^ ((q + (((x2 & 0xFFFF) * y2 + ((((x2 >> 16) * y2) & 0xFFFF) << 16)) & 0xFFFFFFFF)) & 0xFFFFFFFF)
		return float((q ^ (q >> 14)) & 0xFFFFFFFF) / 4294967296.0

	## Roughly standard normal: four uniforms, scaled.
	func gauss() -> float:
		var a := next()
		var b := next()
		var c := next()
		var d := next()
		return (a + b + c + d - 2.0) * 1.7320508


## Slow wandering, roughly 1/f: three filtered noises an octave and a half apart.
class Drift:
	var y := PackedFloat64Array([0.0, 0.0, 0.0])
	var a := PackedFloat64Array([0.0, 0.0, 0.0])
	var rng: Rng

	func _init(control_rate: float, base_hz: float, seed_value: int) -> void:
		a[0] = exp((-TAU * base_hz) / control_rate)
		a[1] = exp((-TAU * (base_hz * 3.0)) / control_rate)
		a[2] = exp((-TAU * (base_hz * 9.0)) / control_rate)
		rng = Rng.new(seed_value)

	func step() -> float:
		var sum := 0.0
		for i in 3:
			var c := a[i]
			y[i] = c * y[i] + sqrt(1.0 - c * c) * rng.gauss()
			sum += y[i] / (float(i) + 1.0)
		return sum / 1.4


## The folds: an area in time. Voicing needs pressure across the folds above a threshold and the folds
## close enough together; jitter, shimmer, vibrato and drift are per cycle or slow.
class Glottis:
	var fs := 0.0
	var f0 := 110.0
	var amplitude := 0.16
	var abduction := 0.0
	var chink := 0.006
	var open_quotient := 0.62
	var skew := 0.62
	var closure_sharpness := 0.6
	var effort := 0.7
	var jitter := 0.004
	var shimmer := 0.03
	var vibrato_depth := 0.0
	var vibrato_rate := 6.0
	var drift := 6.0
	var fry := 0.0
	var diplophonia := 0.0
	var closure := 0.0
	var chaos := 0.0
	var phase := 0.0
	var cycle_amp := 1.0
	var cycle_period_scale := 1.0
	var cycle_index := 0
	var chaos_x := 0.37
	var vib_phase := 0.0
	var rng: Rng
	var drifter: Drift
	var drift_value := 0.0
	var drift_counter := 0
	var pitch_factor := 1.0
	var voicing := 0.0
	var dp_sm := 0.0
	var dp_coef := 0.0
	var voice_coef := 0.0
	var f0_now := 110.0
	var threshold := 2.5 * 980.665
	var static_sm := 0.0
	var closure_sm := 0.0
	var amp_sm := 0.0
	var sm_coef := 0.0

	func _init(sample_rate: float) -> void:
		fs = sample_rate
		rng = Rng.new(777)
		drifter = Drift.new(sample_rate / 32.0, 0.3, 4242)
		dp_coef = 1.0 - exp(-TAU * 30.0 / sample_rate)
		voice_coef = 1.0 - exp(-TAU * 25.0 / sample_rate)
		sm_coef = 1.0 - exp(-1.0 / (0.004 * sample_rate))

	static func shape(ph: float, oq: float, skew_of: float, sharp: float) -> float:
		if ph >= oq: return 0.0
		var q := ph / oq
		var s := clampf(skew_of, 0.3, 0.9)
		if q < s: return 0.5 - 0.5 * cos((PI * q) / s)
		var w := (q - s) / (1.0 - s)
		var soft := 0.5 + 0.5 * cos(PI * w)
		var hard := cos(0.5 * PI * w)
		return soft + (hard - soft) * sharp

	## One step. `dp` is the pressure across the folds (below minus above). Returns the area (cm2).
	func next(dp: float) -> float:
		dp_sm += dp_coef * (dp - dp_sm)
		drift_counter -= 1
		if drift_counter <= 0:
			drift_counter = 32
			drift_value = drifter.step()
			vib_phase += ((vibrato_rate * 32.0) / fs) * (1.0 + 0.04 * drift_value)
			if vib_phase > 1.0: vib_phase -= 1.0
			pitch_factor = pow(2.0, (vibrato_depth * sin(TAU * vib_phase) + drift * drift_value) / 1200.0)
		var f := f0 * pitch_factor
		if fry > 0.0: f = f * (1.0 - fry) + minf(f, 48.0) * fry
		f0_now = f
		var q := clampf((dp_sm - threshold * 0.8) / (threshold * 1.6 - threshold * 0.8), 0.0, 1.0)
		var pressure_gate := q * q * (3.0 - 2.0 * q)
		q = clampf(((static_sm - chink) - 0.08) / (0.22 - 0.08), 0.0, 1.0)
		var target := pressure_gate * (1.0 - q * q * (3.0 - 2.0 * q)) * (1.0 - closure_sm)
		voicing += voice_coef * (target - voicing)
		phase += (f / fs) / cycle_period_scale
		if phase >= 1.0:
			phase -= 1.0
			cycle_index += 1
			var alt := 1.0 if cycle_index & 1 == 1 else -1.0
			var chaos_p := 0.0
			var chaos_a := 0.0
			if chaos > 0.0:
				var r := 2.9 + 1.1 * minf(1.0, chaos)
				chaos_x = r * chaos_x * (1.0 - chaos_x)
				if not (chaos_x > 0.0 and chaos_x < 1.0): chaos_x = 0.37
				var dev := chaos_x - 0.5
				chaos_p = 0.45 * chaos * dev
				chaos_a = 1.1 * chaos * dev
			cycle_period_scale = clampf(1.0 + jitter * rng.gauss() + diplophonia * 0.08 * alt + chaos_p, 0.55, 1.8)
			cycle_amp = maxf(0.12, 1.0 + shimmer * rng.gauss() - diplophonia * 0.35 * (1.0 if alt > 0.0 else 0.0) + chaos_a)
		var oq := clampf(open_quotient - 0.18 * (effort - 0.5), 0.25, 0.98)
		if fry > 0.0: oq = oq * (1.0 - fry) + 0.28 * fry
		var pulse := shape(phase, oq, skew, closure_sharpness)
		if fry > 0.3:
			var ph2 := phase - 0.38
			if ph2 > 0.0:
				var w := clampf((fry - 0.3) / (0.8 - 0.3), 0.0, 1.0)
				pulse += 0.55 * (w * w * (3.0 - 2.0 * w)) * shape(ph2, oq * 0.8, skew, closure_sharpness)
		var sc := sm_coef
		amp_sm += sc * (amplitude * (0.45 + 0.75 * effort) - amp_sm)
		closure_sm += sc * (closure - closure_sm)
		static_sm += sc * (abduction + chink - static_sm)
		return maxf(0.0, amp_sm * cycle_amp * voicing * pulse + static_sm * (1.0 - 0.92 * closure_sm))

	func flush_tiny() -> void:
		if absf(dp_sm) < 1e-30: dp_sm = 0.0
		if absf(voicing) < 1e-30: voicing = 0.0
		if absf(amp_sm) < 1e-30: amp_sm = 0.0
		if absf(closure_sm) < 1e-30: closure_sm = 0.0
		if absf(static_sm) < 1e-30: static_sm = 0.0


## Brings the air column's rate down by a whole factor: a Kaiser-windowed sinc low-pass.
class Decimator:
	var factor := 1
	var h := PackedFloat64Array()
	var buf := PackedFloat64Array()
	var pos := 0
	var count := 0
	var value := 0.0

	static func _bessel_i0(x: float) -> float:
		var sum := 1.0
		var term := 1.0
		for k in range(1, 30):
			var q := x / (2.0 * float(k))
			term *= q * q
			sum += term
			if term < 1e-12 * sum: break
		return sum

	func _init(by: int, taps_per_phase := 24) -> void:
		factor = by
		var taps := 1 if by == 1 else by * taps_per_phase + 1
		h.resize(taps)
		if by == 1:
			h[0] = 1.0
		else:
			var cutoff := 0.46 / float(by)
			var beta := 8.5
			var mid := (float(taps) - 1.0) / 2.0
			var i0b := _bessel_i0(beta)
			var sum := 0.0
			for i in taps:
				var x := float(i) - mid
				var sinc := 2.0 * cutoff if x == 0.0 else sin(2.0 * PI * cutoff * x) / (PI * x)
				var r := (2.0 * float(i)) / (float(taps) - 1.0) - 1.0
				h[i] = sinc * (_bessel_i0(beta * sqrt(maxf(0.0, 1.0 - r * r))) / i0b)
				sum += h[i]
			for i in taps: h[i] /= sum
		buf.resize(taps * 2)
		buf.fill(0.0)

	## One input sample in; true when `value` holds the next output sample.
	func push(x: float) -> bool:
		var n := h.size()
		buf[pos] = x
		buf[pos + n] = x
		pos = 0 if pos + 1 == n else pos + 1
		count += 1
		if count < factor: return false
		count = 0
		var acc := 0.0
		var start := pos
		var last := n - 1
		for i in n: acc += h[last - i] * buf[start + i]
		value = acc
		return true


var fs_out := 44100.0
var m := 2
var fs := 88200.0
var airway: Airway
var glottis: Glottis
var score: Score
var source := {}
var dec: Decimator
var ctrl_every := 128
var ctrl_counter := 0
var gate := 0.0
var gate_target := 0.0
var score_breath_hold := 0.0
var p_lung := 0.0
var p_lung_now := 0.0
var p_lung_step := 0.0
var f0 := 110.0
var output_gain := 5.5e-7
var dc_x := 0.0
var dc_y := 0.0
var dc_coef := 0.0
var clock := 0.0
var base_abduction := 0.0
var base_closure := 0.0
var score_f0 := -1.0
var lim_env := 0.0
var lim_hold := 0
var lim_hold_n := 0
var lim_release := 0.0
var max_penetration := 0.1
## The engine's output limiter; off, the caller gets the sound as radiated (and scales it itself).
var limiter := true

# the articulators: where they are, how fast they move, where they are told to go
var x := PackedFloat64Array()
var v := PackedFloat64Array()
var target := PackedFloat64Array()
var tip_free := true
var _omega := PackedFloat64Array()
var _lo := PackedFloat64Array()
var _hi := PackedFloat64Array()


## `rate`: output rate. `body`: "male", "female", "child" or [scale, pharynx, tongue radius, lip width].
## `oversample`: how many steps of the air column per output sample; 0 picks the engine's own (the
## smallest that puts the air column above 60 kHz). `min_sections`: see human_airway.gd.
func _init(rate: float, body: Variant = "male", oversample := 0, min_sections := 8) -> void:
	fs_out = rate
	m = oversample if oversample > 0 else int(maxf(1.0, floorf(60000.0 / rate) + 1.0))
	fs = rate * float(m)
	airway = Airway.new(fs, body, min_sections)
	glottis = Glottis.new(fs)
	score = Score.new()
	source = DEFAULT_SOURCE.duplicate()
	dec = Decimator.new(m)
	ctrl_every = 64 * m
	dc_coef = exp((-2.0 * PI * 25.0) / rate)
	lim_hold_n = int(Airway._round(0.025 * rate))
	lim_release = exp(-1.0 / (0.2 * rate))
	for i in Tract.N_ARTIC:
		x.append(Tract.NEUTRAL[i])
		target.append(Tract.NEUTRAL[i])
		v.append(0.0)
		_lo.append(float(ARTIC_SPECS[i][0]))
		_hi.append(float(ARTIC_SPECS[i][1]))
		_omega.append(2.0 * PI * float(ARTIC_SPECS[i][2]))
	var tip := Tract.rest_tip(Tract.NEUTRAL[Tract.JAW], Tract.NEUTRAL[Tract.TB_X], Tract.NEUTRAL[Tract.TB_Y])
	x[Tract.TT_X] = tip[0]
	target[Tract.TT_X] = tip[0]
	x[Tract.TT_Y] = tip[1]
	target[Tract.TT_Y] = tip[1]
	airway.apply(x, 0.0)
	airway.net.snap_to_targets()
	# smaller bodies radiate more high-frequency energy at their higher pitch
	var sc := airway.body_scale
	if sc >= 1.0: pass
	elif sc <= 0.9: output_gain *= 0.55
	else: output_gain *= 0.55 + 0.45 * (sc - 0.9) / 0.1
	_apply_source()


## Where the articulators are to go: {name: value}. `tip`: 1 the tongue tip rests behind the lower teeth
## and follows jaw and tongue, 0 it is placed, -1 leave as it is.
func set_articulation(values: Dictionary, tip := -1) -> void:
	if tip >= 0: tip_free = tip == 1
	for key in values:
		var i := Tract.NAMES.find(str(key))
		if i < 0 or values[key] == null: continue
		var val := float(values[key])
		if is_nan(val) or is_inf(val): continue
		target[i] = minf(_hi[i], maxf(_lo[i], val))


## Change the voice's source: any of DEFAULT_SOURCE's keys.
func set_source(values: Dictionary) -> void:
	for key in values:
		if DEFAULT_SOURCE.has(key) and values[key] != null: source[key] = values[key]
	_apply_source()


## Add gestures, their times counted from the voice's clock plus `offset`.
func schedule(gestures: Array, offset := 0.0) -> void:
	score.add_all(gestures, clock + offset)


func release(which: float) -> void: score.release(which, clock)
func cancel_score() -> void: score.clear()


## Breath on (1) or off (0); in between scales the pressure.
func set_gate(level: float) -> void:
	gate_target = clampf(level, 0.0, 1.5)


func _apply_source() -> void:
	var g := glottis
	var k2 := airway.body_scale * airway.body_scale
	var voiced := bool(source.voiced)
	var breathiness := float(source.breathiness)
	var tension := float(source.tension)
	var roughness := float(source.roughness)
	g.amplitude = 0.17 * k2 * (1.0 if voiced else 0.0)
	g.abduction = (0.1 * breathiness * breathiness if voiced else 0.2 + 0.1 * breathiness) * k2
	base_abduction = g.abduction
	base_closure = 0.0
	g.chink = (0.008 + 0.03 * breathiness) * k2
	g.open_quotient = 0.78 - 0.36 * tension
	var bright := float(source.brightness) - 0.25
	var by_tension := 0.4 * tension + 1.375 * maxf(0.0, tension - 0.6)
	g.closure_sharpness = clampf(by_tension + 0.8 * bright, 0.0, 1.0)
	g.skew = 0.56 + 0.16 * tension + 0.2 * bright
	g.fry = float(source.fry)
	g.jitter = 0.0021 + 0.0245 * roughness
	g.shimmer = 0.02 + 0.22 * roughness
	g.diplophonia = (roughness - 0.5) * 1.4 if roughness > 0.5 else 0.0
	g.vibrato_depth = float(source.vibratoDepth)
	g.vibrato_rate = float(source.vibratoRate)
	g.drift = float(source.drift)
	g.effort = clampf((absf(float(source.pressure)) - 3.0) / 10.0, 0.0, 1.0)


## Render output samples into `into[from .. to)`.
func render(into: PackedFloat32Array, from: int, to: int) -> void:
	var net := airway.net
	var lungs := airway.lungs
	var sub_node := net.last_node(airway.trachea)
	var supra := net.first_node(airway.pharynx)
	var gp := airway.glottis_port
	var p := net.p
	var port_area := net.port_area
	var port_target := net.port_area_target
	var port_step := net.port_area_step
	var steps := m
	var gl := glottis
	var decimator := dec
	for o in range(from, to):
		for _i in steps:
			if ctrl_counter <= 0: _control()
			ctrl_counter -= 1
			p_lung_now += p_lung_step
			p[lungs] = p_lung_now
			var a := gl.next(p[sub_node] - p[supra])
			port_area[gp] = a
			port_target[gp] = a
			port_step[gp] = 0.0
			if decimator.push(net.step()):
				var s := decimator.value * output_gain
				var hp := s - dc_x + dc_coef * dc_y
				dc_x = s
				dc_y = hp
				s = hp
				if limiter:
					# a peak envelope held longer than a period of the folds, so a loud vowel is turned
					# down by a steady gain instead of being squared off
					var av := absf(s)
					if av >= lim_env:
						lim_env = av
						lim_hold = lim_hold_n
					elif lim_hold > 0:
						lim_hold -= 1
					else:
						lim_env *= lim_release
					if lim_env > 0.75: s *= 0.75 / lim_env
					var al := absf(s)
					if al > 0.85: s = signf(s) * (0.85 + 0.15 * tanh((al - 0.85) / 0.15))
				into[o] = s


# Articulators follow their targets: x'' = w^2 (T - x) - 2 w x', stepped semi-implicitly.
func _step_articulators(dt: float, blended: bool, base_weight: float) -> void:
	if tip_free:
		var tip := Tract.rest_tip(x[Tract.JAW], x[Tract.TB_X], x[Tract.TB_Y])
		target[Tract.TT_X] = tip[0]
		target[Tract.TT_Y] = tip[1]
	var b_value := score.value
	var b_weight := score.weight
	var b_speed := score.speed_of
	for i in Tract.N_ARTIC:
		var tgt := target[i]
		var sp := 1.0
		if blended and b_weight[i] > 0.0:
			if i == Tract.VELUM:
				# only consonants touch the velum: it follows the gesture's own ramps
				tgt += minf(1.0, b_weight[i] / 2.0) * (b_value[i] - tgt)
			else:
				tgt = (tgt * base_weight + b_value[i] * b_weight[i]) / (base_weight + b_weight[i])
			sp *= b_speed[i]
		if tgt < _lo[i]: tgt = _lo[i]
		elif tgt > _hi[i]: tgt = _hi[i]
		var w := _omega[i] * sp
		var xi := x[i]
		var acc := w * w * (tgt - xi) - 2.0 * w * v[i]
		v[i] += acc * dt
		var nx := xi + v[i] * dt
		if tgt == 0.0 and absf(nx) < 1e-30: nx = 0.0
		if absf(v[i]) < 1e-30: v[i] = 0.0
		x[i] = nx


func _control() -> void:
	var dt := float(ctrl_every) / fs
	var t := clock
	var breath_act := 0.0
	var breath_val := 0.0
	var f0_target := float(source.f0)
	var gl := glottis
	if score.size() > 0:
		score.blend_all(t)
		var bv := score.value
		var bw := score.weight
		_step_articulators(dt, true, 0.05)
		var k2 := airway.body_scale * airway.body_scale
		var ab_act := minf(1.0, bw[Score.ABDUCTION] / 2.0) if bw[Score.ABDUCTION] > 0.0 else 0.0
		gl.abduction = base_abduction + bv[Score.ABDUCTION] * ab_act * k2
		gl.closure = maxf(base_closure, bv[Score.CLOSURE] * minf(1.0, bw[Score.CLOSURE] / 2.0) if bw[Score.CLOSURE] > 0.0 else 0.0)
		if bw[Score.BREATH] > 0.0:
			breath_act = minf(1.0, bw[Score.BREATH])
			breath_val = bv[Score.BREATH]
		var depth := float(source.vibratoDepth)
		gl.vibrato_depth = (depth * 0.05 + bv[Score.VIBRATO] * bw[Score.VIBRATO]) / (0.05 + bw[Score.VIBRATO]) if bw[Score.VIBRATO] > 0.0 else depth
		if bw[Score.F0] > 0.0:
			f0_target = (float(source.f0) * 0.02 + bv[Score.F0] * bw[Score.F0]) / (0.02 + bw[Score.F0])
			score_f0 = f0_target
		else:
			score_f0 = -1.0
		if int(clock * 10.0) != int((clock - dt) * 10.0): score.prune(t - 0.2)
	else:
		_step_articulators(dt, false, 1.0)
		gl.abduction = base_abduction
		gl.closure = base_closure
		score_f0 = -1.0
	clock += dt
	airway.apply(x, dt)
	if _enforce_contacts(): airway.reapply(x)
	airway.net.begin_block(ctrl_every)
	ctrl_counter = ctrl_every
	# breath: a fast attack, a slower release; a score breathes on its own
	var score_breath := breath_val * breath_act
	var gate_goal := score_breath if score_breath < 0.0 else maxf(gate_target, score_breath)
	score_breath_hold = 0.15 if breath_act > 0.0 else maxf(0.0, score_breath_hold - dt)
	var tau := 0.07
	if gate_goal > gate: tau = 0.025
	elif score_breath_hold > 0.0: tau = 0.02
	gate += (gate_goal - gate) * (1.0 - exp(-dt / tau))
	if absf(gate) < 1e-30: gate = 0.0
	gl.flush_tiny()
	if absf(dc_x) < 1e-30: dc_x = 0.0
	if absf(dc_y) < 1e-30: dc_y = 0.0
	if absf(lim_env) < 1e-30: lim_env = 0.0
	var pressure := float(source.pressure)
	p_lung = pressure * CM_H2O * gate
	if p_lung == 0.0 and absf(p_lung_now) < 1e-30: p_lung_now = 0.0
	p_lung_step = (p_lung - p_lung_now) / float(ctrl_every)
	# effort follows the pressure actually applied: a harder breath gives wider, sharper pulses
	gl.effort = clampf((absf(pressure * gate) - 3.0) / 10.0, 0.0, 1.0)
	var glide := maxf(0.002, 0.03 if score_f0 >= 0.0 else float(source.glide))
	f0 *= pow(f0_target / f0, 1.0 - exp(-dt / glide))
	gl.f0 = f0


func _fix_contact(d: float, nx: float, ny: float, kx: int, ky: int, lim: float, k: float) -> bool:
	if not (d < lim): return false
	var depth := lim - d
	# body to template displacement (the mouth's x is compressed by 0.86 in the template)
	var sx := (1.0 / 0.86 if x[kx] > 0.5 else 1.0) / k
	var sy := 1.0 / k
	x[kx] += nx * depth * sx
	x[ky] += ny * depth * sy
	var vn := v[kx] * nx / sx + v[ky] * ny / sy
	if vn < 0.0:
		v[kx] -= vn * nx * sx
		v[ky] -= vn * ny * sy
	return true


# The tongue cannot travel into the palate: past `max_penetration` of squeezed tissue its tip or body is
# put back along the contact's normal and its inward speed taken away.
func _enforce_contacts() -> bool:
	var tr := airway.tract
	var k := tr.scale
	var lim := -max_penetration * k
	var ct := tr.contact_tip
	var ctx := tr.contact_tip_nx
	var cty := tr.contact_tip_ny
	var cb := tr.contact_body
	var cbx := tr.contact_body_nx
	var cby := tr.contact_body_ny
	var changed := _fix_contact(ct, ctx, cty, Tract.TT_X, Tract.TT_Y, lim, k)
	if _fix_contact(cb, cbx, cby, Tract.TB_X, Tract.TB_Y, lim, k): changed = true
	return changed
