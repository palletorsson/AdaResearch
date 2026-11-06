extends "workstation.gd"
## Playground proportions at quarter scale; visitors enter at quarter body size.
const Visit=preload("model_visit.gd")
const CHAMBER:=6.6
const CLEAR:=6.4
# Six-metre storeys leave 5.64m below the next slab. The tall edition uses 6.6m.
@export_range(3.0,6.6,.1) var chamber_height:=5.4
@export_range(.1,1.0,.05) var model_scale:=.25
@export_range(.1,1.0,.05) var visitor_scale:=.25
const START_POSITION:=Vector3(0,.025,2.5)
const START_CLEARANCE:=AABB(Vector3(-.45,.02,2.05),Vector3(.9,1.0,.9))
var visit:Node3D
var fitted_offset:=Vector3.ZERO
var test_ball:RigidBody3D
var test_active:=false
var test_passed:=false
var test_time:=0.0
var steady_time:=0.0
var walk_builder:Node3D
var place_controls:Node3D

func _ready()->void:
	super._ready()
	output.position=Vector3(0,0,-4.25)
	clear_children(output.get_node("Bay"))
	Furniture.glass_cube(output.get_node("Bay"),CHAMBER,chamber_height,model_scale)
	Furniture.work_area(support,output.position,CHAMBER)
	Furniture.visitor_start(output.get_node("Bay"),START_POSITION)
	var label:=Kit.label(output.get_node("Bay"),"PLAYGROUND ¼ SIZE / VISITOR ¼ SIZE",Vector3(0,.18,CHAMBER*.5+.018),30)
	label.modulate=Color("455657")
	add_control("test","DROP TEST",1,Color("b4c2c4"),start_test)
	var title:Label3D=controls.get_node("InfoCard").get_children().filter(func(n):return n is Label3D)[0]
	title.text="ASSEMBLY UNIT"
	controls.get_node("ControlPlate/BuildCaption").text="BUILD MODEL"
	visit=Visit.new();visit.name="ModelVisit";add_child(visit);visit.configure(self)
	if tier>=1:
		walk_builder=load("res://commons/artifacts/scaffold_workstation/walk_builder.gd").new()
		walk_builder.name="RandomWalk";controls.add_child(walk_builder);walk_builder.configure(self)
	if tier>=3:
		enable_brush_controls()
		place_controls=load("res://commons/artifacts/scaffold_workstation/place_controls.gd").new()
		place_controls.name="PlaceParameters";controls.add_child(place_controls);place_controls.configure(self)
	remember_parts();redraw()
	if bool(get_meta("config_space",space)):_enter_space()

func output_unit()->float:return WORLD_UNIT*model_scale

func visitor_start_pose()->Transform3D:
	return output.get_node("Bay/VisitorStart").global_transform

func visitor_start_clear()->bool:
	# Loose prefabs can move after BUILD. Do not enter inside one of them.
	var query:=PhysicsShapeQueryParameters3D.new();var shape:=BoxShape3D.new()
	shape.size=Vector3(.30,.60,.30);query.shape=shape;query.collision_mask=7
	query.transform=visitor_start_pose()*Transform3D(Basis.IDENTITY,Vector3(0,.31,0))
	return get_world_3d().direct_space_state.intersect_shape(query,1).is_empty()

func apply_grid_config(config:Dictionary)->void:
	super.apply_grid_config(config)
	if visit!=null:visit.headset.enabled=_interactive and not space   # the playground editor is walked into; no visor
	if place_controls!=null and config.get("place_spec") is Dictionary:
		place_controls.set_place(config.place_spec);place_controls.set_mode(true)

func copy_pose(record:Dictionary)->Transform3D:
	var pose:Transform3D=Model.pose(record);pose.origin=pose.origin*output_unit()*lattice()+fitted_offset;return pose

func build_copy()->bool:
	if place_controls!=null and place_controls.active:return place_controls.build_copy()
	if not _interactive or is_instance_valid(held):return false
	if visit!=null and visit.active:feedback.text="Take off the VR glasses before rebuilding.";return false
	var unit:float=output_unit()
	var bounds:=AABB();var first:=true
	for r in geometry_records():
		var pose:Transform3D=Model.pose(r);pose.origin*=unit*lattice()
		var box:AABB=pose*shape_for(r,unit).get_debug_mesh().get_aabb()
		bounds=box if first else bounds.merge(box);first=false
	if bounds.size.x>CLEAR or bounds.size.z>CLEAR or bounds.size.y>chamber_height-.65:
		feedback.text="Too large for the glass bay. Revise the model; no part will be shrunk.";return false
	if is_instance_valid(test_ball):test_ball.free()
	test_active=false;test_passed=false
	var old:Vector3=fitted_offset
	# Copy the model's metre lattice into the chamber's metre lattice. Never
	# raise fixed decks according to the decorative joint radius: loose solids
	# would settle onto a different ground plane and miss those decks.
	var introduced=Model.new();introduced.records=visible_records()
	fitted_offset=Vector3(-unit*.5,-introduced.ground_address()*unit,-unit*.5)*lattice()
	for r in geometry_records():
		var part_bounds:AABB=copy_pose(r)*shape_for(r,unit).get_debug_mesh().get_aabb()
		if START_CLEARANCE.intersects(part_bounds):
			fitted_offset=old;feedback.text="Keep the marked START pad clear for your arrival.";return false
	if not super.build_copy():fitted_offset=old;return false
	# The enclosure remains closed. The visor is the route into the model.
	feedback.text="MODEL READY / wear the visor to arrive at START. Mouse: grab, then left-click.";return true

