extends SceneTree
var checks := 0
var failures: Array[String] = []
var observations: Dictionary = {}
func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks+=1
	if not ok: failures.append(message)
	print("[rotation-study] ","PASS " if ok else "FAIL ",message)

func walk(world: Node3D, start: Vector3, direction: Vector3, distance: float) -> Dictionary:
	var walker := CharacterBody3D.new()
	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius=0.22
	shape.height=1.6
	collision.shape=shape
	collision.position.y=0.8
	walker.add_child(collision)
	walker.floor_snap_length=0.15
	world.add_child(walker)
	walker.global_position=start+Vector3.UP*0.02
	var lowest := start.y
	var stalled := 0
	var previous := 0.0
	var stop_reason := "time_budget"
	for i in range(ceili(distance/2*60)*3):
		await physics_frame
		walker.velocity=direction*2+Vector3.UP*(walker.velocity.y-9.8/60)
		walker.move_and_slide()
		lowest=minf(lowest,walker.position.y)
		var progress := (walker.global_position-start).dot(direction)
		stalled=stalled+1 if progress-previous<0.001 else 0
		previous=progress
		if progress>=distance:
			stop_reason="arrived"; break
		if stalled>60:
			stop_reason="blocked"; break
		if walker.position.y<start.y-3:
			stop_reason="fell"; break
	var travel := (walker.global_position-start).dot(direction)
	var result := {"travel":travel,"lowest":lowest,"y":walker.position.y,"stop_reason":stop_reason,"reached":travel>=distance-0.1 and lowest>start.y-1.5}
	walker.queue_free()
	await physics_frame
	return result

