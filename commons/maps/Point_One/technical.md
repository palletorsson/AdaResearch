# Point One

Euclid defined a point as "that which has no part." The floating text in this map says it plainly: *that_which_has_no_part*. This is not poetry. It is the most precise technical specification in the history of mathematics. A point has position. It has nothing else — no length, no width, no depth, no duration. It exists only as a location.

In Godot 4, a point is a Vector3.

```gdscript
var p = Vector3(1.0, 0.0, 0.0)
```

Three floats. A single position beyond the zero reference.

This map demonstrates two versions of the same concept: a point you can hold, and a point that cannot be moved. Before either exists, the infrastructure must be in place. You didn't build it. It was already running when you arrived.

---

## The Coordinate System Is Already Running

When you enter Point_One, the coordinate system is active. Three meter-long axes — X red, Y green, Z blue — establish the right-handed frame that every operation in this sequence assumes. The `CoordinateSystem3M` artifact makes the implicit explicit: the frame precedes the measurement. Before any point can have a coordinate, the system that assigns coordinates must exist and be agreed upon.

```gdscript
# From CoordinateSystem3M.gd
func create_axis(direction: Vector3, color: Color, label_text: String) -> void:
    var mesh_instance = MeshInstance3D.new()
    var mesh = CylinderMesh.new()
    mesh.height = axis_length          # 3.0 meters
    mesh_instance.mesh = mesh
    mesh_instance.position = direction * (axis_length / 2.0)

    # Cylinder is Y-aligned by default — rotate it to match each direction
    if direction != Vector3.UP:
        var up = Vector3.UP
        var axis = up.cross(direction).normalized()
        var angle = up.angle_to(direction)
        mesh_instance.rotate(axis, angle)

    add_child(mesh_instance)
```

The gyroscope gadget attached to the system shows your orientation relative to the axes in real time. Right-handed vs left-handed, Y-up vs Z-up — these are conventions, not laws. OpenGL uses Y-up, right-handed. Vulkan uses Y-down. Godot 4 uses Y-up, right-handed. The coordinate system you're standing in is a choice that was made before you arrived. Standing inside `CoordinateSystem3M`, you are standing inside that choice made visible.

The info panel displays: `P = (x, y, z)`. Every point in this space is fully described by three numbers. Nothing more is required. A point is not an object with material properties, physics, or behavior. It is a triple of coordinates in the agreed frame.

---

## What a Point Is

A Vector3 is not a sphere. It is not a mesh. It has no geometry. It is not visible. It is three floats — 12 bytes — encoding a position in the coordinate frame.

```gdscript
# These are all points — pure position data
var at_origin    : Vector3 = Vector3(0, 0, 0)
var unit_x       : Vector3 = Vector3(1.0, 0.0, 0.0)
var arbitrary    : Vector3 = Vector3(1.5, 0.8, -0.3)
var named_zero   : Vector3 = Vector3.ZERO   # same as at_origin

# The distance from origin is the length of the vector
var distance : float = arbitrary.length()   # sqrt(1.5² + 0.8² + 0.3²) ≈ 1.75
```

The sphere you see in this map is the *representation* of a point — a visual artifact that makes the mathematical object perceivable. The point itself is dimensionless. This distinction is not pedantic. In code, the point is the data. The sphere is the rendering. They are separate things, joined by assignment. You can reposition the data without updating the mesh, or rebuild the mesh without touching the underlying Vector3. Understanding this separation is the foundation of every rendering system you will encounter.

The `la:point` annotation in the map at position (1,3) names a conceptual location. The annotation is not the point. It marks where the concept lives.

---

## The Static Point: Fixed Reference

On the isolated cube at grid position (4,0), there is a point that cannot be grabbed. This is `static_point`.

```gdscript
# From static_point.gd
extends Node3D

@export var point_color: Color = Color(0.0, 1.0, 1.0, 1.0)
@export var point_radius: float = 0.04
@export var show_label: bool = true

func _ready():
    add_to_group("no_gravity_gun")  # mechanism that prevents pickup
    _setup_mesh()
    if show_label:
        _setup_label()

func _setup_mesh():
    var sphere = SphereMesh.new()
    sphere.radius = point_radius
    sphere.height = point_radius * 2
    mesh_instance.mesh = sphere

func _process(_delta):
    if position_label and show_label:
        position_label.text = "(%.1f, %.1f, %.1f)" % [
            global_position.x,
            global_position.y,
            global_position.z
        ]
```

The `no_gravity_gun` group membership is the implementation of immovability. The point still knows where it is — `_process` reads and displays its coordinates every frame. It simply cannot be relocated. This is the distinction between a reference point and a free point.

