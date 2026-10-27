extends SceneTree
var out := "user://"
var checks: Array = []
var failures: Array = []

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out = arg.trim_prefix("--out=")
	run.call_deferred()

func check(label: String, okay: bool) -> void:
	checks.append({"name":label,"passed":okay})
	if not okay: failures.append(label)
	print("SURFACE_TEST ",label," ",okay)

func frames(count: int) -> void:
	for i in count: await physics_frame
	await process_frame

func run() -> void:
	DirAccess.make_dir_recursive_absolute(out)
	var scene: PackedScene = load("res://commons/context/walkgrids/sine_space.tscn")
	for flat in [true,false]:
		var surface: Node3D = scene.instantiate()
		if surface.has_node("Camera3D"): surface.get_node("Camera3D").free()
		surface.space_size = Vector2(8,8)
		surface.resolution = 40
		surface.wave_amplitude = 0.0 if flat else .7
		surface.position = Vector3(0,-12,0)
		root.add_child(surface)
		await frames(5)
		var probe: Node3D = surface.get_node("SurfaceBallTest")
		check("walkable sine surface has recurring auto-trigger component",probe.auto_trigger)
		var samples: Array[Vector3] = []
		for x in [-1.0,0.0,1.0]:
			var y: float = surface.wave_amplitude*sin(x*surface.wave_frequency)*surface.height_scale
			samples.append(Vector3(x,y,0))
		probe.drop(surface,samples)
		var starts: Array[Vector3] = []
		for ball in probe.balls: starts.append(ball.global_position)
		var release_y: float = starts[0].y
		var highest := -INF
		for p in samples: highest = maxf(highest,surface.to_global(p).y)
		check("release is one horizontal plane three metres above highest sample",starts.all(func(p):return is_equal_approx(p.y,release_y)) and is_equal_approx(release_y-highest,3.0))
		check("all balls released at rest with equal material and radius",probe.balls.all(func(b):return b.linear_velocity==Vector3.ZERO and is_equal_approx(b.get_node("WhitePoint").mesh.radius,.10) and b.get_node("WhitePoint").material_override.albedo_color==Color.WHITE))
		await frames(180)
		check("physical points contact actual mesh collision",probe.contacts.has(surface.static_body.get_instance_id()))
		var travel := 0.0
		for i in probe.balls.size():
			var a := Vector2(starts[i].x,starts[i].z)
			var b := Vector2(probe.balls[i].global_position.x,probe.balls[i].global_position.z)
			travel = maxf(travel,a.distance_to(b))
		print("SURFACE_HORIZONTAL_TRAVEL flat=",flat," distance=",travel)
		if flat:
			check("flat surface keeps balls near their vertical drop positions",travel<.12 and probe.balls.all(func(b):return b.linear_velocity.length()<.2))
		else:
			check("curved sine surface redirects the same released balls",travel>.3)
		# Component contract: a visitor leaving supported feet triggers a new
		# batch. Main-tower tests separately use real desktop/XR jump inputs.
		var visitor := CharacterBody3D.new()
		visitor.collision_layer = 0
		visitor.collision_mask = 0
		visitor.add_to_group("player_body")
		root.add_child(visitor)
		visitor.global_position = surface.to_global(Vector3(0,.04,0))
		await frames(3)
		var before: int = probe.releases
		probe.cooldown = 0.0
		visitor.position.y += .7
		await frames(3)
		check("leaving the walkable sine surface automatically releases points",probe.releases==before+1)
		visitor.queue_free()
		surface.queue_free()
		await frames(5)
	FileAccess.open(out.path_join("surface-checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failed":failures,"scope":"Actual walkgrid sine collision, equal white rigid spheres, no launch impulses; flat vs curved negative-height surface."},"\t"))
	quit(0 if failures.is_empty() else 1)
