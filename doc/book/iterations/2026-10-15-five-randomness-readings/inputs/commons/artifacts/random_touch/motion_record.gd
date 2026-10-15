extends RefCounted
## Five abacus paths starting at rest. X is shared; only the last row adds Y.
const COUNT := 48
const RANGE := 0.44
const Y_RANGE := 0.12
const RATES := [0.4, 0.8, 1.6, 3.2, 0.8]
const LANES := 5
const MARKS_PER_SEGMENT := 12
const INK_LIMIT := COUNT * MARKS_PER_SEGMENT

static func make_record(seed_value: int = 435, distribution: String = "uniform") -> Dictionary:
	var x_rng := RandomNumberGenerator.new()
	var y_rng := RandomNumberGenerator.new()
	x_rng.seed = seed_value
	y_rng.seed = seed_value + 1
	var points: Array = [[0.0, 0.0]]
	for i in range(1, COUNT):
		points.append([draw(x_rng,RANGE,distribution), draw(y_rng,Y_RANGE,distribution)])
	return {"schema":"random-touch/4", "seed":seed_value, "distribution":distribution, "points":points, "rates":RATES.duplicate(), "range":RANGE, "y_range":Y_RANGE, "seconds":[0.0,0.0,0.0,0.0,0.0], "offsets":[[0.0,0.0],[0.0,0.0],[0.0,0.0],[0.0,0.0],[0.0,0.0]], "returning":[false,false,false,false,false], "ink":[[],[],[],[],[]]}

static func draw(rng: RandomNumberGenerator, extent: float, distribution: String) -> float:
	if distribution == "uniform": return rng.randf_range(-extent,extent)
	# Truncated normal, sigma = extent/3. Reject tails, never pile them at an edge.
	var value := rng.randfn(0.0,extent/3.0)
	while absf(value) > extent: value = rng.randfn(0.0,extent/3.0)
	return value

static func number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value))

static func valid(record: Dictionary) -> bool:
	if record.get("schema") != "random-touch/4": return false
	if record.get("distribution") not in ["uniform","gaussian_bounded"]: return false
	if not number(record.get("seed")): return false
	if not record.get("points") is Array or record.points.size() != COUNT: return false
	if not record.get("rates") is Array or record.rates != RATES: return false
	if not number(record.get("range")): return false
	if not is_equal_approx(float(record.range), RANGE): return false
	if not number(record.get("y_range")) or not is_equal_approx(float(record.y_range), Y_RANGE): return false
	for field in ["seconds", "offsets", "returning"]:
		if not record.get(field) is Array or record[field].size() != LANES: return false
	for p in record.points:
		if not p is Array or p.size() != 2: return false
		for v in p:
			if not number(v) or absf(float(v)) > RANGE: return false
		if absf(float(p[1])) > Y_RANGE: return false
	if float(record.points[0][0]) != 0 or float(record.points[0][1]) != 0: return false
	for lane in LANES:
		if not number(record.seconds[lane]) or float(record.seconds[lane]) < 0: return false
		if not record.returning[lane] is bool: return false
		var p = record.offsets[lane]
		if not p is Array or p.size() != 2: return false
		if not number(p[0]) or not number(p[1]): return false
		if absf(float(p[0])) > RANGE or absf(float(p[1])) > Y_RANGE: return false
		if lane < LANES-1 and float(p[1]) != 0: return false
		if not record.returning[lane] and not Vector3(p[0],p[1],0).is_equal_approx(offset(record,lane,float(record.seconds[lane]))): return false
	if not record.get("ink") is Array or record.ink.size() != LANES: return false
	for lane in LANES:
		if not record.ink[lane] is Array or record.ink[lane].size() > INK_LIMIT: return false
		for p in record.ink[lane]:
			if not p is Array or p.size()!=2 or not number(p[0]) or not number(p[1]): return false
			if absf(p[0])>RANGE or absf(p[1])>Y_RANGE or (lane<4 and p[1]!=0): return false
	return true

static func offset(record: Dictionary, lane: int, seconds: float) -> Vector3:
	var phase := maxf(seconds, 0.0) * float(record.rates[lane])
	var index := int(floor(phase)) % COUNT
	var u := fposmod(phase, 1.0)
	u = u * u * (3.0 - 2.0 * u)
	var a: Array = record.points[index]
	var b: Array = record.points[(index + 1) % COUNT]
	return Vector3(lerpf(a[0], b[0], u), lerpf(a[1], b[1], u) if lane == LANES-1 else 0.0, 0)
