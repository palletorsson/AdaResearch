extends "res://commons/artifacts/timing_machines/pg_workshop.gd"
## A local desk drives the existing models. No replacement solver lives here.
var actions_taken := 0
var drive_held := false
var pin_mode := 0
var saved_pins: Dictionary = {}
var control_indices: Dictionary = {}
var spec: Dictionary
var lesson_time := 0.0
var lesson_hall: Node

func _process(delta: float) -> void:
	lesson_time+=delta
	if lesson_time<0.5 or not is_instance_valid(lesson_hall):return
	lesson_time=0.0
	for ui in lesson_hall.find_children("*","CanvasLayer",true,false):
		ui.hide()
		for item in ui.find_children("*","Control",true,false):item.hide()

func _bind() -> void:
	var hall: Node = get_parent()
	while hall != null and not hall.has_meta("em_map"): hall=hall.get_parent()
	if hall==null:return
	lesson_hall=hall
	var em: Node=hall
	while em!=null and not "_edit_records" in em:em=em.get_parent()
	if em==null:return
	var data: Array=JSON.parse_string(FileAccess.get_file_as_string("res://commons/artifacts/timing_machines/soft_workshop.json"))
	for row: Dictionary in data:
		if row.slug==chapter:spec=row
	if spec==null or spec.is_empty():return
	for attempt in 100:
		for rec: Dictionary in em.get("_edit_records"):
			var n=rec.get("node")
			if is_instance_valid(n) and hall.is_ancestor_of(n) and rec.token!= "soft_workshop_console":works[rec.token]=n
		var complete:=true
		for key in spec.primary:complete=complete and works.has(key)
		if complete:break
		await get_tree().create_timer(0.1).timeout
	for key in spec.primary:
		if not works.has(key):push_error("Soft workshop missing "+key);return
	model=works[spec.primary[0]]
	if spec.primary.size()>1:other=works[spec.primary[1]]
	match chapter:
		"cloth": _cloth_pins(0)
		"contact":model.set_process(false)
		"sampling":model=works.rounded_softbody_test.get_node("RoundedSoftBody")
		"reaction":
			model.auto_run=false;model.set_process(false)
			# Map configuration may arrive after the display is built. Keep its
			# texture dimensions equal to the actual simulation dimensions.
			if model._image.get_width()!=model.resolution:
				model._image=Image.create(model.resolution,model.resolution,false,Image.FORMAT_RGB8)
				model._texture=ImageTexture.create_from_image(model._image)
				model._material.albedo_texture=model._texture
			model._init_simulation();model._update_texture()
		"morphogenesis":model.regenerate_at_entropy=false
	# The original local controls remain available unless a screen covers the hall.
	for ui in hall.find_children("*","CanvasLayer",true,false):
		ui.hide()
		for item in ui.find_children("*","Control",true,false):item.hide()
	# Artifacts' demo cameras do not take the museum camera away from the visitor.
	for camera in hall.find_children("*","Camera3D",true,false):camera.current=false
	ids=spec.controls
	_build_compact_console(ids,str(spec.title).to_upper())
	rule_card=label(spec.rule,Vector3(0,2.15,0.5),0.001)
	rule_card.visible=false
	var dims: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://commons/maps/"+str(hall.get_meta("em_map"))+"/map_data.json")).map_info.dimensions
	for z in range(7,int(dims.depth),10):
		for x in [int(dims.width)*0.3,int(dims.width)*0.7]:
			var light:=OmniLight3D.new();light.position=Vector3(x,7,z+int(em.get("VESTIBULE_H")));light.omni_range=18;light.light_energy=4;hall.add_child(light)
	ready_for_input=true;refresh()

func _bodies(n: Node) -> Array:
	var out: Array=[]
	if n is SoftBody3D:out.append(n)
	for child in n.find_children("*","SoftBody3D",true,false):
		if child.visible:out.append(child)
	return out

func _next(id: String, count: int) -> int:
	control_indices[id]=(int(control_indices.get(id,0))+1)%count
	return control_indices[id]

