extends SceneTree
## Isolated live-script contact/data contract. No headset input or museum-route claim.
const OUT := "res://doc/book/iterations/2026-09-19-arrays-review/opening/contact-checks.json"
var checks: Array = []
var failures: Array = []
var fixture: Node3D

func _initialize() -> void: run.call_deferred()

func check(ok: bool, label_: String, detail: Variant = null) -> void:
	checks.append({"name":label_, "passed":ok, "detail":detail})
	if not ok: failures.append(label_)
	print("[arrays-opening] ", "PASS " if ok else "FAIL ", label_)

func wait_ticks(n := 4) -> void:
	for i in n:
		await physics_frame
		await process_frame

func toucher(at: Vector3, group_: String) -> CharacterBody3D:
	var body := CharacterBody3D.new()
	body.name = "ContactProbe"
	body.add_to_group(group_)
	body.position = at
	body.collision_layer = 1
	body.collision_mask = 1
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.15
	capsule.height = 1.5
	shape.shape = capsule
	shape.position.y = 0.75
	body.add_child(shape)
	fixture.add_child(body)
	return body

func run() -> void:
	fixture = Node3D.new()
	root.add_child(fixture)
	current_scene = fixture
	var row = load("res://algorithms/arrays/row_3_x.gd").new()
	fixture.add_child(row)
	var grid = load("res://algorithms/arrays/grid_2d_4x4.gd").new()
	grid.notation = "plate"
	grid.position.x = 20.0
	fixture.add_child(grid)
	var lab = load("res://commons/artifacts/regularity/array_flight_lab.gd").new()
	lab.position.x = 40.0
	fixture.add_child(lab)
	await wait_ticks(12)
	check(row.array_data == [[1,1,1,1]], "row begins with four occupied addresses")
	var cube: Node = row.get_node("Cube_2")
	var label_: Label3D
	for child in cube.get_children():
		if child is Label3D: label_ = child
	check(label_ != null and label_.text == "[2]", "row address label belongs to collected cube")
	var walker := toucher(row.to_global(Vector3(2,0,0)), "em_walker")
	await wait_ticks(30)
	check(not is_instance_valid(cube), "desktop-group physical overlap collects row cube")
	check(not is_instance_valid(label_), "row cube takes its label with it")
	check(row.array_data == [[1,1,0,1]], "contact changes only row slot 2")
	check(row._binary_table.get_node("Cell_0_2").text == "0", "row visible table updates to zero")
	walker.queue_free()
	await wait_ticks()
	var card: Label3D
	for child in grid.get_children():
		if child is Label3D and child.text == "[1, 2]": card = child
	check(card != null, "off-diagonal plate is a sibling of its cube")
	var grid_cube: Node = grid.get_node("Cube_1_2")
	walker = toucher(grid.to_global(Vector3(1,0,2)), "player_body")
	await wait_ticks(30)
	check(not is_instance_valid(grid_cube), "XR-body-group physical overlap collects grid cube")
	check(grid.grid_data[1][2] == 0 and grid.grid_data[2][1] == 1, "[x,z] updates correct off-diagonal address")
	check(grid._binary_table.get_node("Cell_1_2").text == "0" and grid._binary_table.get_node("Cell_2_1").text == "1", "visible table preserves x-row z-column ordering")
	check(is_instance_valid(card) and card.text == "[1, 2]", "grid plate remains after occupant collection")
	walker.queue_free()
	await wait_ticks()
	check(lab.grid.find_children("Cube_*","Node3D",false,false).size() == 64, "flight lattice contains 64 live cubes")
	var depth_labels := 0
	for label_node in lab.grid.find_children("*", "Label3D", true, false):
		if not label_node.no_depth_test and is_equal_approx(label_node.position.y,1.0): depth_labels += 1
	check(depth_labels == 64, "all flight-lab address labels respect opaque panels and sit above their cubes", depth_labels)
	lab.select_axis(0)
	lab.select_axis(1)
	lab.select_axis(1)
	lab.select_axis(2)
	lab.select_axis(2)
	lab.select_axis(2)
	check(lab.selected == Vector3i(1,2,3), "console selects x y z independently")
	check(lab.marker.position.is_equal_approx(lab.grid.position + Vector3(1,2,3)*2.4 + Vector3(0,.35,0)), "marker connects display order to spatial position")
	var volume_cube: Node3D = lab.grid.get_node("Cube_1_2_3")
	walker = toucher(volume_cube.global_position, "em_walker")
	await wait_ticks(30)
	check(not is_instance_valid(volume_cube), "physical overlap collects selected volume cube")
	check(lab.values[2][3][1] == 0 and lab.values[1][3][2] == 1, "collection writes y layer z row x entry without transposing")
	check("[1,2,3] | value 0" in lab.readout.text, "selected address remains readable as zero")
	check(lab.enclosure.contains_point(walker.global_position) and lab.values[2][3][1] == 0, "visitor inside recorded vacancy does not replace cube occupancy")
	check(lab.enclosure.flight_velocity(Basis.IDENTITY,Vector2.ZERO) == Vector3.ZERO, "neutral flight input produces zero velocity")
	var tilt := Basis(Vector3.RIGHT, deg_to_rad(30))
	var ascent: Vector3 = lab.enclosure.flight_velocity(tilt,Vector2(0,1))
	check(ascent.y > 0 and ascent.z < 0, "tilted forward basis carries ascent and forward motion", str(ascent))
	check(lab.enclosure.flight_velocity(Basis.IDENTITY,Vector2.ONE,1).length() <= 2.401, "combined flight direction respects 2.4m/s bound")
	check(not lab.enclosure.contains_point(lab.to_global(Vector3(0,1,-7))) and not lab.enclosure.contains_point(lab.to_global(Vector3(0,1,7))), "both ground door approaches lie outside flight permission")
	var provider: Script = load("res://commons/movement/museum_flight_provider.gd")
	check(provider != null and provider.can_instantiate(), "live XR movement provider loads with its dependencies")
	var file := FileAccess.open(OUT,FileAccess.WRITE)
	file.store_string(JSON.stringify({"scope":"Isolated live scripts, real Area3D/capsule overlap, table labels, address order and flight-vector contract; no headset controls or museum route tested", "checks":checks,"failures":failures},"  "))
	file.close()
	quit(0 if failures.is_empty() else 1)
