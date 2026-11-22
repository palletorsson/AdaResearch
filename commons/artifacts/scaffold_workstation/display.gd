extends "workstation.gd"
## Playground proportions at quarter scale; visitors enter at quarter body size.
const Visit=preload("model_visit.gd")
const StudioScript=preload("studio_workstation.gd")
const CHAMBER:=6.6
const CLEAR:=6.4
# Six-metre storeys leave 5.64m below the next slab. The tall edition uses 6.6m.
@export_range(3.0,6.6,.1) var chamber_height:=5.4
@export_range(.1,1.0,.05) var model_scale:=.25
@export_range(.1,1.0,.05) var visitor_scale:=.25
@export var studio:=false
const START_POSITION:=Vector3(0,.025,2.5)
const START_CLEARANCE:=AABB(Vector3(-.45,.02,2.05),Vector3(.9,1.0,.9))
var visit:Node3D
var studio_ctrl:Node3D
var fitted_offset:=Vector3.ZERO
var test_ball:RigidBody3D
var test_active:=false
var test_passed:=false
var test_time:=0.0
var steady_time:=0.0
var walk_builder:Node3D
var place_controls:Node3D

func _ready()->void:
	chamber_height=clampf(float(get_meta("config_chamber_height",chamber_height)),3.0,CHAMBER)
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
	if bool(get_meta("config_studio",studio)) and not bool(get_meta("config_space",space)):
		studio=true
		studio_ctrl=StudioScript.new();studio_ctrl.name="StudioWorkstation";add_child(studio_ctrl);studio_ctrl.configure(self)
	elif bool(get_meta("config_space",space)):_enter_space()

func output_unit()->float:return WORLD_UNIT*model_scale

func lattice()->float:return 1.0 if studio or space else super.lattice()

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
	output.add_child(test_ball)
	test_ball.position=Vector3(0,1.45,fitted_offset.z) if studio else Vector3(0,(chamber_height-.35)*model_scale,0)
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
## ... We take on the vr glasses and we enter the space as the space". Then: "The editing floor should be at zero ... at
## the point floor we can only add points", "the playground editor always have a grid on". Then, after playing the
## jumbotron: "the jumbotron does not work as interface ... point, wedge, triangle quad all have unique positions in the
## grid so we could just have if we point at the position and fire when the element is created ... Remove the
## jumbotron and refer the other prefab to the hand menu".
## config `space: true` (+ `space_floor`: the Void floor, which opens the kinds of commons/data/inventory/space_editor.json):
##   - the table, the arc, the plate, the hand model and the visor dock go dark; the glass box stands on the slab at full
##     scale (one address = 2 m, a half address = 1 m, the hand's metre), its panes without colliders;
##   - the GRID is always on: a faint dot at every node of the build volume, the nodes a ball can go to lit;
##   - NO TOOLS: every piece has places of its own. The ray finds the first place it meets - a free node (BALL), the
##     line between two balls (EDGE), the middle of a square closed by four edges (QUAD), the corner of two edges (a
##     TRIANGLE, which brings its own diagonal), a floor cell (a WEDGE, rising away from you) - and shows that piece's
##     ghost; the TRIGGER makes it. A placed piece the ray meets first lights red: the GRIP takes it away (when nothing
##     still stands on it). Only the kinds this floor opens are offered;
##   - THINGS come from the hand menu (health, danger, a crate, the pyramid ...), which stays up inside the box: with a
##     thing in the hand the box steps aside and the hand places it as it does anywhere (inventory_wand).
@export var space:=false
const SPACE_SCALE:=1.0
const SPACE_REACH:=9.0
const NODE_HIT:=.16       # metres: the ray meets a node this close to its centre
const EDGE_HIT:=.10       # and an edge this close to its line (its middle 70 %: the ends are the balls')
const QUAD_MIDDLE:=.25    # a closed square's middle, each way from its centre in the square's own 0-1 frame, is the quad's; the rest is its corners' triangles
const SPACE_TABLE:="res://commons/data/inventory/space_editor.json"
const KIND_WORDS:={"point":"ball","rod":"edge","rod_short":"edge","diag":"diagonal","panel":"triangle","quad":"quad","wedge":"wedge","pyramid":"pyramid"}
var space_floor:=20
var space_tools:Array=[]           # the table's rows: which kinds each floor opens
var space_sockets:Node3D
var space_grid:MultiMeshInstance3D
var space_ghost:Node3D
var space_hover:Dictionary={}      # what the ray meets first: {make: [records]} or {remove: index}, with `at` (Output's frame)
var space_notice:=""
var space_guide:Label3D
var space_ray:MeshInstance3D
var player_inside:=false
var space_inside_override:=-1       # probes: -1 the player body decides, 0 / 1 forced
var _ball_spots:Array=[]           # per edit: the free nodes a ball can go to
var _edge_spots:Array=[]           # and the edges that can be laid

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
	# Palle, 2026-11-06: "remove the block from the wall" - the service cassette and its vents at the back corners
	for n in bay.get_children():
		if String(n.name).begins_with("ServiceCassette") or String(n.name).begins_with("Vent"):n.free()
	var label:=Kit.label(bay,"PLAYGROUND EDITOR / WALK IN / POINT AT A PLACE AND PULL / GRIP TAKES AWAY",Vector3(0,.18,CHAMBER*.5+.018),26)
	label.modulate=Color("455657")
	space_grid=MultiMeshInstance3D.new();space_grid.name="SpaceGrid";output.add_child(space_grid)
	space_sockets=Node3D.new();space_sockets.name="SpaceSockets";output.add_child(space_sockets)
	space_ghost=Node3D.new();space_ghost.name="SpaceGhost";output.add_child(space_ghost)
	space_ray=MeshInstance3D.new();space_ray.name="SpaceRay";space_ray.top_level=true;space_ray.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var rod:=CylinderMesh.new();rod.top_radius=.006;rod.bottom_radius=.006;rod.height=1.0;rod.radial_segments=6;rod.rings=1;space_ray.mesh=rod
	var rm:=StandardMaterial3D.new();rm.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;rm.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;rm.no_depth_test=true;space_ray.material_override=rm
	space_ray.visible=false;output.add_child(space_ray)
	space_guide=Label3D.new();space_guide.name="SpaceGuide";space_guide.font_size=30;space_guide.pixel_size=.0022
	space_guide.outline_size=10;space_guide.modulate=Color("17302e");space_guide.outline_modulate=Color(1,1,1,.85);space_guide.width=1000;space_guide.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	space_guide.billboard=BaseMaterial3D.BILLBOARD_FIXED_Y;space_guide.position=Vector3(0,chamber_height-.7,0);output.add_child(space_guide)
	_load_space_build()
	add_to_group("space_editors")
	_redraw_space();_draw_grid();_refresh_space_sockets();_guide_state()

