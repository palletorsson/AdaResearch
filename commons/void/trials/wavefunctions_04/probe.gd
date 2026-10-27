extends "res://commons/void/trials/wavefunctions_02/probe.gd"
## Batch 23: WaveFunctions_AirMusic (floor 1) and Wavefunctions_Sky_Stairs (floor 2).
## Visit, inspection, shaft descent, residency and retry come from the shared chain.
## Every floor-specific check below replaces the inherited wavefunctions_02 ones.
## Real input: striker grab/strike/drop, drone PLAY/STOP, gallery grab, walking climb.
## API or introspection checks say so in their names.

const PIPE_PATH := "straight,straight,up,straight,down,straight,straight"
const STAIRS := "f2_sine_cylinder_staircase_7_16"

func debug_cases() -> Dictionary:
	return {"metallophone":1,"gallery":2}

func run_debug_case(name: String, tag: String) -> void:
	match name:
		"metallophone":await metallophone_checks(tag)
		"gallery":await gallery_checks(tag)

func focused_checks(tag: String) -> void:
	check(tag+"standard floor "+str(level),game.building.spec.width==42 and game.building.spec.depth==32 and game.building.spec.storey_height==6)
	await fit_checks(tag)
	match level:
		1:await air_music_checks(tag)
		2:await sky_stairs_checks(tag)
	game.place_player(game.spawn_for(level));await frames(15)

## Whole shaft openings and the arrival, not only the shaft-centre ray.
func fit_checks(tag: String) -> void:
	var spec=game.building.spec
	var y:float=spec.levels[level]
	var keep_out:Array=[]
	for shaft in spec.shafts:
		keep_out.append(["shaft "+str(shaft.name),AABB(Vector3(float(shaft.x)-float(spec.shaft_width)/2.0,y-.5,-float(spec.shaft_depth)/2.0),Vector3(float(spec.shaft_width),6.5,float(spec.shaft_depth)))])
	keep_out.append(["arrival",AABB(Vector3(-1,y,11),Vector3(2,2.2,2))])
	# game.gd _build_signs: default board at (3.5, y+1.35, -7.8), 3.7 x 1.65 x 0.12.
	var sign_xz:Array=spec.get("floor_sign_positions",{}).get(str(level),[3.5,-7.8])
	keep_out.append(["floor sign",AABB(Vector3(float(sign_xz[0])-1.85,y+.525,float(sign_xz[1])-.06),Vector3(3.7,1.65,.12))])
	var hits:Array=[]
	for entry in game.building.content.data.floors[level].artifacts:
		var boxes:Array=[];geometry(station(entry.id),boxes)
		for item in keep_out:
			var zone:AABB=item[1]
			if boxes.any(func(b):return b.intersects(zone)):hits.append(entry.id+" / "+str(item[0]))
	if not xr and not hits.is_empty():fit_notes.append({"floor":level,"enters":hits})
	check(tag+"placement geometry stays out of whole shaft openings, arrival and floor sign",hits.is_empty())

