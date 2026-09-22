extends Node3D
## Two bounded studies: context with unchanged targets; a shared texture on two carriers.
const SOURCE = [[1,0,0,2],[1,0,0,0],[1,1,3,0],[0,0,0,0]]
const PALETTE = [Color("e7dfce"),Color("b32719"),Color("263f80"),Color("c09933")]
const PUSH = preload("res://commons/interactables/push_button.tscn")
var mode:String="carrier"
var buttons:Dictionary={}
var samples:Array[MeshInstance3D]=[]
var backgrounds:Array[MeshInstance3D]=[]
var bridge:MeshInstance3D
var material:ShaderMaterial
var mount:Node3D
var status:Label3D
var shaded:bool=false
var right_light:bool=false
var dense:bool=false
var grid:bool=false
var neutral:bool=false
var swapped:bool=false
var connected:bool=false
var history:Array=[]

func _ready() -> void:
	box(self,Vector3(0,1.65,-0.5),Vector3(9.4,3.3,0.12),Color("33383e"))
	if mode=="carrier":build_carriers()
	else:build_context()
	mount=Node3D.new();mount.position=Vector3(0,1.22,1.5);mount.rotation_degrees.x=-12;add_child(mount)
	box(mount,Vector3.ZERO,Vector3(1.8,1.05,0.08),Color("252a30"))
	box(mount,Vector3(0,0,0.05),Vector3(1.75,1,0.025),Color("e7dfce"))
	box(self,Vector3(0,0.5,1.3),Vector3(0.5,1,0.4),Color("aaa595"),true)
	label(mount,"SAME RECIPE / DIFFERENT CARRIER" if mode=="carrier" else "KEEP THE TARGET / CHANGE ITS NEIGHBOURS",Vector3(0,0.40,0.08),0.00087)
	status=label(mount,"",Vector3(0,0.16,0.08),0.00086)
	var ids=["FLAT / SHADED","LIGHT SIDE","REPEAT SIZE","GRID","UNDO","RESET"] if mode=="carrier" else ["SURROUNDS","SWAP","CONNECT","UNDO","RESET"]
	for i in ids.size():
		var id:String=ids[i];var pos=Vector3(-0.58+(i%3)*0.58,-0.15-floori(i/3.0)*0.20,0.09)
		var b:Node3D=PUSH.instantiate();b.name=id.replace("/","_").replace(" ","_");b.position=pos;b.scale=Vector3.ONE*0.8;mount.add_child(b);b.pressed.connect(func():act(id));buttons[id]=b
		label(mount,id,pos+Vector3(0,-0.063,0),0.00059)
	get_parent().set_meta("em_visibility_bounds",AABB(Vector3(-4.8,0,-0.7),Vector3(9.6,3.5,4)))
	refresh()

func build_carriers() -> void:
	var im=Image.create(4,4,false,Image.FORMAT_RGBA8)
	for y in 4:
		for x in 4:im.set_pixel(x,y,PALETTE[SOURCE[y][x]])
	material=ShaderMaterial.new();material.shader=preload("res://algorithms/color/carrier_comparison.gdshader");material.set_shader_parameter("motif",ImageTexture.create_from_image(im))
	var flat=MeshInstance3D.new();var quad=QuadMesh.new();quad.size=Vector2(4,2);flat.mesh=quad;flat.position=Vector3(-2.3,1.7,0);flat.material_override=material;add_child(flat);samples.append(flat)
	# A half cylinder, four metres along its arc: equal UV span and physical width.
	var vertices=PackedVector3Array();var normals=PackedVector3Array();var uvs=PackedVector2Array();var indices=PackedInt32Array()
	for i in 65:
		var u=float(i)/64.0;var angle=(u-0.5)*PI
		for j in 2:
			vertices.append(Vector3(sin(angle)*4.0/PI,1.0-j*2.0,cos(angle)*4.0/PI))
			normals.append(Vector3(sin(angle),0,cos(angle)));uvs.append(Vector2(u,j))
	for i in 64:
		var k=i*2;indices.append_array(PackedInt32Array([k,k+1,k+2,k+2,k+1,k+3]))
	var arr=[];arr.resize(Mesh.ARRAY_MAX);arr[Mesh.ARRAY_VERTEX]=vertices;arr[Mesh.ARRAY_NORMAL]=normals;arr[Mesh.ARRAY_TEX_UV]=uvs;arr[Mesh.ARRAY_INDEX]=indices
	var mesh=ArrayMesh.new();mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arr)
	var curve=MeshInstance3D.new();curve.mesh=mesh;curve.position=Vector3(2.3,1.7,0);curve.material_override=material;add_child(curve);samples.append(curve)
	label(self,"PLANE / 4 m WIDE",Vector3(-2.3,2.95,0),0.0013)
	label(self,"CURVE / 4 m ALONG ARC",Vector3(2.3,2.95,0),0.0013)