# ── the progression ─────────────────────────────────────────────────────────────────────────────────────────────

## A record kind is offered, shown and edited here when a row of the table this floor has reached lays it.
func can_use(kind:String)->bool:
	if not space:return super.can_use(kind)
	for t in space_tools:
		if kind in t.get("kinds",[]) and int(t.get("from_floor",0))<=space_floor:return true
	return false

## The names of what this floor builds in the box (rows marked `hand` come from the hand menu instead).
func open_labels()->Array:
	var out:=[]
	for t in space_tools:
		if int(t.get("from_floor",0))<=space_floor and not bool(t.get("hand",false)):out.append(str(t.get("label",t.get("id",""))))
	return out

# ── the grid and the lit nodes ──────────────────────────────────────────────────────────────────────────────────

func space_point(r:Dictionary)->Vector3:
	return Model.pose(r).origin*output_unit()*lattice()+fitted_offset

func _node_world(v:Vector3)->Vector3:return v*output_unit()+fitted_offset

## Output's frame -> addresses (the inverse of _node_world).
func _address(local:Vector3)->Vector3:return (local-fitted_offset)/output_unit()

func _fits_height(r:Dictionary)->bool:
	var at:Vector3=Model.vec(r.at)
	if at.y<0:return false
	if r.has("end") and Model.vec(r.end).y<0:return false
	return space_point(r).y+(1.1 if Model.is_prefab(str(r.kind)) else .2)<=chamber_height-.3

## Every node of the build volume as a faint dot: the grid is always on.
func _draw_grid()->void:
	var dot:=SphereMesh.new();dot.radius=.016;dot.height=.032;dot.radial_segments=6;dot.rings=3
	var mm:=MultiMesh.new();mm.transform_format=MultiMesh.TRANSFORM_3D;mm.mesh=dot
	var points:Array=[]
	for xi in 7:
		for yi in 7:
			for zi in 7:
				var at:=_node_world(Vector3(-1+xi*.5,yi*.5,-1+zi*.5))
				if at.y<=chamber_height-.3:points.append(at)
	mm.instance_count=points.size()
	for i in points.size():mm.set_instance_transform(i,Transform3D(Basis.IDENTITY,points[i]))
	space_grid.multimesh=mm
	var m:=Kit.material(Color(.25,.42,.45,.35));m.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;m.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	space_grid.material_override=m;space_grid.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

