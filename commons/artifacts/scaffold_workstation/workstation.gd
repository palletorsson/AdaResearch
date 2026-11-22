extends Node3D
## One evolving bench: miniature construction -> explicit full-size, walkable copy.
const Model=preload("model.gd")
const Geometry=preload("geometry.gd")
const Furniture=preload("shop_furniture.gd")
const Kit=preload("res://commons/artifacts/primitive_encounters/geometry.gd")
const Piece=preload("res://commons/artifacts/primitive_encounters/piece.gd")
const PrefabPiece=preload("prefab_piece.gd")
const ButtonScene=preload("res://commons/interactables/push_button.tscn")
const Finishes=preload("res://commons/modular/construction_materials.gd")
const PartsArc=preload("parts_arc.gd")
const Fitted=preload("fitted_geometry.gd")
const Bauhaus=preload("bauhaus_kit.gd")
const SCALE:=Model.HAND_STEP
const WORLD_UNIT:=Model.WORLD_STEP
## THE LATTICE STEP PER STATION (Palle, 2026-10-31: at Point One "the 6-ball neck to neck", then from Point Lines "a
## distance grid like now"). Records keep their half-metre addresses; only how far apart they are SHOWN changes. At
## the Points station (tier 0) neighbours half a step apart touch collar to collar - each joint's collar stands
## .085 + .006 out of its centre - so a half step is NECK of the address unit instead of .5; from the Rods station
## on the full step, where a one-metre rod needs the room. The same saved graph spreads out at the next bench.
## Geometry (joint radius, rod thickness) stays at SCALE / the output unit; only positions take lattice().
const NECK:=2*(.085+.006)
const MODEL_ORIGIN:=Vector3(-.1,1.36,.4)
const SNAP_DISTANCE:=.12
const SAVE:="user://void_scaffold_work.json"
@export_enum("Points","Rods","Surfaces","Quads") var tier:=0
@export var persist:=true
@export var prefabs_enabled:=false
var model=Model.new()
var support:Node3D
var bench:Node3D
var controls:Node3D
var output:Node3D
var drawing:Node3D
var ghost:Node3D
var sockets:Node3D
var readout:Label3D
var feedback:Label3D
var tools:Dictionary={}
var homes:Dictionary={}
## THE CURRENT TOOL (Palle, 2026-10-31: "let the element you touch be the current tool - touch the 6-ball sphere and
## you can paint 6-balls with that, and so on; add a rubber tool that can remove elements"). Touching a part on the
## arc - a hand within grab reach of it, XR Tools' highlight request - makes that kind the tool, and the BARE HAND
## then paints it: hold the hand on a lit socket for a moment and the part is added there, move to the next. The
## RUBBER on the arc is a tool the same way: hold the hand on a placed piece and it is removed. Grabbing and
## carrying stock still works as before. A timer drives the brush, so it runs whatever set_process says.
var tool_kind:=""
var brush_hand:Node3D=null
var brush_timer:Timer
var buttons:Dictionary={}
var part_defaults:Dictionary={}
var held:Node3D
var candidate:Dictionary={}
var built:Array=[]
var _ready_done:=false
var _interactive:=true
var material_phase:="monochrome"
var workshop_look:="" # "white" (config "palette"): the playground's slim fitted parts, white with dark edges
var basket:Node3D
var edit_options:Array[Dictionary]=[]
var edit_history:Array[Dictionary]=[]
var pending_records:Array=[]
var pending_revision:=false
var brush_mode:="move"
var stroke_before:Array=[]
var brush_wait:=0.0
var brush_last:=Vector3.INF
var brush_target:=""

func _ready() -> void:
	tier=int(get_meta("config_tier",tier));persist=bool(get_meta("config_persist",persist))
	prefabs_enabled=bool(get_meta("config_prefabs_enabled",prefabs_enabled))
	workshop_look=str(get_meta("config_palette",workshop_look))
	material_phase=Finishes.phase_for(self)
	# Export/test projects never read or write the visitor's construction.
	persist=persist and str(ProjectSettings.get_setting("application/config/name"))!="Ada Void Trial Test"
	for title in ["Support","Model","Controls","Output"]:
		var part:=Node3D.new();part.name=title;add_child(part)
	support=$Support;bench=$Model;controls=$Controls;output=$Output
	bench.position=MODEL_ORIGIN;output.position=Vector3(-1,2.22,-5.5)
	var bay:=Node3D.new();bay.name="Bay";output.add_child(bay)
	for x in [-1.15,2.15]:Kit.box(bay,"Limit",Vector3(x*WORLD_UNIT,-2.20,WORLD_UNIT*.5),Vector3(.025,.012,3.3*WORLD_UNIT),Color("b8b8b8"),false)
	for z in [-1.15,2.15]:Kit.box(bay,"Limit",Vector3(WORLD_UNIT*.5,-2.20,z*WORLD_UNIT),Vector3(3.3*WORLD_UNIT,.012,.025),Color("b8b8b8"),false)
	var structure:=Node3D.new();structure.name="Structure";output.add_child(structure)
	Furniture.table(support)
	# The grid belongs to Model, so curation cannot separate it from its sockets.
	# Its intersections project the integer positions, including the lower layer.
	Kit.box(bench,"ModelPad",Vector3(.1,-.25,.1),Vector3(.74,.02,.74),Color("535e68"),false)
	for i in 7:
		Kit.box(bench,"GridX",Vector3(.1,-.233,-step()+i*step()*.5),Vector3(.66,.003,.003),Color("b5c8c4"),false)
		Kit.box(bench,"GridZ",Vector3(-step()+i*step()*.5,-.233,.1),Vector3(.003,.003,.66),Color("b5c8c4"),false)
	PartsArc.build(bench,tier,prefabs_enabled)
	make_controls()
	for kind in ["point","rod_short","rod","rod_4","panel","quad","quad_4"]:
		if Model.required_tier(kind)>tier:continue
		make_tool(kind)
	if prefabs_enabled:
		for kind in ["wedge","pyramid"]:make_tool(kind)
	make_rubber()
	drawing=Node3D.new();drawing.name="Construction";bench.add_child(drawing)
	ghost=Node3D.new();ghost.name="SnapPreview";bench.add_child(ghost)
	sockets=Node3D.new();sockets.name="AvailableConnections";bench.add_child(sockets)
	brush_timer=Timer.new();brush_timer.name="BareBrush";brush_timer.wait_time=1.0/30;brush_timer.autostart=true;add_child(brush_timer)
	brush_timer.timeout.connect(func():_bare_brush(brush_timer.wait_time))
	add_to_group("scaffold_workstations")
	if persist:load_blueprint()
	_ready_done=true;redraw();remember_parts();set_process(false)

