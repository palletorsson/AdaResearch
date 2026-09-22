extends Node3D
## Opt-in paired study: fixed addresses, slice visibility and a height-dependent lookup.
const SOURCE = [[1,0,0,2],[1,0,0,0],[1,1,3,0],[0,0,0,0]] # [z][x]
const PALETTE = [Color("e7dfce"),Color("b32719"),Color("263f80"),Color("c09933")]
const PUSH = preload("res://commons/interactables/push_button.tscn")
var volume:Node3D
var plane:Node3D
var values:Array=[] # [y][z][x]
var voxels:Dictionary={}
var flat:Dictionary={}
var buttons:Dictionary={}
var markers:Array[Node3D]=[]
var mount:Node3D
var status:Label3D
var x_index:int=0
var z_index:int=0
var layer:int=0
var shifted:bool=false
var slice_only:bool=false
var history:Array=[]
var ready_for_use:bool=false

func _ready() -> void:
	volume=get_parent()
	var hall:Node=volume
	while hall.get_parent() and not hall.has_meta("em_map"):hall=hall.get_parent()
	for frame in 120:
		for n in hall.find_children("*","Node3D",true,false):
			if n.get_script() and n.get_script().resource_path=="res://algorithms/arrays/grid_2d_4x4.gd":plane=n;break
		if plane and plane.get("_cube_refs").size()==16:break
		await get_tree().process_frame
	if not plane:
		push_error("Layer pattern lesson needs its paired 4x4 source in the same hall");return
	# Both studies preserve addresses. Collection and decorative bobbing are suspended.
	for x in 4:
		for z in 4:
			var c:Node3D=plane._cube_refs.get("%d_%d"%[x,z])
			if not c:return
			prepare_cube(c,Vector3(x,0,z));flat[Vector2i(x,z)]=c
			for y in 4:
				var v:Node3D=volume.get_node_or_null("Cube_%d_%d_%d"%[x,y,z])
				if not v:return
				prepare_cube(v,Vector3(x,y,z));voxels[Vector3i(x,y,z)]=v
	box(plane,Vector3(1.5,0.015,1.5),Vector3(4,0.03,4),Color("34383e"))
	box(volume,Vector3(1.5,0.015,1.5),Vector3(4,0.03,4),Color("34383e"))
	label(plane,"SOURCE [z][x] / 16 CELLS",Vector3(1.5,0.18,4),0.0017)
	label(volume,"VOLUME [y][z][x] / 64 CELLS",Vector3(1.5,4.3,1.5),0.0017)
	mount=Node3D.new();mount.position=Vector3(-1,1.25,5);mount.rotation_degrees.x=-12;add_child(mount)
	box(mount,Vector3.ZERO,Vector3(1.65,1.10,0.07),Color("292b30"))
	box(mount,Vector3(0,0,0.045),Vector3(1.60,1.05,0.025),Color("e7dfce"))
	box(self,Vector3(-1,0.5,4.8),Vector3(0.55,1,0.4),Color("a6a293"),true)
	label(mount,"AN ADDRESS GAINS DEPTH",Vector3(0,0.43,0.08),0.001)
	status=label(mount,"",Vector3(0,0.15,0.08),0.00095)
	var ids=["X +","Z +","LAYER +","SLICE / ALL","REPEAT / SHIFT","UNDO"]
	for i in ids.size():
		var id:String=ids[i];var pos=Vector3(-0.55+(i%3)*0.55,-0.17-floori(i/3.0)*0.21,0.09)
		var b:Node3D=PUSH.instantiate();b.name=id.replace(" ","_").replace("/","_");b.position=pos;b.scale=Vector3.ONE*0.8;mount.add_child(b);b.pressed.connect(func():act(id));buttons[id]=b
		label(mount,id,pos+Vector3(0,-0.07,0),0.00062)
	for host in [plane,volume]:
		var marker=Node3D.new();host.add_child(marker);markers.append(marker)
		for axis in [0,1,2]:
			for a in [-1,1]:
				for b in [-1,1]:
					var pos=Vector3.ZERO;var size=Vector3.ONE*0.025;size[axis]=0.6;pos[(axis+1)%3]=a*0.3;pos[(axis+2)%3]=b*0.3
					box(marker,pos,size,Color("11e6df"),false,true)
	volume.set_meta("em_visibility_bounds",AABB(Vector3(-3,0,-0.6),Vector3(7,4.8,6.5)))
	plane.set_meta("em_visibility_bounds",AABB(Vector3(-0.6,0,-0.6),Vector3(4.2,1.5,5)))
	ready_for_use=true;refresh()

