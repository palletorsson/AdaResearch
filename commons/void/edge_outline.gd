extends RefCounted
## THE WHITE-WITH-EDGES LOOK for the Transformation floors (Palle, 2026-11-09: "make all artifact in this map white
## (since we have not introduced color yet). Use the same outline shader as in Primitives Ignorance"). Floor 8 has no
## outline shader: its white is PlatonicStudy.finish() and its edges are a dark line overlay of the mesh
## (commons/primitives/shared/mesh_inspection.gd), which draws EVERY triangle edge - right for a sphere whose
## tessellation is the lesson, wrong for a box, whose faces would show their diagonals. This draws the FEATURE edges
## only: where the two faces meeting at an edge bend by more than `angle` degrees, and every open border. A cube shows
## its twelve edges; a cylinder of 8 segments its eight seams; one of 64 segments only its rims.
##   outline(node)       every solid mesh under node takes the white finish and a dark edge overlay child
##   overlay(mesh)       one overlay node for one mesh (artifacts that rebuild a mesh call this again)
##   edges(mesh, angle)  the line mesh alone, cached per mesh
## primitive_finish.gd calls outline() for a placement whose config has "platonic": "outline".
const PlatonicStudy = preload("res://commons/void/platonic_study.gd")
const NAME := "EdgeOutline"
const COLOR := Color(0.05, 0.10, 0.16)
const SKIP_WORDS := ["label", "text", "screen", "ghost", "shell", "highlight", "glass", "caption", "sign", "edgeoutline", "meshinspection"]
static var _cache := {}
static var _line_material: StandardMaterial3D

static func line_material() -> StandardMaterial3D:
	if _line_material == null:
		_line_material = StandardMaterial3D.new()
		_line_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_line_material.albedo_color = COLOR
	return _line_material

## White finish + edges on every solid mesh under node; returns how many meshes it dressed. Safe to call twice: an
## existing overlay is replaced, never doubled.
static func outline(node: Node, angle := 25.0, finish: Material = null) -> int:
	if finish == null:
		finish = PlatonicStudy.finish()
	var count := 0
	if node is SubViewport:
		return 0
	if (node is MeshInstance3D or node is MultiMeshInstance3D) and _takes(node):
		var g := node as GeometryInstance3D
		g.material_override = finish
		_attach(g, angle)
		count += 1
	for child in node.get_children():
		count += outline(child, angle, finish)
	return count

## Replace (or add) the edge overlay of one mesh instance - for an artifact that rebuilt or resized its mesh.
static func refresh(g: GeometryInstance3D, angle := 25.0) -> void:
	_attach(g, angle)

static func _attach(g: GeometryInstance3D, angle: float) -> void:
	var old := g.get_node_or_null(NAME)
	if old != null:
		g.remove_child(old)
		old.free()
	if g is MeshInstance3D:
		var mi := g as MeshInstance3D
		if mi.mesh == null: return
		var node := overlay(mi.mesh, angle)
		if node != null: mi.add_child(node)
	elif g is MultiMeshInstance3D:
		# A copy of the instance transforms at dress time. An artifact that animates its MultiMesh must keep the copy in
		# step itself (carousel_cake does), or draw its own.
		var src := (g as MultiMeshInstance3D).multimesh
		if src == null or src.mesh == null: return
		var wire := edges(src.mesh, angle)
		if wire == null: return
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = wire
		mm.instance_count = src.instance_count
		for i in src.instance_count:
			mm.set_instance_transform(i, src.get_instance_transform(i))
		var node := MultiMeshInstance3D.new()
		node.name = NAME
		node.multimesh = mm
		node.material_override = line_material()
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		g.add_child(node)

static func overlay(mesh: Mesh, angle := 25.0) -> MeshInstance3D:
	var wire := edges(mesh, angle)
	if wire == null:
		return null
	var node := MeshInstance3D.new()
	node.name = NAME
	node.mesh = wire
	node.material_override = line_material()
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Grown 0.2 % about the mesh's own centre so the lines win the depth test against their faces without drifting off
	# a mesh whose origin is far from it.
	var c := mesh.get_aabb().get_center()
	node.transform = Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * 1.002), c - c * 1.002)
	return node

