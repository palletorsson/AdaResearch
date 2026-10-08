extends SceneTree
## Actual endless-museum grid + actual XRTools rig. Does not emulate tracked input.
const BODY_PATH := "res://addons/godot-xr-tools/player/player_body.tscn"
const OUT := "res://doc/space/rotation-passages-2026-09-16"
var checks: Array = []
var failures: Array[String] = []
var cases: Array = []
var world: Node3D
var museum: Node3D
var grid: Node3D
var wall: Node3D
var body_scene: PackedScene

func _initialize() -> void: run.call_deferred()
func check(name: String, passed: bool, detail: Variant = null) -> void:
	checks.append({"name":name,"passed":passed,"detail":detail})
	if not passed: failures.append(name)
	print("[rotation-rides] ", "PASS " if passed else "FAIL ", name, " ", str(detail) if detail != null else "")
func tick() -> void:
	await physics_frame
	await process_frame
func xyz(v: Vector3) -> Array: return [v.x,v.y,v.z]
func station_named(id: String) -> Dictionary:
	for station: Dictionary in wall.stations:
		if station.id == id: return station
	return {}

func spawn_rig(feet: Vector3, offset := Vector3(0.28,0,-0.19), yaw := 0.63) -> Dictionary:
	var origin := XROrigin3D.new()
	origin.name = "RideTestOrigin"
	origin.rotation.y = yaw
	origin.position = feet - origin.basis * Vector3(offset.x,0,offset.z)
	var eye := XRCamera3D.new()
	eye.name = "Camera"
	eye.position = Vector3(offset.x,1.7,offset.z)
	origin.add_child(eye)
	var body: CharacterBody3D = body_scene.instantiate()
	body.set("player_calibrate_height",false)
	body.set("eye_forward_offset",0.0)
	origin.add_child(body)
	world.add_child(origin)
	for i in range(45): await tick()
	return {"origin":origin,"eye":eye,"body":body}

func dispose_rig(rig: Dictionary) -> void:
	rig.origin.queue_free()
	for i in range(3): await tick()
	for id in ["X","Z"]:
		var deck: Node3D=station_named(id).ride_deck
		check(id+" discards freed rig references",deck.riders.all(func(r):return is_instance_valid(r)))

