extends "res://commons/artifacts/spine_films/late/late_stage.gd"
const SOURCE := "res://commons/artifacts/shannon_workbench/shannon_workbench.gd"
var _source: Node3D
var _draws := PackedFloat32Array()
var _balls: Array[MeshInstance3D] = []
var _bits: Array[MeshInstance3D] = []
var _plane: MeshInstance3D
var _readout: Label3D
var _zero: StandardMaterial3D
var _one: StandardMaterial3D

func _build() -> void:
	title_text = "SAME DRAWS, A MOVING THRESHOLD"
	phases.assign(["KEEP THE DRAWS","CHOOSE P","COUNT THIS SAMPLE","SOURCE AND SAMPLE"])
	notes.assign(["Each suspended point is one stored draw between zero and one.","A draw below the plane produces 1. The plane changes; the draws stay.","The lower tiles record the resulting bits. Counts belong to this sample.","H(p) describes the chosen binary source. It does not prove a theory of mind."])
	source_paths.assign([SOURCE])
	frame_scene(Vector3(0,1.2,0),11.7,.42,.40)
	film_deck()
	_source = load(SOURCE).new()
	_source.grid_side = 8
	_source.draw_seed = 1234
	_source._initialize_draws()
	_draws = _source._draws.duplicate()
	_zero = material(CHALK)
	_one = material(TEAL)
	for i in _draws.size():
		var floor_point := Vector3((i%8-3.5)*.60,.05,(i/8-3.5)*.48)
		var point := floor_point+Vector3(0,.4+_draws[i]*2.0,0)
		_balls.append(add_ball(point,.058,CHALK))
		_bits.append(add_box(floor_point,Vector3(.43,.05,.34),CHALK))
		add_rod(floor_point+Vector3(0,.2,0),point,.007,SLATE)
	_plane = add_box(Vector3(0,1.45,0),Vector3(4.85,.025,3.85),Color(PINK,.21))
	_readout = add_label("",Vector3(0,3.1,0),CHALK)
	add_label("0",Vector3(-2.8,.45,0),CHALK)
	add_label("1",Vector3(-2.8,2.45,0),CHALK)
	evidence = {"draw_seed":1234,"fixed_draws":64,"draw_hash":hash(_draws),"min_draw":Array(_draws).min(),"max_draw":Array(_draws).max(),"entropy_endpoints":[_source._binary_entropy(0.0),_source._binary_entropy(.5),_source._binary_entropy(1.0)],"actual_functions":["_initialize_draws","_binary_entropy","prediction_reading"],"limitation":"64-draw private sample; source entropy is not empirical sample entropy or a QFEP proof"}

func _draw(time: float) -> void:
	var phase := phase_index(time)
	var u := phase_progress(time)
	var p := .5
	if phase==1: p = smoothstep(0,1,u)
	if phase==3: p = .5+.45*sin(u*TAU)
	_source._p = p
	var reading: Dictionary = _source.prediction_reading()
	_plane.position.y = .45+p*2
	_plane.visible = phase>0
	for i in _draws.size():
		var mat := _one if _draws[i]<p else _zero
		_balls[i].material_override = mat if phase>0 else _zero
		_bits[i].visible = phase>=2
		_bits[i].material_override = mat
	_readout.text = "64 stored draws" if phase==0 else "p = %.2f   /   %d ones in 64   /   H(p) = %.3f bits" % [p,int(reading.observed_errors),float(reading.source_h)]

func _exit_tree() -> void:
	if is_instance_valid(_source): _source.free()
