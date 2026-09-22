extends Node3D
## Inspect an addressed surface while its carrier remains physically unchanged.
const SOURCE=[[1,0,0,2],[1,0,0,0],[1,1,3,0],[0,0,0,0]]
var tunnel:Node3D
var panel:Node3D
var readout:Label3D
var buttons:Dictionary={}
var source_cells:Array[MeshInstance3D]=[]
var marker:MeshInstance3D
var column:=1
var row:=10
var face:=0 # floor or right wall
var pitch:=0.4
var show_grid:=true
var history:Array=[]
var platform_route:=false

func _ready() -> void:
	var machine:Node3D=get_parent();tunnel=machine._tunnel
	# Retire the generic animated console only on this map's explicit lesson.
	var old=machine.get_node("ControlConsole");old.get_parent().remove_child(old);old.queue_free()
	tunnel.auto_run=false;tunnel.set_process(false);tunnel._reveal=1.3
	tunnel._motif=SOURCE.duplicate(true);tunnel._gs=4;tunnel.group_index=0
	tunnel.palette.assign([Color("e7dfce"),Color("b32719"),Color("263f80"),Color("c09933")])
	tunnel.reskin();tunnel._apply_reveal()
	var shader=Shader.new()
	shader.code=tunnel.TUNNEL_SHADER.code.replace("uniform float grout =", "uniform float study_grid = 1.0;\nuniform float grout =").replace("mix(col, grout_col, line)","mix(col, grout_col, line * study_grid)")
	for mat:ShaderMaterial in tunnel._mats:mat.shader=shader
	# Fully revealed teaching surfaces do not depend on the legacy world-Z reveal.
	# Their floor stays just above the grid; grid collision carries the feet.
	for mesh in tunnel.get_children():
		if mesh is MeshInstance3D:
			mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			if is_zero_approx(mesh.position.y):mesh.position.y=0.018
	panel=Node3D.new();panel.position=Vector3(3,1.35,1.7);panel.rotation_degrees.x=-12;add_child(panel)
	if platform_route:panel.position.y-=1.0
	box(panel,Vector3.ZERO,Vector3(1.8,1.1,0.08),Color("ded5c4"))
	box(self,Vector3(3,-0.4 if platform_route else 0.6,1.5),Vector3(0.6,1.2,0.4),Color("a69e91"),true)
	label(panel,"ARRAY / SURFACE / PASSAGE",Vector3(0,0.46,0.055),0.0012)
	for y in 4:
		for x in 4:
			source_cells.append(box(panel,Vector3(-0.72+x*0.085,0.27-y*0.085,0.065),Vector3(0.077,0.077,0.012),tunnel.palette[SOURCE[y][x]]))
	readout=label(panel,"",Vector3(0.28,0.15,0.065),0.00095)
	var names=["COL +","ROW +","FACE","CELL SIZE","GRID","UNDO"]
	for i in names.size():
		var id:String=names[i];var b:Node3D=load("res://commons/interactables/push_button.tscn").instantiate()
		b.name=id.replace(" ","_");b.position=Vector3(-0.64+(i%3)*0.64,-0.23-floori(i/3.0)*0.19,0.07)
		panel.add_child(b);b.pressed.connect(func():act(id));buttons[id]=b
		label(panel,id,b.position+Vector3(0,-0.065,0.015),0.00078)
	marker=box(self,Vector3.ZERO,Vector3(0.4,0.025,0.4),Color(1,0.8,0.1,0.4))
	var mm=marker.material_override as StandardMaterial3D;mm.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;mm.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	# Side walls and ceiling bound a real passage; ends stay open.
	box(self,Vector3(-1.865,1.6,-3),Vector3(0.10,3.2,6),Color("c3bbaa"),true).cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	box(self,Vector3(1.865,1.6,-3),Vector3(0.10,3.2,6),Color("c3bbaa"),true).cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	box(self,Vector3(0,3.265,-3),Vector3(3.8,0.1,6),Color("c3bbaa"),true).cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if platform_route:
		# Seal both flanks from the tunnel backing to the bay's perimeter walls.
		# The wings reach down to the lower floor and cannot be walked around.
		for side in [-1,1]:
			var wing=box(self,Vector3(side*3.6575,1,-3),Vector3(3.685,4,0.3),Color("c3bbaa"),true)
			wing.name="RouteWingLeft" if side<0 else "RouteWingRight"
	label(self,"FOLLOW AN ADDRESS",Vector3(0,3.5,0),0.003)
	label(self,"FOLLOW A LINE TO THE CORNER",Vector3(0,3.25,0.03),0.0015)
	machine.set_meta("em_visibility_bounds",AABB(Vector3(-5.6,-1,-6.2),Vector3(11.2,5,9.2)) if platform_route else AABB(Vector3(-2.1,0,-6.2),Vector3(6.2,3.8,9.2)))
	refresh()