func air_music_checks(tag: String) -> void:
	await metallophone_checks(tag)
	await drone_checks(tag)
	var display:Node3D=artifact("air_music_display_case")
	var content:Node3D=display.air_music_instance
	check(tag+"display case keeps its own scaled Systems Music loop",content!=null and is_equal_approx(content.scale.x,.35) and content.get_node_or_null("Camera3D")==null and is_equal_approx(float(content.get_node("IntensityController").period),90.0))
	# R2 adapter (air_music_case_local.gd) is required: the one-argument slider
	# signal must no longer reach the zero-argument source callback.
	var slider:Node=display._volume_slider
	check(tag+"case runs the VOLUME arity adapter",display.get_script().resource_path=="res://commons/void/air_music_case_local.gd" and not slider.slider_moved.is_connected(display._on_volume_changed))
	var handle:Node3D=slider.get_node("SliderOrigin/InteractableSlider/HandleOrigin/InteractableHandle")
	var before:float=display.audio_volume_db
	await stand_local(display,Vector3(0,-.94,.95))
	var from:Vector3=handle.global_position
	await pointer_drag(from,from-slider.global_transform.basis.x.normalized()*.05)
	var voices:Array=content.get_node("FMPianoSynth")._players
	check(tag+"real pointer drag on VOLUME lowers the case synth voices",display.audio_volume_db<before-1.0 and voices.all(func(v):return is_equal_approx(v.volume_db,display.audio_volume_db)))
	print("VOLUME ",tag," ",before," -> ",display.audio_volume_db," slider=",slider.get_normalized_value())
	var smt:Node3D=artifact("SystemsMusicTest")
	var looper:Node=smt.get_node("SystemsMusicLooper")
	check(tag+"Systems Music runs its seven timed phasing loops",looper.loops.size()==7 and looper.synth!=null and looper.loop_states.has(false))
	check(tag+"Systems Music has no visitor-position trigger (timed loops only)",smt.find_children("*","Area3D",true,false).is_empty())
	for entry in game.building.content.data.floors[level].artifacts:
		if entry.artifact!="GlassRack":continue
		var glass:Node3D=station(entry.id)
		var wanted:String=str(entry.config["config"])
		# R1 adapter is required: the token selects the apparatus, not the scene's coffee rack.
		var meshes:int=glass.find_children("*","MeshInstance3D",true,false).size()
		check(tag+entry.id+" builds its token apparatus "+wanted+" (no coffee-rack frame)",str(glass.get_meta("config_config",""))==wanted and glass.config_file in [wanted,wanted+".json"] and glass.find_child("Frame",true,false)==null and meshes>0)
		print("GLASS ",tag,entry.id," config_file=",glass.config_file," meshes=",meshes)
	var pipe:Node3D=artifact("BigPipeSystem")
	check(tag+"pipe preserves known empty source and its inert path token",not pipe.auto_build and pipe._curves.is_empty() and str(pipe.get_meta("config_path",""))==PIPE_PATH)
	# Measurement, not a check: the floor-2 staircase's upper treads stand above
	# this floor's slab. Record whether the visitor here can see or touch them.
	var upper:Node3D=game.building.content.exhibits.get("2/"+STAIRS)
	if upper!=null and upper.has_node("Artifact"):
		var s2:Node3D=upper.get_node("Artifact")
		var high:Array=s2.get_node("StairSteps").get_children().filter(func(t):return t.global_position.y>float(game.building.spec.levels[1])+.3)
		if not high.is_empty():
			var t:Node3D=high[int(high.size()/2.0)]
			var hit:=ray(t.global_position+Vector3.UP,t.global_position-Vector3.UP*.6)
			var collides:bool=not hit.is_empty() and s2.is_ancestor_of(hit.collider)
			print("CROWN ",tag," high_treads=",high.size()," visible=",t.is_visible_in_tree()," processing=",s2.can_process()," collides=",collides)
			if not xr:fit_notes.append({"id":STAIRS,"seen_from_floor1":{"treads_above_floor1":high.size(),"visible":t.is_visible_in_tree(),"processing":s2.can_process(),"collides":collides}})

func metallophone_checks(tag: String) -> void:
	var rig:Node3D=artifact("resonating_metallophone")
	check(tag+"metallophone keeps its table stand and eight bars",rig.stand=="table" and rig.bars.size()==8)
	check(tag+"table bars are frozen by the Jolt adapter, strike zones intact",rig.get_script().resource_path=="res://commons/void/metallophone_local.gd" and rig.bars.all(func(b):return b.freeze and b.get_node_or_null("StrikeZone")!=null))
	var stick:Node3D=rig.get_stick()
	var tip:Node3D=stick.get_node("Blade/Top/TrackBall")
	# Desktop holds the striker at arm's length in front of the camera: stand back.
	await stand_local(rig,Vector3(-.45,.06,.95 if xr else 1.9))
	rig.stop_all_resonances()
	await grab_stick(tag,stick)
	if not stick.is_picked_up():return
	await input_tip_to(tip,rig.bars[0].global_position+Vector3.UP*.4)
	rig.stop_all_resonances()
	await input_tip_to(tip,rig.bars[0].global_position+Vector3.UP*.11)
	check(tag+"held striker tip rings a bar",rig.bars[0].audio_player.playing)
	var zone:Area3D=rig.bars[0].get_node_or_null("StrikeZone")
	print("STRIKE ",tag," held=",stick.is_picked_up()," tip_err=",tip.global_position.distance_to(rig.bars[0].global_position+Vector3.UP*.11)," frozen=",rig.bars[0].freeze," zone=",zone.get_overlapping_bodies().map(func(b):return str(b.get_path())) if zone!=null else "none")
	await input_tip_to(tip,rig.bars[0].global_position+Vector3.UP*.4)
	await input_tip_to(tip,rig.bars[3].global_position+Vector3.UP*.4)
	await input_tip_to(tip,rig.bars[3].global_position+Vector3.UP*.11)
	check(tag+"second held strike overlaps the first voice",rig.bars[0].audio_player.playing and rig.bars[3].audio_player.playing)
	check(tag+"table readout sums the sampled bar audio",rig.visualizer.sample_audio and rig.visualizer._audio_windows.size()>=2 and rig.visualizer._summed_samples.size()==512)
	await input_tip_to(tip,rig.bars[7].global_position+Vector3.UP*.6)
	var returns:int=rig.stick_returns
	await drop_point()
	for i in 300:
		await frames(1)
		if rig.stick_returns>returns:break
	check(tag+"dropped striker returns to its cradle",rig.stick_returns>returns)

