extends Node3D
## One changed cell, matched forcing, separate influence and amplitude readings.
const Model=preload("res://algorithms/cellularautomata/ca_showcase/difference_model.gd")
var model=Model.new()
var target:int=0
var elapsed:float=0
var slice_z:int=5
var coating:bool=true
var view_gain:float=1.0
var console:Node3D
var reading:Label3D
var slice_label:Label3D
var textures:Array[ImageTexture]=[]
var materials:Array[StandardMaterial3D]=[]
var walls:Array[MeshInstance3D]=[]
var volumes:Array[MultiMeshInstance3D]=[]
var floor_view:MeshInstance3D
var actions:int=0
var step_usec:int=0

func _ready() -> void:
	_build();_controls();paint()

func operate(i:int) -> void:
	actions+=1;target=0
	match i:
		0:advance(1)
		1:target=mini(model.tick+10,Model.LIMIT);elapsed=0
		2:model.reset()
		3:model.changed=not model.changed;model.reset()
		4:model.coupling=maxf(0,model.coupling-0.25);model.reset()
		5:model.coupling=minf(1,model.coupling+0.25);model.reset()
		6:model.disturbance=maxf(0,model.disturbance-1);model.reset()
		7:model.disturbance=minf(4,model.disturbance+1);model.reset()
		8:model.scattered=not model.scattered;model.reset()
		9:model.integer_storage=not model.integer_storage;model.reset()
		10:slice_z=(slice_z+1)%Model.N
		11:coating=not coating
	paint()

func _process(delta:float) -> void:
	if target<=model.tick:target=0;return
	elapsed+=delta
	if elapsed>=0.12:
		elapsed=0;advance(1)

func advance(n:int) -> void:
	var start:int=Time.get_ticks_usec()
	for _i in range(mini(n,Model.LIMIT-model.tick)):model.step()
	step_usec=Time.get_ticks_usec()-start
	if model.tick>=target:target=0
	paint()

func tint(v:float) -> Color:
	return Color("182c42").lerp(Color("efc0d6"),v/9.0)

func paint() -> void:
	if textures.size()!=3:return
	var rep:Dictionary=model.report()
	get_node("VolumeLabel_1").text="B / ONE ADDRESS CHANGED" if model.changed else "B / MATCHED REFERENCE"
	# Magnify only the difference display. The gain is always printed.
	view_gain=1.0/maxf(rep.max_difference,0.000001)
	for side in range(3):
		var img:=Image.create(Model.N,Model.N,false,Image.FORMAT_RGBA8)
		for y in range(Model.N):
			for x in range(Model.N):
				var i:int=x+Model.N*y+Model.N*Model.N*slice_z
				var c:Color=tint(model.a[i] if side==0 else model.b[i]) if side<2 else Color("112c31").lerp(Color("ffd18e"),absf(model.a[i]-model.b[i])*view_gain)
				img.set_pixel(x,Model.N-1-y,c)
		textures[side].update(img);walls[side].visible=coating
	floor_view.visible=coating
	for side in range(2):
		var data:PackedFloat64Array=model.a if side==0 else model.b
		for i in range(Model.COUNT):volumes[side].multimesh.set_instance_color(i,tint(data[i]))
	reading.text="%s / UPDATE %d OF %d\nNEIGHBOUR PULL %.2f / DISTURBANCE %.1f\n%s / %s / B %s\nDIFFERENT %d / %d (above 0.000001)\nMAX DIFFERENCE %.6f / MEAN %.6f\nDIFFERENCE DISPLAY GAIN x%.1f"%["RUN TO %d"%target if target>model.tick else "HELD",model.tick,Model.LIMIT,model.coupling,model.disturbance,"INTEGER" if model.integer_storage else "FRACTIONAL","SCATTERED" if model.scattered else "UNIFORM 4","+1 CELL" if model.changed else "MATCHED",rep.different,Model.COUNT,rep.max_difference,rep.mean_difference,view_gain]
	slice_label.text="SPATIAL SLICE Z=%d / TIME IS UPDATE %d\nA                       B                       |A-B| x%.1f"%[slice_z,model.tick,view_gain]

func readback() -> Dictionary:
	var r:Dictionary=model.report();r.merge({"slice":slice_z,"coating":coating,"target":target,"actions":actions,"gain":view_gain,"step_usec":step_usec});return r