func start_test()->void:
	if not _interactive or is_instance_valid(held):return
	if built.is_empty():feedback.text="BUILD a construction first, then drop the test ball.";return
	if is_instance_valid(test_ball):test_ball.free()
	test_ball=RigidBody3D.new();test_ball.name="TestBall";test_ball.mass=.25
	test_ball.collision_layer=1;test_ball.collision_mask=1;test_ball.contact_monitor=true;test_ball.max_contacts_reported=8
	var collision:=CollisionShape3D.new();var sphere:=SphereShape3D.new();sphere.radius=.12*model_scale;collision.shape=sphere;test_ball.add_child(collision)
	var mesh:=MeshInstance3D.new();var ball:=SphereMesh.new();ball.radius=.12*model_scale;ball.height=.24*model_scale;ball.radial_segments=20;ball.rings=10
	mesh.mesh=ball;mesh.material_override=Kit.material(Color("e3e6e0"));test_ball.add_child(mesh)
	test_ball.continuous_cd=true;test_ball.gravity_scale=model_scale
	output.add_child(test_ball);test_ball.position=Vector3(0,(chamber_height-.35)*model_scale,0)
	test_active=true;test_passed=false;test_time=0;steady_time=0;feedback.text="TEST / falling under gravity…"

func _physics_process(delta:float)->void:
	if space:_process_space()   # who stands inside the box: the editor has the hand there
	if not test_active or not is_instance_valid(test_ball):return
	test_time+=delta
	var on_build:=false;var on_base:=false
	for body in test_ball.get_colliding_bodies():
		if output.get_node("Structure").is_ancestor_of(body):on_build=true
		elif output.get_node("Bay").is_ancestor_of(body):on_base=true
	# A ground-level built panel shares the floor datum with the chamber slab.
	# Jolt may report either coplanar contact; inspect the small contact region
	# before calling that a miss. An empty frame still cannot catch the ball.
	if on_base and not on_build and test_ball.linear_velocity.length()<.25:
		var query:=PhysicsShapeQueryParameters3D.new();var contact:=SphereShape3D.new();contact.radius=.13*model_scale
		query.shape=contact;query.transform=test_ball.global_transform;query.collision_mask=1;query.exclude=[test_ball.get_rid()]
		for hit in get_world_3d().direct_space_state.intersect_shape(query,16):
			if output.get_node("Structure").is_ancestor_of(hit.collider):on_build=true
	steady_time=steady_time+delta if on_build and test_ball.linear_velocity.length()<.25 else 0
	if steady_time>.6:
		test_passed=true;test_active=false;feedback.text="CAUGHT / your construction supports the ball. Revise and test another way."
	elif (on_base and not on_build and test_time>1.6) or test_time>12:
		test_active=false;feedback.text="NOT CAUGHT / the ball reached the chamber. Change the surface and test again."

## THE PLAYGROUND EDITOR (Palle, 2026-11-06). First: "use the glass box 3d space as the editing space ... non blocking
## ... We take on the vr glasses and we enter the space as the space". Then, after playing: "The editing floor should be
## at zero ... at the point floor we can only add points ... one triangle floor we can add triangles and quad. When we
## add a quad we can start to add things on the place ... like health and danger ... in the menu we should have an
## icon for the thing we can add at that level", "a jumbotron monitor editor menu that shows the option on each screen
## in the ceiling of the glass. We click pick and can add the element ... when we enter the glass playground editor
## the hand menu disappears", "the playground editor always have a grid on".
## config `space: true` (+ `space_floor`: the Void floor, which opens the tools of commons/data/inventory/space_editor.json):
##   - the table, the arc, the plate, the hand model and the visor dock go dark; the glass box stands on the slab at full
##     scale (one address = WORLD_STEP = 2 m, a half address = 1 m, the hand's metre), its panes without colliders;
##   - the GRID is always on: a faint dot at every node of the build volume, the nodes the current tool can fill lit;
##   - the JUMBOTRON hangs from the box ceiling: four faces tilted down, the same tiles on each - one per tool, later ones
##     dark with the floor that opens them; ray + trigger on a tile picks the tool;
##   - ray + trigger into the space places the tool there (model.add, the record's own grammar); an ITEM tool (health,
##     danger ...) places onto a finished horizontal quad, one per quad; SELECT takes a piece back and makes its kind
##     the tool; the RUBBER erases;
##   - INSIDE the box the editor has the hand: the hand menu (prism, belt) is hidden and the wand routes here
##     (inventory_wand._space_editor); outside, the box is inert and the hand is the environment's.
@export var space:=false
const SPACE_SCALE:=1.0
const SPACE_PICK:=.35
const SPACE_REACH:=9.0
const SPACE_TABLE:="res://commons/data/inventory/space_editor.json"
const ItemsLib=preload("res://commons/player/inventory_items.gd")
const HandLib=preload("res://commons/player/inventory_hand.gd")
var space_floor:=20
var space_tools:Array=[]           # the table's tools, in order
var space_tool:=""                  # the current tool id: "" select, "rubber", or a table tool id
var space_sockets:Node3D
var space_grid:MultiMeshInstance3D
var space_ghost:Node3D
var space_items_root:Node3D
var space_items:Array=[]            # [{item, quad}] - things placed onto quads
var space_aimed:Dictionary={}       # the record a placement would add, or {}
var space_aimed_index:=-1           # the placed record under the aim (select / rubber), or -1
var space_aimed_item:=-1            # the placed item under the aim (select / rubber), or -1
var space_aimed_quad:Dictionary={}  # the quad an item would stand on
var space_aimed_solid:=-1          # a placed solid of the tool's kind under the aim: the trigger turns it
var space_turn:=0                  # the quarter turn new solids are laid in (the last one turned)
var space_hover_tile:=""            # the jumbotron tile under the aim
var space_notice:=""
var space_guide:Label3D
var space_ray:MeshInstance3D
var jumbotron:Node3D
var jumbo_bottom:=99.0   # the drum's lowest point and half width, in Output's frame: builds stay below it
var jumbo_half:=0.0
var tiles:Array=[]                  # [{id, node, mat, size, open}]
var player_inside:=false
var space_inside_override:=-1       # probes: -1 the player body decides, 0 / 1 forced

