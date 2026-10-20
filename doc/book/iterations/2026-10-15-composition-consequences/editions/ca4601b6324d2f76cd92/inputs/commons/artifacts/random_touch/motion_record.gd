extends RefCounted
## A retained ride starting at rest. X is shared; Y stays above the entry height.
const COUNT := 48
const RANGE := 1.0
const RATES := [0.8, 1.6, 0.8]

static func make_record(seed_value: int = 435) -> Dictionary:
	var x_rng := RandomNumberGenerator.new()
	var y_rng := RandomNumberGenerator.new()
	x_rng.seed = seed_value
	y_rng.seed = seed_value + 1
	var points: Array = [[0.0, 0.0]]
	for i in range(1, COUNT):
		points.append([x_rng.randf_range(-RANGE, RANGE), y_rng.randf_range(0.0, RANGE)])
	return {"schema":"random-touch/2", "seed":seed_value, "points":points, "rates":RATES.duplicate(), "range":RANGE, "seconds":[0.0,0.0,0.0], "offsets":[[0.0,0.0],[0.0,0.0],[0.0,0.0]], "returning":[false,false,false]}

static func number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value))

static func valid(record: Dictionary) -> bool:
	if record.get("schema") != "random-touch/2": return false
	if not number(record.get("seed")): return false
	if not record.get("points") is Array or record.points.size() != COUNT: return false
	if not record.get("rates") is Array or record.rates != RATES: return false
	if not number(record.get("range")): return false
	if not is_equal_approx(float(record.range), RANGE): return false
	for field in ["seconds", "offsets", "returning"]:
		if not record.get(field) is Array or record[field].size() != 3: return false
	for p in record.points:
		if not p is Array or p.size() != 2: return false
		for v in p:
			if not number(v) or absf(float(v)) > RANGE: return false
		if float(p[1]) < 0: return false
	if float(record.points[0][0]) != 0 or float(record.points[0][1]) != 0: return false
	for lane in 3:
		if not number(record.seconds[lane]) or float(record.seconds[lane]) < 0: return false
		if not record.returning[lane] is bool: return false
		var p = record.offsets[lane]
		if not p is Array or p.size() != 2: return false
		if not number(p[0]) or not number(p[1]): return false
		if absf(float(p[0])) > RANGE or float(p[1]) < 0 or float(p[1]) > RANGE: return false
		if lane < 2 and float(p[1]) != 0: return false
		if not record.returning[lane] and not Vector3(p[0],p[1],0).is_equal_approx(offset(record,lane,float(record.seconds[lane]))): return false
	return true

static func offset(record: Dictionary, lane: int, seconds: float) -> Vector3:
	var phase := maxf(seconds, 0.0) * float(record.rates[lane])
	var index := int(floor(phase)) % COUNT
	var u := fposmod(phase, 1.0)
	u = u * u * (3.0 - 2.0 * u)
	var a: Array = record.points[index]
	var b: Array = record.points[(index + 1) % COUNT]
	return Vector3(lerpf(a[0], b[0], u), lerpf(a[1], b[1], u) if lane == 2 else 0.0, 0)
