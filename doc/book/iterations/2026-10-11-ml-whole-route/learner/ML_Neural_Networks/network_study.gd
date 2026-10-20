extends Node3D
const Model = preload("tiny_network.gd")
const PointBody = preload("point_body.gd")
const Rack = preload("res://commons/audio/rack_templates/RackTemplates.gd")
const ZERO = Color("f18caa")
const ONE = Color("64dad5")
var model := Model.new()
var point: PointBody
var probe := Vector2(-0.8,-0.8)
var example := 0
var running := false
var was_held := false
var check_result: Dictionary = {}
var drawing := Node3D.new()
var readout := Label3D.new()

func _ready() -> void:
    add_child(drawing)
    box(Vector3(-1.05,0.86,0),Vector3(1.8,0.06,1.8))
    box(Vector3(0.8,1.65,-0.8),Vector3(2.2,1.95,0.04))
    box(Vector3(0,2.9,-0.85),Vector3(4,0.6,0.04))
    readout.position = Vector3(0,2.9,-0.8); readout.font_size = 25
    readout.pixel_size = 0.0025; add_child(readout)
    point = PointBody.new(); add_child(point)
    var words := ["STEP","TRAIN","RESET","EXAMPLE","CHECK","FLIP"]
    var rows: Array = []
    for r in 2:
        var row: Array = []
        for c in 3: row.append({"type":"button","label":words[r*3+c]})
        rows.append(row)
    var panel := Rack.create_panel("FIT / PROBE",rows)
    panel.position = Vector3(0,1.05,1.2); panel.rotation_degrees.x = -30
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

func box(where: Vector3, size: Vector3) -> void:
    var node := MeshInstance3D.new(); var mesh := BoxMesh.new(); mesh.size = size
    node.mesh = mesh; node.position = where
    node.material_override = material(Color("18202b")); add_child(node)

func place(p: Vector2, height: float = 1.03) -> Vector3:
    return Vector3(-1.05+p.x*0.78,height,p.y*0.78)

func label(text: String, where: Vector3, size: int = 22) -> void:
    var node := Label3D.new(); node.text = text; node.position = where
    node.font_size = size; node.pixel_size = 0.002; drawing.add_child(node)

func dot(where: Vector3, colour: Color, radius: float = 0.06) -> void:
    var mesh := SphereMesh.new(); mesh.radius = radius; mesh.height = radius*2
    mesh.radial_segments = 16; mesh.rings = 8
    var node := MeshInstance3D.new(); node.mesh = mesh; node.position = where
    node.material_override = material(colour); drawing.add_child(node)

func wire(a: Vector3, b: Vector3, weight: float) -> void:
    var d := b-a
    var mesh := CylinderMesh.new(); mesh.height = d.length(); mesh.radial_segments = 8
    mesh.top_radius = 0.006+0.004*minf(absf(weight),4); mesh.bottom_radius = mesh.top_radius
    var node := MeshInstance3D.new(); node.mesh = mesh; node.position = (a+b)*0.5
    node.quaternion = Quaternion(Vector3.UP,d.normalized())
    node.material_override = material(ONE if weight>=0 else ZERO); drawing.add_child(node)

func redraw() -> void:
    for child in drawing.get_children(): drawing.remove_child(child); child.queue_free()
    for i in model.data.size():
        dot(place(model.data[i],0.94),ONE if model.labels[i]==1 else ZERO,0.032)
        label(str(model.labels[i]),place(model.data[i],1.16))
    label("INPUTS x1 / x2\nSmall dots: supplied labels",Vector3(-1.05,1.5,-0.75))
    var f := model.forward(probe)
    var inputs := [Vector3(0,1.9,-0.7),Vector3(0,1.25,-0.7)]
    var hidden := [Vector3(0.75,2.2,-0.7),Vector3(0.75,1.6,-0.7),Vector3(0.75,1,-0.7)]
    var output := Vector3(1.5,1.6,-0.7)
    for j in 3:
        for i in 2: wire(inputs[i],hidden[j],model.weights[2*j+i])
        wire(hidden[j],output,model.weights[9+j])
    for i in 2:
        var value: float = probe[i]
        dot(inputs[i],ONE if value>=0 else ZERO)
        label("x%d %.2f"%[i+1,value],inputs[i]+Vector3(0,0.17,0.02))
    for j in 3:
        var value: float = f.hidden[j]
        dot(hidden[j],(ONE if value>=0 else ZERO).darkened(0.6*(1-absf(value))))
        label("h%d %.2f"%[j,value],hidden[j]+Vector3(0,0.17,0.02))
    dot(output,ZERO.lerp(ONE,f.p),0.09)
    label("p(1) %.3f"%f.p,output+Vector3(0,0.24,0.02))
    label("Wire colour: sign / width: |weight|\nNode values: this input's activations",Vector3(0.8,0.77,-0.7),18)
    var heldout := "CHECK: four separate positions not yet measured"
    if not check_result.is_empty(): heldout = "CHECK loss %.4f / %d of 4 correct"%[check_result.loss,check_result.correct]
    readout.text = "%s / epoch %d / train loss %.4f / labels flipped %s\nw0 %.4f / last update %+.5f\n%s"%[
        "TRAINING" if running else "PAUSED",model.epoch,model.loss(),model.flipped,model.weights[0],model.last_change,heldout]
    if not point.held(): point.global_position = to_global(place(probe))

func command(word: String) -> void:
    if point.held(): return
    var was_running := running; running = false
    match word:
        "STEP": model.train_epoch(); check_result.clear()
        "TRAIN": running = not was_running and model.epoch<Model.LIMIT
        "RESET": model.reset(); check_result.clear()
        "EXAMPLE": example = (example+1)%model.data.size(); probe = model.data[example]
        "CHECK": check_result = model.check_fresh()
        "FLIP": model.flip_labels(); check_result.clear()
    redraw()

func _physics_process(_delta: float) -> void:
    if not point.held(): point.global_position = to_global(place(probe))

func _process(_delta: float) -> void:
    if point.held():
        running = false; was_held = true
        var hand := to_local(point.global_position)
        probe = Vector2(clampf((hand.x+1.05)/0.78,-1,1),clampf(hand.z/0.78,-1,1))
        redraw()
    elif was_held:
        was_held = false; redraw()
    elif running:
        check_result.clear()
        for i in 10:
            if not model.train_epoch(): running = false; break
        redraw()
