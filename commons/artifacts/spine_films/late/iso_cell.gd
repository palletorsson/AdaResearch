extends "res://commons/artifacts/spine_films/late/late_stage.gd"
const GENERATOR := "res://algorithms/spacetopology/marchingcubes/core/MarchingCubesGenerator.gd"
const DEMO := "res://algorithms/spacetopology/marchingcubes/scenes/FifteenCasesController.gd"
var _corners: Array[MeshInstance3D] = []
var _sheets: Array[Node3D] = []
var _crossings: Array[Node3D] = []
var _readout: Label3D
var _margin_names := ["even","starved","swollen","brimming"]
var _margins: Array = []

func _build() -> void:
	title_text = "A SURFACE BETWEEN EIGHT SAMPLES"
	phases.assign(["SAMPLES","CROSSINGS","TRIANGLES","SAME CASE, ANOTHER SURFACE"])
	notes.assign(["Eight corner values surround one cell. The threshold is 0.5.","Only edges whose ends cross the threshold supply a vertex.","The source lookup table joins those crossings into triangles.","The classification stays fixed. Different values move the crossings."])
	source_paths.assign([GENERATOR,DEMO])
	frame_scene(Vector3(0,1.4,0),10.2,.52,.31)
	film_deck()
	var generator = load(GENERATOR).new()
	var demo = load(DEMO).new()
	var points: Array = [Vector3(0,0,0),Vector3(1,0,0),Vector3(1,1,0),Vector3(0,1,0),Vector3(0,0,1),Vector3(1,0,1),Vector3(1,1,1),Vector3(0,1,1)]
	for edge in demo.EDGE_CONNECTIONS: add_rod(_place(points[edge[0]]),_place(points[edge[1]]),.025,SLATE)
	var configs: Array = []
	var counts: Array = []
	for margin_name in _margin_names:
		demo.margin = margin_name
		var densities: Array = demo._densities_for(demo.fifteen_cases[3])
		_margins.append(densities.duplicate())
		var cube := {"positions":points,"densities":densities}
		var triangles: Array = generator.march_cube_fixed(cube)
		var sheet := film_group()
		var crosses := film_group()
		var all_vertices := PackedVector3Array()
		for triangle in triangles:
			for vertex in triangle.vertices: all_vertices.append(_place(vertex))
		film_triangles(all_vertices,Color(TEAL,.80),sheet)
		for triangle in triangles:
			for i in 3: add_rod(_place(triangle.vertices[i]),_place(triangle.vertices[(i+1)%3]),.022,CHALK,sheet)
		for vertex in generator.calculate_edge_intersections(cube):
			if vertex != null: add_ball(_place(vertex),.075,GOLD,crosses)
		_sheets.append(sheet)
		_crossings.append(crosses)
		var config := 0
		for i in 8:
			if densities[i]<.5: config |= 1<<i
		configs.append(config)
		counts.append(triangles.size())
	for i in 8:
		_corners.append(add_ball(_place(points[i]),.10,PINK if _margins[0][i]<.5 else TEAL))
		add_label(str(i),_place(points[i])+Vector3(0,.20,0),CHALK).font_size = 23
	_readout = add_label("",Vector3(0,3.25,0),GOLD)
	evidence = {"configs":configs,"triangle_counts":counts,"corner_count":8,"threshold":.5,"actual_functions":["_densities_for","march_cube_fixed","calculate_edge_intersections"],"source_classification":"density < threshold","single_cell":true}
	demo.free()

func _place(p: Vector3) -> Vector3:
	return (p-Vector3(.5,0,.5))*2.65+Vector3(0,.12,0)

func _draw(time: float) -> void:
	var phase := phase_index(time)
	var margin := mini(3,int(phase_progress(time)*4)) if phase==3 else 0
	for i in 4:
		_sheets[i].visible = phase>=2 and i==margin
		_crossings[i].visible = phase>=1 and i==margin
	_readout.text = "%s   /   %.2f : 0.50 : %.2f" % [_margin_names[margin].to_upper(),float(_margins[margin].min()),float(_margins[margin].max())]
