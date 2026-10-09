# The held sphere loses resolution

## Learning elements

- Resolution as a construction parameter
- Rings and radial segments
- Visible construction and collision
- Independent mesh resources

## In the museum

Return to the small white sphere you could pick up in Coordinates and use to draw in Trace. In this hall, holding it changes its visible construction. Rings and radial segments decrease in small timed steps. Release it and the change pauses. Its size and physical boundary remain the same.

The lesson is **resolution as a parameter of construction**: the same named sphere can have several finite meshes. Change rings while keeping radial segments fixed, then reverse that comparison. Keep radius and the spherical collider unchanged.

Pickup returns from Coordinates. PointBody and the class extension return from earlier lessons; the short held-time controller is supplied support for this comparison. Its complete code and explanation remain below, but reconstructing the timer is not the new learning goal.

## Make this study

Attach lesson.gd to a unit-scale Node3D named ResolutionStudy in the working museum hall. The existing XR Tools hands provide pickup. The two spheres use the same class but own separate resources. To repeat the comparison, restart the study. The supplied `ui_accept` action also calls `reset_resolution()` on both spheres; its input binding belongs to Day Zero.

PointBody is a small later edition of the earlier file: `sphere` is now a member variable instead of a local `_init` variable. Its radius, height, collider, material defaults and pickup settings are unchanged. Keep this edition in this lesson folder; earlier tested scripts need no edits.

### The program

<!-- student-code:lesson.gd -->
```gdscript
extends Node3D
const ResolutionPoint = preload("resolution_point.gd")
var point := ResolutionPoint.new()
var comparison := ResolutionPoint.new()
var message := Label3D.new()

func _ready() -> void:
    point.position = Vector3(-0.3, 1.12, 0)
    comparison.position = Vector3(0.3, 1.12, 0)
    add_child(point)
    add_child(comparison)
    add_child(message)
    message.position = Vector3(0, 1.65, 0)
    message.pixel_size = 0.002

func _process(delta: float) -> void:
    point.advance(delta)
    comparison.advance(delta)
    if Input.is_action_just_pressed("ui_accept"):
        point.reset_resolution()
        comparison.reset_resolution()
    message.text = "RINGS %d   SEGMENTS %d" % [point.sphere.rings, point.sphere.radial_segments]
```

### Dependency: point_body.gd

<!-- student-code:point_body.gd -->
```gdscript
extends XRToolsPickable

const RADIUS := 0.14
var sphere := SphereMesh.new()

func _init() -> void:
    freeze = true
    freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
    release_mode = XRToolsPickable.ReleaseMode.FROZEN
    ranged_grab_method = XRToolsPickable.RangedMethod.NONE
    collision_layer = 4
    collision_mask = 196615

    var surface := MeshInstance3D.new()
    sphere.radius = RADIUS
    sphere.height = RADIUS * 2.0
    surface.mesh = sphere
    add_child(surface)

    var boundary := CollisionShape3D.new()
    var shape := SphereShape3D.new()
    shape.radius = RADIUS
    boundary.shape = shape
    add_child(boundary)
```

### Dependency: resolution_point.gd

<!-- student-code:resolution_point.gd -->
```gdscript
extends "point_body.gd"
const START_RINGS := 16
const START_SEGMENTS := 32
const STEP_SECONDS := 0.15
var elapsed := 0.0

func _init() -> void:
    super()
    reset_resolution()

func advance(delta: float) -> void:
    if not is_picked_up():
        return
    elapsed += delta
    while elapsed + 0.000001 >= STEP_SECONDS:
        elapsed = maxf(0.0, elapsed - STEP_SECONDS)
        sphere.rings = maxi(1, sphere.rings - 1)
        sphere.radial_segments = maxi(4, sphere.radial_segments - 1)

func reset_resolution() -> void:
    elapsed = 0.0
    sphere.rings = START_RINGS
    sphere.radial_segments = START_SEGMENTS
```

## Read the construction

ResolutionPoint extends PointBody. `super()` runs the base constructor, which constructs the visible sphere and physical boundary; the added class controls the existing sphere mesh. `sphere.rings` divides the construction along its height; `sphere.radial_segments` divides it around the axis. Neither setting changes its radius.

`advance(delta)` receives elapsed seconds from the hall's `_process`. Its first condition returns immediately while the point is not held. Otherwise it accumulates time. A `while` loop consumes every complete 0.15-second interval, including several intervals during a long frame. Release preserves the remaining fraction, and re-grabbing continues it.

`maxi` stops rings at one and radial segments at four, the valid lower bounds used here. We approach a coarse sphere, not a zero-vertex object. The analytical sphere collider remains round: seeing a faceted mesh does not imply feeling a faceted boundary.

`reset_resolution()` restores the two starting counts and clears the clock. Both calls to `ResolutionPoint.new()` construct their own mesh; changing one must not quietly change its neighbour.

## Make it your own

First hold only the left sphere. Make a variant that decrements rings but leaves radial segments unchanged; make a second variant that changes only radial segments. Predict and compare the visible results. Identify what stayed the same: radius, collider and the untouched neighbour.

As a separate check of the supplied controller, release halfway through an interval, wait, and resume. Its change should follow held time, not time spent looking at the sphere.

Carry the same body and the distinction between shape, appearance, interaction and construction parameters. Columns next gives a family of forms three separate inputs.

Parameter meanings: [Godot 4.6 SphereMesh](https://docs.godotengine.org/en/4.6/classes/class_spheremesh.html).

[Current lesson.gd](http://localhost:3003/book-review/doc/book/iterations/2026-10-06-starter-one-course/lessons/Primitives_Godot/lesson.gd) · [Complete working project](http://localhost:3003/book-review/doc/book/iterations/2026-10-03-ada-xr-starter/ada-xr-starter.zip) · [Verification and changes](http://localhost:3003/book-review/doc/book/iterations/2026-10-06-starter-one-course/index.html)
