# Keep the values; change their spatial assignment

This continues Random Definition's seed lesson. The question is no longer whether a random number can make a picture. What changes when the same retained values become colour, height, size or orientation? Predict which relationships will survive a change of assignment. An unhelpful, confusing or visually dull comparison is a result too.

The user asked to see flat colour, bars and their combination at once, then clarified that random values should control object scaling and rotation. All five views now appear together. The 48 values are sixteen ordered triples, not one scalar per cell. Colour uses the three channels directly. The spatial views use their mean `u = (a+b+c)/3`. This distinction matters: the mean discards channel order, so differently coloured triples can produce the same height, scale and turn.

Run `python doc/book/experiments/random-definition/seed-bench-001/launch.py` from the repository. It opens a separate instance of the existing museum beside the study. The original hall instrument stays nearby. The launcher uses desktop mode; physical headset usability remains a separate test. For an XR encounter, mount the same scene in the museum at hall-local `(10.5,0,18.5)`, Y rotation `-90` degrees and unit scale. The printed scripts use the supplied XRTools hand/ray controls and the shared `push_button_front.tscn` from the interactable demo.

The back row shows FLAT, BARS and COMBO. The front row shows SCALE and ROTATE. Each contains the same sixteen cells in the same row-major order, `i = 4*row + column`. Corresponding cells share their input triple. Different viewing positions are not identical retinal conditions; move around the apparatus as well as comparing it from the initial viewpoint.

| View | Assignment | What stays fixed |
| --- | --- | --- |
| FLAT | RGB = `(a,b,c)` | Block height 4 cm |
| BARS | Neutral colour; length `0.04 + 0.12*u` metres | Width/depth 9 cm; bottom 8 cm above tray |
| COMBO | Same RGB as FLAT and same geometry as BARS | All sampled values |
| SCALE | Neutral cube side `0.09*(0.35+0.65*u)` metres | Cell centre XZ and bottom |
| ROTATE | Neutral rectangular piece, yaw `360*u` degrees | Dimensions 9 x 4 x 4 cm; centre and bottom |

The turn marker identifies one end. Rotation is periodic: zero and a full turn look identical. The long rectangular footprint makes rotation visible and fits within its cell at every angle. Its widest rotated extent is less than the 10.5 cm pitch. In SCALE, all three dimensions shrink together; the cube is between 35% and 100% of its 9 cm reference size. These two panels use different fixed shapes to make their respective changes visible; comparing them does not isolate one geometric variable.

For the bar views, set both `mesh.size.y = h` and `centre.y = 0.08 + h/2`. The bottom stays fixed while the top rises. FLAT/BARS/COMBO retain 1.5 cm gutters and fill the dark inset. Each now has a 54 cm outer frame and 46 cm dark inset, making the border broader and more visible. Scale and rotation change the apparent gaps as part of the experiment.

Work through invented black, white, red and green triples before looking at the seed: their means are `0`, `1`, `1/3`, `1/3`. Bar lengths are 4, 16, 8 and 8 cm. Scale factors are `0.35`, `1`, about `0.567`, `0.567`; turns are 0, 360, 120 and 120 degrees. These are arithmetic examples, not the first draws of seed 42. What can height tell you about colour, and what has it lost?

All controls remain on one rectangular-button board. Hand press or controller ray activates a cap. CLOSE hides the board without clearing a result; CONTROLS reopens it. The actions are RESET 42 (F1), CURRENT VIEWS (F2), KEEP (F3), REPLAY (F4), EXPORT (F5), IMPORT (F6), CLEAR KEPT (F7) and NEXT SEED (F8). RESET 42 deliberately regenerates that deterministic baseline. CURRENT VIEWS reuses stored values and explicitly forks an earlier saved recipe into this five-view version. The views themselves are simultaneous, not toggles.

Use the research cycle:

