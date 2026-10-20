extends "res://commons/artifacts/timing_machines/machine_stage.gd"
## Six existing research configurations, displayed three at a time.
const Handle = preload("capture_point.gd")
const NAMES := ["CLOTH / TWO PINS","A LATTICE SETTLES","A BRANCH BENDS","A RULE BECOMES THREAD","INSIDE A BOX MOULD","MEETING A SPHERE"]
var samples: Array = []
var bank := 0
var kept := true
var display: Node3D
var point: XRToolsPickable
var was_held := false
var visible_ids: Array[String] = []
var displayed_positions: Array[PackedVector3Array] = []
var builds := 0
var home := Vector3(-3.7,1.13,1.72)
func _ready() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://commons/artifacts/soft_snapshot_gallery/gallery_samples.json"))
	samples=data.samples
	label("FROM THE SOFT BODY GALLERY",Vector3(0,3.55,0),.0027)
	box(Vector3(0,.015,.4),Vector3(9,.025,3.2),material("c5d6d2"))
	box(Vector3(-3.7,.95,1.65),Vector3(1.8,.12,.5),material("26313a"),true)
	box(Vector3(-3.7,.45,1.65),Vector3(.18,.9,.4),material("26313a"),true)
	for id in ["NEXT","POSE"]:
		var button=PUSH.instantiate();button.position=Vector3(-4.25 if id=="NEXT" else -3.15,1.045,1.72);add_child(button);buttons[id]=button
		button.pressed.connect(act.bind(id))
		var caption:=label(id,button.position+Vector3(0,.035,.14),.0011);caption.rotation_degrees.x=-55
	readout=label("",Vector3(-3.7,1.43,1.42),.0011)
	box(Vector3(-3.7,1.43,1.38),Vector3(2.4,.45,.055),material("15232c"))
	point=Handle.new();point.position=home;add_child(point)
	point.action_pressed.connect(func(_s):act("POSE"))
	rebuild()
func _physics_process(_dt: float) -> void:
	if point==null:return
	var held: bool=point.held()
	if was_held and not held:point.position=home
	was_held=held
func act(id: String) -> void:
	if id=="NEXT":bank=1-bank
	else:kept=not kept
	rebuild()
func decode(data: Array) -> PackedVector3Array:
	var result:=PackedVector3Array()
	for v in data:result.append(Vector3(v[0],v[1],v[2]))
	return result
func rebuild() -> void:
	if is_instance_valid(display):remove_child(display);display.queue_free()
	display=Node3D.new();display.name="SavedSamples";add_child(display)
	visible_ids.clear();displayed_positions.clear()
	for slot in 3:
		var index:=bank*3+slot
		var sample: Dictionary=samples[index]
		var points:=decode(sample.kept if kept else sample.initial)
		visible_ids.append(sample.id);displayed_positions.append(points)
		# Both views share one scale and frame: changing pose cannot disguise deformation.
		var all_points:=decode(sample.initial);all_points.append_array(decode(sample.kept))
		var bounds:=AABB(all_points[0],Vector3.ZERO)
		for p in all_points:bounds=bounds.expand(p)
		var factor:=minf(2.1/maxf(bounds.size.x,.01),minf(2.4/maxf(bounds.size.y,.01),1.5/maxf(bounds.size.z,.01)))
		var piece:=Node3D.new();display.add_child(piece)
		piece.scale=Vector3.ONE*factor
		piece.position=Vector3((slot-1)*2.7,.5,0)-Vector3(bounds.get_center().x,bounds.position.y,bounds.get_center().z)*factor
		var colour:=Color(["dc8da7","83b5ad","d8bd7c","b798cb","a4c5de","ddab88"][index])
		var render_data: Dictionary=sample.config.get("render",{})
		var dot_radius:=maxf(.014/factor,float(render_data.get("particle_radius",.02)))
		var dots:=SphereMesh.new();dots.radius=dot_radius;dots.height=dot_radius*2;dots.radial_segments=8;dots.rings=4
		var multi:=MultiMesh.new();multi.transform_format=MultiMesh.TRANSFORM_3D;multi.mesh=dots;multi.instance_count=points.size()
		for i in points.size():multi.set_instance_transform(i,Transform3D(Basis.IDENTITY,points[i]))
		var node:=MultiMeshInstance3D.new();node.multimesh=multi;node.material_override=lit(colour);piece.add_child(node)
		var cylinder:=CylinderMesh.new();cylinder.top_radius=.009/factor;cylinder.bottom_radius=.009/factor;cylinder.height=1;cylinder.radial_segments=6
		var rods:=MultiMesh.new();rods.transform_format=MultiMesh.TRANSFORM_3D;rods.mesh=cylinder
		var edges: Array=sample.springs.filter(func(e):return points[int(e[0])].distance_to(points[int(e[1])])>.00001)
		rods.instance_count=edges.size()
		for i in edges.size():
			var a:=points[int(edges[i][0])];var b:=points[int(edges[i][1])];var delta:=b-a
			var turn:=Basis(Quaternion(Vector3.UP,delta.normalized()))
			rods.set_instance_transform(i,Transform3D(Basis(turn.x,turn.y*delta.length(),turn.z),(a+b)*.5))
		var wires:=MultiMeshInstance3D.new();wires.multimesh=rods;wires.material_override=lit(colour.darkened(.3));piece.add_child(wires)
		if not sample.indices.is_empty():
			var mesh:=ArrayMesh.new();var arrays:=[];arrays.resize(Mesh.ARRAY_MAX)
			arrays[Mesh.ARRAY_VERTEX]=points;arrays[Mesh.ARRAY_INDEX]=PackedInt32Array(sample.indices)
			mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
			var st:=SurfaceTool.new();st.create_from(mesh,0);st.generate_normals()
			var skin:=MeshInstance3D.new();skin.mesh=st.commit();skin.material_override=lit(colour);piece.add_child(skin)
		box(Vector3((slot-1)*2.7,.2,0),Vector3(2.3,.4,1.8),material("292632"),true,display)
		var title:=label(NAMES[index]+"\n"+("STEP %d"%int(sample.config.steps) if kept else "START"),Vector3((slot-1)*2.7,.3,.93),.00115);title.reparent(display,true)
	readout.text=("KEPT SHAPES" if kept else "STARTING SHAPES")+" / set %d of 2\nNEXT: other examples / point trigger: POSE"%(bank+1)
	builds+=1
func lit(c: Color) -> StandardMaterial3D:
	var mat:=StandardMaterial3D.new();mat.albedo_color=c;mat.roughness=.65;mat.cull_mode=BaseMaterial3D.CULL_DISABLED
	mat.emission_enabled=true;mat.emission=c;mat.emission_energy_multiplier=.15
	return mat