## The feature edges of a mesh as a line mesh (null when it has none). Vertices are welded by position, so a mesh whose
## faces carry their own vertices (flat shading, BoxMesh) still finds its neighbours.
static func edges(mesh: Mesh, angle := 25.0) -> ArrayMesh:
	var key := "%d/%.1f" % [mesh.get_instance_id(), angle]
	if _cache.has(key):
		var hit: Variant = _cache[key]
		return hit as ArrayMesh
	var limit := cos(deg_to_rad(angle))
	var ids := {}
	var points: Array[Vector3] = []
	var edge_normals := {}
	for surface in mesh.get_surface_count():
		if mesh is ArrayMesh and (mesh as ArrayMesh).surface_get_primitive_type(surface) != Mesh.PRIMITIVE_TRIANGLES:
			continue
		var arrays: Array = mesh.surface_get_arrays(surface)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
		var size: int = indices.size() if not indices.is_empty() else vertices.size()
		for i in range(0, size - 2, 3):
			var tri: Array[int] = []
			for k in 3:
				var v: Vector3 = vertices[indices[i + k] if not indices.is_empty() else i + k]
				var weld := str(v.snapped(Vector3.ONE * .0001))
				if not ids.has(weld):
					ids[weld] = points.size(); points.append(v)
				tri.append(ids[weld])
			var a := points[tri[0]]
			var n := (points[tri[1]] - a).cross(points[tri[2]] - a)
			if n.length_squared() < 1e-16:
				continue
			n = n.normalized()
			for e in [[tri[0], tri[1]], [tri[1], tri[2]], [tri[2], tri[0]]]:
				var ek := Vector2i(mini(e[0], e[1]), maxi(e[0], e[1]))
				if not edge_normals.has(ek): edge_normals[ek] = []
				(edge_normals[ek] as Array).append(n)
	var lines := PackedVector3Array()
	for ek: Vector2i in edge_normals:
		var normals: Array = edge_normals[ek]
		var keep := normals.size() == 1
		if not keep:
			for j in range(1, normals.size()):
				if (normals[0] as Vector3).dot(normals[j]) < limit:
					keep = true; break
		if keep:
			lines.append(points[ek.x]); lines.append(points[ek.y])
	var wire: ArrayMesh = null
	if not lines.is_empty():
		wire = ArrayMesh.new()
		var arr := []
		arr.resize(Mesh.ARRAY_MAX)
		arr[Mesh.ARRAY_VERTEX] = lines
		wire.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arr)
	_cache[key] = wire
	return wire

static func _takes(g: GeometryInstance3D) -> bool:
	var lowered := str(g.name).to_lower()
	for word in SKIP_WORDS:
		if lowered.contains(word):
			return false
	if g.layers == 0 or not g.visible:
		return false
	var mesh: Mesh = (g as MeshInstance3D).mesh if g is MeshInstance3D else ((g as MultiMeshInstance3D).multimesh.mesh if (g as MultiMeshInstance3D).multimesh != null else null)
	if mesh == null or mesh is ImmediateMesh:
		return false
	var material: Material = g.material_override
	if material == null and g is MeshInstance3D and mesh.get_surface_count() > 0:
		material = (g as MeshInstance3D).get_active_material(0)
	if material is BaseMaterial3D:
		var base := material as BaseMaterial3D
		if base.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED or base.albedo_color.a < .99:
			return false
	if material is ShaderMaterial:
		# A shader with its own look (a screen, a field) keeps it, unless it is one of the carousel's stripes.
		var path := ((material as ShaderMaterial).shader.resource_path if (material as ShaderMaterial).shader != null else "")
		if not path.contains("stripes"):
			return false
	return true