1. Record seed 42, the current recipe and a prediction about one corresponding cell across the five views.
2. Compare FLAT/COMBO to examine added height; compare BARS/COMBO to examine added colour. Describe what the other two assignments make visible or obscure.
3. KEEP, then EXPORT. NEXT SEED makes new seeded draws. REPLAY must return to the stored values and recipe.
4. CLEAR KEPT, then IMPORT. Close and reopen the study and import again. The file is `seed-bench-001.json` in Godot's user data folder, available through **Project → Open User Data Folder** in the editor.
5. Reconstruct the three printed scripts in a separate folder. Explain the mean, fixed bottom and scale/turn formulas; record what code you borrowed or needed help with.
6. Let an observation choose the next change. For example, propose a first-channel assignment only if it helps investigate what the mean obscures. Preserve the recipe before revising it. Return the account independently to both tutorial and final; either can initiate the next experiment.

Schema v3 records the five-view recipe and its parameters. Older v1 floating cubes and v2 bar layouts still import and render with their original cell geometry. CURRENT VIEWS forks them with a parent ID, preserving their values and the kept original. Earlier source versions and outcomes remain recoverable.

KEEP makes a deep copy. Import validates the complete record before changing state. Seed and generator state remain decimal strings; exact float bytes are authoritative because decimal JSON parsing shifted some values in the first run. An invalid import leaves current and kept results intact. Replay never resumes an RNG. Another seeded acquisition is deterministic; neither replay nor NEXT SEED establishes genuinely unpredictable randomness. See [observations](observations.md) and Godot's [RNG](https://docs.godotengine.org/en/4.6/classes/class_randomnumbergenerator.html) and [JSON](https://docs.godotengine.org/en/4.6/classes/class_json.html) documentation.

The complete files below are extracted and executed by the scripted reconstruction check. That verifies printed code, not a person's understanding. Keep human reconstruction, physical VR and performance evidence separate.


## seed_record.gd

