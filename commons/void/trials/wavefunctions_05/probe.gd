extends "res://commons/void/trials/wavefunctions_04/probe.gd"
## Original controls, native pointer input and measured source geometry.
func expected_empty_source(_node: Node3D) -> bool:
	return false

func debug_cases() -> Dictionary:
	return {"walking":1,"beat":1,"synthesis":2,"case":2}

func run_debug_case(name: String, tag: String) -> void:
	match name:
		"walking":await walking_checks(tag)
		"beat":await beat_checks(tag)
		"synthesis":await synthesis_checks(tag)
		"case":await case_checks(tag)

func focused_checks(tag: String) -> void:
	check(tag+"standard 42 x 32 m floor",game.building.spec.width==42 and game.building.spec.depth==32)
	await fit_checks(tag)
	if level==1:
		await walking_checks(tag);await beat_checks(tag)
	else:
		await synthesis_checks(tag);await case_checks(tag)
	game.place_player(game.spawn_for(level));await frames(15)

func fit_checks(tag: String) -> void:
	var y:float=game.building.spec.levels[level]
	var sign:Array=game.building.spec.get("floor_sign_positions",{}).get(str(level),[3.5,-7.8])
	var zones:Array=[AABB(Vector3(-12.5,y,-3),Vector3(5,5.64,6)),AABB(Vector3(7.5,y,-3),Vector3(5,5.64,6)),AABB(Vector3(-1,y+.1,11),Vector3(2,2,2)),AABB(Vector3(sign[0]-1.85,y+.525,sign[1]-.06),Vector3(3.7,1.65,.12))]
	var conflicts:Array=[]
	for e in game.building.content.data.floors[level].artifacts:
		var boxes:Array=[];geometry(station(e.id),boxes)
		for i in zones.size():
			if boxes.any(func(b):return b.intersects(zones[i])):conflicts.append(e.id+" / "+["shaft A","shaft B","arrival","floor sign"][i])
	check(tag+"source meshes clear both shaft openings, arrival and floor sign",conflicts.is_empty())
	print("FIT ",tag," ",level," ",conflicts)

func walking_checks(tag: String) -> void:
	var path:Node3D=artifact("TrigWalkingPath")
	check(tag+"original two lanes retain 40 steps each",path.sine_steps.size()==40 and path.cosine_steps.size()==40 and path.escalator_mode)
	check(tag+"standalone reference floor and camera excluded",not path.has_node("FloorReference") and not path.has_node("Camera3D"))
	var tread:Node3D=path.sine_steps[20]
	var before:Vector3=tread.global_position
	await frames(30)
	check(tag+"original escalator steps circulate",tread.global_position.distance_to(before)>.1)
	var hit:Dictionary=ray(tread.global_position+Vector3.UP*.5,tread.global_position-Vector3.UP*.5)
	check(tag+"moving tread has its original collision",not hit.is_empty() and (hit.collider==tread or path.is_ancestor_of(hit.collider)))
	print("PATH ",tag," tread=",tread.global_position," source height=",path.get_parent().position.y," body type=",tread.get_class())
	# Source uses StaticBody3D steps. Motion/collision is proven; carried-body
	# locomotion and access to this elevated path remain curation work.

func beat_checks(tag: String) -> void:
	var beat:Node3D=artifact("beat_frequency_demo")
	check(tag+"three original rows retain 64 samples",beat._spheres_a.size()==64 and beat._spheres_b.size()==64 and beat._spheres_sum.size()==64)
	var slider:Node3D=beat.find_child("Param_0",true,false)
	var handle:Node3D=slider.get_node("SliderOrigin/InteractableSlider/HandleOrigin/InteractableHandle")
	await stand_local(beat,Vector3(.35,-.025,.85))
	var before:float=beat._freq_a
	await pointer_drag(handle.global_position,handle.global_position+slider.global_basis.x.normalized()*.08)
	check(tag+"real pointer changes beat frequency A",absf(beat._freq_a-before)>.1)
	var a:float=beat._spheres_a[17].position.y-beat._base_y-beat.row_spacing
	var b:float=beat._spheres_b[17].position.y-beat._base_y
	var sum:float=beat._spheres_sum[17].position.y-beat._base_y+beat.row_spacing
	check(tag+"displayed third row is the half-sum",absf(sum-(a+b)*.5)<.0001)

func synthesis_checks(tag: String) -> void:
	var demo:Node3D=artifact("additive_wave_demo")
	check(tag+"source bench and withheld recipe name preserved",demo.stand=="bench" and demo.name_after_compare and demo.get_baseline().size()==5)
	await stand_local(demo,Vector3(-.8,.06,1.65))
	await press(demo._panel.find_child("Btn_1",true,false))
	check(tag+"H1 ALONE removes four higher harmonics",demo.harmonic_amplitudes.slice(1).all(func(a):return is_zero_approx(a)) and demo._comparison_made)
	await press(demo._panel.find_child("Btn_0",true,false))
	check(tag+"BASELINE restores original sawtooth coefficients",demo.harmonic_amplitudes==demo.get_baseline() and demo.harmonic_amplitudes[1]>.1)
	await press(demo._panel.find_child("Btn_2",true,false))
	var phase:float=demo.phase_at(50);await frames(20)
	check(tag+"HOLD freezes phase",demo.held and is_equal_approx(demo.phase_at(50),phase))
	var sample:Dictionary=demo.display_values(50)
	check(tag+"sampled drawn rows sum to displayed total",absf(sample.sum_of_drawn_rows-sample.total)<.0001)
	await press(demo._panel.find_child("Btn_2",true,false))
	var rack:Node3D=artifact("GlassRack")
	check(tag+"spiral tube token builds the authored apparatus",rack.config_file in ["spiral_tube","spiral_tube.json"] and rack.find_child("Frame",true,false)==null)

func case_checks(tag: String) -> void:
	var display:Node3D=artifact("air_music_display_case")
	var slider:Node3D=display._volume_slider
	var handle:Node3D=slider.get_node("SliderOrigin/InteractableSlider/HandleOrigin/InteractableHandle")
	await stand_local(display,Vector3(0,-.34,.95))
	var before:float=display.audio_volume_db
	await pointer_drag(handle.global_position,handle.global_position-slider.global_basis.x.normalized()*.05)
	var voices:Array=display.air_music_instance.get_node("FMPianoSynth")._players
	check(tag+"case VOLUME controls original synthesiser",display.audio_volume_db<before-1 and voices.all(func(v):return is_equal_approx(v.volume_db,display.audio_volume_db)))

func capture_floor() -> void:
	var y:float=game.building.spec.levels[level]
	if level==1:
		await photo("01-walking-lanes",Vector3(-12,y+4,12),Vector3(-17,y+2.7,-2))
		await photo("02-beat-and-waves",Vector3(0,y+2,11),Vector3(1,y+1.6,5))
	else:
		await photo("03-synthesis-bench",Vector3(0,y+1.8,10),Vector3(0,y+1.4,7))
		await photo("04-laboratory",Vector3(10,y+3.5,12),Vector3(-3,y+1,-4))
