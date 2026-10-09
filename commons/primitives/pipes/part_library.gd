extends RefCounted
## Museum adapter for the existing glass-segment and cable-form libraries.
## Mesh resources are retained in undo records; node instances are disposable.
const Glass = preload("res://commons/glass_rack/GlassRackController.gd")
const Cable = preload("res://algorithms/wavefunctions/line_builder_3d/cable_builder.gd")
const Ports = preload("res://commons/glass_rack/GlassSegmentPorts.gd")
const GROUPS := [
	["straight","corner45","corner","ubend","sbend"],
	["junction","ypipe","cross","reducer"],
	["spiral","wobbly","flask","beaker"],
	["cap","drip","condenser"],
	["chord","spline","catenary","festoon","truss"]]
const GROUP_NAMES := ["BENDS","BRANCHES","COILS AND VESSELS","END PIECES","CABLE FORMS"]
const LABELS := {"corner45":"45° BEND","corner":"90° BEND","ubend":"U-BEND","sbend":"S-BEND","junction":"TEE","ypipe":"Y-JUNCTION","wobbly":"WAVE","catenary":"AUTHORED SAG"}

static func label(part: String) -> String:
	return LABELS.get(part,part.to_upper())

static func make_record(part: String, at: Vector3, colour: Color) -> Dictionary:
	var node: Node3D
	if GROUPS[4].has(part): node = _cable(part)
	else:
		var factory = Glass.new(); factory.auto_build=false; factory.show_liquid=false
		factory.pipe_radius=0.05; factory.segment_length=0.65
		var params := {"length":0.7,"height":0.7,"tube_radius":0.05,"corner_radius":0.5,"bend_radius":0.3,"branch_length":0.4,"arm_length":0.35,"radius_in":0.09,"radius_out":0.04,"spiral_radius":0.18,"turns":3,"resolution":24,"amplitude":0.13,"frequency":2.0,"offset":0.45,"tip_length":0.22,"inner_radius":0.04,"jacket_radius":0.12,"outer_radius":0.08,"neck_radius":0.05,"neck_length":0.25}
		params.radius = 0.23 if part in ["flask","beaker"] else 0.05
		node = factory._create_segment(part,params)
		factory.free()
	if node == null: return {}
	var meshes: Array = []
	var turn := Basis.IDENTITY if part in ["spiral","beaker"] or GROUPS[4].has(part) else Basis(Vector3.RIGHT,-PI/2)
	_collect(node,Transform3D(turn,Vector3.ZERO),meshes)
	if meshes.is_empty(): node.free(); return {}
	var bounds: AABB = meshes[0].pose * meshes[0].mesh.get_aabb()
	for item in meshes: bounds = bounds.merge(item.pose * item.mesh.get_aabb())
	var scale := 1.05/maxf(0.01,maxf(bounds.size.x,maxf(bounds.size.y,bounds.size.z)))
	var fit := Transform3D(Basis.IDENTITY.scaled(Vector3.ONE*scale),at-bounds.get_center()*scale)
	for item in meshes: item.pose = fit*item.pose
	var sockets: Array = []
	var raw: Dictionary = node.get_meta("ports",{})
	for name in raw:
		var port: Dictionary = raw[name]
		sockets.append({"name":name,"point":fit*(turn*port.position),"direction":turn*port.direction,"radius":port.radius*scale})
	var max_radius := 0.0
	for port in sockets: max_radius=maxf(max_radius,port.radius)
	var title_at := at+Vector3(0,-0.72,0.35)
	node.free()
	return {"part":part,"part_meshes":meshes,"sockets":sockets,"points":PackedVector3Array([sockets[0].point,sockets[-1].point]),"radius":max_radius,"sides":12,"colour":colour,"kind":"prefab","label_at":title_at}

static func _collect(node: Node3D, parent: Transform3D, result: Array) -> void:
	var pose := parent*node.transform
	if node is MeshInstance3D and node.mesh:
		result.append({"mesh":node.mesh,"pose":pose})
	for child in node.get_children():
		if child is Node3D: _collect(child,pose,result)

static func _cable(kind: String) -> Node3D:
	var factory = Cable.new(); factory.cable_thickness=0.035; factory.tube_sides=12
	var anchors := PackedVector3Array([Vector3(-0.8,0,0),Vector3(0,0.1,0),Vector3(0.8,0,0)])
	var node := Node3D.new(); var mesh := MeshInstance3D.new()
	if kind == "catenary":
		factory.curve=Curve3D.new(); factory.curve.up_vector_enabled=false
		for p in anchors: factory.curve.add_point(p)
		for i in 2:
			var delta := anchors[i+1]-anchors[i]
			factory.curve.set_point_out(i,delta*0.3+Vector3.DOWN*delta.length()*0.25)
			factory.curve.set_point_in(i+1,-delta*0.3+Vector3.DOWN*delta.length()*0.25)
		factory.mesh_instance=mesh; factory._generate_tube_from_curve()
	else:
		var surface := SurfaceTool.new(); surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		var path := anchors
		if kind == "spline": path=factory._drafted_arc(anchors)
		if kind == "festoon": path=factory._swag(anchors,0.7)
		factory._emit_run(surface,path,0.035)
		if kind == "truss": factory._emit_truss(surface,anchors)
		surface.generate_normals(); mesh.mesh=surface.commit()
	node.add_child(mesh)
	var ports := {"in":Ports.create_port(anchors[0],Vector3.LEFT,0.035),"out":Ports.create_port(anchors[-1],Vector3.RIGHT,0.035)}
	if kind in ["catenary","festoon"]: ports["support"]=Ports.create_port(anchors[1],Vector3.UP,0.035)
	Ports.apply_ports(node,ports)
	factory.free()
	return node
