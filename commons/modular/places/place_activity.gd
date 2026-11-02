extends RefCounted
## THE ACTIVITY IN THE SLOT (Palle, 2026-10-31: "in these slots we want to select specific artifacts and groups of
## artifacts; make the artifact parameterised and make them slot into the playground nicely"). A recipe's `activities`
## (place_builder.gd, from place.json "activity") name a registry artifact and a config carrying the slot - its floor
## footprint, its depth, the floor and rim heights. build() makes the artifact's scene with the config left as
## config_* metas (read in _ready) and stands it on the pool floor; fit() applies the config once it is in the tree.
## A surface that knows the slot (commons/context/walkgrids/TopologySpace.gd) fits and edge-secures itself.
const Items=preload("res://commons/player/inventory_items.gd")
const GroundPhysics=preload("res://addons/godot-xr-tools/overrides/ground_physics.gd")
const GroundSettings=preload("res://addons/godot-xr-tools/overrides/ground_physics_settings.gd")
const BounceCeiling=preload("res://commons/modular/places/bounce_ceiling.gd")

static func build(item:Dictionary)->Node3D:
	var token:=str(item.get("artifact",""));var path:=Items.scene_for(token)
	if path=="" or not ResourceLoader.exists(path):push_warning("place_activity: no scene for artifact '%s'"%token);return null
	var node:Node=load(path).instantiate()
	if not node is Node3D:node.free();return null
	var cfg:Dictionary=item.get("config",{})
	for k in cfg:node.set_meta("config_%s"%str(k),cfg[k])
	node.name=str(item.get("id","activity"))
	var at:Array=item.get("position",[0,0,0]);(node as Node3D).position=Vector3(float(at[0]),float(at[1]),float(at[2]))
	var turn:Array=item.get("rotation",[0,0,0]);(node as Node3D).rotation_degrees=Vector3(float(turn[0]),float(turn[1]),float(turn[2]))   # a wall faces the room
	node.set_meta("activity_artifact",token)
	return node

static func fit(node:Node3D,item:Dictionary)->void:
	if node!=null and node.has_method("apply_grid_config"):node.apply_grid_config(item.get("config",{}))
	if node!=null and item.get("fit")!=null:_fit_into(node,item.fit)
	if node!=null and item.get("walk")!=null:_walk_body(node,item)
	if node!=null and item.get("label")!=null:_floor_label(node,item)
	if node!=null and item.get("skirt")!=null:
		# a floor artifact with its own body (the display plate's glass, its top at its thickness): only the ramp onto it
		var host:=node.get_parent();var at:Array=item.get("position",[0,0,0]);var sk:Array=item.skirt
		var ramp:=StaticBody3D.new();ramp.name=str(item.get("id","floor"))+"_skirt";host.add_child(ramp)
		ramp.position=Vector3(float(at[0]),float(at[1]),float(at[2]));ramp.rotation_degrees=Vector3(0,float((item.get("rotation",[0,0,0]) as Array)[1]),0)
		_skirt(ramp,float(sk[0])*.5,float(sk[1])*.5,float(at[1]),float(sk[2]))

## WALK (a floor board's "walk": true): a thin static box under the artifact's surface, the board's w x h, beside it
## in the hall - not its child, so a fit's scale does not touch it. The surface of a floor artifact lies at its
## origin (+5 mm for the mosaic floors), so the box's top is there and the frame's bars stay under the feet.
static func _walk_body(node:Node3D,item:Dictionary)->void:
	var host:=node.get_parent()
	if host==null:return
	var at:Array=item.get("position",[0,0,0]);var turn:Array=item.get("rotation",[0,0,0]);var size:Array=item.walk
	var body:=StaticBody3D.new();body.name=str(item.get("id","floor"))+"_walk";body.set_meta("walk_of",str(item.get("id","")))
	var shape:=CollisionShape3D.new();var box:=BoxShape3D.new();box.size=Vector3(float(size[0]),.04,float(size[1]));shape.shape=box;shape.position.y=-.015
	body.add_child(shape);host.add_child(body)
	body.position=Vector3(float(at[0]),float(at[1]),float(at[2]));body.rotation_degrees=Vector3(0,float(turn[1]),0)
	if float(at[1])<.2:_skirt(body,float(size[0])*.5,float(size[1])*.5,float(at[1]),.005)
	var jump_h:=float(item.get("jump",0.0));var bounce:Dictionary=item.get("bounce",{}) if item.get("bounce") is Dictionary else {}
	if jump_h>0.0 or not bounce.is_empty():
		# the surface's own ground physics, in the GroundPhysics node the XR body reads from what it stands on and hits;
		# the desktop walker reads the same node (walker._support_jump, walker._bounce)
		var ground:=GroundPhysics.new();ground.name="GroundPhysics";ground.physics=GroundSettings.new();ground.physics.flags=0
		if jump_h>0.0:
			# a surface that throws a jump that high: sqrt(2 g h)
			ground.physics.flags|=GroundSettings.GroundPhysicsFlags.JUMP_VELOCITY
			ground.physics.jump_velocity=sqrt(2.0*float(ProjectSettings.get_setting("physics/3d/default_gravity",9.8))*jump_h)
			body.set_meta("jump_height",jump_h)
		if not bounce.is_empty():
			# THE BOUNCY FLOOR (Palle, 2026-11-02: "the material should be bouncy ... with the 4 m ceiling"): the landing
			# speed is thrown back, v + 2 n m b - above 1 each bounce climbs - from the threshold (m/s) up, so walking and
			# stepping do not bounce; the rise is capped at the ceiling (BounceCeiling for the XR body, walker._bounce)
			ground.physics.flags|=GroundSettings.GroundPhysicsFlags.BOUNCINESS|GroundSettings.GroundPhysicsFlags.BOUNCE_THRESHOLD
			ground.physics.bounciness=float(bounce.get("bounciness",1.2));ground.physics.bounce_threshold=float(bounce.get("threshold",2.0))
			body.set_meta("bounce_ceiling",float(bounce.get("ceiling",4.0)))
			if host.get_node_or_null("BounceCeiling")==null:
				var ceiling:=BounceCeiling.new();ceiling.name="BounceCeiling";host.add_child(ceiling)
		body.add_child(ground)

