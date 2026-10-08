extends "res://commons/artifacts/triangle_construction_plate/triangle_construction_plate.gd"
## Two fixed moments in animatedcubebuilder's front-face experiment.
## The capture runner verifies these positions and triples against the builder.
## This is a reference, not a second set of controls: try the actual handles nearby.
const FACE_VERTICES: Array[Vector3] = [Vector3(-0.5,-0.5,0.5), Vector3(0.5,-0.5,0.5), Vector3(0.5,0.5,0.5), Vector3(-0.5,0.5,0.5)]
const FACE_TRIPLES: Array = [[4,5,7],[5,6,7]]
const DISPLACEMENT := Vector3(0,0,0.55)
const FIXED := Color("b7d3d8")
const MOVED := Color("6c9dad")
const SEAM := Color("b27925")
const MODEL_SCALE := 0.62
var models: Array[Node3D] = []

func _ready() -> void:
    _build_case()
    _build_type()
    _build_model(false,-1.02)
    _build_model(true,1.02)

func diagram_basis() -> Basis:
    return Basis(Vector3.RIGHT,deg_to_rad(-24))*Basis(Vector3.UP,deg_to_rad(35))

func specimen_points(moved: bool) -> Array[Vector3]:
    var points: Array[Vector3] = FACE_VERTICES.duplicate()
    if moved: points[2] += DISPLACEMENT
    return points

func project_point(point: Vector3) -> Vector3:
    var p := diagram_basis()*(point-Vector3(0,0,0.5))*MODEL_SCALE
    p.z *= 0.16 # Equal shallow relief in both studies, for wall legibility.
    return p

func _build_type() -> void:
    _label("ADA RESEARCH   /   PRIMITIVES",Vector3(-1.89,2.52,0.04),24,MUTED,MONO,HORIZONTAL_ALIGNMENT_LEFT)
    _label("FIG. 03",Vector3(1.87,2.52,0.04),24,MUTED,MONO,HORIZONTAL_ALIGNMENT_RIGHT)
    _label("The diagonal was already there.",Vector3(-1.89,2.35,0.04),63,INK,LIGHT,HORIZONTAL_ALIGNMENT_LEFT)
    _rule(Vector3(-1.89,2.19,0.04),Vector3(1.89,2.19,0.04))
    for i in range(2):
        var x := -1.02+float(i)*2.04
        _label(["01  /  ONE FLAT FACE", "02  /  MOVE CORNER 6"][i],Vector3(x-0.8,2.04,0.04),27,MUTED,MONO,HORIZONTAL_ALIGNMENT_LEFT)
        _label(["Two triangles share an edge.","Pull it out of the face's plane."][i],Vector3(x-0.8,1.91,0.04),34,INK,REGULAR,HORIZONTAL_ALIGNMENT_LEFT)
        _label("[4, 5, 7]     [5, 6, 7]",Vector3(x,1.02,0.04),26,INK,MONO)
        _label(["A square before the corner moves.","4, 5 and 7 stay where they were."][i],Vector3(x,0.90,0.04),28,MUTED)
    _rule(Vector3(0,1.1,0.035),Vector3(0,2.1,0.035))
    _rule(Vector3(-1.89,0.8,0.04),Vector3(1.89,0.8,0.04))
    _label("Same connections. A different surface.",Vector3(0,0.735,0.04),28,MUTED)

func _build_model(moved: bool, x: float) -> void:
    var model := Node3D.new()
    model.name = "MovedFace" if moved else "FlatFace"
    add_child(model); model.position=Vector3(x-0.06,1.48,0.14)
    models.append(model)
    var raw := specimen_points(moved)
    var points: Array[Vector3] = []
    for v in raw: points.append(project_point(v))
    for t in range(2):
        var surface := ImmediateMesh.new()
        surface.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
        for i in FACE_TRIPLES[t]: surface.surface_add_vertex(points[i-4])
        surface.surface_end()
        var face := MeshInstance3D.new()
        face.name="Triangle%d" % t;face.mesh=surface
        var mat := _material(FIXED if t==0 else MOVED)
        mat.cull_mode=BaseMaterial3D.CULL_DISABLED
        face.material_override=mat;model.add_child(face)
    for i in range(4):
        var edge := _rule(points[i],points[(i+1)%4],INK,0.004,model)
        edge.name="Edge%d" % i
    var seam := _rule(points[1]+Vector3(0,0,0.006),points[3]+Vector3(0,0,0.006),SEAM,0.010,model)
    seam.name="SharedDiagonal57"
    var offsets := [Vector3(-0.045,-0.052,0.04),Vector3(0.05,-0.05,0.04),Vector3(0.05,0.05,0.04),Vector3(-0.05,0.05,0.04)]
    for i in range(4):
        var point := MeshInstance3D.new()
        point.name="Vertex%d" % (i+4)
        var sphere := SphereMesh.new()
        sphere.radius=0.012;sphere.height=0.024;sphere.radial_segments=16;sphere.rings=8
        point.mesh=sphere;point.material_override=_material(ROSE if i==2 else INK)
        model.add_child(point);point.position=points[i]+Vector3(0,0,0.009)
        _label(str(i+4),model.position+points[i]+offsets[i],28,ROSE if i==2 else INK,MONO)
    if moved:
        var start := project_point(FACE_VERTICES[2])+Vector3(0,0,0.025)
        var end := points[2]+Vector3(0,0,0.025)
        # Dashed former edges and a rose arrow retain the starting position.
        for neighbor in [1,3]:
            var a: Vector3 = points[neighbor]+Vector3(0,0,0.025)
            for k in range(0,10,2):
                var dash := _rule(a.lerp(start,float(k)/10),a.lerp(start,float(k+1)/10),INK,0.0015,model)
                dash.material_override.no_depth_test=true
        var arrow := _rule(start,end,ROSE,0.004,model)
        arrow.material_override.no_depth_test=true
        var direction := (end-start).normalized()
        var side := Vector3(-direction.y,direction.x,0).normalized()*0.018
        for sign_value in [-1,1]:_rule(end,end-direction*0.045+side*sign_value,ROSE,0.003,model)
        var old_label := _label("6 before",model.position+start+Vector3(-0.035,-0.045,0.06),21,INK,MONO,HORIZONTAL_ALIGNMENT_RIGHT)
        old_label.no_depth_test=true