func _cloth_pins(mode: int) -> void:
	for sb in _bodies(model):
		var verts: PackedVector3Array=sb.get_meta("lesson_rest",sb.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX])
		var ymax: float=-INF
		var xmax: float=0.0
		for v in verts:ymax=maxf(ymax,v.y);xmax=maxf(xmax,absf(v.x))
		for i in verts.size():
			var top: bool=absf(verts[i].y-ymax)<0.01
			var keep: bool=top and (mode==0 or (mode==1 and absf(absf(verts[i].x)-xmax)<0.01))
			sb.set_point_pinned(i,keep)
	pin_mode=mode

func _hold_bodies(n: Node, freeze_now: bool) -> void:
	for sb in _bodies(n):
		var count: int=sb.mesh.surface_get_array_len(0)
		if freeze_now:
			var pins: Array=[]
			for i in count:
				if sb.is_point_pinned(i):pins.append(i)
			saved_pins[sb.get_instance_id()]=pins
		for i in count:sb.set_point_pinned(i,freeze_now or i in saved_pins.get(sb.get_instance_id(),[]))

func act(id: String) -> void:
	if not ready_for_input or busy:return
	busy=true;actions_taken+=1
	if id=="RULE":rule_card.visible=not rule_card.visible;busy=false;return
	match chapter:
		"deformation":
			match id:
				"STIFFNESS":model.stiffness=[0.5,0.1,0.9][_next(id,3)]
				"DAMPING":model.damping=[0.01,0.05,0.1][_next(id,3)]
				"PRESSURE":model.pressure=[1.0,0.0,2.0][_next(id,3)]
				"RESET":model._reset_physics()
				"MILL":
					drive_held=not drive_held
					for child in other.find_children("*","Node",true,false):
						if child.get_script()!=null and not child is SoftBody3D:child.set_process(not drive_held);child.set_physics_process(not drive_held)
		"cloth":
			match id:
				"PINS":_cloth_pins((pin_mode+1)%2)
				"RELEASE":_cloth_pins(2)
				"STIFFNESS":
					var value: float=[0.5,0.1,0.9][_next(id,3)]
					for sb in _bodies(model):sb.linear_stiffness=value
				"REBUILD":
					for sb in _bodies(model):model.remove_child(sb);sb.queue_free()
					model.setup_straps();await get_tree().physics_frame;_cloth_pins(0)
				"LANDING":other.apply_grid_config({"landing":["floor","pan","rail","cone"][_next(id,4)]})
		"carousel":
			match id:
				"SPEED":model.ride_speed=[1.0,0.4,1.6][_next(id,3)]
				"REVERSE":model.ride_speed=-model.ride_speed
				"STOP":model.ride_speed=0.0
				"STIFFNESS":
					for sb in _bodies(model):sb.linear_stiffness=[0.5,0.1,0.9][int(control_indices.get(id,0))]
					_next(id,3)
				"PRESSURE":
					var value: float=[0.0,0.5,1.0][_next(id,3)]
					for sb in _bodies(model):sb.pressure_coefficient=value
		"breathing":
			match id:
				"AMPLITUDE":model.breath_amplitude=[0.5,0.15,0.9][_next(id,3)]
				"RATE":model.breath_speed=[1.0,0.4,1.8][_next(id,3)]
				"HOLD DRIVE":drive_held=not drive_held;model.set_process(not drive_held)
				"STIFFNESS":
					var value: float=[0.5,0.2,0.8][_next(id,3)]
					for sb in model._walls:sb.linear_stiffness=value
				"RESET PHASE":model._time=0.0;model._process(0.0)
		"contact":
			match id:
				"REPLAY":model.apply_grid_config({"seed_value":1337,"respawn":false})
				"VARIATION":model.lesson_variation=not model.lesson_variation;model.apply_grid_config({"seed_value":1337})
				"GROUP":model.apply_grid_config({"gallery_part":[2,3,1][_next(id,3)],"respawn":false})
				"HOLD":
					if not drive_held:_hold_bodies(model,true)
					drive_held=true
				"RELEASE":_hold_bodies(model,false);drive_held=false
		"sampling":
			match id:
				"MEASURE":model._cycle_mode()
				"SQUEEZE":model._on_squeeze_changed("lesson",[0.0,0.2,0.6][_next(id,3)])
				"STIFFNESS":model._on_stiffness_changed("lesson",[0.5,0.1,0.9][_next(id,3)])
				"DURATION":other.apply_grid_config({"sim_steps":[200,40,400][_next(id,3)]})
				"GRAVITY":other.apply_grid_config({"gravity_x":[0.0,2.0,-2.0][_next(id,3)]})
		"affect":
			match id:
				"ROTATION":model._on_toggle_rotation_pressed()
				"COLOUR":model._on_toggle_color_mode_pressed()
				"EFFECTS":model._on_toggle_effects_pressed()
				"SEED":model.apply_grid_config({"generation_seed":1337+_next(id,3)});model.regenerate_forms()
				"SPIKES":model.spikiness_probability=[0.7,0.0,1.0][_next(id,3)];model.regenerate_forms()
		"reaction":
			match id:
				"STEP","100 STEPS":
					var count:=1 if id=="STEP" else 100
					for i in count:
						model._simulation_step();step_count+=1
						if i%10==9:await get_tree().process_frame
					model._update_texture()
				"REGIME":model.pattern_type=_next(id,6);model._apply_preset();model._init_simulation();model._update_texture();step_count=0
				"SEEDING":model.apply_grid_config({"seeding":["centre","lattice","ring","discs"][_next(id,4)]});model._update_texture();step_count=0
				"RESET":model._init_simulation();model._update_texture();step_count=0
		"morphogenesis":
			match id:
				"S":model.set_entropy([0.3,0.0,0.7,1.0][_next(id,4)]);model.regenerate_now()
				"LEVEL":model.apply_grid_config({"level":["minimal","thickened","pinched","broken"][_next(id,4)]})
				"NOISE":model.base_noise_amp=0.0 if model.base_noise_amp>0 else 0.05;model.high_noise_amp=0.0 if model.high_noise_amp>0 else 0.2;model.regenerate_now()
				"RESOLUTION":
					var n: int=[24,16,32][_next(id,3)];model.voxel_resolution=Vector3i(n,n,n);model.regenerate_now()
				"RESET":model.S=0.3;model.threshold_center=0.0;model.base_noise_amp=0.05;model.high_noise_amp=0.2;model.voxel_resolution=Vector3i(24,24,24);model.regenerate_now()
	busy=false;refresh()