In mathematics, reference points define the frame. In code, they are constants. The static point at (4, 0, z) demonstrates that position is a property of a location in space, not a property of the object marking it. The coordinates exist whether or not a sphere is drawn there. The sphere makes the position legible to a person standing in the room.

Notice that `_process` runs unconditionally — the label updates every frame even though the value never changes. This is the engine's frame loop doing its work regardless of whether anything moved. Later, when you work with moving objects, this same loop becomes essential. Here it idles. The pattern is the same.

---

## The Interactive Point: Holding a Coordinate

At position (1,3), the `interactive_point_origin` can be picked up. When held, two things happen: a label shows its current coordinates, and a line appears connecting it to the world origin.

```gdscript
# From interactive_point_origin.gd
func _on_picked_up(_pickable) -> void:
    # Cycle display format on each pickup event
    _display_format_index = (_display_format_index + 1) % 4
    _is_held = true
    if _position_label:
        _position_label.visible = true
    if _line_mesh_instance:
        _line_mesh_instance.visible = true

func _update_position_label() -> void:
    var pos = global_position
    match _display_format_index:
        0: _position_label.text = "(%.2f, %.2f, %.2f)" % [pos.x, pos.y, pos.z]
        1: _position_label.text = "(x:%.2f, y:%.2f, z:%.2f)" % [pos.x, pos.y, pos.z]
        2: _position_label.text = "Vector3(%.2f, %.2f, %.2f)" % [pos.x, pos.y, pos.z]
        3: _position_label.visible = false
```

Each pickup cycles through four representations of the same position. This encodes a lesson in the interaction itself: representation and value are separate. The coordinate `(1.5, 0.8, -0.3)` is identical whether written as a tuple, as named components, as a Vector3 constructor call, or hidden entirely. The point doesn't change. Only the notation does.

The haptic pulse fires on pickup before the label updates. The body registers a format-change event before the eyes read it. This ordering is not accidental — embodied learning works through sensation first, conceptualization second.

When you drop the point, both the label and the line disappear. The coordinates still exist — `global_position` still holds a value. But without the label, the position is invisible. This is the difference between data and display, made felt through the act of letting go.

---

## The Line to Origin: Making Distance Visible

While the interactive point is held, a thin cyan cylinder connects it to `Vector3.ZERO`. This line is not decorative. It visualizes what a coordinate *is*: a displacement from the reference.

```gdscript
# From interactive_point_origin.gd
func _update_line_to_origin() -> void:
    var current_pos : Vector3 = global_position
    var direction   : Vector3 = origin_point - current_pos
    var distance    : float   = direction.length()

    if distance < 0.001:
        _line_mesh_instance.visible = false
        return

    _line_mesh_instance.visible = true

    # The cylinder height IS the distance — geometry and measurement unified
    if absf(distance - _last_line_distance) > 0.0005:
        _line_cylinder.height = distance
        _last_line_distance = distance

    # Position the cylinder at the midpoint between point and origin
    var midpoint : Vector3 = (current_pos + origin_point) / 2.0
    _line_mesh_instance.global_position = midpoint

    # Orient toward origin
    _line_mesh_instance.look_at(origin_point, Vector3.UP)
    _line_mesh_instance.rotate_object_local(Vector3.RIGHT, PI / 2.0)
```

The cylinder's height equals `direction.length()` — Euclidean distance from the held point to world origin. As you move the point, the line stretches and rotates. You are watching `d = sqrt(x² + y² + z²)` happen in real time.

Hold the point at (1, 0, 0): the line is 1 unit long, aligned with the X axis. Move to (1, 1, 0): the line is √2 units, angled 45°. Move to (1, 1, 1): the line is √3 units. The Pythagorean theorem becomes a felt measurement. The coordinate is not just a label — it is a distance from the origin in three directions at once.

The `_last_line_distance` variable tracks the previous cylinder height. The mesh only regenerates when the distance changes by more than 0.0005 units. This is a performance optimization — rebuilding geometry every frame for imperceptible changes wastes GPU time. Even in a tutorial artifact, the implementation teaches: measure whether work is necessary before doing it.

---

## Building a Point from Code

The `script_runner#point` at (0,1) runs live GDScript demonstrating point construction. The `code_evolution_screen` at (3,5) stages the same construction step by step, with a parallel panel showing the reasoning behind each line.

Here is that progression:

