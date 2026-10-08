extends SceneTree
## Exercise the actual streamed hall; colour is a presentation of live sources.
var checks: Array = []
var failures: Array = []
var presentation_ms: float = 0.0
func _initialize() -> void: run.call_deferred()
func check(label: String, result: bool) -> void:
	checks.append({"name":label,"passed":result})
	if not result: failures.append(label)
func neutral(c: Color) -> bool:
	return is_equal_approx(c.r,c.g) and is_equal_approx(c.g,c.b)
func run() -> void:
	var spec: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(OS.get_cmdline_user_args()[0]))
	var folder: String = spec.run
	if spec.get("before",false):
		var source := FileAccess.get_file_as_string(folder+"museum_snapshot.gd")
		var begin := source.find("\t# Transformation studies form and movement in grayscale.")
		var end := source.find('\tseg.set_meta("em_map",',begin)
		assert(begin > 0 and end > begin)
		var snapshot := FileAccess.open(folder+"museum_snapshot.gd",FileAccess.WRITE)
		snapshot.store_string(source.left(begin)+source.substr(end))
		snapshot.close()
	var museum: Node3D = load(folder+"museum_snapshot.tscn").instantiate()
	museum.set("EM_CONTROL",folder+"control.json")
	museum.set("_hand_path",folder+"necklace_hand.json")
	museum.set("_overrides_path",folder+"em_overrides.json")
	museum.set("start_chapter",spec.sequence)
	museum.set("start_map",spec.room)
	museum.set("plan_file",folder+"plan.json")
	root.add_child(museum)
	current_scene= museum
	var start := Time.get_ticks_msec()
	while not bool(museum.get("_museum_core_ready")) and Time.get_ticks_msec()-start<60000: await process_frame
	museum.set("_lazy_pending",0)
	museum.set_process(false)
	museum.set_physics_process(false)
	museum.call("flush_stamps")
	await create_timer(1).timeout
	var hall: Node3D
	for node in museum.get_children():
		if node.get_meta("em_map","")==spec.room: hall=node;break
	check("requested museum hall loaded",hall!=null)
	if hall==null: quit(1);return
	var palette: Node = hall.get_node_or_null("TransformationGrayscale")
	if not spec.get("before",false):
		check("grayscale scoped to Transformation",palette!=null and hall.get_meta("em_chapter")=="transformation")
		if palette!=null:
			var originals: Dictionary = {}
			var materials: Dictionary = palette.get("_materials")
			var standard_count := 0
			var shader_count := 0
			for pair in materials.values():
				check("material is a separate display copy",pair[0]!=pair[1])
				if pair[0] is BaseMaterial3D:
					standard_count+=1
					check("standard albedo/emission neutral",neutral(pair[1].albedo_color) and neutral(pair[1].emission))
					originals[pair[0]]=pair[0].albedo_color
				elif pair[0] is ShaderMaterial:
					shader_count+=1
					check("shader surface converted",pair[1].shader!=null and "ALBEDO = vec3(dot(ALBEDO" in pair[1].shader.code)
			check("hall has displayed materials",standard_count+shader_count>0)
			# Deliberately update a shared source. The coloured neighbour remains
			# coloured, the local display responds, and geometry is untouched.
			var source := StandardMaterial3D.new()
			source.albedo_color=Color(1,.2,.1)
			var local: Material=palette.call("_display",source)
			check("shared source keeps colour",not neutral(source.albedo_color))
			source.albedo_color=Color(.1,.4,1)
			source.roughness=.31
			await process_frame
			await process_frame
			check("live colour updates remain gray",neutral(local.albedo_color) and local.albedo_color==palette.gray(source.albedo_color))
			check("surface properties stay live",is_equal_approx(local.roughness,.31))
			check("source still coloured after update",not neutral(source.albedo_color))
			local.albedo_color=Color(.8,.1,.7)
			local.emission_energy_multiplier=2.5
			await process_frame
			await process_frame
			check("direct display animation remains gray",neutral(local.albedo_color))
			check("direct display energy retained",is_equal_approx(local.emission_energy_multiplier,2.5))
	var camera:=Camera3D.new()
	root.add_child(camera)
	var previous: Camera3D=museum.get("_cam")
	if previous!=null:
		for timer in previous.find_children("*","Timer",true,false): timer.stop()
	var origin:=hall.global_position+Vector3(0,0,4)
	var grid: Node3D = hall.get_node_or_null("SimGrid_"+str(spec.room))
	if grid!=null: origin=grid.global_position+Vector3.UP*.5
	for shot in spec.get("shots",[]):
		var eye: Array=shot.from
		var target: Array=shot.look_at
		var frame:=Transform3D(Basis.IDENTITY,origin)
		if shot.has("anchor"):
			var found:=false
			for node in hall.find_children("*","Node3D",true,false):
				if node.get_script()!=null and str(node.get_script().resource_path).ends_with(shot.anchor):
					frame=node.global_transform
					found=true
					break
			check("camera anchor exists",found)
		camera.global_position=frame*Vector3(eye[0],eye[1],eye[2])
		camera.look_at(frame*Vector3(target[0],target[1],target[2]))
		camera.fov=shot.get("fov",65)
		camera.current=true
		await create_timer(.3).timeout
		if DisplayServer.get_name()!="headless":
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(ProjectSettings.globalize_path(folder+shot.tag+".png"))
	# Motion is sampled in live artifacts, not inferred from an image.
	var transforms: Dictionary={}
	for node in hall.find_children("*","Node3D",true,false): transforms[node]=node.transform
	await create_timer(.45).timeout
	var changed:=0
	for node in transforms:
		if is_instance_valid(node) and not node.transform.is_equal_approx(transforms[node]): changed+=1
	if spec.room in ["Trans_Pre","Trans_Introduction","Trans_Translation","Trans_Rotation","Trans_Pit"]:
		check("animated nodes still move",changed>0)
	if palette!=null:
		var costs: Array[float]=[]
		for i in 30:
			var tick:=Time.get_ticks_usec()
			palette.call("_process",1.0/90.0)
			costs.append(float(Time.get_ticks_usec()-tick)/1000.0)
		costs.sort()
		presentation_ms=costs[15]
	var report: Dictionary={"room":spec.room,"before":spec.get("before",false),"passed":failures.is_empty(),"checks":checks,"failures":failures,"moving_nodes":changed,"presentation_poll_median_ms":presentation_ms,"scope":"Live museum render and native material/state assertions; desktop Compatibility renderer. No headset acceptance claim."}
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("GRAYSCALE ",spec.room," ",checks.size()-failures.size(),"/",checks.size()," moving=",changed)
	quit(0 if failures.is_empty() else 1)
