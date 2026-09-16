extends SceneTree
## probe_ten_print_structure — ten_print as the INTERFACE, ten_print_structure as the room.
##
##   godot --path . --xr-mode off --script res://commons/testing/probe_ten_print_structure.gd
##   (NO --headless: the dummy renderer keeps no MultiMesh data, so every slab reads back as
##   identity and the readbacks collapse to one cell; found 2026-09-17)
##
## WHAT IS READ BACK, said before any result. The structure's slabs are read out of its
## MultiMesh (instance transform -> cell and diagonal), never out of its own cell array. The
## screen's field is ten_print.get_field(), which reads the live CSG lines; it is itself
## checked against the pinned stream (coin_is_forward) so neither side is only trusted.
## read_slabs() goes through slabs_node(), which applies a pending reload first; the storm
## section (5b) reads the MultiMesh straight from a held reference instead, so the deferred
## reload is shown to run by itself at the end of the frame, not because a reader asked.
##
## WHICH PRESS PATH: DesktopInteractionPointer's own RayCast3D, _resolve_pointer_target and
## _input, as probe_wall_drawing_291 does it. The eye stands 0.45 m out along the button's own
## normal. THIS PROBE NEVER EMITS button_pressed: emissions are COUNTED per area. OS -> viewport
## dispatch and a VR hand are not exercised. One call in 5b goes to press_control() directly,
## to observe the room in the same instant as the press; the pointer path is proved elsewhere.
##
## What it asserts:
##   1. a default ten_print (no config) has no console, both stubs visible, no group, and no
##      MeshInstance3D anywhere (the DNA framing depends on that);
##   2. #controls:panel#channel:probe at the hall's placement (lift 1.5, scale 0.1875): stubs
##      hidden, six press areas 6-9 cm across at 0.95-1.25 m, the console in metres beside the
##      field, the status screen facing +Z, and the console re-fits when the scale changes;
##   3. a linked structure equals get_field() cell for cell and diagonal for diagonal after
##      stepping, and the marker stands on get_next_cell();
##   4. STEP, RUN, BIAS -, BIAS +, SEMICOLON and RESEED pressed through the pointer: each fires
##      once and does what it says; SEMICOLON resets both and the room follows the column; the
##      status screen shows words and no count;
##   5. when_full scroll and clear stay in sync; the live tick stays in sync; RUN stops it;
##  5b. the hall's own token (seed 1982, count 400, scroll): one SEMICOLON press scrolls 380
##      times inside one call and the room pays ONE reload for it (instance writes counted),
##      deferred to the end of the frame;
##   6. a second pair on another channel does not cross-link; a same-channel screen in ANOTHER
##      hall is not found, including the museum's own boundary (Seg* names, em_map meta) under
##      a node that is not current_scene, with a control that does link; a structure that
##      arrives before its screen links on retry; a screen that changes its channel is let go
##      and taken back;
##   7. a structure with no channel prints the standalone field, and that field equals what a
##      ten_print with the same seed/count/scroll prints (two implementations, one rule), at
##      400, 437 and 1013 characters;
##   8. forms (heights, the floor ridge capped at half a cell, the marker's height), solid
##      on/off, config lanes (strings before the tree, words, refused bools);
##   9. bias words and refusals on the screen, and the pinned stream under a fixed bias.
## Exit code 1 on any failed check, 2 on timeout.

const IFACE_SCENE := "res://algorithms/randomness/ten_print/ten_print.tscn"
const STRUCT_SCENE := "res://commons/artifacts/ten_print_structure/ten_print_structure.tscn"
const POINTER := "res://commons/scenes/DesktopInteractionPointer.gd"
const GRID_COMPONENT := "res://commons/grid/GridInteractablesComponent.gd"
const TAG := "[ten-print-structure] "
const GROUP := "ten_print_interface"
const TIMEOUT_S := 300.0
const EYE_BACK := 0.45
const HALL_LIFT := 1.5
const HALL_SCALE := 0.1875
const KEYS := ["step", "run", "semicolon", "bias_minus", "bias_plus", "reseed"]

var checks := 0
var failures: Array[String] = []
var emits: Dictionary = {}          # area instance id -> button_pressed count
var signal_counts: Dictionary = {}  # name -> count
var world: Node3D
var _done := false


func _initialize() -> void:
	create_timer(TIMEOUT_S).timeout.connect(_on_timeout)
	run.call_deferred()


func _on_timeout() -> void:
	if _done:
		return
	_done = true
	print(TAG, "FAIL probe timed out after %d s: run() stopped before it finished" % int(TIMEOUT_S))
	print(TAG, "RESULT: FAIL (timeout)")
	quit(2)


func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
	print(TAG, "PASS " if ok else "FAIL ", message)


func _count_emit(key: int) -> void:
	emits[key] = int(emits.get(key, 0)) + 1


func _emits_of(area: Object) -> int:
	if area == null:
		return 0
	return int(emits.get(area.get_instance_id(), 0))


func _count_signal(name: String) -> void:
	signal_counts[name] = int(signal_counts.get(name, 0)) + 1


func _frames(n: int) -> void:
	for i in range(n):
		await process_frame
	await physics_frame
	await physics_frame


func hall(name: String, x: float) -> Node3D:
	var h := Node3D.new()
	h.name = name
	h.position = Vector3(x, 0.0, 0.0)
	world.add_child(h)
	return h


## A hall inside a container, as the museum stands its segments side by side.
func sub_hall(parent: Node3D, name: String, z: float, em_map: String = "") -> Node3D:
	var h := Node3D.new()
	h.name = name
	h.position = Vector3(0.0, 0.0, z)
	if em_map != "":
		h.set_meta("em_map", em_map)
	parent.add_child(h)
	return h


## A screen at the 10 PRINT hall's placement. `props` through set() before the tree,
## `config` through apply_grid_config after _ready (the grid's lane) unless before_tree.
func make_screen(parent: Node3D, props: Dictionary, config: Dictionary = {}, before_tree: bool = false) -> Node3D:
	var packed: PackedScene = load(IFACE_SCENE)
	var inst: Node3D = packed.instantiate() as Node3D
	for k in props.keys():
		inst.set(k, props[k])
	inst.position = Vector3(0.0, HALL_LIFT, 0.0)
	inst.scale = Vector3.ONE * HALL_SCALE
	if before_tree and not config.is_empty():
		inst.call("apply_grid_config", config)
	parent.add_child(inst)
	inst.set_process(false)
	if not before_tree and not config.is_empty():
		inst.call("apply_grid_config", config)
	return inst


