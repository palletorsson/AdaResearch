extends "res://commons/artifacts/spine_films/film_stage.gd"
const G = preload("res://commons/artifacts/spine_films/early/geometry.gd")
const SOURCE = "res://commons/primitives/translation/translation_cube_demo.gd"
var paths: Array = []
var doors: Array[Node3D] = []
var origins: Array[Vector3] = []
var path_lines: Array[Node3D] = []
var destination_labels: Array[Label3D] = []
const MAG := 2.8

func _build() -> void:
	title_text = "A lift, then a slide"
	phases = ["ONE DESTINATION", "LIFT BEFORE SLIDING", "BOTH DIRECTIONS TOGETHER", "COMPARE THE JOURNEYS"]
	notes = ["These doors share the source's dimensions and final displacement.", "The source permits Y first; X becomes available after the lift.", "The free setting allows both axes. This film chooses a diagonal journey.", "Equal final displacement does not mean an equal route."]
	source_paths = [SOURCE]
	var src: Node3D = load(SOURCE).new()
	for i in range(2):
		src.course = "lift_lateral" if i==0 else "free"
		var path: Array = src._path_points(1.0,Vector3.ZERO,src.door_width)
		paths.append(path)
		var origin := Vector3(-2.1 if i==0 else 1.4,.22,0)
		origins.append(origin)
		var door := Node3D.new(); display.add_child(door); door.position = origin; doors.append(door)
		G.box(door,Vector3(0,src.door_height*.5,0)*MAG,Vector3(src.door_width,src.door_height,src.door_depth)*MAG,G.BLUE if i==0 else G.PINK)
		G.sphere(door,Vector3(src.door_width*.35,src.knob_height,src.door_depth+.035)*MAG,.075,G.GOLD)
		var rails := Node3D.new(); display.add_child(rails); path_lines.append(rails)
		for j in range(path.size()-1):
			G.line(rails,origin+(path[j]+Vector3(0,1.13,0))*MAG,origin+(path[j+1]+Vector3(0,1.13,0))*MAG,G.GOLD,.021)
		var end: Vector3 = origin+path.back()*MAG
		var outline := G.frame(display,Vector3(src.door_width,src.door_height,src.door_depth)*MAG,Color(.9,.8,.55,.35))
		outline.position = end+Vector3(0,src.door_height*.5*MAG,0)
		G.label(display,"Y then X" if i==0 else "X and Y",Vector3(origin.x+.3,.32,.85),G.WHITE,.19)
		G.box(display,Vector3(origin.x+.6,.07,0),Vector3(3.15,.14,1.4),Color("263b50"))
	evidence = {"ordered_corners":paths[0].size(),"free_corners":paths[1].size(),"same_goal":paths[0].back().is_equal_approx(paths[1].back()),"lift_m":src.target_y,"side_m":src.door_width,"presentation_scale":MAG,"method":"_path_points / _leg_plan"}
	src.free()
	frame_scene(Vector3(.1,1.8,0),10.6,.30,.24)

func sample_path(path: Array, fraction: float) -> Vector3:
	var lengths: Array[float] = []; var total := 0.0
	for i in range(path.size()-1):
		var d: float = path[i].distance_to(path[i+1]); lengths.append(d); total+=d
	var rest := fraction*total
	for i in lengths.size():
		if rest<=lengths[i]: return path[i].lerp(path[i+1],rest/maxf(lengths[i],.0001))
		rest-=lengths[i]
	return path.back()

func _draw(time: float) -> void:
	var p := phase_index(time); var u := smoothstep(.08,.82,phase_progress(time))
	for i in range(2):
		var t := (u if (p==1 and i==0) or (p==2 and i==1) or p==3 else (1.0 if p==2 and i==0 else 0.0))
		doors[i].position = origins[i]+sample_path(paths[i],t)*MAG
		path_lines[i].visible = p>0

func validation() -> Dictionary:
	return {"passed":paths.size()==2 and paths[0].size()==3 and paths[1].size()==2 and bool(evidence.same_goal),"evidence":evidence}
