extends RefCounted
## Original sparse pop score: clean plucked keys, stereo pad, rounded bass,
## dry kick/snap and small offbeat hats. Offline synthesis, two continuous stems.
const SR := 22050

static func render(config: Dictionary) -> Dictionary:
	var beat := 60.0 / float(config.bpm)
	var bars := int(config.bars)
	var frames := roundi(bars * 4.0 * beat * SR)
	var keys := PackedFloat32Array()
	var bed := PackedFloat32Array()
	var pulse := PackedFloat32Array()
	keys.resize(frames * 2)
	bed.resize(frames * 2)
	pulse.resize(frames * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(config.seed)
	for bar in bars:
		var harmony: int = (bar / 2) % config.chords.size()
		var chord: Array = config.chords[harmony]
		var start := bar * 4.0 * beat
		for event: Array in config.keys:
			var onset := start + float(event[0]) * beat
			var strength := float(event[1])
			for n in chord.size():
				_key(keys, onset, _hz(float(chord[n])), 0.042 * strength, lerpf(-0.55, 0.55, float(n) / maxf(1.0, chord.size() - 1)))
		if bar % 2 == 0:
			for n in chord.size():
				_pad(bed, start, beat * 8.0, _hz(float(chord[n])), 0.012, 0.6 if n % 2 else -0.6)
		for event: Array in config.bass:
			_bass(bed, start + float(event[0]) * beat, beat * float(event[1]), _hz(float(config.bass_notes[harmony])), 0.11 * float(event[2]))
		var kicks: Array = config.kick[bar % config.kick.size()]
		for position in kicks: _kick(pulse, start + float(position) * beat)
		for position in config.snap: _snap(pulse, start + float(position) * beat, rng)
		for event: Array in config.hat:
			_hat(pulse, start + float(event[0]) * beat, float(event[1]), rng, -0.35 if bar % 2 else 0.35)
	# A quiet dotted echo makes room around the dry keys; no tape wobble or hiss.
	var echo := roundi(beat * 0.75 * SR)
	for frame in frames:
		var previous := posmod(frame - echo, frames)
		bed[frame * 2] += keys[frame * 2] + keys[previous * 2 + 1] * 0.19
		bed[frame * 2 + 1] += keys[frame * 2 + 1] + keys[previous * 2] * 0.19
	return {"bed": _wav(bed, 0.12), "pulse": _wav(pulse, 0.09), "seconds": float(frames) / SR}

static func _hz(note: float) -> float:
	return 440.0 * pow(2.0, (note - 69.0) / 12.0)

static func _put(data: PackedFloat32Array, index: int, value: float, pan: float = 0.0) -> void:
	var frame := posmod(index, data.size() / 2)
	data[frame * 2] += value * sqrt((1.0 - pan) * 0.5)
	data[frame * 2 + 1] += value * sqrt((1.0 + pan) * 0.5)

static func _key(data: PackedFloat32Array, onset: float, frequency: float, level: float, pan: float) -> void:
	var start := roundi(onset * SR)
	for i in roundi(1.65 * SR):
		var t := float(i) / SR
		var env := (1.0 - exp(-t / 0.006)) * exp(-t / 0.29) * minf(1.0, (1.65 - t) / 0.08)
		var phase := TAU * frequency * t
		var tone := sin(phase + 0.6 * sin(phase * 2.0) * exp(-t * 9.0)) + 0.08 * sin(phase * 3.0)
		_put(data, start + i, tone * env * level, pan)

static func _pad(data: PackedFloat32Array, onset: float, duration: float, frequency: float, level: float, pan: float) -> void:
	var start := roundi(onset * SR)
	for i in roundi(duration * SR):
		var t := float(i) / SR
		var env := minf(1.0, t / 0.22) * minf(1.0, (duration - t) / 0.45)
		var tone := 0.65 * sin(TAU * frequency * t) + 0.22 * sin(TAU * frequency * 1.002 * t) + 0.13 * sin(TAU * frequency * 0.998 * t)
		_put(data, start + i, tone * env * level, pan)

static func _bass(data: PackedFloat32Array, onset: float, duration: float, frequency: float, level: float) -> void:
	var start := roundi(onset * SR)
	for i in roundi(duration * SR):
		var t := float(i) / SR
		var env := (1.0 - exp(-t / 0.012)) * exp(-t * 0.9) * minf(1.0, (duration - t) / 0.09)
		# Audible upper body keeps the sub legible on small headset speakers.
		var phase := TAU * frequency * t
		_put(data, start + i, (sin(phase) + 0.25 * sin(phase * 2.0) + 0.20 * sin(phase * 0.5)) * env * level)

static func _kick(data: PackedFloat32Array, onset: float) -> void:
	var start := roundi(onset * SR)
	for i in roundi(0.34 * SR):
		var t := float(i) / SR
		var phase := TAU * (48.0 * t + 2.8 * (1.0 - exp(-t * 35.0)))
		var env := minf(1.0, t / 0.002) * exp(-t * 18.0) * minf(1.0, (0.34 - t) / 0.025)
		_put(data, start + i, sin(phase) * env * 0.24)

static func _snap(data: PackedFloat32Array, onset: float, rng: RandomNumberGenerator) -> void:
	var start := roundi(onset * SR)
	var low := 0.0
	for i in roundi(0.13 * SR):
		var t := float(i) / SR
		var noise := rng.randf_range(-1.0, 1.0)
		low += 0.28 * (noise - low)
		var env := exp(-t * 52.0) + 0.6 * exp(-absf(t - 0.009) * 320.0) + 0.35 * exp(-absf(t - 0.018) * 260.0)
		env *= minf(1.0, t / 0.001) * minf(1.0, (0.13 - t) / 0.015)
		_put(data, start + i, ((noise - low) * 0.07 + sin(TAU * 195.0 * t) * 0.022) * env, -0.12)

static func _hat(data: PackedFloat32Array, onset: float, velocity: float, rng: RandomNumberGenerator, pan: float) -> void:
	var start := roundi(onset * SR)
	var low := 0.0
	for i in roundi(0.055 * SR):
		var t := float(i) / SR
		var noise := rng.randf_range(-1.0, 1.0)
		low += 0.55 * (noise - low)
		var env := minf(1.0, t / 0.001) * exp(-t * 100.0) * minf(1.0, (0.055 - t) / 0.008)
		_put(data, start + i, (noise - low) * env * velocity * 0.10, pan)

static func _wav(samples: PackedFloat32Array, target_rms: float) -> AudioStreamWAV:
	var frames := samples.size() / 2
	for channel in 2:
		var step := samples[(frames - 1) * 2 + channel] - samples[channel]
		for i in 220:
			var f := 1.0 - float(i) / 220.0
			samples[i * 2 + channel] += step * f * f
	var energy := 0.0
	var peak := 0.0
	for sample in samples:
		energy += sample * sample
		peak = maxf(peak, absf(sample))
	var gain := minf(target_rms / maxf(sqrt(energy / samples.size()), 0.00001), 0.65 / maxf(peak, 0.00001))
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in samples.size(): bytes.encode_s16(i * 2, roundi(samples[i] * gain * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SR
	wav.stereo = true
	wav.data = bytes
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_end = frames
	return wav
