extends AudioStreamPlayer
## Procedural Hard 128 BPM / Hyper 134 BPM Club Disco Synthesizer.
## Pre-renders crisp, zero-crackle seamless 4-bar PCM AudioStreamWAV loops
## (4-on-the-floor club kick, snare/clap, off-beat disco hi-hats, octave-slap
## synth bass, bright disco brass/string stabs, and glittering arpeggio lead).
## Automatically scopes audio playback to Floor 33 so adjacent storeys stay quiet.

const SAMPLE_RATE := 22050

var floor_y: float = -210.0
var bpm: float = 128.0
var mode: String = "hard"  # "hard" (128 BPM) | "hyper" (134 BPM)
var muted: bool = false

var _tracks: Dictionary = {}
var _fallback_time: float = 0.0
var _active_on_floor: bool = false

func _ready() -> void:
	name = "HardDiscoMusic"
	volume_db = -5.5
	_tracks["hard"] = _synthesize_loop(128.0, false)
	_tracks["hyper"] = _synthesize_loop(134.0, true)
	stream = _tracks["hard"]
	bpm = 128.0
	_update_floor_scope(0.0)

func toggle_mode() -> String:
	mode = "hyper" if mode == "hard" else "hard"
	bpm = 134.0 if mode == "hyper" else 128.0
	var was_playing := playing
	stream = _tracks[mode]
	if was_playing and not muted:
		play()
	return mode

func toggle_mute() -> bool:
	muted = not muted
	if muted and playing:
		stop()
	elif not muted and _active_on_floor and not playing:
		play()
	return muted

func _process(delta: float) -> void:
	_fallback_time += delta
	_update_floor_scope(delta)

func _update_floor_scope(_delta: float) -> void:
	var game := get_tree().get_first_node_in_group("void_game")
	var on_floor := true
	if is_instance_valid(game) and game.get("body") != null:
		var body_y: float = (game.body as Node3D).global_position.y
		on_floor = absf(body_y - floor_y) < 4.8
	_active_on_floor = on_floor
	if muted or not on_floor:
		if playing:
			stop()
	else:
		if not playing and stream != null:
			play()

func get_beat_phase() -> float:
	var t := get_playback_position() if playing else _fallback_time
	return t * (bpm / 60.0)

func get_kick_pulse() -> float:
	var frac := fposmod(get_beat_phase(), 1.0)
	return exp(-frac * 5.8)

func get_band_energies() -> Array[float]:
	var beat := get_beat_phase()
	var kick := exp(-fposmod(beat, 1.0) * 6.0)
	var hat := exp(-fposmod(beat + 0.5, 1.0) * 10.0)
	var snare := exp(-fposmod(beat + 1.0, 2.0) * 7.5)
	var out: Array[float] = []
	for i in range(8):
		var fi := float(i)
		var wave := 0.5 + 0.5 * sin(beat * PI * (1.0 + fi * 0.25) + fi * 0.9)
		var e := 0.22 + kick * (0.78 if i < 2 else 0.32) + snare * (0.55 if i >= 2 and i < 5 else 0.15) + hat * (0.65 if i >= 5 else 0.1) + wave * 0.22
		out.append(clampf(e, 0.10, 1.0))
	return out

