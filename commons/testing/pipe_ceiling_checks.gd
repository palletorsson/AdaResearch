extends RefCounted
const Canopy = preload("res://commons/primitives/pipes/pipe_canopy.gd")
class Press extends RefCounted:
	var event_type := 2

func run(tree: SceneTree, station: Node3D, camera: Camera3D) -> void:
	var app = station.specimen.ceiling_application
	var canopy = app.canopy
	var drawing: Array = station.specimen.strokes.duplicate(true)
	var routes: Dictionary = station.specimen.patch_application.manager.routes.duplicate(true)
	var finite := true
	var clear := true
	var budget := true
	var deterministic := true
	for mode in 3:
		for count in Canopy.COUNTS:
			for radius in Canopy.RADII:
				var data := Canopy.make_layout(mode,count,radius)
				deterministic = deterministic and data == Canopy.make_layout(mode,count,radius)
				budget = budget and data.paths.size() <= 22
				for path in data.paths:
					budget = budget and path.points.size() <= 97
					for p in path.points:
						var point := Vector3(p[0],p[1],p[2])
						finite = finite and point.is_finite()
						clear = clear and point.y-radius >= 5.8 and absf(point.x)+radius < 8.0 and absf(point.z)+radius < 8.0
	tree.check("all 27 canopy layouts repeat deterministically with finite paths",finite and deterministic)
	tree.check("all canopy controls retain overhead and side-aisle clearance",clear)
	tree.check("canopy generation stays inside path and sample budgets",budget)
	var rendered := true
	for mode in 3:
		canopy.rule = mode; canopy.count_index = 2; canopy.radius_index = 2; canopy.rebuild()
		for run in canopy.layout.pipe_systems.values():
			var mesh: ArrayMesh = run.skin.mesh
			var arrays := mesh.surface_get_arrays(0)
			rendered = rendered and arrays[Mesh.ARRAY_INDEX].size() > 0
			for vertex in arrays[Mesh.ARRAY_VERTEX]:
				rendered = rendered and vertex.is_finite() and vertex.y > 5.8
	tree.check("each maximum-density ceiling produces actual hollow sweep meshes above the work",rendered)
	# Check nearest sampled centrelines at the densest and widest weave, including
	# off-centre approaches. The sweep samples the very same positions.
	var weave := Canopy.make_layout(1,7,0.42)
	var closest := INF
	for a in 7:
		for b in 7:
			var first: Array = weave.paths[a*2].points
			var second: Array = weave.paths[b*2+1].points
			for i in range(first.size()-1):
				var p := vec(first[i]); var q := vec(first[i+1])
				if absf(p.x-(-5.4+1.8*b)) > 2.0: continue
				for j in range(second.size()-1):
					var r := vec(second[j]); var s := vec(second[j+1])
					if absf(r.z-(-5.4+1.8*a)) > 2.0: continue
					var pair := Geometry3D.get_closest_points_between_segments(p,q,r,s)
					closest = minf(closest,pair[0].distance_to(pair[1]))
	tree.check("thickest densest woven pipes do not intersect",closest > 0.84)
	app.control(4)
	var old_gen: int = canopy.generation
	app.buttons[3].pointer_event(Press.new())
	tree.check("finish control changes actual material without remeshing",canopy.finish == 1 and canopy.generation == old_gen and canopy.layout.pipe_systems.values()[0].skin.material_override.roughness < 0.2)
	app.buttons[0].pointer_event(Press.new())
	app.buttons[1].pointer_event(Press.new())
	app.buttons[2].pointer_event(Press.new())
	tree.check("rule diameter and repetition pointer controls rebuild the canopy",canopy.rule == 2 and canopy.radius_index == 2 and canopy.count_index == 2)
	for i in 3: await tree.physics_frame
	var button = app.buttons[0]
	var ray := PhysicsRayQueryParameters3D.create(button.to_global(Vector3(0,0,1)),button.global_position,(1<<20)|(1<<22))
	var hit := station.get_world_3d().direct_space_state.intersect_ray(ray)
	tree.check("ceiling controls have reachable native pointer colliders",not hit.is_empty() and hit.collider == button)
	app.buttons[4].pointer_event(Press.new())
	tree.check("canopy reset leaves drawing and live patch intact",drawing == station.specimen.strokes and routes == station.specimen.patch_application.manager.routes and canopy.rule == 1 and canopy.radius_index == 1 and canopy.count_index == 1 and canopy.finish == 0)
	old_gen = canopy.generation
	for i in 8: await tree.process_frame
	tree.check("idle canopy does not rebuild its geometry",canopy.generation == old_gen)
	for mode in [1,0,2]:
		canopy.rule = mode; canopy.rebuild(); app.rehang(); app.update_status()
		camera.global_position = app.to_global(Vector3(4.7,1.8,8.5))
		camera.look_at(app.to_global(Vector3(-0.6,6.8,-0.5)))
		for i in 12: await tree.process_frame
		await RenderingServer.frame_post_draw
		var label: String = Canopy.RULES[mode].to_lower()
		tree.check("native museum ceiling capture "+label,tree.root.get_texture().get_image().save_png(tree.OUT+"tube-ceiling-"+label+".png") == OK)
	app.control(4)

func vec(p: Array) -> Vector3:
	return Vector3(p[0],p[1],p[2])
