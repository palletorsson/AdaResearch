extends Node
class_name EmAudio
# em_audio.gd — spatial audio and room tone for the endless museum.
#
# The half of presence that is not visual. A museum you walk in silence reads as
# a diorama; the same geometry with a floor under your shoes and air in the room
# reads as a building. Nothing here loads a file: every sample is synthesised in
# GDScript at install time into AudioStreamWAV buffers, because this repository
# ships no audio assets and must not start shipping binaries.
#
# ── API ──────────────────────────────────────────────────────────────────────
#   EmAudio.install(root: Node3D) -> void      build buses + buffers, start tone
#   EmAudio.set_space(kind: String) -> void    cabinet | corridor | gallery | hall
#   EmAudio.footstep(surface: String) -> void  stone | oak (aliases accepted)
# Convenience, all optional:
#   EmAudio.threshold() -> void                play the doorway whoosh alone
#   EmAudio.bind_footsteps(emitter, signal_name := "footstep") -> void
#   EmAudio.is_active() -> bool
#   EmAudio.uninstall() -> void
#
# ── WIRING ───────────────────────────────────────────────────────────────────
# The feel module owns cadence; this module owns sound. install() does not
# require it: for the first three seconds the rig re-scans `root`, root's direct
# children and the `em_feel` group for any node exposing a `footstep` signal and
# connects itself, tolerating 0, 1 or 2 signal arguments and picking the String
# one as the surface. Explicit wiring via bind_footsteps() always wins.
#
# ── SYNTHESIS ────────────────────────────────────────────────────────────────
# Three families, 16-bit mono PCM, deterministic from a fixed seed:
#
#  1. ROOM TONE — two beds, mixed and filtered per space.
#     `air`    8.000 s @ 22050 Hz — white noise, 1-pole HP 320 Hz, 2-pole LP
#              2400 Hz: the near-field hiss of a room with people-less air in it.
#     `rumble` 8.000 s @ 11025 Hz — white noise, 3-pole LP 95 Hz, plus mains
#              partials at 50/100 Hz: plant, ducting and structure.
#     Both loop SEAMLESSLY by construction. The one-pole filters are run
#     CIRCULARLY — primed on the buffer's tail before the pass begins — so the
#     filtered signal is exactly periodic at the loop length; the slow amplitude
#     drift uses an integer number of cycles per loop (2 and 5), and 50 Hz over
#     8.000 s is exactly 400 cycles. No crossfade, no seam.
#
#  2. FOOTSTEPS — 4 variants x 2 surfaces, one-shots.
#     stone 0.340 s @ 44100 Hz: bright noise transient (tau 12 ms, HP 1.8 kHz),
#           a darker slide layer (tau 30 ms), a 1.35 kHz contact ring
#           (tau 18 ms) and a 78 Hz body thump (tau 45 ms), plus a toe-drop
#           second transient 20-32 ms behind the heel at 38 % level.
#     oak   0.420 s @ 44100 Hz: the same skeleton with the brightness pulled
#           out and PLANK MODES added — decaying sines at 186 / 312 / 517 Hz
#           (tau 90 / 62 / 41 ms) over a 62 Hz under-board boom (tau 130 ms).
#           Those modes are what makes wood read as wood rather than as a quiet
#           stone. One variant in four carries a faint board creak.
#     Per variant the mode frequencies and decay constants jitter +/-6 %, so the
#     four are siblings, not copies.
#
#  3. THRESHOLD WHOOSH — 1.600 s @ 22050 Hz. Noise through a Chamberlin
#     state-variable band-pass whose centre glides 170 -> 990 -> 170 Hz on a
#     half-sine, under a sin(pi*u)^1.8 envelope (zero at both ends, so it can
#     never click), plus a 46 Hz sub swell and a high air layer. It is the
#     pressure change of walking through a door, not a sound effect.
#
# ── MEMORY ───────────────────────────────────────────────────────────────────
#   air     176400 frames x 2 B = 352 800 B
#   rumble   88200 frames x 2 B = 176 400 B
#   whoosh   35280 frames x 2 B =  70 560 B
#   stone    14994 frames x 2 B x 4 = 119 952 B
#   oak      18522 frames x 2 B x 4 = 148 176 B
#   TOTAL                          = 867 888 B  ~= 0.83 MiB resident.
# Peak transient during the build is one extra float32 scratch buffer for the
# air bed (705 600 B), freed before install() returns. Build cost is ~570 000
# noise samples plus a handful of one-pole passes over them — one pass of a few
# million float ops, on the order of 0.2-0.4 s of GDScript, paid ONCE inside
# install() (i.e. inside the museum's _ready, before the walk starts).
#
# ── HEADLESS ─────────────────────────────────────────────────────────────────
# install() no-ops cleanly — no buses, no nodes, no synthesis, no allocation, no
# error, one printed line — when ANY of: the headless OS feature is set, the
# display server names itself headless, AudioServer reports no bus / zero mix
# rate / an empty or "Disabled" output-device list, --em-no-audio is passed, or
# the run is a proof-shot capture (--em-shot...). set_space(), footstep(),
# threshold() and bind_footsteps() are all safe to call before install and after
# a no-op install; they check the rig and return immediately. The headless
# capture path never enters this file's synthesis at all.

