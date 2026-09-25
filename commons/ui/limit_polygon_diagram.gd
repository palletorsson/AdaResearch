extends Node3D
## Native planar comparison shared by the portal instrument and the book.
## Mathematical lengths use the analytic unit circle; the drawn reference has
## 256 segments. Selection changes n, never the reference radius or drawing scale.
const PAPER := Color("f4f0e7")
const INK := Color("25333d")
const ROSE := Color("c83f77")
const MUTED := Color("667984")
const FONT = preload("res://commons/font/static/Roboto-Regular.ttf")
const MONO = preload("res://commons/font/JetBrainsMono-Medium.ttf")
const DRAW_RADIUS := 0.49
const CIRCLE_SEGMENTS := 256
var sides := 0
var redraws := 0
var polygon: MeshInstance3D
var gap_surface: MeshInstance3D
var count_label: Label3D
var lengths: Label3D

func _ready() -> void:
    set_meta("em_local_instrument", true)
    var paper := MeshInstance3D.new()
    var quad := QuadMesh.new()
    quad.size = Vector2(1.48,1.78)
    paper.mesh = quad
    paper.material_override = _material(PAPER)
    add_child(paper)
    _label("ONE CIRCLE / MANY SIDES", Vector3(0,0.76,0.008), 32, INK)
    count_label = _label("", Vector3(0,0.62,0.008), 34, ROSE)
    var reference := MeshInstance3D.new()
    reference.name = "CircleReference"
    reference.mesh = _outline(CIRCLE_SEGMENTS,0.004,0.007)
    reference.material_override = _material(MUTED)
    add_child(reference)
    gap_surface = MeshInstance3D.new()
    gap_surface.name = "BetweenChordAndArc"
    gap_surface.material_override = _material(Color("ead9dc"))
    add_child(gap_surface)
    polygon = MeshInstance3D.new()
    polygon.name = "Polygon"
    polygon.material_override = _material(ROSE)
    add_child(polygon)
    lengths = _label("",Vector3(0,-0.62,0.009),27,INK,true)
    _label("Same radius. More chords.",Vector3(0,-0.81,0.009),27,MUTED)
    set_sides(3)

func _material(color: Color) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    m.albedo_color = color
    m.cull_mode = BaseMaterial3D.CULL_DISABLED
    return m

func _label(text: String,at: Vector3,size: int,color: Color,mono: bool=false) -> Label3D:
    var label := Label3D.new()
    label.text = text
    label.position = at
    label.font = MONO if mono else FONT
    label.font_size = size
    label.pixel_size = 0.0013
    label.modulate = color
    label.outline_size = 0
    add_child(label)
    return label

func point(angle: float,z: float=0.0) -> Vector3:
    return Vector3(cos(angle)*DRAW_RADIUS,sin(angle)*DRAW_RADIUS,z)

func _outline(n: int,width: float,z: float) -> ArrayMesh:
    var verts := PackedVector3Array()
    for i in range(n):
        var a := point(PI/2.0+TAU*float(i)/n,z)
        var b := point(PI/2.0+TAU*float(i+1)/n,z)
        var edge := b-a
        var d := Vector3(-edge.y,edge.x,0).normalized()*width*0.5
        verts.append_array(PackedVector3Array([a-d,b-d,b+d,a-d,b+d,a+d]))
    return _triangles(verts)

func _triangles(verts: PackedVector3Array) -> ArrayMesh:
    var mesh := ArrayMesh.new()
    var arrays := []
    arrays.resize(Mesh.ARRAY_MAX)
    arrays[Mesh.ARRAY_VERTEX] = verts
    mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
    return mesh

func set_sides(n: int) -> void:
    n = clampi(n,3,256)
    if n==sides: return
    sides = n
    redraws += 1
    polygon.mesh = _outline(n,0.008,0.012)
    # Draw the actual region between each chord and its sampled arc.
    var verts := PackedVector3Array()
    var steps := maxi(2,ceili(float(CIRCLE_SEGMENTS)/n))
    for i in range(n):
        var start := PI/2.0+TAU*float(i)/n
        var a := point(start,0.004)
        for j in range(1,steps):
            verts.append_array(PackedVector3Array([a,point(start+TAU*float(j)/(n*steps),0.004),point(start+TAU*float(j+1)/(n*steps),0.004)]))
    gap_surface.mesh = _triangles(verts)
    count_label.text = "%d SIDES" % n
    var perimeter := 2.0*n*sin(PI/n)
    lengths.text = "POLYGON  %.6f\nCIRCLE   %.6f\nGAP      %.6f" % [perimeter,TAU,TAU-perimeter]