func grab_stick(tag: String, stick: Node3D) -> void:
	var shape:Node3D=stick.get_node("CollisionShape3D")
	if xr:
		await palm_at(shape.global_position);right.set_input("grip",1.0);await frames(18)
	else:
		Input.mouse_mode=Input.MOUSE_MODE_CAPTURED;await input_aim_camera(shape.global_position,15)
		await mouse_button(MOUSE_BUTTON_RIGHT,true);await mouse_button(MOUSE_BUTTON_RIGHT,false)
	check(tag+"real "+("grip" if xr else "mouse")+" picks up the original striker",stick.is_picked_up())

## The gallery sets each pickable's collider at its mesh centre, not at the
## wrapper origin: aim the mouse ray or palm at the collider.
func grab_body(tag: String, body: Node3D, _family: Array, label: String) -> void:
	await input_grab(tag+label+" / ",body,body.get_node("CollisionShape3D"))

## Real pointer drag: mouse button held (desktop) or trigger held (XR) while the
## ray moves from `from` to `to`; the slider's scalar_pointer reads the events.
func pointer_drag(from: Vector3, to: Vector3) -> void:
	if not xr:
		Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
		for i in 20:
			game.camera.look_at(from);await frames(1)
		var e:=InputEventMouseButton.new();e.button_index=MOUSE_BUTTON_LEFT;e.pressed=true
		Input.parse_input_event(e);await frames(4)
		for i in 16:
			game.camera.look_at(from.lerp(to,(i+1)/16.0));await frames(2)
		e=InputEventMouseButton.new();e.button_index=MOUSE_BUTTON_LEFT;e.pressed=false
		Input.parse_input_event(e);await frames(8)
		return
	for i in 20:
		aim_pointer(from);await frames(1)
	right.set_input("trigger_click",true);await frames(4)
	for i in 16:
		aim_pointer(from.lerp(to,(i+1)/16.0));await frames(2)
	right.set_input("trigger_click",false);await frames(8)

func aim_pointer(target: Vector3) -> void:
	var origin:Node3D=game.get_node("XROrigin3D")
	var pointer:Node3D=game.pointers[1]
	var at:Vector3=game.camera.global_position+Vector3(.1,-.2,0)
	var aim:=Basis.looking_at(target-at)
	at-=aim*Vector3(0,pointer.y_offset*XRServer.world_scale,0)
	right.set_pose("aim",Transform3D(origin.global_basis.inverse()*aim,origin.to_local(at)),Vector3.ZERO,Vector3.ZERO,XRPose.XR_TRACKING_CONFIDENCE_HIGH)

func drone_checks(tag: String) -> void:
	var rack:Node3D=artifact("RackAmbientDrone")
	var play:Node3D=null
	var stop:Node3D=null
	var freq:Node3D=null
	for c in rack._active_controls.values():
		var action:String=str(c["config"].get("action",""))
		if action=="play":play=c["node"]
		elif action=="stop":stop=c["node"]
		if str(c["parameter"])=="frequency":freq=c["node"]
	check(tag+"drone rack builds PLAY, STOP and three sliders",play!=null and stop!=null and freq!=null and rack._active_controls.size()==5)
	if play==null or stop==null or freq==null:return
	await stand_local(rack,Vector3(0,-.94,1.1))
	await press(play);await frames(10)
	check(tag+"PLAY with real pointer starts the drone voice",rack._audio_player.playing and rack._audio_player.stream!=null)
	var aimed:Vector3=play.get_node("InteractableAreaButton/CollisionShape3D").global_position
	var seen:=ray(game.camera.global_position,aimed+(aimed-game.camera.global_position).normalized()*.3)
	print("DRONE ",tag," playing=",rack._audio_player.playing," eye_to_button_hits=",str(seen.collider.get_path()) if not seen.is_empty() else "nothing")
	freq.set_normalized_value(.25);freq.slider_moved.emit(.25);await frames(5)
	check(tag+"FREQ slider API sets 515 Hz",absf(float(rack.get_current_values()["frequency"])-515.0)<1.0)
	await press(stop);await frames(5)
	check(tag+"STOP with real pointer silences the drone",not rack._audio_player.playing)