<!-- student-code:seed_record.gd -->
```gdscript
extends RefCounted
## Local pilot format. Stored draws are authoritative; replay never resumes an RNG.
const SCHEMA := "ada.seed-bench.v3"
const MAX_BYTES := 65536
const MAPPINGS := ["space-assignments.v1"]
const V2_MAPPINGS := ["rgb-fixed.v2", "rgb-mean-bar.v1"]
const LEGACY_MAPPINGS := ["rgb-fixed.v1", "rgb-mean-height.v1"]
const V2_PARAMETERS := {"grid": [4, 4], "spacing_m": 0.105, "cube_side_m": 0.04,
	"cell_width_m": 0.09, "bottom_m": 0.08, "height_span_m": 0.12}
const PARAMETERS := {"grid": [4, 4], "spacing_m": 0.105, "cube_side_m": 0.04,
	"cell_width_m": 0.09, "bottom_m": 0.08, "height_span_m": 0.12,
	"scale_min": 0.35, "scale_span": 0.65, "turn_degrees": 360.0,
	"turn_depth_m": 0.04, "frame_width_m": 0.54, "panel_layout": "five-trays.v1"}
const ASSIGNMENTS := ["flat", "bars", "combo", "scale", "turn"]
const COMPACT_BAR_PARAMETERS := {"grid": [4, 4], "spacing_m": 0.055, "cube_side_m": 0.04,
	"bottom_m": 0.08, "height_span_m": 0.12}
const LEGACY_PARAMETERS := {"grid": [4, 4], "spacing_m": 0.1, "cube_side_m": 0.04,
	"base_centre_height_m": 0.1, "height_span_m": 0.3}
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
		"parameters": PARAMETERS.duplicate(true),
		"mapping_version": MAPPINGS[0],
		"host_transform": {"hall": "Random_Definition", "position_m": [10.5, 0, 18.5],
			"rotation_y_degrees": -90, "scale": [1, 1, 1], "tray_y_m": 1.0},
		"ordered_interventions": [], "observation": "", "next_change": ""
	}

func encode_values(values: Array) -> String:
	var bytes := PackedByteArray(); bytes.resize(values.size() * 8)
	for i in range(values.size()): bytes.encode_double(i * 8, values[i])
	return bytes.hex_encode()

func use_current_recipe() -> bool:
	if current.is_empty(): return false
	if current.schema != SCHEMA:
		# Explicit control use forks a saved earlier layout; replay never upgrades it.
		current.parent_id = current.id
		serial += 1
		current.id = "%s/spatial-%s" % [current.id, serial]
		current.schema = SCHEMA
		current.parameters = PARAMETERS.duplicate(true)
		current.mapping_version = MAPPINGS[0]
		current.ordered_interventions = []
	return true

func cells(record: Dictionary, fixed: bool = false, assignment: String = "combo") -> Array:
	var result: Array = []
	var p: Dictionary = record.parameters
	var width: float = p.get("cell_width_m", p.cube_side_m)
	for i in range(16):
		var a: float = record.raw_values[i * 3]
		var b: float = record.raw_values[i * 3 + 1]
		var c: float = record.raw_values[i * 3 + 2]
		var mean_value := (a + b + c) / 3.0
		var size := Vector3(width, p.cube_side_m, width)
		var colour := Color(a, b, c)
		var yaw := 0.0
		var y: float
		if record.schema == "ada.seed-bench.v1":
			y = p.base_centre_height_m
			if not fixed and record.mapping_version == LEGACY_MAPPINGS[1]: y += p.height_span_m * mean_value
		else:
			if record.schema == "ada.seed-bench.v2":
				if not fixed and record.mapping_version == V2_MAPPINGS[1]: size.y += p.height_span_m * mean_value
			else:
				var mode := "flat" if fixed else assignment
				if mode in ["bars", "combo"]: size.y += p.height_span_m * mean_value
				if mode in ["bars", "scale", "turn"]: colour = Color(0.78, 0.81, 0.83)
				if mode == "scale": size = Vector3.ONE * width * (p.scale_min + p.scale_span * mean_value)
				if mode == "turn":
					size.z = p.turn_depth_m
					yaw = deg_to_rad(p.turn_degrees * mean_value)
			y = p.bottom_m + size.y / 2.0
		result.append({"position": Vector3((i % 4 - 1.5) * p.spacing_m, y, (i / 4 - 1.5) * p.spacing_m),
			"size": size, "rotation_y": yaw, "colour": colour, "mean": mean_value})
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
	if value.schema not in [SCHEMA, "ada.seed-bench.v2", "ada.seed-bench.v1"]: return "Unsupported version"
	var mappings: Array = MAPPINGS if value.schema == SCHEMA else (V2_MAPPINGS if value.schema == "ada.seed-bench.v2" else LEGACY_MAPPINGS)
	if not value.mapping_version in mappings: return "Unsupported version"
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
	var parameters: Dictionary = PARAMETERS if value.schema == SCHEMA else (V2_PARAMETERS if value.schema == "ada.seed-bench.v2" else LEGACY_PARAMETERS)
	var known_compact_bars: bool = value.schema == "ada.seed-bench.v2" and same_contract(value.parameters, COMPACT_BAR_PARAMETERS)
	if not same_contract(value.parameters, parameters) and not known_compact_bars: return "Unsupported geometry parameters"
	var host := {"hall": "Random_Definition", "position_m": [10.5, 0, 18.5], "rotation_y_degrees": -90, "scale": [1, 1, 1], "tray_y_m": 1.0}
	if not same_contract(value.host_transform, host): return "Unsupported host transform"
	if not value.ordered_interventions is Array or value.ordered_interventions.size() > 256: return "Invalid intervention history"
	var previous: String = mappings[0]
	for step in value.ordered_interventions:
		if not step is Dictionary or step.size() != 2 or not step.has_all(["from", "to"]): return "Invalid intervention"
		if step.from != previous or not step.to in mappings or step.from == step.to: return "Broken mapping lineage"
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
## Simultaneous assignments of one retained set; saved earlier layouts still replay.
const Record = preload("seed_record.gd")
const Board = preload("seed_board.gd")
const CAPTIONS := ["FLAT / RGB", "BARS / MEAN", "COMBO / RGB + MEAN", "SCALE / MEAN", "ROTATE / MEAN"]
const OFFSETS := [Vector3(-0.64,1,-0.40), Vector3(0,1,-0.40), Vector3(0.64,1,-0.40), Vector3(-0.32,1,0.38), Vector3(0.32,1,0.38)]
var model = Record.new()
var cubes: Array = []
var board: Node3D
var display_root: Node3D
var display_recipe := ""
var export_path := "user://seed-bench-001.json"

func label_at(words: String, pos: Vector3, size: int = 30, owner_node: Node = null) -> Label3D:
	var label := Label3D.new()
	label.text = words; label.position = pos; label.font_size = size
	label.pixel_size = 0.001; label.no_depth_test = false
	if owner_node == null: owner_node = self
	owner_node.add_child(label)
	return label

func _ready() -> void:
	model.acquire()
	label_at("48 VALUES / FIVE SPATIAL ASSIGNMENTS", Vector3(0,1.78,-0.78), 38)
	label_at("Same triples in every tray.  u = (r + g + b) / 3", Vector3(0,1.69,-0.78), 23)
	board = Board.new(); board.name = "SeedControlBoard"
	board.position = Vector3(0,1.0,1.12); board.rotation_degrees.x = -25
	add_child(board); board.action_requested.connect(activate)
	refresh("Colour uses RGB; height, size and turn use their mean. KEEP a result.")

func box_at(parent: Node3D, size: Vector3, pos: Vector3, colour: Color) -> MeshInstance3D:
	var box := MeshInstance3D.new(); var mesh := BoxMesh.new(); mesh.size = size
	box.mesh = mesh; box.position = pos
	var material := StandardMaterial3D.new(); material.albedo_color = colour
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	box.material_override = material; parent.add_child(box)
	return box

func build_views() -> void:
	if display_root != null:
		remove_child(display_root); display_root.queue_free()
	display_root = Node3D.new(); add_child(display_root); cubes.clear()
	display_recipe = model.current.schema
	var current_recipe: bool = display_recipe == model.SCHEMA
	for panel in range(5 if current_recipe else 2):
		var tray := Node3D.new()
		tray.position = OFFSETS[panel] if current_recipe else Vector3(-0.32 if panel == 0 else 0.32,1,0)
		display_root.add_child(tray)
		box_at(tray, Vector3(0.54,0.03,0.54), Vector3.ZERO, Color(0.55,0.38,0.20))
		box_at(tray, Vector3(0.46,0.008,0.46), Vector3(0,0.019,0), Color(0.025,0.035,0.045))
		var caption: String = CAPTIONS[panel] if current_recipe else ("SAVED / REFERENCE" if panel == 0 else "SAVED / ORIGINAL MAPPING")
		label_at(caption, tray.position + Vector3(0,0.02,0.31), 20, display_root)
		var panel_cubes: Array = []
		for i in range(16):
			var cube := box_at(tray, Vector3.ONE * 0.04, Vector3.ZERO, Color.WHITE)
			var marker := box_at(cube, Vector3(0.014,0.002,0.022), Vector3(0.03,0.022,0), Color(0.9,0.3,0.07))
			marker.name = "DirectionMark"; marker.visible = current_recipe and panel == 4
			panel_cubes.append(cube)
		cubes.append(panel_cubes)

func refresh(message: String = "") -> void:
	if display_recipe != model.current.schema: build_views()
	var current_recipe: bool = model.current.schema == model.SCHEMA
	for panel in range(cubes.size()):
		var mode: String = model.ASSIGNMENTS[panel] if current_recipe else "combo"
		var data: Array = model.cells(model.current, not current_recipe and panel == 0, mode)
		for i in range(16):
			cubes[panel][i].position = data[i].position
			cubes[panel][i].mesh.size = data[i].size
			cubes[panel][i].rotation.y = data[i].rotation_y
			cubes[panel][i].material_override.albedo_color = data[i].colour
	board.set_reading(model.current.seed, "FIVE VIEWS" if current_recipe else "SAVED LAYOUT", not model.kept.is_empty(), message)

func activate(index: int) -> void:
	var message := ""
	match index:
		0: model.acquire(42); message = "Seed 42 regenerated. Kept copy unchanged."
		1: model.use_current_recipe(); message = "Same stored values, five views. Earlier kept copy unchanged."
		2: model.keep_result(); message = "Independent copy kept. Export to keep it after closing."
		3: message = "Replayed stored values and recipe." if model.replay() else "No kept result. Use KEEP first."
		4: message = "Exported seed-bench-001.json to user data." if model.export_record(export_path) else model.error
		5: message = "Imported original recipe. CURRENT VIEWS forks it." if model.import_record(export_path) else model.error
		6: model.clear_kept(); message = "Memory copy cleared; exported file remains."
		7: model.acquire(model.current.seed.to_int() + 1); message = "NEW DRAWS: next seed. Kept copy unchanged."
	refresh(message)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var index := [KEY_F1,KEY_F2,KEY_F3,KEY_F4,KEY_F5,KEY_F6,KEY_F7,KEY_F8].find(event.keycode)
		if index >= 0:
			board.set_open(true); activate(index); get_viewport().set_input_as_handled()
```

