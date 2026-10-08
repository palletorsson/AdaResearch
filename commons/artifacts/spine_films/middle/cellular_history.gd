extends "res://commons/artifacts/spine_films/film_stage.gd"
const Kit = preload("res://commons/artifacts/spine_films/middle/film_kit.gd")
var histories: Array = []
var layers: Array[Node3D] = []
var witness: Node3D
var newborn: MeshInstance3D
var readout: Label3D
var birth := Vector2i.ZERO

func _build() -> void:
	title_text = "A GENERATION BECOMES A STOREY"
	duration = 26.0
	phases.assign(["COUNT A NEIGHBOURHOOD", "WRITE THE NEXT STATE", "KEEP EACH GENERATION", "TIME BECOMES HEIGHT"])
	notes.assign(["Eight neighbours are read together. This empty cell has three living neighbours.", "The existing Life rule writes a living cell into the next generation.", "Each layer is a complete state. A new generation reads the previous one.", "Height here records time. The artifact's later eroding walkers are a separate process."])
	source_paths.assign(["res://algorithms/cellularautomata/ca_columns/ca_columns.gd"])
	var source = load(source_paths[0]).new()
	source.grid_size = 8
	for x in 8:
		var column: Array = []
		column.resize(8); column.fill(0)
		source.grid_2d.append(column)
	# A small declared seed, evolved by the actual artifact's rule and wrapped grid.
	for at in [Vector2i(2,1),Vector2i(3,2),Vector2i(1,3),Vector2i(2,3),Vector2i(3,3)]: source.grid_2d[at.x][at.y] = 1
	var found := false
	for x in 8:
		for z in 8:
			if not found and source.grid_2d[x][z] == 0 and source._count_neighbors(x,z) == 3:
				birth = Vector2i(x,z); found = true
	histories.append(source.grid_2d.duplicate(true))
	for generation in 13:
		source._evolve_grid()
		histories.append(source.grid_2d.duplicate(true))
	witness = Node3D.new(); display.add_child(witness)
	for x in 8:
		for z in 8:
			Kit.box(display,Vector3((x-3.5)*.58,-.12,(z-3.5)*.58),Vector3(.55,.08,.55),Kit.material(Color("263341")))
	for generation in histories.size():
		var layer := Node3D.new(); display.add_child(layer); layers.append(layer)
		for x in 8:
			for z in 8:
				if histories[generation][x][z] == 1:
					Kit.box(layer,Vector3((x-3.5)*.58,.15,(z-3.5)*.58),Vector3(.48,.29,.48),Kit.material(Kit.TEAL.lerp(Kit.PINK,float(generation)/13.0)))
	var witnesses := 0
	for x in range(-1,2):
		for z in range(-1,2):
			if x == 0 and z == 0: continue
			var nx := posmod(birth.x+x,8); var nz := posmod(birth.y+z,8)
			if histories[0][nx][nz] == 1:
				Kit.dot(witness,Vector3((nx-3.5)*.58,.39,(nz-3.5)*.58),.10,Kit.material(Kit.GOLD,true)); witnesses += 1
	newborn = Kit.box(display,Vector3((birth.x-3.5)*.58,.65,(birth.y-3.5)*.58),Vector3(.5,.3,.5),Kit.material(Kit.GOLD,true))
	readout = Kit.label(display,"",Vector3(0,4.65,0),Kit.WHITE,.006)
	evidence = {"rule":"B3/S23", "grid_size":8, "boundary":"wrapped", "history_count":histories.size(), "birth_neighbours":witnesses, "birth_old":histories[0][birth.x][birth.y], "birth_next":histories[1][birth.x][birth.y], "source_method":"_evolve_grid", "changes_source":false}
	source.free()

func _draw(time: float) -> void:
	var visible_count := clampi(1 + int(maxf(time-13.0,0.0)*2.3),1,layers.size())
	var spacing := lerpf(.30,.35,Kit.progress(time,19,24))
	for i in layers.size():
		layers[i].visible = i < visible_count
		layers[i].position.y = i * spacing
	witness.visible = time < 13.0
	newborn.visible = time >= 6.5 and time < 13.0
	newborn.position.y = lerpf(.15,.65,Kit.progress(time,6.5,9))
	readout.text = "3 NEIGHBOURS → 1 LIVING CELL" if time < 13 else "%d RETAINED GENERATIONS" % visible_count
	frame_scene(Vector3(0,1.8,0),13.8,lerpf(.35,.85,Kit.progress(time,15,26)),.43)
