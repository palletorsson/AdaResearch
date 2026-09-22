extends Node3D
## A matched field comparison. Colour is a projection; the room floor stays solid.
const Field=preload("res://commons/artifacts/rd_artifact/live_field.gd")
const LIMIT:int=2400
const WITNESS:int=15*32+12
var left=Field.new()
var right=Field.new()
var running:bool=false
var target:int=0
var elapsed:float=0.0
var show_u:bool=false
var coating:bool=true
var injections:int=0
var exchange_revealed:bool=false
var console:Node3D
var reading:Label3D
var left_title:Label3D
var right_title:Label3D
var textures:Array[ImageTexture]=[]
var materials:Array[StandardMaterial3D]=[]
var walls:Array[MeshInstance3D]=[]
var last_batch_usec:int=0

func _ready() -> void:
	right.exchange=false
	_build_space();_build_console();reset()

func reset() -> void:
	left.reset();right.reset();running=false;target=0;elapsed=0;injections=0;_paint()

func step_once() -> void:
	running=false;target=0;advance(1)

func advance(count:int) -> void:
	var start:int=Time.get_ticks_usec()
	for _i in range(mini(count,LIMIT-left.ticks)):
		left.step();right.step()
	last_batch_usec=Time.get_ticks_usec()-start
	if left.ticks>=LIMIT or (target>0 and left.ticks>=target):running=false;target=0
	_paint()

func toggle_run() -> void:
	running=not running and left.ticks<LIMIT;target=0;elapsed=0;_readout()

func hundred() -> void:
	target=mini(left.ticks+100,LIMIT);running=left.ticks<LIMIT;elapsed=0;_readout()

func toggle_exchange() -> void:
	# Observation keeps A/B open; the visitor's intervention names the relation.
	# REPLAY retains this knowledge along with the chosen exchange setting.
	exchange_revealed=true
	right.exchange=not right.exchange;reset()

func inject() -> void:
	left.inject();right.inject();injections+=1;_paint()

func change_view() -> void:
	show_u=not show_u;_paint()

func toggle_coating() -> void:
	coating=not coating;_paint()

func _process(delta:float) -> void:
	if not running:return
	elapsed+=delta
	if elapsed<0.1:return
	elapsed=0.0
	# Bounded work, no catch-up loop. Simulation ticks are not seconds of wall time.
	advance(mini(4,target-left.ticks) if target>0 else 4)

func tint(value:float) -> Color:
	return Color("122d3d").lerp(Color("edb1cb"),clampf(value*2.0,0.0,1.0)) if not show_u else Color("241e46").lerp(Color("bce8bc"),value)

func _paint() -> void:
	for side in range(2):
		var field=left if side==0 else right
		var data:PackedFloat32Array=field.u if show_u else field.v
		var img:=Image.create(32,32,false,Image.FORMAT_RGBA8)
		for y in range(32):
			for x in range(32):img.set_pixel(x,y,tint(data[y*32+x]))
		textures[side].update(img)
		walls[side].visible=coating
	_readout()

func _readout() -> void:
	var state:String="LIMIT" if left.ticks==LIMIT else "RUN" if running else "HELD"
	var intervention:String="B EXCHANGE %s / INJECTIONS %d"%["ON" if right.exchange else "OFF",injections] if exchange_revealed else "INJECTIONS %d"%injections
	reading.text="%s / TICK %d / dt 1\nW (12,15)    U        V\nA             %.3f    %.3f\nB             %.3f    %.3f\nVIEW %s / FEED .037 / KILL .060\n%s"%[state,left.ticks,left.u[WITNESS],left.v[WITNESS],right.u[WITNESS],right.v[WITNESS],"U" if show_u else "V ×2",intervention]
	left_title.text="A / EXCHANGE ON" if exchange_revealed else "A"
	right_title.text=("B / EXCHANGE " + ("ON" if right.exchange else "OFF")) if exchange_revealed else "B"

func readback() -> Dictionary:
	return {"ticks":left.ticks,"right_ticks":right.ticks,"running":running,"target":target,"exchange":right.exchange,"exchange_revealed":exchange_revealed,"view_u":show_u,"coating":coating,"injections":injections,"u_a":left.u[WITNESS],"v_a":left.v[WITNESS],"u_b":right.u[WITNESS],"v_b":right.v[WITNESS],"batch_usec":last_batch_usec}