```gdscript
# Stage 1: The data — a position in space
var position = Vector3(4.0, 1.0, 0.0)
# This is the complete point. Everything below is rendering.

# Stage 2: Create a mesh at that position
var mesh_instance = MeshInstance3D.new()
var sphere = SphereMesh.new()
sphere.radius = 0.04
sphere.height = 0.08
mesh_instance.mesh = sphere
mesh_instance.position = position
add_child(mesh_instance)

# Stage 3: Give the GPU a material to render it with
var material = StandardMaterial3D.new()
material.albedo_color = Color(0.0, 1.0, 1.0)  # cyan
material.emission_enabled = true
material.emission = material.albedo_color
material.emission_energy_multiplier = 1.5
mesh_instance.material_override = material

# Stage 4: Make the position legible to a reader
var label = Label3D.new()
label.text = "(%.1f, %.1f, %.1f)" % [position.x, position.y, position.z]
label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
label.position = position + Vector3(0, 0.1, 0)
add_child(label)
```

Four stages. At stage one, the point exists. Everything else is apparatus — geometry, color, language. Each stage adds legibility, not reality. The point at stage four is not more of a point than it was at stage one. It is only more visible.

The `code_evolution_screen` shows both panels simultaneously: the code as it stands at each stage, and the conceptual intent alongside it. The dual-panel design is a claim about learning: seeing the code and reading the reasoning are different cognitive acts. Doing both at once builds the habit of asking *why* when you read *what*.

---

## The Dark Sphere: Ambient Hierarchy

At (3,2), the `dark_sphere` floats and pulses slowly. It does not demonstrate the point concept.

```gdscript
# From dark_sphere.gd
func _process(delta: float) -> void:
    _time_elapsed += delta
    if _sphere_mesh:
        _sphere_mesh.rotation.y += rotation_speed * delta
        _sphere_mesh.rotation.x = sin(_time_elapsed * 0.4) * 0.05
    if _sphere_material:
        var pulse_t := (sin(_time_elapsed * pulse_speed) + 1.0) * 0.5
        _sphere_material.emission_energy_multiplier = lerpf(pulse_min, pulse_max, pulse_t)
```

The sphere breathes. It provides rhythm and spatial depth. When everything in a map is equally bright and active, nothing reads — visual hierarchy collapses. The dark sphere stays dim so the interactive point can be primary. Its emission oscillates between 0.05 and 0.35, staying below the interactive point's 2.0 emission energy. The difference is not accidental — it is the ratio that makes the primary artifact legible against the ambient environment.

This is design at the implementation level: emission values are tuned ratios, not aesthetic preferences.

---

## Position Without Extension

A point occupies no space. A Vector3 occupies 12 bytes. The sphere that represents it occupies a volume with radius 0.04 units. These are three different facts about three different things.

The map stages the core distinction as a contrast. The interactive point can be grabbed and dragged; the static point cannot. Both display their coordinates. Neither is the point concept — they are renderings of it. The concept is the Vector3: three numbers, a position in the agreed frame.

"That which has no part" is computationally exact. A Vector3 has no shape, no physics body, no surface, no color. It has a position, expressed in the coordinate frame that `CoordinateSystem3M` instantiated before you arrived. Everything else — the sphere mesh, the emissive material, the label, the line to origin, the haptic pulse — is the apparatus of legibility.

The origin cycles through its aliases: `Vector3.ZERO`, `origin`, `(0,0,0)`, `World origin`. Each name describes the same location. The origin is a convention. The coordinate is a measurement from that convention. Move the point and the line changes length — the measurement updates. The convention stays fixed.

In the next map, Point_Line, two of these positions will be connected. The line between them is not stored anywhere — it is computed from their coordinates as the difference between two points, scaled by a parameter. The point is the atom. The line is the first relation. But a relation requires two positions, and two positions require the frame, and the frame requires a convention about where zero is. The infrastructure was already running. Now you know why.

---

## Possible Artifacts

**xyz_slider_plate** — Three independent sliders controlling X, Y, and Z independently, driving a visible point in real time. The artifact already exists in commons (`xyz_slider_plate.gd`) but is not placed in this map. Grabbing the interactive point changes all three coordinates simultaneously — the hand's natural motion couples them. The slider plate forces the learner to move one axis at a time, making orthogonality visceral. Moving the X slider doesn't move Y. This is a distinct insight that the current artifacts don't isolate.

**distance_readout** — A persistent numerical label showing the live distance from the interactive point to origin: `d = sqrt(x² + y² + z²)`. The line shows the distance geometrically; a number would close the loop to the formula. The learner would see geometry and algebra correspond as the point moves. Currently only the line is shown; the formula is implied.

**axis_projection_markers** — Small fixed spheres on each axis showing the (x, 0, 0), (0, y, 0), and (0, 0, z) projections of the held point's position, updating as it moves. The held point is the combination of three independent measurements; the projection markers would show each measurement as a separate object. This directly sets up the component decomposition that becomes essential in Point_Line, where direction vectors are built from axis-aligned components.