func state() -> Dictionary:
	return {"column":column,"row":row,"face":face,"pitch":pitch,"grid":show_grid}

func act(id:String) -> void:
	if id=="UNDO":
		if history.is_empty():return
		var s:Dictionary=history.pop_back();column=s.column;row=s.row;face=s.face;pitch=s.pitch;show_grid=s.grid
	else:
		history.append(state());if history.size()>32:history.pop_front()
		match id:
			"COL +":column+=1
			"ROW +":row+=1
			"FACE":face=1-face
			"CELL SIZE":pitch=0.6 if pitch<0.5 else 0.4
			"GRID":show_grid=not show_grid
	refresh()

func refresh() -> void:
	var width:float=3.6 if face==0 else 6.0
	var height:float=6.0 if face==0 else 3.2
	column=posmod(column,int(floor(width/pitch+0.00001)));row=posmod(row,int(floor(height/pitch+0.00001)))
	for mat:ShaderMaterial in tunnel._mats:
		# Each swatch pixel is one source-addressed surface cell.
		var idx=tunnel._mats.find(mat)
		var extent=Vector2(3.6,6) if idx<2 else Vector2(6,3.2)
		mat.set_shader_parameter("tile_reps",extent/pitch)
		mat.set_shader_parameter("pattern_reps",extent/pitch/32.0)
		mat.set_shader_parameter("grout",0.035)
		mat.set_shader_parameter("study_grid",1.0 if show_grid else 0.0)
	marker.mesh.size=Vector3(pitch,0.025,pitch) if face==0 else Vector3(0.025,pitch,pitch)
	marker.position=Vector3(-1.8+(column+0.5)*pitch,0.035,-6+(row+0.5)*pitch) if face==0 else Vector3(1.78,3.2-(row+0.5)*pitch,-6+(column+0.5)*pitch)
	for i in source_cells.size():
		var m:StandardMaterial3D=source_cells[i].material_override;m.emission_enabled=(i==row%4*4+column%4);m.emission=Color(0.3,0.2,0);m.emission_energy_multiplier=0.4
	readout.text=("FLOOR" if face==0 else "RIGHT WALL")+" / [%d,%d]\nSOURCE [%d,%d] = %d\nCELL %.0f cm / MOTIF %.1f m\nGRID %s"%[row,column,row%4,column%4,SOURCE[row%4][column%4],pitch*100,pitch*4,"ON" if show_grid else "OFF"]

func label(parent:Node3D,text:String,pos:Vector3,pixel:float) -> Label3D:
	var l=Label3D.new();l.text=text;l.position=pos;l.font_size=32;l.pixel_size=pixel;l.outline_size=0;l.modulate=Color("272a30") if parent==panel else Color("fff0da");parent.add_child(l);return l

func box(parent:Node3D,pos:Vector3,size:Vector3,color:Color,solid:bool=false) -> MeshInstance3D:
	var mesh=MeshInstance3D.new();var shape=BoxMesh.new();shape.size=size;mesh.mesh=shape;mesh.position=pos
	var mat=StandardMaterial3D.new();mat.albedo_color=color;mat.roughness=0.9;mesh.material_override=mat;parent.add_child(mesh)
	if solid:
		var body=StaticBody3D.new();body.collision_layer=1;body.collision_mask=0;mesh.add_child(body)
		var collider=CollisionShape3D.new();var bs=BoxShape3D.new();bs.size=size;collider.shape=bs;body.add_child(collider)
	return mesh