## seed_board.gd

<!-- student-code:seed_board.gd -->
```gdscript
extends Node3D
## One compact board using the shared demo's XR hand/pointer button mechanism.
signal action_requested(index: int)
const PushButton = preload("res://commons/interactables/push_button_front.tscn")
const BakedText = preload("res://commons/utils/baked_text_albedo.gd")
const ValueSurface = preload("res://commons/ui/control_value_surface.gd")
const NAMES := ["RESET 42", "CURRENT VIEWS", "KEEP", "REPLAY", "EXPORT", "IMPORT", "CLEAR KEPT", "NEXT SEED"]
var face: Node3D
var buttons: Array[Node3D] = []
var close_button: Node3D
var reopen_button: Node3D
var display: Dictionary
var is_open := true

func _ready() -> void:
	face = Node3D.new(); face.name = "BoardFace"; add_child(face)
	var backing := MeshInstance3D.new(); backing.name = "Backing"
	var box := BoxMesh.new(); box.size = Vector3(0.88, 0.46, 0.035)
	backing.mesh = box; backing.position.z = -0.025
	var material := StandardMaterial3D.new(); material.albedo_color = Color(0.81, 0.80, 0.76)
	material.roughness = 0.85; backing.material_override = material; face.add_child(backing)
	var heading := BakedText.make_label_mesh("SEED BENCH / 48 VALUES", Color(0.09,0.10,0.11), Vector2(0.55,0.04), 1800, true)
	heading.position = Vector3(-0.10,0.175,-0.006); face.add_child(heading)
	for i in range(8):
		var button := make_button(NAMES[i], Vector2(0.175,0.065))
		button.name = "Action_%s" % i
		button.position = Vector3((i % 4 - 1.5) * 0.20, 0.065 - (i / 4) * 0.10, 0)
		face.add_child(button); buttons.append(button)
		button.pressed.connect(func():
			if is_open: action_requested.emit(i))
	close_button = make_button("CLOSE", Vector2(0.12,0.05))
	close_button.name = "Close"; close_button.position = Vector3(0.33,0.175,0)
	face.add_child(close_button); close_button.pressed.connect(func(): set_open(false))
	reopen_button = make_button("CONTROLS", Vector2(0.20,0.065))
	reopen_button.name = "Reopen"; reopen_button.position = Vector3(0.28,0.175,0)
	add_child(reopen_button); reopen_button.pressed.connect(func(): set_open(true))
	display = ValueSurface.build(face, Vector2(0.79,0.09), Vector3(0,-0.155,-0.005))
	display.viewport.size = Vector2i(1000,140)
	display.viewport.get_child(0).size = Vector2(1000,140)
	display.label.size = Vector2(1000,140)
	display.label.add_theme_font_size_override("font_size", 30)
	display.label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	set_open(true)

func make_button(words: String, size: Vector2) -> Node3D:
	# Replace cap, body collider AND touch target before entering the tree.
	# Do not nonuniformly scale physics controls or keep a round collision target.
	var button: Node3D = PushButton.instantiate()
	button.transform = Transform3D.IDENTITY
	button.released_color = Color(0.18,0.21,0.23)
	button.selected_color = Color(0.10,0.55,0.44)
	button.pressed_color = Color(0.88,0.42,0.12)
	button.released_emission_energy = 0.02; button.pressed_emission_energy = 0.15
	var base: StaticBody3D = button.get_node("ButtonBase")
	base.transform = Transform3D.IDENTITY; base.position.z = -0.003
	var base_mesh := BoxMesh.new(); base_mesh.size = Vector3(size.x+0.012,size.y+0.012,0.012)
	base.get_node("BaseMesh").mesh = base_mesh
	var cap: StaticBody3D = button.get_node("Button")
	cap.transform = Transform3D.IDENTITY; cap.position.z = 0.015; cap.collision_layer = 0
	var cap_mesh := BoxMesh.new(); cap_mesh.size = Vector3(size.x,size.y,0.018)
	cap.get_node("ButtonMesh").mesh = cap_mesh
	var cap_shape := BoxShape3D.new(); cap_shape.size = cap_mesh.size
	cap.get_node("CollisionShape3D").shape = cap_shape
	var area: Area3D = button.get_node("InteractableAreaButton")
	area.transform = Transform3D.IDENTITY; area.displacement = Vector3(0,0,-0.009)
	var touch := BoxShape3D.new(); touch.size = Vector3(size.x+0.008,size.y+0.008,0.045)
	area.get_node("CollisionShape3D").shape = touch
	area.get_node("CollisionShape3D").position = Vector3(0,0,0.025)
	var pose: Area3D = button.get_node("HandPoseArea")
	pose.transform = Transform3D.IDENTITY
	var pose_shape := BoxShape3D.new(); pose_shape.size = Vector3(size.x+0.02,size.y+0.02,0.07)
	pose.get_node("CollisionShape3D").shape = pose_shape
	pose.get_node("CollisionShape3D").position = Vector3(0,0,0.025)
	var ink := BakedText.make_label_mesh(words, Color(0.96,0.96,0.91), size-Vector2(0.014,0.014), 2000, true)
	ink.name = "Caption"; ink.position.z = 0.010; cap.add_child(ink)
	return button

func enable_button(button: Node3D, enabled: bool) -> void:
	button.visible = enabled
	var area: Area3D = button.get_node("InteractableAreaButton")
	# Clear pointer ownership when closing while a controller is still pressed.
	for pointer in area._pointers.keys(): area._release_pointer(pointer)
	for item in area._trigger_items.keys(): area._on_button_exited(item)
	area.set_deferred("collision_layer", 1048576 if enabled else 0)
	area.set_deferred("collision_mask", 393216 if enabled else 0)
	area.get_node("CollisionShape3D").set_deferred("disabled", not enabled)
	button.get_node("HandPoseArea/CollisionShape3D").set_deferred("disabled", not enabled)

func set_open(value: bool) -> void:
	is_open = value; face.visible = value
	for button in buttons: enable_button(button, value)
	enable_button(close_button, value); enable_button(reopen_button, not value)

func set_reading(seed_text: String, mapping: String, kept: bool, message: String) -> void:
	display.label.text = "SEED %s   /   %s   /   %s\n%s" % [seed_text, mapping,
		"KEPT" if kept else "NO KEPT COPY", message]
	display.viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	buttons[0].set_selected(false)
	buttons[1].set_selected(mapping == "FIVE VIEWS")
```
