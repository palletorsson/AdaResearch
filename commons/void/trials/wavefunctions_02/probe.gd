extends "res://commons/void/trials/formfinding_02/probe.gd"

func expected_empty_source(node: Node3D) -> bool:
	return node.get_meta("artifact_lookup_name","")=="BigPipeSystem"

func focused_checks(tag: String) -> void:
	check(tag+"standard floor "+str(level),game.building.spec.width==42 and game.building.spec.depth==32 and game.building.spec.storey_height==6)
	match level:
		1:await pendulum_checks(tag)
		2:await sine_checks(tag)
		3:await circle_checks(tag)
		4:await wave_checks(tag)
	game.place_player(game.spawn_for(level));await frames(15)

func pendulum_checks(tag: String) -> void:
	var p:Node3D=artifact("PendulumWave")
	await stand_local(p,Vector3(-3,.06,0))
	await press(p._panel.find_child("Btn_1",true,false));await frames(30)
	check(tag+"COARSE changes original sampler",p.sampler=="coarse" and p.current_interval()>.1)
	await press(p._panel.find_child("Btn_2",true,false))
	check(tag+"STROBE selects original sampling mode",p.sampler=="strobe")
	await press(p._panel.find_child("Btn_0",true,false));await frames(30)
	check(tag+"FINE resumes clocked samples",p.sampler=="fine" and p.sample_count()>0 and p.gallery_open)
	var draw:Node3D=artifact("draw_dot_time_domain")
	# Stand at floor height, not at the raised instrument's mounting height.
	await stand_local(draw,Vector3(-.5,-1.04,1))
	await grab_point(tag,draw._grab_point);await frames(35)
	check(tag+"held point records time-domain trace",draw._trail_points.size()>2 and draw._origin_set)
	await drop_point()
	var f:Node3D=artifact("foucault_pendulum")
	var a:float=f.earth_angle;await frames(20)
	check(tag+"Foucault original precession and scale",f.earth_angle>a and is_equal_approx(f.scale.x,.65))
	var pipe:Node3D=artifact("BigPipeSystem")
	check(tag+"pipe preserves known empty source and its inert path token",not pipe.auto_build and pipe._curves.is_empty() and pipe.get_meta("config_path")=="straight,corner_right,straight")

func sine_checks(tag: String) -> void:
	var tray:Node3D=artifact("sine_flow_tray")
	await stand_local(tray,Vector3(-3.4,.06,0))
	await press(tray.buttons.RELEASE);await frames(40)
	check(tag+"RELEASE runs original 32-body experiment",tray.bodies.size()==32 and tray.running and tray.ticks>0)
	await press(tray.buttons.RELIEF)
	check(tag+"RELIEF rebuilds and resets experiment",tray.relief_index==2 and tray.bodies.is_empty())
	await press(tray.buttons.RULE)
	check(tag+"RULE shows original sampling equation",tray.reveal and "sin" in tray.panel.readout.text)
	var corridor:Node3D=artifact("sine_wall_corridor")
	await stand_local(corridor,Vector3(-1,.06,-5))
	await press(corridor._panel.find_child("Btn_0",true,false))
	check(tag+"FREEZE stops corridor phase",not corridor.animate_at_runtime)
	await press(corridor._panel.find_child("Btn_1",true,false))
	check(tag+"RESET restores declared corridor motion",corridor.animate_at_runtime and is_equal_approx(corridor.base_amplitude,.2))
	var surface:Node3D=artifact("sine_space")
	check(tag+"original 14 by 18 metre walk surface",surface.floor_mode=="walk" and surface.walk_width==14 and surface.walk_depth==18 and surface.walk_floor!=null)
	var at:Vector3=surface.to_global(Vector3(0,1,0))
	check(tag+"sine surface has native collision",not ray(at,at-Vector3(0,2,0)).is_empty())

func circle_checks(tag: String) -> void:
	var circle:Node3D=artifact("unit_circle_advanced")
	await stand_local(circle,Vector3(0,.06,2.1))
	await press(circle.gallery_controls.play_button.get_parent())
	check(tag+"RUN PAUSE stops original projection",not circle.running)
	circle.gallery_controls.slider.set_normalized_value(.25)
	circle.gallery_controls.slider.slider_moved.emit(.25)
	await frames(5)
	check(tag+"slider API changes angle to quarter turn",is_equal_approx(circle.angle,PI*.5))
	await press(circle.gallery_controls.replay_button.get_parent());await frames(20)
	check(tag+"REPLAY resumes graph construction",circle.running and circle.built_index>=0)
	var film:Node3D=artifact("film_circle_projection")
	await stand_local(film,Vector3(0,.06,1.7));await press(film.buttons.pause)
	check(tag+"projection film pauses with real pointer",not film.stage.running and film.viewport.own_world_3d)
	var balls:Node3D=artifact("colorballs")
	check(tag+"colour bodies remain on their editable floor below world zero",balls.ball_bodies.all(func(b):return b.global_position.y< -12 and b.global_position.y> -24))

func wave_checks(tag: String) -> void:
	var lattice:Node3D=artifact("coupled_oscillator_lattice")
	await stand_local(lattice,Vector3(4.1,.06,1.2))
	await press(lattice.buttons.COUPLING)
	check(tag+"COUPLING isolates original oscillators",not lattice._coupled and lattice.coupling_strength==0)
	await press(lattice.buttons.DRIVE)
	check(tag+"DRIVE changes sine to pulse",lattice.excitation_mode=="Pulse")
	await press(lattice.buttons.COUPLING);await frames(40)
	check(tag+"coupled lattice advances with bonds",lattice._coupled and lattice._bond_mm!=null and lattice.simulation_steps>0)
	var pool:Node3D=artifact("wave_propagation_3d")
	var time_before:float=pool.time;await frames(20)
	check(tag+"pool retains 400 moving collision tiles",pool.time>time_before and pool.find_children("*","AnimatableBody3D",true,false).size()==400)
	var film:Node3D=artifact("film_wave_neighbours")
	await stand_local(film,Vector3(0,.06,1.7));await press(film.buttons.pause)
	check(tag+"neighbour film pauses independently",not film.stage.running)

func capture_floor() -> void:
	var y:float=game.building.spec.levels[level]
	match level:
		1:
			await photo("01-pendulum-and-recorder",Vector3(-1,y+2.6,10),Vector3(-9,y+1.4,4))
			await photo("02-foucault-and-paintings",Vector3(7,y+3,1),Vector3(10,y+1.8,-7))
		2:
			await photo("03-sine-tray",Vector3(-8,y+2.8,12),Vector3(-4,y+1,7))
			await photo("04-sine-surface",Vector3(11,y+4,1),Vector3(0,y+1,-9))
		3:await photo("05-unit-circle",Vector3(1,y+3,10),Vector3(-4,y+1.8,4))
		4:
			await photo("06-wave-pool",Vector3(-7,y+4.5,12),Vector3(1,y+1.5,3))
			await photo("07-coupled-lattice",Vector3(6,y+3,14),Vector3(10.5,y+1,9))