func _enter_space()->void:
	space=true;model_scale=SPACE_SCALE;visitor_scale=SPACE_SCALE;tier=3;prefabs_enabled=true
	space_floor=int(get_meta("config_space_floor",space_floor))
	chamber_height=clampf(float(get_meta("config_chamber_height",chamber_height)),3.0,CHAMBER)   # an ordinary storey is 5.64 m: config chamber_height 5.4 there
	var table=JSON.parse_string(FileAccess.get_file_as_string(SPACE_TABLE)) if FileAccess.file_exists(SPACE_TABLE) else null
	space_tools=(table.get("tools",[]) if table is Dictionary else [])
	# the table, the hand model, the plate and the visor dock go dark
	support.hide();disable_collisions(support)
	bench.hide();disable_collisions(bench)
	for stock in tools.values():
		if stock is RigidBody3D:stock.enabled=false;stock.collision_layer=0;stock.collision_mask=0
	for child in controls.get_children():child.hide();disable_collisions(child)
	if visit!=null and is_instance_valid(visit.headset):visit.headset.enabled=false
	if brush_timer!=null:brush_timer.stop()
	# the box on the slab, full scale, its panes a hand and a body pass through
	var bay:Node3D=output.get_node("Bay");clear_children(bay)
	Furniture.glass_cube(bay,CHAMBER,chamber_height,1.0)
	for pane in bay.find_children("GlassPane*","MeshInstance3D",false,false):
		for body in pane.find_children("*","StaticBody3D",true,false):body.free()
	var label:=Kit.label(bay,"PLAYGROUND EDITOR / WALK IN / PICK ON THE SCREENS ABOVE",Vector3(0,.18,CHAMBER*.5+.018),26)
	label.modulate=Color("455657")
	space_grid=MultiMeshInstance3D.new();space_grid.name="SpaceGrid";output.add_child(space_grid)
	space_sockets=Node3D.new();space_sockets.name="SpaceSockets";output.add_child(space_sockets)
	space_ghost=Node3D.new();space_ghost.name="SpaceGhost";output.add_child(space_ghost)
	space_items_root=Node3D.new();space_items_root.name="SpaceItems";output.add_child(space_items_root)
	space_ray=MeshInstance3D.new();space_ray.name="SpaceRay";space_ray.top_level=true;space_ray.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var rod:=CylinderMesh.new();rod.top_radius=.006;rod.bottom_radius=.006;rod.height=1.0;rod.radial_segments=6;rod.rings=1;space_ray.mesh=rod
	var rm:=StandardMaterial3D.new();rm.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;rm.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;rm.no_depth_test=true;space_ray.material_override=rm
	space_ray.visible=false;output.add_child(space_ray)
	space_guide=Label3D.new();space_guide.name="SpaceGuide";space_guide.font_size=30;space_guide.pixel_size=.0022
	space_guide.outline_size=10;space_guide.modulate=Color("17302e");space_guide.outline_modulate=Color(1,1,1,.85);space_guide.width=1000;space_guide.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	space_guide.billboard=BaseMaterial3D.BILLBOARD_FIXED_Y;space_guide.position=Vector3(0,chamber_height-2.25,0);output.add_child(space_guide)
	_build_jumbotron()
	_load_space_build()
	_load_space_items()
	add_to_group("space_editors")
	_redraw_space();_draw_grid();_refresh_space_sockets();_guide_state()

# ── the progression ─────────────────────────────────────────────────────────────────────────────────────────────

func tool_def(id:String)->Dictionary:
	for t in space_tools:
		if str(t.id)==id:return t
	return {}

func tool_open(id:String)->bool:
	if id in ["","select","rubber"]:return true
	var t:=tool_def(id)
	return not t.is_empty() and int(t.get("from_floor",0))<=space_floor

## A record kind is shown and edited here when an open tool lays it (the shared blueprint may carry later kinds).
func can_use(kind:String)->bool:
	if not space:return super.can_use(kind)
	for t in space_tools:
		if kind in t.get("kinds",[]) and int(t.get("from_floor",0))<=space_floor:return true
	return false

func tool_kinds(id:String)->Array:return tool_def(id).get("kinds",[])
func tool_item(id:String)->String:return str(tool_def(id).get("item",""))

# ── the grid and the lit nodes ──────────────────────────────────────────────────────────────────────────────────

func space_point(r:Dictionary)->Vector3:
	return Model.pose(r).origin*output_unit()*lattice()+fitted_offset

func _node_world(v:Vector3)->Vector3:return v*output_unit()+fitted_offset

func _fits_height(r:Dictionary)->bool:
	var at:Vector3=Model.vec(r.at)
	if at.y<0:return false
	if r.has("end") and Model.vec(r.end).y<0:return false
	var at_w:=space_point(r);var top:float=at_w.y+(.6 if Model.is_prefab(str(r.kind)) else .2)
	if jumbotron!=null and absf(at_w.x)<jumbo_half+.3 and absf(at_w.z)<jumbo_half+.3:return top<=jumbo_bottom-.15   # under the drum
	return top<=chamber_height-.3

## Every node of the build volume as a faint dot, whatever the tool: the grid is always on.
func _draw_grid()->void:
	var dot:=SphereMesh.new();dot.radius=.016;dot.height=.032;dot.radial_segments=6;dot.rings=3
	var mm:=MultiMesh.new();mm.transform_format=MultiMesh.TRANSFORM_3D;mm.mesh=dot
	var points:Array=[]
	for xi in 7:
		for yi in 7:
			for zi in 7:
				var v:=Vector3(-1+xi*.5,yi*.5,-1+zi*.5)
				var at:=_node_world(v)
				var under:bool=absf(at.x)<jumbo_half+.3 and absf(at.z)<jumbo_half+.3
				if at.y<=(jumbo_bottom-.15 if under else chamber_height-.3):points.append(at)
	mm.instance_count=points.size()
	for i in points.size():mm.set_instance_transform(i,Transform3D(Basis.IDENTITY,points[i]))
	space_grid.multimesh=mm
	var m:=Kit.material(Color(.25,.42,.45,.35));m.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;m.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	space_grid.material_override=m;space_grid.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func _candidates()->Array[Dictionary]:
	var out:Array[Dictionary]=[]
	if space_tool in ["","rubber"] or tool_item(space_tool)!="" or not tool_open(space_tool):return out
	for kind in tool_kinds(space_tool):
		if Model.is_prefab(kind):
			# THE CELL SOLID (2026-11-06): one 1 m cell between four balls, not a 2 m bay over four of them
			for xi in 6:
				for zi in 6:
					var c:=Model.canonical({"kind":kind,"at":Model.arr(Vector3(-1+xi*.5,0,-1+zi*.5)),"turn":[0,space_turn,0],"span":.5})
					if not c.is_empty() and model.prefab_fits(c):out.append(c)
			continue
		for r in model.candidates(kind,tier):
			if _fits_height(r):out.append(r)
	return out

