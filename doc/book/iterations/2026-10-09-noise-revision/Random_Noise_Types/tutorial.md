# A place is still a request

**Learning elements**

- Rejection sampling
- Minimum centre-to-centre distance
- A finite attempt budget for each requested place
- Accepted points, refused candidates and unfilled places
- A construction rule versus an ongoing constraint

At the two framed clouds in Random Noise Types, press REDRAW, then LOAD. The right cloud must leave room between its points. Asking for more does not give it more space. Read how many places remain unfilled.

## What you bring

Keep the pickable `PointBody`, the position list from Trace, the distance comparison from Lines, and the local seeded generator from Randomness. Random Remove chose among eligible addresses. Here the eligibility of a new position depends on the positions already accepted. Nothing moves them aside to make room.

**Build:** one bounded cloud of the same point spheres, admitting a centre only when it is far enough from every earlier centre.

**Investigate:** request more points, spend a limited number of attempts, then carry an accepted point into a relation its generator would refuse.

This is the opening distinction in Noise: neighbours can affect a procedure in different ways. Minimum spacing does not make a smooth scalar field. The columns in the next hall will give a field value a form to change.

## Work inside the museum

Continue in the prepared Endless Museum project. Its floor, light, player, desktop interaction and XR Tools are already running. Create an upright `PointStudy` Node3D at unit scale in the first Noise hall, at map-space `(2, 0, 7)` metres, with Y rotation 90 degrees. That west-side working position was checked in the museum; its local +Z side faces the approach. If placing under a translated hall, use the map's origin rather than treating these numbers as world coordinates.

Save the two complete files below together. Attach `01_spaced_points.gd` to `PointStudy`. It creates its own frame, label, points and control. No mesh child or scene-path reference is required. The point file is unchanged from Randomness; it is printed again so the dependency is available.

The twelve white spheres have the familiar 0.14-metre radius and frozen release. We give their centres a larger frame—2.4 × 1.4 × 0.12 metres—to keep that body useful to the hand. Its centre is 1.5 metres above the study's origin. The frame shows where centres may be generated; it is not a colliding container for their surfaces.

Hold the black point over a caption and press its action trigger: REDRAW repeats, NEXT SEED increments the seed, LOAD switches 12 / 48, RESTORE returns the generated positions. The choice uses the control's local X coordinate. The same point action works through the museum's existing desktop pickup controls. Release sampled white balls before using these actions; a held sample prevents replacement or restoration.

## Complete code — 01_spaced_points.gd

Start with `sample` and `far_enough`. The rest gives their result a familiar body, a record and an input. There is one `_ready` in this file.

<!-- student-code:01_spaced_points.gd -->

