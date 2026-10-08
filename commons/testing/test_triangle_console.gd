extends SceneTree
## Interface regression: production input callbacks and emitted triangle meshes.
var failures: Array[String] = []
var checks := 0
var pointer: Node3D
var tool: Node3D
var panel: Node3D

func _initialize() -> void: run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)
	print(("PASS " if ok else "FAIL ")+label)
func press(name: String) -> void:
	var area: Node3D = panel.get_node(name+"/InteractableAreaButton")
	XRToolsPointerEvent.pressed(pointer,area,area.global_position)
	XRToolsPointerEvent.released(pointer,area,area.global_position)
	panel.update_readout()
func mesh_area() -> float:
	var vertices: PackedVector3Array = tool.completed_triangles[-1].mesh.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var area := 0.0
	# The real artifact emits front and back for every logical triangle.
	for i in range(0,vertices.size(),6): area += (vertices[i+1]-vertices[i]).cross(vertices[i+2]-vertices[i]).length()*.5
	return area
func run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	pointer = Node3D.new()
	world.add_child(pointer)
	tool = load("res://commons/primitives/point/draw_triangle_faces.tscn").instantiate()
	tool.set_meta("config_discovery","1")
	tool.position = Vector3(7,1.4,6)
	tool.rotation_degrees.y = 90
	world.add_child(tool)
	tool.set_process(false)
	panel = tool.get_node("ExperimentPanel")
	panel.set_process(false)
	for i in 3: await process_frame
	press("FillButton")
	check(tool.fills_visible and tool.completed_triangles.is_empty(),"empty fill button cannot hide future faces")
	check(not panel.fill_button.play_press_sound,"unavailable fill action is quiet")
	press("ShiftStartButton")
	check(not panel._shift_ready and not panel.shift_button.play_press_sound,"empty shift action is unavailable and quiet")
	var boundary: Array[Vector2] = [Vector2(0,0),Vector2(1.2,0),Vector2(1.2,.4),Vector2(.4,.4),Vector2(.4,1.2),Vector2(0,1.2),Vector2(0,0)]
	var handle: Node3D = tool.get_node("GrabPoint")
	var tip: Node3D = tool.get("_draw_sphere")
	tool.call("_on_grab_point_picked_up",handle)
	for point in boundary:
		tip.global_position = Vector3(point.x+7,1.4,point.y+6)
		tool.call("_process",1.01)
	tool.call("_on_grab_point_dropped",handle)
	panel.update_readout()
	check(tool.completed_triangles.size()==1 and tool.placed_points.size()==6,"timed drawing makes one six-corner loop")
	check(panel._shift_ready and panel.shift_button.play_press_sound,"released closed loop enables shift")
	check(panel.fill_button.is_selected(),"visible fill has persistent selected feedback")
	var original: Array = tool.completed_triangles[-1].points.duplicate()
	var vertices: Array = tool.placed_points.duplicate()
	var good_area := mesh_area()
	check(is_equal_approx(good_area,.8),"original fan fills the L with 0.8 square metres")
	press("ShiftStartButton")
	check(tool.completed_triangles[-1].points[0]==original[1],"physical shift advances the first vertex")
	check(mesh_area()>good_area+.1,"shift preserves the fan's deliberate overspill comparison")
	check(tool.placed_points==vertices,"shift does not move any boundary corner")
	check(panel.text_label.text.contains("Triangles: 4") and panel.text_label.text.contains("START 2"),"readout reports four triangles and new start")
	check(tool.point_indicators[1].get_node("CornerNumber").get_meta("text")=="START 2","flat corner tag follows selected start")
	press("FillButton")
	check(not tool.completed_triangles[-1].mesh.visible and not panel.fill_button.is_selected(),"fill cap tracks actual hidden state")
	var edge_count: int = tool.line_mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size()
	check(edge_count==12,"six boundary edges remain visible while fill is hidden")
	press("FillButton")
	for i in 5: press("ShiftStartButton")
	check(tool.completed_triangles[-1].points==original and is_equal_approx(mesh_area(),good_area),"six shifts return to the original fan without drift")
	tool.call("_on_grab_point_picked_up",handle)
	press("ShiftStartButton")
	check(tool.completed_triangles[-1].points==original and not panel._shift_ready,"held pen blocks shift at the input boundary")
	tool.call("_on_grab_point_dropped",handle)
	tool.call("_on_edit_point_picked_up",tool.point_indicators[0],0)
	press("ShiftStartButton")
	check(tool.completed_triangles[-1].points==original and not panel._shift_ready,"held corner blocks shift at the input boundary")
	tool.call("_on_edit_point_dropped",tool.point_indicators[0],0)
	press("NewOutlineButton")
	check(tool.completed_triangles.size()==1 and tool.current_path.is_empty(),"relocated outline button preserves the finished face")
	tool.call("_on_grab_point_picked_up",handle)
	tip.global_position = Vector3(9,1.4,8)
	tool.call("_process",1.01)
	tool.call("_on_grab_point_dropped",handle)
	press("ShiftStartButton")
	check(not panel._shift_ready and tool.completed_triangles[-1].points==original,"unfinished outline blocks shifting the previous loop")
	# Repeated transformations retain a single frame and full-size physical controls.
	var button: Node3D = panel.get_node("NewOutlineButton")
	var local_pose := button.transform
	for yaw in [0,90,180,270]:
		tool.rotation_degrees.y = yaw
		tool.scale = Vector3.ONE*1.5
		panel.call("_sync_mount")
		var pose := panel.global_transform
		for i in 4: panel.call("_sync_mount")
		check(panel.global_transform.is_equal_approx(pose),"mount stays stable at yaw "+str(yaw))
		check(button.transform.is_equal_approx(local_pose) and button.global_basis.get_scale().is_equal_approx(Vector3.ONE),"outline cap keeps frame and metre scale at yaw "+str(yaw))
		check(panel.support.global_basis.y.is_equal_approx(Vector3.UP),"support stays upright at yaw "+str(yaw))
	panel.update_readout()
	for i in 3: await process_frame
	check(panel.text_label.get_minimum_size().x <= panel.surface.viewport.size.x-64 and panel.text_label.get_minimum_size().y <= panel.surface.viewport.size.y-140,"longest active status fits the fixed display")
	check(panel.find_children("*","Label3D",true,false).is_empty(),"all console captions and readout are flat surfaces")
	DirAccess.make_dir_recursive_absolute("res://doc/reports/interfaces-2026-09-21/spine-triangle/after")
	FileAccess.open("res://doc/reports/interfaces-2026-09-21/spine-triangle/after/console-checks.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"scope":"Native pointer callbacks, supplied held positions, real mesh comparisons and mount transforms; no headset test."},"\t"))
	world.free()
	quit(0 if failures.is_empty() else 1)