func sky_stairs_checks(tag: String) -> void:
	var spec=game.building.spec
	var y:float=spec.levels[level]
	var ceiling:float=float(spec.levels[level-1])-float(spec.slab_thickness)
	var stairs:Node3D=artifact("sine_cylinder_staircase")
	var treads:Array=stairs.get_node("StairSteps").get_children()
	var half:float=stairs.STEP_THICKNESS*.5
	var tops:Array=treads.map(func(t):return t.global_position.y+half-y)
	check(tag+"staircase keeps 80 treads and its full rise",treads.size()==80 and absf(float(tops.back())-stairs.STEP_RISE*79.0)<.02)
	var through:int=tops.filter(func(h):return y+h>ceiling).size()
	var headroom:=-1
	for i in tops.size():
		if y+float(tops[i])+1.7>ceiling:
			headroom=i
			break
	var at:Vector3=treads[10].global_position+Vector3(0,half+.06,0)
	game.place_player(at);await frames(40)
	var stood:float=game.body.global_position.y-(at.y-.06)
	check(tag+"tread 10 holds a standing visitor 1.1 m up",game.body.is_on_floor() and not game.recovering and stood>-.05 and stood<.5)
	var climbed:Dictionary=await climb(treads)
	if not xr:
		fit_notes.append({"id":STAIRS,"treads":treads.size(),"rise_m":tops.back(),"ceiling_above_floor_m":ceiling-y,"treads_above_upper_slab_underside":through,"first_tread_without_1_7_m_headroom":headroom,"tread10_stand_offset_m":stood,"desktop_climb":climbed})
	else:
		fit_notes.append({"id":STAIRS,"xr_tread10_stand_offset_m":stood,"xr_climb":climbed})
	print("STAIRS ",tag," through=",through," headroom_tread=",headroom," stood=",stood," climb=",climbed)
	game.place_player(game.spawn_for(level));await frames(20)
	await gallery_checks(tag)
	var cube:Node3D=artifact("cube_scene")
	var boxes:Array=[];geometry(cube,boxes)
	var b:AABB=boxes[0]
	for box in boxes:b=b.merge(box)
	var c:Vector3=b.get_center()
	var hit:=ray(Vector3(c.x,b.end.y+.5,c.z),Vector3(c.x,b.position.y-.1,c.z))
	check(tag+"reference cube keeps its own collision",not hit.is_empty() and cube.is_ancestor_of(hit.collider))

func gallery_checks(tag: String) -> void:
	var y:float=game.building.spec.levels[level]
	var gallery:Node3D=artifact("math_objects")
	# Duck-typed: naming the XR Tools class here compiles player_body before its autoload exists.
	var objs:Array=gallery.get_children().filter(func(n):return n.has_method("is_picked_up"))
	check(tag+"math gallery keeps 33 pickable parametric bodies",objs.size()==33)
	await stand_local(gallery,Vector3(-.95,.06,0))
	var shaped:Array=objs.filter(func(o):return o.get_node_or_null("CollisionShape3D")!=null and o.get_node("CollisionShape3D").shape!=null)
	print("GALLERY ",tag," bodies=",objs.size()," with_shape=",shaped.size()," frozen=",objs.filter(func(o):return o.freeze).size()," layer=",objs[0].collision_layer if not objs.is_empty() else -1)
	# Bodies whose own scene is the pickable keep the default physics layer 1, which
	# DesktopHand's GRAB_MASK (393220: layers 3/18/19) and the XR grab area exclude.
	var grabbable:Array=shaped.filter(func(o):return (o.collision_layer&393220)!=0)
	var off_layer:Array=objs.filter(func(o):return (o.collision_layer&393220)==0).map(func(o):return str(o.name)+"@"+str(o.collision_layer))
	print("GALLERY_LAYERS ",tag," on_grab_layers=",grabbable.size(),"/",objs.size()," off=",off_layer)
	if not xr:fit_notes.append({"id":"f2_math_objects_19_17","bodies":objs.size(),"on_grab_layers":grabbable.size(),"off_grab_layers":off_layer})
	check(tag+"gallery grab-layer adapter puts all 33 bodies on a grab layer",gallery.get_script().resource_path=="res://commons/void/math_gallery_local.gd" and grabbable.size()==33)
	var eye:Vector3=game.camera.global_position
	grabbable.sort_custom(func(a,b):return a.global_position.distance_to(eye)<b.global_position.distance_to(eye))
	var trefoils:Array=grabbable.filter(func(o):return o.get_script()!=null and o.get_script().resource_path.ends_with("trefoil_knot.gd"))
	var wrapped:Array=grabbable.filter(func(o):return o.get_script()!=null and o.get_script().resource_path.ends_with("objects/pickable.gd"))
	for pair in [["Trefoil (source layer 1)",trefoils],["wrapped surface",wrapped]]:
		if (pair[1] as Array).is_empty():
			check(tag+"gallery has a "+str(pair[0])+" to grab",false);continue
		await grab_body(tag,pair[1][0],objs,str(pair[0]));await drop_point();await frames(40)
	check(tag+"gallery bodies rest on floor 2, none lost to the shaft",objs.all(func(o):return is_instance_valid(o) and o.global_position.y>y-.2 and o.global_position.y<y+2.5))