func _build() -> void:
	# Paired full volumes: all 1,331 addresses shown, no skipped lattice sites.
	for side in range(2):
		var cx:float=2.8 if side==0 else -2.8
		box("VolumeBase_%d"%side,Vector3(3.15,0.2,3.15),Vector3(cx,0.1,1.6),Color("314857"),true)
		var mm:=MultiMesh.new();mm.transform_format=MultiMesh.TRANSFORM_3D;mm.use_colors=true
		var mesh:=BoxMesh.new();mesh.size=Vector3.ONE*0.095;mm.mesh=mesh;mm.instance_count=Model.COUNT
		for z in range(Model.N):
			for y in range(Model.N):
				for x in range(Model.N):mm.set_instance_transform(x+Model.N*y+Model.N*Model.N*z,Transform3D(Basis(),Vector3((x-5)*0.27,0.5+y*0.27,(z-5)*0.27)))
		var mi:=MultiMeshInstance3D.new();mi.name="Volume_%d"%side;mi.multimesh=mm;mi.position=Vector3(cx,0,1.6)
		var mat:=StandardMaterial3D.new();mat.vertex_color_use_as_albedo=true;mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;mi.material_override=mat;add_child(mi);volumes.append(mi)
		var label_:Label3D=label("VolumeLabel_%d"%side,"A / REFERENCE RUN" if side==0 else "B / ONE ADDRESS CHANGED",42)
		label_.position=Vector3(cx,3.52,1.6);label_.rotation_degrees.y=180;add_child(label_)
	# Side-by-side spatial sections, mounted in brass cases above a clear route.
	for side in range(3):
		var cx:float=3.9-3.9*side
		var img:=Image.create(Model.N,Model.N,false,Image.FORMAT_RGBA8);img.fill(Color.BLACK)
		var tex:=ImageTexture.create_from_image(img);textures.append(tex)
		var mat:=StandardMaterial3D.new();mat.albedo_texture=tex;mat.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST;mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;mat.cull_mode=BaseMaterial3D.CULL_DISABLED;materials.append(mat)
		box("SliceCase_%d"%side,Vector3(3.5,3.5,0.14),Vector3(cx,2.2,6.5),Color("b59a79"))
		var mi:=MeshInstance3D.new();mi.name="Slice_%d"%side;var quad:=QuadMesh.new();quad.size=Vector2(3.25,3.25);mi.mesh=quad;mi.material_override=mat;mi.position=Vector3(cx,2.2,6.41);mi.rotation_degrees.y=180;add_child(mi);walls.append(mi)
	floor_view=MeshInstance3D.new();floor_view.name="DifferenceFloor";var pm:=PlaneMesh.new();pm.size=Vector2(2,4);floor_view.mesh=pm;floor_view.material_override=materials[2];floor_view.position=Vector3(0,0.016,2);add_child(floor_view)
	slice_label=label("SliceLabels","",42);slice_label.position=Vector3(0,4.25,6.3);slice_label.rotation_degrees.y=180;add_child(slice_label)
	var note:=label("FloorNote","SAME Z SLICE / DIFFERENCE ON THE FLOOR / FIXED SUPPORT",28);note.position=Vector3(0,0.025,4.4);note.rotation_degrees=Vector3(-90,0,0);add_child(note)

func _controls() -> void:
	box("ConsoleFoot",Vector3(2.5,0.12,0.8),Vector3(-5,0.06,-1.7),Color("314857"),true)
	box("ConsoleStem",Vector3(0.14,1.1,0.14),Vector3(-5,0.6,-1.7),Color("b59a79"),true)
	console=Node3D.new();console.name="DifferenceConsole";console.position=Vector3(-5,1.15,-1.7);console.rotation_degrees=Vector3(-35,180,0);add_child(console)
	var rack:GDScript=load("res://commons/audio/rack_templates/RackTemplates.gd")
	var rows:Array=[]
	for names in [["STEP","+10","REPLAY","ONE CELL"],["PULL -","PULL +","DRIVE -","DRIVE +"],["SEED","STORE","Z SLICE","COAT"]]:
		var row:Array=[]
		for words in names:row.append({"type":"button","label":words})
		rows.append(row)
	var controls:Node3D=rack.create_panel("HOW FAR DOES ONE DIFFERENCE GO?",rows,false);controls.scale=Vector3.ONE*2.5;console.add_child(controls)
	for i in range(12):controls.find_child("Btn_%d"%i,true,false).get_node("InteractableAreaButton").button_pressed.connect(func(_b):operate(i))
	box("ReadoutCase",Vector3(4.8,1.12,0.07),Vector3(-4.8,2.25,-0.65),Color("172937"))
	reading=label("Reading","",38);reading.pixel_size=0.0023;reading.position=Vector3(-4.8,2.25,-0.70);reading.rotation_degrees.y=180;add_child(reading)

func label(name_:String,words:String,font:int) -> Label3D:
	var n:=Label3D.new();n.name=name_;n.text=words;n.font_size=font;n.pixel_size=0.002;n.outline_size=0;n.modulate=Color("ffe6c7");return n

func box(name_:String,size:Vector3,at:Vector3,colour:Color,solid:bool=false) -> MeshInstance3D:
	var n:=MeshInstance3D.new();n.name=name_;n.position=at;var mesh:=BoxMesh.new();mesh.size=size;n.mesh=mesh
	var mat:=StandardMaterial3D.new();mat.albedo_color=colour;mat.roughness=0.7;n.material_override=mat;add_child(n)
	if solid:
		var body:=StaticBody3D.new();var col:=CollisionShape3D.new();var shape:=BoxShape3D.new();shape.size=size;col.shape=shape;n.add_child(body);body.add_child(col)
	return n
