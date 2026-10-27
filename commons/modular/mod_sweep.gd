extends RefCounted
## Sweep a solid 2D profile along a 3D path. Horizontal side + world-up frames
## preserve vertical headroom on slopes. Rectangular strips can compose the exact
## cross-section difference (outer rectangle minus inner passage), as editable parts.

static func _v(value: Array) -> Vector3:
	return Vector3(float(value[0]),float(value[1]),float(value[2]))

static func make(spec: Dictionary) -> Node3D:
	var path: Array=spec.get("path",[])
	var profile: Array=spec.get("profile",[])
	var root:=Node3D.new();root.name="sweep"
	if path.size()<2 or profile.size()<3:
		push_error("sweep needs a path and a solid profile");return root
	var origin: Vector3=_v(path[0]);root.position=origin
	var rings: Array=[]
	for i in path.size():
		var tangent: Vector3=_v(path[mini(i+1,path.size()-1)])-_v(path[maxi(i-1,0)])
		if i==0 and spec.has("start_direction"):tangent=_v(spec.start_direction)
		if i==path.size()-1 and spec.has("end_direction"):tangent=_v(spec.end_direction)
		var right: Vector3=tangent.cross(Vector3.UP).normalized()
		if right.length_squared()<.5:
			push_error("sweep requires a horizontal path direction");return root
		var ring: Array[Vector3]=[]
		for vertex in profile:ring.append(_v(path[i])-origin+right*float(vertex[0])+Vector3.UP*float(vertex[1]))
		rings.append(ring)
	var surface:=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(rings.size()-1):
		for k in profile.size():
			var next: int=(k+1)%profile.size()
			_quad(surface,rings[i][k],rings[i][next],rings[i+1][next],rings[i+1][k])
	var polygon:=PackedVector2Array()
	for point in profile:polygon.append(Vector2(float(point[0]),float(point[1])))
	var cap: PackedInt32Array=Geometry2D.triangulate_polygon(polygon)
	for i in range(0,cap.size(),3):
		_triangle(surface,rings[0][cap[i]],rings[0][cap[i+2]],rings[0][cap[i+1]])
		_triangle(surface,rings[-1][cap[i]],rings[-1][cap[i+1]],rings[-1][cap[i+2]])
	var mesh:=MeshInstance3D.new();mesh.name="Surface";mesh.mesh=surface.commit()
	var material:=StandardMaterial3D.new();material.albedo_color=Color(str(spec.get("color","eee9df")))
	material.albedo_color.a=float(spec.get("alpha",1));material.roughness=.65;material.metallic=float(spec.get("metallic",.05))
	if material.albedo_color.a<.999:
		material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
		material.cull_mode=BaseMaterial3D.CULL_DISABLED
		mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mesh.material_override=material;root.add_child(mesh)
	if bool(spec.get("collide",true)):
		var body:=StaticBody3D.new();body.name="SweptCollision"
		var shape:=CollisionShape3D.new();shape.shape=mesh.mesh.create_trimesh_shape()
		var physics:=PhysicsMaterial.new();physics.friction=float(spec.get("friction",.25));physics.bounce=0
		body.physics_material_override=physics;body.add_child(shape);root.add_child(body)
	root.set_meta("sweep_path",path)
	return root

static func _triangle(surface: SurfaceTool,a: Vector3,b: Vector3,c: Vector3) -> void:
	var normal: Vector3=-(b-a).cross(c-a).normalized() # Godot clockwise front faces
	for vertex in [a,b,c]:surface.set_normal(normal);surface.add_vertex(vertex)

static func _quad(surface: SurfaceTool,a: Vector3,b: Vector3,c: Vector3,d: Vector3) -> void:
	_triangle(surface,a,b,c);_triangle(surface,a,c,d)