func prepare_cube(c:Node3D,pos:Vector3) -> void:
	c.process_mode=Node.PROCESS_MODE_DISABLED;c.position=pos;c.rotation=Vector3.ZERO
	for area in c.find_children("*","CollisionObject3D",true,false):area.collision_layer=0;area.collision_mask=0
	for l in c.find_children("*","Label3D",true,false):l.visible=false
	var mesh:MeshInstance3D=c.get_node("CubeBaseMesh");mesh.position=Vector3(0,0.25,0);mesh.rotation=Vector3.ZERO;mesh.scale=Vector3.ONE*0.42
	var mat=StandardMaterial3D.new();mat.roughness=0.85;mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;mesh.material_override=mat

func sample(x:int,y:int,z:int) -> int:
	var source_x:int=(x+y)%4 if shifted else x
	return SOURCE[z][source_x]

func act(id:String) -> void:
	if id=="UNDO":
		if history.is_empty():return
		var old:Array=history.pop_back();x_index=old[0];z_index=old[1];layer=old[2];shifted=old[3];slice_only=old[4]
	else:
		history.append([x_index,z_index,layer,shifted,slice_only])
		if history.size()>32:history.pop_front()
		match id:
			"X +":x_index=(x_index+1)%4
			"Z +":z_index=(z_index+1)%4
			"LAYER +":layer=(layer+1)%4
			"SLICE / ALL":slice_only=not slice_only
			"REPEAT / SHIFT":shifted=not shifted
	refresh()

func refresh() -> void:
	values=[]
	for y in 4:
		var sheet:Array=[]
		for z in 4:
			var row:Array=[]
			for x in 4:row.append(sample(x,y,z))
			sheet.append(row)
		values.append(sheet)
	for key:Vector2i in flat:
		flat[key].get_node("CubeBaseMesh").material_override.albedo_color=PALETTE[SOURCE[key.y][key.x]]
	for key:Vector3i in voxels:
		var c:Node3D=voxels[key];c.visible=not slice_only or key.y==layer
		c.get_node("CubeBaseMesh").material_override.albedo_color=PALETTE[values[key.y][key.z][key.x]]
	var sx:int=(x_index+layer)%4 if shifted else x_index
	markers[0].position=Vector3(sx,0.25,z_index);markers[1].position=Vector3(x_index,layer+0.25,z_index)
	status.text="VOLUME [%d][%d][%d]  <-  SOURCE [%d][%d]\nPALETTE %d / %s / %s"%[layer,z_index,x_index,z_index,sx,sample(x_index,layer,z_index),"SHIFT WITH HEIGHT" if shifted else "REPEAT EACH LAYER","16 VISIBLE / 64 STORED" if slice_only else "64 VISIBLE / 64 STORED"]

func label(host:Node3D,text:String,pos:Vector3,pixel:float) -> Label3D:
	var l=Label3D.new();l.text=text;l.position=pos;l.font_size=32;l.pixel_size=pixel;l.outline_size=0;l.modulate=Color("15191e") if host==mount else Color("25292e");host.add_child(l);return l

func box(host:Node3D,pos:Vector3,size:Vector3,color:Color,solid:bool=false,unshaded:bool=false) -> void:
	var m=MeshInstance3D.new();var mesh=BoxMesh.new();mesh.size=size;m.mesh=mesh;m.position=pos
	var mat=StandardMaterial3D.new();mat.albedo_color=color;mat.roughness=0.85
	if unshaded or host==mount:mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	m.material_override=mat;host.add_child(m)
	if solid:
		var body=StaticBody3D.new();body.collision_layer=1;body.collision_mask=0;m.add_child(body)
		var c=CollisionShape3D.new();var shape=BoxShape3D.new();shape.size=size;c.shape=shape;body.add_child(c)