## The nodes the current tool can fill, lit; for an item, the quads it can stand on.
func _refresh_space_sockets()->void:
	if space_sockets==null:return
	clear_children(space_sockets)
	var spots:Array=[]
	if tool_item(space_tool)!="" and tool_open(space_tool):
		for q in _free_quads():spots.append(space_point(q))
	else:
		for r in _candidates().slice(0,160):spots.append(space_point(r))
	for at in spots:
		var marker:=MeshInstance3D.new();var sphere:=SphereMesh.new();sphere.radius=.06;sphere.height=.12;sphere.radial_segments=10;sphere.rings=5
		marker.mesh=sphere;var m:=Kit.material(Color(1,.96,.85,.7));m.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;m.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
		marker.material_override=m;space_sockets.add_child(marker);marker.position=at

# ── the jumbotron ───────────────────────────────────────────────────────────────────────────────────────────────

const TILE:=Vector2(.40,.34)
const FACE_COLS:=5
const JUMBO_SCALE:=.75   # Palle: "the monitor should be a bit smaller"
const JUMBO_TILT:=28.0

## Four faces hung from the box ceiling, tilted down toward the visitor, the same tiles on each: SELECT, RUBBER, then
## the table's tools; a tool its floor has not opened shows dark with that floor.
func _build_jumbotron()->void:
	jumbotron=Node3D.new();jumbotron.name="Jumbotron";output.add_child(jumbotron)
	jumbotron.position=Vector3(0,chamber_height-.8,0)
	var ids:Array=["select","rubber"]
	for t in space_tools:ids.append(str(t.id))
	var rows:int=ceili(float(ids.size())/FACE_COLS)
	var face_w:float=FACE_COLS*TILE.x+.16;var face_h:float=rows*TILE.y+.22
	var hub:=MeshInstance3D.new();var hb:=BoxMesh.new();hb.size=Vector3(face_w*.6,face_h*.7,face_w*.6);hub.mesh=hb;hub.material_override=Kit.material(Color("1f2629"));jumbotron.add_child(hub)
	var stem:=MeshInstance3D.new();var sb:=BoxMesh.new();sb.size=Vector3(.08,.95,.08);stem.mesh=sb;stem.position.y=face_h*.4+.47;stem.material_override=Kit.material(Color("3a4448"));jumbotron.add_child(stem)
	jumbotron.scale=Vector3.ONE*JUMBO_SCALE
	jumbo_bottom=jumbotron.position.y-face_h*.62*JUMBO_SCALE;jumbo_half=(face_w*.5+.1)*JUMBO_SCALE
	_corner_triangles(face_w,face_h)
	tiles.clear()
	for f in 4:
		var face:=Node3D.new();face.name="Face%d"%f;jumbotron.add_child(face)
		face.rotation.y=f*PI*.5
		face.position=Vector3(0,0,face_w*.5+.04).rotated(Vector3.UP,f*PI*.5)   # the screens meet at the corners; closer in, a screen's outer tiles stood in front of its neighbour's
		face.rotate_object_local(Vector3.RIGHT,deg_to_rad(JUMBO_TILT))   # the screen faces down toward someone standing in the box
		var back:=MeshInstance3D.new();var bb:=BoxMesh.new();bb.size=Vector3(face_w,face_h,.05);back.mesh=bb;back.position.z=-.03;back.material_override=Kit.material(Color("161b1d"));face.add_child(back)
		for i in ids.size():
			var c:int=i%FACE_COLS;var r:int=floori(float(i)/FACE_COLS)
			var at:=Vector3(-face_w*.5+.08+TILE.x*(c+.5),face_h*.5-.11-TILE.y*(r+.5),0)
			tiles.append(_tile(face,str(ids[i]),at))
	_paint_tiles()

func _tile(face:Node3D,id:String,at:Vector3)->Dictionary:
	var node:=Node3D.new();node.name="Tile_"+id;face.add_child(node);node.position=at
	var plate:=MeshInstance3D.new();var pb:=BoxMesh.new();pb.size=Vector3(TILE.x-.04,TILE.y-.04,.02);plate.mesh=pb
	var mat:=StandardMaterial3D.new();mat.albedo_color=Color("2f3c41");mat.emission_enabled=true;mat.emission=Color("000000");plate.material_override=mat;node.add_child(plate)
	var open:=tool_open(id)
	var icon:=_icon(id,open);if icon!=null:node.add_child(icon);icon.position=Vector3(0,.03,.06)
	var name:String={"select":"SELECT","rubber":"RUBBER"}.get(id,str(tool_def(id).get("label",id)))
	if not open:name+="\nFLOOR %d"%int(tool_def(id).get("from_floor",0))
	var words:=Label3D.new();words.text=name;words.font_size=30;words.pixel_size=.0018;words.width=200;words.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;words.outline_size=6
	words.modulate=Color("eef7f4") if open else Color("7d8a8c");words.outline_modulate=Color("101416");words.position=Vector3(0,-TILE.y*.33,.025);node.add_child(words)
	return {"id":id,"node":node,"mat":mat,"open":open}