## After every edit: where a ball and an edge can go now, and the free nodes lit.
func _refresh_space_sockets()->void:
	_ball_spots=[];_edge_spots=[]
	if not space:return
	if can_use("point"):
		for r in model.candidates("point",tier):
			if _fits_height(r):_ball_spots.append(r)
	for k in ["rod_short","rod"]:
		if can_use(k):
			for r in model.candidates(k,tier):
				if _fits_height(r):_edge_spots.append(r)
	if space_sockets==null:return
	clear_children(space_sockets)
	for r in _ball_spots.slice(0,200):
		var marker:=MeshInstance3D.new();var sphere:=SphereMesh.new();sphere.radius=.035;sphere.height=.07;sphere.radial_segments=10;sphere.rings=5
		marker.mesh=sphere;var m:=Kit.material(Color(1,.9,.6,.4));m.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;m.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
		marker.material_override=m;space_sockets.add_child(marker);marker.position=_node_world(Model.vec(r.at))+Vector3(0,.05,0)   # lifted: a floor node's dot is not buried in the floor

# ── inside: the editor has the empty hand ───────────────────────────────────────────────────────────────────────

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

## The wand asks each frame: is the hand this editor's? While the player stands inside the box with nothing in the
## hand - a thing chosen on the hand menu is the hand's to place, as anywhere.
func space_active(hand:Node,aim:Node3D)->bool:
	if studio_ctrl!=null:return studio_ctrl.studio_active(hand,aim)
	if not (space and _interactive and aim!=null and player_inside):return false
	if hand==null:return true
	var holding=hand.get("current")
	return holding==null or str(holding)==""

func space_hide()->void:
	if studio_ctrl!=null:studio_ctrl.studio_hide();return
	space_hover={}
	if space_ghost!=null:clear_children(space_ghost)
	if space_ray!=null:space_ray.visible=false

# ── what the ray meets ──────────────────────────────────────────────────────────────────────────────────────────

## The aim as a segment in Output's frame: [from, unit direction, length].
func _aim_local(aim:Node3D)->Array:
	var a:=output.to_local(aim.global_position);var b:=output.to_local(aim.global_position-aim.global_basis.z*SPACE_REACH)
	var length:=a.distance_to(b);return [a,(b-a)/maxf(length,.0001),length]

## Distance along the ray to its closest approach to `c`, if that is within `r`; else INF.
static func _ray_sphere(a:Vector3,d:Vector3,length:float,c:Vector3,r:float)->float:
	var s:=clampf((c-a).dot(d),0.0,length)
	return s if (a+d*s).distance_to(c)<=r else INF

## Distance along the ray to where it passes within `r` of the segment p-q (its middle part only), else INF.
static func _ray_segment(a:Vector3,d:Vector3,length:float,p:Vector3,q:Vector3,r:float,ends:=.15)->float:
	var u:=q-p;var w:=a-p;var b:=d.dot(u);var c:=u.dot(u);var dd:=d.dot(w);var e:=u.dot(w)
	var den:=c-b*b
	if c<.000001 or absf(den)<.000001:return INF   # parallel to the ray: it is met at a ball, not along its length
	var t:=clampf((e-b*dd)/den,0.0,1.0)
	var s:=clampf((p+u*t-a).dot(d),0.0,length)
	if t<ends or t>1.0-ends:return INF
	return s if (a+d*s).distance_to(p+u*t)<=r else INF

## Where the ray crosses the square at P0 spanned by U and V: [distance, x, y] (x, y in the square's 0-1 frame), or [].
static func _ray_square(a:Vector3,d:Vector3,length:float,p0:Vector3,u:Vector3,v:Vector3)->Array:
	var n:=u.cross(v);var den:=n.dot(d)
	if absf(den)<.000001:return []
	var s:=n.dot(p0-a)/den
	if s<0 or s>length:return []
	var h:=a+d*s-p0;var x:=h.dot(u)/u.length_squared();var y:=h.dot(v)/v.length_squared()
	if x<0 or x>1 or y<0 or y>1:return []
	return [s,x,y]