func load_blueprint() -> void:
	if not persist:return
	var raw:Array=[]
	if get_tree().root.has_meta("scaffold_blueprint"):raw=get_tree().root.get_meta("scaffold_blueprint")
	elif FileAccess.file_exists(SAVE):
		var saved=JSON.parse_string(FileAccess.get_file_as_string(SAVE))
		if saved is Dictionary and saved.get("version") in [1,2] and saved.get("records") is Array:raw=saved.records
	model.restore(raw)
	get_tree().root.set_meta("scaffold_blueprint",model.records.duplicate(true))
	if _ready_done:redraw()

func make_controls() -> void:
	# Two low console housings sit on the table, leaving the grid between them.
	var info:=Node3D.new();info.name="InfoCard";controls.add_child(info)
	info.position=Vector3(-.74,1.20,.47);info.rotation.x=deg_to_rad(-72)
	Furniture.panel_shell(controls,info,Vector2(.64,.48),true)
	Kit.box(info,"Header",Vector3.ZERO,Vector3(.64,.48,.025),Color("202d35"),false)
	Kit.box(info,"StatusStripe",Vector3(-.295,0,.015),Vector3(.012,.42,.004),Color("8aa9a5"),false)
	Kit.label(info,"ASSEMBLY UNIT",Vector3(0,.17,.016),16)
	readout=Kit.label(info,"",Vector3(0,.09,.016),12)
	feedback=Kit.label(info,"",Vector3(0,-.08,.016),13)
	feedback.width=285;feedback.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	var stage:String="04 / SOLID PREFABS" if prefabs_enabled and tier==2 else ["01 / POINTS","02 / RODS","03 / HALF FACES","05 / FULL FACES"][tier]
	Kit.label(info,stage+"   |   1:10",Vector3(0,.03,.016),12)
	for label in info.get_children():
		if label is Label3D:label.modulate=Color("deebe7")
	Furniture.control_plate(controls)
	basket=Furniture.discard_basket(controls)
	add_control("build","BUILD 1:1",0,Color("a9cbc6"),build_copy)
	add_control("undo","UNDO",2,Color("dddcd5"),undo)

func add_control(id:String,words:String,slot:int,colour:Color,action:Callable)->void:
	var plate:Node3D=controls.get_node("ControlPlate")
	var button:Node3D=Furniture.rectangular_button(ButtonScene);button.name=id.capitalize()
	# push_button.tscn faces a wall by default. Its local UP must face off the plate.
	button.rotation=Vector3.ZERO;button.position=Vector3(-.14,.022,-.21+slot*.21)
	button.released_color=colour;button.pressed.connect(action);plate.add_child(button);buttons[id]=button
	var caption:=Kit.label(plate,words,Vector3(.065,.014,button.position.z),12)
	caption.name=id.capitalize()+"Caption";caption.rotation.x=-PI/2;caption.modulate=Color("dce6e2")

