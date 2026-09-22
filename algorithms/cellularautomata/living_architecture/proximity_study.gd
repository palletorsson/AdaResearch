extends Node3D
## An embodied input and a repeatable probe share the bridge's actual update.
const WITNESS := Vector2i(2,6)
const LIMIT := 300
var work:Node3D
var running:bool=false
var elapsed:float=0.0
var ticks:int=0
var source_mode:int=0 # VISITOR, PROBE, NONE
var probe_near:bool=true
var beginning:String="FULL"
var reading:Label3D
var console:Node3D
var probe:MeshInstance3D
var source_label:Label3D
var witness_lamp:OmniLight3D
var last_step_usec:int=0
var last_distance:float=-1.0
var last_neighbors:int=0

func _ready() -> void:
	work=get_parent()
	_build_space();_build_desk();reset()

func reset() -> void:
	running=false;elapsed=0.0;ticks=0
	for coord in work.grid:work.grid[coord]=1.0 if beginning=="FULL" else 0.0
	if beginning=="CHAIN":
		work.grid[Vector2i(1,6)]=0.6
		work.grid[WITNESS]=0.495
	work._update_visuals();_refresh()

func full_reset() -> void:
	beginning="FULL";reset()

func chain() -> void:
	beginning="CHAIN";source_mode=2;reset()

func toggle_order() -> void:
	work.synchronous_updates=not work.synchronous_updates;reset()

func toggle_reverse() -> void:
	work.reverse_scan=not work.reverse_scan;reset()

func next_source() -> void:
	source_mode=(source_mode+1)%3;_refresh()

func move_probe() -> void:
	probe_near=not probe_near;source_mode=1;_refresh()

func probe_position() -> Vector3:
	return Vector3(0,0.05,3.6) if probe_near else Vector3(-3.0,0.05,3.6)

func _sample_source() -> void:
	var visitor:Node3D=work.resolve_visitor() if source_mode==0 else null
	work.has_visitor=is_instance_valid(visitor) if source_mode==0 else source_mode==1
	if source_mode==0 and work.has_visitor:work.player_position=visitor.global_position
	elif source_mode==1:work.player_position=work.to_global(probe_position())
	last_distance=work.cell_position(WITNESS).distance_to(work.to_local(work.player_position)) if work.has_visitor else -1.0
	last_neighbors=work.healthy_neighbors(WITNESS,work.grid)
	probe.position=probe_position()+Vector3(0,0.3,0)
	probe.visible=source_mode==1
	source_label.text=["VISITOR / body origin","PROBE / nominated position","NONE / recovery only"][source_mode]
	if source_mode==1:source_label.text="PROBE / " + ("NEAR" if probe_near else "FAR")
	if source_mode==0 and not work.has_visitor:source_label.text="NO VISITOR FOUND / recovery only"

func step_once() -> void:
	running=false;elapsed=0.0;_advance()

func toggle_run() -> void:
	if ticks<LIMIT:running=not running
	elapsed=0.0;_refresh()

func _advance() -> void:
	if ticks>=LIMIT:running=false;_refresh();return
	_sample_source()
	var start:int=Time.get_ticks_usec()
	work._update_simulation(0.1);ticks+=1
	if ticks>=LIMIT:running=false
	last_step_usec=Time.get_ticks_usec()-start
	_refresh()

func _process(delta:float) -> void:
	elapsed+=delta
	if elapsed<0.1:return
	elapsed=0.0
	if running:_advance()
	else:_refresh()

func _refresh() -> void:
	_sample_source()
	var h:float=work.grid[WITNESS]
	var supported:bool=h>=0.2
	witness_lamp.light_energy=0.6 if supported else 0.0
	var clock_state:String="LIMIT" if ticks==LIMIT else "RUN" if running else "HELD"
	reading.text="W (2,6) / HEALTH %.3f\nSUPPORT %s / NEIGHBOURS %d\nDIST %s / RADIUS 1.35 m\n%s / %s / %.1f s\n%s / %s" % [h,"ON" if supported else "OFF",last_neighbors,"%.2f m"%last_distance if last_distance>=0 else "--",beginning,clock_state,ticks*0.1,"SYNC" if work.synchronous_updates else "SCAN","REVERSE" if work.reverse_scan else "FORWARD"]

