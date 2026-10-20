# Keep the values; change their job

This is a continuation of Random Definition's seed lesson. You already have a generator, ordered triples, colour assignments and a carried point. Here the question is yours to test: what does height let you notice that the colour arrangement did not? Predict before pressing a control. A preference for the flat arrangement is a possible result.

The complete printed version is [tutorial.md](tutorial.md). Its code blocks are extracted and executed by the reconstruction check. That checks the printed program; a person rebuilding and explaining it remains a separate test. The supplied record adapter is printed too. You may initially borrow its persistence machinery, but mark that assistance rather than claiming to have understood it.

Run `python doc/book/experiments/random-definition/seed-bench-001/launch.py` from the repository. It prepares a separate museum instance and starts beside the study. The museum supplies its floor, lighting and desktop walker. The installed instrument remains nearby. This launcher uses desktop mode; physical headset operation is still untested. Alternatively, attach `seed_study.gd` to a new Node3D beside the existing instrument, with hall-local position `(10.5, 0, 18.5)`, Y rotation `-90°` and scale `(1, 1, 1)`. Keep the three printed scripts together. The carried point depends on the project's installed XRTools classes; its trigger signal is inherited support.

The left array is a fixed reference. The right array switches between the same flat assignment and the height assignment. Compare the right array before and after as well as across the two trays: their different viewing positions are not identical retinal conditions. Both retain RGB; neither asks for new values while changing height. Unshaded colours make the material assignment identical in both arrays. This is a display study, without a force or cloth model.

Each cell receives three successive draws, `a`, `b`, `c`. There are sixteen cells and forty-eight values. Index `i = 4 * row + column` fixes their order. X and Z use ten-centimetre spacing; each cube is four centimetres wide. A places its centre ten centimetres above the tray. B uses `0.10 + 0.30 * (a + b + c) / 3` metres. Read those two assignments in `cells()`. Everything else in that method stays fixed.

Before running B, work through four invented triples: `(0,0,0)`, `(1,1,1)`, `(1,0,0)`, `(0,1,0)`. Their expected heights are `0.10`, `0.40`, `0.20`, `0.20` metres. These are arithmetic examples, not the first draws from seed 42. Why do the red and green cells have the same height? What information would you need to recover their colours from height alone?

Use this cycle and keep your account beside the exported record:

1. Start at seed 42 and press F1 for flat. Record your prediction and which cell you will follow.
2. Press F2. Describe an observable difference, an absence of interest, or a new question. Do not call the height “more random”: the retained numbers have not changed.
3. Press F3 to KEEP, then F5 to EXPORT. F8 deliberately makes the next seed's draws. F4 replays the kept result. Check the seed, mapping and arrangement return.
4. Press F7 to clear the memory copy, then F6 to import the exported result. Close and reopen the study, then import again. The file is `seed-bench-001.json` in Godot's user data folder; its full location can be found through **Project → Open User Data Folder** in the editor.
5. Rebuild from the printed blocks in a separate folder. Change only the right-hand height formula to use `a`. Predict which equal-height pair separates. This is a proposed next experiment; retain the mean version and give the alternative its own mapping ID before exporting it.
6. Explain which code you understood, borrowed or needed help with. Record assistance and an unsuccessful attempt too. Return your observation to both the tutorial question and the final's “one more agreement” passage. Either may need revision.

Our first automated export/import attempt failed. JSON changed integer field types, and decimal parsing shifted several double values by a tiny amount even with full-precision output. The adapter now validates the entire record before accepting it. Seed and generator state are decimal strings. Exact float bytes are the replay authority; the numeric array remains readable and must agree within `1e-15`. Import restores those bytes and never resumes an RNG. An invalid import leaves the current and kept results intact. KEEP makes a deep copy; clearing it does not delete an exported file.

