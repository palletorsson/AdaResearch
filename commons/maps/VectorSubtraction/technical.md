# Compact gallery for vector subtraction visualization

## From Addition to Difference

In VectorBasics we built the grammar: a vector has components, a magnitude, a direction. Three numbers — `(x, y, z)` — encode a position or a displacement. The magnitude `√(x² + y² + z²)` gives length. The unit vector gives pure direction. That was the vocabulary.

Now the first operation that matters. Not addition — subtraction. Addition combines. Subtraction separates. It answers the question every navigation system, every physics engine, every AI agent must answer: *what is the distance and direction from here to there?*

```gdscript
var a = Vector3(3, 2, 1)
var b = Vector3(1, 4, 0)
var difference = a - b  # Vector3(2, -2, 1)
```

Three lines. The result `(2, -2, 1)` is a new vector — the displacement from `b` to `a`. It tells you: move 2 units in x, -2 in y, 1 in z, and you travel from `b`'s position to `a`'s position. Component by component, subtraction computes what separates two states.

The `vector_subtraction_demo.gd` artifact builds this into a spatial experience. Two vectors, `vector_a` and `vector_b`, anchored at the origin. A third vector — the result — drawn between them. The geometry makes the algebra visible.

```gdscript
@export var vector_a: Vector3 = Vector3(2.0, 1.0, 0.0)
@export var vector_b: Vector3 = Vector3(1.0, 2.0, 0.0)
```

These are the starting conditions. Exported so you can change them live in the inspector or through code. The demo computes `vector_a - vector_b` and renders all three arrows in 3D space, color-coded for legibility.

## The Geometry of Minus

Subtraction has a geometric meaning that addition obscures. When you add two vectors, you place them head-to-tail. The result runs from the first tail to the second head. Clean, intuitive, linear.

Subtraction does something stranger. `A - B` produces the vector that *connects the tips* of `A` and `B` when both are drawn from the same origin. Point `B`'s arrowhead to `A`'s arrowhead — that connecting arrow is the difference vector. It doesn't start at the origin. It starts at `B` and ends at `A`.

```gdscript
# The difference vector
var result = vector_a - vector_b

# Equivalent to:
var result_expanded = Vector3(
    vector_a.x - vector_b.x,
    vector_a.y - vector_b.y,
    vector_a.z - vector_b.z
)
```

The demo draws this with four distinct colors:

```gdscript
@export var color_a: Color       # Vector A — the destination
@export var color_b: Color       # Vector B — the origin
@export var color_neg_b: Color   # Negated B — the ghost
@export var color_result: Color  # A - B — the difference
```

Four arrows, four colors. The `color_neg_b` is critical — it visualizes the negation step that makes subtraction work. Subtraction is addition with a flipped sign. `A - B = A + (-B)`. The demo renders `-B` as a ghost arrow: same magnitude as `B`, opposite direction, drawn translucent so you can see through the operation.

```gdscript
func _create_arrow(arrow_name: String, color: Color, ghost: bool = false) -> Node3D:
    # ghost=true for the negated vector — rendered translucent
```

The `ghost` parameter controls opacity. When `true`, the arrow becomes semi-transparent. You see `B` solid, `-B` ghosted, and the head-to-tail addition of `A + (-B)` producing the result. The algebraic identity becomes spatial fact.

## Negation as Reflection

Negating a vector flips it through the origin. Every component changes sign. The arrow points backward, same length, opposite direction.

```gdscript
var b = Vector3(1, 2, 0)
var neg_b = -b  # Vector3(-1, -2, 0)

# Properties preserved:
assert(b.length() == neg_b.length())       # same magnitude
assert(b.normalized() == -neg_b.normalized())  # opposite direction
```

This is not a minor operation. Negation is the simplest transformation — a reflection through the origin point. In 1D it's just flipping the sign of a number. In 3D it reflects across all three axes simultaneously. The vector `(1, 2, 3)` becomes `(-1, -2, -3)` — diametrically opposite on any sphere centered at the origin.

The demo exploits this visually. The ghost arrow (`color_neg_b`) sits exactly opposite `B`. Place your eye at the origin and `-B` appears behind you when `B` is in front. This is why subtraction works geometrically: negate `B` to get `-B`, then add `A + (-B)` head-to-tail. The result vector emerges naturally from the construction.

```gdscript
# Subtraction decomposed into its two operations
var step_1_negate = -vector_b           # flip B
var step_2_add = vector_a + step_1_negate  # add A + (-B)
# step_2_add == vector_a - vector_b
```