func make_tool(kind:String) -> void:
	var piece:=Piece.new();piece.name=kind.capitalize()+"Stock";piece.set_meta("kind",kind)
	piece.set_meta("desktop_preserve_orientation",true)
	# These stock tools are reused after each valid or rejected drop, never freed in a hand callback.
	bench.add_child(piece);piece.position=PartsArc.address(PartsArc.ORDER.find(kind))
	var record:Dictionary={"kind":kind,"at":[0,0,0],"end":[0,1,0],"plane":[0,2],"half":0}
	if kind=="rod_short":record.end=[0,.5,0]
	if Model.MACRO_UNITS.has(kind):record.end=[0,float(Model.MACRO_UNITS[kind]),0]
	var shape:Shape3D=shape_for(record,SCALE)
	var mesh:=visual(record,SCALE,material_phase);Geometry.hologram(mesh);piece.add_child(mesh)
	var collider:=CollisionShape3D.new();collider.shape=shape;piece.add_child(collider)
	if Model.MACRO_UNITS.has(kind):   # the stock shows the whole chain at the rack's height; the ghost and the copy are full size
		var fit:float=.2/(float(Model.MACRO_UNITS[kind])*SCALE);mesh.scale=Vector3.ONE*fit;collider.shape.size=Vector3(.05,.2,.05)
	if kind=="point":
		var sphere:=SphereShape3D.new();sphere.radius=.045;collider.shape=sphere
		mesh.scale=Vector3.ONE*1.8
	if kind in ["rod","rod_short"]:
		var grip:=BoxShape3D.new();grip.size=Vector3(.05,.1 if kind=="rod_short" else .2,.05);collider.shape=grip   # a box grip in either look
	if kind in ["panel","quad","quad_4"]:
		var handle:=BoxShape3D.new();handle.size=Vector3(.19,.045,.19);collider.shape=handle
		piece.rotation.x=PI/2
		if kind=="quad_4":mesh.scale=Vector3.ONE*.5   # the 4 m plate shown at the 2 m plate's size on the rack; full size in the ghost and the copy
	# Upright rods leave room between neighbours; both lengths remain visible.
	piece.picked_up.connect(lift);piece.dropped.connect(drop)
	piece.highlight_updated.connect(func(p,on):_touched(kind,p,on))
	tools[kind]=piece;homes[kind]=piece.transform

## THE RUBBER on the arc, past its last socket: a pink block with a dark band. Touch it and the hand erases;
## grab it and hold it near a piece as before.
func make_rubber()->void:
	if tools.has("remove"):return
	var piece:=Piece.new();piece.name="RubberStock";piece.set_meta("kind","remove");piece.set_meta("desktop_preserve_orientation",true)
	bench.add_child(piece);piece.position=PartsArc.address(PartsArc.ORDER.size())+Vector3(0,.06,0)
	var mesh:=MeshInstance3D.new();var box:=BoxMesh.new();box.size=Vector3(.09,.035,.05);mesh.mesh=box;mesh.material_override=Kit.material(Color("ee8fb8"));piece.add_child(mesh)
	var band:=MeshInstance3D.new();var bb:=BoxMesh.new();bb.size=Vector3(.02,.037,.052);band.mesh=bb;band.material_override=Kit.material(Color("2b2b33"));band.position.x=-.025;mesh.add_child(band)
	var collider:=CollisionShape3D.new();var shape:=BoxShape3D.new();shape.size=Vector3(.1,.06,.07);collider.shape=shape;piece.add_child(collider)
	var caption:=Kit.label(bench,"RUBBER",piece.position+Vector3(0,.07,0),10);caption.modulate=Color("e0e9e3")
	piece.picked_up.connect(lift);piece.dropped.connect(drop)
	piece.highlight_updated.connect(func(p,on):_touched("remove",p,on))
	tools.remove=piece;homes.remove=piece.transform

## A hand came within reach of a part on the arc (XR Tools asks the pickable to highlight): that part is the tool.
func _touched(kind:String,piece:Node,on:bool)->void:
	if not on or not _interactive or get_meta("place_mode",false) or is_instance_valid(held):return
	var hands:Array=(piece.get("_highlight_requests") as Dictionary).values()
	var hand:Node3D=hands[0] if not hands.is_empty() and hands[0] is Node3D else null
	select_tool(kind,hand)

## The current tool: marked on the arc (its stock a quarter larger), its sockets lit, the bare hand painting it.
func select_tool(kind:String,hand:Node3D)->void:
	if hand!=null:brush_hand=hand
	if tool_kind==kind:return
	for k in tools:
		var stock:Node3D=tools[k];var mesh:Node3D=stock.get_child(0) if stock.get_child_count()>0 and stock.get_child(0) is Node3D else null
		if mesh==null:continue
		if not stock.has_meta("tool_scale"):stock.set_meta("tool_scale",mesh.scale)
		mesh.scale=(stock.get_meta("tool_scale") as Vector3)*(1.25 if k==kind else 1.0)
	tool_kind=kind;brush_wait=0;brush_last=Vector3.INF;brush_target="";candidate={};clear_children(ghost)
	refresh_sockets(kind)
	if kind=="remove":feedback.text="RUBBER is the tool / hold the hand on a piece to remove it. Touch a part on the arc to paint instead."
	else:feedback.text="%s is the tool / hold the hand on a light to paint it there, move to the next. Touch RUBBER to erase."%PartsArc.TITLES[PartsArc.ORDER.find(kind)]

## The nearest legal socket for a kind to a point in the world, within SNAP_DISTANCE; {} if none.
func nearest_at(kind:String,at:Vector3)->Dictionary:
	if Model.is_prefab(kind):return {}
	var best:Dictionary={};var distance:=SNAP_DISTANCE
	for r in model.candidates(kind,tier):
		var d:=at.distance_to(bench.to_global(Model.pose(r).origin*step()))
		if d<distance:distance=d;best=r
	return best

