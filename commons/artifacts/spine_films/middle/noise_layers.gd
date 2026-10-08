extends "res://commons/artifacts/spine_films/film_stage.gd"
const Kit = preload("res://commons/artifacts/spine_films/middle/film_kit.gd")
var layers_: Array[MeshInstance3D] = []
var summed: MeshInstance3D
var lowered: MeshInstance3D
var probe: Array[MeshInstance3D] = []
var values: Array[float] = []
var marks: Array[Label3D] = []
var sample_points: Array[MeshInstance3D] = []

func _build() -> void:
	title_text = "THREE FIELDS, ONE HEIGHT"
	duration = 26.0
	phases.assign(["Three retained fields", "One address receives all three", "Their heights add", "Then the slope pass acts"])
	notes.assign(["These are the noise resources already authored in the basin.","The vertical separation helps us compare; it is not extra terrain height.","The sum uses the same samples and weights: 12 / 6 / 1.5.","The source lowers steep samples in three passes. That is a separate operation."])
	source_paths.assign(["res://algorithms/randomness/noiselayers/noiselayers.tscn","res://algorithms/randomness/noiselayers/noiselayers.gd"])
	var scene: Node3D = load(source_paths[0]).instantiate()
	var source: MeshInstance3D = scene.get_node("MeshInstance3D")
	# Sample the entire authored basin at a reduced 25x25 display density.
	source.set("terrain_size",24)
	source.set("terrain_scale",200.0/24.0)
	var full: Array = source.call("generate_height_field")
	var after: Array = source.call("apply_erosion_simulation",full.duplicate(true))
	var resources: Array = [source.get("low_freq_noise"),source.get("med_freq_noise"),source.get("high_freq_noise")]
	var weights: Array[float] = [float(source.get("low_freq_amplitude")),float(source.get("med_freq_amplitude")),float(source.get("high_freq_amplitude"))]
	var colours := [Kit.BLUE,Kit.TEAL,Kit.PINK]
	var indices := Kit.grid_indices(25,25)
	var combined := PackedVector3Array()
	var processed := PackedVector3Array()
	var parts: Array[PackedVector3Array] = [PackedVector3Array(),PackedVector3Array(),PackedVector3Array()]
	for z in 25:
		for x in 25:
			var world_x := (x-12)*200.0/24.0
			var world_z := (z-12)*200.0/24.0
			for i in 3:
				var h: float = resources[i].get_noise_2d(world_x,world_z)*weights[i]
				parts[i].append(Vector3(world_x*0.028,h*0.08,world_z*0.028))
			combined.append(Vector3(world_x*0.028,float(full[z][x])*0.08,world_z*0.028))
			processed.append(Vector3(world_x*0.028,float(after[z][x])*0.08,world_z*0.028))
	for i in 3:
		layers_.append(Kit.node(display,Kit.surface(parts[i],indices),Vector3(0,0.6+i*1.5,0),Kit.material(colours[i])))
		values.append(parts[i][12*25+16].y)
		probe.append(Kit.rod(display,Vector3.ZERO,Vector3.UP,0.035,Kit.material(Kit.GOLD,true)))
		marks.append(Kit.label(display,["LOW","MIDDLE","HIGH"][i],Vector3(-3.0,0.6+i*1.5,3.2),colours[i],0.005))
		sample_points.append(Kit.dot(display,Vector3.ZERO,.07,Kit.material(Kit.GOLD,true)))
	summed = Kit.node(display,Kit.surface(combined,indices),Vector3(0,1.4,0),Kit.material(Kit.WHITE))
	lowered = Kit.node(display,Kit.surface(processed,indices),Vector3(0,1.4,0),Kit.material(Kit.GOLD))
	var max_delta := 0.0
	for i in combined.size(): max_delta=maxf(max_delta,absf(combined[i].y-processed[i].y))
	evidence={"source_method":"generate_height_field / apply_erosion_simulation","seeds":[resources[0].seed,resources[1].seed,resources[2].seed],"samples":625,"weights":weights,"slope_change_display_max":max_delta,"changes_source":false}
	scene.free()

func _draw(time: float) -> void:
	var join_ := Kit.progress(time,11.0,17.0)
	for i in 3:
		layers_[i].position.y=lerpf(0.65+i*1.45,1.4,join_)
		layers_[i].visible=time<17.0
		marks[i].position.y=layers_[i].position.y
		marks[i].visible=time<15.0
		var start := Vector3(0.94,layers_[i].position.y,0)
		Kit.set_rod(probe[i],start,start+Vector3.UP*values[i])
		probe[i].visible=time>=5.0 and time<15.0
		sample_points[i].position=start+Vector3.UP*values[i]
		sample_points[i].visible=probe[i].visible
	summed.visible=time>=17.0 and time<21.0
	lowered.visible=time>=21.0
	frame_from_position(Vector3(0,1.6,0),Vector3(7.8,6.1,8.4))