Every subtraction you will ever perform — in physics, in graphics, in AI — executes these two steps. Negate, then add. The computer doesn't distinguish. But understanding the decomposition reveals why the difference vector points from `B` to `A`, not from `A` to `B`. You negate `B` and add it to `A`, so the result is anchored in `A`'s frame, pointing away from where `B` was.

## Building the Visualization

The demo constructs its scene programmatically. No pre-built meshes. Every arrow, every label, every axis line is generated in `_ready()`.

```gdscript
func _ready():
    _create_base()
    _create_coordinate_axes()
    _create_vector_labels()
    _create_arrows()
    _create_handles()
```

Five calls, strict order. The base plane provides ground reference. The coordinate axes establish the 3D frame — three colored lines for x, y, z. Then labels, then arrows, then interactive handles.

The coordinate axes use a helper that draws a line in one direction with a text label at the end:

```gdscript
func _create_axis_line(direction: Vector3, color: Color, label_text: String):
    # Draws a thin line from origin along 'direction'
    # Places label_text at the endpoint
```

This is boilerplate you will write a hundred times in 3D visualization. A line mesh, a material with the given color, a `Label3D` at the tip. The pattern repeats for every arrow in the scene — only the color and endpoints change.

The arrows themselves are more involved. Each arrow is a `Node3D` containing a cylinder (the shaft) and a cone (the arrowhead). The `_create_arrow` function builds one:

```gdscript
func _create_arrow(arrow_name: String, color: Color, ghost: bool = false) -> Node3D:
    # Returns a Node3D with:
    #   - CylinderMesh shaft (radius = arrow_thickness)
    #   - ConeMesh head
    #   - Material with 'color', transparency if ghost=true
```

The `arrow_thickness` export controls shaft radius. For ghost arrows, the material gets alpha transparency — you see the negated vector as a faded echo of the original. This visual language matters. Solid means real. Ghost means constructed — a tool for understanding, not a thing in the world.

Labels attach to each vector with the `_create_text_panel` function:

```gdscript
func _create_text_panel(panel_name: String, text: String, pos: Vector3):
    # Creates a Label3D with a backing panel frame
```

```gdscript
func _add_panel_frame(panel: Node3D, size: Vector2):
    # Adds a rectangular frame behind the label for readability
```

Text in 3D space is hard to read without contrast. The panel frame — a thin rectangle behind the text — solves this. Dark background, light text, always facing the camera. The demo uses this for labeling each vector: "A", "B", "-B", "A - B". Four labels, four panels, no ambiguity about what you're looking at.

## Displacement: The Vector That Matters Most

The difference vector is a displacement. It tells you how to get from one point to another. This is the single most common vector operation in any interactive system.

```gdscript
# Enemy AI: which way to the player?
var displacement = player_position - enemy_position
var direction = displacement.normalized()
var distance = displacement.length()

# Move toward player at constant speed
enemy_position += direction * speed * delta
```

Four lines of code. The entire steering behavior of every enemy in every game descends from this pattern. Subtract positions to get displacement. Normalize to get direction. Use the length for distance checks. Multiply direction by speed and delta time to get movement.

The demo's `vector_a` and `vector_b` are abstract — they could represent any two positions. The result arrow shows the displacement between them. Drag the handles to move `A` and `B` and the displacement updates in real time. The length changes, the direction changes, but the relationship holds: the result always points from `B` toward `A`.

```gdscript
@export var max_vector_length: float
```

The `max_vector_length` export clamps how far the handles can be dragged. Without it, vectors could extend beyond the gallery walls. A practical constraint, but also a pedagogical one — keeping the vectors short enough to see all three arrows simultaneously. When the difference vector gets too long, the geometry becomes hard to parse.

## Relative Velocity and Frame of Reference

Position subtraction gives displacement. Velocity subtraction gives relative velocity. The same operation, different quantities.

```gdscript
var velocity_car_a = Vector3(30, 0, 0)   # 30 m/s east
var velocity_car_b = Vector3(20, 0, 0)   # 20 m/s east

var relative_velocity = velocity_car_a - velocity_car_b  # Vector3(10, 0, 0)
```

Car A approaches car B at 10 m/s from B's perspective. The subtraction removes B's motion from the picture, leaving only what A does relative to B. This is frame of reference — choosing which observer's perspective to adopt. Subtraction is the operation that shifts frames.

Every physics simulation does this implicitly. Collision detection subtracts velocities to find closing speed. Orbital mechanics subtracts planetary velocities to compute encounter trajectories. The Doppler effect is velocity subtraction made audible — the pitch shift you hear is the relative velocity between source and listener, computed by subtracting one from the other.

