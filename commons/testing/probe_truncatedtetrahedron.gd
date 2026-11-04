extends SceneTree
## Counts what the truncatedtetrahedron artifact actually builds, with the same
## topology() the Void's platonic studies use (welded vertices, coplanar triangles merged
## into faces, diagonals inside a face not counted as edges).
##
##   godot --headless --path . --xr-mode off --script res://commons/testing/probe_truncatedtetrahedron.gd
##
## Exit code = number of failed checks. The checks:
##   t = 1/3   12 V, 18 E, 4 triangles + 4 hexagons, all edges equal, every vertex a
##             permutation of (3,1,1)*BODY/3 with an even number of minus signs
##   t = 1/2   the octahedron: 6 V, 12 E, 8 triangles
##   other t   12 V, 18 E, 4 + 4, but two edge lengths (NOT Archimedean) — the negative
##   every t   V - E + F = 2, each triangle wound clockwise from outside, its stored
##             normal pointing out
##   ghost     origin_solid=ghost adds the seed tetrahedron shell (4 V, 6 E, 4 faces)

const ARTIFACT := "res://commons/primitives/truncatedtetrahedron/truncatedtetrahedron.tscn"
const STUDY := "res://commons/void/platonic_study.gd"

var _fails := 0
var _ran := false

# Run on the first frame, not in _initialize: the root is not ready there yet, so an
# added child's _ready (which builds the mesh) has not run.
func _process(_delta: float) -> bool:
	if _ran:
		return false
	_ran = true
	_run()
	return false

func _run() -> void:
	var study = load(STUDY)
	if study == null:
		print("FAIL could not load ", STUDY)
		quit(1)
		return
	var scene: PackedScene = load(ARTIFACT)
	for t in [0.1, 0.2, 1.0 / 3.0, 0.4, 0.5]:
		var node: Node3D = scene.instantiate()
		node.truncation = t
		root.add_child(node)
		var mi: MeshInstance3D = node.get_node("TruncatedTetrahedron")
		_check(t, mi.mesh, study.topology(mi.mesh), node.BODY)
		node.free()
	var ghosted: Node3D = scene.instantiate()
	ghosted.origin_solid = "ghost"
	root.add_child(ghosted)
	var ghost: MeshInstance3D = ghosted.get_node_or_null("OriginSolid")
	if ghost == null:
		_fail("ghost: no OriginSolid node")
	else:
		var g: Dictionary = study.topology(ghost.mesh)
		var line := "ghost  V=%d E=%d F=%d" % [g.vertices.size(), g.edges.size(), g.face_vertices.size()]
		if g.vertices.size() != 4 or g.edges.size() != 6 or g.face_vertices.size() != 4:
			_fail(line)
		else:
			print("ok   ", line)
	ghosted.free()
	print("probe_truncatedtetrahedron: %d failed" % _fails)
	quit(_fails)

func _check(t: float, mesh: Mesh, topo: Dictionary, body: float) -> void:
	var v: int = topo.vertices.size()
	var e: int = topo.edges.size()
	var tri := 0
	var hexa := 0
	for f in topo.face_vertices:
		if f.size() == 3: tri += 1
		elif f.size() == 6: hexa += 1
	var f_count: int = topo.face_vertices.size()
	var lengths := {}
	for edge: Vector2i in topo.edges:
		var l: float = topo.vertices[edge.x].distance_to(topo.vertices[edge.y])
		lengths[snappedf(l, 0.0001)] = true
	var line := "t=%.4f  V=%d E=%d F=%d (%d tri + %d hex)  edge lengths %s" % [t, v, e, f_count, tri, hexa, str(lengths.keys())]
	var ok := v - e + f_count == 2
	if is_equal_approx(t, 0.5):
		ok = ok and v == 6 and e == 12 and tri == 8 and lengths.size() == 1
	else:
		ok = ok and v == 12 and e == 18 and tri == 4 and hexa == 4
		if is_equal_approx(t, 1.0 / 3.0):
			ok = ok and lengths.size() == 1
			for p: Vector3 in topo.vertices:
				var a := (p / (body / 3.0)).abs()
				var sorted := [snappedf(a.x, 0.001), snappedf(a.y, 0.001), snappedf(a.z, 0.001)]
				sorted.sort()
				var minus := int(p.x < 0) + int(p.y < 0) + int(p.z < 0)
				if sorted != [1.0, 1.0, 3.0] or minus % 2 != 0:
					ok = false
					line += "  bad vertex %s" % str(p)
		else:
			ok = ok and lengths.size() == 2
	# winding + normals, read straight off the committed arrays
	var arrays := mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var wrong := 0
	for i in range(0, verts.size(), 3):
		var c := (verts[i] + verts[i + 1] + verts[i + 2]) / 3.0
		var ccw := (verts[i + 1] - verts[i]).cross(verts[i + 2] - verts[i])
		if ccw.dot(c) >= 0.0 or normals[i].dot(c) <= 0.0:
			wrong += 1
	if wrong > 0:
		ok = false
		line += "  %d triangle(s) wound or normalled inward" % wrong
	if ok:
		print("ok   ", line)
	else:
		_fail(line)

func _fail(line: String) -> void:
	_fails += 1
	print("FAIL ", line)
