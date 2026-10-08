extends Node3D
## The CA, architectural mapping and visitor body are separate, inspectable choices.
const Model=preload("res://commons/artifacts/ca_volume_lab/volume_model.gd")
const Geometry=preload("res://commons/artifacts/ca_volume_lab/volume_geometry.gd")
const SEEDS:Array[String]=["ONE CLUSTER","SCATTERED CELLS","TWO CLUSTERS"]
const VIEWS:Array[String]=["SOLID CELLS","BOUNDARY FRAME","FACETED SHELL"]
var model=Model.new()
var geometry=Geometry.new()
var view:int=0
var bend:bool=false
var cut:bool=false
var form:MeshInstance3D
var collision:CollisionShape3D
var reading:Label3D
var console:Node3D
var notice:String=""
var build_usec:int=0
signal state_changed
func _ready() -> void:
	stage();controls();model.reset()
	for i in range(6):model.step()
	rebuild()
func allowed() -> bool:
	for body in get_tree().get_nodes_in_group("player_body")+get_tree().get_nodes_in_group("em_walker"):
		if body is Node3D:
			var p:Vector3=to_local(body.global_position)
			if absf(p.x)<15 and p.z>-0.4 and p.z<26.4:notice="STEP BACK TO THE CONSOLE BEFORE CHANGING THE FORM";refresh();return false
	notice="";return true
func next_seed() -> void:
	if allowed():model.reset((model.seed_id+1)%3,model.rule,model.sine);rebuild()
func next_rule() -> void:
	if allowed():model.reset(model.seed_id,1-model.rule,model.sine);rebuild()
func advance(count:int=1) -> void:
	if not allowed():return
	for i in range(count):model.step()
	rebuild()
func select_view(value:int) -> void:
	if allowed():view=value;rebuild()
func toggle_cut() -> void:
	if allowed():cut=not cut;rebuild()
func toggle_sine() -> void:
	if allowed():model.reset(model.seed_id,model.rule,not model.sine);rebuild()
func toggle_bend() -> void:
	if allowed():bend=not bend;rebuild()
func replay() -> void:
	if not allowed():return
	var target:int=model.generation;model.reset(model.seed_id,model.rule,model.sine)
	for i in range(target):model.step()
	rebuild()
func beginning() -> void:
	if allowed():model.reset(model.seed_id,model.rule,model.sine);rebuild()
func rebuild() -> void:
	var start:int=Time.get_ticks_usec();form.mesh=geometry.build(model,view,bend,cut)
	if form.mesh:
		collision.shape=form.mesh.create_trimesh_shape();(collision.shape as ConcavePolygonShape3D).backface_collision=true;collision.disabled=false
	else:collision.disabled=true;collision.shape=null
	build_usec=Time.get_ticks_usec()-start;refresh();state_changed.emit()
func refresh() -> void:
	var report:Dictionary=model.report()
	reading.text="%s / G%d OF %d\n13 × 13 × 13 SITES / X, Y, Z ARE SPACE\nBIRTH %s / SURVIVE %s / 26 NEIGHBOURS\n%d CELLS / +%d BIRTHS / -%d DEATHS / %d COMPONENTS*\n%s / %d BARS / %d DELIBERATE APERTURES\nSINE RULE %s / BEND %s / CUT %s (%d CELLS SHOWN)\n%s"%[SEEDS[model.seed_id],model.generation,Model.LIMIT,"4" if model.rule==0 else "5","4..26" if model.rule==0 else "4..7",report.occupied,report.births,report.deaths,report.components_6,VIEWS[view],geometry.bars,geometry.apertures,"ON: ±2" if model.sine else "OFF","ON" if bend else "OFF","ON" if cut else "OFF",geometry.visible_cells,notice if not notice.is_empty() else "*FACE-CONNECTED COMPONENTS / NO RESERVED CORRIDOR"]
