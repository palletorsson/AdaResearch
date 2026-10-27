extends MeshInstance3D
## Endpoints live in each touched body's frame, including non-uniform scale.
## Marks on one body; reversible native constraints between separate bodies.
const Binding := preload("binding.gd")
var anchors: Array[Dictionary] = []
var tape_width := 0.05
var paid_length := 0.0
var issuer: WeakRef
var cached: Array = []
var peeled := false

static func anchor(hit: Dictionary) -> Dictionary:
	var body: Node3D = hit.collider
	return {"body":weakref(body),"point":body.to_local(hit.position),
		"normal":body.global_basis.transposed()*Vector3(hit.normal)}

static func resolve(record: Dictionary) -> Dictionary:
	var body = record.body.get_ref()
	if not is_instance_valid(body) or not body.is_inside_tree():return {}
	return {"position":body.to_global(record.point),
		"normal":(body.global_basis.inverse().transposed()*Vector3(record.normal)).normalized(),"body":body}

func _physics_process(_delta: float) -> void:
	if anchors.size()<2:return
	for record in anchors:
		if not is_instance_valid(record.body.get_ref()):
			print("TAPE_ORPHAN / removed endpoint body");queue_free();return
	if anchors.size()>2:
		var points: Array[Dictionary] = []
		for record in anchors:
			var point := resolve(record)
			if point.is_empty() or not point.body.is_visible_in_tree():hide();return
			point.break_before = record.get("break_before",false);points.append(point)
		show();draw_path(points);return
	var a := resolve(anchors[0]);var b := resolve(anchors[1])
	# XRTools may transiently reparent a live body while switching grab frames.
	if a.is_empty() or b.is_empty():visible = false;return
	if not a.body.is_visible_in_tree() or not b.body.is_visible_in_tree():visible = false;return
	visible = true
	draw_between(a.position,a.normal,b.position,b.normal)

func bind_surfaces() -> void:
	var seen: Dictionary = {}
	for i in range(1,anchors.size()):
		if anchors[i].get("break_before",false):continue
		var a := resolve(anchors[i-1]);var b := resolve(anchors[i])
		if a.is_empty() or b.is_empty() or a.body==b.body:continue
		if not a.body is PhysicsBody3D or not b.body is PhysicsBody3D:continue
		if not a.body is RigidBody3D and not b.body is RigidBody3D:continue
		var key := str(mini(a.body.get_instance_id(),b.body.get_instance_id()))+":"+str(maxi(a.body.get_instance_id(),b.body.get_instance_id()))
		if seen.has(key):continue
		seen[key] = true
		var binding := Binding.new();add_child(binding);binding.peeled.connect(func():peeled = true);binding.connect_bodies(a.body,b.body,(a.position+b.position)*.5)

func draw_path(points: Array[Dictionary]) -> void:
	visible = points.size()>1
	var state: Array = [tape_width,peeled]
	for point in points:state.append_array([point.position,point.normal,point.get("break_before",false)])
	if cached==state:return
	cached = state
	var tool := SurfaceTool.new();tool.begin(Mesh.PRIMITIVE_TRIANGLES);var distance := 0.0;var count := 0
	for i in range(1,points.size()):
		if points[i].get("break_before",false):continue
		if peeled and i==maxi(1,points.size()/2):continue
		var a: Vector3 = points[i-1].position;var b: Vector3 = points[i].position
		var axis := b-a;var length := axis.length()
		if length<.001:continue
		axis /= length
		var na: Vector3 = points[i-1].normal;var nb: Vector3 = points[i].normal
		var wa := na.cross(axis).normalized();var wb := nb.cross(axis).normalized()
		if wa.length()<.5:wa = Vector3.UP.cross(axis).normalized()
		if wa.length()<.5:wa = Vector3.RIGHT.cross(axis).normalized()
		if wb.length()<.5:wb = wa
		if wa.dot(wb)<0:wb = -wb
		a += na*.004;b += nb*.004;wa *= tape_width*.5;wb *= tape_width*.5
		var vertices := [a-wa,a+wa,b-wb,a+wa,b+wb,b-wb]
		var uvs := [Vector2(distance,0),Vector2(distance,1),Vector2(distance+length,0),Vector2(distance,1),Vector2(distance+length,1),Vector2(distance+length,0)]
		for k in 6:
			tool.set_normal(global_basis.transposed()*(na if k in [0,1,3] else nb));tool.set_uv(uvs[k]);tool.add_vertex(to_local(vertices[k]))
		distance += length;count += 1
	if count>0:mesh = tool.commit()

func draw_between(a: Vector3,na: Vector3,b: Vector3,nb: Vector3) -> void:
	var next: Array = [a,na,b,nb,tape_width,peeled]
	if cached==next:return
	cached = next
	var axis := b-a;var length := axis.length()
	if length<0.001:visible = false;return
	visible = true;axis /= length
	var wa := na.cross(axis).normalized();var wb := nb.cross(axis).normalized()
	if wa.length()<.5:wa = Vector3.UP.cross(axis).normalized()
	if wa.length()<.5:wa = Vector3.RIGHT.cross(axis).normalized()
	if wb.length()<.5:wb = wa
	if wa.dot(wb)<0:wb = -wb
	var vertices := PackedVector3Array();var normals := PackedVector3Array();var uv := PackedVector2Array();var indices := PackedInt32Array()
	for i in range(9):
		var t := float(i)/8.0;var normal := na.lerp(nb,t).normalized()
		if normal.length()<.5:normal = na
		var width_axis := wa.lerp(wb,t).normalized()*tape_width*.5
		var center := a.lerp(b,t)+normal*.004
		for side in [-1.0,1.0]:
			vertices.append(to_local(center+width_axis*side));normals.append(global_basis.transposed()*normal);uv.append(Vector2(t*length,(side+1)*.5))
		if i>0 and not (peeled and i==5):
			var k := i*2;indices.append_array(PackedInt32Array([k-2,k-1,k,k-1,k+1,k]))
	var arrays := [];arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices;arrays[Mesh.ARRAY_NORMAL] = normals;arrays[Mesh.ARRAY_TEX_UV] = uv;arrays[Mesh.ARRAY_INDEX] = indices
	var ribbon := ArrayMesh.new();ribbon.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays);mesh = ribbon