func _build_space() -> void:
	for side in range(2):
		# A is on the visitor's left when looking down the hall's +Z direction.
		var cx:float=2.45 if side==0 else -2.45
		var image:=Image.create(32,32,false,Image.FORMAT_RGBA8);image.fill(Color.BLACK)
		var texture:=ImageTexture.create_from_image(image);textures.append(texture)
		var mat:=StandardMaterial3D.new();mat.albedo_texture=texture;mat.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST
		mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;mat.cull_mode=BaseMaterial3D.CULL_DISABLED;materials.append(mat)
		# The same texture is mounted twice; no second automaton in the architecture.
		var desk:=box("FieldDesk_%d"%side,Vector3(1.72,0.12,1.72),Vector3(cx,0.9,0.5),Color("71584d"),true)
		box("FieldPlinth_%d"%side,Vector3(0.7,0.86,0.7),Vector3(cx,0.43,0.5),Color("263744"),true)
		var plane:=MeshInstance3D.new();plane.name="TableField_%d"%side
		var pm:=PlaneMesh.new();pm.size=Vector2(1.6,1.6);plane.mesh=pm;plane.material_override=mat;plane.position=Vector3(cx,0.967,0.5);add_child(plane)
		# Each column bends around the observer. It is a display surface with no collider.
		var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for x in range(32):
			var u0:float=float(x)/32.0;var u1:float=float(x+1)/32.0
			var a:Vector3=wall_point(cx,u0,0);var b:Vector3=wall_point(cx,u1,0)
			var c:Vector3=wall_point(cx,u1,1);var d:Vector3=wall_point(cx,u0,1)
			for pair in [[a,Vector2(u0,1)],[b,Vector2(u1,1)],[c,Vector2(u1,0)],[a,Vector2(u0,1)],[c,Vector2(u1,0)],[d,Vector2(u0,0)]]:
				st.set_uv(pair[1]);st.add_vertex(pair[0])
			var strip:MeshInstance3D=box("Crown_%d_%d"%[side,x],Vector3(0.14,0.055,0.08),(d+c)*0.5+Vector3.UP*0.03,Color("d5ae74"))
			strip.rotation.y=-((u0+u1)*0.5-0.5)*1.3
		st.generate_normals();var wall:=MeshInstance3D.new();wall.name="FieldWall_%d"%side;wall.mesh=st.commit();wall.material_override=mat;add_child(wall);walls.append(wall)
		var title_case:MeshInstance3D=box("TitleCase_%d"%side,Vector3(2.5,0.28,0.06),Vector3(cx,3.43,4.25),Color("122d3d"))
		(title_case.material_override as StandardMaterial3D).shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
		var label_:Label3D=label("FieldTitle_%d"%side,"A" if side==0 else "B",48)
		label_.pixel_size=0.002;label_.position=Vector3(cx,3.43,4.21);label_.rotation_degrees.y=180;add_child(label_)
		if side==0:left_title=label_
		else:right_title=label_
		var note:Label3D=label("DeskTag_%d"%side,"A" if side==0 else "B",55);note.position=Vector3(cx,0.97,-0.41);note.rotation_degrees=Vector3(-90,0,0);add_child(note)
		# W is the first unseeded address beside the square: watch exchange arrive.
		var wx:float=cx+(12.5/32.0-0.5)*1.6;var wz:float=0.5+(15.5/32.0-0.5)*1.6
		for sign_ in [-1,1]:
			box("WitnessX_%d_%d"%[side,sign_],Vector3(0.052,0.007,0.008),Vector3(wx,0.976,wz+sign_*0.025),Color("ffe49a"))
			box("WitnessZ_%d_%d"%[side,sign_],Vector3(0.008,0.007,0.052),Vector3(wx+sign_*0.025,0.976,wz),Color("ffe49a"))
	var footer:=label("ArchitectureNote","32 × 32 / SAME FIELD ON TABLE AND WALL / FIXED FLOOR",34)
	footer.position=Vector3(0,0.025,2.8);footer.rotation_degrees=Vector3(-90,0,0);add_child(footer)

func wall_point(cx:float,u:float,v:float) -> Vector3:
	var angle:float=(u-0.5)*1.3
	return Vector3(cx+sin(angle)*3.1,0.18+v*3.0,2.2+cos(angle)*2.2)

func _build_console() -> void:
	box("ControlFoot",Vector3(1.9,0.12,0.8),Vector3(-4.5,0.06,-1.7),Color("71584d"),true)
	box("ControlStem",Vector3(0.15,1.15,0.15),Vector3(-4.5,0.6,-1.7),Color("d5ae74"),true)
	console=Node3D.new();console.name="ExchangeConsole";console.position=Vector3(-4.5,1.16,-1.7);console.rotation_degrees=Vector3(-35,180,0);add_child(console)
	var rack:GDScript=load("res://commons/audio/rack_templates/RackTemplates.gd")
	var controls:Node3D=rack.create_panel("SAME BEGINNING / CHANGE ONE RELATION",[
		[{"type":"button","label":"STEP"},{"type":"button","label":"RUN"},{"type":"button","label":"REPLAY"},{"type":"button","label":"+100"}],
		[{"type":"button","label":"EXCHANGE B"},{"type":"button","label":"INJECT"},{"type":"button","label":"VIEW U/V"},{"type":"button","label":"COAT"}]],false)
	controls.scale=Vector3.ONE*2;console.add_child(controls)
	var callbacks:Array[Callable]=[step_once,toggle_run,reset,hundred,toggle_exchange,inject,change_view,toggle_coating]
	for i in range(callbacks.size()):
		var callback:Callable=callbacks[i]
		controls.find_child("Btn_%d"%i,true,false).get_node("InteractableAreaButton").button_pressed.connect(func(_b):callback.call())
	var case_:=Node3D.new();case_.name="FieldReadout";case_.position=Vector3(-4.5,1.83,-0.82);case_.rotation_degrees.y=180;add_child(case_)
	var housing:MeshInstance3D=box("ReadoutCase",Vector3(2.2,1.02,0.07),Vector3.ZERO,Color("162735"));housing.reparent(case_,false)
	(housing.material_override as StandardMaterial3D).shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	reading=label("Reading","",38);reading.pixel_size=0.0018;reading.position=Vector3(0,0,0.04);case_.add_child(reading)

func label(name_:String,words:String,font:int) -> Label3D:
	var n:=Label3D.new();n.name=name_;n.text=words;n.font_size=font;n.pixel_size=0.0014;n.outline_size=0;n.modulate=Color("ffe6c7");return n

func box(name_:String,size:Vector3,at:Vector3,colour:Color,solid:bool=false) -> MeshInstance3D:
	var n:=MeshInstance3D.new();n.name=name_;n.position=at;var mesh:=BoxMesh.new();mesh.size=size;n.mesh=mesh
	var mat:=StandardMaterial3D.new();mat.albedo_color=colour;mat.roughness=0.7;n.material_override=mat;add_child(n)
	if solid:
		var body:=StaticBody3D.new();var col:=CollisionShape3D.new();var shape:=BoxShape3D.new();shape.size=size;col.shape=shape;n.add_child(body);body.add_child(col)
	return n
