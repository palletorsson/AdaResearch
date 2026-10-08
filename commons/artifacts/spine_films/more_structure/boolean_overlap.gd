extends "res://commons/artifacts/spine_films/more_structure/structure_stage.gd"
const SOURCE=preload("res://algorithms/boolean_surfaces/csg_intersection_demo.gd")
var results:Array[Node3D]=[]
var offsets:Array[Vector3]=[]
var operand_a:MeshInstance3D
var operand_b:MeshInstance3D
var labels:Array[Label3D]=[]
var readout:Label3D
var volumes:Array=[]
func _build()->void:
	title_text="Only what both solids contain"
	phases.assign(["The two operands arrive", "Put them in the same space", "Intersection keeps their shared volume", "Moving one operand changes what remains"])
	notes.assign(["The hall's box and sphere keep their actual dimensions. Their separation here exposes the two operands.","The source's broad offset is (0.3, 0.2, 0.1). Neither original mesh is edited.","Godot's native CSG intersection computes the survivor; it is not a hand-shaped approximation.","The four offsets come from the artifact's own consensus ladder. These are geometric sets; the film does not prove a social claim about agreement."])
	source_paths.assign(["res://algorithms/boolean_surfaces/csg_intersection_demo.gd"])
	var names:Array[String]=["unanimous","broad","narrow","token"]
	for word in names:
		var source=SOURCE.new();source.consensus=word;source._rig=Node3D.new();source.add_child(source._rig);source._build_intersection()
		offsets.append(source._cut_offset());volumes.append(source._volumes())
		var csg:CSGCombiner3D=source._root_csg
		source._rig.remove_child(csg);display.add_child(csg);csg.position=Vector3.ZERO;csg.material_override=material(TEAL)
		results.append(csg);source.free()
		labels.append(add_label(word.to_upper(),Vector3.ZERO,CHALK))
	var box:=BoxMesh.new();box.size=Vector3.ONE*.8
	operand_a=add_mesh(box,Color(PINK,.42));var sphere:=SphereMesh.new();sphere.radius=.55;sphere.height=1.1
	operand_b=add_mesh(sphere,Color(GOLD,.42))
	readout=add_label("",Vector3(0,3.2,0),CHALK)
	evidence={"offsets":offsets.duplicate(),"volumes":volumes.duplicate(true),"native_operation":CSGShape3D.OPERATION_INTERSECTION,"box_size":Vector3.ONE*.8,"radius":.55,"source_calls":["_cut_offset","_build_intersection","_volumes"],"private_native_csg":true,"source_never_entered_tree":true}
	film_deck();frame_scene(Vector3(0,1.45,0),11.5,.25,.25)
func _draw(time:float)->void:
	var phase:=phase_index(time);var u:=phase_progress(time)
	for i in results.size():
		results[i].visible=phase==3 or (phase==2 and i==1)
		results[i].scale=Vector3.ONE*(1.6 if phase==3 else 2.6)
		results[i].position=Vector3((i-1.5)*1.85,1.3,0) if phase==3 else Vector3(0,1.35,0)
		labels[i].visible=phase==3;labels[i].position=results[i].position+Vector3(0,-1.1,0)
	operand_a.visible=phase<3;operand_b.visible=phase<3
	var blend:=0.0 if phase==0 else (smoothstep(0,1,u) if phase==1 else 1.0)
	operand_a.scale=Vector3.ONE*2.6;operand_b.scale=Vector3.ONE*2.6
	operand_a.position=Vector3(-1.9,1.35,0).lerp(Vector3(0,1.35,0),blend)
	operand_b.position=Vector3(1.8,1.35,0).lerp(Vector3(0,1.35,0)+offsets[1]*2.6,blend)
	if phase==2:
		operand_a.visible=u<.5;operand_b.visible=u<.5
	readout.text="A  /  BOX                 B  /  SPHERE" if phase<2 else ("A ∩ B  /  INSIDE BOTH" if phase==2 else "SAME INPUT SHAPES / FOUR OFFSETS")