func run() -> void:
	var parser: Node = load("res://commons/grid/GridInteractablesComponent.gd").new()
	var cfg: Dictionary = parser._parse_config_token("boolean_tunnel:30:0:1#segment_vertical_offset:-0.65#num_segments:5#rotation_per_segment:18#plinth:0")
	check(cfg.config_data.segment_vertical_offset=="-0.65" and cfg.config_data.num_segments=="5" and cfg.config_data.rotation_per_segment=="18" and cfg.config_data.plinth=="0", "tunnel numeric config keeps exact values")
	check(is_equal_approx(float(cfg.overrides.rotation_y_degrees),30.0), "config values do not overwrite authored yaw")
	var array_cfg: Dictionary = parser._parse_config_token("rotation_array_compare:45:0#columns:2#rows:6#band_spacing:7#row_angle_step:18#plinth:0")
	check(array_cfg.config_data.band_spacing=="7" and array_cfg.config_data.row_angle_step=="18" and is_equal_approx(float(array_cfg.overrides.rotation_y_degrees),45.0), "array values and authored yaw survive parsing")
	var legacy: Dictionary = parser._parse_config_token("code_display#point_zero:15:-0.3:1.1")
	check(legacy.config_data.point_zero==true and is_equal_approx(float(legacy.overrides.rotation_y_degrees),15.0), "legacy tutorial shorthand remains available")
	parser.free()
	var quick := "--quick" in OS.get_cmdline_user_args()
	var world := Node3D.new()
	root.add_child(world)
	current_scene=world
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode=Environment.BG_COLOR
	env.background_color=Color(0.16,0.18,0.22)
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color=Color(0.83,0.87,1)
	env.ambient_light_energy=0.75
	environment.environment=env
	world.add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees=Vector3(-55,-25,0)
	light.light_energy=1.2
	world.add_child(light)
	var grid: Node3D=load("res://commons/grid/grid_system.tscn").instantiate()
	grid.map_name="Trans_Rotation"
	grid.bare_world=true
	grid.skip_player_spawn=true
	grid.position.y=-0.5
	var ready:=[false]
	grid.build_finished.connect(func():ready[0]=true,CONNECT_ONE_SHOT)
	world.add_child(grid)
	for i in range(2400):
		if ready[0]:break
		await process_frame
	for i in range(20):await physics_frame
	check(ready[0],"merged rotation source grid builds")
	var wall: Node3D
	var arrays: Node3D
	var tunnel: Node3D
	var cakes: Array[Node3D]=[]
	for n in grid.find_children("*","Node3D",true,false):
		if n.get_script()==load("res://commons/artifacts/rotation_studies/wall_crossings.gd"):wall=n
		if n.get_script()==load("res://commons/artifacts/rotation_studies/array_compare.gd"):arrays=n
		if n.get_script()==load("res://algorithms/transformation/booleanTunnel/booleanTunnel.gd"):tunnel=n
		if n.get_script()==load("res://algorithms/transformation/carousel_cake/carousel_cake.gd"):cakes.append(n)
	check(wall!=null and arrays!=null and tunnel!=null and cakes.size()==5,"four encounter types, eight actual placements")
	if wall==null or arrays==null or tunnel==null:quit(1);return
	wall.set_process(false)
	wall.set_crossing_pose()
	check(wall.global_position.is_equal_approx(Vector3(19,0,11)),"full-size blades at authored centre")
	check(arrays.global_position.is_equal_approx(Vector3(19,0,25)),"array at authored centre")
	check(wall.global_basis.get_scale().is_equal_approx(Vector3.ONE) and arrays.global_basis.get_scale().is_equal_approx(Vector3.ONE),"body-scale blades and array cubes retained")
	check(arrays.rows==6 and arrays.columns==2 and arrays.bands.size()==4,"four actual two-column six-row arrays")
	check(is_equal_approx(arrays.row_angle_step,18),"row angles remain 0 through 90 degrees")
	var profiles: Array[String]=[]
	for cake in cakes:
		profiles.append(cake.profile)
		check(cake._gallery_clean and cake.mm_inst.multimesh.instance_count==8,"single eight-layer "+cake.profile)
		check(cake.global_basis.get_scale().is_equal_approx(Vector3.ONE*0.4),"compact scale for "+cake.profile)
		check(cake._collider_bodies.size()==8,"matching visible/collision layers for "+cake.profile)
	profiles.sort()
	check(profiles==["cake","column","flare","spindle","ziggurat"],"all five distinct profiles retained")
	check(tunnel.num_segments==5 and is_equal_approx(tunnel.rotation_per_segment,18),"five hollow segments at eighteen-degree intervals")
	await physics_frame
	var space:=world.get_world_3d().direct_space_state
	var capsule:=CapsuleShape3D.new()
	capsule.radius=0.22;capsule.height=1.6
	var query:=PhysicsShapeQueryParameters3D.new()
	query.shape=capsule
	query.collision_mask=1
	query.transform=Transform3D(Basis.IDENTITY,Vector3(19,0.81,41.8))
	query.motion=Vector3(0,0,16.0)
	var sweep:=space.cast_motion(query)
	check(sweep[0]>0.99,"standing capsule passage through full-scale tunnel")
	observations["tunnel_sweep"]=sweep
	for x in [12.0,26.0]:
		var supported:=true
		for z in range(3,58):
			var hit:=space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(x,0.15,z),Vector3(x,-0.15,z),1))
			supported=supported and not hit.is_empty()
		check(supported,"continuous still floor along x="+str(x))
		query.transform=Transform3D(Basis.IDENTITY,Vector3(x,0.81,3))
		query.motion=Vector3(0,0,54)
		var aisle:=space.cast_motion(query)
		check(aisle[0]>0.99,"clear body-width aisle x="+str(x))
		observations["aisle_"+str(x)]=aisle
	if not quick:
		for station: Dictionary in wall.stations:
			var direction:=Vector3.RIGHT if station.id=="Z" else Vector3.BACK
			var start: Vector3=station.node.to_global(-direction*4.5)
			var result: Dictionary=await walk(world,start,direction,10)
			observations["blade_"+str(station.id)]=result
			var expected_y:=0.0 if station.id=="Y" else 3.0
			check(result.reached and absf(result.y-expected_y)<0.04,str(station.id)+" full-size blade reaches bank")
			print("[compact-walk] ",station.id," ",result)
		arrays.row_angle_step=0
		arrays.apply_gradient()
		await physics_frame
		for band: Dictionary in arrays.bands:
			var start: Vector3=band.node.to_global(Vector3(-1,0,-1.4))
			var result: Dictionary=await walk(world,start,Vector3.BACK,14)
			observations["flat_"+str(band.id)]=result
			check(result.reached,str(band.id)+" unrotated array control can be crossed")
		arrays.row_angle_step=18
		arrays.apply_gradient()
		await physics_frame
		for band: Dictionary in arrays.bands:
			var start: Vector3=band.node.to_global(Vector3(-1,0,-1.4))
			var result: Dictionary=await walk(world,start,Vector3.BACK,14)
			observations["gradient_"+str(band.id)]=result
			print("[compact-gradient] ",band.id," ",result)
		for start in [Vector3(18.5,3,17.5),Vector3(35.5,3,13.5)]:
			var result: Dictionary=await walk(world,start,Vector3.BACK,6)
			# A planned three-metre descent exceeds the flat-route helper's fall allowance.
			check(result.stop_reason=="arrived" and result.lowest>-0.05 and absf(result.y)<0.04,"grid wedge return from "+str(start))
			observations["return_"+str(start)]=result
	if "--capture" in OS.get_cmdline_user_args():
		var camera:=Camera3D.new();world.add_child(camera);camera.fov=68
		var shots: Array=[
			["rotation-compact-overview",Vector3(56,48,-9),Vector3(19,0,30)],
			["rotation-compact-blades",Vector3(4,10,0),Vector3(20,1.5,11)],
			["rotation-compact-arrays",Vector3(19,8,18),Vector3(19,0,30)],
			["rotation-compact-gallery",Vector3(11,4,39),Vector3(20,2,50)]]
		for shot in shots:
			camera.global_position=shot[1];camera.look_at(shot[2]);camera.make_current()
			for i in range(10):await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://doc/space/transformation-refresh-2026-09-16/"+shot[0]+".png")
	var out:={"checks":checks,"failures":failures,"observations":observations,"quick":quick,"limits":["Source grid, not full museum staging","Static crossing poses; human timing and headset comfort untested","Straight capsule walks do not rule out detours or jumping"]}
	FileAccess.open("res://ada_run/rotation_compact_quick_checks.json" if quick else "res://ada_run/rotation_compact_checks.json",FileAccess.WRITE).store_string(JSON.stringify(out,"  "))
	FileAccess.open("res://doc/space/transformation-refresh-2026-09-16/rotation-compact-quick-checks.json" if quick else "res://doc/space/transformation-refresh-2026-09-16/rotation-compact-checks.json",FileAccess.WRITE).store_string(JSON.stringify(out,"  "))
	print("[rotation-compact] ",checks," checks; ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)
