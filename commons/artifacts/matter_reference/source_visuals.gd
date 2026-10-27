extends RefCounted
## Native meshes reconstructed from the reference's actual Three.js mesh recipes.
static func vec(a: Array) -> Vector3:return Vector3(a[0],a[1],a[2])
static func append(host: Node3D,data: Dictionary) -> void:
	var tree := Engine.get_main_loop();var cache_key := "matter_reference_visual_materials"
	if not tree.has_meta(cache_key):tree.set_meta(cache_key,{})
	var materials: Dictionary = tree.get_meta(cache_key)
	for p in data.meshes:
		var mesh: Mesh
		var pars: Dictionary = p.get("parameters",{})
		match str(p.type):
			"BoxGeometry":mesh = BoxMesh.new();mesh.size = Vector3(pars.width,pars.height,pars.depth)
			"CylinderGeometry":mesh = CylinderMesh.new();mesh.top_radius = pars.radiusTop;mesh.bottom_radius = pars.radiusBottom;mesh.height = pars.height;mesh.radial_segments = int(pars.radialSegments);mesh.cap_top = not pars.openEnded;mesh.cap_bottom = not pars.openEnded
			"SphereGeometry":mesh = SphereMesh.new();mesh.radius = pars.radius;mesh.height = pars.radius*2;mesh.radial_segments = int(pars.widthSegments);mesh.rings = int(pars.heightSegments)
			_:
				var arrays := [];arrays.resize(Mesh.ARRAY_MAX);var vertices := PackedVector3Array();var normals := PackedVector3Array();var uv := PackedVector2Array();var indices := PackedInt32Array()
				for i in range(0,p.vertices.size(),3):vertices.append(Vector3(p.vertices[i],p.vertices[i+1],p.vertices[i+2]));normals.append(Vector3(p.normals[i],p.normals[i+1],p.normals[i+2]))
				for i in range(0,p.uv.size(),2):uv.append(Vector2(p.uv[i],p.uv[i+1]))
				for i in range(0,vertices.size(),3):indices.append_array(PackedInt32Array([i,i+2,i+1]))
				arrays[Mesh.ARRAY_VERTEX] = vertices;arrays[Mesh.ARRAY_NORMAL] = normals;arrays[Mesh.ARRAY_INDEX] = indices
				if not uv.is_empty():arrays[Mesh.ARRAY_TEX_UV] = uv
				mesh = ArrayMesh.new();mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
		var key := JSON.stringify(p.material)
		var material: Material = materials[key].get_ref() if materials.has(key) else null
		if material==null:
			var info: Dictionary = p.material;var m := StandardMaterial3D.new();m.albedo_color = Color(info.color);m.roughness = info.roughness;m.metallic = info.metallic
			if not str(info.texture).is_empty():m.albedo_texture = load("res://commons/artifacts/matter_reference/textures/"+info.texture+".png") as Texture2D;m.uv1_scale = Vector3(info.repeat[0],info.repeat[1],1)
			if info.alpha<1:m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA;m.albedo_color.a = info.alpha
			if info.double:m.cull_mode = BaseMaterial3D.CULL_DISABLED
			material = m;materials[key] = weakref(m)
		var instance := MeshInstance3D.new();instance.mesh = mesh;instance.material_override = material;instance.position = vec(p.position);instance.quaternion = Quaternion(p.quaternion[0],p.quaternion[1],p.quaternion[2],p.quaternion[3]);instance.scale = vec(p.scale);host.add_child(instance)
	for p in data.get("labels",[]):
		var label := Label3D.new();label.text = p.text;label.position = vec(p.position);label.pixel_size = .0014;label.font_size = 22;host.add_child(label)
