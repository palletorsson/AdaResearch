extends RefCounted
## Original utilities, configured by the SAME parser/seating code as grid and museum.
const Utilities=preload("res://commons/grid/UtilityRegistry.gd")
static func validate(raw:Dictionary)->PackedStringArray:
	var errors:=PackedStringArray();var items:Variant=raw.get("grid_connectors",[]);var ids:Dictionary={}
	if not items is Array:return PackedStringArray(["grid_connectors must be an array"])
	for item in items:
		if not item is Dictionary:errors.append("connector must be an object");continue
		var id:=str(item.get("id",""));var at:Variant=item.get("at")
		if not id.is_valid_identifier() or ids.has(id):errors.append("connector needs a unique id")
		ids[id]=true
		if item.has("artifact"):
			if item.artifact not in ["rotation_array_compare","adjustable_landing","sine_flow_tray","sine_wall_corridor"] or not item.get("config",{}) is Dictionary:errors.append(id+": unsupported connector artifact or config")
		elif Utilities.parse_utility_cell(str(item.get("cell",""))).type not in ["tc","sc","rc"]:errors.append(id+": only tc, sc and rc connectors are supported")
		if not at is Array or at.size()!=3 or not at.all(func(v):return (v is int or v is float) and is_finite(v) and absf(v)<=48):errors.append(id+": invalid anchor")
	return errors

static func build(host:Node3D,raw:Dictionary)->Array[Node3D]:
	var nodes:Array[Node3D]=[]
	for item in raw.get("grid_connectors",[]):
		if item.has("artifact"):
			var Activity=load("res://commons/modular/places/place_activity.gd")
			var activity:Dictionary=item.duplicate(true);activity["position"]=item.at
			var artifact:Node3D=Activity.build(activity)
			if artifact!=null:host.add_child(artifact);Activity.fit(artifact,activity);nodes.append(artifact)
			continue
		var parsed:Dictionary=Utilities.parse_utility_cell(item.cell)
		var node:Node3D=load(Utilities.get_utility_scene_path(parsed.type)).instantiate()
		node.name=item.id;node.position=Vector3(item.at[0],item.at[1],item.at[2])
		Utilities.apply_params(node,parsed.type,parsed.parameters,{"config":parsed.config})
		Utilities.seat_crossing_before_ready(node,parsed.type,float(item.at[1]))
		Utilities.make_carriable(node)
		if parsed.type=="tc":
			node.set_meta("route_local_origin",node.position)
			node.set_meta("route_local_direction",node.move_direction)
			node.move_direction=host.global_basis*node.move_direction
		node.set_meta("source_cell",item.cell);host.add_child(node);nodes.append(node)
	return nodes

static func rebase(nodes:Array[Node3D])->void:
	for n in nodes:
		if not n.has_meta("route_local_origin"):continue
		n.position=n.get_meta("route_local_origin")
		n.initial_position=n.global_position;n.original_y=n.global_position.y
		n.move_direction=(n.get_parent().global_basis*(n.get_meta("route_local_direction") as Vector3)).normalized()
		n.target_position=n.initial_position+n.move_direction*n.move_distance
		n.is_moving=false;n.is_returning=false;n.waiting_to_start=false;n.carried_player=null
		if n.auto_start:n.start_transport()
