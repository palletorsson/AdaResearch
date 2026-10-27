extends "res://tools/probes/sine_yoke.gd"
## Find a clear route through existing solids, without moving the old exhibits.
func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out = arg.trim_prefix("--out=")
	Source.use_main_tower = true;scene = Node3D.new();root.add_child(scene);current_scene = scene
	var building: Node3D = load("res://commons/void/architecture.gd").new();building.stream_content = true;scene.add_child(building);building.content.load_floor(46);await tick(10)
	var world := building.get_world_3d().direct_space_state;var y: float = building.spec.levels[46];var capsule := CapsuleShape3D.new();capsule.radius = .24;capsule.height = 1.75
	var free: Dictionary = {};var obstacles: Dictionary = {}
	for ix in range(-38,39):
		for iz in range(-16,17):
			var p := Vector2i(ix,iz);var at := Vector3(ix*.5,y+.96,iz*.5);var query := PhysicsShapeQueryParameters3D.new();query.shape = capsule;query.transform.origin = at;query.collision_mask = 1;query.collide_with_areas = false
			var hits := world.intersect_shape(query,1);var floor_hit := world.intersect_ray(PhysicsRayQueryParameters3D.create(at-Vector3(0,.71,0),at-Vector3(0,1.11,0),1))
			if hits.is_empty() and not floor_hit.is_empty():free[p] = true
			elif not hits.is_empty() and ix in [-22,-21,-20,-19,-18,0]:obstacles[str(p)] = str(hits[0].collider.get_path())
	var start := Vector2i(-28,6);var end := Vector2i(32,-5);var queue: Array[Vector2i] = [start];var came: Dictionary = {start:start};var found := false
	while not queue.is_empty():
		var p: Vector2i = queue.pop_front()
		if p==end:found = true;break
		for d in [Vector2i(1,0),Vector2i(-1,0),Vector2i(0,1),Vector2i(0,-1)]:
			var next: Vector2i = p+d
			if free.has(next) and not came.has(next):came[next] = p;queue.append(next)
	var points: Array = []
	if found:
		var p := end;points.push_front([p.x*.5,p.y*.5])
		while p!=start:p = came[p];points.push_front([p.x*.5,p.y*.5])
	var report := {"passed":found,"path":points,"obstacles":obstacles,"scope":"Capsule/ground queries on actual existing main-floor solids. Proposed walking route, not a substitute for actual-player walking."}
	FileAccess.open(out.path_join("friction-route.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  "));print("MATTER_REFERENCE_RESULT ",JSON.stringify({"passed":found,"points":points.size()}));building.queue_free();await tick(4);quit(0 if found else 1)