## A tile's icon: the record itself at icon size, or the item's own miniature; dimmed when not yet open.
func _icon(id:String,open:bool)->Node3D:
	var holder:=Node3D.new()
	var record:Dictionary={}
	match id:
		"select":record={}
		"rubber":
			var box:=MeshInstance3D.new();var bm:=BoxMesh.new();bm.size=Vector3(.14,.06,.08);box.mesh=bm;box.material_override=Kit.material(Color("ee8fb8"));holder.add_child(box);return holder
		_:
			var kinds:Array=tool_kinds(id)
			if not kinds.is_empty():
				var k:String=str(kinds[-1])
				match k:
					"point":record={"kind":"point","at":[0,0,0]}
					"rod","rod_short":record={"kind":"rod","at":[0,0,0],"end":[1,0,0]}
					"diag":record={"kind":"diag","at":[0,0,0],"end":[1,1,0]}
					"panel":record={"kind":"panel","at":[0,0,0],"plane":[0,1],"half":0}
					"quad":record={"kind":"quad","at":[0,0,0],"plane":[0,1]}
					"wedge","pyramid":record={"kind":k,"at":[0,0,0],"turn":[0,0,0]}
	if id=="select":
		var ray:=MeshInstance3D.new();var cm:=CylinderMesh.new();cm.top_radius=.012;cm.bottom_radius=.012;cm.height=.16;ray.mesh=cm;ray.rotation.z=PI*.25;ray.material_override=Kit.material(Color("f59e0b"));holder.add_child(ray)
		return holder
	if not record.is_empty():
		var mesh:=visual(record,.13,material_phase);holder.add_child(mesh);mesh.transform=Model.pose(record);mesh.position*=.13
		mesh.position-=Vector3(.065 if record.has("end") or record.kind in ["panel","quad"] else 0,.065 if record.kind in ["panel","quad","diag"] else 0,0)
		if not open:mesh.material_override=Kit.material(Color("4a5355"))
		return holder
	var item:=tool_item(id)
	if item!="":
		var it:=ItemsLib.item(item);var path:=ItemsLib.scene_for(str(it.get("token","")))
		if path!="" and ResourceLoader.exists(path):
			var n:Node=(load(path) as PackedScene).instantiate()
			if n is Node3D:
				var cfg:=ItemsLib.config_for(it,{})
				for k in cfg:n.set_meta("config_%s"%str(k),cfg[k])
				if n.has_method("apply_grid_config"):n.apply_grid_config(cfg)
				HandLib._make_inert(n);n.ready.connect(func():HandLib._make_inert(n),CONNECT_ONE_SHOT)
				var size:Array=it.get("size",[.3,.3,.3]);var side:float=maxf(maxf(float(size[0]),float(size[1])),float(size[2]))
				(n as Node3D).scale=Vector3.ONE*(.16/maxf(side,.01));holder.add_child(n);(n as Node3D).position.y=-.06
	return holder

func _paint_tiles()->void:
	for t in tiles:
		var mat:StandardMaterial3D=t.mat
		if not t.open:mat.albedo_color=Color("1c2225");mat.emission=Color.BLACK
		elif t.id==space_tool or (t.id=="select" and space_tool==""):mat.albedo_color=Color("b8741a");mat.emission=Color("f59e0b");mat.emission_energy_multiplier=.6
		elif t.id==space_hover_tile:mat.albedo_color=Color("3f5a60");mat.emission=Color("5fb3c0");mat.emission_energy_multiplier=.35
		else:mat.albedo_color=Color("4b6168");mat.emission=Color("1f3a40");mat.emission_energy_multiplier=.4

## The tile the aim passes through, or "" - tested in each tile's own frame (the faces are turned and tilted).
func _tile_under(s:Array)->String:
	var best:="";var nearest:=INF
	for t in tiles:
		var node:Node3D=t.node;var inv:=node.global_transform.affine_inverse()
		var a:Vector3=inv*(s[0] as Vector3);var b:Vector3=inv*(s[1] as Vector3)
		if absf(b.z-a.z)<.0001:continue
		var k:=(0.0-a.z)/(b.z-a.z)
		if k<0 or k>1:continue
		var p:=a+(b-a)*k
		if absf(p.x)<=TILE.x*.5 and absf(p.y)<=TILE.y*.5:
			var d:=(s[0] as Vector3).distance_to(node.global_position)
			if d<nearest:nearest=d;best=str(t.id)
	return best

# ── inside: the editor has the hand ─────────────────────────────────────────────────────────────────────────────

func _update_inside()->void:
	var inside:=false
	if space_inside_override>=0:inside=space_inside_override==1
	else:
		for body in get_tree().get_nodes_in_group("player_body"):
			if not body is Node3D:continue
			var p:Vector3=output.to_local((body as Node3D).global_position)
			if absf(p.x)<CHAMBER*.5 and absf(p.z)<CHAMBER*.5 and p.y>-.6 and p.y<chamber_height:inside=true
	if inside!=player_inside:
		player_inside=inside
		if not inside:space_hide()

## The wand asks each frame: is the hand this editor's? While the player stands inside the box.
func space_active(_hand:Node,aim:Node3D)->bool:
	return space and _interactive and aim!=null and player_inside

func space_hide()->void:
	space_aimed={};space_aimed_index=-1;space_aimed_item=-1;space_aimed_quad={}
	if space_ghost!=null:clear_children(space_ghost)
	if space_ray!=null:space_ray.visible=false
	if space_hover_tile!="":space_hover_tile="";_paint_tiles()

func _aim_segment(aim:Node3D)->Array:
	var from:Vector3=aim.global_position;return [from,from-aim.global_basis.z*SPACE_REACH]

static func _line_distance(p:Vector3,a:Vector3,b:Vector3)->float:
	var d:=b-a;var t:=clampf((p-a).dot(d)/maxf(d.length_squared(),.0001),0.0,1.0)
	return p.distance_to(a+d*t)

## Horizontal quads with nothing placed on them yet.
func _free_quads()->Array:
	var out:=[]
	for r in model.records:
		if r.kind=="quad" and r.plane==[0,2] and can_use("quad"):
			var taken:=false
			for it in space_items:
				if it.quad==r:taken=true
			if not taken:out.append(r)
	return out