func test_complete_ride(id: String) -> void:
	wall.set_crossing_pose()
	var station := station_named(id)
	var deck: Node3D = station.ride_deck
	var start := deck.global_position
	var expected_motion: Vector3 = station.node.global_basis * (Vector3(0,3,7) if id == "X" else Vector3(7,3,0))
	var rig := await spawn_rig(start + Vector3.UP*0.01)
	var body: CharacterBody3D = rig.body
	var eye: XRCamera3D = rig.eye
	check(id+" natural boarding at held dock", body in deck.riders, {"feet":xyz(body.global_position),"deck":xyz(deck.global_position)})
	check(id+" lower dock meets floor", absf(start.y)<0.025,start.y)
	var body_start := body.global_position
	var eye_start := eye.global_position
	var eye_basis := eye.global_basis
	var local_eye := eye.transform
	var previous_deck := deck.global_position
	var previous_eye := eye.global_position
	var previous_tick := Engine.get_physics_frames()
	var max_body_error := 0.0
	var max_eye_error := 0.0
	var max_height_error := 0.0
	var max_eye_local_error := 0.0
	var min_upright := 1.0
	var max_heading_error := 0.0
	var max_step_error := 0.0
	var max_invariant_error := 0.0
	var lowest_deck := start.y
	var highest_deck := start.y
	var held_rider := true
	var reached_far := false
	var returned := false
	var samples: Array = []
	wall.start_rides()
	for i in range(900):
		await tick()
		var displacement := deck.global_position-start
		max_body_error=maxf(max_body_error,body.global_position.distance_to(body_start+displacement))
		max_eye_error=maxf(max_eye_error,eye.global_position.distance_to(eye_start+displacement))
		max_height_error=maxf(max_height_error,absf((eye.global_position.y-body.global_position.y)-(eye_start.y-body_start.y)))
		max_eye_local_error=maxf(max_eye_local_error,eye.position.distance_to(local_eye.origin))
		min_upright=minf(min_upright,eye.global_basis.y.dot(Vector3.UP))
		max_heading_error=maxf(max_heading_error,eye.global_basis.z.distance_to(eye_basis.z))
		var delta_steps:=Engine.get_physics_frames()-previous_tick
		var allowed: float=4.0*deg_to_rad(wall.turn_speed)*float(delta_steps)/float(Engine.physics_ticks_per_second)+0.01
		max_step_error=maxf(max_step_error,eye.global_position.distance_to(previous_eye)-allowed)
		max_invariant_error=maxf(max_invariant_error,absf(displacement.x if id=="X" else displacement.z))
		lowest_deck=minf(lowest_deck,deck.global_position.y)
		highest_deck=maxf(highest_deck,deck.global_position.y)
		held_rider=held_rider and body in deck.riders
		if deck.global_position.distance_to(start+expected_motion)<0.015: reached_far=true
		if reached_far and deck.global_position.distance_to(start)<0.015: returned=true
		if i%4==0:
			samples.append({"tick":Engine.get_physics_frames(),"deck":xyz(deck.global_position),"body":xyz(body.global_position),"eye":xyz(eye.global_position),"aboard":body in deck.riders})
		previous_deck=deck.global_position
		previous_eye=eye.global_position
		previous_tick=Engine.get_physics_frames()
		if returned: break
	check(id+" arrives at opposite upper dock",reached_far)
	check(id+" returns along upper arc",returned and lowest_deck>=start.y-0.035,{"lowest":lowest_deck,"highest":highest_deck})
	check(id+" remains naturally supported throughout",held_rider)
	check(id+" actual body carried exactly once",max_body_error<0.04,max_body_error)
	check(id+" actual camera carried exactly once",max_eye_error<0.04,max_eye_error)
	check(id+" keeps standing eye height",max_height_error<0.015,max_height_error)
	check(id+" keeps tracked local camera pose",max_eye_local_error<0.00001,max_eye_local_error)
	check(id+" never pitches or rolls camera",min_upright>0.99999,min_upright)
	check(id+" never changes camera heading",max_heading_error<0.00001,max_heading_error)
	check(id+" no instantaneous destination jump",max_step_error<0.015,max_step_error)
	check(id+" orbit preserves "+("x" if id=="X" else "z"),max_invariant_error<0.00001,max_invariant_error)
	cases.append({"id":id,"kind":"outbound_return","samples":samples,"body_error_m":max_body_error,"eye_error_m":max_eye_error,
		"roomscale_offset":xyz(local_eye.origin),"expected_displacement":xyz(expected_motion)})
	await dispose_rig(rig)
	wall.set_crossing_pose()

func test_departure(id: String, jump: bool) -> void:
	wall.set_crossing_pose()
	var deck: Node3D=station_named(id).ride_deck
	var rig:=await spawn_rig(deck.global_position+Vector3.UP*0.01)
	var body: CharacterBody3D=rig.body
	wall.start_rides()
	for i in range(65): await tick()
	check(id+" departure starts aboard",body in deck.riders)
	var release_start:=body.global_position
	if jump:
		body.request_jump()
	else:
		var pose:=body.global_transform
		# Step off along the axis invariant of this orbit, onto the surrounding bank.
		pose.origin-=(Vector3.RIGHT if id=="X" else Vector3.BACK)*2.1
		body.teleport(pose)
	var release_position:=body.global_position
	var deck_start:=deck.global_position
	var rose:=false
	for i in range(20):
		await tick()
		rose=rose or body.global_position.y>release_start.y+0.04
	check(id+(" jump" if jump else " step-off")+" releases immediately",not body in deck.riders)
	if jump: check(id+" true jump rises",rose)
	else:
		var direction:=(Vector3.BACK if id=="X" else Vector3.RIGHT)
		check(id+" stepped-off body no longer follows deck",absf((body.global_position-release_position).dot(direction))<0.05,xyz(body.global_position-release_position))
	check(id+" empty deck continues",deck.global_position.distance_to(deck_start)>0.1)
	await dispose_rig(rig)
	wall.set_crossing_pose()

func test_invalid_contact(id: String, below: bool) -> void:
	wall.set_crossing_pose()
	var deck: Node3D=station_named(id).ride_deck
	var rig:=await spawn_rig(deck.global_position+Vector3.UP*0.01)
	var body: CharacterBody3D=rig.body
	var pose:=body.global_transform
	pose.origin+=(Vector3.DOWN*1.4 if below else Vector3.RIGHT*1.35)
	body.teleport(pose)
	# Freeze the rig, keeping an actual collision body in the detector; no gravity
	# or floor recovery should turn an invalid below/side contact into boarding.
	body.set_physics_process(false)
	for i in range(8): await tick()
	check(id+(" below" if below else " side")+" contact does not ride",not body in deck.riders)
	var before:=body.global_position
	wall.start_rides()
	for i in range(65): await tick()
	check(id+(" below" if below else " side")+" contact is not dragged",body.global_position.distance_to(before)<0.01,xyz(body.global_position-before))
	await dispose_rig(rig)
	wall.set_crossing_pose()