func readback() -> Dictionary:
	return {"ticks":ticks,"running":running,"source":source_mode,"near":probe_near,"beginning":beginning,"sync":work.synchronous_updates,"reverse":work.reverse_scan,"health":work.grid[WITNESS],"distance":last_distance,"neighbors":last_neighbors,"grid":work.grid.duplicate(),"step_usec":last_step_usec}

func _build_space() -> void:
	box("CollectingBasin",Vector3(5,0.12,10),Vector3(0,-0.66,4.5),Color("354650"),true)
	_ramp("EntryRecovery",0.9,-0.5)
	_ramp("ExitRecovery",8.1,9.5)
	for x:float in [-2.55,2.55]:box("Rim",Vector3(0.08,0.07,10),Vector3(x,-0.035,4.5),Color("bf9469"))
	# A thin fixed grid under the transparent cells lets absence remain locatable.
	for z in range(17):box("BasinLine",Vector3(3,0.01,0.015),Vector3(0,-0.587,z*0.6-0.3),Color("98745b"))
	for x in range(6):box("BasinLine",Vector3(0.015,0.01,9.6),Vector3(x*0.6-1.5,-0.587,4.5),Color("98745b"))
	# The frieze wears the same graded state, with no collision mapping.
	box("FriezeBack",Vector3(0.08,1.95,9.6),Vector3(3.1,1.45,4.5),Color("20373a"))
	for z in range(16):
		for x in range(5):
			var cell:=Vector2i(x,z)
			var panel:MeshInstance3D=box("HealthPanel_%d_%d"%[x,z],Vector3(0.1,0.29,0.53),Vector3(3.04,0.8+x*0.32,z*0.6),Color.WHITE)
			panel.material_override=work.materials[cell]
	for z:float in [-0.3,9.3]:box("FriezePost",Vector3(0.1,2.5,0.1),Vector3(3.1,1.25,z),Color("bf9469"),true)
	var caption:=label("FriezeCaption","THE SAME HEALTH / A WALL CAN WEAR IT",30)
	caption.position=Vector3(3.0,2.65,4.5);caption.rotation_degrees.y=-90;add_child(caption)
	var at:Vector3=work.cell_position(WITNESS)+Vector3(0,0.12,0)
	for sign_ in [-1,1]:
		box("WitnessEdge",Vector3(0.61,0.015,0.018),at+Vector3(0,0,sign_*0.305),Color("ffd484"))
		box("WitnessEdge",Vector3(0.018,0.015,0.61),at+Vector3(sign_*0.305,0,0),Color("ffd484"))
	var tag:=label("WitnessTag","W (2,6)",32);tag.position=at+Vector3(-0.85,0.01,0);tag.rotation_degrees=Vector3(-90,0,0);add_child(tag)
	box("SupportPost",Vector3(0.06,1.5,0.06),Vector3(-2.9,0.75,3.6),Color("bf9469"),true)
	witness_lamp=OmniLight3D.new();witness_lamp.position=Vector3(-2.9,1.5,3.6);witness_lamp.light_color=Color("ffd484");witness_lamp.omni_range=2;add_child(witness_lamp)
	var lamp:=MeshInstance3D.new();var sphere:=SphereMesh.new();sphere.radius=0.13;sphere.height=0.26;lamp.mesh=sphere;lamp.position=witness_lamp.position;add_child(lamp)
	var lm:=StandardMaterial3D.new();lm.albedo_color=Color("ffd484");lamp.material_override=lm
	probe=MeshInstance3D.new();var ball:=SphereMesh.new();ball.radius=0.16;ball.height=0.32;probe.mesh=ball
	var pm:=StandardMaterial3D.new();pm.albedo_color=Color("e6a0d3");pm.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;probe.material_override=pm;add_child(probe)
	var warning:=label("BasinNote","FIXED BASIN 0.60 m BELOW / RECOVERY RAMPS ON LEFT",27)
	warning.position=Vector3(0,0.025,-0.95);warning.rotation_degrees=Vector3(-90,0,0);add_child(warning)

