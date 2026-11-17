extends RefCounted
## Original procedural accompaniment. Two phase-aligned loops: warm keys/bass
## and a brushed pulse. Generated offline by ship_opera_music.gd; no live DSP.
const SR := 22050

static func render(config: Dictionary) -> Dictionary:
	var beat := 60.0 / float(config.get("bpm", 84.0))
	var beats := int(config.get("bars", 4)) * 4
	var frames := roundi(beat * beats * SR)
	var duration := float(frames) / SR
	var bed := PackedFloat32Array()
	var pulse := PackedFloat32Array()
	bed.resize(frames)
	pulse.resize(frames)
	var chords: Array = config.chords
	var rng := RandomNumberGenerator.new()
	rng.seed = int(config.get("seed", 171126))
	var low_noise := 0.0
	var filtered_bed := 0.0
	var filtered_pulse := 0.0
	var frequencies := []
	for chord: Array in chords:
		var row := []
		for note in chord: row.append(440.0 * pow(2.0, (float(note) - 69.0) / 12.0))
		frequencies.append(row)
	for i in frames:
		var t := float(i) / SR
		var b := t / beat
		var bar := int(b / 4.0)
		var key_age := fposmod(t, beat * 2.0)
		var env := (1.0 - exp(-key_age / 0.018)) * exp(-key_age / 1.1) * minf(1.0, (beat * 2.0 - key_age) / 0.025)
		var row: Array = frequencies[(bar / 2) % frequencies.size()]
		var keys := 0.0
		# Gentle tape drift, harmonically simple keys and a soft electrical edge.
		var wobble := 0.00013 * sin(TAU * t * 0.31) + 0.000018 * sin(TAU * t * 4.1)
		for f: float in row:
			var phase := TAU * f * (key_age + wobble)
			keys += (sin(phase + 0.35 * sin(phase * 2.0) * exp(-key_age * 4.0)) + 0.14 * sin(phase * 2.0)) * env
		keys *= 0.13 / row.size()
		var bass_age := fposmod(t, beat * 4.0)
		var bass := sin(TAU * 82.4069 * bass_age) * (1.0 - exp(-bass_age / 0.025)) * exp(-bass_age / 1.7) * minf(1.0, (beat * 4.0 - bass_age) / 0.025) * 0.055
		var white := rng.randf_range(-1.0, 1.0)
		low_noise += 0.18 * (white - low_noise)
		filtered_bed += 0.24 * (keys + bass + low_noise * 0.0012 - filtered_bed)
		bed[i] = tanh(filtered_bed * 1.3) / 1.3
		var kick_age := fposmod(t, beat * 2.0)
		var kick_phase := TAU * (49.0 * kick_age + 4.0 * (1.0 - exp(-kick_age * 25.0)))
		var kick := sin(kick_phase) * exp(-kick_age * 22.0) * minf(1.0, kick_age / 0.004) * 0.12
		var snare_age := fposmod(t + beat, beat * 2.0)
		var brush := low_noise * exp(-snare_age * 20.0) * minf(1.0, snare_age / 0.006) * 0.10
		var hat_age := fposmod(t + beat * 0.04, beat * 0.5)
		var hat := (white - low_noise) * exp(-hat_age * 125.0) * minf(1.0, hat_age / 0.002) * 0.012
		filtered_pulse += 0.30 * (kick + brush + hat - filtered_pulse)
		pulse[i] = filtered_pulse
	return {"bed": _wav(_join_loop(bed)), "pulse": _wav(_join_loop(pulse)), "seconds": duration}

static func _join_loop(samples: PackedFloat32Array) -> PackedFloat32Array:
	# Remove the tiny end-to-start step over ten milliseconds, preserving length.
	var step := samples[samples.size() - 1] - samples[0]
	var edge := mini(220, samples.size())
	for i in edge:
		var f := 1.0 - float(i) / edge
		samples[i] += step * f * f
	return samples

static func _wav(samples: PackedFloat32Array) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	var energy := 0.0
	var peak := 0.0
	for x in samples:
		energy += x * x
		peak = maxf(peak, absf(x))
	var gain := minf(0.12 / maxf(sqrt(energy / samples.size()), 0.00001), 0.65 / maxf(peak, 0.00001))
	for i in samples.size(): bytes.encode_s16(i * 2, roundi(samples[i] * gain * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SR
	wav.data = bytes
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_end = samples.size()
	return wav
