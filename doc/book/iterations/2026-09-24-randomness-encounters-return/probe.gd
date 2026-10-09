extends SceneTree
var checks: Array = []
var hall: Node3D
var cam: Camera3D
var out := "res://doc/book/iterations/2026-09-24-randomness-encounters-return/"
func _initialize() -> void: run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks.append({"pass":ok,"label":label})
	print(("PASS " if ok else "FAIL ") + label)
func shot(file: String, pos: Vector3, target: Vector3) -> void:
	cam.position = pos; cam.look_at(target); cam.make_current()
	for i in range(4): await process_frame
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(out + file) == OK, "native image " + file)
func reset_network(n: Node3D, s: int) -> void:
	seed(s);n.connections.clear();n.cell_birth_times.clear();n.cell_parents.clear()
	n.iteration_count = 0;n.initialize_grid();n.is_running = true
	if n._arrival_history != null:
		n._arrival_history.counts.clear();n._arrival_history.begun = false
		n._arrival_history.ready_to_watch = false;n._arrival_history.playing = false
	for i in range(21):
		n.update_simulation(0.016);n.update_visualization();n.iteration_count += 1
func run() -> void:
	hall = Node3D.new();hall.set_meta("em_map", "Noise_Perlin_Simplex");root.add_child(hall)
	var env := WorldEnvironment.new();var e := Environment.new()
	e.background_mode = Environment.BG_COLOR;e.background_color = Color(0.07,0.08,0.1)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR;e.ambient_light_color = Color.WHITE;e.ambient_light_energy = 0.75
	env.environment=e;hall.add_child(env)
	var light := DirectionalLight3D.new();light.rotation_degrees=Vector3(-45,-25,0);hall.add_child(light)
	var floor_mesh := MeshInstance3D.new();var plane := PlaneMesh.new();plane.size=Vector2(30,30);floor_mesh.mesh=plane
	var mat := StandardMaterial3D.new();mat.albedo_color=Color(0.28,0.29,0.31);floor_mesh.material_override=mat;hall.add_child(floor_mesh)
	cam=Camera3D.new();cam.position=Vector3(0,5,-10);cam.fov=58;hall.add_child(cam);cam.make_current()
	var a: Node3D=load("res://algorithms/randomness/simplexnoise/simplexnoise.tscn").instantiate()
	var b: Node3D=load("res://algorithms/randomness/perlinnoise/perlinnoise.tscn").instantiate()
	var config := {"seed":20260910,"size":8,"ramp":"shared","panel":"front","frequency":10,"amplitude":0.8,"persistence":0.5,"octaves":4}
	a.set_meta("config_study","compare");a.apply_grid_config(config.merged({"witness":"show"}));b.apply_grid_config(config.merged({"generator":"perlin"}))
	a.position=Vector3(-2.5,1.1,0);b.position=Vector3(2.5,1.1,0);hall.add_child(a);hall.add_child(b)
	for i in range(5): await process_frame
	var study: Node = a.find_child("PairStudy",true,false)
	check(study != null,"actual shared comparison built")
	if study == null: finish();return
	a.regenerate();b.regenerate()
	var seeds := [a.current_seed(),b.current_seed()]
	var values := [a.sample_at(-1,0.5),b.sample_at(-1,0.5)]
	var colors := [a.noise_field.noise_cubes[3].material_override.albedo_color,b.noise_field.noise_cubes[3].material_override.albedo_color]
	var initial_a: Dictionary=a.generator_readback();var initial_b: Dictionary=b.generator_readback()
	await shot("noise-relief.png",Vector3(0,5.0,-9),Vector3(0,1,0))
	study.toggle_view()
	check(a.current_seed()==seeds[0] and b.current_seed()==seeds[1],"VIEW preserves both regenerated seeds")
	check(a.generator_readback()==initial_a and b.generator_readback()==initial_b,"VIEW preserves both generator configurations")
	check(a.sample_at(-1,0.5)==values[0] and b.sample_at(-1,0.5)==values[1],"VIEW preserves sampled answers")
	check(a.noise_field.noise_cubes[3].material_override.albedo_color==colors[0] and b.noise_field.noise_cubes[3].material_override.albedo_color==colors[1],"VIEW preserves sample colours")
	var flat := true
	for work in [a,b]:
		for cube in work.noise_field.noise_cubes: flat = flat and is_zero_approx(cube.position.y)
	check(flat,"VIEW flattens every cube on both displays")
	await shot("noise-plate.png",Vector3(0,5.0,-9),Vector3(0,1,0))
	study.toggle_view()
	check(a.current_seed()==seeds[0] and b.current_seed()==seeds[1],"return to relief preserves the selected fields")
	study.match_pair()
	check(a.current_seed()==20260910 and b.current_seed()==20260910,"MATCH still restores the declared seeds")
	a.queue_free();b.queue_free();await process_frame
	var script: GDScript=load("res://algorithms/cellularautomata/ca_showcase/LineNetworkCA.gd")
	var plain: Node3D=script.new();hall.add_child(plain);plain.set_process(false);plain.visible=false
	var watched: Node3D=script.new();watched.apply_grid_config({"size":2.0,"study":"arrival"});hall.add_child(watched);watched.set_process(false)
	var history: Node=watched._arrival_history;history.set_process(false)
	check(plain._arrival_history==null,"ordinary placement adds no history or controls")
	for s in [11,42,190919]:
		reset_network(plain,s);reset_network(watched,s)
		check(plain.connections==watched.connections,"sparse arrival mode preserves original growth and parent links, seed %d"%s)
	check(history.strokes.multimesh.instance_count==watched.connections.size(),"one visible stroke per recorded connection")
	check(history.counts.size()==20,"twenty recorded growth stages")
	check(history.counts[0] < history.counts[-1],"later stages contain more connections")
	check(not watched.is_running,"simulation stops after capturing its history")
	history.observe_from(Vector3(0,1.7,-10));check(not history.begun,"distant visitor leaves first stage waiting")
	history.observe_from(Vector3(0,1.7,-2.5));check(history.begun and history.playing,"approach starts recorded growth")
	var fixed: Transform3D=watched.mesh_instance_lines.transform
	var first_vertices: PackedVector3Array=watched.immediate_mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	await shot("network-early.png",Vector3(1.8,1.7,-3.1),Vector3(0,1.2,0))
	for i in range(100): history.advance(0.1)
	check(not history.playing and history.stage==19,"growth history holds its completed stage")
	check(history.strokes.multimesh.visible_instance_count==history.counts[-1],"last stage displays every recorded stroke")
	check(watched.mesh_instance_lines.transform==fixed,"one fixed display frame preserves old line positions")
	var final_vertices: PackedVector3Array=watched.immediate_mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	check(final_vertices.slice(0,first_vertices.size())==first_vertices,"old vertices remain exactly in place as lines arrive")
	await shot("network-grown.png",Vector3(1.8,1.7,-3.1),Vector3(0,1.2,0))
	var replay_button: Node=history.find_child("Btn_0",true,false).get_node("InteractableAreaButton")
	replay_button.emit_signal("button_pressed",replay_button)
	check(history.strokes.multimesh.visible_instance_count==history.counts[0],"REPLAY hides later strokes without moving earlier ones")
	check(history.stage==0 and history.playing,"physical REPLAY button restarts the saved history")
	check(watched.immediate_mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]==first_vertices,"REPLAY restores identical first geometry")
	for i in range(100):history.advance(0.1)
	check(watched.immediate_mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]==final_vertices,"REPLAY restores identical final geometry")
	finish()
func finish() -> void:
	var f:=FileAccess.open(out+"native-checks.json",FileAccess.WRITE);f.store_string(JSON.stringify(checks,"  "));f.close()
	var failed:=0
	for c in checks:
		if not c["pass"]:failed+=1
	print("NATIVE RESULT %d / %d"%[checks.size()-failed,checks.size()]);quit(1 if failed else 0)
