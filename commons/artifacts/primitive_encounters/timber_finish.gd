extends RefCounted
## Shared real-metre timber finish. Chamfers catch light without changing the
## simple box collider or the nominal construction dimensions.
static var finish: StandardMaterial3D
static var meshes: Dictionary = {}

static func material() -> StandardMaterial3D:
	if finish==null:
		finish=StandardMaterial3D.new()
		finish.albedo_texture=load("res://commons/void/textures/construction_wood.png")
		finish.albedo_color=Color("f2e5ce")
		finish.roughness=.67
		finish.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return finish

static func mesh(size: Vector3) -> ArrayMesh:
	if meshes.has(size):return meshes[size]
	var h := size*.5
	var bevel := minf(.006,minf(h.x,minf(h.y,h.z))*.22)
	var st := SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Six inset faces, twelve edge facets and eight clipped corners.
	for axis in 3:
		var b := (axis+1)%3;var c := (axis+2)%3
		for side in [-1,1]:
			var face: Array[Vector3]=[]
			for pair in [Vector2(-1,-1),Vector2(1,-1),Vector2(1,1),Vector2(-1,1)]:
				var p := Vector3.ZERO;p[axis]=h[axis]*side
				p[b]=(h[b]-bevel)*pair.x;p[c]=(h[c]-bevel)*pair.y;face.append(p)
			_face(st,face)
		for sb in [-1,1]:
			for sc in [-1,1]:
				var face: Array[Vector3]=[]
				for end in [-1,1]:
					for flip in ([false,true] if end==-1 else [true,false]):
						var p := Vector3.ZERO;p[axis]=(h[axis]-bevel)*end
						p[b]=(h[b]-(bevel if flip else 0.0))*sb
						p[c]=(h[c]-(0.0 if flip else bevel))*sc;face.append(p)
				_face(st,face)
	for x in [-1,1]:
		for y in [-1,1]:
			for z in [-1,1]:
				var signs := Vector3(x,y,z)
				_face(st,[(h-Vector3(0,bevel,bevel))*signs,(h-Vector3(bevel,0,bevel))*signs,(h-Vector3(bevel,bevel,0))*signs])
	st.generate_tangents()
	var result := st.commit();meshes[size]=result;return result

static func _face(st: SurfaceTool, points: Array) -> void:
	var centre := Vector3.ZERO
	for p: Vector3 in points:centre+=p
	centre/=points.size()
	for i in range(1,points.size()-1):
		var a: Vector3=points[0];var b: Vector3=points[i];var c: Vector3=points[i+1]
		var normal := (b-a).cross(c-a).normalized()
		if normal.dot(centre)<0:
			var swap := b;b=c;c=swap;normal=-normal
		for p: Vector3 in [a,c,b]:
			st.set_normal(normal)
			# Long grain follows the local X length; end grain reads across Y/Z.
			st.set_uv(Vector2(p.z,p.y)*1.8 if absf(normal.x)>.8 else Vector2((p.z if absf(normal.y)>.5 else p.y)*1.8,p.x*.28))
			st.add_vertex(p)