## THE BARE HAND as a brush, on the timer: with a tool chosen and nothing held, the hand's place is the brush -
## a lit socket under it for a fifth of a second adds the part (the rubber: removes the piece under it); the
## hand on the arc itself paints nothing (that is where tools are touched).
func _bare_brush(delta:float)->void:
	if tool_kind=="" or not _interactive or get_meta("place_mode",false) or pending_revision or is_instance_valid(held) or not is_instance_valid(brush_hand):return
	var at:Vector3=brush_hand.global_position
	for stock in tools.values():
		if is_instance_valid(stock) and at.distance_to(stock.global_position)<.1:return
	if tool_kind=="remove":_remove_at(at,delta);return
	var next:=nearest_at(tool_kind,at)
	if next!=candidate:
		candidate=next;brush_wait=0;clear_children(ghost)
		if not next.is_empty():
			var mesh:=visual(next,SCALE,material_phase);Geometry.hologram(mesh);ghost.add_child(mesh);mesh.transform=Model.pose(next);mesh.position*=step()
	# "moved on" is a share of the station's step: at the neck pitch the next socket is 3.6 cm away
	if candidate.is_empty() or at.distance_to(brush_last)<minf(.035,step()*.3):return
	brush_wait+=delta
	if brush_wait<.2:return
	var before:Array=model.records.duplicate(true)
	if model.add(candidate,tier):
		remember_edit(before);brush_last=at;brush_wait=0;candidate={};clear_children(ghost)
		share();redraw();refresh_sockets(tool_kind);feedback.text="PAINTED / move to the next light. UNDO takes it back; BUILD updates the copy."

func _remove_at(at:Vector3,delta:float)->void:
	var nearest_index:=-1;var distance:=minf(.075,step()*.45)   # under half a socket spacing: the piece under the hand, not its neighbour
	for i in model.records.size():
		if not can_use(model.records[i].kind):continue
		var d:float=at.distance_to(bench.to_global(Model.pose(model.records[i]).origin*step()))
		if d<distance:distance=d;nearest_index=i
	if nearest_index<0:brush_wait=0;brush_target="";clear_children(ghost);return
	var record:Dictionary=model.records[nearest_index];var target:=JSON.stringify(record)
	if target!=brush_target:
		brush_target=target;brush_wait=0;clear_children(ghost)
		var mesh:=visual(record,SCALE,material_phase);mesh.material_override=Kit.material(Color("ef7974"));ghost.add_child(mesh);mesh.transform=Model.pose(record);mesh.position*=step()
	if at.distance_to(brush_last)<minf(.035,step()*.3):return
	brush_wait+=delta
	if brush_wait<.2:return
	var result:Dictionary=model.revision(nearest_index,{})
	if not result.ok:feedback.text="Still supporting another piece. Remove its faces or rods first.";brush_wait=0;return
	var before:Array=model.records.duplicate(true);model.records.assign(result.records);remember_edit(before)
	brush_last=at;brush_wait=0;brush_target="";clear_children(ghost);share();redraw()
	feedback.text="REMOVED / move to another piece. UNDO restores it."

static func vertices(half:int,unit:float)->PackedVector3Array:return Geometry.vertices(half,unit)
## The part library this bench draws with. Default: the legacy kit, as before. With workshop_look "white" the SAME
## slim fitted parts and white-with-edges finish the playground draws with that palette (points, rods, quads fitted;
## the cell solids and triangles keep their kit geometry, whitened), so the bench, the glass box and the floor agree.
func fitted_kind(r:Dictionary)->bool:return workshop_look==Fitted.PALETTE_WHITE and str(r.get("kind","")) in ["point","rod","rod_short","quad"]
func shape_for(r:Dictionary,unit:float)->Shape3D:
	if workshop_look==Bauhaus.PALETTE_BAUHAUS:return Bauhaus.shape_for(r,unit)
	return Fitted.shape_for(r,unit) if fitted_kind(r) else Geometry.shape_for(r,unit)
func visual(r:Dictionary,unit:float,phase:String="monochrome")->MeshInstance3D:
	if workshop_look==Bauhaus.PALETTE_BAUHAUS:return Bauhaus.visual(r,unit,phase)
	if workshop_look!=Fitted.PALETTE_WHITE:return Geometry.visual(r,unit,phase)
	return Fitted.white(Fitted.visual(r,unit,phase) if fitted_kind(r) else Geometry.visual(r,unit,phase))

func lift(piece:Node3D) -> void:
	if not _interactive or get_meta("place_mode",false):return
	if is_instance_valid(held) and held!=piece:
		piece.call_deferred("drop");return
	held=piece;candidate={};stroke_before=model.records.duplicate(true);brush_wait=0;brush_last=Vector3.INF;brush_target=""
	if brush_mode=="paint" and piece.has_meta("record_index"):
		# The grabbed member becomes a temporary template; keep the original in the model.
		piece.reparent(bench,true);piece.remove_meta("record_index");piece.set_meta("brush_copy",true)
		redraw()
	refresh_sockets(str(piece.get_meta("kind")));set_process(true)
	lock_other_pieces(piece)
	if piece.get_meta("kind","")=="remove":feedback.text="Hold REMOVE near a piece. Remove faces before their supports.";return
	if piece.has_meta("record_index"):
		edit_options=model.edit_candidates(int(piece.get_meta("record_index")),tier)
		refresh_sockets(str(piece.get_meta("kind")))
		feedback.text="Move to another socket, or release in the REMOVE basket."
		return
	print("SCAFFOLD_PICKUP ",str(piece.get_meta("kind")))
	select_tool(str(piece.get_meta("kind")),null)
	feedback.text=instruction(str(piece.get_meta("kind")))