Replaying these values is different from obtaining a new unpredictable outcome. F8 is another deterministic seeded acquisition. The same-build generator check and the stored-value replay are separate tests; neither establishes the quality of a physical randomness source. Godot documents [RNG state and seeds](https://docs.godotengine.org/en/4.6/classes/class_randomnumbergenerator.html) and [JSON's numeric conversion](https://docs.godotengine.org/en/4.6/classes/class_json.html). The actual failures and repairs are in [observations.md](observations.md).

The following three complete files form this continuation. `seed_record.gd` holds the experiment and persistence rules; `seed_study.gd` builds the visible objects and controls; `point_body.gd` is the unchanged carried-point support from the earlier lesson. The record adapter is deliberately explicit so a hidden persistence failure can become a question about the apparatus.


## seed_record.gd

<!-- student-code:seed_record.gd -->
```gdscript
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
```

## seed_study.gd

<!-- student-code:seed_study.gd -->
```gdscript
extends Node3D
## Side-by-side reference and interpretation. Desktop keys and carried-point activation.
const Record = preload("seed_record.gd")
const Point = preload("point_body.gd")
var model = Record.new()
var cubes: Array = []
var status_label: Label3D
var point: Node3D
var export_path := "user://seed-bench-001.json"
var controls := ["F1: FLAT", "F2: HEIGHT", "F3: KEEP", "F4: REPLAY", "F5: EXPORT", "F6: IMPORT", "F7: CLEAR", "F8: NEXT SEED"]

func label_at(words: String, pos: Vector3, size: int = 30) -> Label3D:
	var label := Label3D.new()
	label.text = words; label.position = pos; label.font_size = size
	label.pixel_size = 0.001; label.no_depth_test = false
	add_child(label)
	return label

func _ready() -> void:
	model.acquire()
	label_at("48 VALUES / TWO ASSIGNMENTS", Vector3(0, 1.67, -0.24), 40)
	label_at("REFERENCE: RGB, FIXED HEIGHT", Vector3(-0.32, 1.12, 0.31), 20)
	label_at("SAME RGB / SELECT A OR B", Vector3(0.32, 1.12, 0.31), 20)
	for panel in range(2):
		var tray := Node3D.new(); tray.position = Vector3(-0.32 if panel == 0 else 0.32, 1.0, 0)
		add_child(tray)
		var panel_cubes: Array = []
		for i in range(16):
			var cube := MeshInstance3D.new()
			var mesh := BoxMesh.new(); mesh.size = Vector3.ONE * 0.04
			cube.mesh = mesh
			var material := StandardMaterial3D.new()
			# Unshaded shared mapping prevents lighting differences masquerading as data changes.
			material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			cube.material_override = material; tray.add_child(cube); panel_cubes.append(cube)
		cubes.append(panel_cubes)
		var plate := MeshInstance3D.new(); var plate_mesh := BoxMesh.new()
		plate_mesh.size = Vector3(0.45, 0.015, 0.45); plate.mesh = plate_mesh
		var plate_mat := StandardMaterial3D.new(); plate_mat.albedo_color = Color(0.035, 0.045, 0.055)
		plate.material_override = plate_mat; tray.add_child(plate)
	for i in range(controls.size()):
		label_at(controls[i], Vector3((i % 4 - 1.5) * 0.30, 0.85 - (i / 4) * 0.13, 0.42), 23)
	status_label = label_at("", Vector3(0, 0.51, 0.42), 20)
	point = Point.new(); add_child(point); point.position = Vector3(-0.85, 1.05, 0.65)
	point.action_pressed.connect(point_action)
	refresh("Choose FLAT or HEIGHT, then KEEP.\nDesktop: F1-F8. VR: hold point at a label; press trigger.")

func refresh(message: String = "") -> void:
	for panel in range(2):
		var data: Array = model.cells(model.current, panel == 0)
		for i in range(16):
			cubes[panel][i].position = data[i].position
			cubes[panel][i].material_override.albedo_color = data[i].colour
	status_label.text = "Seed %s | %s | %s\n%s" % [model.current.seed, model.current.mapping_version,
		"KEPT" if not model.kept.is_empty() else "NO KEPT COPY", message]

func activate(index: int) -> void:
	var message := ""
	match index:
		0, 1: model.select_mapping(index); message = "Same 48 values. Only the height rule changes."
		2: model.keep_result(); message = "Independent copy kept. Export to keep it after closing."
		3: message = "Replayed stored values and mapping." if model.replay() else "No kept result. Use KEEP first."
		4: message = "Exported: " + export_path if model.export_record(export_path) else model.error
		5: message = "Imported stored result." if model.import_record(export_path) else model.error
		6: model.clear_kept(); message = "Memory copy cleared; exported file remains."
		7: model.acquire(model.current.seed.to_int() + 1); message = "NEW DRAWS: next seed. Kept copy unchanged."
	refresh(message)

func _input(event: InputEvent) -> void:
	# Children receive _input before the museum: consume pilot keys before its F6/F7.
	if event is InputEventKey and event.pressed and not event.echo:
		var index := [KEY_F1, KEY_F2, KEY_F3, KEY_F4, KEY_F5, KEY_F6, KEY_F7, KEY_F8].find(event.keycode)
		if index >= 0: activate(index); get_viewport().set_input_as_handled()

func point_action(action: String) -> void:
	if action != "trigger_click": return
	var p := to_local(point.global_position)
	for i in range(controls.size()):
		var target := Vector3((i % 4 - 1.5) * 0.30, 0.85 - (i / 4) * 0.13, 0.42)
		if absf(p.x - target.x) < 0.14 and absf(p.y - target.y) < 0.06 and absf(p.z - target.z) < 0.18:
			activate(i); return
```

## point_body.gd

<!-- student-code:point_body.gd -->
```gdscript
extends XRToolsPickable

const RADIUS := 0.14

func _init() -> void:
    freeze = true
    freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
    release_mode = XRToolsPickable.ReleaseMode.FROZEN
    ranged_grab_method = XRToolsPickable.RangedMethod.NONE
    collision_layer = 4
    collision_mask = 196615

    var surface := MeshInstance3D.new()
    var sphere := SphereMesh.new()
    sphere.radius = RADIUS
    sphere.height = RADIUS * 2.0
    surface.mesh = sphere
    add_child(surface)

    var boundary := CollisionShape3D.new()
    var shape := SphereShape3D.new()
    shape.radius = RADIUS
    boundary.shape = shape
    add_child(boundary)
```