func stage() -> void:
	form=MeshInstance3D.new();form.name="CellularArchitecture";add_child(form)
	var mat:=StandardMaterial3D.new();mat.vertex_color_use_as_albedo=true;mat.cull_mode=BaseMaterial3D.CULL_DISABLED;mat.roughness=.55;form.material_override=mat
	var body:=StaticBody3D.new();body.name="RenderedBoundaryCollision";form.add_child(body);collision=CollisionShape3D.new();body.add_child(collision)
	box("WorkshopFloor",Vector3(40,.24,40),Vector3(0,-.06,12),Color("364852"),true)
	for x in [-19.8,19.8]:box("GalleryWall",Vector3(.2,18,40),Vector3(x,9,12),Color("c8c5c9"),true)
	box("GalleryBack",Vector3(40,18,.2),Vector3(0,9,31.9),Color("c8c5c9"),true)
	# The outline describes the computational domain, not a physical glass barrier.
	for x in [-13.0,13.0]:box("DomainEdge",Vector3(.04,.02,26),Vector3(x,.078,13),Color("e5c788"))
	for z in [0.0,26.0]:box("DomainEdge",Vector3(26,.02,.04),Vector3(0,.078,z),Color("e5c788"))
	var title:=label("A VOLUME CAN BECOME A ROOM",64);title.position=Vector3(0,7,-.5);title.rotation_degrees.y=180;title.pixel_size=.005;add_child(title)
	var floor_text:=label("X ↔ SPACE     Y ↑ SPACE     Z → SPACE\nTIME ADVANCES WITH STEP",40);floor_text.position=Vector3(0,.083,-1.2);floor_text.rotation_degrees.x=-90;floor_text.pixel_size=.003;add_child(floor_text)
func controls() -> void:
	var at:=Vector3(-7,1.14,-3)
	box("ConsoleFoot",Vector3(3,.12,1.1),Vector3(at.x,.12,at.z),Color("936875"),true)
	box("ConsoleStem",Vector3(.18,1.1,.18),Vector3(at.x,.6,at.z),Color("d985aa"),true)
	console=Node3D.new();console.name="VolumeConsole";console.position=at;console.rotation_degrees=Vector3(-35,180,0);add_child(console)
	var rack:GDScript=load("res://commons/audio/rack_templates/RackTemplates.gd")
	var panel:Node3D=rack.create_panel("WHAT BECOMES MATERIAL?",[
		[{"type":"button","label":"SEED"},{"type":"button","label":"RULE"},{"type":"button","label":"STEP"},{"type":"button","label":"+4"}],
		[{"type":"button","label":"SOLID"},{"type":"button","label":"FRAME"},{"type":"button","label":"SHELL"},{"type":"button","label":"CUT"}],
		[{"type":"button","label":"SINE"},{"type":"button","label":"BEND"},{"type":"button","label":"REPLAY"},{"type":"button","label":"FIRST"}]],false)
	panel.scale=Vector3.ONE*3.5;console.add_child(panel)
	var actions:Array[Callable]=[next_seed,next_rule,func():advance(),func():advance(4),func():select_view(0),func():select_view(1),func():select_view(2),toggle_cut,toggle_sine,toggle_bend,replay,beginning]
	for i in range(actions.size()):
		var action:Callable=actions[i];panel.find_child("Btn_%d"%i,true,false).get_node("InteractableAreaButton").button_pressed.connect(func(_b):action.call())
	var housing:=box("ReadoutHousing",Vector3(5.1,1.32,.1),Vector3(-7,2.3,-1.6),Color("142e3b"));(housing.material_override as StandardMaterial3D).shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	reading=label("",32);reading.pixel_size=.0032;reading.position=Vector3(-7,2.3,-1.66);reading.rotation_degrees.y=180;add_child(reading)
func label(words:String,font:int) -> Label3D:
	var n:=Label3D.new();n.text=words;n.font_size=font;n.pixel_size=.002;n.outline_size=0;n.modulate=Color("ffe8d5");return n
func box(name_:String,size:Vector3,at:Vector3,colour:Color,solid:bool=false) -> MeshInstance3D:
	var n:=MeshInstance3D.new();n.name=name_;n.position=at;var mesh:=BoxMesh.new();mesh.size=size;n.mesh=mesh
	var mat:=StandardMaterial3D.new();mat.albedo_color=colour;mat.roughness=.7;n.material_override=mat;add_child(n)
	if solid:
		var body:=StaticBody3D.new();var col:=CollisionShape3D.new();var shape:=BoxShape3D.new();shape.size=size;col.shape=shape;n.add_child(body);body.add_child(col)
	return n
