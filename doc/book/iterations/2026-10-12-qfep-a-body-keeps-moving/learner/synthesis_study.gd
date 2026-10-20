extends "bench.gd"
const Mapping = preload("morphology_map.gd")
const LOW := 1.12
const TRAVEL := 0.48
var model := Mapping.new()
var selected := 0
var body: SoftBody3D
var state_label: Label3D
var built_stiffness := 0.5

func _ready() -> void:
    start("A BODY RECEIVES THE MAPPING",["LAMBDA","PHI","PULSE / STEADY","NUDGE","KEEP"],
        [select.bind(0),select.bind(1),toggle,nudge,keep])
    block(self,Vector3(-1.12,LOW+TRAVEL/2,0.04),Vector3(0.018,TRAVEL,0.018),Color("526071"))
    # Six fixed boundaries; the thin frame makes the invisible collision box visible.
    boundary(Vector3(0.4,0.99,0),Vector3(1.1,0.02,0.9))
    boundary(Vector3(0.4,1.65,0),Vector3(1.1,0.02,0.9))
    boundary(Vector3(-0.15,1.32,0),Vector3(0.02,0.66,0.9))
    boundary(Vector3(0.95,1.32,0),Vector3(0.02,0.66,0.9))
    boundary(Vector3(0.4,1.32,-0.45),Vector3(1.1,0.66,0.02))
    boundary(Vector3(0.4,1.32,0.45),Vector3(1.1,0.66,0.02))
    block(self,Vector3(0.4,0.99,0),Vector3(1.1,0.02,0.9),Color("b8b0a6"))
    for y: float in [1.0,1.64]:
        for z: float in [-0.45,0.45]:
            block(self,Vector3(0.4,y,z),Vector3(1.1,0.012,0.012),Color("526071"))
        for x: float in [-0.15,0.95]:
            block(self,Vector3(x,y,0),Vector3(0.012,0.012,0.9),Color("526071"))
    for x: float in [-0.15,0.95]:
        for z: float in [-0.45,0.45]:
            block(self,Vector3(x,1.32,z),Vector3(0.012,0.64,0.012),Color("526071"))
    body = SoftBody3D.new()
    var sphere := SphereMesh.new()
    sphere.radius = 0.16
    sphere.height = 0.32
    sphere.radial_segments = 16
    sphere.rings = 12
    body.mesh = sphere
    body.position = Vector3(0.4,1.34,0)
    body.total_mass = 0.5
    body.simulation_precision = 8
    body.collision_layer = 2
    body.collision_mask = 1
    var material := StandardMaterial3D.new()
    material.albedo_color = Color("ac7fd0")
    material.roughness = 0.45
    body.material_override = material
    model.apply_to(body)
    built_stiffness = body.linear_stiffness
    add_child(body)
    state_label = label(self,"",Vector3(-0.91,1.71,0.15),20)
    label(self,"FIXED BOUNDARY / soft sphere",Vector3(0.4,1.04,0.52),17)
    redraw()

func boundary(at: Vector3, size: Vector3) -> void:
    var wall := StaticBody3D.new()
    wall.position = at
    wall.collision_layer = 1
    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = size
    collision.shape = shape
    wall.add_child(collision)
    add_child(wall)

func _process(_delta: float) -> void:
    if point == null: return
    if point.held():
        var fraction := clampf((to_local(point.global_position).y-LOW)/TRAVEL,0.0,1.0)
        model.set_value(selected,fraction if selected == 0 else 2.0*fraction-1.0)
        model.apply_to(body)
    redraw()

func _physics_process(delta: float) -> void:
    super._physics_process(delta)
    if body == null: return
    model.advance(delta)
    model.apply_to(body)

func select(term: int) -> void:
    if point.held(): return
    selected = term
    redraw()

func toggle() -> void:
    if point.held(): return
    model.toggle()
    model.apply_to(body)
    redraw()

func nudge() -> void:
    if point.held(): return
    body.apply_central_impulse(global_basis*Vector3(0.08,0.04,0))

func keep() -> void:
    if point.held(): return
    model.keep()
    redraw()

func redraw() -> void:
    var r := model.reading()
    var fraction: float = r.values[0] if selected == 0 else (r.values[1]+1.0)*0.5
    point_home = Vector3(-1.12,LOW+fraction*TRAVEL,0.22)
    state_label.text = "L %.2f / P %+.2f" % r.values
    var kept := "KEEP: no settings kept"
    if not model.kept.is_empty():
        kept = "Kept L %.2f / P %+.2f / settings only" % model.kept.values
    readout.text = "%s / hand edits %s\nStiffness request %.3f / built %.3f / damping %.3f\nPressure base %.3f / now %.3f\nDrag request %.3f / engine %.3f (unused)\n%s" % [
        "PULSE" if r.active else "STEADY","LAMBDA" if selected == 0 else "PHI",
        body.linear_stiffness,built_stiffness,body.damping_coefficient,
        r.baseline,body.pressure_coefficient,r.drag,body.drag_coefficient,kept]