## ── the rig ──────────────────────────────────────────────────────────────────
## Everything lives on one Node so the whole module frees in one queue_free and
## so tweens and signal callbacks have an Object to belong to. All state is
## instance state; the outer class is a thin static facade.
class Rig extends Node:

	## Per-space acoustics. Every number is a physical claim, not a taste.
	##
	## predelay_msec ~= (distance to the first reflecting surface) / 343 m/s:
	##   cabinet 2.7 m -> 8 ms, corridor 4.8 m -> 14 ms, gallery 9 m -> 26 ms,
	##   hall 14 m -> 42 ms. This is the single cue that reads as ROOM SIZE
	##   before the tail does.
	## damping is high-frequency absorption. A cabinet is vitrines, fabric and
	##   close plaster (0.62); a stone gallery is hard, near-specular surfaces
	##   that keep their treble (0.18); a hall keeps almost all of it (0.10).
	## spread is decorrelation of the tail: a small room's reflections arrive
	##   from nearly one direction, a hall's from everywhere.
	## hipass keeps low end out of the tail — small rooms need it most, or the
	##   reverb mud sits on top of the rumble bed.
	## tone_hz / air_db / rum_db move the bed's BALANCE with size: near-field
	##   air is bright and present in a cabinet; in a hall what survives to the
	##   ear is diffuse low structure, so air falls 6 dB, rumble rises 8 dB, and
	##   the bed's low-pass drops from 5.2 kHz to 1.9 kHz.
	const SPACES := {
		"cabinet": {
			"air_db": -31.0, "rum_db": -30.0, "tone_hz": 5200.0,
			"room": 0.28, "damp": 0.62, "spread": 0.35, "predelay": 8.0,
			"wet": 0.16, "dry": 1.00, "hipass": 0.30, "step_db": -1.0,
		},
		"corridor": {
			"air_db": -33.0, "rum_db": -27.0, "tone_hz": 3600.0,
			"room": 0.55, "damp": 0.36, "spread": 0.20, "predelay": 14.0,
			"wet": 0.28, "dry": 1.00, "hipass": 0.22, "step_db": 0.0,
		},
		"gallery": {
			"air_db": -35.0, "rum_db": -25.0, "tone_hz": 2600.0,
			"room": 0.78, "damp": 0.18, "spread": 0.70, "predelay": 26.0,
			"wet": 0.42, "dry": 0.94, "hipass": 0.12, "step_db": 0.0,
		},
		"hall": {
			"air_db": -37.0, "rum_db": -22.0, "tone_hz": 1900.0,
			"room": 0.92, "damp": 0.10, "spread": 1.00, "predelay": 42.0,
			"wet": 0.55, "dry": 0.88, "hipass": 0.06, "step_db": 1.0,
		},
	}
	const DEFAULT_SPACE := "gallery"
	const CROSSFADE_S := 0.9      # a threshold is a walk-through, not a cut
	const STEP_VARIANTS := 4
	const STEP_VOICES := 6        # 0.34 s tail vs 0.19 s sprint cadence -> 2 spare
	const BUS_TONE := "EmTone"
	const BUS_SPACE := "EmSpace"
	const SYNTH_SEED := 20260807

	var air_player: AudioStreamPlayer
	var rum_player: AudioStreamPlayer
	var music_player: AudioStreamPlayer = null   # THE LO-FI BED, lazy (see lofi())
	var lofi_stream: AudioStreamWAV = null
	var whoosh_player: AudioStreamPlayer
	var step_players: Array[AudioStreamPlayer] = []
	var steps: Dictionary = {}          # "stone"/"oak" -> Array[AudioStreamWAV]

	var bus_tone: int = -1
	var bus_space: int = -1
	var tone_filter: AudioEffectLowPassFilter
	var reverb: AudioEffectReverb

	var space: String = DEFAULT_SPACE
	var _from: Dictionary = {}
	var _to: Dictionary = {}
	var _fade: Tween
	var _voice: int = 0
	var _step_i: int = 0
	var _bag: Dictionary = {}           # surface -> Array[int] shuffle bag
	var _last_variant: Dictionary = {}
	var _rng := RandomNumberGenerator.new()
	var _bound: bool = false
	var _scan_t: float = 0.0
	var _scan_age: float = 0.0
	var _root: Node = null
	var _bytes: int = 0

	func _init() -> void:
		name = "EmAudio"
		process_mode = Node.PROCESS_MODE_ALWAYS
		_rng.seed = SYNTH_SEED

	# ── build ────────────────────────────────────────────────────────────────

	func build(root: Node) -> void:
		_root = root
		_make_buses()
		_synth()
		_make_players()
		space = DEFAULT_SPACE
		_from = SPACES[space]
		_to = SPACES[space]
		_apply(1.0)
		air_player.play()
		rum_player.play()
		print("[em_audio] %d generated buffers, %.0f KiB resident, buses %s/%s, space=%s" % [
			2 + 1 + STEP_VARIANTS * 2, float(_bytes) / 1024.0,
			BUS_TONE, BUS_SPACE, space])

	## Two buses, both sending to Master.
	##   EmTone  — the bed. A 12 dB/oct low-pass whose cutoff moves with room
	##             size. The bed is ALREADY the reverberant field of the room,
	##             so it is deliberately NOT sent through the reverb; feeding a
	##             diffuse noise bed into a reverb only smears it and eats CPU.
	##   EmSpace — everything the walker EXCITES: footsteps and the whoosh. This
	##             is where the AudioEffectReverb lives.
	func _make_buses() -> void:
		bus_tone = _ensure_bus(BUS_TONE)
		bus_space = _ensure_bus(BUS_SPACE)
		if bus_tone < 0 or bus_space < 0:
			return
		if AudioServer.get_bus_effect_count(bus_tone) == 0:
			tone_filter = AudioEffectLowPassFilter.new()
			tone_filter.cutoff_hz = 2600.0
			tone_filter.resonance = 0.0
			tone_filter.db = AudioEffectFilter.FILTER_12DB
			AudioServer.add_bus_effect(bus_tone, tone_filter)
		else:
			tone_filter = AudioServer.get_bus_effect(bus_tone, 0) as AudioEffectLowPassFilter
		if AudioServer.get_bus_effect_count(bus_space) == 0:
			reverb = AudioEffectReverb.new()
			AudioServer.add_bus_effect(bus_space, reverb)
		else:
			reverb = AudioServer.get_bus_effect(bus_space, 0) as AudioEffectReverb

	func _ensure_bus(bus_name: String) -> int:
		var idx: int = AudioServer.get_bus_index(bus_name)
		if idx >= 0:
			return idx
		AudioServer.add_bus()
		idx = AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(idx, bus_name)
		AudioServer.set_bus_send(idx, "Master")
		AudioServer.set_bus_volume_db(idx, 0.0)
		return idx

	func _make_players() -> void:
		air_player = AudioStreamPlayer.new()
		air_player.stream = _mk_air()
		air_player.bus = BUS_TONE
		air_player.volume_db = -60.0
		add_child(air_player)

		rum_player = AudioStreamPlayer.new()
		rum_player.stream = _mk_rumble()
		rum_player.bus = BUS_TONE
		rum_player.volume_db = -60.0
		add_child(rum_player)

		whoosh_player = AudioStreamPlayer.new()
		whoosh_player.stream = _whoosh
		whoosh_player.bus = BUS_SPACE
		whoosh_player.volume_db = -14.0
		add_child(whoosh_player)

		for _v in range(STEP_VOICES):
			var p := AudioStreamPlayer.new()
			p.bus = BUS_SPACE
			p.volume_db = -8.0
			add_child(p)
			step_players.append(p)

	# ── the API, as instance methods ────────────────────────────────────────

	func go_space(kind: String) -> void:
		var k: String = kind.to_lower().strip_edges()
		if not SPACES.has(k):
			k = DEFAULT_SPACE
		if k == space:
			return
		space = k
		_from = _snapshot()
		_to = SPACES[k]
		if _fade != null and _fade.is_valid():
			_fade.kill()
		if not is_inside_tree():
			_apply(1.0)   # create_tween() needs a tree; land the space anyway
			return
		_fade = create_tween()
		_fade.set_ease(Tween.EASE_IN_OUT)
		_fade.set_trans(Tween.TRANS_SINE)
		_fade.tween_method(Callable(self, "_apply"), 0.0, 1.0, CROSSFADE_S)
		play_whoosh()

	func play_whoosh() -> void:
		if whoosh_player == null:
			return
		whoosh_player.pitch_scale = _rng.randf_range(0.93, 1.08)
		whoosh_player.play()

	func step(surface: String) -> void:
		var fam: String = _family(surface)
		var bank: Array = steps.get(fam, [])
		if bank.is_empty():
			return
		var v: int = _draw_variant(fam)
		var p: AudioStreamPlayer = _free_voice()
		if p == null:
			return
		# Anti-machine-gun, three independent axes:
		#   variant  — shuffle bag, never the same sample twice in a row
		#   pitch    — +/-6 % semitone-ish spread, the shoe/floor contact point
		#   level    — 4 dB window, footfalls are not calibrated
		# plus a deterministic left/right asymmetry: real gait is not symmetric,
		# and a 1.5 % pitch alternation is what stops a run reading as a loop.
		var foot: float = 1.0 if (_step_i % 2) == 0 else -1.0
		_step_i += 1
		p.stream = bank[v]
		p.pitch_scale = clampf(_rng.randf_range(0.945, 1.065) + foot * 0.015, 0.85, 1.20)
		var sp: Dictionary = SPACES[space]
		var trim: float = _num(sp, "step_db", 0.0)
		p.volume_db = -8.0 + trim + _rng.randf_range(-3.0, 1.0) + (0.0 if foot > 0.0 else -0.8)
		p.play()

	func _family(surface: String) -> String:
		var s: String = surface.to_lower().strip_edges()
		match s:
			"oak", "wood", "timber", "plank", "parquet", "board":
				return "oak"
			_:
				return "stone"

	## Shuffle bag: draw a permutation, refill when empty, and refuse a refill
	## whose head repeats the variant we just played.
	func _draw_variant(fam: String) -> int:
		var bag: Array = _bag.get(fam, [])
		if bag.is_empty():
			var last: int = int(_last_variant.get(fam, -1))
			for _attempt in range(6):
				bag = []
				for i in range(STEP_VARIANTS):
					bag.append(i)
				for i in range(bag.size() - 1, 0, -1):
					var j: int = _rng.randi_range(0, i)
					var t: int = bag[i]
					bag[i] = bag[j]
					bag[j] = t
				if bag[0] != last:
					break
		var v: int = int(bag.pop_front())
		_bag[fam] = bag
		_last_variant[fam] = v
		return v

	func _free_voice() -> AudioStreamPlayer:
		for i in range(step_players.size()):
			var p: AudioStreamPlayer = step_players[(_voice + i) % step_players.size()]
			if not p.playing:
				_voice = (_voice + i + 1) % step_players.size()
				return p
		var q: AudioStreamPlayer = step_players[_voice % step_players.size()]
		_voice = (_voice + 1) % step_players.size()
		return q

	# ── space blending ──────────────────────────────────────────────────────

	func _snapshot() -> Dictionary:
		if air_player == null or reverb == null or tone_filter == null:
			return SPACES[DEFAULT_SPACE]
		return {
			"air_db": air_player.volume_db, "rum_db": rum_player.volume_db,
			"tone_hz": tone_filter.cutoff_hz,
			"room": reverb.room_size, "damp": reverb.damping,
			"spread": reverb.spread, "predelay": reverb.predelay_msec,
			"wet": reverb.wet, "dry": reverb.dry, "hipass": reverb.hipass,
		}

	func _apply(t: float) -> void:
		if air_player == null or reverb == null or tone_filter == null:
			return
		air_player.volume_db = _mix("air_db", t)
		rum_player.volume_db = _mix("rum_db", t)
		# cutoff crossfades in LOG space — a linear sweep from 5200 to 1900 Hz
		# spends most of its time near the top and lands as a lurch.
		tone_filter.cutoff_hz = exp(lerpf(
			log(maxf(_num(_from, "tone_hz", 2600.0), 20.0)),
			log(maxf(_num(_to, "tone_hz", 2600.0), 20.0)), t))
		reverb.room_size = clampf(_mix("room", t), 0.0, 1.0)
		reverb.damping = clampf(_mix("damp", t), 0.0, 1.0)
		reverb.spread = clampf(_mix("spread", t), 0.0, 1.0)
		reverb.predelay_msec = maxf(_mix("predelay", t), 0.0)
		reverb.wet = clampf(_mix("wet", t), 0.0, 1.0)
		reverb.dry = clampf(_mix("dry", t), 0.0, 1.0)
		reverb.hipass = clampf(_mix("hipass", t), 0.0, 1.0)

	func _mix(key: String, t: float) -> float:
		return lerpf(_num(_from, key, 0.0), _num(_to, key, 0.0), t)

	## NOT named _get: Object declares a native virtual `_get(property)` and an
	## incompatible override is a parse error, which would take the whole scene
	## down with it.
	func _num(d: Dictionary, key: String, fallback: float) -> float:
		if d.has(key):
			return float(d[key])
		return fallback

	# ── footstep autowiring ─────────────────────────────────────────────────

	func _process(delta: float) -> void:
		if _bound or _root == null:
			set_process(false)
			return
		_scan_age += delta
		_scan_t += delta
		if _scan_age > 3.0:
			set_process(false)
			return
		if _scan_t < 0.25:
			return
		_scan_t = 0.0
		_scan()

	func _scan() -> void:
		var cands: Array = []
		cands.append(_root)
		for c in _root.get_children():
			cands.append(c)
		if _root.is_inside_tree():
			for g in _root.get_tree().get_nodes_in_group("em_feel"):
				cands.append(g)
		for c in cands:
			if c == null or c == self:
				continue
			if bind(c, "footstep"):
				return

	## Connect to an emitter's footstep signal, tolerating 0, 1 or 2 declared
	## arguments and picking whichever is a String as the surface. Returns true
	## when a connection was made or already existed.
	func bind(emitter: Object, signal_name: String) -> bool:
		if emitter == null or not emitter.has_signal(signal_name):
			return false
		var argc: int = -1
		for s in emitter.get_signal_list():
			var sd: Dictionary = s
			if str(sd.get("name", "")) == signal_name:
				var sargs: Array = sd.get("args", [])
				argc = sargs.size()
				break
		if argc < 0:
			return false
		var cb: Callable
		match argc:
			0:
				cb = Callable(self, "_fs0")
			1:
				cb = Callable(self, "_fs1")
			2:
				cb = Callable(self, "_fs2")
			_:
				push_warning("em_audio: `%s` on %s declares %d arguments; not wiring (call EmAudio.footstep() directly)" % [
					signal_name, emitter, argc])
				return false
		if emitter.is_connected(signal_name, cb):
			_bound = true
			return true
		emitter.connect(signal_name, cb)
		_bound = true
		set_process(false)
		print("[em_audio] footsteps bound to %s.%s (%d args)" % [emitter, signal_name, argc])
		return true

	func _fs0() -> void:
		step("stone")

	func _fs1(a: Variant) -> void:
		if a is String or a is StringName:
			step(str(a))
		else:
			step("stone")

	func _fs2(a: Variant, b: Variant) -> void:
		if a is String or a is StringName:
			step(str(a))
		elif b is String or b is StringName:
			step(str(b))
		else:
			step("stone")

	# ── synthesis ───────────────────────────────────────────────────────────

	var _whoosh: AudioStreamWAV

	func _synth() -> void:
		var bank_stone: Array = []
		var bank_oak: Array = []
		for v in range(STEP_VARIANTS):
			bank_stone.append(_mk_step("stone", v))
			bank_oak.append(_mk_step("oak", v))
		steps["stone"] = bank_stone
		steps["oak"] = bank_oak
		_whoosh = _mk_whoosh()

	## White noise, near-gaussian by the Bates-3 sum rather than Box-Muller.
	## Two reasons, and neither is laziness: it costs three randf() instead of a
	## log/sqrt/cos per sample (this runs ~570 000 times at install), and its
	## support is BOUNDED, so no rare six-sigma spike forces _normalize to squash
	## the whole buffer 10 dB to accommodate one inaudible sample.
	func _noise(n: int) -> PackedFloat32Array:
		var b := PackedFloat32Array()
		b.resize(n)
		for i in range(n):
			b[i] = (_rng.randf() + _rng.randf() + _rng.randf() - 1.5) * 0.46
		return b

	## One-pole low-pass run CIRCULARLY: the state is primed on the buffer's own
	## tail (~50 time constants) before the real pass starts, so the output is
	## exactly periodic at the buffer length. This is what makes the room-tone
	## loops seamless without a crossfade — a crossfade would halve the effective
	## decorrelation length and put a comb notch in the bed.
	func _lp_circ(buf: PackedFloat32Array, cutoff: float, sr: float, poles: int) -> void:
		var n: int = buf.size()
		if n <= 0:
			return
		var a: float = 1.0 - exp(-TAU * maxf(cutoff, 0.01) / sr)
		var prime: int = mini(n, int(sr / maxf(cutoff, 1.0) * 8.0) + 8)
		for _pole in range(poles):
			var y: float = 0.0
			for i in range(n - prime, n):
				y += a * (buf[i] - y)
			for i in range(n):
				y += a * (buf[i] - y)
				buf[i] = y

	func _hp_circ(buf: PackedFloat32Array, cutoff: float, sr: float) -> void:
		var low: PackedFloat32Array = buf.duplicate()
		_lp_circ(low, cutoff, sr, 1)
		for i in range(buf.size()):
			buf[i] = buf[i] - low[i]

	## Plain (non-circular) one-pole passes for one-shots: state starts at zero,
	## which for a transient that starts at silence is the physically right
	## initial condition.
	func _lp_lin(buf: PackedFloat32Array, cutoff: float, sr: float, poles: int) -> void:
		var a: float = 1.0 - exp(-TAU * maxf(cutoff, 0.01) / sr)
		for _pole in range(poles):
			var y: float = 0.0
			for i in range(buf.size()):
				y += a * (buf[i] - y)
				buf[i] = y

	func _hp_lin(buf: PackedFloat32Array, cutoff: float, sr: float) -> void:
		var low: PackedFloat32Array = buf.duplicate()
		_lp_lin(low, cutoff, sr, 1)
		for i in range(buf.size()):
			buf[i] = buf[i] - low[i]

	func _normalize(buf: PackedFloat32Array, peak: float) -> void:
		var m: float = 0.0
		for i in range(buf.size()):
			m = maxf(m, absf(buf[i]))
		if m < 0.000001:
			return
		var g: float = peak / m
		for i in range(buf.size()):
			buf[i] = buf[i] * g

	## Raised-cosine attack and release. 0.3 ms in stops the DAC overshooting a
	## hard sample-zero step; 4 ms out guarantees the one-shot ends at silence.
	func _edges(buf: PackedFloat32Array, sr: float, attack_s: float, release_s: float) -> void:
		var n: int = buf.size()
		var na: int = mini(n, int(sr * attack_s))
		var nr: int = mini(n, int(sr * release_s))
		for i in range(na):
			var u: float = float(i) / float(maxi(na, 1))
			buf[i] = buf[i] * (0.5 - 0.5 * cos(PI * u))
		for i in range(nr):
			var u2: float = float(i) / float(maxi(nr, 1))
			var k: int = n - 1 - i
			buf[k] = buf[k] * (0.5 - 0.5 * cos(PI * u2))

	## The air bed: 8.000 s @ 22050 Hz. Band-limited noise between 320 Hz and
	## 2.4 kHz — below that band the rumble bed does the work, above it the ear
	## reads hiss as equipment rather than as a room.
	func _mk_air() -> AudioStreamWAV:
		var sr: int = 22050
		var n: int = sr * 8
		var b: PackedFloat32Array = _noise(n)
		_hp_circ(b, 320.0, float(sr))
		_lp_circ(b, 2400.0, float(sr), 2)
		_normalize(b, 0.80)
		# slow drift at 2 and 5 cycles PER LOOP: integer counts, so the drift is
		# periodic too and the seam stays invisible.
		for i in range(n):
			var u: float = float(i) / float(n)
			b[i] = b[i] * (1.0 + 0.10 * sin(TAU * 2.0 * u) + 0.06 * sin(TAU * 5.0 * u + 1.3))
		_normalize(b, 0.86)
		return _to_wav(b, sr, true)

	## The rumble bed: 8.000 s @ 11025 Hz. Everything of interest here is under
	## 200 Hz, so half the air bed's rate is transparent and halves the RAM.
	## 50 Hz over exactly 8.000 s is 400 whole cycles, 100 Hz is 800 — the mains
	## partials land on the loop point exactly.
	func _mk_rumble() -> AudioStreamWAV:
		var sr: int = 11025
		var n: int = sr * 8
		var b: PackedFloat32Array = _noise(n)
		_lp_circ(b, 95.0, float(sr), 3)
		_normalize(b, 0.72)
		for i in range(n):
			var t: float = float(i) / float(sr)
			var u: float = float(i) / float(n)
			var hum: float = 0.055 * sin(TAU * 50.0 * t) + 0.022 * sin(TAU * 100.0 * t + 0.7)
			var drift: float = 1.0 + 0.14 * sin(TAU * 3.0 * u + 0.4)
			b[i] = b[i] * drift + hum
		_normalize(b, 0.88)
		return _to_wav(b, sr, true)

	## One footstep. `variant` jitters the resonant structure so four samples
	## are siblings rather than clones; the jitter is deterministic in the seed,
	## so a capture of the museum is reproducible.
	func _mk_step(surface: String, variant: int) -> AudioStreamWAV:
		var sr: int = 44100
		var srf: float = float(sr)
		var stone: bool = surface == "stone"
		var dur: float = 0.34 if stone else 0.42
		var n: int = int(srf * dur)
		var out := PackedFloat32Array()
		out.resize(n)
		var jit: float = 1.0 + (float(variant) - 1.5) * 0.04 + _rng.randf_range(-0.02, 0.02)

		# layer 1 — the strike transient
		var hi: PackedFloat32Array = _noise(n)
		if stone:
			_hp_lin(hi, 1800.0, srf)
			_lp_lin(hi, 9000.0, srf, 2)
		else:
			_lp_lin(hi, 3500.0, srf, 2)
		var tau_hi: float = (0.012 if stone else 0.020) * jit

		# layer 2 — the shoe sliding into contact, darker and longer
		var mid: PackedFloat32Array = _noise(n)
		_hp_lin(mid, 400.0, srf)
		_lp_lin(mid, (2500.0 if stone else 1200.0), srf, 2)
		var tau_mid: float = (0.030 if stone else 0.045) * jit

		var amp_hi: float = 0.55 if stone else 0.32
		var amp_mid: float = 0.45 if stone else 0.30
		var toe_d: float = (0.020 + 0.004 * float(variant)) * jit   # heel -> toe drop
		var toe_i: int = int(srf * toe_d)

		for i in range(n):
			var t: float = float(i) / srf
			var v: float = amp_hi * hi[i] * exp(-t / tau_hi)
			v += amp_mid * mid[i] * exp(-t / tau_mid)
			if stone:
				# a hard contact ring (leather on stone) and the body thump of
				# the mass landing on a slab
				v += 0.22 * sin(TAU * 1350.0 * jit * t) * exp(-t / (0.018 * jit))
				v += 0.30 * sin(TAU * 78.0 * t) * exp(-t / 0.045)
			else:
				# PLANK MODES — the whole reason wood is not quiet stone. Three
				# decaying sines with progressively shorter taus (higher modes
				# radiate and damp faster) over an under-board cavity boom.
				v += 0.30 * sin(TAU * 186.0 * jit * t) * exp(-t / (0.090 * jit))
				v += 0.18 * sin(TAU * 312.0 * jit * t + 0.9) * exp(-t / (0.062 * jit))
				v += 0.11 * sin(TAU * 517.0 * jit * t + 2.1) * exp(-t / (0.041 * jit))
				v += 0.26 * sin(TAU * 62.0 * t) * exp(-t / 0.130)
				if variant == 3 and t > 0.035:
					# one board in four creaks: a slowly detuning squeak, low
					# enough to be felt rather than noticed
					var ct: float = t - 0.035
					v += 0.05 * sin(TAU * (880.0 - 140.0 * ct) * ct) * exp(-ct / 0.070) * minf(ct * 30.0, 1.0)
			if i >= toe_i:
				var tt: float = float(i - toe_i) / srf
				v += 0.38 * amp_mid * mid[i] * exp(-tt / (tau_mid * 0.8))
				if stone:
					v += 0.10 * hi[i] * exp(-tt / (tau_hi * 1.4))
			out[i] = v

		_edges(out, srf, 0.0003, 0.004)
		_normalize(out, 0.89)
		var w: AudioStreamWAV = _to_wav(out, sr, false)
		return w

	## The threshold whoosh: 1.600 s @ 22050 Hz. A Chamberlin state-variable
	## band-pass on noise, centre gliding 170 -> 990 -> 170 Hz. The SVF is
	## unconditionally stable while fc stays below sr/6 (3675 Hz here), so the
	## sweep can never blow up. The sin^1.8 envelope is zero at both ends: the
	## one-shot cannot click no matter when it is triggered.
	func _mk_whoosh() -> AudioStreamWAV:
		var sr: int = 22050
		var srf: float = float(sr)
		var n: int = int(srf * 1.6)
		var src: PackedFloat32Array = _noise(n)
		var air: PackedFloat32Array = src.duplicate()
		_hp_lin(air, 2500.0, srf)
		_lp_lin(air, 6000.0, srf, 1)
		var out := PackedFloat32Array()
		out.resize(n)
		var low: float = 0.0
		var band: float = 0.0
		var q: float = 1.0 / 1.6
		for i in range(n):
			var u: float = float(i) / float(n)
			var fc: float = 170.0 + 820.0 * sin(PI * u)
			var f: float = 2.0 * sin(PI * fc / srf)
			var inp: float = src[i]
			var high: float = inp - low - q * band
			band += f * high
			low += f * band
			var env: float = pow(sin(PI * u), 1.8)
			var t: float = float(i) / srf
			var v: float = band * env
			v += 0.25 * sin(TAU * 46.0 * t) * pow(sin(PI * u), 3.0)   # pressure swell
			v += 0.12 * air[i] * pow(sin(PI * u), 4.0)                # air past the ear
			out[i] = v
		_edges(out, srf, 0.002, 0.008)
		_normalize(out, 0.84)
		return _to_wav(out, sr, false)

	## float32 -> 16-bit signed little-endian PCM. 16 bits is the right depth:
	## the beds sit 30 dB down and the quantisation floor at -96 dBFS is still
	## 60 dB below them.
	func _to_wav(samples: PackedFloat32Array, sr: int, loop: bool) -> AudioStreamWAV:
		var n: int = samples.size()
		var data := PackedByteArray()
		data.resize(n * 2)
		for i in range(n):
			var v: float = clampf(samples[i], -1.0, 1.0)
			data.encode_s16(i * 2, int(round(v * 32767.0)))
		var w := AudioStreamWAV.new()
		w.format = AudioStreamWAV.FORMAT_16_BITS
		w.mix_rate = sr
		w.stereo = false
		w.data = data
		if loop:
			w.loop_mode = AudioStreamWAV.LOOP_FORWARD
			w.loop_begin = 0
			w.loop_end = n
		else:
			w.loop_mode = AudioStreamWAV.LOOP_DISABLED
		_bytes += n * 2
		return w

	func teardown() -> void:
		if _fade != null and _fade.is_valid():
			_fade.kill()
		var si: int = AudioServer.get_bus_index(BUS_SPACE)
		if si >= 0:
			AudioServer.remove_bus(si)
		var ti: int = AudioServer.get_bus_index(BUS_TONE)
		if ti >= 0:
			AudioServer.remove_bus(ti)


	# ── THE LO-FI BED (2026-08-21, Palle: "we have a music system, can add
	# some low fi") ── a 75 BPM loop synthesised like everything else here:
	# no file, deterministic from a seed, seamless BY CONSTRUCTION. 75 BPM
	# makes the beat exactly 0.8 s = 17,640 frames at 22050 Hz, so four bars
	# are 282,240 frames and the loop closes on an integer — no crossfade,
	# no seam. Four warm chords (Fmaj7 Am7 Dm7 Cmaj7) with tremolo and a
	# soft second harmonic, a bass root on the strong beats, a gliding kick,
	# a brushed snare, swung hats, and vinyl: hiss plus Poisson crackle whose
	# tick tails WRAP the loop with modulo indexing. Routed through BUS_TONE,
	# so the music inherits each room's low-pass like the air does.
	const LOFI_BPM := 75.0
	const LOFI_RATE := 22050
	const LOFI_DB := -14.0

	func lofi(on: bool) -> void:
		if not on:
			if music_player != null and music_player.playing:
				var tw_off := create_tween()
				tw_off.tween_property(music_player, "volume_db", -60.0, 1.2)
				tw_off.tween_callback(music_player.stop)
			return
		if lofi_stream == null:
			var t0 := Time.get_ticks_msec()
			lofi_stream = _build_lofi()
			print("[em_audio] lo-fi bed synthesised: %.1f s loop in %d ms" % [
				lofi_stream.data.size() / 2.0 / LOFI_RATE, Time.get_ticks_msec() - t0])
		if music_player == null:
			music_player = AudioStreamPlayer.new()
			music_player.name = "LofiBed"
			music_player.bus = BUS_TONE
			music_player.stream = lofi_stream
			add_child(music_player)
		music_player.volume_db = -60.0
		music_player.play()
		var tw := create_tween()
		tw.tween_property(music_player, "volume_db", LOFI_DB, 2.5)

	func _build_lofi() -> AudioStreamWAV:
		var rng := RandomNumberGenerator.new()
		rng.seed = SYNTH_SEED + 1
		var beat := int(round(60.0 / LOFI_BPM * LOFI_RATE))   # 17,640
		var bar := beat * 4
		var n := bar * 4                                       # 282,240
		var buf := PackedFloat32Array()
		buf.resize(n)
		# chords: [root, third-ish, fifth, seventh] in Hz, one per bar
		var chords := [
			[174.61, 220.0, 261.63, 329.63],   # Fmaj7
			[220.0, 261.63, 329.63, 392.0],    # Am7
			[146.83, 174.61, 220.0, 261.63],   # Dm7
			[130.81, 164.81, 196.0, 246.94],   # Cmaj7
		]
		var dt := 1.0 / float(LOFI_RATE)
		for b in range(4):
			var notes: Array = chords[b]
			var det := 1.0 + rng.randf_range(-0.0015, 0.0015)
			for i in range(bar):
				var t := float(i) * dt
				var u := float(i) / float(bar)
				var env := minf(t / 0.05, 1.0) * (1.0 if u < 0.94 else (1.0 - u) / 0.06)
				var trem := 1.0 - 0.18 * (0.5 - 0.5 * cos(TAU * 4.7 * t))
				var v := 0.0
				for f_v in notes:
					var f := float(f_v)
					v += sin(TAU * f * t) + 0.32 * sin(TAU * f * 2.0 * t) \
						+ 0.5 * sin(TAU * f * det * t)
				buf[b * bar + i] += v * env * trem * 0.045
				# bass root on beats 1 and 3
				var ib := i % (beat * 2)
				var tb := float(ib) * dt
				buf[b * bar + i] += sin(TAU * float(notes[0]) * 0.5 * tb) \
					* exp(-tb / 0.4) * 0.16
		# drums per bar
		for b in range(4):
			for k in [0, 2]:                                   # kick, beats 1 and 3
				var at: int = b * bar + k * beat
				for j in range(int(0.25 * LOFI_RATE)):
					var t2 := float(j) * dt
					var f2 := 58.0 - 20.0 * minf(t2 / 0.12, 1.0)
					buf[(at + j) % n] += sin(TAU * f2 * t2) * exp(-t2 / 0.07) * 0.42
			for sn in [1, 3]:                                  # brushed snare, 2 and 4
				var at2: int = b * bar + sn * beat
				var lp := 0.0
				for j in range(int(0.12 * LOFI_RATE)):
					lp += 0.25 * (rng.randf_range(-1, 1) - lp)
					buf[(at2 + j) % n] += lp * exp(-float(j) * dt / 0.05) * 0.30
			for e in range(8):                                 # swung hats
				if rng.randf() < 0.15:
					continue
				var swing := int(0.085 * LOFI_RATE) if e % 2 == 1 else 0
				var at3: int = b * bar + e * (beat / 2) + swing
				var hp := 0.0
				var prev := 0.0
				for j in range(int(0.035 * LOFI_RATE)):
					var w := rng.randf_range(-1, 1)
					hp = w - prev + 0.6 * hp
					prev = w
					buf[(at3 + j) % n] += hp * exp(-float(j) * dt / 0.016) * 0.06
		# vinyl: hiss + crackle, tails wrapping the seam
		var hiss := 0.0
		for i in range(n):
			hiss += 0.3 * (rng.randf_range(-1, 1) - hiss)
			buf[i] += hiss * 0.010
		var ticks := int(3.5 * float(n) / float(LOFI_RATE))
		for _t in range(ticks):
			var at4 := rng.randi_range(0, n - 1)
			var amp := rng.randf_range(0.02, 0.09) * (1.0 if rng.randf() < 0.5 else -1.0)
			var tau := rng.randf_range(0.0012, 0.004)
			for j in range(int(tau * 6.0 * LOFI_RATE)):
				buf[(at4 + j) % n] += amp * exp(-float(j) * dt / tau)
		# the lo in lo-fi: one-pole LP ~3.1 kHz, primed on the tail so the
		# filtered loop is exactly periodic (the beds' own trick)
		var a := 1.0 - exp(-TAU * 3100.0 * dt)
		var st := 0.0
		for i in range(n - int(0.25 * LOFI_RATE), n):
			st += a * (buf[i] - st)
		for i in range(n):
			st += a * (buf[i] - st)
			buf[i] = st
		# normalise and pack
		var peak := 0.0
		for i in range(n):
			peak = maxf(peak, absf(buf[i]))
		var g := 0.7 / maxf(peak, 0.001)
		var data := PackedByteArray()
		data.resize(n * 2)
		for i in range(n):
			var q := int(clampf(buf[i] * g, -1.0, 1.0) * 32767.0)
			data[2 * i] = q & 0xFF
			data[2 * i + 1] = (q >> 8) & 0xFF
		var stream := AudioStreamWAV.new()
		stream.format = AudioStreamWAV.FORMAT_16_BITS
		stream.mix_rate = LOFI_RATE
		stream.stereo = false
		stream.data = data
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = n
		return stream


