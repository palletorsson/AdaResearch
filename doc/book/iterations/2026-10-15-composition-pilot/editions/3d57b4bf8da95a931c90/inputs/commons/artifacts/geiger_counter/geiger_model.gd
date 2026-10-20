extends RefCounted
## Ideal stationary Poisson detections; not a radiation measurement.
const VERSION := "ada-geiger-1"
const COUNT := 96
const SAMPLE_RATE := 44100
const MODULUS := 2147483647

static func extract(events: Array, clock_us: int) -> Array:
	var pairs: Array = []
	var emitted := 0
	for i in range(0,events.size()-3,4):
		# Four distinct pulses. The intervening gap is not one of the two measurements.
		@warning_ignore("integer_division")
		var t1 := (int(events[i+1])-int(events[i])) / clock_us
		@warning_ignore("integer_division")
		var t2 := (int(events[i+3])-int(events[i+2])) / clock_us
		var bit := -1
		if t1 != t2:
			bit = (0 if t1 < t2 else 1) ^ (emitted % 2)
			emitted += 1
		pairs.append({"t1":t1,"t2":t2,"bit":bit,"reverse":(emitted-1)%2==1 if bit>=0 else emitted%2==1})
	return pairs

static func make_record(seed_value: int, rate: int, clock_us: int, source: Dictionary) -> Dictionary:
	var state := clampi(seed_value,1,MODULUS-1)
	var events: Array = []
	var elapsed := 0
	for i in range(COUNT):
		state = (state * 48271) % MODULUS
		var u := float(state)/MODULUS
		elapsed += maxi(1,int(round(-log(1.0-u)/rate*1000000.0)))
		events.append(elapsed)
	return {"version":VERSION,"seed":seed_value,"rate_per_second":rate,"clock_us":clock_us,
		"source":source.duplicate(true),"events_us":events,"pairs":extract(events,clock_us),
		"sound":{"sample_rate":SAMPLE_RATE,"pulse_ms":6,"gain":0.38}}

static func valid(record: Dictionary) -> bool:
	if record.get("version") != VERSION or not record.get("source") is Dictionary: return false
	if not record.source.get("label") is String: return false
	for key in ["seed","rate_per_second","clock_us"]:
		var v: Variant = record.get(key)
		if not (v is int or v is float): return false
		if not is_finite(float(v)) or float(v)!=floor(float(v)): return false
	if int(record.seed)<0 or int(record.seed)>=MODULUS or not int(record.rate_per_second) in [2,4,8]: return false
	if not int(record.clock_us) in [1000,100000]: return false
	if not record.get("events_us") is Array or record.events_us.size()!=COUNT: return false
	if not record.get("pairs") is Array or record.pairs.size()!=COUNT/4: return false
	if record.get("sound") != {"sample_rate":SAMPLE_RATE,"pulse_ms":6,"gain":0.38}:
		# JSON turns integral numbers into floats, so compare fields explicitly.
		if not record.get("sound") is Dictionary: return false
		if record.sound.get("sample_rate")!=SAMPLE_RATE or record.sound.get("pulse_ms")!=6 or record.sound.get("gain")!=0.38: return false
	if not record.source.get("provider") in ["chosen_seed","system_seed"]: return false
	if record.source.provider=="system_seed":
		var hex_text := str(record.source.get("bytes_hex",""))
		if hex_text.length()!=8: return false
		for character in hex_text:
			if not character in "0123456789abcdef": return false
		if int(hex_text.hex_decode().decode_u32(0) % (MODULUS-1))+1!=int(record.seed): return false
	var rebuilt := make_record(int(record.seed),int(record.rate_per_second),int(record.clock_us),record.source)
	for i in range(COUNT):
		if record.events_us[i]!=rebuilt.events_us[i]: return false
	if int(record.events_us[-1])>120000000: return false
	for i in range(COUNT/4):
		if not record.pairs[i] is Dictionary: return false
		for key in ["t1","t2","bit","reverse"]:
			if record.pairs[i].get(key)!=rebuilt.pairs[i][key]: return false
	return true

static func waveform(events: Array) -> AudioStreamWAV:
	# Whole-clip rendering: frame hitches cannot bunch clicks into one frame.
	var duration := float(events[-1])/1000000.0+0.3
	var pcm := PackedByteArray(); pcm.resize(int(ceil(duration*SAMPLE_RATE))*2)
	var pulse := PackedInt32Array()
	for i in range(int(SAMPLE_RATE*0.006)):
		var t := float(i)/SAMPLE_RATE
		var wave := (sin(TAU*2300*t)+0.35*sin(TAU*6100*t))*exp(-t/0.0011)*minf(1.0,t/0.0001)
		pulse.append(int(wave*0.38*32767))
	for stamp in events:
		var start := int(round(float(stamp)/1000000.0*SAMPLE_RATE))
		for i in range(pulse.size()):
			var offset := (start+i)*2
			pcm.encode_s16(offset,clampi(pcm.decode_s16(offset)+pulse[i],-26214,26214))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS; stream.mix_rate = SAMPLE_RATE; stream.stereo = false; stream.data = pcm
	return stream

static func bit_string(record: Dictionary) -> String:
	var words := ""
	for pair in record.pairs: words += "-" if int(pair.bit)<0 else str(int(pair.bit))
	return words