func instruction(kind:String) -> String:
	if brush_mode=="paint":return "Hold near a light to paint. Move to the next socket; release to finish the stroke."
	if Model.is_prefab(kind):return "Place on the model grid. Turn in your hand. BUILD makes a loose solid with gravity."
	if model.candidates(kind,tier).is_empty():
		if Model.is_macro_face(kind):return "No room: the 4 m plate needs a free 4 x 4 m square from a point, inside the bench."
		if Model.is_macro(kind):return "No room: the long rod needs %d m of free line from a point."%int(Model.MACRO_UNITS[kind]*2)
		return "Add two neighbouring POINTS first." if kind in ["rod","rod_short"] else "Close a square with four RODS first."
	return "Move to a light. When the solid preview appears, release grip."

func refresh_sockets(kind:String="point") -> void:
	clear_children(sockets)
	if kind=="remove":return
	# Lightweight marks reveal the targets before the hand reaches them.
	# Bound the preview count as the construction grows; nearest() still uses all.
	var available:Array[Dictionary]=edit_options if is_instance_valid(held) and held.has_meta("record_index") else model.candidates(kind,tier)
	for r in available.slice(0,64):
		var marker:=MeshInstance3D.new();var sphere:=SphereMesh.new()
		# Large clouds of targets hid the holographic model. Keep idle marks
		# smaller than the joints; the held part still gives a full-size preview.
		sphere.radius=.01 if is_instance_valid(held) or model.records.is_empty() else .004
		sphere.height=sphere.radius*2;sphere.radial_segments=8;sphere.rings=4;marker.mesh=sphere
		var material:=Kit.material(Color(.8,.8,.8,.38));material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
		material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
		marker.material_override=material;sockets.add_child(marker);marker.position=Model.pose(r).origin*step()

func nearest(piece:Node3D) -> Dictionary:
	var kind:String=str(piece.get_meta("kind"))
	if Model.is_prefab(kind):
		if not prefabs_enabled:return {}
		var local:Transform3D=bench.global_transform.affine_inverse()*piece.global_transform
		var at:Vector3=(local.origin/step()).snapped(Vector3.ONE*.5)
		if local.origin.distance_to(at*step())>.06:return {}
		var turn:Vector3=(local.basis.get_euler()/(PI*.5)).round()
		var proposed:=Model.canonical({"kind":kind,"at":Model.arr(at),"turn":Model.arr(turn)})
		var test=Model.new();test.records=model.records.duplicate(true)
		if piece.has_meta("record_index"):test.records.remove_at(int(piece.get_meta("record_index")))
		return proposed if test.prefab_fits(proposed) else {}
	var best:Dictionary={};var distance:=SNAP_DISTANCE
	var available:Array[Dictionary]=edit_options if piece.has_meta("record_index") else model.candidates(str(piece.get_meta("kind")),tier)
	for r in available:
		var pose:Transform3D=Model.pose(r);pose.origin*=step()
		var d:=piece.global_position.distance_to(bench.to_global(pose.origin))
		if d<distance:distance=d;best=r
	return best

func _process(_delta:float) -> void:
	if not is_instance_valid(held):set_process(false);return
	if pending_revision:return
	if held.get_meta("kind","")=="remove":process_remove(_delta);return
	if brush_mode=="paint" and not held.has_meta("record_index"):process_paint(_delta);return
	if in_basket(held):
		clear_children(ghost);candidate={}
		feedback.text="Release to REMOVE. UNDO brings it back." if held.has_meta("record_index") else "Release to return this stock piece."
		return
	var next:=nearest(held)
	if next==candidate:return
	candidate=next;clear_children(ghost)
	if candidate.is_empty():feedback.text="Release outside a socket to return the piece." if held.has_meta("record_index") else instruction(str(held.get_meta("kind")));return
	if held.has_meta("record_index") and not model.revision(int(held.get_meta("record_index")),candidate).ok:
		feedback.text="Remove attached rods or faces first. This connection is still needed.";return
	feedback.text="READY / release grip to connect."
	var mesh:=visual(candidate,SCALE,material_phase);var material:=Kit.material(Color(1,1,1,.6))
	material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh.material_override=material;ghost.add_child(mesh);mesh.transform=Model.pose(candidate);mesh.position*=step()

