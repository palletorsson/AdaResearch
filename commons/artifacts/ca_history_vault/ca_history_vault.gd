extends Node3D
const Model=preload("res://commons/artifacts/ca_history_vault/history_model.gd")
const TITLES:Array[String]=["STRAIGHT HISTORY","SINE BEND / SAME CELLS","SINE BREATH / SAME CELLS","SINE IN THE RULE"]
var model=Model.new()
var mode:int=0
var phase:float=0
var reserve:bool=false
var layers:int=28
var form:MeshInstance3D
var collision:CollisionShape3D
var reading:Label3D
var console:Node3D
var notice:String=""
var build_usec:int=0
var guidance:Node3D

func _ready() -> void:
	_build_stage();_build_console();rebuild()

func _can_change() -> bool:
	for body in get_tree().get_nodes_in_group("player_body")+get_tree().get_nodes_in_group("em_walker"):
		if body is Node3D:
			var p:Vector3=to_local(body.global_position)
			if p.z>-0.6 and p.z<14.6 and absf(p.x)<8:
				notice="STEP OUT TO THE ENTRANCE BEFORE CHANGING FORM";refresh();return false
	notice="";return true

func select_mode(which:int) -> void:
	if not _can_change():return
	mode=which;rebuild()
func next_phase() -> void:
	if not _can_change():return
	phase=fposmod(phase+PI*0.5,TAU);rebuild()
func toggle_corridor() -> void:
	if not _can_change():return
	reserve=not reserve;rebuild()
func next_layers() -> void:
	if not _can_change():return
	layers=8 if layers==28 else 16 if layers==8 else 28;rebuild()
func replay() -> void:
	if _can_change():rebuild()

func rebuild() -> void:
	var start:int=Time.get_ticks_usec();model.generate(mode,phase,reserve)
	var geometry:ArrayMesh=model.mesh(layers);form.mesh=geometry
	collision.shape=geometry.create_trimesh_shape()
	(collision.shape as ConcavePolygonShape3D).backface_collision=true
	build_usec=Time.get_ticks_usec()-start
	for n in guidance.get_children():n.queue_free()
	# The yellow marks identify an imposed empty corridor, not an emergent route.
	if reserve:
		for g in range(layers+1):
			for sign_ in [-1,1]:
				var p:Vector3=model.warp(Vector3(sign_*1.0,0.012,g*0.5))
				var n:MeshInstance3D=box("ReservedEdge_%d_%d"%[g,sign_],Vector3(0.03,0.016,0.32),p,Color("f9cd68"));n.reparent(guidance)
	refresh()

func refresh() -> void:
	reading.text="%s\n25 × 15 SITES / %d OF 28 GENERATIONS\nZ = HISTORY / 0.5 m PER GENERATION\nPHASE %.2f / %d OCCUPIED IN FULL HISTORY\nCORRIDOR %s / %d BIRTHS OR SURVIVALS SUPPRESSED\n%s"%[TITLES[mode],layers,phase,model.occupied,"RESERVED" if reserve else "UNRESERVED",model.forced_empty,notice if not notice.is_empty() else "SEED ALREADY CONTAINS AN ARCH / FOUNDATION HELD"]