## A half face's region in its square's 0-1 frame (geometry.gd's four corner sets).
static func _in_half(half:int,x:float,y:float)->bool:
	match half:
		0:return x>=y
		1:return y>=x
		2:return x+y<=1.0
		3:return x+y>=1.0
	return false

## The first thing the ray meets: a placed piece (to take away) or the place of a new one (to make).
func _space_hover(aim:Node3D)->Dictionary:
	var seg:=_aim_local(aim);var a:Vector3=seg[0];var d:Vector3=seg[1];var length:float=seg[2]
	var unit:float=output_unit()
	var best:={"s":INF,"what":{}}   # a lambda captures a float by value: the running best lives in a dictionary
	# ties go to the placed piece, then a face, an edge, a ball, a wedge: the more deliberate place first
	var consider:=func(s:float,bias:float,what:Dictionary)->void:
		if s<INF and s+bias<float(best.s):best.s=s+bias;what.at=a+d*s;best.what=what
	# the placed pieces
	for i in model.records.size():
		var r:Dictionary=model.records[i];var kind:String=str(r.kind)
		if not can_use(kind):continue
		var s:=INF
		if kind=="point":s=_ray_sphere(a,d,length,_node_world(Model.vec(r.at)),NODE_HIT)
		elif kind in ["rod","rod_short","diag"]:s=_ray_segment(a,d,length,_node_world(Model.vec(r.at)),_node_world(Model.vec(r.end)),EDGE_HIT,.1)
		elif kind in ["quad","panel"]:
			var span:float=float(r.get("span",1))
			var hit:=_ray_square(a,d,length,_node_world(Model.vec(r.at)),Vector3(Model.AXES[r.plane[0]])*span*unit,Vector3(Model.AXES[r.plane[1]])*span*unit)
			if not hit.is_empty() and (kind=="quad" or _in_half(int(r.half),hit[1],hit[2])):s=hit[0]
		elif Model.is_prefab(kind):
			var box:AABB=Model.prefab_box(r);var local:=AABB(box.position*unit+fitted_offset,box.size*unit)
			var hit_at:Variant=local.intersects_segment(a,a+d*length)
			if hit_at!=null:s=a.distance_to(hit_at)
		consider.call(s,0.0,{"remove":i})
	# the new pieces: balls, edges
	for r in _ball_spots:consider.call(_ray_sphere(a,d,length,_node_world(Model.vec(r.at)),NODE_HIT),.04,{"make":[r]})
	for r in _edge_spots:consider.call(_ray_segment(a,d,length,_node_world(Model.vec(r.at)),_node_world(Model.vec(r.end)),EDGE_HIT),.02 if r.kind=="rod_short" else .03,{"make":[r]})
	# faces: the squares the ray crosses, in each of the three orientations, at every level
	if can_use("quad") or can_use("panel"):
		var A:=_address(a);var B:=_address(a+d*length)
		for plane:Array in [[0,1],[0,2],[1,2]]:
			var n:int=3-plane[0]-plane[1];var iu:int=plane[0];var iv:int=plane[1]
			if absf(B[n]-A[n])<.000001:continue
			for li in 7:
				var level:=-1.0+li*.5
				var k:=(level-A[n])/(B[n]-A[n])
				if k<0 or k>1:continue
				var h:=A+(B-A)*k
				for span:float in [.5,1.0]:
					var starts_u:=[floorf(h[iu]/span)*span];var starts_v:=[floorf(h[iv]/span)*span]
					if span==1.0:starts_u.append(floorf((h[iu]-.5)/span)*span+.5);starts_v.append(floorf((h[iv]-.5)/span)*span+.5)
					for su:float in starts_u:
						for sv:float in starts_v:
							var p:=Vector3.ZERO;p[n]=level;p[iu]=su;p[iv]=sv
							var made:=_face_piece(p,plane,span,(h[iu]-su)/span,(h[iv]-sv)/span)
							if not made.is_empty():consider.call(k*length,0.001 if span==1.0 else 0.0,{"make":made})
	# a wedge on the floor: the cell the ray meets, rising away from the hand
	if can_use("wedge"):
		var A:=_address(a);var B:=_address(a+d*length)
		if B.y<A.y and A.y>0:
			var k:=A.y/(A.y-B.y)
			if k<=1:
				var h:=A+(B-A)*k;var cell:=Vector3(floorf(h.x/.5)*.5,0,floorf(h.z/.5)*.5)
				var dir:=B-A;var turn:=(1 if dir.x>0 else 3) if absf(dir.x)>absf(dir.z) else (0 if dir.z>0 else 2)
				var w:=Model.canonical({"kind":"wedge","at":Model.arr(cell),"turn":[0,turn,0],"span":.5})
				if not w.is_empty() and model.prefab_fits(w) and _fits_height(w):consider.call(k*length,.06,{"make":[w]})
	return best.what