## THE SKIRT of a walk surface on the ground (found 2026-11-02: the desktop walker could not get onto the mosaic
## field - the frame's bar along its edge stands 7.5 cm and the surface 8.5 cm, and a 20 cm capsule meets either at
## more than its 45-degree floor angle). Four wedges, 50 cm out from each edge down to the ground: a 10-degree ramp
## over the bar. Between two boards a wedge lies under the neighbour's surface and does nothing.
static func _skirt(body:StaticBody3D,hx:float,hz:float,lift:float,top:float)->void:
	var low:=-lift;var out:=.5
	for side in [Vector3(1,0,0),Vector3(-1,0,0),Vector3(0,0,1),Vector3(0,0,-1)]:
		var along:=Vector3(side.z,0,side.x)   # the edge's direction
		var half:=hz if side.x!=0 else hx;var edge:=(hx if side.x!=0 else hz)
		var points:=PackedVector3Array()
		for s in [-1.0,1.0]:
			var a:Vector3=side*edge+along*half*s
			points.append(a+Vector3(0,top,0));points.append(a+Vector3(0,low,0));points.append(a+side*out+Vector3(0,low,0))
		var wedge:=ConvexPolygonShape3D.new();wedge.points=points
		var cs:=CollisionShape3D.new();cs.name="Skirt";cs.shape=wedge;body.add_child(cs)

## LABEL (a floor board's "label": true): the artifact's title flat on the walk surface along the board's south edge.
static func _floor_label(node:Node3D,item:Dictionary)->void:
	var host:=node.get_parent()
	if host==null:return
	var at:Array=item.get("position",[0,0,0]);var size:Array=item.get("walk",[4,4])
	var label:=Label3D.new();label.name=str(item.get("id","floor"))+"_label";label.text=str(item.label).replace("_"," ")+(" - draws nothing" if node.get_meta("draws_nothing",false) else "")
	label.font_size=40;label.pixel_size=.0045;label.outline_size=8;label.modulate=Color("f4efe4");label.outline_modulate=Color("1d1b19")
	label.rotation_degrees=Vector3(-90,0,0);host.add_child(label)
	label.position=Vector3(float(at[0]),float(at[1])+.012,float(at[2])+float(size[1])*.5-.22)

## FIT (a board's "fit": true, 2026-11-02): whatever the artifact built is scaled uniformly into the board's w x h -
## a wall board's width along local x and height up y, a floor board's w x h on x and z - and moved so its extent is
## centred on the board, a wall's base on the sill. Measured off the artifact's own meshes, so a facade plan anchored
## at its left edge, or a floor built from a corner, lands where its frame is.
static func _fit_into(node:Node3D,fit:Array)->void:
	# measured in the BOARD's frame - the hall's, turned by the artifact's yaw only - so a tilted artifact (a floor
	# stood up in a wall frame) is fitted by what it shows the room: x along the board, y up, z out of it
	var host:=node.get_parent()
	if host==null:return
	var yaw:=Basis(Vector3.UP,node.rotation.y);var to_board:=yaw.inverse()
	var lo:=Vector3.INF;var hi:=-Vector3.INF;var any:=false
	for m in node.find_children("*","MeshInstance3D",true,false):
		var mi:=m as MeshInstance3D
		if mi.mesh==null or _leaving(mi,node):continue   # a rebuild queue_frees the first build; it is still here this frame
		var to_hall:Transform3D=host.global_transform.affine_inverse()*mi.global_transform
		var box:AABB=mi.mesh.get_aabb()
		for i in 8:
			var p:Vector3=to_board*(to_hall*box.get_endpoint(i)-node.position)
			lo=lo.min(p);hi=hi.max(p);any=true
	var size:=hi-lo
	if not any or size.x<=0.0:node.set_meta("draws_nothing",true);return   # nothing to fit: the label says so
	var w:=float(fit[0]);var h:=float(fit[1]);var wall:=str(fit[2])=="wall"
	var s:=minf(w/size.x,h/(size.y if wall else maxf(size.z,.001)))
	var c:=(lo+hi)*.5
	var anchor:=Vector3(c.x,lo.y if wall else 0.0,c.z)
	node.scale=node.scale*s
	node.position-=yaw*(anchor*s)
	node.set_meta("fit_scale",s)

static func _leaving(n:Node,root:Node)->bool:
	while n!=null and n!=root:
		if n.is_queued_for_deletion():return true
		n=n.get_parent()
	return false
