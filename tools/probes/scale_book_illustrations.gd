extends "res://tools/probes/transformation_encounters.gd"
## Capture the existing scale encounter; supplied desktop grab and selected camera positions.
var study: Node3D
var actor: CharacterBody3D

func doorway_photo(name: String) -> void:
	var opening: Vector3 = study.room.to_global(Vector3(study.EXIT_X,0,study.ROOM_DEPTH))
	# Same world-space eye height, distance, orientation and FOV in both states.
	await snapshot(name, opening+Vector3(0,1.65,-2.5), opening+Vector3(0,1.2,0), 70)

func landing_checks() -> void:
	study = find_scene("/drink_me_room.gd")
	actor = museum.get("_player")
	check("scale encounter and museum body loaded",study != null and actor != null)
	if study == null or actor == null: return
	actor.set_process(false);actor.set_physics_process(false)
	var body_scale: Vector3 = actor.global_basis.get_scale()
	var fixed_frame: Transform3D = study.witness.global_transform
	observations["anchor"] = xyz(study.global_position)
	observations["door_camera"] = {"eye_height_m":1.65,"distance_from_opening_m":2.5,"target_height_m":1.2,"fov":70}
	await snapshot("room-before",study.to_global(Vector3(0,1.65,0.25)),study.to_global(Vector3(0,1.4,2.4)),70)
	await doorway_photo("door-before")
	var query := PhysicsShapeQueryParameters3D.new()
	var capsule := CapsuleShape3D.new();capsule.radius=0.22;capsule.height=1.6
	query.shape=capsule;query.collision_mask=1;query.exclude=[actor.get_rid()]
	query.transform.origin=study.room.to_global(Vector3(1.2,0,3.5))+Vector3.UP*0.81
	query.motion=Vector3(0,0,1)
	check("0.44 m by 1.6 m capsule cannot cross tiny door",hall.get_world_3d().direct_space_state.cast_motion(query)[0] < 0.99)
	actor.global_position=study.to_global(Vector3(0,0.04,0.6))
	var pointer: Node = actor.find_child("DesktopPointer",true,false)
	if pointer == null:
		pointer=load("res://commons/scenes/DesktopInteractionPointer.gd").new();actor.add_child(pointer)
	pointer.set_process(false);pointer.set_physics_process(false)
	camera.global_position=actor.global_position+Vector3.UP*1.6
	camera.look_at(study.bottle.global_position);camera.current=true
	pointer.set("_camera",camera)
	var grabbable: Node3D=pointer.call("_find_grabbable")
	check("desktop pointer finds the real bottle",grabbable==study.bottle)
	if grabbable != study.bottle:return
	pointer.call("_grab_held",grabbable)
	for i in range(6):await physics_frame
	check("desktop pickup activates fourfold room scale",study.enlarged and study.room.scale.is_equal_approx(Vector3.ONE*4))
	check("bottle is consumed and hand released",not study.bottle.visible and study.bottle.collision_layer==0 and pointer.get("_held")==null)
	check("body keeps its scale",actor.global_basis.get_scale().is_equal_approx(body_scale))
	check("outer gold frame stays in place and at size",study.witness.global_transform.is_equal_approx(fixed_frame))
	var plate: Vector3 = study.table.to_global(study.landings[0])
	check("pickup places body just above the highest plate",actor.global_position.distance_to(plate+Vector3.UP*0.08)<0.02)
	observations["plate_top_world"]=xyz(plate)
	await snapshot("on-the-plate",actor.global_position+Vector3.UP*1.65,study.figure.to_global(Vector3(0,1.3,0)),70)
	await snapshot("serving-descent",actor.global_position+Vector3.UP*1.65,study.table.to_global(study.landings[5]),72)
	await doorway_photo("door-after")
	query.transform.origin=study.room.to_global(Vector3(1.2,0,3.8))+Vector3.UP*0.81
	query.motion=Vector3(0,0,4)
	check("same capsule clears enlarged door and fixed frame",hall.get_world_3d().direct_space_state.cast_motion(query)[0]>0.99)
	# Set height first: raising radius first clamps CapsuleShape3D height.
	capsule.height=6.4;capsule.radius=0.88
	observations["counterfactual_actual_capsule"]={"width":capsule.radius*2,"height":capsule.height}
	query.transform.origin=study.room.to_global(Vector3(1.2,0,4.0))+Vector3(0,3.24,-1.5)
	check("enlarged test body begins clear of solids",hall.get_world_3d().direct_space_state.intersect_shape(query).is_empty())
	check("fourfold capsule still cannot clear enlarged doorway",hall.get_world_3d().direct_space_state.cast_motion(query)[0]<0.99)
	observations["door_sizes_m"]={"before":[0.45,0.6],"after":[1.8,2.4],"fixed_frame":[1.8,2.4]}
	observations["capsule_sizes_m"]={"unchanged":[0.44,1.6],"fourfold":[1.76,6.4]}

func finish() -> void:
	var result := {"room":map_id,"checks":checks,"failures":failures,"observations":observations,"passed":failures.is_empty(),"scope":"Isolated production museum; supplied desktop grab, doorway capsule sweeps and selected native views. Descent not rewalked. No runtime source or map changes. Headset and learner experience untested."}
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
	print("SCALE ILLUSTRATIONS ",checks.size()-failures.size(),"/",checks.size())
	quit(0 if failures.is_empty() else 1)