## ── static facade ────────────────────────────────────────────────────────────

static var _rig: Rig = null
static var _checked: bool = false
static var _available: bool = false
static var _announced: bool = false

## Build the audio rig under `root`. Idempotent, and a clean no-op with no
## side effects at all when there is no audio output to build for.
static func install(root: Node3D) -> void:
	if _rig != null and is_instance_valid(_rig):
		return
	if root == null:
		return
	if not _audio_available():
		if not _announced:
			_announced = true
			print("[em_audio] no audio output (headless, capture or --em-no-audio) — install is a no-op")
		return
	var r := Rig.new()
	root.add_child(r)
	_rig = r
	r.build(root)

## cabinet | corridor | gallery | hall. Anything else resolves to gallery.
## Crossfades the bed and the reverb over 0.9 s and fires the threshold whoosh.
static func lofi(on: bool) -> void:
	if _rig != null:
		_rig.lofi(on)


static func set_space(kind: String) -> void:
	if _rig == null or not is_instance_valid(_rig):
		return
	_rig.go_space(kind)

## stone | oak (aliases: wood/timber/plank/parquet/board -> oak, everything
## else -> stone). Call it once per footfall; the module owns the variation.
static func footstep(surface: String) -> void:
	if _rig == null or not is_instance_valid(_rig):
		return
	_rig.step(surface)