## What the trigger would do now, shown before the pull: the hovered tile, the ghost of the piece, the quad lit for an
## item, or the placed piece (or item) the select / rubber would take.
func space_update(aim:Node3D,_hand:Node=null)->void:
	var s:=_aim_segment(aim)
	clear_children(space_ghost);space_aimed={};space_aimed_index=-1;space_aimed_item=-1;space_aimed_quad={};space_aimed_solid=-1
	var hover:=_tile_under(s)
	if hover!=space_hover_tile:space_hover_tile=hover;_paint_tiles()
	if hover!="":
		var t:Dictionary={}
		for x in tiles:
			if x.id==hover:t=x
		_draw_ray(s[0],(t.node as Node3D).global_position if not t.is_empty() else s[1],Color("5fb3c0"));_guide_state();return
	var target:Vector3=s[1];var colour:=Color(1,1,1,.35)
	if space_tool in ["","rubber"]:
		var best:=-1;var best_item:=-1;var distance:=SPACE_PICK
		for i in model.records.size():
			if not can_use(model.records[i].kind):continue
			var d:=_line_distance(output.to_global(space_point(model.records[i])),s[0],s[1])
			if d<distance:distance=d;best=i
		for i in space_items.size():
			var node:Node3D=space_items[i].get("node")
			if node==null:continue
			var d:=_line_distance(node.global_position+Vector3(0,.2,0),s[0],s[1])
			if d<distance:distance=d;best_item=i;best=-1
		space_aimed_index=best;space_aimed_item=best_item
		var tint:=Color("ef7974") if space_tool=="rubber" else Color("f59e0b")
		if best>=0:
			var r:Dictionary=Model.fit_record(model.records[best],visible_records())
			var mesh:=visual(r,output_unit(),material_phase);mesh.material_override=Kit.material(tint);space_ghost.add_child(mesh);mesh.transform=copy_pose(r)
			target=output.to_global(space_point(model.records[best]));colour=tint
		elif best_item>=0:
			target=(space_items[best_item].node as Node3D).global_position+Vector3(0,.2,0);colour=tint
	elif tool_item(space_tool)!="":
		var best_q:Dictionary={};var distance:=SPACE_PICK*2.5
		for q in _free_quads():
			var d:=_line_distance(output.to_global(space_point(q)),s[0],s[1])
			if d<distance:distance=d;best_q=q
		space_aimed_quad=best_q
		if not best_q.is_empty():
			target=output.to_global(space_point(best_q));colour=Color("f59e0b")
			var mark:=MeshInstance3D.new();var pm:=BoxMesh.new();pm.size=Vector3(output_unit()*.9,.03,output_unit()*.9);mark.mesh=pm
			var mm:=Kit.material(Color(1,.7,.2,.35));mm.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;mm.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;mark.material_override=mm
			space_ghost.add_child(mark);mark.position=space_point(best_q)+Vector3(0,.03,0)
	else:
		var best_c:Dictionary={};var distance:=SPACE_PICK
		for r in _candidates():
			var d:=_line_distance(output.to_global(space_point(r)),s[0],s[1])
			if d<distance:distance=d;best_c=r
		# a solid of this tool already standing under the aim: the trigger turns it a quarter
		var kinds:Array=tool_kinds(space_tool)
		for i in model.records.size():
			var placed:Dictionary=model.records[i]
			if not Model.is_prefab(str(placed.kind)) or placed.kind not in kinds:continue
			var d:=_line_distance(output.to_global(space_point(placed)+Vector3(0,.25,0)),s[0],s[1])
			if d<distance:distance=d;space_aimed_solid=i;best_c={}
		if space_aimed_solid>=0:
			var turned:Dictionary=_turned_fit(space_aimed_solid)
			target=output.to_global(space_point(model.records[space_aimed_solid])+Vector3(0,.25,0));colour=Color("5fb3c0") if not turned.is_empty() else Color("ef7974")
			if not turned.is_empty():
				var mesh:=visual(turned,output_unit(),material_phase);Geometry.hologram(mesh);space_ghost.add_child(mesh);mesh.transform=copy_pose(turned)
		space_aimed=best_c
		if not best_c.is_empty():
			var mesh:=visual(best_c,output_unit(),material_phase);Geometry.hologram(mesh);space_ghost.add_child(mesh);mesh.transform=copy_pose(best_c)
			target=output.to_global(space_point(best_c));colour=Color("f59e0b")
	if target==s[1]:
		var hit:Variant=_space_box().intersects_segment(s[1],s[0])
		if hit!=null:target=hit
	_draw_ray(s[0],target,colour);_guide_state()

func _space_box()->AABB:
	return AABB(output.global_position+Vector3(-CHAMBER*.5,0,-CHAMBER*.5),Vector3(CHAMBER,chamber_height,CHAMBER))

func _draw_ray(from:Vector3,to:Vector3,colour:Color)->void:
	if space_ray==null:return
	var length:=from.distance_to(to)
	if length<.01:space_ray.visible=false;return
	(space_ray.material_override as StandardMaterial3D).albedo_color=colour
	space_ray.global_transform=Transform3D(Basis(Quaternion(Vector3.UP,(to-from)/length))*Basis.from_scale(Vector3(1,length,1)),(from+to)*.5)
	space_ray.visible=true

