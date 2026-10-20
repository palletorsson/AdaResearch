extends RefCounted
## Small real classifier: 6 hand coordinates -> 8 tanh units -> 3 softmax outputs.
## No guide poses, category templates or prerecorded scores enter this model.
const INPUTS := 6
const HIDDEN := 8
const CLASSES := 3
const PARAMETERS := 83
const MAX_PER_CLASS := 20
const EPOCHS := 300
const RATE := 0.20
const SCHEMA := "ada-hand-pose-1"
var weights := PackedFloat64Array()
var examples: Array = []
var tests: Array = []
var epoch := 0
var trained := false
var initial_loss := 0.0
var history: Array = []
var revision := 0

func _init() -> void:
	initialize(417)

func initialize(seed_value: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	weights.resize(PARAMETERS)
	weights.fill(0.0)
	for j in HIDDEN:
		for i in INPUTS: weights[j * INPUTS + i] = rng.randf_range(-0.55, 0.55)
	for k in CLASSES:
		for j in HIDDEN: weights[56 + k * HIDDEN + j] = rng.randf_range(-0.55, 0.55)
	epoch = 0
	trained = false
	tests.clear()
	history.clear()
	initial_loss = loss()
	history.append(initial_loss)

static func valid_input(x: Array) -> bool:
	if x.size() != INPUTS: return false
	for v in x:
		if not (v is float or v is int) or not is_finite(float(v)) or absf(float(v)) > 4.0: return false
	return true

func counts() -> Array:
	var result := [0, 0, 0]
	for e: Dictionary in examples: result[int(e.label)] += 1
	return result

func add_example(x: Array, label: int) -> bool:
	if label < 0 or label >= CLASSES or not valid_input(x) or counts()[label] >= MAX_PER_CLASS: return false
	examples.append({"x": x.duplicate(), "label": label})
	revision += 1
	trained = false
	epoch = 0
	tests.clear()
	history.clear()
	return true

func can_train() -> bool:
	for amount in counts():
		if amount < 3: return false
	return true

func forward(x: Array) -> Dictionary:
	if not valid_input(x): return {}
	var hidden := PackedFloat64Array()
	for j in HIDDEN:
		var z := weights[48 + j]
		for i in INPUTS: z += weights[j * INPUTS + i] * float(x[i])
		hidden.append(tanh(z))
	var scores := PackedFloat64Array()
	for k in CLASSES:
		var z := weights[80 + k]
		for j in HIDDEN: z += weights[56 + k * HIDDEN + j] * hidden[j]
		scores.append(z)
	var largest := scores[0]
	for value in scores: largest = maxf(largest, value)
	var total := 0.0
	for k in CLASSES:
		scores[k] = exp(scores[k] - largest)
		total += scores[k]
	for k in CLASSES: scores[k] /= total
	return {"hidden": hidden, "scores": scores}

func gradient(x: Array, label: int) -> PackedFloat64Array:
	var result := PackedFloat64Array()
	result.resize(PARAMETERS)
	result.fill(0.0)
	var f := forward(x)
	if f.is_empty() or label < 0 or label >= CLASSES: return result
	var delta: PackedFloat64Array = f.scores.duplicate()
	delta[label] -= 1.0 # derivative of softmax + cross entropy
	for k in CLASSES:
		result[80 + k] = delta[k]
		for j in HIDDEN: result[56 + k * HIDDEN + j] = delta[k] * f.hidden[j]
	for j in HIDDEN:
		var hidden_delta := 0.0
		for k in CLASSES: hidden_delta += delta[k] * weights[56 + k * HIDDEN + j]
		hidden_delta *= 1.0 - f.hidden[j] * f.hidden[j] # tanh derivative
		result[48 + j] = hidden_delta
		for i in INPUTS: result[j * INPUTS + i] = hidden_delta * float(x[i])
	return result # all derivatives use the same, not-yet-updated weights

func example_loss(x: Array, label: int) -> float:
	return -log(maxf(1e-12, forward(x).scores[label]))

func loss() -> float:
	if examples.is_empty(): return 0.0
	var value := 0.0
	for e: Dictionary in examples: value += example_loss(e.x, int(e.label))
	return value / examples.size()

func train_epoch() -> void:
	if not can_train() or epoch >= EPOCHS: return
	var mean := PackedFloat64Array()
	mean.resize(PARAMETERS)
	mean.fill(0.0)
	for e: Dictionary in examples:
		var g := gradient(e.x, int(e.label))
		for p in PARAMETERS: mean[p] += g[p] / examples.size()
	for p in PARAMETERS: weights[p] -= RATE * mean[p]
	epoch += 1
	if epoch % 10 == 0: history.append(loss())
	trained = epoch == EPOCHS

func predict(x: Array) -> Dictionary:
	if not trained: return {}
	var f := forward(x)
	if f.is_empty(): return {}
	var best := 0
	for k in CLASSES:
		if f.scores[k] > f.scores[best]: best = k
	# A separate proximity policy. A softmax score alone cannot detect novelty.
	var distance := INF
	for e: Dictionary in examples:
		var squared := 0.0
		for i in INPUTS: squared += pow(float(x[i]) - float(e.x[i]), 2)
		distance = minf(distance, sqrt(squared / INPUTS))
	return {"label": best, "scores": f.scores, "distance": distance,
		"accepted": f.scores[best] >= 0.70 and distance <= 0.32}

func test_example(x: Array, expected: int) -> Dictionary:
	if expected < 0 or expected >= CLASSES: return {}
	var prediction := predict(x)
	if prediction.is_empty(): return {}
	var record := {"x": x.duplicate(), "expected": expected,
		"predicted": prediction.label, "accepted": prediction.accepted,
		"correct": prediction.label == expected, "revision": revision}
	tests.append(record)
	if tests.size() > 90: tests.pop_front()
	return record

func snapshot() -> Dictionary:
	return {"schema": SCHEMA, "weights": Array(weights), "examples": examples.duplicate(true),
		"tests": tests.duplicate(true), "epoch": epoch, "trained": trained,
		"initial_loss": initial_loss, "history": history.duplicate(), "revision": revision}

func restore(data: Variant) -> bool:
	if not data is Dictionary or data.get("schema") != SCHEMA: return false
	var w: Variant = data.get("weights")
	var rows: Variant = data.get("examples")
	var ep: Variant = data.get("epoch")
	if not w is Array or w.size() != PARAMETERS or not rows is Array or rows.size() > MAX_PER_CLASS * CLASSES: return false
	if not (ep is int or ep is float) or float(ep) != int(ep) or ep < 0 or ep > EPOCHS: return false
	if not data.get("trained") is bool: return false
	for v in w:
		if not (v is int or v is float) or not is_finite(float(v)) or absf(float(v)) > 1000.0: return false
	var amounts := [0, 0, 0]
	for row in rows:
		if not row is Dictionary or not row.get("x") is Array or not valid_input(row.x): return false
		var label: Variant = row.get("label")
		if not (label is int or label is float) or float(label) != int(label) or label < 0 or label >= CLASSES: return false
		amounts[int(label)] += 1
		if amounts[int(label)] > MAX_PER_CLASS: return false
	if data.trained:
		if int(ep) != EPOCHS: return false
		for n in amounts:
			if n < 3: return false
	weights = PackedFloat64Array(w)
	examples = rows.duplicate(true)
	epoch = int(ep)
	trained = data.trained
	# Re-open a saved model as a new evaluation session. Do not import stale claims.
	tests.clear()
	history.clear()
	initial_loss = loss()
	history.append(initial_loss)
	revision += 1
	return true

func save_file(path: String) -> Error:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null: return FileAccess.get_open_error()
	file.store_string(JSON.stringify(snapshot(), "  ", true, true))
	return file.get_error()

func load_file(path: String) -> bool:
	if not FileAccess.file_exists(path): return false
	return restore(JSON.parse_string(FileAccess.get_file_as_string(path)))
