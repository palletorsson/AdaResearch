extends SceneTree
const OUT := "res://doc/book/iterations/2026-09-24-primitives-review-comments/"
var results: Array[Dictionary] = []
var failures: Array[String] = []
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, label: String) -> void:
	results.append({"passed": ok, "check": label})
	if not ok: failures.append(label)
func run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	current_scene = world
	var previous = load(OUT + "grid-before.gd").new()
	var loader = load("res://commons/grid/GridInteractablesComponent.gd").new()
	var map: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://commons/maps/Point_Triangle_Context/map_data.json"))
	var paths := {"triangle_line_puzzle": "res://commons/primitives/line/puzzles/triangle_line_puzzle.tscn", "draw_triangle_faces": "res://commons/primitives/point/draw_triangle_faces.tscn"}
	for row: Array in map.layers.interactables:
		for value in row:
			var token := str(value)
			var name_part := token.split(":")[0].split("#")[0]
			if not paths.has(name_part): continue
			var before: Dictionary = previous.call("_parse_interactable_token", token)
			var after: Dictionary = loader.call("_parse_interactable_token", token)
			check(before.config_data.get("discovery") is bool and float(before.overrides.get("rotation_y_degrees", 0)) == 1, name_part + ": reproduced old bool/yaw misparse")
			check(str(after.config_data.get("discovery")) == "1", name_part + ": discovery stays a configuration value")
			var head := token.split("#")[0].split(":")
			var yaw := float(head[1]) if head.size() > 1 else 0.0
			check(is_equal_approx(float(after.overrides.get("rotation_y_degrees", 0)), yaw), name_part + ": authored yaw retained")
			for pair in [[previous,before,"before"],[loader,after,"after"]]:
				var subject: Node3D = load(paths[name_part]).instantiate()
				pair[0].call("_apply_artifact_config", subject, pair[1].config_data, name_part)
				world.add_child(subject)
				await process_frame
				await process_frame
				subject.set_process(false)
				check(subject.has_node("ExperimentPanel") == (pair[2] == "after"), name_part + ": actual panel " + ("created after fix" if pair[2] == "after" else "missing before fix"))
				subject.queue_free()
				await process_frame
	for token in ["triangle_line_puzzle:90:1.2#discovery:0", "clipboard#point_zero:15:-0.3:1.1", "capsule:45:0.2#rings:4"]:
		var a: Dictionary = loader.call("_parse_interactable_token",token)
		if token.contains("discovery:0"):
			check(str(a.config_data.discovery)=="0" and a.overrides.rotation_y_degrees==90, "discovery off retains authored yaw")
		elif token.contains("point_zero"):
			check(a.config_data.point_zero==true and a.overrides.rotation_y_degrees==15 and is_equal_approx(a.overrides.y_position,-0.3),"tutorial shorthand unchanged")
		else:
			check(str(a.config_data.rings)=="4" and a.overrides.rotation_y_degrees==45,"other numeric configuration unchanged")
	# The quad paragraph follows actual emitted meshes, not just its labels.
	var quad: Node3D = load("res://commons/primitives/quad/quad.tscn").instantiate()
	world.add_child(quad)
	await process_frame
	var a0: PackedVector3Array = quad.get_node("TriangleMesh_A_Front").mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var b0: PackedVector3Array = quad.get_node("TriangleMesh_B_Front").mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	quad.call("_on_point_moved",1,Vector3(0.8,0.5,0.4),{})
	var a1: PackedVector3Array = quad.get_node("TriangleMesh_A_Front").mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var b1: PackedVector3Array = quad.get_node("TriangleMesh_B_Front").mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	check(a1!=a0 and b1==b0,"quad: off-diagonal corner changes one triangle")
	quad.call("_on_point_moved",0,Vector3(-0.8,0.3,0.6),{})
	check(quad.get_node("TriangleMesh_A_Front").mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]!=a1 and quad.get_node("TriangleMesh_B_Front").mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]!=b1,"quad: shared-diagonal corner changes both triangles")
	# Source-map placement: use real instrument nodes and their actual transforms.
	var portals: Node3D = load("res://commons/primitives/combines/combine_portals.tscn").instantiate()
	portals.position = Vector3(3,-0.2,4)
	portals.set_meta("config_discovery","1")
	world.add_child(portals)
	portals.call("apply_grid_config",{"portal_spacing":"1.4"})
	var race: Node3D = load("res://commons/primitives/combines/achilles_tortoise.tscn").instantiate()
	race.set_meta("config_discovery","1")
	world.add_child(race)
	race.set_process(false)
	var panel: Node3D = portals.get_node("ExperimentPanel")
	var map_after: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://commons/maps/Primitives_Portals/map_data.json"))
	for version in ["before","after"]:
		var path: String = OUT+"before/commons/maps/Primitives_Portals/map_data.json" if version=="before" else "res://commons/maps/Primitives_Portals/map_data.json"
		var source: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
		var cell := Vector2i.ZERO
		for z in source.layers.interactables.size():
			for x in source.layers.interactables[z].size():
				if str(source.layers.interactables[z][x]).begins_with("achilles_tortoise"):
					cell = Vector2i(x,z)
		race.position = Vector3(cell.x,1,cell.y)
		var a: Vector3 = panel.to_local(race.global_position)
		var b: Vector3 = panel.to_local(race.to_global(Vector3(0,0,-float(race.get("track_length")))))
		var t: float = -a.z/(b.z-a.z)
		var crossing: Vector3 = a.lerp(b,t)
		var overlap: bool = t>=0 and t<=1 and absf(crossing.x)<=0.775 and absf(crossing.y)<=0.55
		check(overlap==(version=="before"),"portal track: "+("old rail crosses real panel" if version=="before" else "new rail clears real panel"))
		if version=="after":
			var supported := true
			for z in range(cell.y-6,cell.y+1):
				supported = supported and z>=0 and z<source.layers.structure.size() and str(source.layers.structure[z][cell.x])=="1"
			check(supported,"new track spans seven authored floor cells inside hall")
			race.call("next_discovery_step")
			check(race.call("discovery_snapshot").step==1,"relocated Achilles retains NEXT STEP")
			check(race.has_node("ExperimentPanel/StepButton"),"relocated Achilles retains its own control")
	quad.queue_free()
	race.queue_free()
	portals.queue_free()
	await process_frame
	previous.free()
	loader.free()
	FileAccess.open(OUT+"runtime.json",FileAccess.WRITE).store_string(JSON.stringify({"scope":"Production grid parsing and configuration of actual Triangle map tokens, then instantiated artifacts; actual quad mesh updates and real portal-panel intersection at before/after source-map positions. Not a full room walkthrough or headset test.","checks":results,"failures":failures},"  "))
	print("REVIEW_PROBE ",results.size()," checks; failures=",failures)
	world.queue_free()
	current_scene = null
	await process_frame
	await process_frame
	quit(0 if failures.is_empty() else 1)