```gdscript
extends Node3D

const PointBody = preload("point_body.gd")
const CENTRE := Vector3(0, 1.5, 0)

var seed_value := 42
var requested := 12
var tries_per_place := 100
var half_size := Vector3(1.2, 0.7, 0.06)
var separation := 0.34
var rng := RandomNumberGenerator.new()
var homes: Array[Vector3] = []
var points: Array[Node3D] = []
var attempts := 0
var refused := 0
var control: Node3D
var label: Label3D

func _ready() -> void:
    build_frame()
    label = Label3D.new()
    label.position = Vector3(0, 2.65, 0)
    label.font_size = 28
    label.pixel_size = 0.002
    add_child(label)
    control = PointBody.new()
    control.position = Vector3(0, 0.65, 0.5)
    add_child(control)
    var black := StandardMaterial3D.new()
    black.albedo_color = Color(0.025, 0.025, 0.025)
    control.get_child(0).material_override = black
    control.action_pressed.connect(use_control)
    for i in range(4):
        var nameplate := Label3D.new()
        nameplate.text = ["REDRAW", "NEXT SEED", "LOAD", "RESTORE"][i]
        nameplate.position = Vector3(-1.2 + i * 0.8, 0.4, 0.5)
        nameplate.font_size = 26
        nameplate.pixel_size = 0.002
        add_child(nameplate)
    redraw()

func sample() -> void:
    rng.seed = seed_value
    homes.clear()
    attempts = 0
    refused = 0
    for place in range(requested):
        for attempt in range(tries_per_place):
            var candidate := Vector3(
                rng.randf_range(-half_size.x, half_size.x),
                rng.randf_range(-half_size.y, half_size.y),
                rng.randf_range(-half_size.z, half_size.z)
            )
            attempts += 1
            if far_enough(candidate):
                homes.append(candidate)
                break
            refused += 1

func far_enough(candidate: Vector3) -> bool:
    for existing in homes:
        if candidate.distance_to(existing) < separation:
            return false
    return true

func redraw() -> void:
    for point in points:
        remove_child(point)
        point.queue_free()
    points.clear()
    sample()
    for home in homes:
        var point := PointBody.new()
        point.position = CENTRE + home
        add_child(point)
        points.append(point)
    update_readout()

func restore() -> void:
    for i in range(points.size()):
        points[i].position = CENTRE + homes[i]
    update_readout()

func close_pairs() -> int:
    var count := 0
    for i in range(points.size()):
        for j in range(i + 1, points.size()):
            if points[i].position.distance_to(points[j].position) < separation - 0.001:
                count += 1
    return count

func update_readout() -> void:
    label.text = "Seed %d | spacing %.2f m\n%d requested | %d filled | %d unfilled\n%d candidates | %d refused | %d close pairs now" % [
        seed_value, separation, requested, homes.size(), requested - homes.size(),
        attempts, refused, close_pairs()
    ]

func _process(_delta: float) -> void:
    update_readout()

func use_control(_pickable) -> void:
    # Release the sampled balls before replacing or restoring their positions.
    for point in points:
        if point.is_picked_up():
            return
    var x := to_local(control.global_position).x
    if x < -0.8:
        redraw()
    elif x < 0.0:
        seed_value += 1
        redraw()
    elif x < 0.8:
        requested = 48 if requested == 12 else 12
        redraw()
    else:
        restore()

func build_frame() -> void:
    for axis in range(3):
        for a in [-1.0, 1.0]:
            for b in [-1.0, 1.0]:
                var bar := MeshInstance3D.new()
                var box := BoxMesh.new()
                var size := Vector3.ONE * 0.01
                var offset := Vector3.ZERO
                size[axis] = 2.0 * half_size[axis]
                offset[(axis + 1) % 3] = a * half_size[(axis + 1) % 3]
                offset[(axis + 2) % 3] = b * half_size[(axis + 2) % 3]
                box.size = size
                bar.mesh = box
                bar.position = CENTRE + offset
                add_child(bar)
```

## Follow one candidate

The outer loop asks for one place at a time. The inner loop may try one hundred candidates for that place. Each candidate uses three successive uniform draws: local X, Y and Z. The generator belongs to this study, so other museum artifacts cannot spend its next request.

`far_enough` reads the centres already in `homes`. One distance smaller than `separation` is enough to refuse the candidate. If there are no earlier centres, there is nothing to conflict with. A distance exactly equal to the separation is allowed.

On admission, `append` keeps the centre and `break` ends only the inner loop. The next requested place gets its own attempts. When all attempts fail, the inner loop simply ends without appending. The next place still gets a chance. No fallback point is secretly added.

The record uses metres in the study's local axes, relative to `CENTRE`. A point is displayed at `CENTRE + home`. All points share that parent and its unit scale, so rotating or translating the study preserves their distances. Scaling the host would change the world-space distance represented by the numbers; keep it at unit scale.

## Keep the two accounts separate

Every candidate is either accepted or refused:

`attempts = homes.size() + refused`

Every requested place is either filled or still unfilled:

`requested = homes.size() + unfilled`

One unfilled place may have refused a hundred candidates. It is not one refusal. With no more than one hundred attempts per place, the total cannot exceed `requested * tries_per_place`. Successfully finding a point stops that place's search early.

REDRAW resets the local seed before sampling. Identical bounds, spacing, request count, budget and call order repeat the record in the same Godot version. NEXT SEED changes the recipe's starting seed. It does not guarantee a different visible result or a similar result to the previous integer.

## Predict, then change the request

Press LOAD. Before reading the result, name what stays fixed: frame dimensions, centre separation and attempt budget per place. The request rises from twelve to forty-eight. The readout may show unfilled places. A finite search ending does not establish that no legal position remains; it establishes that this search stopped finding one within its budget.

For a decisive code experiment, set `requested = 5`, `tries_per_place = 7` and `separation = 3.0`, then restart the study. The frame's centre-to-centre diagonal is less than three metres. Predict the result before running: the first candidate is accepted, then each of the four remaining places exhausts seven attempts. That gives one filled place, four unfilled places, twenty-eight refused candidates and twenty-nine candidates in total. Here geometry, rather than the exhausted budget alone, explains why another centre cannot fit. Return to the original settings afterward.

