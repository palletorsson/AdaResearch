extends SceneTree
## Check the changed architectural cover independently of live user placements.
var checks: Array[Dictionary] = []
var out := "user://"

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out=arg.trim_prefix("--out=")
	run.call_deferred()

func check(label: String, passed: bool) -> void:
	checks.append({"name":label,"passed":passed})

func run() -> void:
	var cover: Node3D=load("res://commons/void/polyhedra_walk_up.tscn").instantiate()
	cover.rotation_degrees.y=90
	root.add_child(cover)
	for i in range(4): await physics_frame
	var deck: Node3D=cover.get_node("ShaftCover")
	var mesh: MeshInstance3D=deck.find_children("*","MeshInstance3D",true,false)[0]
	var bounds: AABB=mesh.global_transform*mesh.get_aabb()
	check("Architectural cover has no cube prefab",deck.scene_file_path.is_empty() and cover.get_meta("construction_definition")=="wp_shaft_cover")
	check("Cover keeps the five by six metre footprint and one metre top",bounds.size.is_equal_approx(Vector3(5,1,6)) and is_equal_approx(bounds.end.y,1))
	var space := cover.get_world_3d().direct_space_state
	for x in range(6):
		for z in range(7):
			var p := Vector3(lerpf(bounds.position.x+.02,bounds.end.x-.02,x/5.0),1,lerpf(bounds.position.z+.02,bounds.end.z-.02,z/6.0))
			var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(p+Vector3.UP*.05,p-Vector3.UP*.05,1))
			check("Solid shaft cover sample %d,%d"%[x,z],not hit.is_empty() and deck.is_ancestor_of(hit.collider))
	var ramps := 0
	for ramp in cover.get_children():
		if not ramp.has_node("OriginalWP"): continue
		ramps+=1
		for z in [-.8,0,.8]:
			var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(ramp.to_global(Vector3(0,2,z)),ramp.to_global(Vector3(0,-.1,z)),1))
			check(str(ramp.name)+" slope "+str(z),not hit.is_empty() and absf(ramp.to_local(hit.position).y-(z+1)*.5)<.015)
	check("Nine six-vertex wp ramps remain",ramps==9)
	var passed := checks.all(func(item: Dictionary) -> bool: return item.passed)
	FileAccess.open(out.path_join("polyhedra-cover-checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":passed,"checks":checks,"scope":"Actual shaft-cover scene and physics, independent of user-edited floor placement."},"\t"))
	cover.queue_free()
	await process_frame
	print("Polyhedra cover: ",checks.size()," checks; passed=",passed)
	quit(0 if passed else 1)
