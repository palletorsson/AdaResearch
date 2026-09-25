extends "res://commons/artifacts/triangle_construction_plate/triangle_construction_plate.gd"
## Book layout of the six existing museum artifacts, using their real scenes and
## room configurations. This page layout is not a newly placed museum artifact.
var pairs: Array = []

func _ready() -> void:
    _label("ADA RESEARCH   /   PRIMITIVES IGNORANCE",Vector3(-3.1,5.10,0),36,MUTED,MONO,HORIZONTAL_ALIGNMENT_LEFT)
    _label("Enough to hold which distinction?",Vector3(-3.1,4.85,0),132,INK,LIGHT,HORIZONTAL_ALIGNMENT_LEFT)
    _rule(Vector3(-3.1,4.57,0),Vector3(3.1,4.57,0))
    _label("TRIANGLE EDGES VISIBLE",Vector3(-3.1,3.98,0),44,MUTED,MONO,HORIZONTAL_ALIGNMENT_LEFT)
    _label("TRIANGLE EDGES HIDDEN",Vector3(-3.1,2.38,0),44,MUTED,MONO,HORIZONTAL_ALIGNMENT_LEFT)
    var reference: Array = JSON.parse_string(FileAccess.get_file_as_string("res://reference.json"))
    for i in range(3):
        var row: Dictionary = reference[i]
        var x := -2.1+float(i)*2.1
        var pair: Array = []
        for j in range(2):
            var subject: MeshInstance3D = load(row["scene"]).instantiate()
            subject.apply_grid_config(row["configs"][j])
            subject.name=String(row["token"])+("_marked" if j==0 else "_plain")
            add_child(subject)
            subject.position=Vector3(x,3.15 if j==0 else 1.55,0.65)
            subject.rotation_degrees=Vector3(-16,20,0)
            subject.scale=Vector3.ONE*1.22
            pair.append(subject)
        pairs.append(pair)
        var sample: SphereMesh = pair[0].mesh
        _label("%d %s / %d segments" % [sample.rings,"ring" if sample.rings==1 else "rings",sample.radial_segments],Vector3(x,4.28,0),64,INK,MONO)
    _rule(Vector3(-3.1,0.65,0),Vector3(3.1,0.65,0))
    _label("Within each pair: the same mesh, material, size and view.",Vector3(0,0.48,0),48,INK)
    _label("The lines change what you can follow. They do not rebuild the surface.",Vector3(0,0.31,0),42,MUTED)