func _build_stage() -> void:
	form=MeshInstance3D.new();form.name="HistoryBoundary";var mat:=StandardMaterial3D.new();mat.vertex_color_use_as_albedo=true;mat.roughness=0.62;mat.cull_mode=BaseMaterial3D.CULL_DISABLED;form.material_override=mat;add_child(form)
	var body:=StaticBody3D.new();body.name="ActualFormCollision";collision=CollisionShape3D.new();form.add_child(body);body.add_child(collision)
	guidance=Node3D.new();guidance.name="DeclaredCorridor";add_child(guidance)
	box("StableWorkshopFloor",Vector3(20,0.2,24),Vector3(0,-0.105,6),Color("35414b"),true)
	for x in [-9.8,9.8]:box("GalleryWall",Vector3(0.16,7.0,24),Vector3(x,3.5,6),Color("d5cdc3"),true)
	box("BackWall",Vector3(20,7,0.16),Vector3(0,3.5,17.9),Color("d5cdc3"),true)
	# Fixed brass marks make generation distance legible outside each specimen.
	for g in range(0,29,4):
		for x in [-8.4,8.4]:
			box("Measure",Vector3(0.65,0.012,0.035),Vector3(x,0.015,g*0.5),Color("c8a57c"))
			var t:=label("Generation","G%d"%g,32);t.position=Vector3(x,0.025,g*0.5+0.23);t.rotation_degrees=Vector3(-90,0,0);add_child(t)
	var title:=label("EntryTitle","WALK THROUGH A RECORDED PROCESS",66);title.position=Vector3(0,6.2,0);title.rotation_degrees.y=180;add_child(title)
	title.pixel_size=0.004
	var floor_note:=label("FloorNote","X ↔ SITES      Y ↑ SITES      Z → GENERATIONS",38);floor_note.position=Vector3(0,0.02,-1.0);floor_note.rotation_degrees=Vector3(-90,0,0);add_child(floor_note)

func _build_console() -> void:
	box("ControlFoot",Vector3(2.6,0.12,0.8),Vector3(-5.6,0.06,-2.5),Color("7c645f"),true)
	box("ControlStem",Vector3(0.15,1.15,0.15),Vector3(-5.6,0.6,-2.5),Color("c8a57c"),true)
	console=Node3D.new();console.name="FormConsole";console.position=Vector3(-5.6,1.16,-2.5);console.rotation_degrees=Vector3(-35,180,0);add_child(console)
	var rack:GDScript=load("res://commons/audio/rack_templates/RackTemplates.gd")
	var panel:Node3D=rack.create_panel("WHERE DOES SINE ENTER?",[
		[{"type":"button","label":"STRAIGHT"},{"type":"button","label":"BEND"},{"type":"button","label":"BREATHE"},{"type":"button","label":"SINE RULE"}],
		[{"type":"button","label":"PHASE"},{"type":"button","label":"CORRIDOR"},{"type":"button","label":"LAYERS"},{"type":"button","label":"REPLAY"}]],false)
	panel.scale=Vector3.ONE*3.4;console.add_child(panel)
	var callbacks:Array[Callable]=[func():select_mode(0),func():select_mode(1),func():select_mode(2),func():select_mode(3),next_phase,toggle_corridor,next_layers,replay]
	for i in range(callbacks.size()):
		var callback:Callable=callbacks[i];panel.find_child("Btn_%d"%i,true,false).get_node("InteractableAreaButton").button_pressed.connect(func(_b):callback.call())
	var case_:=Node3D.new();case_.name="ReadoutCase";case_.position=Vector3(-5.6,1.94,-1.56);case_.rotation_degrees.y=180;add_child(case_)
	var housing:=box("ReadoutHousing",Vector3(3.3,1.04,0.08),Vector3.ZERO,Color("192d39"));housing.reparent(case_,false)
	(housing.material_override as StandardMaterial3D).shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	reading=label("Reading","",34);reading.pixel_size=0.0023;reading.position=Vector3(0,0,0.047);case_.add_child(reading)

func label(name_:String,words:String,font:int) -> Label3D:
	var n:=Label3D.new();n.name=name_;n.text=words;n.font_size=font;n.pixel_size=0.0014;n.outline_size=0;n.modulate=Color("ffe6c7");return n
func box(name_:String,size:Vector3,at:Vector3,colour:Color,solid:bool=false) -> MeshInstance3D:
	var n:=MeshInstance3D.new();n.name=name_;n.position=at;var mesh:=BoxMesh.new();mesh.size=size;n.mesh=mesh
	var mat:=StandardMaterial3D.new();mat.albedo_color=colour;mat.roughness=0.7;n.material_override=mat;add_child(n)
	if solid:
		var body:=StaticBody3D.new();var col:=CollisionShape3D.new();var shape:=BoxShape3D.new();shape.size=size;col.shape=shape;n.add_child(body);body.add_child(col)
	return n
