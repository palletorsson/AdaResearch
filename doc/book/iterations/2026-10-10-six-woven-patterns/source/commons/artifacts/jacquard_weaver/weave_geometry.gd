extends RefCounted
## Display geometry shared by the machine and the layer view.
## Paths prescribe interlacement; they do not solve cloth tension or collisions.

static func material(color: String, metal: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(color)
	m.metallic = metal
	m.roughness = 0.65 if metal == 0.0 else 0.3
	return m

static func box(parent: Node3D, pos: Vector3, size: Vector3, mat: Material, solid := false) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var b := BoxMesh.new(); b.size = size
	mesh.mesh = b; mesh.material_override = mat; mesh.position = pos
	parent.add_child(mesh)
	if solid:
		var body := StaticBody3D.new(); body.collision_layer = 1
		var col := CollisionShape3D.new(); var shape := BoxShape3D.new(); shape.size = size
		col.shape = shape; body.add_child(col); mesh.add_child(body)
	return mesh

static func label(parent: Node3D, text: String, pos: Vector3, size := 24) -> Label3D:
	var n := Label3D.new(); n.text = text; n.position = pos
	n.font_size = size * 2; n.pixel_size = 0.0014; n.outline_size = 5
	n.modulate = Color("f4ead5"); parent.add_child(n)
	return n

static func tube(path: PackedVector3Array, radius := 0.009) -> ArrayMesh:
	var vertices := PackedVector3Array(); var normals := PackedVector3Array(); var indices := PackedInt32Array()
	if path.size() < 2: return ArrayMesh.new()
	for i in range(path.size()):
		var tangent := path[mini(i + 1, path.size() - 1)] - path[maxi(0, i - 1)]
		if tangent.length_squared() < 0.000001: tangent = Vector3.RIGHT
		tangent = tangent.normalized()
		var axis := Vector3.UP if absf(tangent.dot(Vector3.UP)) < 0.95 else Vector3.RIGHT
		var u := tangent.cross(axis).normalized(); var v := tangent.cross(u).normalized()
		for side in range(8):
			var a := TAU * float(side) / 8.0; var normal := u * cos(a) + v * sin(a)
			vertices.append(path[i] + normal * radius); normals.append(normal)
	for i in range(path.size() - 1):
		for side in range(8):
			var a := i * 8 + side; var b := i * 8 + (side + 1) % 8
			indices.append_array([a, a + 8, b, b, a + 8, b + 8])
	var arrays: Array = []; arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices; arrays[Mesh.ARRAY_NORMAL] = normals; arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new(); mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

static func yarn(parent: Node3D, path: PackedVector3Array, mat: Material, radius := 0.009) -> MeshInstance3D:
	var n := MeshInstance3D.new(); n.mesh = tube(path, radius); n.material_override = mat; parent.add_child(n)
	return n

static func weft_runs(parent: Node3D, paths: Array, colours: Array, radius := .009) -> void:
	# A colour change starts a new yarn. Consecutive picks of the same colour
	# return at the selvedge; different colours are not a gradient-dyed strand.
	var run := PackedVector3Array(); var colour := ""
	for row in range(paths.size()):
		if not run.is_empty() and colours[row]!=colour:
			yarn(parent,run,material(colour),radius); run.clear()
		colour=str(colours[row]); run.append_array(paths[row])
	if not run.is_empty(): yarn(parent,run,material(colour),radius)

static func drawdown(parent: Node3D, records: Array, repeats := 1, pitch := .15, start_z := -.55) -> MeshInstance3D:
	# One flat, vertex-coloured mesh: the thread visible on top at each crossing.
	var v:=PackedVector3Array(); var c:=PackedColorArray(); var n:=PackedVector3Array(); var ids:=PackedInt32Array()
	var Colours=preload("res://commons/artifacts/jacquard_weaver/yarn_colours.gd")
	for row in range(records.size()):
		for col in range(12*repeats):
			var x:=(col-(12*repeats-1)*.5)*pitch; var z:=start_z+row*(.075 if repeats==1 else pitch); var base:=v.size()
			var half_x:=pitch*.5;var half_z:=.0375 if repeats==1 else pitch*.5
			v.append_array([Vector3(x-half_x,.894,z-half_z),Vector3(x+half_x,.894,z-half_z),Vector3(x+half_x,.894,z+half_z),Vector3(x-half_x,.894,z+half_z)])
			for i in range(4): c.append(Color(Colours.top_colour(records[row],col))); n.append(Vector3.UP)
			ids.append_array([base,base+1,base+2,base,base+2,base+3])
	var arrays:Array=[]; arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=v; arrays[Mesh.ARRAY_NORMAL]=n; arrays[Mesh.ARRAY_COLOR]=c; arrays[Mesh.ARRAY_INDEX]=ids
	var mesh:=ArrayMesh.new(); mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	var mat:=StandardMaterial3D.new(); mat.vertex_color_use_as_albedo=true; mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode=BaseMaterial3D.CULL_DISABLED
	var result:=MeshInstance3D.new(); result.mesh=mesh; result.material_override=mat; parent.add_child(result); return result

static func clear(parent: Node) -> void:
	for child in parent.get_children(): child.free()

static func card(parent: Node3D, bits: Array, mat: Material, width := 0.46) -> void:
	# Real rectangular openings; no black dots masquerading as holes.
	var step := width / 12.0
	box(parent, Vector3(0, 0.065, 0), Vector3(width + 0.035, 0.065, 0.014), mat)
	box(parent, Vector3(0, -0.065, 0), Vector3(width + 0.035, 0.065, 0.014), mat)
	for i in range(13):
		box(parent, Vector3(-width / 2 + i * step, 0, 0), Vector3(0.009, 0.068, 0.014), mat)
	for i in range(12):
		if int(bits[i]) == 0:
			box(parent, Vector3(-width / 2 + (i + 0.5) * step, 0, 0), Vector3(step, 0.068, 0.014), mat)

static func crossing(col: int, row: int, bit: int, warp: bool, gap: float) -> Vector3:
	var sign_y := 1.0 if bit == 1 else -1.0
	if not warp: sign_y *= -1.0
	# gap unfolds pick order vertically without changing any stored crossing bit.
	return Vector3(-0.825 + col * 0.15, 0.98 + row * gap + sign_y * 0.022, -0.55 + row * 0.075)