func refresh() -> void:
	if readout==null or not ready_for_input:return
	match chapter:
		"deformation":readout.text="stiffness %.2f | damping %.2f\npressure %.2f | mill drive %s" % [model.stiffness,model.damping,model.pressure,"held" if drive_held else "running"]
		"cloth":readout.text="%d cloth strips | pins: %s\nFour samples: %s landing\nREBUILD restores strips, not elapsed time" % [_bodies(model).size(),["top row","top corners","released"][pin_mode],other.landing]
		"carousel":readout.text="Hub %.2f radians / second\nSTOP holds drive; gravity and bodies continue\nCloth beside it keeps a fixed support" % model.ride_speed
		"breathing":readout.text="Pressure amplitude %.2f | rate %.2f\nDrive %s | physics continues\nSelected vertices stay pinned in the scene" % [model.breath_amplitude,model.breath_speed,"held" if drive_held else "running"]
		"contact":readout.text="Group %d | %d bodies | variation %s\nDeflation/respawn disabled in this study\nHOLD pins current vertices" % [model.gallery_part,model.active_soft_bodies.size(),str(model.lesson_variation)]
		"sampling":readout.text="Measurement: %s | squeeze %.2f\nVessel: %d solver steps | gravity x %.1f\nA baked surface beside a running body" % [model.measure,model._squeeze_strength,other.sim_steps,other.gravity_x]
		"affect":readout.text="%d constructed forms | seed %d\nSpikes %.1f | rotation %s\nBiological resemblance is not simulated growth" % [model.number_of_forms,model.generation_seed,model.spikiness_probability,str(model.enable_rotation)]
		"reaction":readout.text="Gray-Scott | step %d | %d squared cells\nfeed %.4f | kill %.4f | %s\nWrapped edges; concentrations clamped to 0..1" % [step_count,model.resolution,model.feed,model.kill,model.seeding]
		"morphogenesis":readout.text="S %.2f | frequency %.2f | noise %.2f\nthreshold %.2f | resolution %d cubed\nS is a control, not measured entropy" % [model.S,model.current_frequency,model.current_noise_amp,model.current_threshold,model.voxel_resolution.x]
