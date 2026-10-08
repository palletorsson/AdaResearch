extends "res://commons/artifacts/spine_films/film_stage.gd"
const Kit = preload("res://commons/artifacts/spine_films/middle/film_kit.gd")
var paths: Array = []
var rods: Array = []
var cursor: MeshInstance3D
var heading: MeshInstance3D
var readout: Label3D

func _build() -> void:
	title_text = "FORWARD IS A LOCAL DIRECTION"
	duration = 26.0
	phases.assign(["ONE REWRITE", "TURN THEN ADVANCE", "REWRITE AGAIN", "A FINITE PATH IN SPACE"])
	notes.assign(["The hall's 3D Hilbert grammar gives a short sequence of turns and forward steps.", "The next segment follows the turtle's current direction, not a fixed world axis.", "The same production is applied again. Its instruction string becomes a longer path.", "The film follows the source's actual segment order. Two generations remain finite."])
	source_paths.assign(["res://algorithms/lsystems/Hilbert3D.gd","res://utils/lsystem.gd"])
	var source = load(source_paths[0]).new()
	var grammar_script = load(source_paths[1])
	var counts: Array[int] = []
	for generation in [1,2]:
		source.lsystem = grammar_script.create_3d_hilbert()
		source.lsystem.generate_n(generation)
		source.step_length = 1.0
		source.compute_segments()
		var segments: Array = source.all_segments.duplicate(true)
		counts.append(segments.size())
		var bounds := AABB(segments[0].start,Vector3.ZERO)
		for row in segments: bounds = bounds.expand(row.start).expand(row.end)
		var factor := 4.2/maxf(bounds.size.x,maxf(bounds.size.y,bounds.size.z))
		var row_rods: Array[MeshInstance3D] = []
		for row in segments:
			row.start = (row.start-bounds.get_center())*factor+Vector3.UP*2.2
			row.end = (row.end-bounds.get_center())*factor+Vector3.UP*2.2
			row_rods.append(Kit.rod(display,row.start,row.end,.04,Kit.material(Kit.TEAL if generation == 1 else Kit.WHITE)))
		paths.append(segments); rods.append(row_rods)
	source.free()
	cursor = Kit.dot(display,Vector3.ZERO,.12,Kit.material(Kit.GOLD,true))
	heading = Kit.rod(display,Vector3.ZERO,Vector3.UP,.035,Kit.material(Kit.PINK,true))
	readout = Kit.label(display,"",Vector3(0,4.4,0),Kit.WHITE,.006)
	evidence = {"generations":[1,2],"segment_counts":counts,"source_methods":["create_3d_hilbert","generate_n","compute_segments"],"camera_only_rotation":true,"changes_source":false}

func _draw(time: float) -> void:
	var generation := 0 if time < 12 else 1
	var progress := clampf((time-(1.0 if generation == 0 else 12.0))/(9.0 if generation == 0 else 11.0),0,1)
	var path: Array = paths[generation]
	var amount := progress*path.size()
	var current := mini(int(amount),path.size()-1)
	for g in rods.size():
		for i in rods[g].size():
			rods[g][i].visible = g == generation and i < amount
			if g == generation and i == current:
				Kit.set_rod(rods[g][i],path[i].start,path[i].start.lerp(path[i].end,clampf(amount-i,0,1)))
			elif g == generation:
				Kit.set_rod(rods[g][i],path[i].start,path[i].end)
				rods[g][i].visible = i < amount
	var start: Vector3 = path[current].start
	var finish: Vector3 = path[current].end
	cursor.position = start.lerp(finish,clampf(amount-current,0,1))
	Kit.set_rod(heading,cursor.position,cursor.position+(finish-start).normalized()*.48)
	readout.text = "GENERATION %d  /  %d OF %d FORWARD STEPS" % [generation+1,mini(int(amount),path.size()),path.size()]
	frame_scene(Vector3(0,2.2,0),13.8,lerpf(.45,1.25,Kit.progress(time,0,26)),.32)