## The trigger. Returns what happened: picked, placed, taken, rubber, refused.
func space_press(aim:Node3D,hand:Node=null)->String:
	space_update(aim,hand)
	space_notice=""
	if space_hover_tile!="":
		var id:=space_hover_tile
		if not tool_open(id):space_notice="%s opens on floor %d"%[str(tool_def(id).get("label",id)),int(tool_def(id).get("from_floor",0))];return "refused"
		pick_tool("" if id=="select" else id);space_notice="%s in hand"%({"select":"SELECT","rubber":"RUBBER"}.get(id,str(tool_def(id).get("label",id))));return "picked"
	if space_tool in ["","rubber"]:
		if space_aimed_item>=0:
			var it:Dictionary=space_items[space_aimed_item]
			if is_instance_valid(it.get("node")):(it.node as Node).queue_free()
			space_items.remove_at(space_aimed_item);_save_space_items();space_hide();_refresh_space_sockets()
			if space_tool=="":pick_tool(_tool_for_item(str(it.item)))
			space_notice="taken" if space_tool!="rubber" else "erased";return "taken" if space_tool!="rubber" else "rubber"
		if space_aimed_index<0:space_notice="point at a piece";return "refused"
		var taken:Dictionary=model.records[space_aimed_index]
		var result:Dictionary=model.revision(space_aimed_index,{})
		if not result.ok:space_notice="still holding another piece: take its faces or rods first";return "refused"
		var before:Array=model.records.duplicate(true);model.records.assign(result.records);remember_edit(before)
		_drop_items_off_missing_quads();space_hide();share();redraw()
		if space_tool=="":pick_tool(_tool_for_kind(str(taken.kind)));space_notice="taken: %s"%str(taken.kind).replace("_"," ");return "taken"
		space_notice="erased";return "rubber"
	if not tool_open(space_tool):space_notice="not open on this floor";return "refused"
	if tool_item(space_tool)!="":
		if space_aimed_quad.is_empty():space_notice="point at a finished quad";return "refused"
		_place_item(tool_item(space_tool),space_aimed_quad);_save_space_items();space_hide();_refresh_space_sockets()
		space_notice="placed";return "placed"
	if space_aimed_solid>=0:
		var before_turn:Array=model.records.duplicate(true)
		var turned:Dictionary=_turned_fit(space_aimed_solid)
		if turned.is_empty():space_notice="no room to turn it";return "refused"
		model.records[space_aimed_solid]=turned;space_turn=int(turned.turn[1])
		remember_edit(before_turn);space_hide();share();redraw()
		space_notice="turned";return "turned"
	if space_aimed.is_empty():space_notice="no lit node under the aim";return "refused"
	var before:Array=model.records.duplicate(true)
	if not model.add(space_aimed,tier):space_notice="refused here";return "refused"
	remember_edit(before);space_hide();share();redraw()
	space_notice="placed";return "placed"

## A solid a quarter turn further about the vertical (it stays in its own cell: a square turns into itself).
static func _turned(r:Dictionary)->Dictionary:
	var t:Dictionary=r.duplicate(true);var turn:Array=t.get("turn",[0,0,0]).duplicate()
	turn[1]=posmod(int(turn[1])+1,4);t.turn=turn;return t

## The next quarter turn of a placed solid that has room (the others stay where they are), or {}.
func _turned_fit(i:int)->Dictionary:
	var test=Model.new();test.records=model.records.duplicate(true);test.records.remove_at(i)
	var t:Dictionary=model.records[i]
	for k in 3:
		t=_turned(t)
		if test.prefab_fits(t):return t
	return {}

func space_grip()->bool:
	if not player_inside:return false
	pick_tool("");return true   # the grip lets the tool go: the hand is SELECT again

func pick_tool(id:String)->void:
	space_tool=id;_paint_tiles();_refresh_space_sockets();_guide_state()

func _tool_for_kind(kind:String)->String:
	for t in space_tools:
		if kind in t.get("kinds",[]) and tool_open(str(t.id)):return str(t.id)
	return ""

func _tool_for_item(item:String)->String:
	for t in space_tools:
		if str(t.get("item",""))==item:return str(t.id)
	return ""

# ── things on quads ─────────────────────────────────────────────────────────────────────────────────────────────

func _place_item(item:String,quad:Dictionary)->void:
	var it:=ItemsLib.item(item);var path:=ItemsLib.scene_for(str(it.get("token","")))
	if path=="" or not ResourceLoader.exists(path):return
	var n:Node=(load(path) as PackedScene).instantiate()
	if not n is Node3D:n.free();return
	var cfg:=ItemsLib.config_for(it,{})
	for k in cfg:n.set_meta("config_%s"%str(k),cfg[k])
	if n.has_method("apply_grid_config"):n.apply_grid_config(cfg)
	n.name="On_"+item;space_items_root.add_child(n);(n as Node3D).position=space_point(quad)+Vector3(0,.02,0)
	if n is RigidBody3D:(n as RigidBody3D).freeze=true
	space_items.append({"item":item,"quad":quad.duplicate(true),"node":n})

func _drop_items_off_missing_quads()->void:
	for i in range(space_items.size()-1,-1,-1):
		if not model.has_record(space_items[i].quad):
			if is_instance_valid(space_items[i].get("node")):(space_items[i].node as Node).queue_free()
			space_items.remove_at(i)
	_save_space_items()

func _space_items_path()->String:return "user://void_space_items_%d.json"%space_floor

func _save_space_items()->void:
	if not persist:return
	var rows:=[]
	for it in space_items:rows.append({"item":it.item,"quad":it.quad})
	var f:=FileAccess.open(_space_items_path(),FileAccess.WRITE)
	if f:f.store_string(JSON.stringify({"version":1,"items":rows},"\t"))

func _load_space_items()->void:
	if not persist or not FileAccess.file_exists(_space_items_path()):return
	var d=JSON.parse_string(FileAccess.get_file_as_string(_space_items_path()))
	if not d is Dictionary:return
	for row in d.get("items",[]):
		var q:=Model.canonical(row.get("quad",{}))
		if not q.is_empty() and model.has_record(q):_place_item(str(row.get("item","")),q)

# ── the construction, live ──────────────────────────────────────────────────────────────────────────────────────