## The piece a square makes where the ray crosses it at (x, y): a QUAD in the middle of a square closed by four edges;
## else a TRIANGLE - on a diagonal's side when the square has one, or at the corner of two edges nearest the hit,
## bringing its own diagonal. [] when nothing can go there.
func _face_piece(p:Vector3,plane:Array,span:float,x:float,y:float)->Array:
	if not Model.inside(p):return []
	var u:=Vector3(Model.AXES[plane[0]])*span;var v:=Vector3(Model.AXES[plane[1]])*span
	var e_u0:bool=model.edge(p,p+u);var e_v0:bool=model.edge(p,p+v);var e_u1:bool=model.edge(p+v,p+u+v);var e_v1:bool=model.edge(p+u,p+u+v)
	if int(e_u0)+int(e_v0)+int(e_u1)+int(e_v1)<2:return []
	var at:=Model.arr(p);var base:={"at":at,"plane":[int(plane[0]),int(plane[1])]}
	if span!=1.0:base.span=span
	if p.y<0 or (p+u+v).y<0:return []
	var d0:bool=model.diag_exists(p,p+u+v);var d1:bool=model.diag_exists(p+u,p+v)
	var square:=e_u0 and e_v0 and e_u1 and e_v1
	var middle:=absf(x-.5)<QUAD_MIDDLE and absf(y-.5)<QUAD_MIDDLE
	if square and not d0 and not d1 and can_use("quad") and (middle or not can_use("panel")):
		if model.face_occupied(at,base.plane,-1,span):return []
		var q:Dictionary=base.duplicate(true);q.kind="quad";return [q]
	if not can_use("panel"):return []
	var half:=-1;var needs:={}
	if d0:
		half=0 if x>=y else 1
		if not model.triangle_edges(p,u,v,half):return []
	elif d1:
		half=2 if x+y<=1.0 else 3
		if not model.triangle_edges(p,u,v,half):return []
	else:
		var nearest:=INF
		for c:Array in [[2,e_u0 and e_v0,Vector2(0,0)],[0,e_u0 and e_v1,Vector2(1,0)],[1,e_v0 and e_u1,Vector2(0,1)],[3,e_v1 and e_u1,Vector2(1,1)]]:
			if not c[1] or not _in_half(c[0],x,y):continue
			var dist:float=Vector2(x,y).distance_to(c[2])
			if dist<nearest:nearest=dist;half=c[0]
		if half<0:return []
		needs={"kind":"diag","at":Model.arr(p if half<2 else p+u),"end":Model.arr(p+u+v if half<2 else p+v)}
	if model.face_occupied(at,base.plane,half,span):return []
	var tri:Dictionary=base.duplicate(true);tri.kind="panel";tri.half=half
	return [tri] if needs.is_empty() else [needs,tri]

## What the trigger would do now, shown before the pull: the ghost of the piece it makes, or the placed piece the
## grip would take away, in red.
func space_update(aim:Node3D,_hand:Node=null)->void:
	if studio_ctrl!=null:studio_ctrl.studio_update(aim,_hand);return
	clear_children(space_ghost)
	space_hover=_space_hover(aim)
	var colour:=Color(1,1,1,.35);var target:Vector3=output.to_local(aim.global_position-aim.global_basis.z*SPACE_REACH)
	if space_hover.has("make"):
		for r:Dictionary in space_hover.make:
			var mesh:=visual(r,output_unit(),material_phase);Geometry.hologram(mesh);space_ghost.add_child(mesh);mesh.transform=copy_pose(r)
			# amber like the ray (the pale hologram vanished against the pale floor); a horizontal face lifted clear of the floor it lies in
			var glow:StandardMaterial3D=mesh.material_override;glow.albedo_color=Color(.96,.62,.04,.55);glow.emission=Color("f59e0b");glow.emission_energy_multiplier=.6
			if str(r.kind) in ["quad","panel"] and r.plane==[0,2]:mesh.position.y+=.03
		colour=Color("f59e0b");target=space_hover.at
	elif space_hover.has("remove"):
		var r:Dictionary=Model.fit_record(model.records[space_hover.remove],visible_records())
		var mesh:=visual(r,output_unit(),material_phase);mesh.material_override=Kit.material(Color("ef7974"));space_ghost.add_child(mesh);mesh.transform=copy_pose(r)
		colour=Color("ef7974");target=space_hover.at
	else:
		var hit:Variant=_space_box().intersects_segment(aim.global_position-aim.global_basis.z*SPACE_REACH,aim.global_position)
		if hit!=null:target=output.to_local(hit)
	_draw_ray(aim.global_position,output.to_global(target),colour);_guide_state()

