extends Node3D
const Evaluator=preload("evaluator.gd")
const PointBody=preload("point_body.gd")
const DISPLAY_SCALE:=0.38
var candidates: Array=[]
var bodies: Dictionary={}
var captions: Dictionary={}
var target_index:=0
var held: Dictionary={}
var witness: Node3D
var point
var title: Label3D

func _ready() -> void:
	title=label(Vector3(0,2.2,.4),"")
	point=PointBody.new();add_child(point)
	point.action_pressed.connect(func(_p):act("TARGET"))
	reset()
	act("HOLD")

func reset() -> void:
	for body in bodies.values():remove_child(body);body.queue_free()
	for caption in captions.values():remove_child(caption);caption.queue_free()
	bodies.clear();captions.clear();candidates=Evaluator.opening();target_index=0
	for candidate in candidates:
		bodies[candidate.id]=build(candidate)
		captions[candidate.id]=label(Vector3.ZERO,"")
	arrange()

func act(command: String) -> void:
	var ordered: Array=Evaluator.rank(candidates,Evaluator.TARGETS[target_index])
	match command:
		"TARGET":target_index=(target_index+1)%Evaluator.TARGETS.size()
		"RING":
			var candidate: Dictionary=ordered[0]
			Evaluator.toggle_ring(candidate)
			var old: Node3D=bodies[candidate.id];remove_child(old);old.queue_free()
			bodies[candidate.id]=build(candidate)
		"HOLD":
			held=ordered[0].duplicate()
			if is_instance_valid(witness):remove_child(witness);witness.queue_free()
			witness=build(held);witness.position=Vector3(-2.15,.6,.65)
		"RESET":reset()
	arrange()

func arrange() -> void:
	var target: float=Evaluator.TARGETS[target_index]
	var ordered: Array=Evaluator.rank(candidates,target)
	for rank_index in ordered.size():
		var candidate: Dictionary=ordered[rank_index]
		var at:=Vector3((rank_index%3-1)*1.15,.6,-floori(rank_index/3.0)*1.8)
		var body: Node3D=bodies[candidate.id];body.position=at
		for mesh in body.get_children():
			mesh.material_override.albedo_color=Color("dcaccb") if rank_index==0 else Color("82c4c8")
		var caption: Label3D=captions[candidate.id];caption.position=at+Vector3(0,-.15,.55)
		caption.text="ID %d / rank %d\nestimate %.3f / score %.2f" % [candidate.id,rank_index+1,Evaluator.estimate(candidate),Evaluator.score(candidate,target)]
	title.text="TARGET %.0f / same six candidates\nT or held trigger: target   G: ring   H: hold   R: reset\nMiniatures at 0.38 scale / held ID %s" % [target,str(held.get("id","none"))]

func build(candidate: Dictionary) -> Node3D:
	var body:=Node3D.new();add_child(body);body.scale=Vector3.ONE*DISPLAY_SCALE
	for gene in candidate.genes:
		var mesh: Mesh
		# Only these two primitive types enter this exercise.
		assert(gene.type in ["box","torus"])
		if gene.type=="box":
			var box:=BoxMesh.new();box.size=Vector3.ONE;mesh=box
		else:
			var ring:=TorusMesh.new();ring.inner_radius=.3;ring.outer_radius=.7;mesh=ring
		var surface:=MeshInstance3D.new();surface.mesh=mesh;body.add_child(surface)
		surface.position=gene.position;surface.rotation=gene.rotation;surface.scale=gene.scale
		var finish:=StandardMaterial3D.new();finish.albedo_color=Color("b7b2c7")
		finish.metallic=.3;finish.roughness=.7;surface.material_override=finish
	return body

func label(at: Vector3, text: String) -> Label3D:
	var result:=Label3D.new();result.position=at;result.text=text
	result.font_size=28;result.pixel_size=.002;result.outline_size=8
	add_child(result);return result

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:return
	var actions: Dictionary={KEY_T:"TARGET",KEY_G:"RING",KEY_H:"HOLD",KEY_R:"RESET"}
	if actions.has(event.keycode):act(actions[event.keycode])

func _physics_process(_dt: float) -> void:
	if not point.held():
		point.global_transform=global_transform*Transform3D(Basis.IDENTITY,Vector3(0,1.15,1.1))