## The doorway whoosh on its own, for thresholds that do not change space kind.
static func threshold() -> void:
	if _rig == null or not is_instance_valid(_rig):
		return
	_rig.play_whoosh()

## Explicit wiring, when the feel module is not reachable from the museum root.
static func bind_footsteps(emitter: Object, signal_name: String = "footstep") -> bool:
	if _rig == null or not is_instance_valid(_rig):
		return false
	return _rig.bind(emitter, signal_name)

static func is_active() -> bool:
	return _rig != null and is_instance_valid(_rig)

static func uninstall() -> void:
	if _rig == null or not is_instance_valid(_rig):
		_rig = null
		return
	_rig.teardown()
	_rig.queue_free()
	_rig = null

## THE HEADLESS GUARD. Six independent reasons to stay silent, any one of which
## is sufficient. Cached: the answer cannot change inside a run, and the capture
## path must not pay for the check per call.
##
## The --em-shot clause is not paranoia, it is the 16-second rule: a proof shot
## has no ears, so it should not pay 0.3 s of synthesis or hold an audio device
## while the watchdog is counting. A capture run is silent BY CONSTRUCTION, not
## by luck.
static func _audio_available() -> bool:
	if _checked:
		return _available
	_checked = true
	_available = false
	if _flagged(OS.get_cmdline_args()) or _flagged(OS.get_cmdline_user_args()):
		return false
	if OS.has_feature("headless"):
		return false
	if DisplayServer.get_name().to_lower().find("headless") >= 0:
		return false
	if AudioServer.get_bus_count() < 1:
		return false
	if AudioServer.get_mix_rate() <= 0.0:
		return false
	var devices: PackedStringArray = AudioServer.get_output_device_list()
	if devices.is_empty():
		return false
	if devices.size() == 1 and str(devices[0]) == "Disabled":
		return false
	_available = true
	return true

static func _flagged(args: PackedStringArray) -> bool:
	for a in args:
		var s: String = str(a)
		if s == "--em-no-audio" or s.begins_with("--em-shot"):
			return true
	return false