func drop(piece:Node3D) -> void:
	if held!=piece:return
	lock_other_pieces(null)
	if pending_revision:
		if not piece.has_meta("record_index"):return_stock(piece)
		held=null;finish_pending.call_deferred();return
	if piece.get_meta("kind","")=="remove" or (brush_mode=="paint" and not piece.has_meta("record_index")):
		remember_edit(stroke_before);return_stock(piece);held=null;candidate={};clear_children(ghost);refresh_sockets();set_process(false)
		feedback.text="Stroke kept. UNDO reverses the whole stroke; BUILD updates the copy."
		return
	if piece.has_meta("record_index"):
		var index:int=int(piece.get_meta("record_index"))
		var remove:=in_basket(piece);var next:Dictionary={} if remove else nearest(piece)
		var result:Dictionary=model.revision(index,next) if remove or not next.is_empty() else {"ok":false}
		var message:="Returned. Release on a socket to move, or in the basket to remove."
		if result.ok:
			var before:Array=model.records.duplicate(true);model.records.assign(result.records)
			remember_edit(before);share();message="REMOVED. UNDO restores it." if remove else "MOVED. Press BUILD to update the large copy."
		elif remove or not next.is_empty():message="Still attached. Remove its attached faces or rods first."
		held=null;candidate={};edit_options.clear();set_process(false)
		# XRTools and the desktop pointer finish their release callback before bodies disappear.
		finish_edit.call_deferred(message);return
	var next:=nearest(piece)
	var before:Array=model.records.duplicate(true)
	if _interactive and not in_basket(piece) and not next.is_empty() and model.add(next,tier):
		remember_edit(before)
		share();redraw();feedback.text="CONNECTED. Build when you want the walkable copy."
		print("SCAFFOLD_CONNECTED ",JSON.stringify(next))
	else:
		feedback.text="Stock returned. The supply stays available." if in_basket(piece) else instruction(str(piece.get_meta("kind")))
		print("SCAFFOLD_REJECTED ",str(piece.get_meta("kind")))
	return_stock(piece)
	held=null;candidate={};clear_children(ghost);refresh_sockets();set_process(false)

func return_stock(piece:Node3D)->void:
	if piece.get_meta("brush_copy",false):piece.queue_free();return
	piece.transform=homes[str(piece.get_meta("kind"))]
	PhysicsServer3D.body_set_state(piece.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,piece.global_transform)

func lock_other_pieces(active:Node3D)->void:
	var pieces:Array=tools.values()+drawing.get_children()
	for piece in pieces:
		if not piece is RigidBody3D or not piece.has_method("can_pick_up") or piece==active:continue
		piece.enabled=active==null and _interactive and not get_meta("place_mode",false);piece.collision_layer=7 if piece.enabled else 0

func in_basket(piece:Node3D)->bool:
	var p:Vector3=basket.to_local(piece.global_position)
	return absf(p.x)<.145 and absf(p.z)<.115 and p.y>.018 and p.y<.26

func finish_edit(message:String)->void:
	clear_children(ghost);redraw();feedback.text=message

func enable_brush_controls()->void:
	var strip:=Node3D.new();strip.name="BrushTools";controls.add_child(strip);strip.position=Vector3(0,1.08,1.15)
	Kit.box(strip,"Board",Vector3.ZERO,Vector3(.95,.025,.19),Color("263b45"),false)
	for i in 2:
		var mode:String=["move","paint"][i]
		var button:Node3D=Furniture.rectangular_button(ButtonScene);button.position=Vector3(-.36+i*.30,.025,0)
		button.released_color=Color("8fcacc");button.pressed.connect(func():set_brush_mode(mode));strip.add_child(button)
		var caption:=Kit.label(strip,mode.to_upper(),Vector3(-.24+i*.30,.018,0),12);caption.rotation.x=-PI/2
		caption.modulate=Color("eef6f1")
	if tools.has("remove"):return   # the arc's RUBBER is the remove tool
	var eraser:=Piece.new();eraser.name="RemoveTool";eraser.set_meta("kind","remove")
	bench.add_child(eraser);eraser.global_position=strip.to_global(Vector3(.32,.08,0))
	var mesh:=MeshInstance3D.new();var box:=BoxMesh.new();box.size=Vector3(.07,.08,.07);mesh.mesh=box;mesh.material_override=Kit.material(Color("ea7975"));eraser.add_child(mesh)
	var collider:=CollisionShape3D.new();var shape:=BoxShape3D.new();shape.size=box.size;collider.shape=shape;eraser.add_child(collider)
	eraser.picked_up.connect(lift);eraser.dropped.connect(drop);tools.remove=eraser;homes.remove=eraser.transform
	var caption:=Kit.label(strip,"REMOVE",Vector3(.32,.018,.065),12);caption.rotation.x=-PI/2
	caption.modulate=Color("eef6f1")

func set_brush_mode(value:String)->void:
	if not _interactive or get_meta("place_mode",false):return
	if is_instance_valid(held):feedback.text="Release the current tool first.";return
	brush_mode=value
	feedback.text="PAINT / grab stock or a placed piece as a template; hold near a socket." if value=="paint" else "MOVE / grab and release a piece on a legal socket."

func process_paint(delta:float)->void:
	var next:=nearest(held)
	if next!=candidate:
		candidate=next;brush_wait=0;clear_children(ghost)
		if not next.is_empty():
			var mesh:=visual(next,SCALE,material_phase);Geometry.hologram(mesh);ghost.add_child(mesh);mesh.transform=Model.pose(next);mesh.position*=step()
	if candidate.is_empty() or held.global_position.distance_to(brush_last)<.035:return
	brush_wait+=delta
	if brush_wait<.2:return
	if model.add(candidate,tier):
		brush_last=held.global_position;brush_wait=0;candidate={};clear_children(ghost)
		share();redraw();lock_other_pieces(held);feedback.text="PAINTED / move to another socket. Release to finish."

