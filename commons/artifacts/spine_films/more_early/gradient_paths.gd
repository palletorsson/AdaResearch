extends "res://commons/artifacts/spine_films/film_stage.gd"
const G = preload("res://commons/artifacts/spine_films/early/geometry.gd")
const SOURCE = "res://algorithms/color/gradient_interpolator/gradient_interpolator.gd"
var colours: Array = []
var markers: Array = []
var links: Array = []
var samples: Array = []
var cursor: Array[MeshInstance3D] = []

func place(c: Color) -> Vector3:
	return Vector3((c.r-.5)*3.1,c.g*3.1+.40,(c.b-.5)*3.1)

func _build() -> void:
	title_text="The space changes the colours between"
	phases=["THE SAME TWO ENDS","RGB WALKS A STRAIGHT LINE","HSV TAKES ANOTHER PATH","COMPARE SIXTEEN SAMPLES"]
	notes=["Red and cyan are fixed at opposite corners of RGB space.","The original interpolator blends red, green and blue independently.","Its HSV function crosses the hue wheel; these results are plotted in the same RGB cube.","Both rows use the source's sixteen samples. The middle colours differ."]
	source_paths=[SOURCE]
	var source: Node3D=load(SOURCE).new(); source._color_a_idx=0;source._color_b_idx=4
	source._build_gradient_row()
	for mode in range(2):
		source._mode_hsv=mode==1;source._recalculate()
		var palette: Array[Color]=[]
		for cube: MeshInstance3D in source._cubes:palette.append(cube.material_override.albedo_color)
		colours.append(palette)
		var points: Array[MeshInstance3D]=[];var roads: Array[MeshInstance3D]=[];var row: Array[MeshInstance3D]=[]
		for i in palette.size():
			var point:=G.sphere(display,place(palette[i]),.067,palette[i]);point.material_override=G.material(palette[i],true);points.append(point)
			if i>0:roads.append(G.line(display,place(palette[i-1]),place(palette[i]),G.WHITE if mode==0 else G.GOLD,.019))
			var swatch:=G.box(display,Vector3(-2.25+i*.30,.1,2.25+mode*.42),Vector3(.27,.14,.3),palette[i]);swatch.material_override=G.material(palette[i],true);row.append(swatch)
		markers.append(points);links.append(roads);samples.append(row)
		cursor.append(G.sphere(display,place(palette[0]),.12,G.WHITE if mode==0 else G.GOLD))
	var frame:=G.frame(display,Vector3.ONE*3.1,Color("78919e"));frame.position.y=1.95
	for text: String in ["R","G","B"]:
		var at:=Vector3(1.8,.32,-1.55) if text=="R" else (Vector3(-1.55,3.8,-1.55) if text=="G" else Vector3(-1.55,.32,1.8))
		G.label(display,text,at,G.WHITE,.2)
	G.label(display,"RGB",Vector3(-2.65,.10,2.25),G.WHITE,.17);G.label(display,"HSV",Vector3(-2.65,.10,2.67),G.GOLD,.17)
	G.box(display,Vector3(0,-.06,.48),Vector3(5.8,.12,5.1),Color("233a4b"))
	evidence={"samples":colours[0].size(),"a":"red","b":"cyan","rgb_middle":[colours[0][8].r,colours[0][8].g,colours[0][8].b],"hsv_middle":[colours[1][8].r,colours[1][8].g,colours[1][8].b],"method":"_build_gradient_row / _recalculate / _lerp_hsv","coordinate_frame":"both paths plotted in RGB"}
	source.free();frame_scene(Vector3(0,1.8,.5),11.8,.61,.33)

func _draw(time: float) -> void:
	var p:=phase_index(time);var u:=phase_progress(time)
	for mode in range(2):
		var limit:=15 if p==3 or (p==2 and mode==0) else int(u*15.99)
		var show_path: bool=p>=1+mode
		for i in markers[mode].size():markers[mode][i].visible=(i==0 or i==15) or (show_path and i<=limit)
		for i in links[mode].size():links[mode][i].visible=show_path and i<limit
		for i in samples[mode].size():samples[mode][i].visible=p==3
		cursor[mode].visible=show_path
		cursor[mode].position=place(colours[mode][mini(limit,15)])

func validation() -> Dictionary:
	return {"passed":colours.size()==2 and colours[0].size()==16 and colours[0][0].is_equal_approx(colours[1][0]) and colours[0][15].is_equal_approx(colours[1][15]) and not colours[0][8].is_equal_approx(colours[1][8]),"evidence":evidence}
