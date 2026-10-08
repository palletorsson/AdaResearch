extends "res://commons/artifacts/spine_films/film_stage.gd"
const Kit = preload("res://commons/artifacts/spine_films/middle/film_kit.gd")
var keep: Array = []
var first: Array[MeshInstance3D] = []
var second: Array[MeshInstance3D] = []
var final_body: MultiMeshInstance3D
var readout: Label3D
var centers: Array[Vector3] = []
var selected := Vector3(1.2,1.2,1.2)

func offset(index: int) -> Vector3:
	return Vector3(index%3-1,(index/3)%3-1,index/9-1)

func _build() -> void:
	title_text = "TWENTY OF TWENTY-SEVEN"
	duration = 26.0
	phases.assign(["DIVIDE ONE CUBE", "REMOVE SEVEN", "REPEAT IN ONE CHILD", "REPEAT IN EVERY CHILD"])
	notes.assign(["The existing Menger artifact partitions a cube into 27 positions.", "Its retained-index list keeps 20. The centre and six face centres leave.", "The same position rule acts inside a retained child.", "Twenty children each keep twenty: 400 cubes at this finite depth."])
	source_paths.assign(["res://algorithms/fractals/mengersponge/menger_sponge.gd"])
	var source = load(source_paths[0]).new()
	keep.assign(source.keep_positions)
	source.free()
	var white := Kit.material(Kit.WHITE)
	var pink := Kit.material(Kit.PINK)
	for i in 27:
		var center := offset(i)*1.2
		centers.append(center)
		first.append(Kit.box(display,center+Vector3.UP*2.0,Vector3.ONE*1.19,white if i in keep else pink))
	for i in 27:
		second.append(Kit.box(display,selected+offset(i)*.4+Vector3.UP*2,Vector3.ONE*.38,white if i in keep else pink))
	var mesh := BoxMesh.new(); mesh.size = Vector3.ONE*.38
	var multi := MultiMesh.new(); multi.transform_format = MultiMesh.TRANSFORM_3D; multi.mesh = mesh; multi.instance_count = keep.size()*keep.size()
	var n := 0
	for parent in keep:
		for child in keep:
			multi.set_instance_transform(n,Transform3D(Basis.IDENTITY,offset(parent)*1.2+offset(child)*.4+Vector3.UP*2)); n += 1
	final_body = MultiMeshInstance3D.new(); final_body.multimesh = multi; final_body.material_override = white; display.add_child(final_body)
	readout = Kit.label(display,"",Vector3(0,4.3,0),Kit.WHITE,.006)
	evidence = {"retained":keep.size(),"removed":27-keep.size(),"second_depth":n,"source_data":"keep_positions","changes_source":false}

func _draw(time: float) -> void:
	var removal := Kit.progress(time,6.5,11)
	var detail := time >= 13.0 and time < 19.5
	for i in first.size():
		var retained := i in keep
		first[i].visible = time < 19.5 and (retained or removal < .999) and not(detail and i == 26)
		var direction := centers[i].normalized() if centers[i].length_squared() > .01 else Vector3.FORWARD
		first[i].position = centers[i]+Vector3.UP*2+direction*removal*2.0*(0.0 if retained else 1.0)
		first[i].scale = Vector3.ONE*lerpf(1.0,.95,Kit.progress(time,2,5))
	for i in second.size():
		second[i].visible = detail and (i in keep or time < 17.5)
		var direction := offset(i).normalized() if offset(i).length_squared() > .01 else Vector3.FORWARD
		second[i].position = selected+offset(i)*.4+Vector3.UP*2 + direction*Kit.progress(time,15.3,17.5)*.6*(0.0 if i in keep else 1.0)
	final_body.visible = time >= 19.5
	readout.text = "27 POSITIONS" if time < 6.5 else ("20 REMAIN" if time < 13 else ("THE SAME RULE, ONE SCALE DOWN" if time < 19.5 else "20 × 20 = 400"))
	frame_scene(Vector3(0,2,0),12.3,lerpf(.45,1.05,Kit.progress(time,18,26)),.28)
