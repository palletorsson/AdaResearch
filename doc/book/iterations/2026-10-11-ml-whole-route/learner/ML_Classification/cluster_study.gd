extends Node3D
const Model = preload("cluster_model.gd")
const PointBody = preload("point_body.gd")
const Rack = preload("res://commons/audio/rack_templates/RackTemplates.gd")
const COLOURS = [Color("f2799d"),Color("62d8da"),Color("ffd56c"),Color("ad9cf2")]
const DATASETS = ["BLOBS", "RINGS", "GRID"]
var model := Model.new()
var point: PointBody
var selected := 0
var was_held := false
var drawing := Node3D.new()
var readout := Label3D.new()

func _ready() -> void:
    add_child(drawing)
    var backing := MeshInstance3D.new(); var slab := BoxMesh.new()
    slab.size = Vector3(2.7,0.06,2.7); backing.mesh = slab
    backing.position.y = 0.88; backing.material_override = material(Color("18202b")); add_child(backing)
    readout.position = Vector3(0,2.1,-1.45)
    readout.font_size = 27; readout.pixel_size = 0.0025; add_child(readout)
    var header := MeshInstance3D.new(); var plate := BoxMesh.new()
    plate.size = Vector3(3.2,0.65,0.04); header.mesh = plate
    header.position = Vector3(0,2.1,-1.5)
    header.material_override = material(Color("18202b")); add_child(header)
    point = PointBody.new(); add_child(point)
    var words := ["ASSIGN","MEAN","RESET","CENTRE","K 2","K 3","K 4","DATA"]
    var rows: Array = []
    for r in 2:
        var row: Array = []
        for c in 4: row.append({"type":"button","label":words[r*4+c]})
        rows.append(row)
    var panel := Rack.create_panel("K-MEANS",rows)
    panel.position = Vector3(0,1.05,1.7); panel.rotation_degrees.x = -30
    panel.scale = Vector3.ONE*2; add_child(panel)
    for mesh in panel.find_children("*","MeshInstance3D",true,false):
        var m := mesh.material_override as BaseMaterial3D
        if m != null:
            m = m.duplicate(); m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
            mesh.material_override = m
    for i in words.size():
        var button = panel.find_child("Btn_%d"%i,true,false).get_node("InteractableAreaButton")
        button.button_pressed.connect(func(_area):command(words[i]))
    redraw()

func material(colour: Color) -> StandardMaterial3D:
    var m := StandardMaterial3D.new(); m.albedo_color = colour
    m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    return m

func place(p: Vector2, height: float = 0.98) -> Vector3:
    return Vector3(p.x*1.25,height,p.y*1.25)

func dot(p: Vector3, radius: float, colour: Color) -> void:
    var mesh := SphereMesh.new(); mesh.radius = radius; mesh.height = radius*2
    mesh.radial_segments = 16; mesh.rings = 8
    var node := MeshInstance3D.new(); node.mesh = mesh; node.position = p
    node.material_override = material(colour); drawing.add_child(node)

func rod(a: Vector3, b: Vector3, colour: Color) -> void:
    var d := b-a
    if d.length() < 0.00001: return
    var mesh := CylinderMesh.new(); mesh.top_radius = 0.007; mesh.bottom_radius = 0.007
    mesh.height = d.length(); mesh.radial_segments = 8
    var node := MeshInstance3D.new(); node.mesh = mesh; node.position = (a+b)*0.5
    node.quaternion = Quaternion(Vector3.UP,d.normalized())
    node.material_override = material(colour); drawing.add_child(node)

func redraw() -> void:
    for child in drawing.get_children(): drawing.remove_child(child); child.queue_free()
    for i in model.data.size():
        var colour := Color("eeeeee")
        if not model.groups.is_empty():
            var j: int = model.groups[i]; colour = COLOURS[j]
            rod(place(model.data[i]),place(model.centres[j],1.12),colour.darkened(0.35))
        dot(place(model.data[i]),0.034,colour)
    for j in model.centres.size():
        var centre: Vector3 = place(model.centres[j],1.12)
        if j != selected: dot(centre,0.07,COLOURS[j])
        var label := Label3D.new(); label.text = "C%d"%(j+1)
        label.position = centre+Vector3(0,0.18,0)
        label.modulate = COLOURS[j]; label.font_size = 25; label.pixel_size = 0.002
        drawing.add_child(label)
    if not point.held(): point.global_position = to_global(place(model.centres[selected],1.12))
    var score := "unassigned"
    if not model.groups.is_empty(): score = "SSE %.4f"%model.score()
    readout.text = "%s / K %d / %d mean updates / %s\n%s\nBlack sphere = C%d. Grab to change its position.\nSmall dots stay fixed. Colour is an index, not a name." % [
        DATASETS[model.dataset],model.k,model.rounds,score,model.status,selected+1]

func command(word: String) -> void:
    if point.held(): return
    match word:
        "ASSIGN": model.assign()
        "MEAN": model.move_means()
        "RESET": model.reset(model.k)
        "CENTRE": selected = (selected+1)%model.k
        "K 2", "K 3", "K 4": model.reset(int(word.right(1))); selected = 0
        "DATA": model.set_data(model.dataset+1); selected = 0
    redraw()

func _physics_process(_delta: float) -> void:
    if not point.held():
        point.global_position = to_global(place(model.centres[selected],1.12))

func _process(_delta: float) -> void:
    if point.held():
        var hand := to_local(point.global_position)
        model.move_centre(selected,Vector2(hand.x,hand.z)/1.25)
        was_held = true; redraw()
    elif was_held:
        was_held = false; redraw()
