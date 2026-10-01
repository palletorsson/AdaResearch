extends RefCounted
## Borrowed from the project's MeshGrammar (commons/mesh_grammar in the Ada
## Research repository): a small version of what MeshData.from_array_mesh()
## and ExtrudeFaceOp do there, behind one function. Use it by path:
##   const Grammar := preload("res://borrowed/grammar_extrude.gd")
##   mesh = Grammar.extrude_up(mesh, 0.5, 0.3)
## One contract:
##   extrude_up(mesh, distance, scale) -> ArrayMesh
##       every triangle of `mesh` that faces up is pushed out along its own
##       normal by `distance` metres and scaled toward its own middle by `scale`;
##       three walls of two triangles join its old edges to the new ones.
## What it shares with your extrude(): a wall for every edge, and the same two
## numbers. What it does not share: it knows triangles and no outline. A cap
## made of five triangles is pushed out five times, each about its own middle.
## The rest is the project's, kept as it is there:
##   - "faces up" is: the normal is within 60 degrees of straight up;
##   - a triangle smaller than 0.01 m2, or with its shortest edge under a
##     twentieth of its longest, is left as it is, in silence;
##   - corners in one place are welded into one on the way in, and a triangle
##     that has two corners in one place is dropped;
##   - MeshGrammar winds its triangles counter-clockwise and draws both sides.
##     Godot's renderer wants front faces clockwise. So every triangle is turned
##     over on the way in and again on the way out. Without that, "up" is the
##     bottom of your solid.
## The mesh that comes back has one flat normal for each triangle.

const UP_WITHIN := 60.0     # degrees
const MIN_AREA := 0.01      # square metres
const MIN_ASPECT := 0.05    # shortest edge / longest edge

static func extrude_up(mesh: ArrayMesh, distance: float, scale: float) -> ArrayMesh:
	var data := read(mesh)
	var vertices: PackedVector3Array = data["vertices"]
	var faces: Array = data["faces"]
	var chosen := facing_up(vertices, faces)
	chosen.reverse()                        # from the last to the first: removing one does not move the ones before it
	for index: int in chosen:
		var face: PackedInt32Array = faces[index]
		var v0 := vertices[face[0]]
		var v1 := vertices[face[1]]
		var v2 := vertices[face[2]]
		if (v1 - v0).cross(v2 - v0).length() * 0.5 < MIN_AREA:
			continue
		var edges := [(v1 - v0).length(), (v2 - v1).length(), (v0 - v2).length()]
		if edges.max() > 0.0 and edges.min() / edges.max() < MIN_ASPECT:
			continue
		var normal := (v1 - v0).cross(v2 - v0).normalized()
		var middle := (v0 + v1 + v2) / 3.0
		var n0 := vertices.size()
		vertices.append(middle + (v0 - middle) * scale + normal * distance)
		vertices.append(middle + (v1 - middle) * scale + normal * distance)
		vertices.append(middle + (v2 - middle) * scale + normal * distance)
		faces.remove_at(index)
		faces.append(PackedInt32Array([n0, n0 + 1, n0 + 2]))                # the new top
		for edge in 3:                                                       # a wall for every edge
			var a := face[edge]
			var b := face[(edge + 1) % 3]
			var a_up := n0 + edge
			var b_up := n0 + (edge + 1) % 3
			faces.append(PackedInt32Array([a, b, b_up]))
			faces.append(PackedInt32Array([a, b_up, a_up]))
	return write(vertices, faces)

## The mesh as MeshGrammar holds it: {"vertices": the corners, each place once,
## "faces": a list of three corner numbers for each triangle, wound
## counter-clockwise}.
static func read(mesh: ArrayMesh) -> Dictionary:
	var arrays := mesh.surface_get_arrays(0)
	var raw: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var order := PackedInt32Array()
	if arrays[Mesh.ARRAY_INDEX] != null and arrays[Mesh.ARRAY_INDEX].size() > 0:
		order = arrays[Mesh.ARRAY_INDEX]
	else:
		for i in raw.size():
			order.append(i)
	var vertices := PackedVector3Array()
	var places := {}
	var faces: Array = []
	for i in range(0, order.size() - 2, 3):
		var face := PackedInt32Array()
		for k: int in [0, 2, 1]:             # turned over: Godot's clockwise becomes counter-clockwise
			var v := raw[order[i + k]]
			var key := "%s_%s_%s" % [snapped(v.x, 0.0001), snapped(v.y, 0.0001), snapped(v.z, 0.0001)]
			if not places.has(key):
				places[key] = vertices.size()
				vertices.append(v)
			face.append(places[key])
		if face[0] != face[1] and face[1] != face[2] and face[2] != face[0]:
			faces.append(face)
	return {"vertices": vertices, "faces": faces}

## The numbers of the triangles whose normal is within 60 degrees of straight up.
static func facing_up(vertices: PackedVector3Array, faces: Array) -> Array:
	var chosen: Array = []
	for index in faces.size():
		var face: PackedInt32Array = faces[index]
		var normal := (vertices[face[1]] - vertices[face[0]]).cross(vertices[face[2]] - vertices[face[0]])
		normal = normal.normalized() if normal.length_squared() >= 1e-10 else Vector3.UP
		if normal.dot(Vector3.UP) >= cos(deg_to_rad(UP_WITHIN)):
			chosen.append(index)
	return chosen

## Back to a mesh Godot draws: each triangle turned over again, with a flat
## normal of its own.
static func write(vertices: PackedVector3Array, faces: Array) -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_smooth_group(-1)
	for face: PackedInt32Array in faces:
		surface.add_vertex(vertices[face[0]])
		surface.add_vertex(vertices[face[2]])
		surface.add_vertex(vertices[face[1]])
	surface.generate_normals()
	return surface.commit()
