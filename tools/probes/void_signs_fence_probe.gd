extends "res://tools/probes/void_evening_probe.gd"

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out=arg.trim_prefix("--out=")
	await start(true)
	game.atmosphere.animate_sky=false;game.atmosphere.set_sky_time(180)
	await visit(3)
	game._set_enabled(true)
	var setting: Node3D=game.building.content.exhibits["3/setting_out"].get_node("Artifact")
	var room: Node3D=setting.get_node("MeasurementRoom")
	check("Initial gap is 60 cm and stays unsolved",is_equal_approx(room.point_a.position.distance_to(room.point_b.position),.6) and not room.unlocked)
	check("White walls and header remain matte",room.get_node("West").material_override.albedo_color.r>.9 and room.get_node("Header").material_override.roughness==1)
	check("Door reuses the original chain-link prefab without razor wire",room.gate.get_node("ConstructionFence/ChainLinkPanel")!=null and not room.gate.get_node("ConstructionFence").show_razor)
	var sign: Node3D=room.gate.get_node("ConstructionFence/DangerSign")
	var text: Array=[]
	for label in sign.find_children("*","Label3D",true,false): text.append(label.text)
	check("Warning sign carries the reference's danger and entry instructions",text.has("DANGER") and text.has("DO NOT ENTER") and text.has("AUTHORIZED\nPERSONNEL ONLY"))
	game.place_player(Vector3(0,-17.94,5.6));await frames(15)
	check("Closed fence still blocks the doorway",not await move_to(Vector3(0,-18,.2),false,170) and game.body.global_position.z>1.2)
	await photograph("entry-closed.png",Vector3(1.7,-16.35,7.7),Vector3(0,-16.5,2.3),76)
	await photograph("fence-detail.png",room.to_global(Vector3(1.5,1.8,-.5)),room.to_global(Vector3(0,1.5,-3.34)),60)
	game.place_player(Vector3(0,-17.94,5.6));await frames(15)
	hand_at(right,room.point_b.global_position);await frames(15)
	right.set_input("grip",1.0);await frames(15)
	check("Closer endpoint remains a real XRTools pickup",game.pickups[1].picked_up_object==room.point_b)
	hand_at(right,room.point_a.global_position+Vector3(.18,0,0));await frames(100)
	check("Bringing the points together still creates the line and opens the gate",room.unlocked and room.line.current_line.visible and room.gate.position.y>2.75)
	check("The warning sign travels with the opening door",sign.global_position.y>room.global_position.y+4)
	await photograph("entry-open.png",Vector3(1.7,-16.35,7.7),Vector3(0,-16.5,2.3),76)
	right.set_input("grip",0.0);await frames(12)
	check("Player passes through the raised construction fence",await move_to(Vector3(0,-18,.2)))
	room.reset_line();await frames(5)
	check("Retry returns the points to 60 cm while retaining the solved door",is_equal_approx(room.point_a.position.distance_to(room.point_b.position),.6) and room.unlocked)
	await visit(5)
	var surfaces: Node3D=game.building.content.exhibits["5/surfaces"].get_node("Artifact")
	for title in ["PinkTriangle","PinkTriangleDown","PinkTriangleLeft","PinkTriangleRight"]:
		var direction_sign: Node3D=surfaces.get_node(title)
		var triangle: MeshInstance3D=direction_sign.face.get_node("PinkTriangle")
		var finish: StandardMaterial3D=triangle.material_override
		check(title+": colour has no reflection or angle-dependent lighting",finish.shading_mode==BaseMaterial3D.SHADING_MODE_UNSHADED and finish.metallic_specular==0 and not finish.emission_enabled)
		var original: int=direction_sign.direction
		direction_sign.turn_button.pressed.emit();await frames(2)
		check(title+": physical turn button retains its direction change",direction_sign.direction==(original+1)%4)
		direction_sign.set_direction(original)
	var first: Node3D=surfaces.get_node("PinkTriangle")
	await photograph("signs-front.png",first.to_global(Vector3(1.9,1.85,4.5)),first.to_global(Vector3(1.9,1.85,0)),66)
	await photograph("sign-side.png",first.to_global(Vector3(2.6,1.85,.85)),first.to_global(Vector3(0,1.85,0)),46)
	game.queue_free();await frames(15)
	for tracker in [head,left,right]: XRServer.remove_tracker(tracker)
	FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed,"scope":"Real Godot Mobile rendering and XRTools with synthetic controller input; no physical headset test."},"\t"))
	quit(0 if failed.is_empty() else 1)

func photograph(filename: String, at: Vector3, target: Vector3, field_of_view := 75.0) -> void:
	var rig: Node3D=game.get_node("XROrigin3D")
	var shown: bool=rig.visible;rig.hide()
	await super.photograph(filename,at,target,field_of_view)
	rig.visible=shown