func make_structure(parent: Node3D, props: Dictionary, config: Dictionary = {}, before_tree: bool = false,
		pos: Vector3 = Vector3(3.0, 0.0, 1.0)) -> Node3D:
	var packed: PackedScene = load(STRUCT_SCENE)
	var inst: Node3D = packed.instantiate() as Node3D
	for k in props.keys():
		inst.set(k, props[k])
	inst.position = pos
	if before_tree and not config.is_empty():
		inst.call("apply_grid_config", config)
	parent.add_child(inst)
	if not before_tree and not config.is_empty():
		inst.call("apply_grid_config", config)
	return inst


func draw_to(screen: Node, n: int) -> void:
	var guard: int = n * 3 + 50
	while int(screen.get("draw_count")) < n and guard > 0:
		screen.call("generate_maze_step")
		guard -= 1


## A MultiMesh read as a field: Vector2i(col, row) -> forward. A collapsed basis is an empty
## cell. Yaw -45 degrees sends the slab's +X toward +Z (from the cell's far-left corner to its
## near-right corner): that is the forward flag.
func read_multimesh(mm: MultiMesh, sz: float) -> Dictionary:
	var out: Dictionary = {}
	if mm == null:
		return out
	for i in range(mm.instance_count):
		var xf: Transform3D = mm.get_instance_transform(i)
		var bx: Vector3 = xf.basis.x
		if bx.length() < 0.001:
			continue
		out[Vector2i(floori(xf.origin.x / sz), floori(xf.origin.z / sz))] = bx.z > 0.0
	return out


## The structure's slabs, through slabs_node() (which applies a pending reload first).
func read_slabs(st: Node) -> Dictionary:
	var mmi: MultiMeshInstance3D = st.call("slabs_node") as MultiMeshInstance3D
	if mmi == null:
		return {}
	return read_multimesh(mmi.multimesh, float(st.get("size")))


## "" when equal, otherwise the first difference.
func diff_fields(a: Dictionary, b: Dictionary) -> String:
	if a.size() != b.size():
		return "sizes %d vs %d" % [a.size(), b.size()]
	for key in a.keys():
		if not b.has(key):
			return "%s missing" % str(key)
		if bool(a[key]) != bool(b[key]):
			return "%s: %s vs %s" % [str(key), str(a[key]), str(b[key])]
	return ""


func field_of(screen: Node) -> Dictionary:
	var f: Dictionary = screen.call("get_field")
	return f


func all_in_column_zero(field: Dictionary) -> bool:
	for key in field.keys():
		var k: Vector2i = key
		if k.x != 0:
			return false
	return true


func count_mesh_instances(n: Node) -> int:
	return n.find_children("*", "MeshInstance3D", true, false).size()


func body_of(ts: Node) -> String:
	return str(ts.get("body")) if ts != null else ""


func marker_of(st: Node) -> MeshInstance3D:
	return st.call("marker_node") as MeshInstance3D


