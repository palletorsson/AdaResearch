extends "res://tools/probes/disco_separate_clocks.gd"
func snapshot(title:String,eye:Vector3,target:Vector3,fov:float=55.0) -> void:
	for node in root.find_children("*","Node",true,false):
		if node.get_script()!=null and str(node.get_script().resource_path).ends_with("/MushroomHand.gd"):
			node.show_desktop_count=false
			var hud:CanvasLayer=node.get("_hud")
			if hud!=null:hud.visible=false
	await super.snapshot(title,eye,target,fov)

func landing_checks() -> void:
	await super.landing_checks()
	if not completed:return
	completed=false
	driver.release();driver.set_physics_process(false)
	seq.stop();ui.clear_pattern()
	while controls.pattern != 0:await press(0)
	var viewpoint:=Vector3(-3.6,walking_y+1.65,-3.9)
	var subject:=Vector3(-1.4,walking_y,0)
	await snapshot("checker-underfoot-zero",floor_node.to_global(viewpoint),floor_node.to_global(subject),73)
	var before:Array=floor_node.tile_colors.duplicate()
	var previous_phase:int=controls.phase
	await press(2)
	check("checker comparison changes phase but retains the rule",controls.pattern==0 and controls.phase==previous_phase+1 and not controls.running)
	await snapshot("checker-underfoot-one",floor_node.to_global(viewpoint),floor_node.to_global(subject),73)
	await press(2)
	check("two steps return the pictured floor values",floor_node.tile_colors==before)
	for i in 4:await press(0)
	check("the diagonal motif returns in SUPER TRIANGLE",controls.pattern==controls.TRIANGLE_MODE and controls.triangle_surface.visible)
	for i in 8:await press(2)
	await snapshot("triangles-within-reach",floor_node.to_global(viewpoint),floor_node.to_global(subject),73)
	await press(1)
	await create_timer(0.2).timeout
	await press(1)
	var held:float=controls.triangle_surface.material_override.get_shader_parameter("motion")
	await create_timer(0.35).timeout
	check("intermediate triangle arrangement remains held",not controls.running and is_equal_approx(float(controls.triangle_surface.material_override.get_shader_parameter("motion")),held))
	await snapshot("triangles-held-turn",floor_node.to_global(viewpoint),floor_node.to_global(subject),73)
	observations["triangle_held_motion"]=held
	await press(2)
	check("one step reaches an exact triangle pose",is_equal_approx(float(controls.triangle_surface.material_override.get_shader_parameter("motion")),float(controls.phase%24)))
	for path in ["commons/artifacts/regularity/super_triangle.gdshader","commons/artifacts/regularity/super_triangle_surface.gd"]:
		observations[path]=FileAccess.get_sha256("res://"+path)
	completed=true
