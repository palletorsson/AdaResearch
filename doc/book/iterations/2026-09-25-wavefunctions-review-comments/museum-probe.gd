extends "res://tools/probes/transformation_encounters.gd"

func landing_checks() -> void:
	museum.flush_stamps()
	await create_timer(2.0).timeout
	for n in museum.find_children("*MushroomHand*","Node3D",true,false):n.visible=false
	match map_id:
		"WaveFunctions_Unit_Circle":await circle_checks()
		"WaveFunctions_Synthesis_Lab":await synthesis_checks()
		"WaveFunctions_3D_Wave_Propagation":await lattice_checks()

func platforms(circle: Node3D) -> Array:
	var result: Array=[]
	for c in circle.get_children():
		if str(c.name).begins_with("Platform_"):result.append(c)
	return result

func circle_checks() -> void:
	var circle := find_scene("/UnitCircle.gd")
	check("unit circle is present in the museum",circle!=null)
	if circle==null:return
	circle.set_process(false)
	observations["circle_transform"]=str(circle.global_transform)
	check("whole circle is above the museum floor",circle.global_position.y-circle.radius>hall.global_position.y+0.1)
	var support := floor_at(Vector3(circle.global_position.x+3,hall.global_position.y,circle.global_position.z))
	observations["view_support"]=str(support)
	for i in 1200:
		if circle.finished:break
		circle._process(1.0/60)
	check("finite graph completes",circle.finished)
	var count: int=circle.samples_per_cycle*circle.num_cycles
	var pieces: Array=platforms(circle)
	check("graph contains its declared sample count",pieces.size()==count)
	var before_geometry: Array=[]
	for c in pieces:before_geometry.append(str(c.transform))
	var before: Vector3=circle.rotating_point.position
	var old_angle: float=circle.angle
	circle._process(PI/(2*circle.rotation_speed))
	var after: Vector3=circle.rotating_point.position
	observations["finished_motion"]={"before":xyz(before),"after":xyz(after),"old_angle":old_angle,"angle":circle.angle,"sample_count":count}
	var updated := FileAccess.get_file_as_string("res://algorithms/wavefunctions/unit_circle/UnitCircle.gd").contains("continue_after_build")
	if not updated:
		check("baseline freezes a late visitor's point",before.is_equal_approx(after))
	else:
		check("hall opts into continuing projection",circle.continue_after_build)
		check("late point advances a quarter turn",absf(before.dot(after))<0.0001 and absf(before.length()-after.length())<0.0001)
		check("angle stays bounded",circle.angle>=0 and circle.angle<TAU)
	var after_geometry: Array=[]
	for c in platforms(circle):after_geometry.append(str(c.transform))
	check("complete graph is not rebuilt or moved",before_geometry==after_geometry and circle.built_index==count-1)
	var eye: Vector3=circle.to_global(Vector3(0.0,0,-3.0));eye.y=hall.global_position.y+1.7
	await snapshot("circle-late-arrival",eye,circle.global_position+circle.global_basis*Vector3(0.5,0,0),62)
	if updated:
		circle.angle=0;circle._process(0)
		await snapshot("circle-right",eye,circle.global_position+circle.global_basis*Vector3(0.5,0,0),62)
		circle._process(PI/(2*circle.rotation_speed))
		check("top has zero cosine and full sine",circle.rotating_point.position.is_equal_approx(Vector3(0,circle.radius,0)))
		check("vertical rod reaches radius",absf(circle.sine_line.get_node("Rod").scale.z-circle.radius)<0.0001)
		await snapshot("circle-top",eye,circle.global_position+circle.global_basis*Vector3(0.5,0,0),62)
		var held: Vector3=circle.rotating_point.position
		circle.apply_grid_config({"continue_after_build":false});circle._process(2)
		check("non-opted-in complete figures retain held pose",circle.rotating_point.position.is_equal_approx(held))
		circle.apply_grid_config({"continue_after_build":"true"});circle._process(300)
		check("long running point remains bounded without new steps",circle.angle>=0 and circle.angle<TAU and platforms(circle).size()==count)

