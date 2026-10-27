extends "res://tools/probes/transformation_walkability.gd"
## Focused native collision/geometry evidence for the editable width comparison.

func band_box(band: Dictionary) -> AABB:
	var box: AABB
	var first := true
	for cube: Node3D in band.cubes:
		var mesh: MeshInstance3D = cube.get_child(0)
		var bounds: AABB = mesh.global_transform * mesh.get_aabb()
		box = bounds if first else box.merge(bounds)
		first = false
	return box

func photo(name: String, at: Vector3, target: Vector3) -> void:
	lens.global_position = at + Vector3.UP * building.spec.levels[16]
	lens.look_at(target + Vector3.UP * building.spec.levels[16])
	await frames(4)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join(name + ".png"))

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out = arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(out)
	Source.use_main_tower = true
	scene = Node3D.new();root.add_child(scene);current_scene=scene
	building=load("res://commons/void/architecture.gd").new();building.stream_content=true;scene.add_child(building)
	building.content.load_floor(16)
	var shown: Array[int]=[16];building.show_floor_window(shown)
	root.size=Vector2i(1600,1000)
	var env=WorldEnvironment.new();env.environment=Environment.new()
	env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color("242731")
	env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color=Color("d7dfef");env.environment.ambient_light_energy=.7;scene.add_child(env)
	var light=DirectionalLight3D.new();light.rotation_degrees=Vector3(-55,-35,0);light.light_energy=1.8;scene.add_child(light)
	lens=Camera3D.new();lens.fov=73;scene.add_child(lens);lens.current=true
	await frames(50)
	check("real Jolt solver",ProjectSettings.get_setting("physics/3d/physics_engine")=="Jolt Physics")
	check("standard 42 by 18 floor and six metre storey",building.spec.width==42 and building.spec.depth==18 and building.spec.storey_height==6)
	var original=exhibit(16,"angle-bands")
	var wide=exhibit(16,"z-wide")
	var narrow: Dictionary=original.bands.filter(func(b):return b.id=="Z")[0]
	var broad: Dictionary=wide.bands[0]
	check("four original axis studies retained",original.bands.size()==4 and original.columns==1)
	check("independent two-column Z specimen",wide!=original and wide.single_axis=="Z" and wide.bands.size()==1 and wide.columns==2 and broad.id=="Z")
	check("six rows and identical 18 degree increments",original.rows==6 and wide.rows==6 and original.row_angle_step==18 and wide.row_angle_step==18)
	check("six control cubes and twelve comparison cubes",narrow.cubes.size()==6 and broad.cubes.size()==12)
	for row in range(6):
		var control: Node3D=narrow.cubes[row]
		for column in range(2):
			var cube: Node3D=broad.cubes[row*2+column]
			check("row %d col %d: same 2.04m mesh and collider" % [row,column],cube.get_child(0).mesh.size.is_equal_approx(Vector3.ONE*2.04) and cube.get_node("Body").get_child(0).shape.size.is_equal_approx(Vector3.ONE*2.04))
			check("row %d col %d: exact same world rotation and height" % [row,column],cube.global_basis.is_equal_approx(control.global_basis) and absf(cube.global_position.y-control.global_position.y)<.001)
	check("two metre lateral centre spacing",broad.cubes[0].global_position.distance_to(broad.cubes[1].global_position)>1.999 and broad.cubes[0].global_position.distance_to(broad.cubes[1].global_position)<2.001)
	var narrow_bounds=band_box(narrow);var wide_bounds=band_box(broad)
	var gap:float=wide_bounds.position.z-narrow_bounds.end.z
	check("Z specimens have over half a metre between cube envelopes",gap>.5)
	for pair in [["single",narrow_bounds],["wide",wide_bounds]]:
		var box: AABB=pair[1]
		check(pair[0]+" stays inside floor and clear of both shaft openings",box.position.x> -7.5 and box.end.x<7.5 and box.position.z> -9 and box.end.z<9)
		check(pair[0]+" leaves standing headroom",box.end.y-building.spec.levels[16]+1.6<5.64)
	for entry in [["single",-3.7],["wide",.7]]:
		var y:float=building.spec.levels[16]
		var body=visitor(Vector3(-6.65,y+3.02,entry[1]))
		await frames(15)
		check(entry[0]+" is reachable from the shared real bank",await walk(body,Vector3(-4.4,y+3,entry[1]),3))
		check(entry[0]+" visitor stands on actual first cubes",body.is_on_floor() and absf(body.global_position.y-y-3)<.15)
		body.queue_free();await frames(4)
	# The unchanged full-height frame posts require a side approach at the
	# outboard courses. Verify a real capsule can clear the two first-cube posts.
	for z in [8.05,-7.95]:
		var y:float=building.spec.levels[16]
		var body=visitor(Vector3(-6.65,y+3.02,z));await frames(12)
		check("outer course entry can steer around frame post at z %.2f" % z,await walk(body,Vector3(-4.12,y+3,z),4))
		body.queue_free();await frames(4)
	original.body_comparison.auto_repeat=false;wide.body_comparison.auto_repeat=false
	for i in range(2200):
		if original.body_comparison.results.has("WIDE") and wide.body_comparison.results.has("WIDE"):break
		await frames(1)
	check("both widths complete bounded real collision trials on both specimens",original.body_comparison.results.has("WIDE") and wide.body_comparison.results.has("WIDE"))
	observations={"single":original.body_comparison.results,"double":wide.body_comparison.results,"cube_envelope_gap_m":gap,"scope":"Constant-forward capsules do not steer or jump; outcomes are observations, not a requirement to cross."}
	await photo("01-width-pair",Vector3(-11,5.5,4.5),Vector3(0,2.6,-1.5))
	await photo("02-overview",Vector3(-15,12,16),Vector3(0,1.8,0))
	await photo("03-on-bank",Vector3(-7.0,4.65,-1.5),Vector3(3,2.5,-1.5))
	FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed,"observations":observations,"scope":"Actual native main-floor geometry, Jolt CharacterBody3D collision, reachable launch banks and static renders. No physical headset or full desktop-input playthrough."},"  "))
	print("ROTATION_Z_WIDTH_RESULT ",failed.size())
	quit(0 if failed.is_empty() else 1)
