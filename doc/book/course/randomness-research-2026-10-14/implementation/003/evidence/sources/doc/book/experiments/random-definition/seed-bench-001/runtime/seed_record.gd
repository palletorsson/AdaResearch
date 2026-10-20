extends RefCounted
## Local pilot format. Stored draws are authoritative; replay never resumes an RNG.
const SCHEMA := "ada.seed-bench.v1"
const MAX_BYTES := 65536
const MAPPINGS := ["rgb-fixed.v1", "rgb-mean-height.v1"]
var current: Dictionary = {}
var kept: Dictionary = {}
var serial := 0
var error := ""

func acquire(seed_value: int = 42) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var before := str(rng.state)
	var values: Array = []
	for i in range(48): values.append(rng.randf())
	serial += 1
	current = {
		"schema": SCHEMA, "id": "seed-%s-%s-%s" % [seed_value, Time.get_ticks_usec(), serial],
		"parent_id": null, "generator": "Godot.RandomNumberGenerator.randf",
		"build": Engine.get_version_info().string, "seed": str(seed_value),
		"state_before": before, "state_after": str(rng.state), "raw_values": values,
		"raw_values_f64_hex": encode_values(values),
		"draw_count": 48, "draw_order": "row-major triples; no discard",
		"parameters": {"grid": [4, 4], "spacing_m": 0.1, "cube_side_m": 0.04,
			"base_centre_height_m": 0.1, "height_span_m": 0.3},
		"mapping_version": MAPPINGS[0],
		"host_transform": {"hall": "Random_Definition", "position_m": [10.5, 0, 18.5],
			"rotation_y_degrees": -90, "scale": [1, 1, 1], "tray_y_m": 1.0},
		"ordered_interventions": [], "observation": "", "next_change": ""
	}

func encode_values(values: Array) -> String:
	var bytes := PackedByteArray(); bytes.resize(values.size() * 8)
	for i in range(values.size()): bytes.encode_double(i * 8, values[i])
	return bytes.hex_encode()

func select_mapping(index: int) -> bool:
	if current.is_empty() or index < 0 or index >= MAPPINGS.size(): return false
	if current.mapping_version != MAPPINGS[index]:
		current.ordered_interventions.append({"from": current.mapping_version, "to": MAPPINGS[index]})
		current.mapping_version = MAPPINGS[index]
	return true

func cells(record: Dictionary, fixed: bool = false) -> Array:
	var result: Array = []
	for i in range(16):
		var a: float = record.raw_values[i * 3]
		var b: float = record.raw_values[i * 3 + 1]
		var c: float = record.raw_values[i * 3 + 2]
		var y := 0.1
		if not fixed and record.mapping_version == MAPPINGS[1]: y += 0.3 * (a + b + c) / 3.0
		result.append({"position": Vector3((i % 4 - 1.5) * 0.1, y, (i / 4 - 1.5) * 0.1),
			"colour": Color(a, b, c)})
	return result

func keep_result() -> bool:
	if current.is_empty(): return false
	kept = current.duplicate(true)
	kept.parent_id = current.id
	serial += 1
	kept.id = "%s/keep-%s" % [current.id, serial]
	return true

func replay() -> bool:
	if kept.is_empty(): return false
	current = kept.duplicate(true)
	return true

func clear_kept() -> void:
	kept.clear()

func export_record(path: String) -> bool:
	error = ""
	if kept.is_empty(): error = "KEEP a result first"; return false
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null: error = "Cannot write " + path; return false
	file.store_string(JSON.stringify(kept, "\t", true, true) + "\n")
	file.flush()
	if file.get_error() != OK: error = "Write failed"; return false
	return true

func decimal64(value: Variant) -> bool:
	# Reject exponent syntax and overflow; never round a seed/state through JSON float.
	return value is String and value.is_valid_int() and str(value.to_int()) == value

func same_contract(value: Variant, expected: Variant) -> bool:
	# JSON numbers have one floating type; bools and numeric strings are not numbers.
	if expected is int or expected is float:
		return (value is int or value is float) and value == expected
	if expected is Array:
		if not value is Array or value.size() != expected.size(): return false
		for i in range(expected.size()):
			if not same_contract(value[i], expected[i]): return false
		return true
	if expected is Dictionary:
		if not value is Dictionary or value.size() != expected.size(): return false
		for key in expected:
			if not value.has(key) or not same_contract(value[key], expected[key]): return false
		return true
	return typeof(value) == typeof(expected) and value == expected