func bench_button(bench: Node3D, id: int) -> void:
	var button: Node = bench._panel.find_child("Btn_"+str(id),true,false).get_node("InteractableAreaButton")
	button.button_pressed.emit(button)
	bench._process(0)

func synthesis_checks() -> void:
	var bench := find_scene("/additive_wave_demo.gd")
	check("placed synthesis bench exists",bench!=null)
	if bench==null:return
	bench.set_process(false)
	check("bench begins with five baseline amounts",bench.harmonic_amplitudes==bench.get_baseline() and bench.harmonic_amplitudes.size()==5)
	check("bench begins running",not bench.held)
	bench_button(bench,2)
	bench_button(bench,0)
	var held_time: float=bench._time
	var kept=bench.display_values(bench.mark_index())
	var coefficient: float=bench.harmonic_amplitudes[4]
	bench.harmonic_sliders[4].set_normalized_value(0.8)
	bench.harmonic_sliders[4].slider_moved.emit(Vector3.ZERO)
	bench._process(0)
	check("real fifth slider changes one coefficient",is_equal_approx(bench.harmonic_amplitudes[4],0.8) and bench.harmonic_amplitudes.slice(0,4)==bench.get_baseline().slice(0,4))
	bench._process(1.0)
	check("HOLD keeps phase while coefficients change",is_equal_approx(bench._time,held_time))
	var eye: Vector3=bench.to_global(Vector3(-0.2,1.7,2.3))
	await snapshot("sum-fifth-raised",eye,bench.to_global(Vector3(0,1.5,0)),56)
	bench_button(bench,0)
	check("BASELINE restores coefficients and held marker values",is_equal_approx(bench.harmonic_amplitudes[4],coefficient) and bench.display_values(bench.mark_index())==kept)
	await snapshot("sum-returned",eye,bench.to_global(Vector3(0,1.5,0)),56)
	bench_button(bench,2)
	bench._process(0.317)
	var advanced: float=bench._time
	bench_button(bench,0)
	check("BASELINE leaves advancing phase alone",not is_equal_approx(advanced,held_time) and is_equal_approx(advanced,bench._time))
	observations["bench_return"]={"held_time":held_time,"advanced_time":advanced,"baseline":bench.get_baseline(),"held_marker":kept}
	check("room entry artifact remains in this hall",find_scene("/ambient_patch.gd")!=null)

func lattice_checks() -> void:
	var lattice := find_scene("/coupled_oscillator_lattice.gd")
	check("comparison lattice exists",lattice!=null)
	if lattice==null:return
	lattice.set_process(false);lattice.set_physics_process(false)
	check("initial captions are SINE and COUPLED",lattice._comparison_labels.DRIVE.text=="SINE" and lattice._comparison_labels.COUPLING.text=="COUPLED")
	lattice.buttons.DRIVE.pressed.emit()
	check("SINE button changes caption to PULSE and restarts",lattice._comparison_labels.DRIVE.text=="PULSE" and lattice.time==0)
	for i in 120:lattice.comparison_step(1.0/60)
	var connected: float=lattice._neighbor_peak
	lattice._update_visualization();lattice._refresh_comparison()
	var eye: Vector3=lattice.to_global(Vector3(4.4,1.7,1.0))
	await snapshot("pulse-coupled",eye,lattice.to_global(Vector3(0.4,0.8,0.5)), 60.0)
	lattice.buttons.COUPLING.pressed.emit()
	check("COUPLED changes caption to INDEPENDENT and restarts",lattice._comparison_labels.COUPLING.text=="INDEPENDENT" and lattice.time==0)
	for i in 120:lattice.comparison_step(1.0/60)
	var disconnected: float=lattice._neighbor_peak
	lattice._update_visualization();lattice._refresh_comparison()
	check("same pulse reaches neighbours only through coupling",connected>0 and is_zero_approx(disconnected))
	await snapshot("pulse-independent",eye,lattice.to_global(Vector3(0.4,0.8,0.5)),60.0)
	lattice.buttons.COUPLING.pressed.emit()
	check("INDEPENDENT restores COUPLED",lattice._comparison_labels.COUPLING.text=="COUPLED" and lattice.time==0)
	observations["pulse_peak_m"]={"coupled":connected,"independent":disconnected}



