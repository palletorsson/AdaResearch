extends "res://commons/artifacts/spine_films/film_stage.gd"
const Kit = preload("res://commons/artifacts/spine_films/middle/film_kit.gd")
const Draw = preload("res://commons/artifacts/spine_films/more_motion/drawing.gd")
var rigs: Array[Node3D] = []
var captions: Array[Label3D] = []
var products: Array[float] = []

func _build() -> void:
	title_text="A LONGER ARM, A SMALLER PUSH"
	duration=28
	phases.assign(["ALONG THE ARM","ACROSS THE ARM","SEPARATE THE PUSH","LONG / BALANCED / SHORT"])
	notes.assign(["A push aligned with the arm has no perpendicular component.","The source opens the angle. Its cross-direction factor grows.","The source draws the parallel and perpendicular components at the arm tip.","Twice the arm and half the push keep the same product. These are static poses, not spinning dynamics."])
	source_paths.assign(["res://commons/artifacts/torque_crank/torque_crank.gd","res://commons/artifacts/_toy_console/toy_console.gd"])
	for config in [["balanced",0.0,"trace"],["balanced",.78,"trace"],["balanced",.78,"operands"],["long",.78,"operands"],["stub",.78,"operands"]]:
		var source=load(source_paths[0]).new()
		source.seed=17
		source.purchase=config[0];source.leverage=config[1];source.workings=config[2]
		source.demo_root=Node3D.new();source.add_child(source.demo_root)
		source._build_demo()
		var rig:Node3D=source.demo_root.get_child(0)
		source.demo_root.remove_child(rig)
		rig.transform=Transform3D.IDENTITY
		display.add_child(rig)
		rigs.append(rig)
		# Read arrow lengths from the geometry the original function actually built.
		var r:Node3D=rig.get_child(4)
		var f:Node3D=rig.get_child(5)
		var rv:=arrow_vector(r);var fv:=arrow_vector(f)
		products.append(rv.cross(fv).length())
		source.free()
	# Read a short sequence of actual source builds as the original slider opens.
	for i in 17:
		var source=load(source_paths[0]).new()
		source.seed=17;source.leverage=.78*float(i+1)/17;source.workings="trace"
		source.demo_root=Node3D.new();source.add_child(source.demo_root)
		source._build_demo()
		var rig:Node3D=source.demo_root.get_child(0)
		source.demo_root.remove_child(rig);rig.transform=Transform3D.IDENTITY
		display.add_child(rig);rigs.append(rig);source.free()
	for i in 3:captions.append(Draw.caption(display,["LONG ARM / HALF PUSH","BALANCED","HALF ARM / DOUBLE PUSH"][i],Vector3(-2.8+i*2.8,2.6,0),Kit.WHITE))
	add_box(Vector3(0,-.12,0),Vector3(8.5,.14,3.3),Color("222a35"))
	evidence={"source_rigs":rigs.size(),"source_slider_samples":17,"measured_cross_products":products,"static_wheel_poses":true,"seed":17}

func arrow_vector(arrow:Node3D) -> Vector3:
	var shaft:MeshInstance3D=arrow.get_child(0)
	var head:MeshInstance3D=arrow.get_child(1)
	var start:Vector3=shaft.position-shaft.basis.y*(shaft.mesh.height*.5)
	var end:Vector3=head.position+head.basis.y*(head.mesh.height*.5)
	return end-start

func _draw(time:float) -> void:
	if rigs.is_empty():return
	var p:=phase_index(time)
	var angle_frame:=5+mini(16,int(phase_progress(time)*17))
	for i in rigs.size():
		rigs[i].visible=i==angle_frame if p==1 else (i==p if p<3 else i in [2,3,4])
		rigs[i].position=Vector3.ZERO
		rigs[i].scale=Vector3.ONE*1.55
	if p==3:
		rigs[3].position.x=-2.8;rigs[4].position.x=2.8
		for i in [2,3,4]:rigs[i].scale=Vector3.ONE*1.15
	for c in captions:c.visible=p==3
	frame_scene(Vector3(0,.85,0),12.5 if p==3 else 8.6,.35+time*.006,.47)

func validation() -> Dictionary:
	return {"passed":products.size()==5 and products[0]<.00001 and products[2]>.3 and absf(products[2]-products[3])<.00001 and absf(products[2]-products[4])<.00001,"evidence":evidence}
