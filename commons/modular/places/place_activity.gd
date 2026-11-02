extends RefCounted
## THE ACTIVITY IN THE SLOT (Palle, 2026-10-31: "in these slots we want to select specific artifacts and groups of
## artifacts; make the artifact parameterised and make them slot into the playground nicely"). A recipe's `activities`
## (place_builder.gd, from place.json "activity") name a registry artifact and a config carrying the slot - its floor
## footprint, its depth, the floor and rim heights. build() makes the artifact's scene with the config left as
## config_* metas (read in _ready) and stands it on the pool floor; fit() applies the config once it is in the tree.
## A surface that knows the slot (commons/context/walkgrids/TopologySpace.gd) fits and edge-secures itself.
const Items=preload("res://commons/player/inventory_items.gd")

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
