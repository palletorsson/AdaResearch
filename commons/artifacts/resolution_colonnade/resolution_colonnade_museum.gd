extends Node3D
## Museum installation: compare one parameter at a time before entering the grove.
## The host provides floor, walls, sky, lighting and the visitor. Local x=0 is a
## continuous 2.14 m clear aisle; entrance is -Z and the continuation is +Z.

const Totem = preload("resolution_totem.gd")
const Gallery = preload("gallery.gd")
const COUNTS: Array[int] = [4, 6, 8, 12, 16]
const X_POSITIONS: Array[float] = [-10.0, -6.0, -2.0, 2.0, 6.0]
const PLINTH_WIDTH := 1.86
const PLINTH_HEIGHT := 0.22
var columns: Array[Node3D] = []


func _ready() -> void:
    # The entry row isolates radial sampling from profile, height and width.
    for col in COUNTS.size():
        _column("Sides_%02d" % COUNTS[col], Vector3(X_POSITIONS[col], 0, -10),
            COUNTS[col], 8, 0, 4.67, 1.0, "SIDES CHANGE")

    # The remaining four rows retain twenty authored bodies at full size.
    # The original twenty-five-body arrangement stays in the standalone scene.
    for row in range(1, COUNTS.size()):
        for col in COUNTS.size():
            var kind := (row + col) % Totem.PROFILE_NAMES.size()
            var width: float = [1.0, 0.92, 1.02, 0.96, 1.0][(row * 2 + col) % 5]
            _column("Grove_%02d_%02d" % [COUNTS[col], COUNTS[row]],
                Vector3(X_POSITIONS[col], 0, -10 + 5 * row),
                COUNTS[col], COUNTS[row], kind, Gallery.HEIGHTS[row][col], width,
                Totem.PROFILE_NAMES[kind].to_upper())

    _panel("RINGS OF ASH\nSAME PROFILE, HEIGHT AND WIDTH\nFirst row: 4, 6, 8, 12 and 16 sides.\nProfile divisions stay at 8. Follow one change.",
        Vector3(-6.0, 1.32, -13.0))
    _panel("FIVE PROFILES / TWENTY VARIED BODIES\nBeyond this point, shape, height and width also vary.\nWalk around a body before comparing its numbers.\nThe same rules can carry another form.",
        Vector3(6.0, 1.32, -7.0))


func _column(node_name: String, at: Vector3, sides: int, rings: int,
        kind: int, metres: float, width: float, caption: String) -> void:
    var column := Totem.new()
    column.name = node_name
    column.radial_segments = sides
    column.profile_rings = rings
    column.profile_kind = kind
    column.column_height = metres
    column.width_factor = width
    column.collisions = true
    column.position = at + Vector3.UP * PLINTH_HEIGHT
    add_child(column)
    columns.append(column)
    _box("Plinth_" + node_name, Vector3(PLINTH_WIDTH, PLINTH_HEIGHT, PLINTH_WIDTH),
        at + Vector3.UP * PLINTH_HEIGHT * 0.5, Color("ded4c0"), true)
    _box("Plaque_" + node_name, Vector3(1.78, 0.48, 0.035),
        at + Vector3(0, 0.47, -0.95), Color("29272b"), false)
    _label("%s / %.2f M\n%02d SIDES / %02d PROFILE DIVISIONS" % [caption, metres, sides, rings],
        at + Vector3(0, 0.47, -0.971), 0.00165, 22)


func _panel(words: String, at: Vector3) -> void:
    _box("ReadingPanel", Vector3(4.2, 0.86, 0.08), at, Color("29272b"), true)
    _box("ReadingPanelSupport", Vector3(0.10, at.y - 0.43, 0.10),
        Vector3(at.x, (at.y - 0.43) * 0.5, at.z), Color("af8854"), true)
    _label(words, at + Vector3(0, 0, -0.045), 0.0025, 25)


func _box(node_name: String, size: Vector3, at: Vector3, colour: Color, solid: bool) -> void:
    var instance := MeshInstance3D.new()
    instance.name = node_name
    var mesh := BoxMesh.new()
    mesh.size = size
    instance.mesh = mesh
    var material := StandardMaterial3D.new()
    material.albedo_color = colour
    material.roughness = 0.8
    instance.material_override = material
    instance.position = at
    add_child(instance)
    if solid:
        var body := StaticBody3D.new()
        body.collision_layer = 1
        body.collision_mask = 0
        var collision := CollisionShape3D.new()
        var shape := BoxShape3D.new()
        shape.size = size
        collision.shape = shape
        body.add_child(collision)
        instance.add_child(body)


func _label(words: String, at: Vector3, pixel_size: float, font_size: int) -> void:
    var label := Label3D.new()
    label.text = words
    label.position = at
    label.rotation.y = PI
    label.pixel_size = pixel_size
    label.font_size = font_size
    label.outline_size = 0
    label.modulate = Color("ead5ae")
    add_child(label)
