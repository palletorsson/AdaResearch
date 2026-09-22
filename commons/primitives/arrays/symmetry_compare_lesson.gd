extends Node3D
## A bounded comparison using the existing editor's source and CPU renderer.
const SEED = [[1,0,0,2],[1,0,0,0],[1,1,3,0],[0,0,0,0]]
const GROUPS = [WallpaperGroups.Group.P1, WallpaperGroups.Group.PM, WallpaperGroups.Group.PG]
const NAMES = ["P1 / TRANSLATE", "PM / REFLECT", "PG / GLIDE"]
const PUSH = preload("res://commons/interactables/push_button.tscn")
var station:Node3D
var puzzle:Node3D
var mount:Node3D
var buttons:Dictionary={}
var cells:Array=[]
var live:MeshInstance3D
var held:MeshInstance3D
var live_label:Label3D
var held_label:Label3D
var status:Label3D
var group_index:int=0
var paint_index:int=1
var history:Array=[]

func _ready() -> void:
	station=get_parent();puzzle=station._puzzle
	# Hide and suspend the nested physical-cube editor in this placement only.
	puzzle.visible=false;puzzle.process_mode=Node.PROCESS_MODE_DISABLED
	for area in puzzle.find_children("*","CollisionObject3D",true,false):
		area.collision_layer=0;area.collision_mask=0
	station._wall_preview.visible=false;station._title_label.visible=false;station._mode_label.visible=false
	mount=Node3D.new();mount.position=Vector3(0,1.2,0.6);mount.rotation_degrees.x=-12;add_child(mount)
	box(mount,Vector3.ZERO,Vector3(1.4,1.05,0.08),Color("292b30"))
	box(mount,Vector3(0,0,0.05),Vector3(1.35,1,0.025),Color("e7dfce"))
	box(self,Vector3(0,0.5,0.35),Vector3(0.5,1,0.4),Color("b5ad9c"),true)
	label(mount,"ONE MARK / THREE RULES",Vector3(0,0.43,0.08),0.001)
	label(mount,"SOURCE",Vector3(-0.27,0.35,0.09),0.00065)
	label(mount,"PAINT",Vector3(0.32,0.35,0.09),0.00065)
	for y in 4:
		for x in 4:
			var b=button("cell_%d_%d"%[x,y],Vector3(-0.43+x*0.11,0.26-y*0.11,0.09),func():paint(x,y))
			b.scale=Vector3.ONE*0.72;cells.append(b)
	for i in 4:
		var b=button("paint_%d"%i,Vector3(0.13+i*0.13,0.26,0.09),func():paint_index=i;refresh())
		b.scale=Vector3.ONE*0.7;b.released_color=puzzle.palette[i];b.pressed_color=puzzle.palette[i];b.update_colors()
	var actions=["P1","PM","PG","HOLD","UNDO","RESET"]
	for i in actions.size():
		var id:String=actions[i];var pos=Vector3(-0.47+(i%3)*0.47,-0.25-floori(i/3.0)*0.15,0.09)
		var b=button(id,pos,func():act(id));b.scale=Vector3.ONE*0.65
		label(mount,id,pos+Vector3(0,-0.055,0),0.0007)
	status=label(mount,"",Vector3(0.32,0.03,0.09),0.0007)
	box(self,Vector3(0,1.65,-1.43),Vector3(5.25,3.3,0.14),Color("363a40"),true)
	live=panel(1.75);held=panel(-1.75)
	live_label=label(self,"",Vector3(1.75,2.48,-1.2),0.0015)
	held_label=label(self,"",Vector3(-1.75,2.48,-1.2),0.0015)
	label(self,"Finite samples / 8 x 8 source blocks / 4 x 4 cells per source",Vector3(0,2.85,-1.2),0.0014)
	station.set_meta("em_visibility_bounds",AABB(Vector3(-2.6,0,-3.1),Vector3(5.2,3.1,4.4)))
	puzzle.set_pattern_data(SEED);refresh();hold_sample()

func panel(x:float) -> MeshInstance3D:
	box(self,Vector3(x,1.6,-1.26),Vector3(1.58,1.58,0.10),Color("292b30"),true)
	var m=MeshInstance3D.new();var q=QuadMesh.new();q.size=Vector2(1.45,1.45);m.mesh=q;m.position=Vector3(x,1.6,-1.2)
	var mat=StandardMaterial3D.new();mat.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST;mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;m.material_override=mat;add_child(m);return m

func snapshot() -> Dictionary:
	return {"source":puzzle.get_pattern_data(),"group":group_index,"paint":paint_index,"held":held.material_override.albedo_texture,"caption":held_label.text}

func remember() -> void:
	history.append(snapshot())
	if history.size()>32:history.pop_front()

func paint(x:int,y:int) -> void:
	if puzzle.get_cell(x,y)==paint_index:return
	remember();puzzle.set_cell(x,y,paint_index);refresh()

func act(id:String) -> void:
	if id=="UNDO":
		if history.is_empty():return
		var old:Dictionary=history.pop_back();puzzle.set_pattern_data(old.source);group_index=old.group;paint_index=old.paint
		held.material_override.albedo_texture=old.held;held_label.text=old.caption
	else:
		remember()
		match id:
			"P1":group_index=0
			"PM":group_index=1
			"PG":group_index=2
			"HOLD":hold_sample()
			"RESET":puzzle.set_pattern_data(SEED);group_index=0;paint_index=1
	refresh()

func hold_sample() -> void:
	# Own the pixels: later source edits and rule changes cannot alter this image.
	held.material_override.albedo_texture=ImageTexture.create_from_image(station._carpet_material.albedo_texture.get_image())
	held_label.text="HELD / "+NAMES[group_index]

func refresh() -> void:
	puzzle.symmetry_mode=1;puzzle.wallpaper_group=GROUPS[group_index]
	station._update_carpet_texture()
	live.material_override.albedo_texture=station._carpet_material.albedo_texture
	live_label.text="LIVE / "+NAMES[group_index]
	for i in cells.size():
		var c:Color=puzzle.palette[puzzle.get_cell(i%4,i/4)]
		cells[i].released_color=c;cells[i].pressed_color=c;cells[i].update_colors()
	status.text="PAINT / %d\n\n%s\n\nHOLD keeps pixels"%[paint_index,["REPEAT","REVERSE X","REVERSE X\n+ 2 SOURCE ROWS"][group_index]]

func button(id:String,pos:Vector3,action:Callable) -> Node3D:
	var b:Node3D=PUSH.instantiate();b.name=id;b.position=pos;mount.add_child(b);b.pressed.connect(action);buttons[id]=b;return b

func label(parent:Node3D,text:String,pos:Vector3,pixel:float) -> Label3D:
	var l=Label3D.new();l.text=text;l.position=pos;l.font_size=32;l.pixel_size=pixel;l.outline_size=0
	l.modulate=Color("272a30") if parent==mount else Color("f4ead4");parent.add_child(l);return l

func box(parent:Node3D,pos:Vector3,size:Vector3,color:Color,solid:bool=false) -> void:
	var m=MeshInstance3D.new();var mesh=BoxMesh.new();mesh.size=size;m.mesh=mesh;m.position=pos
	var mat=StandardMaterial3D.new();mat.albedo_color=color;mat.roughness=0.9;m.material_override=mat;parent.add_child(m)
	if solid:
		var body=StaticBody3D.new();body.collision_layer=1;body.collision_mask=0;m.add_child(body)
		var c=CollisionShape3D.new();var shape=BoxShape3D.new();shape.size=size;c.shape=shape;body.add_child(c)
