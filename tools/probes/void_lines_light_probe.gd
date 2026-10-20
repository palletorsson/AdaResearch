extends "res://tools/probes/void_triangle_probe.gd"

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out=arg.trim_prefix("--out=")
	await trial()
	FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed,"scope":"Real Mobile-rendered Godot tower and XRTools with synthetic controllers; physical headset not tested."},"\t"))
	quit(0 if failed.is_empty() else 1)

func trial() -> void:
	await start(true)
	game.place_player(Vector3(0,-11.94,8.0));await frames(35)
	game.atmosphere.animate_sky=false;game.atmosphere.set_sky_time(180)
	check("Drop from Coordinates lands inside the open-top entry",await move_to(Vector3(0,-18,10.0)))
	check("Landing records Lines checkpoint without death",game.checkpoint==3 and game.deaths==0)
	var content: Node3D=game.building.content
	var setting: Node3D=content.exhibits["3/setting_out"].get_node("Artifact")
	var gate: Node3D=setting.get_node("MeasurementRoom")
	var assembly: Node3D=content.exhibits["3/assembly"].get_node("Artifact")
	check("Four existing assemblies are retained",content.exhibits.has("3/directions") and content.exhibits.has("3/consequences") and setting.has_node("PairingPoints"))
	check("Entry begins with two points and no segment",not gate.unlocked and not gate.line.current_line.visible)
	check("Closed construction grid door blocks a player",not await move_to(Vector3(0,-18,.2),false,170) and game.body.global_position.z>1.2)
	await photograph("entry-closed.png",Vector3(2,-16.35,7.5),Vector3(0,-16.7,3.7),75)
	game.place_player(Vector3(0,-17.94,5.6));await frames(15)
	hand_at(right,gate.point_b.global_position);await frames(15)
	right.set_input("grip",1.0);await frames(15)
	check("Gate endpoint is picked up through real XRTools",game.pickups[1].picked_up_object==gate.point_b)
	hand_at(right,gate.point_a.global_position+Vector3(.18,0,0));await frames(30)
	check("Bringing the points close creates the line and unlocks the door",gate.unlocked and gate.line.current_line.visible)
	hand_at(right,gate.point_a.global_position+Vector3(1.2,0,0));await frames(80)
	check("Grid door rises out of the walking opening",gate.gate.position.y>2.75)
	await photograph("entry-open.png",Vector3(2,-16.35,7.5),Vector3(0,-16.7,3.7),75)
	right.set_input("grip",0.0);await frames(10)
	check("Open door permits continuous passage",await move_to(Vector3(0,-18,.2)))
	var plan: Node3D=setting.get_node("FloorPlanTable")
	var ruler: Node3D=setting.get_node("FullSizeRuler")
	check("Plan and full ruler use the existing segment calculation",plan.line.get_script()==gate.line.get_script() and ruler.line.get_script()==gate.line.get_script())
	check("1:10 plan starts with an exact twenty-metre measurement",is_equal_approx(plan.measured_length,20.0))
	check("Plan handles start within 55 cm of the visitor's table edge",1.2-plan.point_a.position.z<.551 and 1.2-plan.point_b.position.z<.551)
	check("1:1 ruler starts with an exact two-metre measurement",is_equal_approx(ruler.measured_length,2.0))
	game.place_player(Vector3(0,-17.94,-.8));await frames(12)
	hand_at(left,plan.point_b.global_position);await frames(12)
	left.set_input("grip",1.0);await frames(15)
	check("Left hand picks up the plan endpoint",game.pickups[0].picked_up_object==plan.point_b)
	hand_at(left,plan.line.to_global(Vector3(1.5,1.3,.25)));await frames(15)
	check("Plan endpoint follows the hand in three dimensions",plan.point_b.position.distance_to(Vector3(1.5,1.3,.25))<.02)
	check("Three-dimensional measurement converts exactly at 1:10",absf(plan.measured_length-plan.point_a.global_position.distance_to(plan.line.to_global(Vector3(1.5,1.3,.25)))*10)<.02 and plan.glow.visible)
	await photograph("plan-measure.png",Vector3(1.8,-15.65,.6),Vector3(0,-17,-2.4),69)
	left.set_input("grip",0.0);await frames(10)
	check("Release keeps the plan measurement and turns off its light",not plan.glow.visible and plan.measured_length>25)
	game.place_player(Vector3(0,-17.94,-4.7));await frames(10)
	hand_at(right,ruler.point_b.global_position);await frames(12)
	right.set_input("grip",1.0);await frames(15)
	hand_at(right,ruler.line.to_global(Vector3(2.0,1.4,.5)));await frames(12)
	check("Full ruler follows all three axes at 1:1",ruler.point_b.position.distance_to(Vector3(2.0,1.4,.5))<.02 and absf(ruler.measured_length-ruler.point_a.global_position.distance_to(ruler.line.to_global(Vector3(2.0,1.4,.5))))<.02 and ruler.glow.visible)
	await photograph("ruler-full-size.png",Vector3(2.5,-15.9,-3.8),Vector3(0,-17,-5.8),75)
	right.set_input("grip",0.0);await frames(10)
	# Clear spatial route, beginning after the puzzle. This uses real body motion.
	game.place_player(Vector3(0,-17.94,.3));await frames(10)
	var route_ok := true
	for stop in content.data.floors[3].route.slice(4):
		if not await move_to(Vector3(stop.position[0],-18,stop.position[1])):
			route_ok=false;print("[void] blocked route: ",stop.label)
			var p: Vector3=game.body.global_position
			for height in [.2,.7,1.2]:
				var hit := ray(p+Vector3(0,height,0),Vector3(stop.position[0],p.y+height,stop.position[1]))
				if not hit.is_empty(): print("[void] obstruction ",hit.collider.get_path())
			break
	check("Route reaches measurement, wall collection, tunnel and next descent",route_ok and game.deaths==0)
	game.place_player(Vector3(17.2,-17.94,-2.2));await frames(12)
	await photograph("wall-collection.png",Vector3(17.9,-16.35,-1.4),Vector3(16.4,-16.1,-5.8),80)
	var plank: RigidBody3D=assembly.get_node("SevenPlanks4")
	hand_at(left,plank.global_position);await frames(12)
	left.set_input("grip",1.0);await frames(12)
	check("Hanging collection retains pickup and adds real light",game.pickups[0].picked_up_object==plank and plank.get_node("InteractionLight").visible)
	left.set_input("grip",0.0);await frames(8)
	check("Wall line light stops on release",not plank.get_node("InteractionLight").visible)
	var stick: RigidBody3D=assembly.get_node("Hand_light")
	hand_at(right,stick.global_position);await frames(12)
	right.set_input("grip",1.0);await frames(15)
	check("Pink light stick is the existing grabbable line",game.pickups[1].picked_up_object==stick and stick.get_script().resource_path.ends_with("line_body.gd"))
	game.place_player(Vector3(16.5,-17.94,-.4));await frames(10)
	hand_at(right,Vector3(16.65,-16.8,.7));await frames(20)
	var lamp: OmniLight3D=stick.get_node("InteractionLight")
	check("Carried light follows the stick inside the passage",lamp.is_visible_in_tree() and lamp.global_position.distance_to(stick.global_position)<.001 and lamp.shadow_enabled)
	await photograph("tunnel-lit.png",Vector3(16.5,-16.35,-1.25),Vector3(16.5,-16.6,3.6),78)
	lamp.hide()
	await photograph("tunnel-unlit.png",Vector3(16.5,-16.35,-1.25),Vector3(16.5,-16.6,3.6),78)
	lamp.show()
	check("Walk through the dark passage carrying the light",await move_to(Vector3(16.5,-18,4.5)))
	right.set_input("grip",0.0);await frames(10)
	check("Released light stick switches off",not lamp.visible)
	for prop in content.data.floors[3].props:
		if prop.kind=="work_light": check("Reduced work light: "+prop.id,is_equal_approx(content.props["3/"+prop.id].get_node("Prefab").beam_energy,1.2))
	var original: Transform3D=plan.transform
	var measured_before: float=plan.measured_length
	print("[void] measurement before editor move: ",measured_before," endpoints ",plan.point_a.position,plan.point_b.position)
	setting.apply_grid_config({"parts":{"FloorPlanTable":{"position":[16.2,0,-2.7],"rotation":[0,90,0]}}})
	await frames(4)
	print("[void] measurement after editor move: ",plan.measured_length," endpoints ",plan.point_a.position,plan.point_b.position)
	check("Rotating the editable plan keeps its local measurement",absf(plan.measured_length-measured_before)<.02)
	plan.transform=original
	var copy: Node3D=load("res://commons/void/lines_setting_out.tscn").instantiate()
	game.add_child(copy)
	copy.apply_grid_config({"only_parts":["FloorPlanTable"],"parts":{"FloorPlanTable":{"position":[0,0,0],"rotation":[0,90,0]}}})
	await frames(5)
	check("Editor copy owns its own independent measuring points",copy.get_child_count()==1 and copy.get_node("FloorPlanTable").point_a!=plan.point_a)
	copy.queue_free();await frames(5)
	game.place_player(game.spawn_for(2));await frames(20)
	game.place_player(game.spawn_for(3));await frames(20)
	check("Streamed return preserves the solved gate",gate.unlocked and gate.gate.position.y>2.75)
	game.die("Lines retry");await wait_for_recovery(0)
	check("Retry returns inside the entry and keeps the open route",game.checkpoint==3 and gate.unlocked and absf(game.body.global_position.x)<1 and game.body.global_position.z>4)
	game.queue_free();await frames(15)
	for tracker in [head,left,right]: XRServer.remove_tracker(tracker)

func photograph(filename: String, at: Vector3, target: Vector3, field_of_view := 75.0) -> void:
	if DisplayServer.get_name()=="headless": return
	# An independent camera would otherwise photograph the inside of the avatar.
	# Hide only the rig while capturing; real held artifacts remain in the room.
	var rig: Node3D=game.get_node("XROrigin3D")
	var shown: bool=rig.visible
	rig.hide()
	await super.photograph(filename,at,target,field_of_view)
	rig.visible=shown