func process_remove(delta:float)->void:
	var nearest_index:=-1;var distance:=.075
	for i in model.records.size():
		if not can_use(model.records[i].kind):continue
		var at:Vector3=bench.to_global(Model.pose(model.records[i]).origin*step())
		var d:float=held.global_position.distance_to(at)
		if d<distance:distance=d;nearest_index=i
	if nearest_index<0:brush_wait=0;brush_target="";clear_children(ghost);return
	var record:Dictionary=model.records[nearest_index]
	var target:=JSON.stringify(record)
	if target!=brush_target:
		brush_target=target;brush_wait=0;clear_children(ghost)
		var mesh:=visual(record,SCALE,material_phase);mesh.material_override=Kit.material(Color("ef7974"));ghost.add_child(mesh);mesh.transform=Model.pose(record);mesh.position*=step()
	if held.global_position.distance_to(brush_last)<.035:return
	brush_wait+=delta
	if brush_wait<.25:return
	var result:Dictionary=model.revision(nearest_index)
	brush_wait=0;brush_last=held.global_position
	if not result.ok:feedback.text="Still supporting another piece. Remove its faces or rods first.";return
	model.records.assign(result.records);share();redraw();lock_other_pieces(held);clear_children(ghost)
	feedback.text="REMOVED / move to another piece. UNDO restores the stroke."

func finish_pending()->void:
	model.restore(pending_records);pending_revision=false;pending_records.clear();edit_history.clear()
	finish_edit("The shared model changed. Pick the piece up again.");set_process(false)

func remember_edit(before:Array)->void:
	if before==model.records:return
	edit_history.append({"before":before,"after":model.records.duplicate(true)})
	if edit_history.size()>32:edit_history.pop_front()

func undo() -> void:
	if not _interactive or is_instance_valid(held) or get_meta("place_mode",false):return
	if not edit_history.is_empty():
		var last:Dictionary=edit_history.back()
		if last.after==model.records:
			model.records.assign(last.before);edit_history.pop_back();share();redraw()
			feedback.text="Edit undone. Press BUILD to update the large copy.";return
		edit_history.clear()
	if not model.records.is_empty():
		var kind:String=model.records.back().kind
		if not can_use(kind):
			feedback.text="The last step uses a later tool. Undo it at the later workstation.";return
	if not model.records.is_empty():model.records.pop_back();share();redraw()
	feedback.text="Last model step undone. The built copy stays until BUILD."

func share() -> void:
	if not persist:return
	get_tree().root.set_meta("scaffold_blueprint",model.records.duplicate(true))
	var file:=FileAccess.open(SAVE,FileAccess.WRITE)
	if file:file.store_string(JSON.stringify({"version":2,"coordinate_unit_metres":2,"records":model.records},"\t"))
	get_tree().call_group("scaffold_workstations","receive",model.records,self)

func receive(records:Array,sender:Node) -> void:
	if sender==self or not persist:return
	if is_instance_valid(held):pending_records=records.duplicate(true);pending_revision=true;return
	if model.restore(records):edit_history.clear();redraw()

func visible_records() -> Array[Dictionary]:
	var result:Array[Dictionary]=[{"kind":"point","at":[0,0,0]}]
	for r in model.records:
		if not can_use(r.kind):continue
		result.append(r)
	return result

func can_use(kind:String)->bool:
	return Model.required_tier(kind)<=tier and (not Model.is_prefab(kind) or prefabs_enabled)

func geometry_records()->Array[Dictionary]:
	var records:=visible_records();var result:Array[Dictionary]=[]
	for r in records:result.append(Model.fit_record(r,records))
	return result

func redraw() -> void:
	if not _ready_done:return
	clear_children(drawing)
	var introduced:=visible_records()
	var origin:=visual(Model.fit_record({"kind":"point","at":[0,0,0]},introduced),SCALE,material_phase);Geometry.hologram(origin);drawing.add_child(origin)
	for i in model.records.size():
		var r:Dictionary=Model.fit_record(model.records[i],introduced)
		if not can_use(r.kind):continue
		var piece:=Piece.new();piece.name="Placed"+str(i);piece.set_meta("kind",r.kind);piece.set_meta("record_index",i);piece.set_meta("desktop_preserve_orientation",true)
		var mesh:=visual(r,SCALE,material_phase);Geometry.hologram(mesh);piece.add_child(mesh)
		var collider:=CollisionShape3D.new();collider.shape=shape_for(r,SCALE);piece.add_child(collider)
		piece.picked_up.connect(lift);piece.dropped.connect(drop)
		drawing.add_child(piece);piece.transform=Model.pose(r);piece.position*=step()
		piece.enabled=_interactive
	readout.text="%d POINTS / %d RODS\n%d HALVES / %d QUADS"%[model.points().size(),model.records.filter(func(r):return r.kind in ["rod","rod_short"] and tier>=1).size(),model.records.filter(func(r):return r.kind=="panel" and tier>=2).size(),model.records.filter(func(r):return r.kind=="quad" and tier>=3).size()]
	refresh_sockets()
	lock_other_pieces(held)
	feedback.text="Grip stock to add. Grip a placed piece to move. Basket to remove."

