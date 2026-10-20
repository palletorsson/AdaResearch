extends Node3D
const Fit = preload("line_fit.gd")
const PointBody = preload("point_body.gd")
const Rack = preload("res://commons/audio/rack_templates/RackTemplates.gd")
var fit := Fit.new()
var point: PointBody
var running := false
var clock := 0.0
var outlier := false
var was_held := false
var terrain := MeshInstance3D.new()
var plot := Node3D.new()
var readout := Label3D.new()

func _ready() -> void:
    add_child(terrain); add_child(plot)
    readout.position = Vector3(0.1, 2.95, -0.7)
    readout.font_size = 28; readout.pixel_size = 0.0025
    add_child(readout)
    var backing := MeshInstance3D.new(); var slab := BoxMesh.new()
    slab.size = Vector3(1.95, 2.4, 0.04); backing.mesh = slab
    backing.position = Vector3(-1.35, 1.65, -0.85)
    backing.material_override = material(Color("161d2b")); add_child(backing)
    label("OBSERVATIONS / x and y", Vector3(-1.35, 2.6, -0.79))
    label("PARAMETERS / slope across, intercept towards you\nHeight = 0.025 x loss; no gravity", Vector3(0.95, 0.65, 0.5))
    point = PointBody.new(); add_child(point)
    var words := ["STEP", "RUN", "RESET", "MSE", "HUBER", "OUTLIER", "SLOW", "LARGE"]
    var rows: Array = []
    for r in 2:
        var row: Array = []
        for c in 4: row.append({"type":"button", "label":words[r*4+c]})
        rows.append(row)
    var panel := Rack.create_panel("FIT ONE LINE", rows)
    panel.position = Vector3(0, 1.05, 1.3); panel.rotation_degrees.x = -30
    panel.scale = Vector3.ONE*2; add_child(panel)
    for mesh in panel.find_children("*", "MeshInstance3D", true, false):
        var m := mesh.material_override as BaseMaterial3D
        if m != null:
            m = m.duplicate(); m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
            mesh.material_override = m
    for i in words.size():
        var button = panel.find_child("Btn_%d" % i, true, false).get_node("InteractableAreaButton")
        button.button_pressed.connect(func(_area):command(words[i]))
    rebuild_surface(); redraw()

func label(text: String, where: Vector3) -> void:
    var node := Label3D.new(); node.text = text; node.position = where
    node.font_size = 22; node.pixel_size = 0.002; add_child(node)

func surface_position(q: Vector2) -> Vector3:
    return Vector3(0.95+q.x*0.26, 0.9+fit.loss(q)*0.025, q.y*0.26)

func plot_position(sample: Vector2) -> Vector3:
    return Vector3(-1.35+sample.x*0.8, 1.65+sample.y*0.18, -0.8)

func material(colour: Color) -> StandardMaterial3D:
    var m := StandardMaterial3D.new(); m.albedo_color = colour
    m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    m.cull_mode = BaseMaterial3D.CULL_DISABLED
    return m

func rod(a: Vector3, b: Vector3, colour: Color, radius: float = 0.009) -> void:
    var d := b-a
    if d.length() < 0.00001: return
    var mesh := CylinderMesh.new(); mesh.top_radius = radius; mesh.bottom_radius = radius
    mesh.height = d.length(); mesh.radial_segments = 8
    var node := MeshInstance3D.new(); node.mesh = mesh; node.position = (a+b)*0.5
    node.quaternion = Quaternion(Vector3.UP, d.normalized())
    node.material_override = material(colour); plot.add_child(node)

func rebuild_surface() -> void:
    var st := SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for z in 24:
        for x in 24:
            for offset: Vector2 in [Vector2(0,0),Vector2(1,0),Vector2(1,1),Vector2(0,0),Vector2(1,1),Vector2(0,1)]:
                var q := Vector2(-3+(x+offset.x)*0.25, -3+(z+offset.y)*0.25)
                st.set_color(Color("57bbc8") if (x+z)%2==0 else Color("326979"))
                st.add_vertex(surface_position(q))
    st.generate_normals(); terrain.mesh = st.commit()
    var m := material(Color.WHITE); m.vertex_color_use_as_albedo = true
    terrain.material_override = m

func redraw() -> void:
    for child in plot.get_children(): plot.remove_child(child); child.queue_free()
    rod(plot_position(Vector2(-1.1,0)), plot_position(Vector2(1.1,0)), Color.GRAY)
    rod(plot_position(Vector2(0,-6)), plot_position(Vector2(0,6)), Color.GRAY)
    rod(plot_position(Vector2(-1,fit.prediction(fit.p,-1))), plot_position(Vector2(1,fit.prediction(fit.p,1))), Color("60e3df"), 0.015)
    for sample in fit.data:
        var mesh := SphereMesh.new(); mesh.radius = 0.028; mesh.height = 0.056
        var node := MeshInstance3D.new(); node.mesh = mesh; node.position = plot_position(sample)
        node.material_override = material(Color("ffbc68")); plot.add_child(node)
        rod(node.position, plot_position(Vector2(sample.x,fit.prediction(fit.p,sample.x))), Color("e26ba2"), 0.006)
    if not point.held(): point.global_position = to_global(surface_position(fit.p)+Vector3.UP*0.085)
    readout.text = "%s / outlier %s / rate %.2f / steps %d\nslope %.3f / intercept %.3f / loss %.4f\n%s" % [
        "HUBER delta 1" if fit.robust else "MSE", outlier, fit.rate, fit.steps,
        fit.p.x, fit.p.y, fit.loss(fit.p), "RUNNING" if running else fit.status]

func command(word: String) -> void:
    if point.held(): return # Put the parameter point down before starting descent.
    var was_running := running
    running = false; clock = 0.0
    match word:
        "STEP": fit.step()
        "RUN": running = not was_running
        "RESET": fit.reset()
        "MSE": fit.robust = false; fit.steps = 0; fit.status = "SAME PARAMETERS"; rebuild_surface()
        "HUBER": fit.robust = true; fit.steps = 0; fit.status = "SAME PARAMETERS"; rebuild_surface()
        "OUTLIER": outlier = not outlier; fit.set_outlier(outlier); rebuild_surface()
        "SLOW": fit.rate = 0.1; fit.status = "RATE CHANGED"
        "LARGE": fit.rate = 1.5; fit.status = "RATE CHANGED"
    redraw()

func _physics_process(_delta: float) -> void:
    if not point.held():
        point.global_position = to_global(surface_position(fit.p)+Vector3.UP*0.085)

func _process(delta: float) -> void:
    if point.held():
        running = false; clock = 0.0; was_held = true
        var hand := to_local(point.global_position)
        fit.p = Vector2(clampf((hand.x-0.95)/0.26,-3,3), clampf(hand.z/0.26,-3,3))
        fit.steps = 0; fit.status = "HAND CHOOSES PARAMETERS"; redraw()
    elif was_held:
        was_held = false; redraw()
    elif running:
        clock += delta
        while clock >= 0.15 and running:
            clock -= 0.15
            running = fit.step()
        redraw()