func _synthesize_loop(target_bpm: float, hyper: bool) -> AudioStreamWAV:
	var beat_sec := 60.0 / target_bpm
	var total_beats := 16.0  # 4 full bars of 4/4
	var total_sec := beat_sec * total_beats
	var total_samples := int(roundf(total_sec * float(SAMPLE_RATE)))
	var data := PackedByteArray()
	data.resize(total_samples * 2)

	# Hard Italo / Hi-NRG minor progression (F minor or G minor)
	var root_hz := 49.0 if hyper else 43.65  # G1 or F1
	var chord_roots: Array[int] = [0, 0, -4, -2]       # i, i, bVI, bVII
	var bass_octaves: Array[int] = [0, 12, 0, 12, 3, 15, 7, 19]
	if not hyper:
		bass_octaves = [0, 12, 0, 12, 0, 12, 7, 12]
	var arp_notes: Array[int] = [0, 3, 7, 10, 12, 15, 12, 7]
	var chord_intervals: Array[int] = [0, 3, 7, 10]

	var noise_seed: int = 133742
	var lp_state: float = 0.0

	for i in range(total_samples):
		var t := float(i) / float(SAMPLE_RATE)
		var beat := t / beat_sec
		var beat_frac := fposmod(beat, 1.0)
		var bar_idx := int(floor(beat / 4.0)) % 4
		var step16 := int(floor(beat * 4.0))
		var step16_frac := fposmod(beat * 4.0, 1.0)
		var root_semi: int = chord_roots[bar_idx]

		# Deterministic crisp white noise generator for hats & claps
		noise_seed = int((noise_seed * 1103515245 + 12345) & 0x7FFFFFFF)
		var noise := (float(noise_seed) / 1073741824.0) - 1.0

		# 1. HARD 4-ON-THE-FLOOR CLUB KICK (punchy sub drop + beater snap)
		var kick_env := exp(-beat_frac * 9.5) * minf(1.0, beat_frac * 140.0)
		var kick_phase := beat_frac * beat_sec
		var kick := sin(TAU * (46.0 * kick_phase + 11.5 * (1.0 - exp(-beat_frac * 24.0)))) * kick_env
		var click := sin(TAU * 920.0 * kick_phase) * exp(-beat_frac * 65.0) * 0.35
		var kick_sample := (kick + click) * 0.72
		var sidechain := clampf(0.28 + 0.72 * minf(1.0, beat_frac * 3.8), 0.28, 1.0)

		# 2. SNAPPY DISCO CLAP / SNARE ON BEATS 2 & 4
		var beat_in_bar := int(floor(fposmod(beat, 4.0)))
		var clap := 0.0
		if beat_in_bar == 1 or beat_in_bar == 3:
			var c_env := exp(-beat_frac * 15.0) * (1.0 + 0.45 * sin(beat_frac * 210.0))
			var body := sin(TAU * 195.0 * kick_phase) * exp(-beat_frac * 24.0) * 0.45
			clap = (noise * c_env * 0.48 + body) * 0.58

		# 3. SIZZLING OFF-BEAT OPEN DISCO HI-HAT (+ 16th shimmer)
		var off_frac := fposmod(beat + 0.5, 1.0)
		var open_hat := noise * exp(-off_frac * 16.0) * 0.28
		var closed_hat := noise * exp(-step16_frac * 38.0) * (0.12 if step16 % 2 == 1 else 0.05)
		var hat_sample := open_hat + closed_hat

		# 4. DRIVING OCTAVE-JUMPING FUNKY DISCO SYNTH BASS (16th-note pulse!)
		var bass_semi: int = root_semi + bass_octaves[step16 % bass_octaves.size()]
		var bass_hz := root_hz * pow(2.0, float(bass_semi) / 12.0)
		var bp := fposmod(t * bass_hz, 1.0)
		var bass_raw := (bp * 2.0 - 1.0) * 0.65 + (1.0 if bp < 0.5 else -1.0) * 0.35
		var bass_env := exp(-step16_frac * (4.2 if hyper else 3.4)) * minf(1.0, step16_frac * 45.0)
		# Simple one-pole resonant-style lowpass for fat synth punch
		var cutoff := clampf(0.14 + bass_env * 0.38, 0.08, 0.65)
		lp_state = lp_state + cutoff * (bass_raw - lp_state)
		var bass_sample := lp_state * bass_env * sidechain * 0.58

		# 5. BRIGHT DISCO BRASS / STRING CHORD STABS (syncopated funk hits)
		var stab_hits: Array[int] = [0, 3, 6, 10, 12, 14]
		var stab_sample := 0.0
		var bar_step := step16 % 16
		if bar_step in stab_hits:
			var s_env := exp(-step16_frac * 5.2) * minf(1.0, step16_frac * 35.0)
			var chord_sum := 0.0
			for iv: int in chord_intervals:
				var hz := root_hz * 4.0 * pow(2.0, float(root_semi + iv) / 12.0)
				var sp := fposmod(t * hz, 1.0)
				chord_sum += (sp * 2.0 - 1.0) * 0.25 + sin(TAU * hz * t) * 0.25
			stab_sample = chord_sum * s_env * sidechain * 0.24

		# 6. GLITTERING DISCO ARPEGGIO SYNTH LEAD
		var arp_semi: int = root_semi + arp_notes[(step16 + bar_idx * 2) % arp_notes.size()]
		var arp_hz := root_hz * 8.0 * pow(2.0, float(arp_semi) / 12.0)
		var arp_env := exp(-step16_frac * 7.5) * minf(1.0, step16_frac * 60.0)
		var arp_sample := (sin(TAU * arp_hz * t) * 0.7 + sin(TAU * arp_hz * 2.0 * t) * 0.3) * arp_env * sidechain * (0.20 if hyper else 0.15)

		# Master punchy club limiter (soft saturation tanh)
		var mix := kick_sample + clap + hat_sample + bass_sample + stab_sample + arp_sample
		mix = tanh(mix * 1.18) * 0.90
		var v := int(clampf(mix, -1.0, 1.0) * 32000.0)
		data[i * 2] = v & 0xFF
		data[i * 2 + 1] = (v >> 8) & 0xFF

	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SAMPLE_RATE
	wav.stereo = false
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = 0
	wav.loop_end = total_samples
	wav.data = data
	return wav

func kick_frac_scale(f: float) -> float:
	return f * 22.0