func build_copy() -> bool:
	if not _interactive or is_instance_valid(held):return false
	var unit:float=output_unit()
	var records:=geometry_records();var exclusion:Array[RID]=[]
	for body in output.find_children("*","CollisionObject3D",true,false):exclusion.append(body.get_rid())
	# Refuse blocked placements, including moving an editor output into a wall.
	for r in records:
		var query:=PhysicsShapeQueryParameters3D.new();query.shape=shape_for(r,unit);query.transform=output.global_transform*copy_pose(r)
		query.collision_mask=7;query.exclude=exclusion;query.margin=.002
		var overlaps:=get_world_3d().direct_space_state.intersect_shape(query,32)
		var bounds:AABB=query.transform*query.shape.get_debug_mesh().get_aabb()
		for hit in overlaps:
			if foundation_contact(hit.collider,bounds):continue
			set_meta("blocked_by",str(hit.collider.get_path()))
			feedback.text="Output blocked. Clear the marked bay or move Output in the editor.";return false
	# The player's body must leave the old and new output before replacing support.
	var bounds:AABB=output.global_transform*AABB(Vector3(-1.2,-1.2,-1.2)*WORLD_UNIT,Vector3(3.4,3.4,3.4)*WORLD_UNIT)
	# A receiving station can translate the graph within its output frame. Include
	# both the proposed geometry and the actual old copy before replacing support.
	for r in records:
		bounds=bounds.merge(output.global_transform*copy_pose(r)*shape_for(r,unit).get_debug_mesh().get_aabb())
	for shape:CollisionShape3D in output.find_children("*","CollisionShape3D",true,false):
		bounds=bounds.merge(shape.global_transform*shape.shape.get_debug_mesh().get_aabb())
	for body in get_tree().get_nodes_in_group("player_body"):
		if body is Node3D and bounds.has_point(body.global_position):feedback.text="Step out of the output bay before rebuilding.";return false
	var structure:Node3D=output.get_node("Structure");clear_children(structure)
	for r in records:
		var body:PhysicsBody3D=PrefabPiece.new() if Model.is_prefab(r.kind) else StaticBody3D.new()
		body.collision_layer=7 if Model.is_prefab(r.kind) else 1;body.name="Built"+str(structure.get_child_count())
		body.add_child(visual(r,unit,material_phase));var shape:=CollisionShape3D.new();shape.name="Collision";shape.shape=shape_for(r,unit);body.add_child(shape)
		structure.add_child(body);body.transform=copy_pose(r);body.set_meta("workshop_kind",r.kind)
		if Model.is_prefab(r.kind):
			body.grid=output;body.grid_offset=copy_pose(r).origin-Model.pose(r).origin*unit*lattice()
			body.unit_scale=unit/WORLD_UNIT*Model.prefab_span(r)   # a cell solid snaps to its own 1 m cells
			body.gravity_scale=unit/WORLD_UNIT
	built=visible_records().duplicate(true)
	feedback.text="BUILT / 20 cm becomes 2 m. The same connections, ten times larger."
	return true

func foundation_contact(body:Node,bounds:AABB)->bool:
	# Floor-level joints and frames seat into the slab. This narrow exception is
	# only for a registered structural floor at the bay datum, never a wall/prop.
	if not body.get_meta("void_structural_slab",false) and not body.get_meta("void_landing_pad",false):return false
	var ground:float=output.global_position.y
	if bounds.position.y<ground-.181 or bounds.end.y<ground:return false
	for shape in body.get_children():
		if shape is CollisionShape3D:
			var slab:AABB=shape.global_transform*shape.shape.get_debug_mesh().get_aabb()
			if absf(slab.end.y-ground)<.005:return true
	return false

func copy_pose(record:Dictionary) -> Transform3D:
	var pose:=Model.pose(record);pose.origin*=WORLD_UNIT*lattice();return pose

func output_unit()->float:return WORLD_UNIT

static func clear_children(node:Node) -> void:
	for child in node.get_children():child.free()

func remember_parts() -> void:
	for node:Node3D in [support,bench,controls,output]:
		part_defaults[str(node.name)]={"position":[node.position.x,node.position.y,node.position.z],"rotation":[0,0,0]}

## How much closer the lattice is shown than its addresses say: NECK/.5 at the Points station, 1 from Rods on.
func lattice() -> float:return NECK/.5 if tier==0 else 1.0

## A hand-model address unit in metres at this station (SCALE, compressed at the Points station).
func step() -> float:return SCALE*lattice()

func apply_grid_config(config:Dictionary) -> void:
	if not _ready_done:return
	for key in config.get("parts",{}):
		var node:=get_node_or_null(NodePath(key)) as Node3D
		if node==null or not part_defaults.has(key):continue
		var p:Array=config.parts[key].get("position",part_defaults[key].position);var r:Array=config.parts[key].get("rotation",[0,0,0])
		node.position=Vector3(p[0],p[1],p[2]);node.rotation_degrees=Vector3(r[0],r[1],r[2])
	# Parts are editable as groups; an isolated copied group does not spawn other furniture.
	if config.has("only_parts"):
		_interactive=["Model","Controls","Output"].all(func(key):return key in config.only_parts)
		for node:Node3D in [support,bench,controls,output]:
			if str(node.name) not in config.only_parts:node.hide();disable_collisions(node)
		if not _interactive:lock_other_pieces(null)
		set_process(false)

static func disable_collisions(node:Node) -> void:
	if node is CollisionObject3D:node.collision_layer=0;node.collision_mask=0
	for child in node.get_children():disable_collisions(child)
