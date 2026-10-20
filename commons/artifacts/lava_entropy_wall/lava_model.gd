extends RefCounted
## A deliberately inspectable animation, NOT a fluid solver or entropy source.
## Integer state and a CPU sensor keep the experiment independent of GPU pixels.
const VERSION := "ada-lava-1"
const WIDTH := 96
const HEIGHT := 48
const MODULUS := 2147483647
const MULTIPLIER := 48271

static func next_value(state: int) -> int:
	return (state * MULTIPLIER) % MODULUS

static func triangle(phase: int) -> int:
	return 1000 - absi(posmod(phase, 2000) - 1000)

static func bodies(seed_value: int, frame: int, heat: int) -> Array:
	var state := clampi(seed_value, 1, MODULUS - 1)
	var result: Array = []
	for lamp in range(12):
		for blob in range(4):
			state = next_value(state)
			var phase := state % 2000
			state = next_value(state)
			var speed := 2 + state % 4
			@warning_ignore("integer_division")
			var travel := frame * speed * heat / 100
			state = next_value(state)
			@warning_ignore("integer_division")
			var x := -85 + triangle(phase + travel / 3) * 170 / 1000
			@warning_ignore("integer_division")
			var y := 160 + triangle(phase + travel) * 670 / 1000
			result.append({"lamp":lamp,"x":x,"y":y,"rx":65 + state % 30,"ry":105 + state % 55})
	return result

static func pixels(blobs: Array, covered: bool) -> PackedByteArray:
	var raw := PackedByteArray()
	raw.resize(WIDTH * HEIGHT)
	for py in range(HEIGHT):
		for px in range(WIDTH):
			@warning_ignore("integer_division")
			var lamp := (1 - py / 24) * 6 + px / 16
			var x := (px % 16) * 25 - 188
			@warning_ignore("integer_division")
			var y := 1000 - ((py % 24) * 1000 + 500) / 24
			var level := 12
			for index in range(lamp * 4, lamp * 4 + 4):
				var b: Dictionary = blobs[index]
				var dx: int = x - int(b.x)
				var dy: int = y - int(b.y)
				@warning_ignore("integer_division")
				var distance := dx * dx * 256 / (int(b.rx) * int(b.rx)) + dy * dy * 256 / (int(b.ry) * int(b.ry))
				level += maxi(0, 230 - distance)
			raw[py * WIDTH + px] = 0 if covered and px < WIDTH / 2 else mini(255, level)
	return raw

static func digest(raw: PackedByteArray) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(raw)
	return context.finish().hex_encode()

static func values(hash_text: String) -> Array:
	# The reduction is intentionally visible: a 28-bit seed, not a crypto key.
	var state := maxi(1, hash_text.left(7).hex_to_int())
	var result: Array = []
	for i in range(48):
		state = next_value(state)
		result.append(float(state) / MODULUS)
	return result

static func capture(seed_value: int, frame: int, heat: int, covered: bool, source: Dictionary) -> Dictionary:
	var state := bodies(seed_value, frame, heat)
	var raw := pixels(state, covered)
	var hash_text := digest(raw)
	return {"version":VERSION,"seed":seed_value,"tick":frame,"ticks_per_second":30,"heat":heat,
		"covered":covered,"source":source.duplicate(true),"bodies":state,"width":WIDTH,"height":HEIGHT,
		"pixels_hex":raw.hex_encode(),"sha256":hash_text,"output_seed":maxi(1,hash_text.left(7).hex_to_int()),
		"values":values(hash_text)}

static func valid(record: Dictionary) -> bool:
	if record.get("version") != VERSION or record.get("width") != WIDTH or record.get("height") != HEIGHT:
		return false
	for key in ["seed","tick","heat","covered","source","bodies","pixels_hex","sha256","values","output_seed"]:
		if not record.has(key): return false
	if not record.source is Dictionary or not record.bodies is Array or not record.values is Array:
		return false
	if not record.source.get("label") is String or not record.source.get("provider") is String:
		return false
	if record.get("ticks_per_second") != 30: return false
	for key in ["seed","tick","heat","output_seed"]:
		var number: Variant = record[key]
		if not (number is int or number is float): return false
		if not is_finite(float(number)) or float(number) != floor(float(number)): return false
	if int(record.seed) < 0 or int(record.seed) >= MODULUS or int(record.tick) < 0 or int(record.tick) > 100000000:
		return false
	if int(record.heat) < 50 or int(record.heat) > 200 or not record.covered is bool:
		return false
	var hex_text := str(record.pixels_hex)
	if hex_text.length() != WIDTH * HEIGHT * 2: return false
	for character in hex_text:
		if not character in "0123456789abcdef": return false
	if record.source.provider == "godot_crypto_random_bytes":
		var source_hex := str(record.source.get("bytes_hex",""))
		if source_hex.length() != 32: return false
		for character in source_hex:
			if not character in "0123456789abcdef": return false
		if maxi(1,digest(source_hex.hex_decode()).left(7).hex_to_int()) != record.seed: return false
	elif record.source.provider != "chosen_model_seed": return false
	var raw := hex_text.hex_decode()
	if raw.size() != WIDTH * HEIGHT or digest(raw) != str(record.sha256): return false
	var rebuilt := capture(int(record.seed),int(record.tick),int(record.heat),bool(record.covered),record.source)
	if rebuilt.pixels_hex != hex_text or rebuilt.output_seed != record.output_seed: return false
	if record.bodies.size() != 48 or record.values.size() != 48: return false
	# JSON numbers return as floats: compare numeric fields, not their JSON spellings.
	for i in range(48):
		if not record.bodies[i] is Dictionary: return false
		for key in ["lamp","x","y","rx","ry"]:
			if record.bodies[i].get(key) != rebuilt.bodies[i][key]: return false
		if not (record.values[i] is float or record.values[i] is int): return false
		if absf(float(record.values[i])-float(rebuilt.values[i])) > 0.00000000000001: return false
	return true
