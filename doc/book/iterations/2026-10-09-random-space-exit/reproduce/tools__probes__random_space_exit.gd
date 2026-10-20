extends "res://tools/probes/transformation_encounters.gd"
## Diagnose the real hall; candidate queries do not mutate its geometry.

func landing_checks() -> void:
	museum.call("flush_stamps")
	var stream: Node = museum.get("_portal_stream")
	var visitor: Node3D = museum.get("_player")
	visitor.set_physics_process(false)
	visitor.set_process(false)
	visitor.global_position = Vector3(-1000,0,-1000)
	await tick(); await tick()
	observations.exit = stream._authored_exit()
	observations.transform = str(hall.global_transform)
	observations.blockers = frame_hits(Vector3(6.5,0.05,14.5))
	var checks_at:=[]
	for distance in [0.0,0.1,1.15,2.1,2.2,2.3]:
		var p:=Vector3(6.5,1.05,14.5-distance)
		var hits:=[]
		for offset in [Vector3.ZERO,Vector3(0.3,0,0),Vector3(-0.3,0,0),Vector3(0,0,0.3),Vector3(0,0,-0.3)]:
			var h:=hall.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(p+offset+Vector3(0,0.15,0),p+offset-Vector3(0,0.2,0)))
			hits.append({"path":str(h.collider.get_path()),"point":xyz(h.position),"normal":xyz(h.normal)} if not h.is_empty() else {})
		checks_at.append({"distance":distance,"supported":stream._supported(p),"clear":stream._body_clear(p),"rays":hits})
	observations.approach=checks_at
	var capsule:=CapsuleShape3D.new();capsule.radius=0.3;capsule.height=1.8
	var cq:=PhysicsShapeQueryParameters3D.new();cq.shape=capsule;cq.transform.origin=Vector3(6.5,2.0,14.5)
	var obstruction:=[]
	for hit in hall.get_world_3d().direct_space_state.intersect_shape(cq,10):obstruction.append(str(hit.collider.get_path()))
	observations.exit_capsule_obstructions=obstruction
	var candidates := []
	var floors := []
	for z in range(11,17):
		for x in range(3,11):
			var at := Vector3(x+0.5,0.05,z+0.5)
			var surface: Vector3 = stream._nearest_floor(at+Vector3.UP)
			floors.append({"at":xyz(at),"surface":xyz(surface),"supported":stream._supported(surface)})
			for outset in [0.0,0.5,1.0,1.5,2.0]:
				var p := at+Vector3(0,0,outset)
				if not stream._portal_clear(p,PI) or not stream._supported(p+Vector3.FORWARD*2.3): continue
				var clear := true
				for distance in [0.0,0.4,0.8,1.15,1.6,2.0,2.3]:
					if not stream._body_clear(p+Vector3.FORWARD*distance): clear=false
				if clear: candidates.append({"cell":[x,z],"outset":outset,"door":xyz(p)})
	observations.candidates=candidates
	var raised:=[]
	for z in range(9,15):
		for x in range(3,11):
			for outset in [0.0,0.5,1.0,1.5,2.0]:
				var p:=Vector3(x+0.5,1.05,z+0.5+outset)
				if not stream._portal_clear(p,PI) or not stream._supported(p+Vector3.FORWARD*2.3):continue
				var clear:=true
				for distance in [0.0,0.4,0.8,1.15,1.6,2.0,2.3]:
					if not stream._body_clear(p+Vector3.FORWARD*distance):clear=false
				if clear:raised.append({"cell":[x,z],"outset":outset,"door":xyz(p)})
	observations.raised_candidates=raised
	observations.floors=floors
	root.size=Vector2i(1280,900)
	await snapshot("rear-overview",Vector3(3,5,10),Vector3(6.5,0.8,14.5),70)
	await snapshot("exit-before",Vector3(5,1.7,11),Vector3(6.5,1.0,15),70)
	check("diagnostic identifies blocked exit or valid authored door",not observations.exit.is_empty())

func frame_hits(p: Vector3) -> Array:
	var shape := BoxShape3D.new()
	shape.size=Vector3(2.18,2.76,0.44)
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape=shape
	query.transform=Transform3D(Basis.IDENTITY,p+Vector3(0,1.41,0))
	query.collision_mask=1
	var result:=[]
	for hit in hall.get_world_3d().direct_space_state.intersect_shape(query,32):
		var body: Node3D=hit.collider
		var owner: Node=body.shape_owner_get_owner(body.shape_find_owner(hit.shape))
		result.append({"path":str(body.get_path()),"position":xyz(body.global_position),"shape":str(owner.shape) if owner is CollisionShape3D else str(owner),"shape_transform":str(owner.global_transform) if owner is Node3D else ""})
	return result

func finish() -> void:
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"observations":observations,"scope":"Native hall geometry diagnostic; no continuous walk or headset claim."},"  "))
	quit(0 if failures.is_empty() else 1)
