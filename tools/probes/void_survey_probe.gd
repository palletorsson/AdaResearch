extends "res://tools/probes/void_evening_probe.gd"

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out=arg.trim_prefix("--out=")
	await trial()
	FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed,"scope":"Actual Godot Mobile render, desktop load and XRTools synthetic controllers. Physical headset not tested."},"\t"))
	quit(0 if failed.is_empty() else 1)

func trial() -> void:
	await start(false)
	await visit(3)
	var content: Node3D = game.building.content
	var saved_ok := true
	var saved_count := 0
	for item in content.data.floors[3].artifacts+content.data.floors[3].get("copies",[]):
		var area: Node3D = content.exhibits["3/"+str(item.id)].get_node("Artifact")
		for key in item.get("config",{}).get("parts",{}):
			var pose: Dictionary = item.config.parts[key]
			var part: Node3D = area.get_node_or_null(str(key))
			if part == null: saved_ok=false;continue
			if pose.has("position"):
				var p: Array=pose.position
				saved_ok = saved_ok and part.position.distance_to(Vector3(p[0],p[1],p[2]))<.002
			saved_count += 1
	check("Desktop loads all %d saved part overrides from shared rooms.json" % saved_count,saved_ok and saved_count>0)
	game.queue_free();await frames(15)
	await start(true)
	await visit(3)
	game._set_enabled(true)
	game.atmosphere.animate_sky=false;game.atmosphere.set_sky_time(180)
	var setting: Node3D=game.building.content.exhibits["3/setting_out"].get_node("Artifact")
	var plan: Node3D=setting.get_node("FloorPlanTable")
	var full: Node3D=setting.get_node("FullSizeRuler")
	check("Small ruler converts 1:10; large ruler measures 1:1",is_equal_approx(plan.measured_length,20) and is_equal_approx(full.measured_length,2))
	var drawing: Node3D=plan.get_node("Blueprint")
	check("Blueprint uses the real 42x18 m frame, two shafts and twelve columns",drawing.structure_size==Vector2(42,18) and drawing.shaft_count==2 and drawing.column_count==12 and drawing.strokes.size()>60)
	check("Blueprint includes saved partitions and entrance walls",drawing.partition_count>game.building.content.data.floors[3].walls.size())
	check("Large ruler has graduations but no static table or board",not full.has_node("Table") and full.ruler.tick_count>10)
	game.place_player(plan.to_global(Vector3(0,.06,1.9)));await frames(12)
	hand_at(left,plan.point_b.global_position);await frames(12)
	left.set_input("grip",1.0);await frames(15)
	check("Original left XRTools hand picks up the plan endpoint",game.pickups[0].picked_up_object==plan.point_b)
	var target := Vector3(1.4,1.8,-.35)
	hand_at(left,plan.line.to_global(target));await frames(20)
	check("Small ruler endpoint moves freely in X, Y and Z",plan.point_b.position.distance_to(target)<.02)
	var expected: float=plan.point_a.global_position.distance_to(plan.line.to_global(target))*10.0
	check("Readout measures the full 3D diagonal at 1:10",absf(plan.measured_length-expected)<.03 and plan.glow.visible)
	await photograph("plan-spatial-ruler.png",plan.to_global(Vector3(2.8,2.8,3.4)),plan.to_global(Vector3(0,1.1,0)),68)
	left.set_input("grip",0.0);await frames(12)
	check("Release retains the 3D measurement",plan.point_b.position.distance_to(target)<.02 and not plan.glow.visible)
	await photograph("blueprint.png",plan.to_global(Vector3(0,4.2,1.6)),plan.to_global(Vector3(0,.99,0)),66)
	game.place_player(full.to_global(Vector3(0,.06,1.2)));await frames(12)
	hand_at(right,full.point_b.global_position);await frames(12)
	right.set_input("grip",1.0);await frames(15)
	check("Original right XRTools hand picks up full-size endpoint",game.pickups[1].picked_up_object==full.point_b)
	var large_target := Vector3(2.4,2.2,.8)
	hand_at(right,full.line.to_global(large_target));await frames(20)
	var metres: float=full.point_a.global_position.distance_to(full.line.to_global(large_target))
	check("Large ruler follows all axes and reads actual world metres",full.point_b.position.distance_to(large_target)<.02 and absf(full.measured_length-metres)<.02)
	await photograph("full-size-ruler.png",full.to_global(Vector3(3.3,2.5,3.5)),full.to_global(Vector3(.5,1.5,.2)),68)
	right.set_input("grip",0.0);await frames(12)
	var retained: float=full.measured_length
	var old_pose: Transform3D=full.transform
	full.rotate_y(PI/2);full.position.x+=.5;await frames(20)
	check("Editor rotation and translation preserve a released measurement",absf(full.measured_length-retained)<.02)
	full.transform=old_pose
	full.local_positions[0]=Vector3(0,1,0);full.local_positions[1]=Vector3(0,3,0);await frames(10)
	var finite := true
	for i in range(full.ruler.tick_count):
		var transform: Transform3D=full.ruler.ticks.multimesh.get_instance_transform(i)
		finite=finite and transform.is_finite()
	check("Vertical ruler has finite graduation geometry",finite and is_equal_approx(full.measured_length,2))
	full.local_positions[0]=Vector3.ZERO;full.local_positions[1]=Vector3.ZERO;await frames(8)
	check("Coincident endpoints show zero without stale ruler geometry",is_zero_approx(full.measured_length) and full.ruler.tick_count==0 and not full.line.current_line.visible)
	full.local_positions[0]=Vector3.ZERO;full.local_positions[1]=Vector3(1000,0,0);await frames(8)
	check("Long ruler keeps a bounded number of draw instances",full.ruler.tick_count<=64 and is_equal_approx(full.measured_length,1000))
	full.reset_line();await frames(8)
	check("Reset restores accessible endpoints",is_equal_approx(full.measured_length,2))
	game.queue_free();await frames(15)
	for tracker in [head,left,right]: XRServer.remove_tracker(tracker)

func photograph(filename: String, at: Vector3, target: Vector3, field_of_view := 75.0) -> void:
	var rig: Node3D=game.get_node("XROrigin3D")
	var shown: bool=rig.visible
	rig.hide()
	await super.photograph(filename,at,target,field_of_view)
	rig.visible=shown