func _space_box()->AABB:
	return AABB(output.global_position+Vector3(-CHAMBER*.5,0,-CHAMBER*.5),Vector3(CHAMBER,chamber_height,CHAMBER))

func _draw_ray(from:Vector3,to:Vector3,colour:Color)->void:
	if space_ray==null:return
	var length:=from.distance_to(to)
	if length<.01:space_ray.visible=false;return
	(space_ray.material_override as StandardMaterial3D).albedo_color=colour
	space_ray.global_transform=Transform3D(Basis(Quaternion(Vector3.UP,(to-from)/length))*Basis.from_scale(Vector3(1,length,1)),(from+to)*.5)
	space_ray.visible=true

## The trigger: makes the piece under the aim. Returns placed or refused.
func space_press(aim:Node3D,hand:Node=null)->String:
	if studio_ctrl!=null:return studio_ctrl.studio_press(aim,hand)
	space_update(aim,hand)
	space_notice=""
	if space_hover.has("remove"):space_notice="that one stands: the grip takes it away";return "refused"
	if not space_hover.has("make"):space_notice="point at a place in the grid";return "refused"
	var before:Array=model.records.duplicate(true);var made_kind:=str(space_hover.make[-1].kind)
	for r:Dictionary in space_hover.make:
		var ok:bool=model.add(r,tier)
		if not ok and r.kind=="diag":ok=model.add({"kind":"diag","at":r.end,"end":r.at},tier)   # the record keeps one direction of a diagonal
		if not ok:model.records.assign(before);space_notice="not here";return "refused"
	remember_edit(before);space_hide();share();redraw()
	space_notice="made: %s"%str(KIND_WORDS.get(made_kind,made_kind))
	return "placed"

## The grip: takes away the placed piece under the aim. False when there is none, so the grip stays the hand's
## (a thing placed from the hand menu is taken back by the hand).
func space_grip()->bool:
	if studio_ctrl!=null:return studio_ctrl.studio_grip()
	if not player_inside or not space_hover.has("remove"):return false
	var i:int=space_hover.remove
	var kind:String=str(model.records[i].kind)
	var result:Dictionary=model.revision(i,{})
	if not result.ok:space_notice="something still stands on it: take that first";return true
	var before:Array=model.records.duplicate(true);model.records.assign(result.records);remember_edit(before)
	space_hide();share();redraw()
	space_notice="taken away: %s"%str(KIND_WORDS.get(kind,kind));return true

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

## The guide: what this floor builds, and what the trigger or grip does now.
func _guide_state()->void:
	if space_guide==null:return
	var now:String
	if space_hover.has("make"):now="PULL: make the %s"%str(KIND_WORDS.get(str(space_hover.make[-1].kind),"piece")).to_upper()
	elif space_hover.has("remove"):now="GRIP: take away the %s"%str(KIND_WORDS.get(str(model.records[space_hover.remove].kind),"piece")).to_upper()
	else:now="THIS FLOOR BUILDS: %s\nPoint at a place in the grid and pull. Things come from the hand menu."%", ".join(open_labels())
	if space_guide.text!=now:space_guide.text=now

func redraw()->void:
	if studio_ctrl!=null:studio_ctrl.redraw_all();return
	super.redraw()
	if space and space_sockets!=null:_redraw_space();_refresh_space_sockets()

func _process_space()->void:
	_update_inside()

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
	if studio_ctrl!=null:studio_ctrl.save_studio_build();return
	if space:_save_space_build();return   # this floor's build only: no shared blueprint, no other station told
	super.share()

func receive(records:Array,sender:Node)->void:
	if studio_ctrl!=null or space:return   # another station's build is not this floor's
	super.receive(records,sender)
