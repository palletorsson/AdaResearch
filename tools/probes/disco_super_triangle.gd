extends "res://tools/probes/disco_separate_clocks.gd"
## Retain the square-floor checks, then exercise the new triangle mode in place.
func landing_checks() -> void:
	await super.landing_checks()
	if not completed:return
	completed=false
	var geometry:Array=[]
	for i in 144:geometry.append(floor_node.multimesh.get_instance_transform(i))
	var collision_count:int=floor_node.find_children("*","CollisionShape3D",true,false).size()
	var collider:Dictionary=floor_at(actor.global_position)
	for i in 3:await press(0)
	check("PATTERN reaches SUPER TRIANGLE after SNAKE",controls.pattern==controls.TRIANGLE_MODE and controls.phase==0)
	var surface:MeshInstance3D=controls.triangle_surface
	check("triangle image uses the same floor extent",surface!=null and surface.visible and surface.mesh.size.is_equal_approx(Vector2(12,12)*floor_node.tile_size))
	if surface==null:return
	check("triangle image adds no collision",surface.find_children("*","CollisionShape3D",true,false).is_empty() and floor_node.find_children("*","CollisionShape3D",true,false).size()==collision_count)
	check("mode starts black and white",surface.material_override.get_shader_parameter("ink")==Color.BLACK and surface.material_override.get_shader_parameter("paper")==Color.WHITE)
	for i in 24:
		if i>0:await press(2)
		check("held triangle pose "+str(i),controls.phase==i and is_equal_approx(float(surface.material_override.get_shader_parameter("motion")),float(i)))
		await photo("triangles-"+str(i).pad_zeros(2))
	await press(2)
	check("24 steps return to the first triangle arrangement",is_zero_approx(float(surface.material_override.get_shader_parameter("motion"))))
	await press(1)
	await create_timer(0.22).timeout
	await press(1)
	var stopped_motion:float=surface.material_override.get_shader_parameter("motion")
	await create_timer(0.35).timeout
	check("HOLD freezes the actual intermediate triangle pose",not controls.running and not is_equal_approx(stopped_motion,floorf(stopped_motion)) and is_equal_approx(float(surface.material_override.get_shader_parameter("motion")),stopped_motion))
	await photo("triangles-held-between")
	observations["held_motion"]=stopped_motion
	await press(2)
	check("ONE STEP reaches the next exact pose from a held turn",is_equal_approx(float(surface.material_override.get_shader_parameter("motion")),float(controls.phase%24)))
	seq.step_triggered.emit(1,12)
	check("musical step records column zero",controls.pulse_remaining.has(0))
	await process_frame
	await RenderingServer.frame_post_draw
	check("musical step reaches the triangle image's folded column",surface._pulse_data[0]==255 and surface._pulse_data.count(255)==1)
	await create_timer(0.25).timeout
	check("triangle pulse expires while movement holds",surface._pulse_data.count(255)==0)
	# The shared colour return uses the same two-palette inputs.
	controls.cycle_palette()
	check("triangle mode receives the existing palette selection",surface.material_override.get_shader_parameter("ink")==controls.PALETTES[1][0] and surface.material_override.get_shader_parameter("paper")==controls.PALETTES[1][1])
	for i in 3:controls.cycle_palette()
	check("black and white palette restores",surface.material_override.get_shader_parameter("ink")==Color.BLACK and surface.material_override.get_shader_parameter("paper")==Color.WHITE)
	await press(0)
	check("leaving triangle mode restores the square checker",controls.pattern==0 and not surface.visible and floor_node.tile_colors[0].is_equal_approx(Color.BLACK) and floor_node.tile_colors[1].is_equal_approx(Color.WHITE))
	for i in 4:await press(0)
	check("return reuses one triangle surface",controls.triangle_surface==surface and surface.visible)
	var unchanged:=true
	for i in 144:unchanged=unchanged and geometry[i].is_equal_approx(floor_node.multimesh.get_instance_transform(i))
	check("triangle choreography preserves all 144 tile transforms",unchanged)
	var after_collider:=floor_at(actor.global_position)
	check("the physical standing surface is unchanged",not collider.is_empty() and not after_collider.is_empty() and collider.collider==after_collider.collider and collider.position.is_equal_approx(after_collider.position))
	await press(1)
	var original_score:=score()
	if not await walk(Vector3(-4,walking_y+0.05,-4),"cross the running triangle floor"):return
	check("triangle crossing leaves the score untouched",score()==original_score)
	await press(1)
	await snapshot("triangles-underfoot",actor.global_position+Vector3.UP*1.65,floor_node.to_global(Vector3(0,walking_y,0)),72)
	await snapshot("triangle-console",controls.to_global(Vector3(0,1.7,-1.9)),controls.to_global(Vector3(0,1.2,0)),57)
	for path in ["commons/artifacts/regularity/super_triangle.gdshader","commons/artifacts/regularity/super_triangle_surface.gd"]:
		observations[path]=FileAccess.get_sha256("res://"+path)
	# Native samples of the actual shader's between-pose motion for a pausable review.
	camera.global_position=floor_node.to_global(Vector3(7,9,-9))
	camera.look_at(floor_node.to_global(Vector3.ZERO));camera.fov=63;camera.current=true
	var saved_frames:=0
	for i in 96:
		controls.phase=i / 4
		controls.triangle_motion=float(i) / 4.0
		controls.paint()
		await process_frame
		await RenderingServer.frame_post_draw
		var frame:=root.get_texture().get_image()
		frame.resize(768,512,Image.INTERPOLATE_LANCZOS)
		if frame.save_png(folder+"motion-"+str(i).pad_zeros(3)+".png")==OK:saved_frames+=1
	check("96 native intermediate motion frames saved",saved_frames==96)
	completed=true
func finish() -> void:
	if driver!=null:driver.release();driver.set_physics_process(false)
	if seq!=null:seq.stop()
	check("encounter completed",completed)
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"room":map_id,"passed":failures.is_empty(),"checks":checks,"failures":failures,"observations":observations,"scope":"Isolated production museum, supplied floor pointer events and sequencer UI/events. Original square modes plus 24 held triangle poses, continuous play/hold, original geometry, pulse/palette integration and ordinary-controller walks. Audio muted. Palette method check is not a full colour-hall test. Selected camera states; no headset or learner claim."},"  "))
	print("SUPER TRIANGLE ",checks.size()-failures.size(),"/",checks.size())
	quit(0 if failures.is_empty() else 1)