func run() -> void:
	world = Node3D.new()
	world.name = "World"
	root.add_child(world)
	current_scene = world
	print(TAG, "PRESS PATH: DesktopInteractionPointer's own RayCast3D + _resolve_pointer_target + _input -> XRToolsPointerEvent -> InteractableAreaButton.button_pressed. The probe never emits button_pressed.")

	# ── 0. the config keys ────────────────────────────────────────────────────────
	var gic: String = FileAccess.get_file_as_string(GRID_COMPONENT)
	var list_at: int = gic.find("const CONFIG_PARAM_NAMES")
	var list_end: int = gic.find("\n]", list_at) if list_at != -1 else -1
	var names_block: String = gic.substr(list_at, list_end - list_at) if list_at != -1 and list_end != -1 else ""
	var listed_ok := true
	for key in ["cols", "rows", "size", "seed", "count"]:
		if names_block.find("\"%s\"" % key) == -1:
			listed_ok = false
	check(listed_ok, "cols, rows, size, seed and count are listed in CONFIG_PARAM_NAMES (they arrive as values)")
	for key in ["form", "solid", "channel", "controls", "bias"]:
		print(TAG, "info: `%s` listed in CONFIG_PARAM_NAMES: %s (the artifacts take WORDS for it either way)" % [key, names_block.find("\"%s\"" % key) != -1])

	# ── 1. the default screen is the screen it was ────────────────────────────────
	var h0: Node3D = hall("HallDefault", -60.0)
	var plain: Node3D = make_screen(h0, {})
	await _frames(2)
	var stubs_visible: bool = true
	for stub_name in ["ProbabilityControl", "GenerationSpeed"]:
		var stub: Node3D = plain.get_node_or_null(NodePath(str(stub_name))) as Node3D
		if stub == null or not stub.visible:
			stubs_visible = false
	check(plain.find_child("InterfaceConsole", false, false) == null and plain.call("console_node") == null,
		"default ten_print: no console")
	check(stubs_visible, "default ten_print: both placeholder stubs visible")
	check(not plain.is_in_group(GROUP) and not get_nodes_in_group(GROUP).has(plain), "default ten_print: not in group %s" % GROUP)
	check(count_mesh_instances(plain) == 0, "default ten_print: no MeshInstance3D in its subtree (%d); the DNA framing reads the 1 m fallback box" % count_mesh_instances(plain))
	var st0: Dictionary = plain.call("get_state")
	check(str(st0["controls"]) == "none" and str(st0["channel"]) == "" and is_equal_approx(float(st0["bias"]), -1.0) and bool(st0["running"]),
		"default ten_print: controls none, channel \"\", bias -1 (breathing), running (%s)" % str(st0))

	# ── 2. the interface at the hall's placement ──────────────────────────────────
	var ha: Node3D = hall("HallA", 0.0)
	var screen_a: Node3D = make_screen(ha, {"seed": 41}, {"controls": "panel", "channel": "probe"})
	await _frames(4)
	var console: Node3D = screen_a.call("console_node") as Node3D
	check(console != null, "#controls:panel after _ready (grid lane) builds the console")
	check(screen_a.is_in_group(GROUP), "#channel:probe joins group %s" % GROUP)
	var hidden_ok := true
	for stub_name in ["ProbabilityControl", "GenerationSpeed"]:
		var stub2: Node3D = screen_a.get_node_or_null(NodePath(str(stub_name))) as Node3D
		if stub2 == null or stub2.visible:
			hidden_ok = false
	check(hidden_ok, "controls panel: both placeholder stubs hidden")
	if console == null:
		_finish()
		return
	var cs_scale: Vector3 = console.global_transform.basis.get_scale()
	check(absf(cs_scale.x - 1.0) < 0.001 and absf(cs_scale.y - 1.0) < 0.001,
		"the console holder is in metres at the hall's scale 0.1875 (global scale %s)" % str(cs_scale))
	var areas: Dictionary = {}
	var area_report: Array[String] = []
	for key in KEYS:
		var area: Area3D = screen_a.call("console_button_area", key) as Area3D
		areas[key] = area
		if area == null:
			area_report.append("%s: none" % key)
			continue
		var acs: CollisionShape3D = area.get_node_or_null("CollisionShape3D") as CollisionShape3D
		var cyl: CylinderShape3D = acs.shape as CylinderShape3D if acs != null else null
		var dia: float = (cyl.radius * 2.0 * acs.global_transform.basis.get_scale().x) if cyl != null else 0.0
		var y: float = acs.global_position.y if acs != null else -1.0
		if dia < 0.06 or dia > 0.09 or y < 0.95 or y > 1.25:
			area_report.append("%s: %.3f m across at y %.3f" % [key, dia, y])
		print(TAG, "info: %s press area %.3f m across, centre y %.3f m, x %.3f m" % [key, dia, y, acs.global_position.x if acs != null else 0.0])
		area.connect("button_pressed", func(_b): _count_emit(area.get_instance_id()))
	check(area_report.is_empty(), "six press areas, each 6-9 cm across, at 0.95-1.25 m above the floor (%s)" % str(area_report))
	var field_right: float = screen_a.global_position.x + 3.8 * HALL_SCALE
	var console_min_x: float = INF
	for node in console.find_children("*", "MeshInstance3D", true, false):
		var mi: MeshInstance3D = node as MeshInstance3D
		if mi.mesh == null:
			continue
		var box: AABB = mi.global_transform * mi.get_aabb()
		console_min_x = minf(console_min_x, box.position.x)
	check(console_min_x > field_right + 0.03, "the console stands clear of the field's right edge (console from x %.3f, field edge %.3f)" % [console_min_x, field_right])
	var status: Node3D = screen_a.call("status_screen") as Node3D
	check(status != null and status.global_transform.basis.z.normalized().dot(Vector3(0, 0, 1)) > 0.999,
		"the status screen faces +Z, as the field does")
	check(status != null and str(status.get("title")) == "10 PRINT CHR$(205.5+RND(1)); : GOTO 10",
		"the status screen shows the one-liner (%s)" % (str(status.get("title")) if status != null else "none"))
	# re-fit on a scale change (NOTIFICATION_TRANSFORM_CHANGED is flushed on the next frame)
	screen_a.scale = Vector3.ONE * 0.25
	await _frames(2)
	var cs_scale2: Vector3 = console.global_transform.basis.get_scale()
	check(absf(cs_scale2.x - 1.0) < 0.001, "the console re-fits when the screen is rescaled to 0.25 (global scale %s)" % str(cs_scale2))
	screen_a.scale = Vector3.ONE * HALL_SCALE
	await _frames(2)

	# ── 3. a linked structure follows the stream ──────────────────────────────────
	screen_a.connect("field_reset", func(): _count_signal("reset_a"))
	screen_a.connect("field_scrolled", func(): _count_signal("scroll_a"))
	var room_a: Node3D = make_structure(ha, {}, {"channel": "probe"})
	await _frames(3)
	check(str(room_a.call("link_state")) == "linked" and room_a.call("linked_interface") == screen_a,
		"the structure with #channel:probe links to the screen in its own hall (%s)" % str(room_a.call("link_state")))
	check(body_of(room_a.call("plate_node")).find("printed by the screen with channel probe") != -1,
		"the plate says \"printed by the screen with channel probe\"")
	check(read_slabs(room_a).is_empty(), "linked to an empty screen, the room is empty (not the standalone field)")
	draw_to(screen_a, 137)
	var field_a: Dictionary = screen_a.call("get_field")
	var stream_ok := field_a.size() == 137
	for i in range(137):
		var k := Vector2i(i % 20, i / 20)
		if not field_a.has(k) or bool(field_a[k]) != bool(screen_a.call("coin_is_forward", i)):
			stream_ok = false
			break
	check(stream_ok, "get_field() after 137 steps is the pinned stream, character i at (i % 20, i / 20)")
	var d137: String = diff_fields(read_slabs(room_a), field_a)
	check(d137 == "", "after 137 steps the room's slabs equal get_field() cell for cell and diagonal for diagonal (%s)" % d137)
	var marker: MeshInstance3D = marker_of(room_a)
	var nc: Vector2i = screen_a.call("get_next_cell")
	check(nc == Vector2i(17, 6) and marker != null and marker.visible
		and absf(marker.position.x - 17.5 * 0.5) < 0.001 and absf(marker.position.z - 6.5 * 0.5) < 0.001,
		"the marker stands on the next cell (17, 6) (next %s, marker %s)" % [str(nc), str(marker.position) if marker != null else "none"])
	# the mapping: forward runs from the far-left corner to the near-right corner
	var mm: MultiMesh = (room_a.call("slabs_node") as MultiMeshInstance3D).multimesh
	var map_ok := true
	var seen_f := false
	var seen_b := false
	for i in range(137):
		var xf: Transform3D = mm.get_instance_transform(i)
		var half: Vector3 = xf.basis.x * float(room_a.call("slab_length")) * 0.5
		var e1: Vector3 = xf.origin - half
		var e2: Vector3 = xf.origin + half
		var near_end: Vector3 = e1 if e1.z > e2.z else e2
		var far_end: Vector3 = e2 if e1.z > e2.z else e1
		var fwd: bool = bool(field_a[Vector2i(i % 20, i / 20)])
		if fwd:
			seen_f = true
			if not (far_end.x < near_end.x):
				map_ok = false
		else:
			seen_b = true
			if not (far_end.x > near_end.x):
				map_ok = false
		var c0: Vector2 = Vector2(float(i % 20) * 0.5, float(i / 20) * 0.5)
		if absf(minf(e1.x, e2.x) - c0.x) > 0.04 or absf(minf(e1.z, e2.z) - c0.y) > 0.04:
			map_ok = false
	check(map_ok and seen_f and seen_b, "forward slabs run far-left -> near-right, backward near-left -> far-right, corner to corner of their own cell")

	# ── 4. the console, pressed through the pointer ───────────────────────────────
	var head := Node3D.new()
	head.name = "Head"
	world.add_child(head)
	var cam := Camera3D.new()
	cam.name = "Camera3D"
	head.add_child(cam)
	var pointer_script: GDScript = load(POINTER)
	var ptr: Node3D = pointer_script.new() as Node3D
	ptr.name = "DesktopInteractionPointer"
	head.add_child(ptr)
	await _frames(2)
	check(ptr.get("_raycast") != null, "the desktop pointer built its RayCast3D")

	var rec: Dictionary = await _pointer_press(ptr, head, areas["step"])
	check(bool(rec["hover_is_expected"]) and int(rec["emits"]) == 1, "STEP: the ray named its area and it fired once (hover %s, emits %d)" % [rec["hover"], rec["emits"]])
	check(int(screen_a.get("draw_count")) == 138 and diff_fields(read_slabs(room_a), screen_a.call("get_field")) == "",
		"STEP printed one character and the room has it (draw_count %d)" % int(screen_a.get("draw_count")))

	rec = await _pointer_press(ptr, head, areas["run"])
	check(bool(rec["hover_is_expected"]) and int(rec["emits"]) == 1 and not bool(screen_a.call("get_state")["running"]),
		"RUN: fired once and the live tick is off (hover %s)" % rec["hover"])
	var body_now: String = body_of(status)
	check(body_now.find("stopped") != -1 and body_now.find("running") == -1 and body_now.find("138") == -1,
		"the status screen says \"stopped\" and shows no count, so no texture per value is baked (%s)" % body_now.replace("\n", " | "))
	check(str(screen_a.call("status_line")) == "semicolon on · bias breathing · 138 printed · stopped",
		"status_line() keeps the exact count: %s" % str(screen_a.call("status_line")))

	rec = await _pointer_press(ptr, head, areas["bias_plus"])
	check(bool(rec["hover_is_expected"]) and int(rec["emits"]) == 1 and is_equal_approx(float(screen_a.get("bias")), 0.6),
		"BIAS +: fired once, bias breathing -> 0.6 (%s)" % str(screen_a.get("bias")))
	check(str(status.get("title")).find("205.4") != -1 and body_of(status).find("bias 0.6") != -1,
		"the one-liner reads CHR$(205.4+RND(1)) and the status \"bias 0.6\" (%s)" % str(status.get("title")))
	check(int(screen_a.get("draw_count")) == 138, "a BIAS press does not restart the stream")
	rec = await _pointer_press(ptr, head, areas["bias_minus"])
	check(bool(rec["hover_is_expected"]) and int(rec["emits"]) == 1 and is_equal_approx(float(screen_a.get("bias")), 0.5),
		"BIAS -: fired once, 0.6 -> 0.5 (%s)" % str(screen_a.get("bias")))

	var resets_before: int = int(signal_counts.get("reset_a", 0))
	rec = await _pointer_press(ptr, head, areas["semicolon"])
	check(bool(rec["hover_is_expected"]) and int(rec["emits"]) == 1 and str(screen_a.get("semicolon")) == "off",
		"SEMICOLON: fired once, semicolon on -> off (hover %s)" % rec["hover"])
	check(int(signal_counts.get("reset_a", 0)) > resets_before and int(screen_a.get("draw_count")) == 0
		and field_of(screen_a).is_empty() and read_slabs(room_a).is_empty(),
		"SEMICOLON reset both: the screen is empty, field_reset fired, the room is empty")
	check(str(status.get("title")) == "10 PRINT CHR$(205.5+RND(1)) : GOTO 10", "the one-liner lost its semicolon (%s)" % str(status.get("title")))
	draw_to(screen_a, 25)
	var col_field: Dictionary = screen_a.call("get_field")
	var col_slabs: Dictionary = read_slabs(room_a)
	check(col_field.size() == 5 and all_in_column_zero(col_field) and all_in_column_zero(col_slabs) and diff_fields(col_slabs, col_field) == "",
		"no semicolon, 25 characters (one wipe): the room follows the column, 5 slabs in column 0 equal to the screen (%s)" % diff_fields(col_slabs, col_field))

	rec = await _pointer_press(ptr, head, areas["reseed"])
	check(bool(rec["hover_is_expected"]) and int(rec["emits"]) == 1 and int(screen_a.get("seed")) == 42 and int(screen_a.get("draw_count")) == 0
		and read_slabs(room_a).is_empty(),
		"RESEED: fired once, seed 41 -> 42, the stream restarted and the room emptied")
	rec = await _pointer_press(ptr, head, areas["semicolon"])
	check(str(screen_a.get("semicolon")) == "on" and int(rec["emits"]) == 1, "SEMICOLON again: back on")
	var total_emits: int = 0
	for key in KEYS:
		total_emits += _emits_of(areas[key])
	check(total_emits == 7, "7 presses, 7 emissions across the six areas (%d)" % total_emits)

	# ── 5. scroll, wipe and the live tick stay in sync ────────────────────────────
	screen_a.call("apply_grid_config", {"when_full": "scroll", "seed": "41"})
	draw_to(screen_a, 437)
	var scroll_field: Dictionary = screen_a.call("get_field")
	check(scroll_field.size() == 397 and int(signal_counts.get("scroll_a", 0)) >= 2,
		"when_full scroll, 437 characters: 397 on screen after two scrolls (%d, scrolls %d)" % [scroll_field.size(), int(signal_counts.get("scroll_a", 0))])
	var ds: String = diff_fields(read_slabs(room_a), scroll_field)
	check(ds == "", "after the scrolls the room equals the screen (%s)" % ds)
	marker = marker_of(room_a)
	check(marker.visible and screen_a.call("get_next_cell") == Vector2i(17, 19)
		and absf(marker.position.z - 19.5 * 0.5) < 0.001, "the marker follows the cursor to the bottom row (17, 19)")
	screen_a.call("apply_grid_config", {"when_full": "clear"})
	draw_to(screen_a, 400)
	screen_a.call("generate_maze_step")     # the wipe tick
	check(field_of(screen_a).is_empty() and read_slabs(room_a).is_empty(), "when_full clear: the wipe empties the screen and the room")
	marker = marker_of(room_a)
	check(marker.visible and absf(marker.position.x - 0.25) < 0.001 and absf(marker.position.z - 0.25) < 0.001, "after the wipe the marker is home at (0, 0)")
	# the live tick: RUN is off, so _process prints nothing
	var n_before: int = int(screen_a.get("draw_count"))
	screen_a.set_process(true)
	await _frames(20)
	check(int(screen_a.get("draw_count")) == n_before, "RUN off: 20 live frames print nothing (%d -> %d)" % [n_before, int(screen_a.get("draw_count"))])
	# start the breath near its fast phase (speed 1 + 2 sin(0.8) = 2.4, a tick every 0.08 s)
	screen_a.set("time", 4.0)
	rec = await _pointer_press(ptr, head, areas["run"])
	check(bool(screen_a.call("get_state")["running"]) and int(rec["emits"]) == 1, "RUN pressed again: the live tick is on")
	var deadline: int = Time.get_ticks_msec() + 6000
	while int(screen_a.get("draw_count")) < n_before + 10 and Time.get_ticks_msec() < deadline:
		await process_frame
	screen_a.set_process(false)
	var dl: String = diff_fields(read_slabs(room_a), screen_a.call("get_field"))
	check(int(screen_a.get("draw_count")) >= n_before + 10 and dl == "",
		"the live tick printed %d characters and the room kept up (%s)" % [int(screen_a.get("draw_count")) - n_before, dl])

	# ── 5b. the hall's own token: one press, 380 scrolls, one reload ──────────────
	var hs: Node3D = hall("HallStorm", 360.0)
	var screen_s: Node3D = make_screen(hs, {"seed": 1982, "count": 400, "when_full": "scroll"}, {"controls": "panel", "channel": "storm"})
	var room_s: Node3D = make_structure(hs, {}, {"channel": "storm"})
	await _frames(4)
	check(room_s.call("linked_interface") == screen_s and read_slabs(room_s).size() == 400,
		"the hall's token pair (seed 1982, count 400, scroll, panel, one channel): linked, 400 slabs")
	screen_s.connect("field_scrolled", func(): _count_signal("scroll_s"))
	var mm_s: MultiMesh = (room_s.call("slabs_node") as MultiMeshInstance3D).multimesh
	var sz_s: float = float(room_s.get("size"))
	var writes0: int = int(room_s.call("instance_writes"))
	var semi_s: Area3D = screen_s.call("console_button_area", "semicolon") as Area3D
	if semi_s != null:
		semi_s.connect("button_pressed", func(_b): _count_emit(semi_s.get_instance_id()))
	rec = await _pointer_press(ptr, head, semi_s)
	await _frames(1)
	var storm_scrolls: int = int(signal_counts.get("scroll_s", 0))
	var storm_writes: int = int(room_s.call("instance_writes")) - writes0
	check(int(rec["emits"]) == 1 and str(screen_s.get("semicolon")) == "off" and storm_scrolls >= 300,
		"premise: SEMICOLON through the pointer on that screen reprints 400 characters unwrapped and scrolls %d times inside one call" % storm_scrolls)
	check(storm_writes <= 420,
		"the room paid one reload for the whole storm: %d instance writes (a rewrite per scroll would be %d)" % [storm_writes, storm_scrolls * 400])
	var mm_read: Dictionary = read_multimesh(mm_s, sz_s)
	var dstorm: String = diff_fields(mm_read, screen_s.call("get_field"))
	check(dstorm == "" and mm_read.size() == 20 and all_in_column_zero(mm_read),
		"a frame later, read straight from the MultiMesh (no readback flush), the room is the screen's column of 20 (%s)" % dstorm)
	var writes1: int = int(room_s.call("instance_writes"))
	screen_s.call("press_control", "semicolon")
	var stale: Dictionary = read_multimesh(mm_s, sz_s)
	check(str(screen_s.get("semicolon")) == "on" and bool(room_s.call("reload_pending"))
		and int(room_s.call("instance_writes")) == writes1 and stale.size() == 20,
		"inside the press nothing is written: the reload is pending and the MultiMesh still shows the column (%d slabs)" % stale.size())
	await _frames(1)
	var settled: Dictionary = read_multimesh(mm_s, sz_s)
	var dset: String = diff_fields(settled, screen_s.call("get_field"))
	check(not bool(room_s.call("reload_pending")) and settled.size() == 400 and dset == ""
		and (room_s.call("slabs_node") as MultiMeshInstance3D).multimesh == mm_s,
		"at the end of the frame the deferred reload ran by itself: 400 slabs equal to the screen, same MultiMesh (%s)" % dset)

	# ── 6. scope: channels, halls, late arrival ───────────────────────────────────
	var hb: Node3D = hall("HallB", 40.0)
	var screen_b: Node3D = make_screen(hb, {"seed": 7, "count": 60}, {"channel": "other"})
	var room_b: Node3D = make_structure(hb, {}, {"channel": "other"})
	await _frames(3)
	check(room_b.call("linked_interface") == screen_b and room_a.call("linked_interface") == screen_a,
		"two pairs, two channels: each room is linked to its own screen")
	check(diff_fields(read_slabs(room_b), screen_b.call("get_field")) == "" and read_slabs(room_b).size() == 60,
		"room B equals screen B (60 characters)")
	var snap_b: Dictionary = read_slabs(room_b)
	var snap_a: Dictionary = read_slabs(room_a)
	draw_to(screen_a, int(screen_a.get("draw_count")) + 15)
	check(diff_fields(read_slabs(room_b), snap_b) == "", "15 characters on screen A do not reach room B")
	check(diff_fields(read_slabs(room_a), snap_a) != "", "premise: they did reach room A")
	draw_to(screen_b, 75)
	check(diff_fields(read_slabs(room_a), screen_a.call("get_field")) == "" and diff_fields(read_slabs(room_b), screen_b.call("get_field")) == "",
		"15 characters on screen B reach room B only; both rooms still equal their screens")

	var hc: Node3D = hall("HallC", 80.0)
	var _screen_c: Node3D = make_screen(hc, {"seed": 5, "count": 30}, {"channel": "probe"})
	var hd: Node3D = hall("HallD", 120.0)
	var room_d: Node3D = make_structure(hd, {}, {"channel": "probe"})
	# the museum's own boundary: segments are SIBLINGS under a node that is not current_scene,
	# so the scene-root rule never fires and only the hall rule (Seg* name / em_map meta) stops it
	var museum_seg: Node3D = hall("MuseumSeg", 400.0)
	var seg0: Node3D = sub_hall(museum_seg, "Seg0_a", 0.0)
	var seg1: Node3D = sub_hall(museum_seg, "Seg1_b", 30.0)
	var _screen_seg: Node3D = make_screen(seg0, {"seed": 2, "count": 20}, {"channel": "seg"})
	var room_seg: Node3D = make_structure(seg1, {}, {"channel": "seg"})
	var museum_map: Node3D = hall("MuseumMap", 440.0)
	var map_a: Node3D = sub_hall(museum_map, "MapHallA", 0.0, "Map_A")
	var map_b: Node3D = sub_hall(museum_map, "MapHallB", 30.0, "Map_B")
	var _screen_map: Node3D = make_screen(map_a, {"seed": 2, "count": 20}, {"channel": "emmap"})
	var room_map: Node3D = make_structure(map_b, {}, {"channel": "emmap"})
	var rooms_plain: Node3D = hall("RoomsPlain", 480.0)
	var room0: Node3D = sub_hall(rooms_plain, "Room0", 0.0)
	var room1: Node3D = sub_hall(rooms_plain, "Room1", 30.0)
	var screen_plain: Node3D = make_screen(room0, {"seed": 2, "count": 20}, {"channel": "plain"})
	var room_plain: Node3D = make_structure(room1, {}, {"channel": "plain"})
	await _frames(70)
	check(str(room_d.call("link_state")) == "standalone" and room_d.call("linked_interface") == null,
		"a room with #channel:probe in ANOTHER hall does not find the screens with channel probe (state %s)" % str(room_d.call("link_state")))
	check(body_of(room_d.call("plate_node")).find("standalone: no screen linked") != -1, "its plate says \"standalone: no screen linked\"")
	check(room_a.call("linked_interface") == screen_a, "room A is still linked to screen A, not to hall C's screen")
	check(room_seg.call("find_interface") == null and str(room_seg.call("link_state")) == "standalone",
		"museum segments: a room in Seg1_b does not find the same-channel screen in its sibling Seg0_a (state %s)" % str(room_seg.call("link_state")))
	check(room_map.call("find_interface") == null and str(room_map.call("link_state")) == "standalone",
		"em_map halls: a room in MapHallB (em_map meta, no Seg name) does not find the screen in MapHallA (state %s)" % str(room_map.call("link_state")))
	check(room_plain.call("linked_interface") == screen_plain,
		"control: the same two sibling halls with no Seg name and no em_map meta DO link, so the two checks above can fail (state %s)" % str(room_plain.call("link_state")))

	var hg: Node3D = hall("HallLate", 160.0)
	var room_g: Node3D = make_structure(hg, {}, {"channel": "late"})
	await _frames(3)
	check(str(room_g.call("link_state")) == "searching", "a room that arrives before its screen is searching (%s)" % str(room_g.call("link_state")))
	var screen_g: Node3D = make_screen(hg, {"seed": 3, "count": 45}, {"controls": "panel", "channel": "late"}, true)
	await _frames(4)
	check(room_g.call("linked_interface") == screen_g and diff_fields(read_slabs(room_g), screen_g.call("get_field")) == "",
		"the screen arrives three frames later (configured before the tree, as the museum does) and the room links on retry")
	var console_g: Node3D = screen_g.call("console_node") as Node3D
	check(console_g != null and absf(console_g.global_transform.basis.get_scale().x - 1.0) < 0.001,
		"config before the tree builds the console once, in metres")

	# past the retry window: the screen announces itself, the room re-runs its SCOPED search
	var hl: Node3D = hall("HallLater", 180.0)
	var room_l: Node3D = make_structure(hl, {}, {"channel": "later"})
	await _frames(70)
	check(str(room_l.call("link_state")) == "standalone", "no screen within the retry window: standalone (%s)" % str(room_l.call("link_state")))
	var screen_l: Node3D = make_screen(hl, {"seed": 9, "count": 33}, {"channel": "later"})
	await _frames(3)
	check(room_l.call("linked_interface") == screen_l and diff_fields(read_slabs(room_l), screen_l.call("get_field")) == ""
		and read_slabs(room_l).size() == 33,
		"a screen arriving after the retry window announces itself and the room links (33 slabs)")
	# a screen that leaves the channel is let go; back on the channel, it is taken again
	screen_l.call("apply_grid_config", {"channel": "elsewhere"})
	await _frames(3)
	check(room_l.call("linked_interface") == null and str(room_l.call("link_state")) == "searching",
		"the linked screen changes its channel to elsewhere: the room lets it go and searches (state %s)" % str(room_l.call("link_state")))
	screen_l.call("apply_grid_config", {"channel": "later"})
	await _frames(3)
	check(room_l.call("linked_interface") == screen_l and diff_fields(read_slabs(room_l), screen_l.call("get_field")) == "",
		"back on channel later, the room takes it again and equals it")
	var hc2: Node3D = hall("HallC2", 100.0)
	var _screen_c2: Node3D = make_screen(hc2, {"seed": 6, "count": 12}, {"channel": "probe"})
	await _frames(3)
	check(str(room_d.call("link_state")) == "standalone" and room_d.call("linked_interface") == null,
		"a same-channel screen announcing in ANOTHER hall is still not taken by room D (%s)" % str(room_d.call("link_state")))
	check(room_a.call("linked_interface") == screen_a, "and the announce does not move room A off its own screen")

	# ── 7. standalone: one rule in two implementations ────────────────────────────
	var he: Node3D = hall("HallE", 200.0)
	var room_e: Node3D = make_structure(he, {"seed": 41, "count": 400})
	var ref_400: Node3D = make_screen(he, {"seed": 41, "count": 400, "when_full": "scroll"})
	var room_e2: Node3D = make_structure(he, {"seed": 41, "count": 437}, {}, false, Vector3(20.0, 0.0, 1.0))
	var ref_437: Node3D = make_screen(he, {"seed": 41, "count": 437, "when_full": "scroll"})
	var room_e3: Node3D = make_structure(he, {"seed": 41, "count": 1013}, {}, false, Vector3(40.0, 0.0, 1.0))
	var ref_1013: Node3D = make_screen(he, {"seed": 41, "count": 1013, "when_full": "scroll"})
	await _frames(2)
	var slabs_e: Dictionary = read_slabs(room_e)
	var de: String = diff_fields(slabs_e, ref_400.call("get_field"))
	check(slabs_e.size() == 400 and de == "", "a room with no channel prints seed 41 x 400 as a ten_print with seed 41, count 400, scroll does (%s)" % de)
	var de2: String = diff_fields(read_slabs(room_e2), ref_437.call("get_field"))
	check(read_slabs(room_e2).size() == 397 and de2 == "", "and count 437 scrolls as the screen scrolls: 397 slabs, equal (%s)" % de2)
	var de3: String = diff_fields(read_slabs(room_e3), ref_1013.call("get_field"))
	check(read_slabs(room_e3).size() == 393 and de3 == "", "count 1013 (31 scrolls, laid from the closed form): 393 slabs, equal to the screen that stepped them (%s)" % de3)
	check(str(room_e.call("link_state")) == "standalone" and body_of(room_e.call("plate_node")).find("standalone: no screen linked") != -1,
		"its plate says \"standalone: no screen linked\"")
	var marker_e: MeshInstance3D = marker_of(room_e)
	check(marker_e != null and not marker_e.visible, "no screen, no next character: the marker is hidden")
	check(not ref_400.is_in_group(GROUP) and not plain.is_in_group(GROUP), "screens without a channel never joined the group")
	var plate_e: Node3D = room_e.call("plate_node") as Node3D
	check(plate_e != null and plate_e.global_transform.basis.z.normalized().dot(Vector3(0, 0, 1)) > 0.999
		and absf(room_e.to_local(plate_e.global_position).z - 10.6) < 0.001,
		"the plate stands 0.6 m beyond the near edge (z = rows x size) and faces +Z")

	# ── 8. forms, solid, config lanes ─────────────────────────────────────────────
	var hf: Node3D = hall("HallF", 240.0)
	# [slab height, slab centre y, anchor top, marker centre y] at the default 0.5 m cell
	var form_expect := {"floor": [0.25, 0.125, 0.25, 0.262], "wall": [2.4, 1.2, 2.4, 0.012], "overhead": [0.2, 3.0, 3.1, 2.88]}
	var fx: float = 0.0
	for form_name in ["floor", "wall", "overhead"]:
		var rf: Node3D = make_structure(hf, {"form": form_name, "seed": 41, "count": 400}, {}, false, Vector3(fx, 0.0, 0.0))
		fx += 15.0
		await _frames(1)
		var mmi: MultiMeshInstance3D = rf.call("slabs_node") as MultiMeshInstance3D
		var bm: BoxMesh = mmi.multimesh.mesh as BoxMesh
		var want: Array = form_expect[form_name]
		var y0: float = mmi.multimesh.get_instance_transform(0).origin.y
		var min_y: float = INF
		for node in rf.find_children("*", "MeshInstance3D", true, false):
			var mi2: MeshInstance3D = node as MeshInstance3D
			if mi2.mesh == null or mi2.is_queued_for_deletion():
				continue
			var ab: AABB = rf.global_transform.affine_inverse() * (mi2.global_transform * mi2.get_aabb())
			min_y = minf(min_y, ab.position.y)
		var anchor: MeshInstance3D = rf.find_child("CaptureAnchor", false, false) as MeshInstance3D
		check(bm != null and absf(bm.size.y - float(want[0])) < 0.001 and absf(y0 - float(want[1])) < 0.001,
			"form %s: slabs %.2f m tall centred at %.3f m (%s, %.3f)" % [form_name, float(want[0]), float(want[1]), str(bm.size) if bm != null else "none", y0])
		check(absf(min_y) < 0.002 and anchor != null and anchor.layers == 0
			and absf((anchor.mesh as BoxMesh).size.y - float(want[2])) < 0.001,
			"form %s: base at y 0 (%.4f), a layers-0 anchor %.2f m tall spans the field" % [form_name, min_y, float(want[2])])
		check(absf(float(rf.call("marker_y")) - float(want[3])) < 0.001,
			"form %s: the next-cell tile's centre at %.3f m (%.3f)" % [form_name, float(want[3]), float(rf.call("marker_y"))])
		check(rf.find_children("*", "CollisionShape3D", true, false).is_empty(), "form %s, solid off: no collider anywhere (a venue)" % form_name)
	var small: Node3D = make_structure(hf, {"size": 0.2, "seed": 41, "count": 400}, {}, false, Vector3(45.0, 0.0, 0.0))
	await _frames(1)
	var small_bm: BoxMesh = (small.call("slabs_node") as MultiMeshInstance3D).multimesh.mesh as BoxMesh
	check(small_bm != null and absf(small_bm.size.y - 0.1) < 0.001 and absf(float(small.call("marker_y")) - 0.112) < 0.001,
		"floor at #size:0.2: ridges capped at half a cell, 0.1 m, and the tile on their tops at 0.112 m (%s, %.3f)" % [
			str(small_bm.size) if small_bm != null else "none", float(small.call("marker_y"))])
	var solid_room: Node3D = make_structure(hf, {"solid": "on", "seed": 41, "count": 400}, {}, false, Vector3(60.0, 0.0, 0.0))
	await _frames(3)
	var shapes: Array = solid_room.find_children("*", "CollisionShape3D", true, false)
	var enabled: int = 0
	for s in shapes:
		if not (s as CollisionShape3D).disabled:
			enabled += 1
	check(shapes.size() == 400 and enabled == 400, "solid on: 400 box colliders, all enabled for a full field (%d shapes, %d enabled)" % [shapes.size(), enabled])

	var pre: Node3D = make_structure(hf, {}, {"form": "wall", "cols": "10", "rows": "8", "size": "1.0", "seed": "41", "count": "80"}, true, Vector3(80.0, 0.0, 0.0))
	await _frames(1)
	check(str(pre.get("form")) == "wall" and pre.call("get_dims") == Vector2i(10, 8) and is_equal_approx(float(pre.get("size")), 1.0)
		and read_slabs(pre).size() == 80,
		"config before the tree as token strings: wall, 10 x 8 at 1.0 m, 80 slabs (%s)" % str(pre.call("get_dims")))
	pre.call("apply_grid_config", {"form": true, "solid": true, "cols": true})
	check(str(pre.get("form")) == "wall" and str(pre.get("solid")) == "off" and int(pre.get("cols")) == 10,
		"bools (the shorthand misparse of #form:1, #solid:1, #cols without a listed value) are refused")
	pre.call("apply_grid_config", {"form": "overhead"})
	await _frames(1)
	var slab_nodes: int = 0
	for ch in pre.get_children():
		if ch is MultiMeshInstance3D and not ch.is_queued_for_deletion():
			slab_nodes += 1
	check(slab_nodes == 1 and str(pre.get("form")) == "overhead" and read_slabs(pre).size() == 80,
		"#form:overhead after _ready rebuilds once: one slab node, the same 80 slabs")

	# ── 9. bias on the screen ─────────────────────────────────────────────────────
	var hh: Node3D = hall("HallBias", 280.0)
	var sb: Node3D = make_screen(hh, {"seed": 41})
	sb.call("apply_grid_config", {"bias": "p30"})
	check(is_equal_approx(float(sb.get("bias")), 0.3), "#bias:p30 reads as 0.3")
	for bad in [true, 0.7, "0.7", "sideways"]:
		sb.call("apply_grid_config", {"bias": bad})
	check(is_equal_approx(float(sb.get("bias")), 0.3), "bias refuses a bool, a number, a numeric string and an unknown word")
	sb.call("apply_grid_config", {"bias": "breathing"})
	check(is_equal_approx(float(sb.get("bias")), -1.0), "#bias:breathing returns to the breathing threshold")
	sb.call("apply_grid_config", {"bias": "p30"})
	draw_to(sb, 300)
	var fresh: Node3D = make_screen(hh, {"seed": 41, "bias": 0.3})
	var pure_ok := true
	var fwd_count: int = 0
	var sbf: Dictionary = sb.call("get_field")
	for i in range(300):
		var want_f: bool = bool(fresh.call("coin_is_forward", i))
		if want_f:
			fwd_count += 1
		var kk := Vector2i(i % 20, i / 20)
		if not sbf.has(kk) or bool(sbf[kk]) != want_f:
			pure_ok = false
	check(pure_ok, "with seed 41 and bias 0.3, character i is a function of (seed, i, bias): a fresh instance predicts all 300")
	check(fwd_count > 60 and fwd_count < 120, "bias 0.3 leans the field: %d of 300 forward" % fwd_count)
	var control: Node3D = make_screen(hh, {"seed": 41})
	var differs := false
	for i in range(300):
		if bool(control.call("coin_is_forward", i)) != bool(fresh.call("coin_is_forward", i)):
			differs = true
			break
	check(differs, "the same seed at breathing prints a different stream (bias reaches the draw)")
	var sc: Node3D = make_screen(hh, {})
	sc.call("apply_grid_config", {"controls": true, "channel": true})
	check(str(sc.get("controls")) == "none" and str(sc.get("channel")) == "" and sc.call("console_node") == null and not sc.is_in_group(GROUP),
		"#controls and #channel refuse a bool (no console, no group)")

	# ── 9. the window and the plate (lead's addition, 2026-09-17) ─────────────────
	var hw: Node3D = hall("HallW", 320.0)
	var screen_w: Node3D = make_screen(hw, {"seed": 1982, "count": 400, "when_full": "scroll"}, {"channel": "band"})
	var room_w: Node3D = make_structure(hw, {"seed": 7, "count": 0}, {"channel": "band", "rows": 7, "plate": "none"}, false, Vector3(3.0, 0.0, 1.0))
	await _frames(3)
	var dims_w: Vector2i = room_w.call("get_dims")
	var off_w: int = int(room_w.call("row_offset"))
	check(str(room_w.call("link_state")) == "linked" and dims_w == Vector2i(20, 7) and off_w == 13,
		"rows 7 linked to a 20-row screen: the room is 20 x 7, a window onto rows 13..19 (dims %s, offset %d)" % [str(dims_w), off_w])
	var slabs_w: Dictionary = read_slabs(room_w)
	var fw: Dictionary = field_of(screen_w)
	var want_w: Dictionary = {}
	for key in fw.keys():
		var cw: Vector2i = key
		if cw.y >= 13:
			want_w[Vector2i(cw.x, cw.y - 13)] = fw[key]
	var dw: String = diff_fields(slabs_w, want_w)
	check(slabs_w.size() == 140 and dw == "", "its 140 slabs equal the screen's last seven rows shifted up by 13 (%s)" % dw)
	var nc_w: Vector2i = screen_w.call("get_next_cell")
	var marker_w: MeshInstance3D = marker_of(room_w)
	var mz: float = marker_w.position.z if marker_w != null else -1.0
	check(marker_w != null and marker_w.visible and nc_w.y == 19 and absf(mz - 3.25) < 0.001,
		"the marker for the screen's next cell on row 19 stands on the window's row 6 (z %.3f)" % mz)
	draw_to(screen_w, 401)
	await _frames(2)
	var slabs_w2: Dictionary = read_slabs(room_w)
	var fw2: Dictionary = field_of(screen_w)
	var want_w2: Dictionary = {}
	for key2 in fw2.keys():
		var cw2: Vector2i = key2
		if cw2.y >= 13:
			want_w2[Vector2i(cw2.x, cw2.y - 13)] = fw2[key2]
	var dw2: String = diff_fields(slabs_w2, want_w2)
	check(dw2 == "", "after one more character (a scroll at 400) the window still equals the screen's last seven rows (%s)" % dw2)
	check(room_w.call("plate_node") == null, "plate:none builds no plate")
	var room_p: Node3D = make_structure(hw, {"seed": 7, "count": 40}, {"plate": "left", "rows": 4, "cols": 6}, false, Vector3(30.0, 0.0, 1.0))
	await _frames(1)
	var plate_p: Node3D = room_p.call("plate_node") as Node3D
	var lp: Vector3 = room_p.to_local(plate_p.global_position) if plate_p != null else Vector3.ZERO
	var facing_x: float = plate_p.global_transform.basis.z.normalized().dot(Vector3(1, 0, 0)) if plate_p != null else 0.0
	check(plate_p != null and absf(lp.x + 0.6) < 0.001 and absf(lp.z - 1.0) < 0.001 and facing_x > 0.999,
		"plate:left stands 0.6 m off the left edge at mid-depth and faces +X into the field (x %.2f z %.2f)" % [lp.x, lp.z])

	_finish()


