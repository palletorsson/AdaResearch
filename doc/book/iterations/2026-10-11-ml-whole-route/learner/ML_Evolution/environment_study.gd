extends Node3D
const Population = preload("population.gd")
const PointBody = preload("point_body.gd")
# Supplied museum buttons; learning logic is entirely in these two new files.
const Rack = preload("res://commons/audio/rack_templates/RackTemplates.gd")
var world := Population.new()
var seed_value := 17
var playing := false
var accumulator := 0.0
var point: PointBody
var title := Label3D.new()
var tiles: Array[StandardMaterial3D] = []
var views: Dictionary = {}

func _ready() -> void:
    var table := BoxMesh.new(); table.size = Vector3(2.2, 0.10, 2.2)
    mesh_at(table, Vector3(0, 1.0, 0), Color("161c28"))
    for z in Population.SIDE:
        for x in Population.SIDE:
            var tile := BoxMesh.new(); tile.size = Vector3(0.23, 0.012, 0.23)
            var view := mesh_at(tile, Vector3(-0.875+x*0.25, 1.06, -0.875+z*0.25), Color.WHITE)
            tiles.append(view.material_override)
    title.position = Vector3(0, 1.85, -1.0)
    title.font_size = 26; title.pixel_size = 0.002
    add_child(title)
    point = PointBody.new(); point.position = Vector3(1.23, 1.2, 0.8)
    add_child(point)
    point.action_pressed.connect(func(_p):command("RUN"))
    var rows: Array = []; var words: Array = []
    for names in [["RUN", "STEP", "RESET"], ["FINITE", "RETURN", "NEXT SEED"]]:
        var row: Array = []
        for word in names:
            row.append({"type":"button", "label":word}); words.append(word)
        rows.append(row)
    var panel := Rack.create_panel("WHAT KEEPS A BODY?", rows)
    panel.position = Vector3(0, 1.05, 1.38); panel.rotation_degrees.x = -30
    panel.scale = Vector3.ONE * 2; add_child(panel)
    for i in words.size():
        var button = panel.find_child("Btn_%d" % i, true, false).get_node("InteractableAreaButton")
        button.button_pressed.connect(func(_area):command(words[i]))
    reset(false)

func mesh_at(mesh: Mesh, p: Vector3, colour: Color) -> MeshInstance3D:
    var view := MeshInstance3D.new(); view.mesh = mesh; view.position = p
    var material := StandardMaterial3D.new(); material.albedo_color = colour
    view.material_override = material; add_child(view)
    return view

func reset(renew: bool) -> void:
    playing = false; accumulator = 0.0
    world.reset(seed_value, renew)
    for view in views.values(): remove_child(view); view.queue_free()
    views.clear(); redraw()

func command(word: String) -> void:
    match word:
        "RUN": playing = not playing
        "STEP": playing = false; accumulator = 0.0; world.step()
        "RESET": reset(world.renewal)
        "FINITE": reset(false)
        "RETURN": reset(true)
        "NEXT SEED": seed_value += 1; reset(world.renewal)
    redraw()

func _process(delta: float) -> void:
    if playing:
        accumulator += delta
        while accumulator >= Population.DT:
            world.step(); accumulator -= Population.DT
        if world.bodies.is_empty(): playing = false
        redraw()

func redraw() -> void:
    for i in tiles.size():
        tiles[i].albedo_color = Color("a3c8aa") if world.available(i) else Color("303747")
    var living: Dictionary = {}
    for body: Dictionary in world.bodies:
        living[body.id] = true
        if not views.has(body.id):
            var sphere := SphereMesh.new(); sphere.radius = 0.045; sphere.height = 0.09
            sphere.radial_segments = 12; sphere.rings = 6
            views[body.id] = mesh_at(sphere, Vector3.ZERO, Color.from_hsv(body.family/12.0, 0.65, 0.95))
        views[body.id].position = Vector3(body.p.x, 1.115, body.p.y)
    for id in views.keys():
        if not living.has(id):
            remove_child(views[id]); views[id].queue_free(); views.erase(id)
    title.text = "%s / seed %d / %.1f seconds\nAlive %d / born %d / died %d / meals %d\n%s / colour = ancestry, not fitness" % [
        "RETURN: food regrows in 4 s" if world.renewal else "FINITE: each cell pays once",
        seed_value, world.ticks*Population.DT, world.bodies.size(), world.born, world.died,
        world.meals, "RUNNING" if playing else "PAUSED"]
