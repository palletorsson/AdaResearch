extends "res://commons/artifacts/spine_films/film_stage.gd"
const Kit = preload("res://commons/artifacts/spine_films/middle/film_kit.gd")
var records: Array[PackedVector3Array] = []
var links: Array = []
var pins := PackedInt32Array()
var grip_index := 0
var skin: MeshInstance3D
var network: MeshInstance3D
var handle: MeshInstance3D
var pin_dots: Array[MeshInstance3D] = []
var readout: Label3D
var indices := PackedInt32Array()
var drawn_record := -1

func _build() -> void:
	title_text = "A SHEET IS HELD BY RELATIONS"
	duration = 26.0
	phases.assign(["FOUR FIXED POINTS", "REVEAL THE DISTANCE LINKS", "PULL ONE POINT", "RELEASE, KEEP THE RELATIONS"])
	notes.assign(["The actual membrane solver settles a waisted sheet between four pins.", "The skin opens to reveal stored positions and the solver's distance links.", "A recorded handle pull moves one point. The constraints distribute its effect.", "Release lets gravity and damping act again. Six simulated seconds are slowed for inspection."])
	source_paths.assign(["res://commons/artifacts/spine_studies/tension_score.gd","res://commons/artifacts/spine_studies/tension_membrane.gd"])
	var score = load(source_paths[0]).new()
	for settling_step in 600: score.step()
	pins = score.pins.duplicate(); grip_index = score.grip_index
	for link in score.links: links.append(link)
	var start: Vector3 = score.points[grip_index]
	var maximum_pin_error := 0.0
	for tick in 721:
		var seconds := tick/120.0
		score.grip_held = seconds >= 1.0 and seconds < 3.0
		score.grip_target = start.lerp(Vector3(.65,3.1,1.8),Kit.progress(seconds,1.0,2.2))
		if tick%4 == 0:
			records.append(score.points.duplicate())
			for pin in pins: maximum_pin_error = maxf(maximum_pin_error,score.points[pin].distance_to(score.rest[pin]))
		score.step()
	indices = Kit.grid_indices(score.NX,score.NZ)
	var fabric := Kit.material(Kit.WHITE)
	fabric.cull_mode = BaseMaterial3D.CULL_DISABLED
	skin = Kit.node(display,Kit.surface(records[0],indices),Vector3.ZERO,fabric)
	network = Kit.wire(display,records[0],links,Kit.material(Kit.TEAL,true))
	handle = Kit.dot(display,records[0][grip_index],.11,Kit.material(Kit.PINK,true))
	for pin in pins:
		var point: Vector3 = records[0][pin]
		Kit.rod(display,Vector3(point.x,0,point.z),point,.065,Kit.material(Color("677784")))
		pin_dots.append(Kit.dot(display,point,.1,Kit.material(Kit.GOLD,true)))
	readout = Kit.label(display,"",Vector3(0,3.8,0),Kit.WHITE,.006)
	evidence = {"positions":records[0].size(),"links":links.size(),"pins":pins.size(),"recorded_frames":records.size(),"simulation_seconds":6.0,"simulation_step":score.STEP,"settling_steps":600,"maximum_pin_error":maximum_pin_error,"source_method":"step","changes_source":false}

func _draw(time: float) -> void:
	# A hold on the already settled start leaves time to see the fixed corners.
	var simulated := 0.0
	if time >= 13.0 and time < 19.5: simulated = 1.0+2.0*(time-13.0)/6.5
	elif time >= 19.5: simulated = 3.0+3.0*(time-19.5)/6.5
	var index := clampi(int(simulated*30),0,records.size()-1)
	if index != drawn_record:
		skin.mesh = Kit.surface(records[index],indices)
		var wire := ImmediateMesh.new(); wire.surface_begin(Mesh.PRIMITIVE_LINES)
		for link in links:
			wire.surface_add_vertex(records[index][link.x]); wire.surface_add_vertex(records[index][link.y])
		wire.surface_end(); network.mesh = wire
		handle.position = records[index][grip_index]
		drawn_record = index
	skin.visible = time < 6.5 or time >= 22.0
	network.visible = time >= 5.5
	readout.text = "225 POSITIONS / 4 PINS" if time < 6.5 else ("%d DISTANCE LINKS" % links.size() if simulated < 1 else ("ONE HELD POINT / MANY RESPONSES" if simulated < 3 else "RELEASE / GRAVITY / DAMPING"))
	frame_scene(Vector3(0,1.75,0),12.8,lerpf(.30,.90,Kit.progress(time,0,26)),.35)
