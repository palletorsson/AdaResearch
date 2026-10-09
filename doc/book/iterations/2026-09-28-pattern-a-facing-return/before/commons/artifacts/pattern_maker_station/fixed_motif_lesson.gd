extends Node3D
## Tutorial_Pattern's opt-in comparison. One source; two fixed receiving rules.
const SEED = [[1,0,0,2],[1,0,0,0],[1,1,3,0],[0,0,0,0]]
var station:Node3D
var mount:Node3D
var buttons:Dictionary={}
var cells:Array=[]
var panels:Array[MeshInstance3D]=[]
var history:Array=[]
var status:Label3D

func _ready() -> void:
	station=get_parent()
	# This lesson supplies pointer-capable cells as well as ordinary push buttons.
	# The untouched legacy station remains available in every other configuration.
	station._panel_root.visible=false
	for area in station._panel_root.find_children("*","Area3D",true,false):
		area.collision_layer=0;area.collision_mask=0
	station.set_process(false)
	# This cell lesson exposes the discrete source; other stations keep their finish.
	var lesson_shader=Shader.new()
	lesson_shader.code=station._carpet_shader_material.shader.code.replace("filter_linear, repeat_disable","filter_nearest, repeat_disable")
	station._carpet_shader_material.shader=lesson_shader
	rotation.y=PI
	mount=Node3D.new();mount.position=Vector3(0,1.25,0);mount.rotation_degrees.x=-12;add_child(mount)
	box(mount,Vector3.ZERO,Vector3(1.34,1.12,0.07),Color("292b30"))
	box(mount,Vector3(0,0,0.045),Vector3(1.29,1.07,0.025),Color("e7dfce"))
	box(self,Vector3(0,0.55,-0.25),Vector3(0.55,1.1,0.35),Color("b5ad9c"),true)
	label(mount,"ONE SOURCE / 4 x 4",Vector3(0,0.46,0.07),0.0011)
	for y in 4:
		for x in 4:
			var b=button(mount,"cell_%d_%d"%[x,y],Vector3(-0.36+x*0.10,0.28-y*0.10,0.08),func():paint(x,y))
			b.scale=Vector3.ONE*0.72;cells.append(b)
	for i in 8:
		var b=button(mount,"paint_%d"%i,Vector3(-0.48+i*0.137,-0.17,0.08),func():station._select_color(i);refresh())
		b.scale=Vector3.ONE*0.55;b.released_color=station.PALETTE[i];b.pressed_color=station.PALETTE[i];b.update_colors()
	var actions=["P1","PM","FLIP X","ROTATE","UNDO","RESET"]
	for i in actions.size():
		var id:String=actions[i]
		var pos=Vector3(-0.48+(i%3)*0.48,-0.31-floori(i/3.0)*0.15,0.08)
		var b=button(mount,id,pos,func():act(id));b.scale=Vector3.ONE*0.6
		label(mount,id,pos+Vector3(0,-0.054,0),0.00065)
	status=label(mount,"",Vector3(0.29,0.15,0.08),0.00078)
	for i in 2:
		var frame=Node3D.new();frame.position=Vector3(-1.95 if i==0 else 1.95,1.5,-0.25);add_child(frame)
		box(frame,Vector3(0,0,-0.06),Vector3(1.72,1.86,0.10),Color("292b30"),true)
		var mesh=MeshInstance3D.new();var quad=QuadMesh.new();quad.size=Vector2(1.6,1.6);mesh.mesh=quad;frame.add_child(mesh);panels.append(mesh)
		mesh.material_override=station._carpet_shader_material.duplicate()
		label(frame,"P1" if i==0 else "PM",Vector3(0,1.05,0.01),0.0021)
		label(frame,"SAME SOURCE / 40 cm PER TILE",Vector3(0,-1.05,0.01),0.0012)
	station.set_meta("em_visibility_bounds",AABB(Vector3(-3,0,-2.5),Vector3(6,3,5)))
	reset_source();refresh()

func reset_source() -> void:
	station._grid_data=SEED.duplicate(true);station._group_index=0;station._current_group=station.GROUP_ORDER[0]
	station.carpet_repeats=10;station._selected_color=1

func snapshot() -> Dictionary:
	return {"domain":station._grid_data.duplicate(true),"group":station._group_index,"paint":station._selected_color}

func remember() -> void:
	history.append(snapshot())
	if history.size()>32:history.pop_front()

func paint(x:int,y:int) -> void:
	if station._grid_data[y][x]==station._selected_color:return
	remember();station._paint_cell(x,y);refresh()

func act(id:String) -> void:
	if id=="UNDO":
		if history.is_empty():return
		var previous:Dictionary=history.pop_back()
		station._grid_data=previous.domain;station._group_index=previous.group;station._selected_color=previous.paint
	else:
		remember()
		match id:
			"P1":station._group_index=0
			"PM":station._group_index=2
			"FLIP X":station._mirror_x()
			"ROTATE":station._rotate_cw()
			"RESET":reset_source()
	station._current_group=station.GROUP_ORDER[station._group_index]
	refresh()

func refresh() -> void:
	station._refresh_grid_visuals();station._update_carpet()
	for i in cells.size():
		var c:Color=station.PALETTE[station._grid_data[i/4][i%4]]
		cells[i].released_color=c;cells[i].pressed_color=c
		cells[i].update_colors()
	for i in panels.size():
		var mat:ShaderMaterial=panels[i].material_override
		mat.set_shader_parameter("domain_texture",station._domain_texture)
		mat.set_shader_parameter("tile_scale",4.0)
		mat.set_shader_parameter("wallpaper_group",0 if i==0 else 2)
	status.text="FLOOR / "+("P1" if station._group_index==0 else "PM")+"\n\nPAINT / "+str(station._selected_color)+"\n\n40 cm / TILE"

func button(parent:Node3D,id:String,pos:Vector3,action:Callable) -> Node3D:
	var b:Node3D=station.PUSH_BUTTON.instantiate();b.name=id.replace(" ","_");b.position=pos;parent.add_child(b)
	b.pressed.connect(action);buttons[id]=b;return b

func label(parent:Node3D,text:String,pos:Vector3,pixel:float) -> Label3D:
	var l=Label3D.new();l.text=text;l.position=pos;l.font_size=32;l.pixel_size=pixel;l.outline_size=0
	l.modulate=Color("272a30") if parent==mount else Color("f4ead4");parent.add_child(l);return l

func box(parent:Node3D,pos:Vector3,size:Vector3,color:Color,solid:bool=false) -> void:
	var mesh=MeshInstance3D.new();var shape=BoxMesh.new();shape.size=size;mesh.mesh=shape;mesh.position=pos
	var mat=StandardMaterial3D.new();mat.albedo_color=color;mat.roughness=0.9;mesh.material_override=mat;parent.add_child(mesh)
	if solid:
		var body=StaticBody3D.new();body.collision_layer=1;body.collision_mask=0;mesh.add_child(body)
		var collider=CollisionShape3D.new();var bs=BoxShape3D.new();bs.size=size;collider.shape=bs;body.add_child(collider)