```gdscript
# Collision detection: are these two objects approaching?
var relative_vel = object_a.velocity - object_b.velocity
var separation = object_b.position - object_a.position
var closing_speed = relative_vel.dot(separation.normalized())

if closing_speed > 0:
    # Objects are approaching each other
    pass
```

Notice the dot product appearing here — measuring alignment between relative velocity and separation direction. VectorBasics introduced magnitude. This map introduces subtraction. The dot product measures how much one vector aligns with another. That connection — between difference and alignment — threads through the entire sequence.

## The Ambient Sphere

The `DarkSphere` artifact sits in the gallery as atmospheric furniture. A dark orb floating above its own halo, pulsing with purple emission.

```gdscript
@export var sphere_radius: float = 0.35
@export var float_height: float = 0.25
@export var rotation_speed: float = 0.15
@export var pulse_speed: float = 1.2
```

It doesn't teach subtraction directly. But its implementation uses subtraction everywhere — implicitly, in the way Godot's renderer subtracts camera position from object position to determine screen coordinates, in the way the pulse oscillation subtracts `pulse_min` from the brightness range:

```gdscript
var pulse_t := (sin(_time_elapsed * pulse_speed) + 1.0) * 0.5
_sphere_material.emission_energy_multiplier = lerpf(pulse_min, pulse_max, pulse_t)
```

The `lerpf` function interpolates between min and max. Internally, linear interpolation is subtraction: `min + t * (max - min)`. The range `max - min` is a scalar difference — the 1D version of vector subtraction. Same operation. Same meaning. What separates two values?

The sphere's wobble uses another implicit subtraction — the sine function oscillates around zero, and the `0.05` multiplier maps that oscillation to a tiny angular range. The rotation is additive (`rotation.y += rotation_speed * delta`), but the wobble is centered, meaning it subtracts its own mean to stay balanced. Oscillation is addition and subtraction in alternation.

## Order at λ = 0.2

This map's spatial temperature is low. λ = 0.2 — firmly in the ordered regime. The gallery is compact. The vectors are clean arrows with sharp colors. No noise, no randomness, no emergent behavior. Pure geometry.

This is appropriate. Subtraction is deterministic. `A - B` always produces the same result for the same inputs. There is no entropy here, no probability, no chaos. The operation is closed and exact. The visualization reflects this: three arrows, fixed relationship, clear labels.

But the displacement interpretation opens a crack. When you subtract positions to get direction-to-target, you've introduced *intention*. The difference vector doesn't just describe geometry — it describes a relationship. Where am I relative to you? How fast am I closing? Which way must I turn? Subtraction is the operation that creates perspective.

In the QFEP framework, vectors define system states — the S in QFE = F - λ·E(S) + φ·ΔE(S,t). Subtraction computes the difference between states. Without it, you cannot express change. The temporal term φ·ΔE(S,t) is literally a subtraction: the entropy at time t+dt minus the entropy at time t, scaled by sensitivity. Change is difference. Difference is subtraction.

## Toward the Cross Product

This sets up what VectorCrossProduct explores. Subtraction gives you a vector between two points — a relationship in existing dimensions. The cross product gives you a vector perpendicular to two others — a direction that didn't exist until you computed it. Subtraction stays in the plane. The cross product escapes it.

But cross product depends on subtraction. Surface normals — the perpendicular direction at every point on a surface — are computed from cross products of edge vectors, and edge vectors are computed by subtracting vertex positions:

```gdscript
# Triangle normal from three vertices
var edge_1 = vertex_b - vertex_a  # subtraction
var edge_2 = vertex_c - vertex_a  # subtraction
var normal = edge_1.cross(edge_2) # cross product of differences
```

Two subtractions feed one cross product. The difference vectors become the inputs. Without subtraction, there are no edges. Without edges, there are no normals. Without normals, there is no lighting, no collision, no physics. The chain of dependency starts here, with the simplest signed operation: take one vector from another and see what remains.

## Possible Artifacts

**relative_displacement_tracker** — Two moveable points in 3D space with a live-updating displacement vector between them, showing magnitude and direction as numeric readouts. Would demonstrate how displacement changes continuously as either point moves, connecting static subtraction to dynamic systems.

**frame_of_reference_switcher** — Toggle between two observers' frames, watching the same vectors recompute relative to each observer's position. Subtraction changes meaning when you change the origin. Would make frame-of-reference tangible rather than theoretical.

**vector_field_gradient** — A grid of arrows showing the difference between neighboring samples of a scalar field. Gradient computation is vector subtraction applied spatially — the finite difference method that underpins all numerical simulation. Would bridge from single-vector subtraction to field-level thinking.