extends SceneTree
## Native grab and pointer actions on the real pyramid; constraint and recovery regressions.
var checks := 0
var failures: Array[String] = []
var tool: Node3D
var panel: Node3D
var pointer: Node3D
class PyramidTestGrabber extends Node3D:
	var picked_up_ranged := false
	var held: Node3D
	func drop_object() -> void:
		held.let_go(self,Vector3.ZERO,Vector3.ZERO)
		held = null
func _initialize() -> void: run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)
	print(("PASS " if ok else "FAIL ")+label)
func press() -> void:
	var area: Node3D = panel.button.get_node("InteractableAreaButton")
	XRToolsPointerEvent.pressed(pointer,area,area.global_position)
	XRToolsPointerEvent.released(pointer,area,area.global_position)
	panel.refresh()
func vertices() -> PackedVector3Array:
	return tool.mesh_instance.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
func run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	pointer = Node3D.new()
	world.add_child(pointer)
	tool = load("res://commons/primitives/pyramid/pyramid_edit.tscn").instantiate()
	tool.workbench = true
	tool.position = Vector3(4,.708,5)
	tool.rotation_degrees.y = 180
	world.add_child(tool)
	panel = tool.get_node("RecoveryPanel")
	for i in 3: await process_frame
	var home := vertices().duplicate()
	check(home.size()==18,"Pyramid retains six rendered triangles")
	check(panel.is_set_as_top_level(),"Recovery panel excluded from specimen seating")
	check(panel.find_children("*","Label3D",true,false).is_empty(),"All recovery text is flat texture geometry")
	check(panel.status.get_child_count()==2,"The two status lines occupy separate readable planes")
	for handle in tool.handle_nodes.values():
		check(is_equal_approx(handle.get_node("MeshInstance3D").mesh.radius,.028),str(handle.name)+" visible grip enlarged")
		check(is_equal_approx(handle.get_node("CollisionShape3D").shape.radius,.0455009),str(handle.name)+" native grab collider unchanged")
	var grabber := PyramidTestGrabber.new()
	world.add_child(grabber)
	var apex: Node3D = tool.handle_nodes.apex
	grabber.global_transform = apex.global_transform
	grabber.held = apex
	apex.pick_up(grabber)
	check(tool.any_handle_held(),"Native grab owns the apex")
	grabber.global_position += Vector3(.25,.10,.12)
	for i in 8: await process_frame; await physics_frame
	check(vertices()!=home,"Native hand movement rebuilds the real pyramid mesh")
	var held_vertices := vertices().duplicate()
	panel.refresh()
	check(not panel.button.play_press_sound,"Reset is quiet while a vertex is held")
	check(panel.status.get_meta("text").begins_with("LET GO FIRST"),"Held state explains unavailable reset")
	press()
	check(vertices()==held_vertices and tool.any_handle_held(),"Pointer reset cannot snatch a held vertex")
	grabber.drop_object()
	for i in 3: await process_frame
	check(not tool.any_handle_held(),"Native drop releases the vertex")
	press()
	check(vertices()==home,"Physical reset restores the authored mesh after release")
	check(panel.button.play_press_sound,"Reset becomes available after release")
	for mode in ["free","apex_only","base_only","symmetric"]:
		tool.apply_grid_config({"constraint":mode})
		var corner: Node3D = tool.handle_nodes.base_back_left
		corner.position += Vector3(-.2,.1,.15)
		apex.position += Vector3(.2,.15,.1)
		tool._process(0)
		if mode=="apex_only": check(corner.position==tool._home_positions.base_back_left,"Apex-only still fixes the base")
		elif mode=="base_only": check(apex.position==tool._home_positions.apex,"Base-only still fixes the apex")
		elif mode=="symmetric": check(is_zero_approx(apex.position.x) and is_zero_approx(apex.position.z),"Symmetric mode still centres the apex")
		else: check(corner.position!=tool._home_positions.base_back_left and apex.position!=tool._home_positions.apex,"Free mode preserves independent movement")
		press()
		check(vertices()==home and tool.constraint==mode,"Reset preserves "+mode+" rule and restores the vertices")
	tool.set_pyramid_size(.5,.8)
	var authored := vertices().duplicate()
	apex.position.y += .3
	tool._rebuild_pyramid()
	press()
	check(vertices()==authored,"Reset respects a newly authored size")
	for yaw in [0,90,180,270]:
		tool.rotation_degrees.y = yaw
		panel.refresh()
		check(panel.global_basis.get_scale().is_equal_approx(Vector3.ONE),"Console keeps unit physics scale at yaw "+str(yaw))
		check(panel.support.global_basis.y.is_equal_approx(Vector3.UP),"Support stays upright at yaw "+str(yaw))
	var other: Node3D = load("res://commons/primitives/pyramid/pyramid_edit.tscn").instantiate()
	world.add_child(other)
	check(not other.has_node("RecoveryPanel"),"Other placements retain direct manipulation without an added panel")
	check(is_equal_approx(other.handle_nodes.apex.get_node("MeshInstance3D").mesh.radius,.012),"Other placements retain their authored grip size")
	other.apply_grid_config({"workbench":"1"})
	other.apply_grid_config({"workbench":"1"})
	check(other.find_children("RecoveryPanel","Node3D",false,false).size()==1,"Repeated configuration builds only one recovery panel")
	other.apply_grid_config({"workbench":"0"})
	check(not other.has_node("RecoveryPanel"),"Disabling workbench removes the optional console")
	check(is_equal_approx(other.handle_nodes.apex.get_node("MeshInstance3D").mesh.radius,.012),"Disabling workbench restores the original grip radius")
	other.apply_grid_config({"workbench":"1"})
	check(other.find_children("RecoveryPanel","Node3D",false,false).size()==1,"Re-enabling workbench creates one live console")
	check(is_equal_approx(other.handle_nodes.apex.get_node("MeshInstance3D").mesh.radius,.028),"Re-enabling restores the larger visible grip")
	FileAccess.open("res://doc/reports/interfaces-2026-09-21/spine-polyhedra/after/functional-checks.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"scope":"Native grab and pointer callbacks, actual mesh and constraint comparisons; no headset test."},"\t"))
	print("PYRAMID_RESULT ",checks," ",failures)
	quit(0 if failures.is_empty() else 1)
