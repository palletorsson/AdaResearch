extends "res://tools/probes/drone_comparison_museum.gd"
var appearance_completed:=false

func choose(control:Node3D,mode:int,pointer:Node3D)->void:
	var at:=control.to_global(Vector3(0,0,.03))
	var end:Vector3=at+control.global_basis*Vector3(0,(mode/2.0-control.get_normalized_value())*control.TRAVEL,0)
	var face:Node3D=control.get_node("Face")
	XRToolsPointerEvent.pressed(pointer,face,at)
	XRToolsPointerEvent.moved(pointer,face,end,at)
	XRToolsPointerEvent.released(pointer,face,end)

func landing_checks()->void:
	await super.landing_checks()
	var h:=find_scene("/drone_comparison.gd")
	if h==null:return
	var control:Node3D=h.display_selector
	var foot:=h.to_global(Vector3(-6.5,0,-.55))
	var floor:=floor_at(foot)
	check("Display selector is reachable at hand height",not floor.is_empty() and control.global_position.y-floor.position.y>1.0 and control.global_position.y-floor.position.y<1.4)
	var capsule:=CapsuleShape3D.new();capsule.radius=.24;capsule.height=1.7
	var query:=PhysicsShapeQueryParameters3D.new();query.shape=capsule;query.collision_mask=1;query.transform.origin=foot+Vector3.UP*.9
	check("Visitor can stand in front of the display selector",hall.get_world_3d().direct_space_state.intersect_shape(query).is_empty())
	var ray:=PhysicsRayQueryParameters3D.create(control.to_global(Vector3(.05,0,.4)),control.to_global(Vector3(.05,0,-.04)),(1<<20)|(1<<22))
	var hit:=hall.get_world_3d().direct_space_state.intersect_ray(ray)
	check("Selector face has a real pointer target",not hit.is_empty() and hit.collider==control.get_node("Face"))
	var pointer:=Node3D.new();root.add_child(pointer)
	h.point.on_desktop_grab(pointer);h.point.global_position=h.to_global(h.HOME+Vector3(1,.3,.4))
	await create_timer(.45).timeout
	h.playing=false;await create_timer(.1).timeout
	# Freeze only integration for three photographs of exactly the same pose.
	# Runtime has no pause action here. Display, hand input and guide updates run.
	h.guides=false
	var saved:Array=[]
	for f in h.flights:
		for d in f.drones:saved.append([d.get_instance_id(),d.transform,d.velocity])
	for mode in range(3):
		choose(control,mode,pointer);await create_timer(.1).timeout
		check("Museum pointer selects view "+str(mode),h.appearance==mode and h.body_views[0][mode].visible)
		var current:Array=[]
		for f in h.flights:
			for d in f.drones:current.append([d.get_instance_id(),d.transform,d.velocity])
		check("Photograph view "+str(mode)+" preserves the exact agent state",current==saved)
		await snapshot(["drone-view","point-view","light-view"][mode],h.to_global(Vector3(-5.0,2.3,0)),h.to_global(Vector3(.4,2.05,0)),100)
	await snapshot("appearance-control",h.to_global(Vector3(-7.0,1.7,-1.1)),h.to_global(Vector3(-5.8,1.25,-.45)),62)
	h.playing=true;h.guides=true
	var start:Vector3=h.flights[0].drones[0].global_position
	h.point.global_position=h.to_global(h.HOME+Vector3(-1,-.1,-.4))
	await create_timer(.5).timeout
	check("Light mode resumes the same moving agents",h.flights[0].drones[0].global_position.distance_to(start)>.1)
	check("Point control still moves both targets in light mode",h.target_offset.distance_to(Vector3(-1,-.1,-.4))<.01)
	await snapshot("light-guidance",h.to_global(Vector3(-4.8,6.5,.1)),h.to_global(Vector3(0,1.5,0)),105)
	h.point.action();await create_timer(.2).timeout
	check("Point trigger still hides guidance in light mode",not h.guides and not h.beacons[0].visible)
	h.point.on_desktop_drop(pointer);await create_timer(2).timeout
	check("Drop returns point while preserving selected appearance",h.point.position.distance_to(h.HOME)<.01 and h.appearance==2)
	observations.comparison_photographs="Integration paused for three equal-state views; resumed and verified in light mode."
	appearance_completed=true

func finish()->void:
	var result={"passed":appearance_completed and failures.is_empty(),"checks":checks,"failures":failures,"observations":observations,"scope":"Production museum; synthetic pointer/pickup/action, exact-state visual comparison and resumed flight. Physical headset and Quest untested."}
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
	quit(0 if result.passed else 1)