func test_standing_clearance() -> void:
	wall.set_crossing_pose()
	wall.set_physics_process(false)
	var capsule:=CapsuleShape3D.new()
	capsule.radius=0.25;capsule.height=1.8
	var query:=PhysicsShapeQueryParameters3D.new()
	query.shape=capsule
	query.collision_mask=1
	query.margin=0.001
	var collisions: Array=[]
	var sampled:=0
	for step in range(91):
		var progress:=float(step)/90.0
		for id in ["X","Z"]:
			var station:=station_named(id)
			wall._apply(station,float(station.crossing)-180.0*progress)
			station.panel.get_node("Body").force_update_transform()
		wall._place_decks(progress)
		await tick()
		for id in ["X","Z"]:
			var deck: Node3D=station_named(id).ride_deck
			for x in [-0.55,0.0,0.55]:
				for z in [-0.55,0.0,0.55]:
					var feet:=deck.to_global(Vector3(x,0.02,z))
					query.transform=Transform3D(Basis.IDENTITY,feet+Vector3.UP*0.9)
					var hits:=world.get_world_3d().direct_space_state.intersect_shape(query,8)
					sampled+=1
					if not hits.is_empty():
						collisions.append({"id":id,"progress":progress,"feet":xyz(feet),"colliders":hits.map(func(h):return str(h.collider.get_path()))})
	check("standing capsule clearance at centre and eight deck offsets",collisions.is_empty(),{"poses":sampled,"collisions":collisions.size()})
	cases.append({"kind":"standing_clearance","poses":sampled,"capsule_radius":0.25,"capsule_height":1.8,"offsets":[-0.55,0,0.55],"contacts":collisions})
	wall.set_crossing_pose()
	wall.set_physics_process(true)

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	body_scene=load(BODY_PATH)
	world=Node3D.new();root.add_child(world);current_scene=world
	museum=load("res://commons/scenes/endless_museum.tscn").instantiate()
	var control:="res://ada_run/rotation-rides-probe-control.json"
	FileAccess.open(control,FileAccess.WRITE).store_string(JSON.stringify({"first_chapter":"transformation","first_map":"Trans_Rotation","grid_pack":1,"dollhouse":0}))
	museum.set("EM_CONTROL",control);museum.set("_overrides_path",control+".unused")
	museum.set("_cartridge_read_enabled",false)
	museum.set("start_chapter","transformation");museum.set("start_map","Trans_Rotation")
	var layout: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://commons/data/em_layout.json"))
	layout.get_or_add("stream",{})["bodies"]=1;museum.set("_layout",layout)
	world.add_child(museum)
	await create_timer(3).timeout
	museum.set_process(false);museum.set_physics_process(false)
	for n in museum.find_children("*","Node3D",true,false):
		if n.name=="SimGrid_Trans_Rotation":grid=n;break
	if grid!=null:
		for n in grid.find_children("*","Node3D",true,false):
			if n.get_script()!=null and n.get_script().resource_path.ends_with("wall_crossings.gd"):wall=n;break
	check("actual endless museum contains rotation hall",grid!=null and wall!=null)
	if wall==null:quit(1);return
	wall.crossing_hold=0.7;wall.turn_speed=60.0
	wall.set_crossing_pose()
	check("X and Z have level endpoint decks",station_named("X").has("ride_deck") and station_named("Z").has("ride_deck"))
	if not station_named("X").has("ride_deck"):quit(1);return
	await test_complete_ride("X")
	await test_complete_ride("Z")
	await test_departure("X",true)
	await test_departure("Z",false)
	await test_invalid_contact("X",false)
	await test_invalid_contact("Z",true)
	await test_standing_clearance()
	var report:={"actual_endless_museum":true,"map":"Trans_Rotation","checks":checks,"failures":failures,"cases":cases,
		"headset_verified":false,"limits":["Actual XRTools rig and collision tests; no tracked headset or comfort test", "Accelerated test timing: 60 deg/s, 0.7 second holds", "Runtime body/camera trajectory is tested, not every possible visitor position on the deck"]}
	FileAccess.open(OUT+"/rotation-rides-checks.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("[rotation-rides] TOTAL ",checks.size()," checks; ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)