## Walk tread to tread from the floor (real drive input); report the height reached.
## Walking first; a jump (Space / A) only when a tread is not gained by walking.
func climb(treads: Array) -> Dictionary:
	var y:float=game.building.spec.levels[level]
	var start:Vector3=treads[0].global_position-treads[0].global_basis.z*.9
	start.y=y+.06
	game.place_player(start);await frames(25)
	var report:={"best_m":0.0,"walked_treads":0,"jumped_treads":0,"travel_m":0.0}
	var last:Vector3=game.body.global_position
	var stalled:=0
	for i in range(1,40):
		var target:Vector3=treads[i].global_position
		var before:float=game.body.global_position.y
		await steer(target,45)
		var jumped:=false
		if game.body.global_position.y<before+.05 and not game.recovering:
			press_jump();await frames(2);release_jump()
			await steer(target,40);jumped=true
		var at:Vector3=game.body.global_position
		report["travel_m"]+=Vector2(at.x-last.x,at.z-last.z).length();last=at
		var h:float=at.y-y
		if h>float(report["best_m"])+.05:
			report["best_m"]=h;stalled=0
			if jumped:report["jumped_treads"]+=1
			else:report["walked_treads"]+=1
		else:stalled+=1
		if stalled>=3 or game.recovering:break
	axes(Vector2.ZERO);await frames(10)
	report["recovering"]=game.recovering
	return report

func steer(target: Vector3, limit: int) -> void:
	for f in limit:
		var at:Vector3=game.body.global_position
		var off:=Vector2(target.x-at.x,target.z-at.z)
		if off.length()<.15 or game.recovering:break
		axes(off.normalized());await frames(1)
	axes(Vector2.ZERO)

## The visitor stands at the floor spawn during a photo: hide its inferred body
## and the camera-held CHARGE readout so they do not cover an eye-height view.
func photo(filename: String, at: Vector3, target: Vector3) -> void:
	var hidden:Array=[]
	for node in [game.get_node_or_null("CareBody"),game.charge_display]:
		if node!=null and node.visible:
			node.visible=false;hidden.append(node)
	await super.photo(filename,at,target)
	for node in hidden:
		if is_instance_valid(node):node.visible=true

func capture_floor() -> void:
	var y:float=game.building.spec.levels[level]
	match level:
		1:
			await photo("01-airmusic-arrival-eye",Vector3(0,y+1.65,12.5),Vector3(0,y+1.1,2))
			await photo("02-metallophone-eye",Vector3(4.6,y+1.65,10),Vector3(4,y+.95,8))
			await photo("03-racks-drone-case",Vector3(0,y+2.6,5),Vector3(-5,y+1,1))
			await photo("04-systems-music-pipe",Vector3(.5,y+3.2,3),Vector3(5,y+.5,-3.5))
			await photo("05-floor1-stair-crowns",Vector3(-4,y+2.4,-2),Vector3(1.5,y+1,-9.5))
		2:
			await photo("06-skystairs-arrival-eye",Vector3(0,y+1.65,12.5),Vector3(1.5,y+2.2,-9.5))
			await photo("07-staircase-into-slab",Vector3(-7,y+2.2,-1),Vector3(1.5,y+3.5,-9.5))
			await photo("08-math-objects-eye",Vector3(-2.6,y+1.7,-1.2),Vector3(-5,y+.15,-3))