## Stand an eye EYE_BACK out along the button's own normal, look at its press shape, and click
## through the desktop pointer's own ray and input handler.
func _pointer_press(ptr: Node3D, head: Node3D, area: Area3D) -> Dictionary:
	if area == null:
		return {"hover_is_expected": false, "hover": "no area", "emits": 0}
	var acs: CollisionShape3D = area.get_node_or_null("CollisionShape3D") as CollisionShape3D
	var aim: Vector3 = acs.global_position if acs != null else area.global_position
	var normal: Vector3 = area.global_transform.basis.y.normalized()
	head.global_position = aim + normal * EYE_BACK
	head.look_at(aim, Vector3.UP)
	await physics_frame
	await physics_frame
	var ray: RayCast3D = ptr.get("_raycast") as RayCast3D
	if ray != null:
		ray.force_raycast_update()
	ptr.call("_process", 0.0)
	var hover: Variant = ptr.get("_last_target")
	var hover_node: Node = hover as Node if hover is Node else null
	var before: int = _emits_of(area)
	var down := InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	ptr.call("_input", down)
	await process_frame
	var up := InputEventMouseButton.new()
	up.button_index = MOUSE_BUTTON_LEFT
	up.pressed = false
	ptr.call("_input", up)
	await process_frame
	return {
		"hover_is_expected": hover_node == area,
		"hover": str(hover_node.get_parent().name) + "/" + str(hover_node.name) if hover_node != null and hover_node.get_parent() != null else "nothing",
		"emits": _emits_of(area) - before,
	}


func _finish() -> void:
	if _done:
		return
	_done = true
	print(TAG, "%d checks, %d failed" % [checks, failures.size()])
	for f in failures:
		print(TAG, "  FAILED: ", f)
	print(TAG, "RESULT: ", "PASS" if failures.is_empty() else "FAIL")
	quit(0 if failures.is_empty() else 1)