func _redraw_space()->void:
	var unit:float=output_unit()
	fitted_offset=Vector3(-unit*.5,0,-unit*.5)*lattice()   # the construction stands on the box floor at zero
	var structure:Node3D=output.get_node("Structure");clear_children(structure)
	for r in geometry_records():
		var body:PhysicsBody3D=StaticBody3D.new();body.collision_layer=1;body.name="Built"+str(structure.get_child_count())
		body.add_child(visual(r,unit,material_phase));var shape:=CollisionShape3D.new();shape.name="Collision";shape.shape=shape_for(r,unit);body.add_child(shape)
		structure.add_child(body);body.transform=copy_pose(r);body.set_meta("workshop_kind",r.kind)
	built=visible_records().duplicate(true)
	for it in space_items:
		if is_instance_valid(it.get("node")):(it.node as Node3D).position=space_point(it.quad)+Vector3(0,.02,0)

## The guide: what is in hand, what the trigger does now.
func _guide_state()->void:
	if space_guide==null:return
	var now:String
	if space_hover_tile!="":now="TRIGGER: pick %s"%({"select":"SELECT","rubber":"RUBBER"}.get(space_hover_tile,str(tool_def(space_hover_tile).get("label",space_hover_tile))))+("" if tool_open(space_hover_tile) else " - opens on floor %d"%int(tool_def(space_hover_tile).get("from_floor",0)))
	elif space_tool=="":now="SELECT: point at a piece and pull to take it back. Pick a tool on the screens above."
	elif space_tool=="rubber":now="RUBBER: point at a piece and pull to erase it."
	elif tool_item(space_tool)!="":now="%s: point at a finished quad and pull. Grip: put it down."%str(tool_def(space_tool).get("label",""))
	else:now="%s: point at a lit dot and pull. Grip: put it down."%str(tool_def(space_tool).get("label",""))
	if space_guide.text!=now:space_guide.text=now

func redraw()->void:
	super.redraw()
	if space and space_sockets!=null:_redraw_space();_refresh_space_sockets()

func _process_space()->void:
	_update_inside()

## THE CORNERS (Palle: "the monitor should have black triangle corners"): where two tilted screens meet, the gap between
## their edges is closed by two black triangles - the screen frame's corner, as on an arena scoreboard.
func _corner_triangles(face_w:float,face_h:float)->void:
	var d:float=face_w*.5+.04;var s:float=sin(deg_to_rad(JUMBO_TILT));var c:float=cos(deg_to_rad(JUMBO_TILT));var hw:float=face_w*.5;var hh:float=face_h*.5
	# the corner between the +z screen's right edge and the +x screen's left edge, in the drum's frame
	var a:=Vector3(hw,-hh*c,d-hh*s);var b:=Vector3(hw,hh*c,d+hh*s)          # the +z screen's right edge, bottom and top
	var cc:=Vector3(d+hh*s,hh*c,hw);var dd:=Vector3(d-hh*s,-hh*c,hw)        # the +x screen's left edge, top and bottom
	var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for f in 4:
		var turn:=Basis(Vector3.UP,f*PI*.5)
		for v in [a,b,cc,a,cc,dd]:st.add_vertex(turn*v)
	st.generate_normals()
	var corners:=MeshInstance3D.new();corners.name="CornerTriangles";corners.mesh=st.commit()
	var m:=StandardMaterial3D.new();m.albedo_color=Color("0b0d0e");m.roughness=.6;m.cull_mode=BaseMaterial3D.CULL_DISABLED;corners.material_override=m
	jumbotron.add_child(corners)

# ── each floor its own build (Palle, 2026-11-06: "each floor its own build") ───────────────────────────────────
## The workstation shared ONE construction between every station (the root meta, user://void_scaffold_work.json, the
## scaffold_workstations group). A playground editor keeps its own per floor: user://void_space_build_<floor>.json.
## On a first visit it starts from the nearest lower floor's build, the pieces this floor allows - the playground
## grows down the tower - and from then on the two are separate.
const SPACE_FLOORS:=[1,3,5,6,7,20]
func _space_build_path(floor:int)->String:return "user://void_space_build_%d.json"%floor

func _load_space_build()->void:
	model.restore([]);edit_history.clear()
	if not persist:return
	var raw:Array=_read_build(_space_build_path(space_floor))
	if raw.is_empty() and not FileAccess.file_exists(_space_build_path(space_floor)):
		for f in range(space_floor-1,-1,-1):
			if FileAccess.file_exists(_space_build_path(f)):
				raw=_read_build(_space_build_path(f)).filter(func(r):return r is Dictionary and can_use(str(r.get("kind",""))))
				break
	var kept:=Model.new()
	for raw_r in raw:
		var r=raw_r
		if r is Dictionary and Model.is_prefab(str(r.get("kind",""))) and Model.prefab_span(r)==1.0 and r.get("at") is Array:
			# the 2 m solid of v11 becomes the cell solid that lies inside its old footprint
			var old_box:AABB=Model.prefab_box(r)
			for off:Vector3 in [Vector3(-.5,0,-.5),Vector3(0,0,-.5),Vector3(-.5,0,0),Vector3(0,0,0)]:
				var cell:Dictionary=r.duplicate(true);cell.span=.5;cell.at=Model.arr(Model.vec(r.at)+off)
				if old_box.grow(.001).encloses(Model.prefab_box(cell)):r=cell;break
		var c:=Model.canonical(r)
		if not c.is_empty() and kept.add(c,3):pass   # a piece that no longer fits (a removed support) is dropped, not the whole build
	model.restore(kept.records.duplicate(true))
	if FileAccess.file_exists(_space_build_path(space_floor)) or not model.records.is_empty():_save_space_build()

static func _read_build(path:String)->Array:
	if not FileAccess.file_exists(path):return []
	var d=JSON.parse_string(FileAccess.get_file_as_string(path))
	return d.get("records",[]) if d is Dictionary and d.get("records") is Array else []

func _save_space_build()->void:
	if not persist:return
	var f:=FileAccess.open(_space_build_path(space_floor),FileAccess.WRITE)
	if f:f.store_string(JSON.stringify({"version":1,"floor":space_floor,"records":model.records},"	"))

func share()->void:
	if space:_save_space_build();return   # this floor's build only: no shared blueprint, no other station told
	super.share()

func receive(records:Array,sender:Node)->void:
	if space:return   # another station's build is not this floor's
	super.receive(records,sender)
