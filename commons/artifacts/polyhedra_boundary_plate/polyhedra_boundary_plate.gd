extends "res://commons/artifacts/triangle_construction_plate/triangle_construction_plate.gd"
## Same presentation furniture as the Triangle plate; a different investigation.
## Coordinates/faces reproduce grab_trihedron's default wedge at size 0.6.
## Both diagrams use one rotated set of 3D positions. The second makes visible
## the boundary of the convex hull supplied to physics, not another art object.
const VERTICES: Array[Vector3] = [Vector3(0,0.6,0), Vector3(-0.6,-0.6,-0.6), Vector3(0.6,-0.6,-0.6), Vector3(0,-0.6,0.6)]
const OPEN_FACES: Array = [[0,1,2],[0,2,3],[0,3,1]]
const BASE_FACE: Array = [1,3,2]
const HULL_COLOR := Color("c09143")
const MODEL_SCALE := 0.60
var models: Array[Node3D] = []
var hull_shape: ConvexPolygonShape3D

func _ready() -> void:
    _build_case()
    _build_type()
    hull_shape = ConvexPolygonShape3D.new()
    hull_shape.points = PackedVector3Array(VERTICES)
    _build_model(false, -1.02)
    _build_model(true, 1.02)

func diagram_basis() -> Basis:
    return Basis(Vector3.FORWARD, deg_to_rad(8)) * Basis(Vector3.RIGHT, deg_to_rad(-78)) * Basis(Vector3.UP, deg_to_rad(0))

func _build_type() -> void:
    _label("ADA RESEARCH   /   PRIMITIVES", Vector3(-1.89,2.52,0.04),24,MUTED,MONO,HORIZONTAL_ALIGNMENT_LEFT)
    _label("FIG. 02", Vector3(1.87,2.52,0.04),24,MUTED,MONO,HORIZONTAL_ALIGNMENT_RIGHT)
    _label("An opening for the eye.",Vector3(-1.89,2.35,0.04),66,INK,LIGHT,HORIZONTAL_ALIGNMENT_LEFT)
    _rule(Vector3(-1.89,2.19,0.04),Vector3(1.89,2.19,0.04))
    for i in range(2):
        var x := -1.02 + float(i)*2.04
        _label(["01  /  VISIBLE SURFACE", "02  /  COLLISION HULL"][i],Vector3(x-0.78,2.04,0.04),27,MUTED,MONO,HORIZONTAL_ALIGNMENT_LEFT)
        _label(["Three faces. One opening.", "Four points. A closed solid."][i],Vector3(x-0.78,1.92,0.04),39,INK,REGULAR,HORIZONTAL_ALIGNMENT_LEFT)
        _label(["0-1-2    0-2-3    0-3-1", "CONVEX HULL  { 0, 1, 2, 3 }"][i],Vector3(x,1.02,0.04),23,MUTED,MONO)
        _label(["The base is absent from the mesh.", "The hull closes the missing base."][i],Vector3(x,0.9,0.04),28,INK)
    _rule(Vector3(0,1.08,0.035),Vector3(0,2.1,0.035))
    _rule(Vector3(-1.89,0.8,0.04),Vector3(1.89,0.8,0.04))
    _label("Seeing an opening and passing through it are different questions.",Vector3(0,0.735,0.04),27,MUTED)

func _face(parent: Node3D, indices: Array, points: Array[Vector3], color: Color, face_name: String) -> void:
    var instance := MeshInstance3D.new()
    instance.name = face_name
    var mesh := ImmediateMesh.new()
    mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
    for i in indices: mesh.surface_add_vertex(points[i])
    mesh.surface_end()
    instance.mesh = mesh
    var mat := _material(color)
    mat.cull_mode = BaseMaterial3D.CULL_DISABLED
    instance.material_override = mat
    parent.add_child(instance)

func _build_model(closed: bool, x: float) -> void:
    var model := Node3D.new()
    model.name = "Hull" if closed else "OpenCorner"
    add_child(model)
    model.position = Vector3(x,1.52,0.20)
    # A shallow relief keeps the orthographic diagram readable from room angles.
    # Both specimens use the same depth projection; local vertices stay identical.
    model.scale.z = 0.2
    models.append(model)
    var points: Array[Vector3] = []
    for v in VERTICES: points.append(diagram_basis() * v * MODEL_SCALE)
    var shades := [Color("d5e6e5"),Color("add0d0"),Color("83b4bf")]
    for i in range(3): _face(model,OPEN_FACES[i],points,shades[i],"Side%d" % i)
    if closed: _face(model,BASE_FACE,points,Color("dfbc7f"),"MissingBaseClosed")
    var edges := [[0,1],[0,2],[0,3],[1,2],[2,3],[3,1]]
    for i in range(edges.size()):
        var edge := _rule(points[edges[i][0]],points[edges[i][1]],INK,0.0045,model)
        edge.name = "Edge%d" % i
    for i in range(4):
        var point := MeshInstance3D.new()
        point.name = "Vertex%d" % i
        var sphere := SphereMesh.new()
        sphere.radius=0.014; sphere.height=0.028; sphere.radial_segments=16; sphere.rings=8
        point.mesh=sphere; point.material_override=_material(ROSE)
        if not closed and i==0:
            # Mark the interior corner as a schematic datum over its meeting faces.
            point.material_override.no_depth_test=true
        model.add_child(point);point.position=points[i]
        var offset := Vector3(0.0,0.06,0.035)
        if i==1: offset.x=-0.06;offset.y=-0.025
        if i==2: offset.x=0.06;offset.y=-0.025
        if i==3: offset.y=-0.06
        # Apex 0 is inside the hull's projected base; do not print it over that face.
        if not closed or i!=0:
            var vertex_label := _label(str(i),model.position+points[i]*model.scale+offset,26,INK,MONO)
            if i==0: vertex_label.no_depth_test=true
    # For the hull, annotate the base's centre; this is a diagram of its boundary.
    if closed:
        var centre: Vector3 = (points[1]+points[2]+points[3])/3.0
        _label("BASE",model.position+centre*model.scale+Vector3(0,0,0.025),24,Color("704d20"),MONO)