func validate(value: Variant) -> String:
	if not value is Dictionary: return "Record must be an object"
	var keys := ["schema", "id", "parent_id", "generator", "build", "seed", "state_before", "state_after",
		"raw_values", "raw_values_f64_hex", "draw_count", "draw_order", "parameters", "mapping_version", "host_transform",
		"ordered_interventions", "observation", "next_change"]
	if value.size() != keys.size(): return "Unknown or missing fields"
	for key in keys:
		if not value.has(key): return "Missing " + key
	if value.schema != SCHEMA or not value.mapping_version in MAPPINGS: return "Unsupported version"
	for key in ["id", "generator", "build", "draw_order", "observation", "next_change"]:
		if not value[key] is String or value[key].length() > 2048: return "Invalid text: " + key
	if value.id.is_empty() or value.build.is_empty(): return "Missing provenance"
	if value.parent_id != null and (not value.parent_id is String or value.parent_id.length() > 2048): return "Invalid parent"
	for key in ["seed", "state_before", "state_after"]:
		if not decimal64(value[key]): return "Invalid signed 64-bit decimal: " + key
	if value.generator != "Godot.RandomNumberGenerator.randf" or value.draw_count != 48 or value.draw_order != "row-major triples; no discard": return "Unsupported acquisition"
	if not value.raw_values is Array or value.raw_values.size() != 48: return "Expected 48 values"
	for v in value.raw_values:
		if not (v is float or v is int) or not is_finite(float(v)) or v < 0 or v > 1: return "Value outside [0,1]"
	if not value.raw_values_f64_hex is String or value.raw_values_f64_hex.length() != 768: return "Missing exact float bytes"
	var bytes: PackedByteArray = value.raw_values_f64_hex.hex_decode()
	if bytes.size() != 384 or bytes.hex_encode() != value.raw_values_f64_hex: return "Invalid float bytes"
	for i in range(48):
		var exact := bytes.decode_double(i * 8)
		if not is_finite(exact) or exact < 0 or exact > 1 or absf(exact - value.raw_values[i]) > 0.000000000000001: return "Decimal values disagree with exact bytes"
	var parameters := {"grid": [4, 4], "spacing_m": 0.1, "cube_side_m": 0.04, "base_centre_height_m": 0.1, "height_span_m": 0.3}
	if not same_contract(value.parameters, parameters): return "Unsupported geometry parameters"
	var host := {"hall": "Random_Definition", "position_m": [10.5, 0, 18.5], "rotation_y_degrees": -90, "scale": [1, 1, 1], "tray_y_m": 1.0}
	if not same_contract(value.host_transform, host): return "Unsupported host transform"
	if not value.ordered_interventions is Array or value.ordered_interventions.size() > 256: return "Invalid intervention history"
	var previous: String = MAPPINGS[0]
	for step in value.ordered_interventions:
		if not step is Dictionary or step.size() != 2 or not step.has_all(["from", "to"]): return "Invalid intervention"
		if step.from != previous or not step.to in MAPPINGS or step.from == step.to: return "Broken mapping lineage"
		previous = step.to
	if previous != value.mapping_version: return "Mapping differs from history"
	return ""

func import_record(path: String) -> bool:
	error = ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null: error = "Cannot read " + path; return false
	if file.get_length() > MAX_BYTES: error = "Record exceeds 64 KiB"; return false
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK: error = "Invalid JSON: " + parser.get_error_message(); return false
	error = validate(parser.data)
	if not error.is_empty(): return false
	# Atomic acceptance: a bad import cannot change either the live or kept result.
	kept = parser.data.duplicate(true)
	# Decimal JSON parsing can shift a double by one ULP even with full_precision.
	# Godot's byte codec is the replay authority; the numeric array is inspectable text.
	var bytes: PackedByteArray = kept.raw_values_f64_hex.hex_decode()
	for i in range(48): kept.raw_values[i] = bytes.decode_double(i * 8)
	# Restore the schema's integer types only after validating their exact values.
	kept.draw_count = 48
	kept.parameters.grid = [4, 4]
	kept.host_transform.position_m = [10.5, 0, 18.5]
	kept.host_transform.rotation_y_degrees = -90
	kept.host_transform.scale = [1, 1, 1]
	return replay()
