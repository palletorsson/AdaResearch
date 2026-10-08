extends RefCounted
## A deliberately small room model: three damped round-trip delay paths.
## Not geometric ray tracing or a measured impulse response. All sample work
## runs on a worker. Every pass takes the PREVIOUS buffer, not the original.
const RATE := 22050
const MAX_VOICE_SECONDS := 8.0
const TAIL_SECONDS := 3.0
const DIMENSIONS := Vector3(6.0,3.0,5.0)
const SPEED_OF_SOUND := 343.0

static func unpack(wav: AudioStreamWAV) -> PackedFloat32Array:
	var samples := PackedFloat32Array()
	if wav == null or wav.format != AudioStreamWAV.FORMAT_16_BITS: return samples
	var channels := 2 if wav.stereo else 1
	var count := wav.data.size() / (2*channels)
	samples.resize(count)
	var data := wav.data
	for i in count:
		var value := float(data.decode_s16(i*2*channels))/32768.0
		if channels==2: value = (value+float(data.decode_s16(i*4+2))/32768.0)*.5
		samples[i] = value
	return samples

static func prepare(wav: AudioStreamWAV) -> Dictionary:
	var raw := unpack(wav)
	if raw.is_empty(): return {"error":"No microphone audio. Try DEMO VOICE."}
	var count := mini(raw.size(),int(MAX_VOICE_SECONDS*wav.mix_rate))
	var energy := 0.0
	for i in count: energy += raw[i]*raw[i]
	if sqrt(energy/maxi(1,count)) < .0005: return {"error":"No clear voice received. Try DEMO VOICE."}
	# Bound bandwidth before decimating microphone PCM. This is an inexpensive
	# low-pass approximation, not a studio sample-rate converter.
	var filtered := 0.0
	var alpha := 1.0-exp(-TAU*6500.0/wav.mix_rate)
	for i in count:
		filtered += alpha*(raw[i]-filtered)
		raw[i] = filtered
	var voice_count := int(float(count)*RATE/wav.mix_rate)
	var output := PackedFloat32Array()
	output.resize(voice_count+int(TAIL_SECONDS*RATE))
	for i in voice_count:
		var at := float(i)*wav.mix_rate/RATE
		var lo := mini(int(at),count-1)
		output[i] = lerpf(raw[lo],raw[mini(lo+1,count-1)],at-lo)
	return finish(output)

static func room_pass(previous: PackedFloat32Array, absorption: float, dimensions := DIMENSIONS) -> Dictionary:
	var start := Time.get_ticks_msec()
	var reflectivity := lerpf(.94,.25,clampf(absorption,0,1))
	var damping := lerpf(.10,.72,clampf(absorption,0,1))
	var result := PackedFloat32Array()
	result.resize(previous.size())
	for axis in 3:
		var delay := maxi(1,roundi(2.0*dimensions[axis]/SPEED_OF_SOUND*RATE))
		var ring := PackedFloat32Array()
		ring.resize(delay)
		var cursor := 0
		var low := 0.0
		for i in previous.size():
			low = lerpf(ring[cursor],low,damping)
			var sample := previous[i]+reflectivity*low
			ring[cursor] = sample
			cursor += 1
			if cursor==delay: cursor = 0
			result[i] += sample/3.0
	for i in result.size(): result[i] = .12*previous[i]+.88*result[i]
	var finished := finish(result)
	finished["worker_ms"] = Time.get_ticks_msec()-start
	return finished

static func finish(samples: PackedFloat32Array) -> Dictionary:
	var peak := 0.0
	# A fixed recording window models a finite tape pass. Fade only the last
	# 60 ms to avoid a hard cut if a resonance reaches that window's end.
	var edge := mini(1323,samples.size()/2)
	for i in edge:
		samples[samples.size()-1-i] *= float(i)/edge
	for sample in samples: peak = maxf(peak,absf(sample))
	var gain := .55/maxf(peak,.000001)
	var bytes := PackedByteArray()
	bytes.resize(samples.size()*2)
	for i in samples.size():
		samples[i] *= gain
		bytes.encode_s16(i*2,roundi(clampf(samples[i],-.55,.55)*32767))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.stereo = false
	stream.data = bytes
	return {"samples":samples,"stream":stream,"peak_before_normalization":peak}