func _build_desk() -> void:
	box("DeskFoot",Vector3(1.8,0.1,0.7),Vector3(-2.7,0.05,-1.6),Color("745b54"),true)
	box("DeskStem",Vector3(0.1,1.2,0.1),Vector3(-2.7,0.6,-1.6),Color("bf9469"),true)
	console=Node3D.new();console.name="ProximityConsole";console.position=Vector3(-2.7,1.18,-1.6);console.rotation_degrees=Vector3(-35,180,0);add_child(console)
	var rack:GDScript=load("res://commons/audio/rack_templates/RackTemplates.gd")
	var controls:Node3D=rack.create_panel("APPROACH / WAIT / WITHDRAW",[
		[{"type":"button","label":"STEP"},{"type":"button","label":"RUN"},{"type":"button","label":"RESTORE"},{"type":"button","label":"SOURCE"}],
		[{"type":"button","label":"NEAR/FAR"},{"type":"button","label":"CHAIN"},{"type":"button","label":"ORDER"},{"type":"button","label":"REVERSE"}]],false)
	controls.scale=Vector3.ONE*2;console.add_child(controls)
	var callbacks:Array[Callable]=[step_once,toggle_run,full_reset,next_source,move_probe,chain,toggle_order,toggle_reverse]
	for i in range(callbacks.size()):
		var callback:Callable=callbacks[i]
		controls.find_child("Btn_%d"%i,true,false).get_node("InteractableAreaButton").button_pressed.connect(func(_b):callback.call())
	var case_:Node3D=Node3D.new();case_.name="WitnessReadout";case_.position=Vector3(-2.7,1.75,-0.9);case_.rotation_degrees.y=180;add_child(case_)
	var housing:MeshInstance3D=box("ReadoutCase",Vector3(1.95,0.85,0.07),Vector3.ZERO,Color("153237"));housing.reparent(case_,false)
	(housing.material_override as StandardMaterial3D).shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	reading=label("Reading","",42);reading.pixel_size=0.0018;reading.position=Vector3(0,0.07,0.039);case_.add_child(reading)
	source_label=label("Source","",27);source_label.position=Vector3(0,-0.31,0.04);case_.add_child(source_label)

func label(name_:String,words:String,font:int) -> Label3D:
	var n:=Label3D.new();n.name=name_;n.text=words;n.font_size=font;n.pixel_size=0.0014;n.outline_size=0;n.modulate=Color("ffe6c7");return n

func box(name_:String,size:Vector3,at:Vector3,colour:Color,solid:bool=false) -> MeshInstance3D:
	var n:=MeshInstance3D.new();n.name=name_;n.position=at;var mesh:=BoxMesh.new();mesh.size=size;n.mesh=mesh
	var mat:=StandardMaterial3D.new();mat.albedo_color=colour;mat.roughness=0.7;n.material_override=mat;add_child(n)
	if solid:
		var body:=StaticBody3D.new();var col:=CollisionShape3D.new();var shape:=BoxShape3D.new();shape.size=size;col.shape=shape;n.add_child(body);body.add_child(col)
	return n

func _ramp(name_:String,inner_z:float,outer_z:float) -> void:
	var a:=Vector3(-2.5,-0.6,inner_z);var b:=Vector3(-1.55,-0.6,inner_z)
	var c:=Vector3(-1.55,0,outer_z);var d:=Vector3(-2.5,0,outer_z)
	var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var verts:Array=[a,c,b,a,d,c] if outer_z<inner_z else [a,b,c,a,c,d]
	for v in verts:st.add_vertex(v)
	st.generate_normals();var mesh:ArrayMesh=st.commit();var mat:=StandardMaterial3D.new();mat.albedo_color=Color("52666a");mat.cull_mode=BaseMaterial3D.CULL_DISABLED;mesh.surface_set_material(0,mat)
	var node:=MeshInstance3D.new();node.name=name_;node.mesh=mesh;add_child(node)
	var body:=StaticBody3D.new();var col:=CollisionShape3D.new();var shape:=ConvexPolygonShape3D.new()
	shape.points=PackedVector3Array([a,b,c,d,Vector3(a.x,-0.74,a.z),Vector3(b.x,-0.74,b.z),Vector3(c.x,-0.74,c.z),Vector3(d.x,-0.74,d.z)])
	col.shape=shape;node.add_child(body);body.add_child(col)
