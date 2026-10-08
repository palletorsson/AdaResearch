extends "res://commons/artifacts/spine_films/late/late_stage.gd"
const SOURCE := "res://algorithms/numericalmethods/gradientdescent/gradient_descent_visualization.gd"
var _path := PackedVector3Array()
var _trail: Array[MeshInstance3D] = []
var _marker: MeshInstance3D
var _slope: Node3D
var _step: Node3D
var _readout: Label3D

func _build() -> void:
	title_text = "ONE LEARNING STEP"
	phases.assign(["THE LOSS SURFACE","THE LOCAL SLOPE","THE STEP SIZE","REPEAT THE OPERATION"])
	notes.assign(["A position on the bowl has a loss: height records the source function.","The source estimates a gradient from nearby function values.","The learning rate scales the negative gradient into one displacement.","Each step asks again. This toy loss surface is not a trained neural network."])
	source_paths.assign([SOURCE])
	frame_scene(Vector3(0,1.0,0),13,.58,.62)
	film_deck()
	var source = load(SOURCE).new()
	source.function_preset = 0
	source.learning_rate = .15
	var vertices := PackedVector3Array()
	for x in 24:
		for z in 24:
			var a := Vector2(-3.2+x*6.4/24,-3.2+z*6.4/24)
			var b := a+Vector2(6.4/24,0)
			var c := a+Vector2(0,6.4/24)
			var d := a+Vector2(6.4/24,6.4/24)
			for p in [a,c,b,b,c,d]: vertices.append(_lift(p,source._eval(p)))
	film_triangles(vertices,Color("45647a"))
	var start := Vector2(2.8,2.4)
	var gradient: Vector2 = source._gradient(start)
	source._optimizers = [{"type":"sgd","pos":start,"converged":false,"path":[],"value":source._eval(start)}]
	_path.append(_lift(start,source._eval(start)))
	for i in 25:
		source._step_optimizers()
		var p: Vector2 = source._optimizers[0].pos
		_path.append(_lift(p,source._eval(p)))
	_marker = add_ball(_path[0],.13,GOLD)
	_trail = film_path(_path,PINK,null,.035)
	_slope = film_arrow(_path[0]+Vector3(0,.08,0),Vector3(-gradient.x,0,-gradient.y)*.23,PINK)
	_step = film_arrow(_path[0]+Vector3(0,.05,0),_path[1]-_path[0],GOLD)
	_readout = add_label("",Vector3(0,3.2,0),CHALK)
	evidence = {"start":[start.x,start.y],"gradient":[gradient.x,gradient.y],"learning_rate":.15,"steps":25,"initial_loss":source._eval(start),"final_loss":source._optimizers[0].value,"epsilon":.0001,"vertical_scale":.13,"actual_functions":["_eval","_gradient","_step_optimizers"]}
	source.free()

func _lift(p: Vector2, value: float) -> Vector3:
	return Vector3(p.x,value*.13+.04,p.y)

func _draw(time: float) -> void:
	var phase := phase_index(time)
	_slope.visible = phase==1
	_step.visible = phase==2
	var progress := phase_progress(time)
	var index := 0
	if phase==2:
		_marker.position = _path[0].lerp(_path[1],smoothstep(.15,.85,progress))
	elif phase==3:
		var sample := progress*(_path.size()-1)
		index = mini(_path.size()-2,int(sample))
		_marker.position = _path[index].lerp(_path[index+1],fposmod(sample,1))
	else: _marker.position = _path[0]
	film_reveal(_trail,float(index+1)/_trail.size() if phase==3 else 0)
	_readout.text = ["f(x, z) = x² + z²","gradient = (5.6, 4.8)","step = −0.15 × gradient","%d source steps  /  height scale ×0.13" % (index+1)][phase]