func build_context() -> void:
	for x in [-2.3,2.3]:
		backgrounds.append(box(self,Vector3(x,1.7,0),Vector3(4,2,0.05),Color.WHITE))
		samples.append(box(self,Vector3(x,1.7,0.06),Vector3(0.65,0.65,0.05),Color(0.5,0.5,0.5)))
	bridge=box(self,Vector3(0,1.7,0.07),Vector3(4.6,0.14,0.05),Color(0.5,0.5,0.5))
	label(self,"TWO TARGETS / ONE RGB VALUE",Vector3(0,2.95,0),0.0013)

func act(id:String) -> void:
	if id=="UNDO":
		if history.is_empty():return
		var s:Array=history.pop_back();shaded=s[0];right_light=s[1];dense=s[2];grid=s[3];neutral=s[4];swapped=s[5];connected=s[6]
	else:
		history.append([shaded,right_light,dense,grid,neutral,swapped,connected])
		if history.size()>32:history.pop_front()
		match id:
			"FLAT / SHADED":shaded=not shaded
			"LIGHT SIDE":right_light=not right_light
			"REPEAT SIZE":dense=not dense
			"GRID":grid=not grid
			"SURROUNDS":neutral=not neutral
			"SWAP":swapped=not swapped
			"CONNECT":connected=not connected
			"RESET":shaded=false;right_light=false;dense=false;grid=false;neutral=false;swapped=false;connected=false
	refresh()

func refresh() -> void:
	if mode=="carrier":
		material.set_shader_parameter("shaded",shaded);material.set_shader_parameter("repeats",8.0 if dense else 4.0);material.set_shader_parameter("show_grid",grid);material.set_shader_parameter("light_direction",Vector3(0.7 if right_light else -0.7,0.5,1))
		status.text="%s / LIGHT %s / %s PER REPEAT\nFixed source / local directional shading model"%["SHADED" if shaded else "FLAT COLOUR","RIGHT" if right_light else "LEFT","50 cm" if dense else "1 m"]
	else:
		for i in 2:backgrounds[i].material_override.albedo_color=Color(0.5,0.5,0.5) if neutral else (Color(0.1,0.1,0.1) if (i==0)!=swapped else Color(0.9,0.9,0.9))
		bridge.visible=connected
		status.text="TARGETS / RGB (0.5, 0.5, 0.5)\n%s / %s"%["EQUAL SURROUNDS" if neutral else "DARK + LIGHT","CONNECTED" if connected else "SEPARATE"]

func label(host:Node3D,text:String,pos:Vector3,pixel:float) -> Label3D:
	var l=Label3D.new();l.text=text;l.position=pos;l.font_size=32;l.pixel_size=pixel;l.outline_size=0;l.modulate=Color("20262c") if host==mount else Color("eee7da");host.add_child(l);return l

func box(host:Node3D,pos:Vector3,size:Vector3,color:Color,solid:bool=false) -> MeshInstance3D:
	var m=MeshInstance3D.new();var mesh=BoxMesh.new();mesh.size=size;m.mesh=mesh;m.position=pos
	var mat=StandardMaterial3D.new();mat.albedo_color=color;mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;m.material_override=mat;host.add_child(m)
	if solid:
		var body=StaticBody3D.new();body.collision_layer=1;body.collision_mask=0;m.add_child(body)
		var c=CollisionShape3D.new();var shape=BoxShape3D.new();shape.size=size;c.shape=shape;body.add_child(c)
	return m