## What continues after construction?

Carry a white point beside another, then release it. The close-pair count can rise. The update reads current positions; it never assigns replacement positions. Its one-millimetre tolerance is for the observer, not a relaxation of the generator's admission rule. `j` starts at `i + 1` so each pair is counted once and no point is compared with itself. Three coincident centres make three pairs.

The saved `homes` do not follow your hand. RESTORE reads them without requesting another random value. REDRAW regenerates and replaces the sampled bodies. They can produce the same arrangement by different routes. The black control survives both actions.

This record lives only in this study instance. It is not a saved trace file, and it does not automatically travel through the next portal. What we carry onward here is the procedure and the distinction between a sampled value and its later use.

## Make a deeper cloud

Change only `half_size.z` from `0.06` to `0.30`, keeping the seed and three requests per candidate. Predict the first accepted centre: its X and Y stay the same; its Z becomes five times as large. Later accepted centres need not correspond one for one. Changing depth changes distances, which can change admission and how far the generator proceeds.

Run your version. Find two points that overlap when viewed from the front but separate when you lean sideways. The rule measures three-dimensional centre distance. A projected overlap is not enough to establish a breach. Keep this version and explain why stretching the already generated picture would be a different operation.

## The inherited point — point_body.gd

This file is unchanged. It creates the sphere and its collision shape; Day Zero's XR Tools parent provides pickup and `action_pressed`. We reuse that class for white samples and the black control. The spheres share a construction, not one live identity carried through every room.

<!-- student-code:point_body.gd -->

```gdscript
extends XRToolsPickable

const RADIUS := 0.14

func _init() -> void:
    freeze = true
    freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
    release_mode = XRToolsPickable.ReleaseMode.FROZEN
    ranged_grab_method = XRToolsPickable.RangedMethod.NONE
    collision_layer = 4
    collision_mask = 196615

    var surface := MeshInstance3D.new()
    var sphere := SphereMesh.new()
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

## Compare with the installed work

The installed bench uses two smaller 0.90 × 0.90 × 0.12-metre slabs and requests 24 / 96 centres. The left keeps uniform proposals. The right continues the same generator's stream and applies its spacing rule. These are not the same candidate list with and without filtering. Our one-cloud construction starts directly at the seeded stream and keeps the admission loop visible.

The bench also shows at most 220 refused proposals as grey specks, although its refusal counter includes all of them. Our smaller lesson counts refusals without drawing them. Both allow a hundred attempts per requested place. The bench's RULE control can replace spacing with clamped Gaussian draws; that branch promises no minimum pair distance. It is a comparison with what you learned in Random Gaussian, not another implementation required here.

At the separate single-point frame, move the point out of its plane. The artifact keeps clipping X and Y to its bounds and setting local Z to zero. It does so continuously, without drawing another position on release. Compare that response with your freely altered cloud.

The needle field, noise-colour sculpture and sound console extend the encounter. Their image and sound generators are separate; the bars are not a measured audio spectrum. The moving walls of Related Weather let you compare fresh draws, accumulated steps and a filtered record. Those works have a place in the reflection without becoming extra requirements for this lesson.

## What travels onward

We can now say when a relation acts: during admission, during display, or after a hand changes a body. In Noise Columns, keep the receiving form fixed and compare a held value, a periodic value and a value read from a field. The next question is what the same number can make a body do.

## Optional experiment: The Uncertain Surface

**Learning elements:** saved original; Gaussian xyz displacement; seed replay; fixed-sample strength; indexed connectivity; RMS/maximum/centroid.

After the sampling displays, compare the two pale surfaces in the west bay. Move STRENGTH without changing seed, then try NEXT SEED. ZERO removes displacement; RESET restores the opening. The two actions answer different questions: scaling a retained sample and drawing another one. Both surfaces have the same material and a removable edge overlay.

Reconstruct this optional experiment with the [complete code and explanation](../../artifacts/geometry_noise/tutorial.md). The base geometry is a 2m square, with 289 vertices and 512 triangles. The experimental surfaces do not collide; their plinths and the museum floor remain ordinary supports. Predict the measured RMS at half strength before moving the slider. Keep the original and connectivity; carry the difference to the later field and surface comparisons.
