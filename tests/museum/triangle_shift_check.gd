extends Node3D
## Real drawing scene, XRTools pickup/release and pointer buttons; supplied hand
## positions are deterministic. Inspect emitted geometry, not a copied fan algorithm.
const DRAW_SCENE := preload("res://commons/primitives/point/draw_triangle_faces.tscn")
const L := [Vector2(0, 0), Vector2(1.2, 0), Vector2(1.2, 0.4),
	Vector2(0.4, 0.4), Vector2(0.4, 1.2), Vector2(0, 1.2)]

class TestHand extends Node3D:
	var picked_up_ranged: bool = false

var subject: Node3D
var handle: Node3D
var tip: Node3D
var panel: Node3D
var hand: TestHand
var checks: int = 0
var failures: Array[String] = []
var evidence: Dictionary = {}

func _ready() -> void:
	run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)
	print("[triangle-shift] ", "PASS " if ok else "FAIL ", label)

func state() -> Dictionary:
	return subject.call("get_experiment_state")

func press(path: String) -> void:
	var area: Node3D = subject.get_node(path + "/InteractableAreaButton")
	XRToolsPointerEvent.pressed(hand, area, area.global_position)
	XRToolsPointerEvent.released(hand, area, area.global_position)

func sample(at: Vector3) -> void:
	# Move the actual pickable so its tip lands at the supplied hand position.
	handle.global_position += at - tip.global_position
	subject.call("_process", float(subject.get("hold_place_seconds")) + 0.01)

func release_pen() -> void:
	handle.call("let_go", hand, Vector3.ZERO, Vector3.ZERO)

func draw_loop(points: Array, start: int = 0, offset: Vector3 = Vector3.ZERO) -> void:
	handle.call("pick_up", hand)
	for step in range(points.size() + 1):
		var p: Vector2 = points[(start + step) % points.size()]
		sample(Vector3(p.x, 1.2, p.y) + offset)
	release_pen()
	panel.call("update_readout")

func vertices(loop_index: int) -> PackedVector3Array:
	var face: Dictionary = subject.get("completed_triangles")[loop_index]
	return face.mesh.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]

func edge_set() -> Array[String]:
	var mesh: ImmediateMesh = subject.get("line_mesh")
	var data: PackedVector3Array = mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var edges: Array[String] = []
	for i in range(0, data.size(), 2):
		var ends: Array[String] = [str(data[i]), str(data[i + 1])]
		ends.sort()
		edges.append("/".join(ends))
	edges.sort()
	return edges

func measure(data: PackedVector3Array) -> Dictionary:
	var area := 0.0
	var outside := 0
	# Six emitted vertices = one logical triangle plus its reverse winding.
	for i in range(0, data.size(), 6):
		var a := Vector2(data[i].x, data[i].z)
		var b := Vector2(data[i + 1].x, data[i + 1].z)
		var c := Vector2(data[i + 2].x, data[i + 2].z)
		area += absf((b - a).cross(c - a)) * 0.5
		var center := (a + b + c) / 3.0
		outside += int(center.x > 0.40001 and center.y > 0.40001)
	return {"sum_triangle_area_m2": area, "centroids_in_excluded_notch": outside,
		"logical_triangles": data.size() / 6}

func run() -> void:
	hand = TestHand.new()
	add_child(hand)
	subject = DRAW_SCENE.instantiate()
	subject.set_meta("config_discovery", "1")
	add_child(subject)
	subject.set_process(false)
	handle = subject.get_node("GrabPoint")
	handle.set("freeze", true)
	handle.set("alter_freeze", false)
	tip = subject.get_node("GrabPoint/DrawSphere")
	panel = subject.get_node("ExperimentPanel")
	panel.set_process(false)
	await get_tree().process_frame
	await get_tree().process_frame
	check(subject.has_method("shift_start") and subject.has_method("get_experiment_state"), "Production scene exposes the controlled comparison")
	if not subject.has_method("shift_start") or not subject.has_method("get_experiment_state"):
		finish()
		return
	check(not state().shift_start_ready and state().selected_loop_index == -1, "Empty scene has no selected fan")
	check(not str(state().shift_start_reason).is_empty(), "Unavailable control explains what is missing")
	press("ExperimentPanel/ShiftStartButton")
	check(subject.get("completed_triangles").is_empty(), "Pressing SHIFT START before drawing creates nothing")
	draw_loop(L)
	check(state().points == 6 and state().filled_loops == 1, "Timed hand path closes the six-corner L once")
	check(state().shift_start_ready and not state().partial_outline, "Release at a completed loop's continuation anchor permits shifting")
	check(state().selected_start_index == 0 and state().logical_triangles == 4, "A is the initial start and one L submits four triangles")
	var original_points: Array = subject.get("placed_points").duplicate()
	var original_edges := edge_set()
	var first_vertices := vertices(0)
	var first_measure := measure(first_vertices)
	evidence["start_A"] = first_measure
	check(is_equal_approx(first_measure.sum_triangle_area_m2, 0.8) and first_measure.centroids_in_excluded_notch == 0, "Start A fits the 0.8 square metre L")
	var face: Dictionary = subject.get("completed_triangles")[0]
	var mesh_node: MeshInstance3D = face.mesh
	var material: Material = mesh_node.material_override
	press("ExperimentPanel/ShiftStartButton")
	check(state().selected_start_index == 1, "Real pointer button advances start A to B")
	check(subject.get("placed_points") == original_points, "SHIFT START does not move or reindex any corner")
	check(edge_set() == original_edges, "SHIFT START preserves all boundary edges")
	check(state().filled_loops == 1 and state().logical_triangles == 4, "Replacement does not accumulate loops or triangles")
	check(subject.get("completed_triangles")[0].mesh == mesh_node and mesh_node.material_override == material, "Replacement preserves the mesh node and material")
	var second_measure := measure(vertices(0))
	evidence["start_B"] = second_measure
	check(is_equal_approx(second_measure.sum_triangle_area_m2, 1.44) and second_measure.centroids_in_excluded_notch == 2, "Start B overspills the notch in the actual emitted mesh")
	var corners: Array = subject.get("point_indicators")
	check(str(corners[1].get_node("CornerNumber").text).contains("START"), "Start marker moves to B")
	check(not str(corners[0].get_node("CornerNumber").text).contains("START"), "Previous closed-loop anchor has no misleading start marker")
	for i in range(5):
		check(bool(subject.call("shift_start")), "Remaining cyclic shift %d succeeds" % (i + 1))
	check(state().selected_start_index == 0 and vertices(0) == first_vertices, "Six shifts restore the original emitted fan exactly")
	check(subject.get("placed_points") == original_points and edge_set() == original_edges, "Full cycle preserves exact points and edges")
	var public_state := state()
	public_state.selected_loop_points.clear()
	check(state().selected_loop_points.size() == 6, "Inspection state cannot mutate stored indices")
	press("ExperimentPanel/FillButton")
	check(not mesh_node.visible and not state().fills_visible, "SHOW/HIDE FILL hides the mesh")
	press("ExperimentPanel/ShiftStartButton")
	check(not mesh_node.visible and edge_set() == original_edges, "Hidden fill remains hidden while its start changes")
	press("ExperimentPanel/FillButton")
	check(mesh_node.visible and state().fills_visible, "Fill can be shown after shifting")
	press("NewOutlineButton")
	check(state().path_entries == 0 and state().filled_loops == 1, "NEW OUTLINE preserves the completed fan")
	check(state().shift_start_ready, "NEW OUTLINE alone does not disable a completed fan")
	draw_loop(L, 1)
	check(state().points == 6 and state().filled_loops == 2 and state().logical_triangles == 8, "Manual retracing still reuses corners and adds a second four-triangle loop")
	check(state().selected_loop_index == 1 and state().selected_start_index == 1, "Most recently completed loop becomes selected")
	var earlier_vertices := vertices(0)
	var earlier_indices: Array = subject.get("completed_triangles")[0].points.duplicate()
	press("ExperimentPanel/ShiftStartButton")
	check(vertices(0) == earlier_vertices and subject.get("completed_triangles")[0].points == earlier_indices, "Shifting latest loop leaves earlier fan unchanged")
	check(state().selected_start_index == 2 and state().logical_triangles == 8, "Latest loop shifts independently without changing totals")
	var indices_before: Array = state().selected_loop_points.duplicate()
	handle.call("pick_up", hand)
	check(not state().shift_start_ready and str(state().shift_start_reason).contains("pen"), "Held pen disables shifting with an explanation")
	press("ExperimentPanel/ShiftStartButton")
	check(state().selected_loop_points == indices_before, "Pointer button cannot shift while the pen is held")
	# NEW OUTLINE resets logical sampling; the physical pickable remains held.
	press("NewOutlineButton")
	check(not state().shift_start_ready, "NEW OUTLINE cannot bypass a physically held pen")
	release_pen()
	check(state().shift_start_ready, "Releasing after NEW OUTLINE restores availability")
	var corner: Node3D = corners[2]
	corner.call("pick_up", hand)
	check(not state().shift_start_ready and str(state().shift_start_reason).contains("corner"), "Held editable corner also blocks shifting")
	check(not bool(subject.call("shift_start")), "Direct request cannot bypass held-corner guard")
	corner.global_position += Vector3(0, 0.2, 0)
	corner.call("let_go", hand, Vector3.ZERO, Vector3.ZERO)
	check(state().shift_start_ready and is_equal_approx(subject.get("placed_points")[2].y, 1.4), "Corner release retains free editing and restores shifting")
	check(vertices(0) != earlier_vertices, "Moving a shared corner rebuilds earlier faces too")
	handle.call("pick_up", hand)
	sample(Vector3(3, 1.2, 3))
	release_pen()
	check(state().partial_outline and not state().shift_start_ready, "One fresh corner is an unfinished outline, unlike closure's continuation anchor")
	panel.call("update_readout")
	var drawing_marker: Label3D = subject.get("point_indicators")[-1].get_node("CornerNumber")
	check(drawing_marker.text.contains("DRAW START"), "Unfinished outline has a distinct DRAW START marker")
	check(str(panel.get_node("Readout").text).contains("Close this outline"), "Panel explains unfinished-outline restriction")
	check(not bool(subject.call("shift_start")) and state().selected_loop_points == indices_before, "Unfinished outline cannot change the last fan")
	press("NewOutlineButton")
	check(state().shift_start_ready and state().filled_loops == 2, "Clearing unfinished path preserves both completed loops")
	# Verify the operation works on other loop lengths, not only the chosen L.
	var shapes := [
		[Vector2(0,0), Vector2(1,0), Vector2(0,1)],
		[Vector2(0,0), Vector2(1,0), Vector2(1,1), Vector2(0,1)],
		[Vector2(0,0), Vector2(1,0), Vector2(1.2,0.6), Vector2(0.5,1.2), Vector2(-0.2,0.6)]
	]
	for shape: Array in shapes:
		press("NewOutlineButton")
		draw_loop(shape, 0, Vector3(float(shape.size()) * 3, 0, 0))
		var index: int = state().selected_loop_index
		var saved := vertices(index)
		var totals: int = state().logical_triangles
		check(saved.size() == (shape.size() - 2) * 6, "%d-corner shape emits expected logical triangles" % shape.size())
		var all_shifted := true
		for i in range(shape.size()):
			all_shifted = bool(subject.call("shift_start")) and all_shifted
		check(all_shifted and vertices(index) == saved and state().logical_triangles == totals, "%d-corner full cycle preserves its fan and counts" % shape.size())
	subject.call("clear_all")
	panel.call("update_readout")
	check(state().points == 0 and state().filled_loops == 0 and state().logical_triangles == 0, "Clear resets points, loops and counts")
	check(state().selected_loop_index == -1 and not bool(subject.call("shift_start")), "Clear removes the selected fan and disables shifting")
	check(str(panel.get_node("Readout").text).contains("No closed loop selected"), "Cleared readout does not retain a stale selection")
	draw_loop(shapes[0])
	check(state().selected_start_index == 0 and state().logical_triangles == 1 and state().shift_start_ready, "Free drawing works again after clear")
	# The same panel serves the preceding boundary puzzle; it gets no new control.
	var puzzle: Node3D = load("res://commons/primitives/line/puzzles/triangle_line_puzzle.tscn").instantiate()
	puzzle.set_meta("config_discovery", "1")
	add_child(puzzle)
	puzzle.set_process(false)
	# Base scene yields once per line; don't remove it during deferred setup.
	for frame in range(8):
		await get_tree().process_frame
	check(puzzle.get("snap_lines").size() == 3, "Boundary puzzle finishes building all three lines")
	var puzzle_panel: Node3D = puzzle.get_node("ExperimentPanel")
	check(not puzzle_panel.has_node("ShiftStartButton"), "Shared panel adds SHIFT START only to the drawing artifact")
	check(str(puzzle_panel.get_node("Readout").text).contains("BOUNDARY / FACE"), "Boundary puzzle retains its own readout")
	var fill_area: Node3D = puzzle_panel.get_node("FillButton/InteractableAreaButton")
	XRToolsPointerEvent.pressed(hand, fill_area, fill_area.global_position)
	XRToolsPointerEvent.released(hand, fill_area, fill_area.global_position)
	check(not is_instance_valid(puzzle.get("discovery_face")), "Boundary puzzle still waits for closure before adding fill")
	puzzle.free()
	finish()

func finish() -> void:
	var report_path := "res://ada_run/triangle_shift_checks.json"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--report="): report_path = arg.substr(9)
	var report := {"checks": checks, "failures": failures, "evidence": evidence,
		"scope": "Real scene and pointer/pickup methods with supplied hand positions; no headset trial. Triangle area sums include overlaps, not union area."}
	var file := FileAccess.open(report_path, FileAccess.WRITE)
	if file == null:
		push_error("Cannot write triangle report: " + report_path)
		get_tree().quit(2)
		return
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	subject.free()
	hand.free()
	get_tree().quit(0 if failures.is_empty() else 1)
