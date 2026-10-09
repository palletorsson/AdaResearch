# Wavefunctions — the complete tutorial

# The cube returns

**Learning elements**

- Periodic movement
- Amplitude
- Frequency and period
- Phase

Start with the cube moving up and down near the entrance. Follow it from the middle to the top, through the middle to the bottom, then back. Its direction changes while its shape remains familiar.

Three questions travel through this sequence. **Movement:** what changes, and what makes it change? **Record:** what do we keep when the movement has passed? **Composition:** what can those parts make together? We will return to these questions through a swing, a surface, a sound and a sum. Begin with one cube and one returning height.

## What you bring

Keep the cube from Transformation: one `MeshInstance3D`, a `BoxMesh`, and a position updated from elapsed time. There we made a body travel, turn and change size. Here we open the rule for a movement that keeps returning. We do not need to rebuild its faces or introduce a new body.

**Build:** use a sine function to place the cube along one vertical axis.

**Investigate:** change how far it moves, how often it returns, and where in the cycle it begins. Keep these three decisions separate.

## Work inside the museum

Use your existing `PointStudy` Node3D, under this hall, upright at unit scale. The working bay is hall-local `(6.3, 0, 16.5)` metres. The name of the study node does not restrict it to spheres. The museum supplies floor, lighting, camera and player.

Save `01_cube_return.gd` and attach it to the study. This is the complete program; no companion scripts or named scene children are required. It uses the same cube construction as Transformation, displayed at 0.4 metres across. The overlap sensor from the collection exercise is left out so the cube remains available to observe.

## Complete code — 01_cube_return.gd

<!-- student-code:01_cube_return.gd -->

```gdscript
extends Node3D

@export var amplitude := 0.4
@export var frequency := 0.5
@export var phase := 0.0
var centre := Vector3(0, 1.3, 0)
var elapsed := 0.0
var cube := MeshInstance3D.new()
var label := Label3D.new()

func _ready() -> void:
    assert(amplitude >= 0.0 and frequency >= 0.0)
    cube.mesh = BoxMesh.new()
    cube.scale = Vector3.ONE * 0.4
    add_child(cube)
    label.position = centre + Vector3(0, 0.8, 0)
    label.font_size = 36
    label.pixel_size = 0.0025
    label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    add_child(label)
    draw_state()

func _process(delta: float) -> void:
    elapsed += delta
    draw_state()

func height_at(seconds: float) -> float:
    return centre.y + amplitude * sin(TAU * frequency * seconds + phase)

func draw_state() -> void:
    cube.position = Vector3(centre.x, height_at(elapsed), centre.z)
    label.text = "time %.2f s   height %.2f m\nA %.2f m   f %.2f Hz   phase %.2f rad" % [
        elapsed, cube.position.y, amplitude, frequency, phase]
```


## Read the movement

`elapsed += delta` keeps time in seconds, as before. `height_at` turns that time into a height. The cube receives the resulting position every frame.

Sine returns a value between −1 and +1. Multiplying by `amplitude` gives the displacement above or below `centre.y`. With amplitude 0.4 metres, the cube's centre travels between 0.9 and 1.7 metres: a total span of 0.8 metres. Amplitude is half that span.

`frequency` counts complete cycles per second, in hertz. At 0.5 Hz, a cycle takes two seconds. `TAU` is one full turn in radians; multiplying it by frequency and time turns elapsed cycles into the angle that sine reads. The Unit Circle hall will make that relationship visible around a circle.

`phase` adds a starting angle, in radians. At phase zero the cube begins at its middle and rises. At `PI / 2.0` it begins at the top. At `PI` it begins in the middle and falls. That middle position alone does not tell us which way the cube is travelling.

The `@export` lines expose these values in the Inspector for each study instance. The instances can share one script while using different parameters.

## Predict one cycle

With the original values and phase zero, predict these heights before running:

| Time | Position in the cycle | Height of the cube's centre |
| --- | --- | --- |
| 0 s | Middle, rising | 1.3 m |
| 0.5 s | Top | 1.7 m |
| 1 s | Middle, falling | 1.3 m |
| 1.5 s | Bottom | 0.9 m |
| 2 s | Middle, rising again | 1.3 m |

Watch the readout in your study. Then change one parameter. Double amplitude: the span doubles while the cycle still takes two seconds. Restore it and double frequency: the span stays the same while the cycle takes one second. Restore frequency and set phase to `PI`: the starting height stays the same, but the first direction reverses.

The formula assigns a height from the centre each time. It does not keep adding the sine value to the previous height. The cube therefore stays within the same band instead of drifting away.

## Build a comparison

Make a second study instance beside the first and attach the same script. Keep their amplitude and frequency equal; give the second a phase of `PI`. Predict when they share a height and when one is at the top while the other is at the bottom. Each instance owns its clock and parameters.

Next give the second cube frequency 1.0 Hz while the first keeps 0.5 Hz. Count both cycles over the same two seconds. Explain which value changed the rate and which only changed the starting part of a cycle.

## Compare with the hall

The installed `y_oscillation_cube` uses this same sine-of-time operation with its own dimensions, rail, markers and trail. Your smaller program isolates the moving cube and its readout. The surrounding rotating and transforming cubes let you recognise other kinds of return without making all of them part of this lesson.

This movement is prescribed by a clock. It does not calculate gravity, collision or a hand's release. A push cannot change a movement rule that never reads it. The pendulum elsewhere in the hall offers a comparison: its next movement depends on its current angle and angular velocity. We will work with that distinction as the sequence continues.

## What travels onward

Keep the cube, elapsed time and the three parameters. The next hall, Pendulum, lets us compare a responding swing with a prescribed cycle and keep a timestamped record. Trace's earlier list returns with another job: making the history of a movement visible.

## Four distinctions for the journey

Return to these names as the encounters change. A similar outline can come from a different operation.

| Operation | What changes | Where we will meet it |
| --- | --- | --- |
| Oscillation | A quantity changes periodically in time. | This returning cube. |
| Spatial pattern | A periodic rule places geometry across space; it can remain still. | Sine Space and Bernini. |
| Propagation through coupling | A disturbance affects neighbouring locations through their relations. | The coupled lattice. |
| Composition | Components combine to produce a result. | Two signed waves in Beats; five weighted harmonics in Synthesis. |

These are distinctions to inspect, not four separate blocks of rooms. A composition can oscillate; a moving pattern can be prescribed without neighbour coupling. Ask what the program reads to produce its next value.


---

# A swing keeps a record

**Learning elements**

- Angular state and a restoring acceleration
- Records with named position and time fields
- Sampling intervals
- Count and age limits
- Drawing time as distance

Watch the pendulum in its frame. Choose one teal mark behind it. The bob turns back; the mark keeps travelling down the hall. The bob has not visited that depth. The drawing gives its past somewhere to go.

## What you bring

Keep the cube from the previous hall and the list from Trace. There, a distance condition decided when to keep another position. Here a time condition does that job. Each entry needs both the position and the time it was observed.

**Build:** let the familiar cube swing beneath a pivot, then keep a bounded record of its positions. The installed exhibit uses a spherical bob; our cube remains a recognisable marker for the same point-mass model.

**Investigate:** change the recording interval while keeping the movement rule. Predict whether you will retain more detail, more duration, or both.

## Work inside the museum

Keep the opening script. Save this next version as `02_pendulum_record.gd` and attach it to your `PointStudy` Node3D in the Pendulum hall. Use hall-local position `(10, 0, 21.8)`, zero rotation and unit scale. Its history extends towards local negative Z. The museum supplies the room, light, camera and player.

The complete script below creates every object it uses. The cube construction returns unchanged at 0.4 metres across. A pivot and a thin rod give it a constraint. Small teal copies mark the recorded positions; their meshes are allocated once, then reused. No named scene children, external classes or scene references are required.

## Complete code — 02_pendulum_record.gd

<!-- student-code:02_pendulum_record.gd -->

```gdscript
extends Node3D

class Sample:
    var position: Vector3
    var time: float

    func _init(at: Vector3, seconds: float) -> void:
        position = at
        time = seconds

@export var sample_interval := 0.025
@export var trail_speed := 0.6
var length := 1.0
var gravity := 9.8
var initial_angle := PI / 4.0
var angle := initial_angle
var angular_velocity := 0.0
var elapsed := 0.0
var sample_clock := 0.0
var max_samples := 120
var max_age := 6.0
var history: Array[Sample] = []
var marks: Array[MeshInstance3D] = []
var pivot := Node3D.new()
var cube := MeshInstance3D.new()
var label := Label3D.new()

func _ready() -> void:
    assert(sample_interval > 0.0 and length > 0.0)
    var mesh := BoxMesh.new()
    pivot.position = Vector3(0, 2.0, 0)
    add_child(pivot)
    cube.mesh = mesh
    cube.scale = Vector3.ONE * 0.4
    cube.position.y = -length
    pivot.add_child(cube)
    var rod := MeshInstance3D.new()
    var cylinder := CylinderMesh.new()
    cylinder.top_radius = 0.008
    cylinder.bottom_radius = 0.008
    cylinder.height = length
    rod.mesh = cylinder
    rod.position.y = -length / 2.0
    pivot.add_child(rod)
    var ink := StandardMaterial3D.new()
    ink.albedo_color = Color(0.08, 0.65, 0.7)
    ink.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    for i in range(max_samples):
        var mark := MeshInstance3D.new()
        mark.mesh = mesh
        mark.material_override = ink
        mark.scale = Vector3.ONE * 0.035
        mark.visible = false
        add_child(mark)
        marks.append(mark)
    label.position = Vector3(0, 2.35, 0)
    label.font_size = 36
    label.pixel_size = 0.0025
    label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    add_child(label)
    draw_state()

func _physics_process(delta: float) -> void:
    var acceleration := -(gravity / length) * sin(angle)
    angular_velocity += acceleration * delta
    angle += angular_velocity * delta
    elapsed += delta
    pivot.rotation.z = angle
    sample_clock += delta
    if sample_clock >= sample_interval:
        sample_clock = fmod(sample_clock, sample_interval)
        history.append(Sample.new(to_local(cube.global_position), elapsed))
    while history.size() > max_samples:
        history.pop_front()
    while not history.is_empty() and elapsed - history[0].time > max_age:
        history.pop_front()

func _process(_delta: float) -> void:
    draw_state()

func display_position(sample: Sample) -> Vector3:
    var age := elapsed - sample.time
    return sample.position + Vector3.FORWARD * age * trail_speed

func draw_state() -> void:
    pivot.rotation.z = angle
    for i in range(marks.size()):
        marks[i].visible = i < history.size()
        if i < history.size():
            marks[i].position = display_position(history[i])
    label.text = "swing %.2f rad   time %.2f s\n%d marks   request %.3f s" % [
        angle, elapsed, history.size(), sample_interval]

func set_sampling(seconds: float) -> void:
    assert(seconds > 0.0)
    sample_interval = seconds
    sample_clock = 0.0
    history.clear()
    draw_state()

func reset_experiment() -> void:
    angle = initial_angle
    angular_velocity = 0.0
    elapsed = 0.0
    sample_clock = 0.0
    history.clear()
    draw_state()
```


## From a prescribed cycle to a responding swing

In the opening, elapsed time directly supplied a height. Here the next angle depends on the current angle and angular velocity. The update follows the integration we used in Forces: acceleration changes velocity; velocity changes position. Both steps multiply by `delta` in seconds. Angle is measured in radians and angular velocity in radians per second.

The acceleration `-(gravity / length) * sin(angle)` points back towards the hanging position. Start on the right: acceleration is negative. At the bottom it is zero, but the accumulated velocity carries the cube through. The cube slows on the other side before returning. Change its angular velocity and you change what follows; a clock prescribing its position would overwrite that intervention.

The pivot rotates around Z. Its child cube stays one metre below it in the pivot's coordinates. We therefore need `to_local(cube.global_position)` to record the moving centre in the **study's** coordinates. Recording `cube.position` would repeatedly save the unchanged offset beneath the pivot.

This is a numerical, undamped, fixed-length pendulum model. The cube represents a point mass; its shape, rotational inertia, air resistance and collisions are absent. It is not a Jolt rigid body and cannot be grabbed. Small numerical energy errors remain. Keep the room's existing pendulum as the encounter; the small reconstruction isolates its update and recorder.

## One observation has two fields

`Sample` groups a position with a time. `Array[Sample]` says what kind of entry belongs in `history`. Position is a three-dimensional vector in metres; time is a separate number in seconds. Z remains a spatial coordinate.

Each physics update advances the local clock. When the sampling interval has elapsed, `append` saves the cube's current centre and the current time. Oldest records stay at the beginning of the list, so `pop_front` removes the oldest.

`fmod` keeps the unused fraction of the sampling interval. We save at most one observation per physics update. If an update is late, we keep the position actually observed; we do not invent several earlier positions from that one observation.

With a 60 Hz physics tick, a requested interval of 0.025 seconds falls between ticks. Actual gaps alternate between approximately 0.0167 and 0.0333 seconds. A headset's display rate does not, by itself, set the physics tick rate. The timestamps describe the observations we obtained, not the ideal schedule we requested.

## Two limits on a record

The first `while` loop keeps no more than 120 entries. The second removes entries older than six seconds. Either condition can shorten the history.

At 0.025 seconds per sample, 120 entries cover about three seconds. At 0.2 seconds, the six-second age limit is reached with about thirty entries. The exact oldest-to-newest span depends on the retained timestamps. The count limit gives fine sampling less duration here.

`set_sampling` clears the record and sampling clock while keeping angle, angular velocity and elapsed time. `reset_experiment` also resets those movement variables. The museum's own clock continues in either case.

## Give age a direction

`display_position` starts from a stored position, then displaces its **drawing** along negative Z. Age in seconds times `trail_speed` in metres per second becomes distance in metres. At 0.6 metres per second, a two-second-old mark is drawn 1.2 metres behind its recorded position.

The stored position never changes. Changing the display speed rearranges the same record; it does not make the pendulum swing faster. This distinction carries Trace's original-data rule into another representation.

## Build and compare

Run the original values. Predict where a mark will be drawn two seconds after its timestamp. Check a record in Godot's Remote Inspector: compare its saved position with the corresponding mesh in `marks`.

Place a second study across the hall, at `(2.5, 0, 22.2)`, with the same script and initial state. Set its exported sampling interval to `0.2` before running. After eight seconds, both cubes should still swing together. The coarse record should contain fewer marks and reach further back. Explain both results using the two limits, not the appearance alone.

Now set the second study's `trail_speed` to `0.3`. Its history occupies half as much depth for the same ages. The period, stored positions and sample count do not change. This is a change to the drawing.

For an independent variation, edit the second script to request `0.1` seconds and retain at most twenty samples. Predict which limit will end its history. Then change only the count limit until all six seconds fit. Use the actual timestamps to judge the result.

## Read the installed exhibit

The hall's enlarged `PendulumWave` uses the same update and recording principle with a 2.8-metre pendulum, up to 300 records and ten seconds of history. Its FINE, COARSE and RESET controls make the comparisons available in the existing museum. Our shorter study uses smaller limits so the record fits beside it.

The floor beneath the installation carries a second drawing of its record. It retains horizontal position and age while omitting height. Compare that projection with the suspended marks. The floor drawing and measured-period control belong to the installed exhibit; the printed reconstruction builds the small swing and its suspended record.

The exhibit also has STROBE: it measures a period from successive crossings in the same direction, then samples approximately once per return. Watch the moving bob while its marks almost line up. Much of the motion happened between observations. That measured-period control is an encounter here; it is not concealed inside the printed reconstruction.

## What travels onward

Keep the timestamped list and the distinction between data and its drawing. The next hall, Sine Space, gives a repeating rule a spatial coordinate directly. Here depth described a record's age; there position in space will be an input to the rule.


---

# A rule becomes a surface

**Learning elements**

- Spatial frequency: cycles per metre
- A height function of two coordinates
- Sampling a grid into shared positions
- Joining neighbouring samples with triangles
- Giving a static mesh collision

At the entrance, look across the blue tray. Choose a hollow before pressing RELEASE. Will a sphere pass through it, settle there, or knock another sphere out? The sine rule supplies a landscape. Gravity and contact determine what the bodies do with it.

## What returns

The opening cube repeated a height as **time** advanced. Pendulum kept observations of a moving body. Here a repeating rule takes **position** as its input. The surface stays still.

Bring the addresses from Grid and the face lists from Polyhedra. Bring back the PointBody sphere used in Forces: the same 0.14-metre radius, mesh, boundary and pickup behaviour. We create another instance of that class; we do not rebuild or re-explain its sphere. This is a return to a learned object after using the cube as our clock and pendulum marker.

**Build:** sample a two-metre square, connect the samples, and give its triangles a collision receiver. Drop one PointBody onto it.

**Investigate:** change the height range or spacing while keeping the sphere. Predict a change in the surface before you predict the body's response.

## Inside the museum

Save `03_sine_surface.gd` beside the carried `point_body.gd`. Attach the new script to your `PointStudy` Node3D in Sine Space, at **hall-local `(10.5, 0, 8.5)`**, zero rotation and unit scale. This places your small study across from the existing tray. The museum continues to supply its player, camera, light and XR tools.

Run the study. The sphere drops automatically; you can then pick it up and release it elsewhere using the museum's existing interaction. Restart the study after changing its exported values. Use a positive `cells` value; start with 16. We build a static mesh once in `_ready()`. Changing a variable while it runs does not rebuild the surface.

## Complete new code — 03_sine_surface.gd

<!-- student-code:03_sine_surface.gd -->

```gdscript
extends Node3D

const PointBody = preload("point_body.gd")
@export var cells: int = 16
@export var amplitude: float = 0.18
@export var frequency: float = 1.0 # Cycles per metre, not per second.
var points: Array[Vector3] = []
var faces: Array[Vector3i] = []
var surface := MeshInstance3D.new()
var receiver := StaticBody3D.new()
var boundary := CollisionShape3D.new()
var point: PointBody

func height_at(x: float, z: float) -> float:
    return 0.8 + amplitude * sin(TAU * frequency * x) * sin(TAU * frequency * z)

func _ready() -> void:
    add_child(surface)
    add_child(receiver)
    receiver.add_child(boundary)
    for row in range(cells + 1):
        for column in range(cells + 1):
            var x := -1.0 + 2.0 * column / cells
            var z := -1.0 + 2.0 * row / cells
            points.append(Vector3(x, height_at(x, z), z))
    var stride := cells + 1
    for row in range(cells):
        for column in range(cells):
            var a := row * stride + column
            faces.append(Vector3i(a, a + 1, a + stride))
            faces.append(Vector3i(a + 1, a + stride + 1, a + stride))
    var builder := SurfaceTool.new()
    builder.begin(Mesh.PRIMITIVE_TRIANGLES)
    for face in faces:
        for index in [face.x, face.y, face.z]:
            builder.add_vertex(points[index])
    builder.generate_normals()
    surface.mesh = builder.commit()
    var blue := StandardMaterial3D.new()
    blue.albedo_color = Color("76b6c9")
    blue.roughness = 0.65
    surface.material_override = blue
    boundary.shape = surface.mesh.create_trimesh_shape()
    var contact := PhysicsMaterial.new()
    contact.friction = 0.45
    contact.bounce = 0.0
    receiver.physics_material_override = contact
    point = PointBody.new()
    point.position = Vector3(0.20, 1.8, 0.20)
    point.mass = 0.1
    point.gravity_scale = 1.0
    point.release_mode = XRToolsPickable.ReleaseMode.UNFROZEN
    point.freeze = false
    point.physics_material_override = contact
    var black := StandardMaterial3D.new()
    black.albedo_color = Color("17191c")
    black.roughness = 0.16
    for child in point.get_children():
        if child is MeshInstance3D:
            child.material_override = black
    add_child(point)
```


## Read the height rule

At `(x, z)`, the function returns `0.8 + amplitude * sin(...) * sin(...)`. The 0.8 metres raises the study to table height. With amplitude 0.18, the mathematical rule ranges from 0.62 to 0.98 metres. A particular sampling grid might miss its highest and lowest points.

`frequency` is measured in **cycles per metre**. `TAU * frequency * x` converts a position in metres to an angle in radians. At frequency 1, moving one metre in X repeats the value. There is no elapsed time in this expression and no `_process()` moving the terrain.

Hold Z at 0.25 metres. Predict the heights at X = 0, 0.25 and 0.5: **0.8, 0.98 and 0.8 metres**. At Z = 0, its sine is zero, so the whole row stays at 0.8. The two factors act together: a crest along one direction can be cancelled by the other.

## Addresses become faces again

Sixteen cells need seventeen sample positions along each edge. The nested loops keep `17 × 17 = 289` positions. X and Z run from −1 to 1 in the study's local coordinates. We keep positions row by row, so `row * stride + column` finds a sample in the list.

For each cell, `a` is one corner; `a + 1` is its neighbour along X; `a + stride` is the next row. The fourth corner is `a + stride + 1`. The two `Vector3i` entries refer to these four positions. This is the face-list relationship from Polyhedra, repeated across a grid: **256 cells, 512 triangles**.

The builder emits each triangle's three vertices and generates lighting normals. The order shown gives the triangles upward-facing fronts in Godot. The position list still contains shared samples even though the resulting rendering mesh repeats vertices per face. We leave out the earlier edge cylinders to keep this surface and its contacts readable.

## Seeing and supporting are separate

`surface` makes the triangles visible. `receiver` is a static physics body. Its `boundary` receives a triangle collision shape made from **that same mesh**, so the contact surface matches the drawn facets. The trimesh construction is a supplied engine operation; we are not writing a collision solver here.

The familiar point is unfrozen, has gravity, and keeps its spherical boundary. The physics engine advances it. We do not also assign its position every frame. A grab temporarily controls the body through the existing XR tool; releasing returns it to physics.

The new surface is a finite, thin sheet with no enclosing rails. A sphere can roll off and fall onto the museum floor. It collides with the sampled triangles, not an infinitely smooth mathematical sine. The contact material sets friction to 0.45 and bounce to zero; it does not promise that every hollow will hold the sphere.

## Make another surface without copying the answer

1. Keep frequency 1 and cells 16. Set amplitude to zero and restart. Predict the terrain and the released sphere separately. Then try amplitude 0.30. Which changes are consequences of the height rule, and which depend on contact?
2. Keep amplitude 0.18. Set frequency to 0.5, then 2, restarting each time. Predict how many full cycles fit across the two-metre width. Explain why increasing frequency is different from increasing height.
3. Return to frequency 1 but use only 4 cells. The sample spacing is now half a metre: all sampled sine values are approximately zero. The built surface becomes almost flat even though the unsampled function still has crests. Restore 16 cells. The function and its representation made different promises.

Now make one independent variation: give X and Z separate frequency variables. Aim for one cycle across the width and two along the depth. State your two frequencies in cycles per metre before running it. Keep the same PointBody and explain what you changed without calling it a faster wave.

## Compare with the installed encounters

The museum tray uses a denser, tilted surface and 32 smaller spheres. It rescales its sampled heights into the selected relief range. Our study uses a horizontal surface and a centred height range. Both construct static triangles and matching collision. The tray's SIZE and RELIEF controls reset its trial; its twelve-second counter records a deadline, not proof of permanent trapping. Use its batch for comparison after making the smaller construction.

Further into the hall, the red corridor advances the phase of layered waves. Its walls are visible but noncolliding; its thin floor provides support. Beyond that, the silver sine floor has a matching collider and stays still. Walk across a fold in each and compare what the same word, *surface*, lets your body do.

## Carried code — point_body.gd

This is the unchanged PointBody from Forces, included so the two-file study is complete. Keep it beside the new script. Its superclass, `XRToolsPickable`, is part of the museum's installed XR Tools; running these files in an empty Godot project would require that setup first.

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


## Take forward

Keep the height function, sample list and face list. You can now make a repeating value occupy a surface and state whether that surface can stop a body. In Unit Circle, we examine where the sine value comes from: a turning point and one of its coordinates.


---

# Unit Circle — two coordinates from one angle

## Learning elements

- Radians and angular speed.
- Sine and cosine as signed coordinate ratios.
- A circle-position function: centre, radius and angle.
- A path and a graph with different horizontal axes.

In the museum, follow the bright point around the circle. Its vertical rod grows, disappears and grows below the centre. Stop the point with the nearby angle slider. At the top, the vertical offset is one metre and the horizontal offset is zero. Move through another quarter turn: those roles change.

Sine Space used sine to set heights. Here we open that function's geometric relationship: at radius one, cosine gives the horizontal offset and sine the vertical offset. We continue with our PointBody sphere and the thin cylinder from Lines. This sphere is a marker whose position we prescribe; pickup and collision are disabled in this study. The previous physical sphere remains available in its own lesson.

## Place the study in the existing hall

Use the museum and installed XR Tools from Day Zero. Save the three files below together. Attach `04_circle_coordinates.gd` to an empty Node3D in the Unit Circle hall's clear forecourt. The verified placement is hall-local `(11, 0, 10)`, Y rotation `180°`, scale `1`. No child nodes or scene paths are required. The museum supplies the player, camera, light and floor.

The local XY plane holds the circle. Positive X goes right and positive Y goes up when viewed from its positive Z side. The centre starts 1.5 metres above the floor. Angles increase counterclockwise from the rightmost point. `PI` radians is half a turn; `TAU` is a full turn. Angular speed is radians per second, so `PI / 2` makes one turn in four seconds.

The graph beside it shows one complete turn. Its horizontal axis allocates four metres to `TAU` radians. It does **not** show the sphere's horizontal position. Its vertical offset is the same `radius * sin(angle)` used by the sphere. At each full turn, the graph marker returns from the right end to the left.

## The complete study

<!-- student-code:04_circle_coordinates.gd -->

```gdscript
extends Node3D

const PointBody = preload("point_body.gd")
const LineSkin = preload("line_skin.gd")
@export var centre := Vector3(0, 1.5, 0)
@export var radius := 1.0
@export var angle := 0.0
@export var angular_speed := PI / 2.0
@export var running := true
var point: RigidBody3D
var marker: MeshInstance3D
var label: Label3D
var rods: Array[MeshInstance3D] = []

func circle_position(theta: float) -> Vector3:
    return centre + radius * Vector3(cos(theta), sin(theta), 0)

func graph_position(theta: float) -> Vector3:
    return centre + Vector3(1.6 + 4.0 * theta / TAU, radius * sin(theta), 0)

func line_between(a: Vector3, b: Vector3, colour: Color) -> MeshInstance3D:
    var line := LineSkin.new()
    line.material_override.albedo_color = colour
    add_child(line)
    line.show_segment(a, b - a, a.distance_to(b))
    return line

func _ready() -> void:
    point = PointBody.new()
    point.enabled = false
    point.collision_layer = 0
    point.collision_mask = 0
    add_child(point)
    var ink := StandardMaterial3D.new()
    ink.albedo_color = Color(0.035, 0.035, 0.04)
    ink.roughness = 0.22
    point.get_child(0).material_override = ink
    marker = MeshInstance3D.new()
    var cube := BoxMesh.new()
    cube.size = Vector3.ONE * 0.09
    marker.mesh = cube
    add_child(marker)
    var grey := Color(0.45, 0.45, 0.45)
    for i in range(48):
        var a := TAU * i / 48.0
        var b := TAU * (i + 1) / 48.0
        line_between(circle_position(a), circle_position(b), grey)
        line_between(graph_position(a), graph_position(b), grey)
    line_between(centre - Vector3.RIGHT * 1.2, centre + Vector3.RIGHT * 1.2, grey)
    line_between(centre - Vector3.UP * 1.2, centre + Vector3.UP * 1.2, grey)
    for colour in [grey, Color(0.2, 0.75, 0.35), Color(0.2, 0.5, 0.95), grey]:
        rods.append(line_between(centre, centre, colour))
    label = Label3D.new()
    label.position = centre + Vector3(2.4, 1.4, 0)
    label.font_size = 30
    label.pixel_size = 0.006
    label.outline_size = 8
    add_child(label)
    draw_state()

func _process(delta: float) -> void:
    if running:
        angle = fposmod(angle + angular_speed * delta, TAU)
    draw_state()

func draw_state() -> void:
    var p := circle_position(angle)
    point.position = p
    marker.position = graph_position(angle)
    var starts := [centre, Vector3(p.x, centre.y, centre.z), Vector3(centre.x, p.y, centre.z), p]
    var ends := [p, p, p, marker.position]
    for i in range(rods.size()):
        var displacement: Vector3 = ends[i] - starts[i]
        rods[i].show_segment(starts[i], displacement, displacement.length())
    label.text = "angle %.2f rad | x %+.2f m | y %+.2f m\nGRAPH: horizontal = angle; vertical = y offset" % [angle, p.x - centre.x, p.y - centre.y]
```


`circle_position()` returns a position without creating a new body. The centre supplies the location; the radius scales the two ratios. Keeping the centre outside that multiplication lets us move the construction without enlarging its distance from the origin.

The two short coloured rods show signed offsets through their endpoints. A rod has positive physical length even when its coordinate is negative; the readout supplies the sign. The grey connector joins the point to the graph marker at their shared height.

The loop in `_ready()` samples the two outlines once. It reuses the line renderer; it is drawing assistance, not another motion system. `_process()` advances one shared angle with `delta`, then updates both markers. There are no competing clocks. Change the radius or centre before running again so the sampled outlines and the moving markers use the same settings.

## Predict, stop, inspect

Set `running` to `false` and try these starting angles, rerunning after each edit. These are offsets from the centre, not world positions.

| Angle | X offset at radius 1 | Y offset at radius 1 |
| --- | --- | --- |
| `0.0` | +1 m | 0 m |
| `PI / 2.0` | 0 m | +1 m |
| `PI` | −1 m | 0 m |
| `3.0 * PI / 2.0` | 0 m | −1 m |

Restart with `running = true`. Half the angular speed: the same circle takes twice as long. Its radius and the graph's height do not change.

Now work independently: set the radius to `0.5` and the centre to `(0.5, 1.5, 0)`. Predict the top point's local position before running. Explain why the graph becomes half as high while its angle axis stays four metres wide. A successful variation preserves the shared height and the circle's distance from its new centre.

## Carried files

These are the unchanged PointBody from the preceding lessons and LineSkin from Lines. Keep your existing copies if they match. They provide the sphere and cylinder drawing; the new lesson is the coordinate function above.

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


<!-- student-code:line_skin.gd -->

```gdscript
# Supplied renderer, adapted from commons/primitives/line/line.gd.
# This finite cylinder gives the segment a visible thickness. It is not a collider.
# Inputs share the parent station's local frame; that station has unit scale.
extends MeshInstance3D

func _init() -> void:
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.012
	cylinder.bottom_radius = 0.012
	cylinder.radial_segments = 16
	cylinder.rings = 0
	mesh = cylinder
	var finish := StandardMaterial3D.new()
	finish.albedo_color = Color(0.98, 0.70, 0.82)
	finish.roughness = 0.3
	material_override = finish
	visible = false

func show_segment(start: Vector3, displacement: Vector3, distance: float) -> void:
	# A zero-length segment has no direction. Do not normalize it.
	visible = distance > 0.0001
	if not visible:
		return
	(mesh as CylinderMesh).height = distance
	position = start + displacement * 0.5
	# CylinderMesh runs along local Y. This borrowed basis aligns it to the ends.
	var direction := displacement / distance
	var right := direction.cross(Vector3.UP).normalized()
	if right.length() < 0.001:
		right = Vector3.RIGHT
	var depth := right.cross(direction).normalized()
	basis = Basis(right, direction, depth)
```


One angular state now produces a visible position and two coordinate readings. In the next hall, many moving bodies will affect one another. A shared trigonometric formula alone does not make that coupling.


---

# Propagation — a neighbour responds

## Learning elements

- Neighbour coupling through displacement differences.
- One old state and a separate next state.
- Propagation through coupling, distinguished from phase-delayed animation.
- Boundary points with fewer neighbours.

In the museum, find the lattice of small spheres. Press SINE to select PULSE. The centre receives one push after half a second. Follow a nearby sphere. Now press COUPLED to select INDEPENDENT: the trial restarts, but that neighbour stays still. Restore COUPLED and watch again. The source repeats the same action; the links change what can receive it.

In Unit Circle, we prescribed the point's position from an angle. Here we carry its PointBody shape into a row of nine points. Each keeps a displacement and a velocity, as in Forces. Arrays hold their states. The new operation lets a difference between neighbouring displacements contribute force.

## Build beside the existing lattice

Use the Endless Museum and installed XR Tools from Day Zero. Save the three files below together. Attach `05_neighbour_motion.gd` to an empty Node3D in this hall's entrance bay: hall-local `(12, 0, 11)`, Y rotation `180°`, scale `1`. The museum supplies the player, camera, light and floor. The script creates all the points, rods and readout. It does not control the existing exhibit.

These points move only vertically. Their resting centres are 1.4 metres above the floor, spaced half a metre apart. Displacement is an offset in metres; velocity is metres per second. `restoring` and `coupling` are spring coefficients in newtons per metre; `damping` is newton-seconds per metre; `mass` is kilograms.

The point's pickup and collision are disabled for this study. Our arrays now govern its motion. Jolt must not add another integration of gravity or contact to that same movement. We keep the familiar sphere, while stating what its role has changed to.

## The complete study

<!-- student-code:05_neighbour_motion.gd -->

```gdscript
extends Node3D

const PointBody = preload("point_body.gd")
const LineSkin = preload("line_skin.gd")
@export var count := 9
@export var spacing := 0.5
@export var mass := 1.0
@export var restoring := 4.0
@export var coupling := 12.0
@export var damping := 0.3
@export var running := true
var displacement: Array[float] = []
var velocity: Array[float] = []
var points: Array[RigidBody3D] = []
var links: Array[MeshInstance3D] = []
var label: Label3D
var elapsed := 0.0

func _ready() -> void:
    assert(count >= 3 and mass > 0.0)
    for i in range(count):
        var point := PointBody.new()
        point.enabled = false
        point.collision_layer = 0
        point.collision_mask = 0
        add_child(point)
        var ink := StandardMaterial3D.new()
        ink.albedo_color = Color(0.95, 0.45, 0.65) if i == count / 2 else Color(0.04, 0.04, 0.05)
        ink.roughness = 0.25
        point.get_child(0).material_override = ink
        points.append(point)
        if i > 0:
            var link := LineSkin.new()
            add_child(link)
            links.append(link)
    label = Label3D.new()
    label.position = Vector3(0, 2.5, 0)
    label.font_size = 30
    label.pixel_size = 0.004
    add_child(label)
    reset()

func reset() -> void:
    displacement.resize(count)
    velocity.resize(count)
    displacement.fill(0.0)
    velocity.fill(0.0)
    displacement[count / 2] = 0.6
    elapsed = 0.0
    draw_state()

func _physics_process(delta: float) -> void:
    if running:
        step(delta)
    draw_state()

func step(delta: float) -> void:
    var next_displacement := displacement.duplicate()
    var next_velocity := velocity.duplicate()
    for i in range(count):
        var force := -restoring * displacement[i] - damping * velocity[i]
        for j in [i - 1, i + 1]:
            if j >= 0 and j < count:
                force += coupling * (displacement[j] - displacement[i])
        next_velocity[i] = velocity[i] + force / mass * delta
        next_displacement[i] = displacement[i] + next_velocity[i] * delta
    displacement = next_displacement
    velocity = next_velocity
    elapsed += delta

func draw_state() -> void:
    for i in range(count):
        points[i].position = Vector3((i - (count - 1) * 0.5) * spacing, 1.4 + displacement[i], 0)
    for i in range(links.size()):
        var a := points[i].position
        var difference := points[i + 1].position - a
        links[i].show_segment(a, difference, difference.length())
        links[i].visible = coupling > 0.0
    label.text = "t %.2f s | coupling %.1f N/m\ncentre %+.3f m | next %+.3f m" % [elapsed, coupling, displacement[count / 2], displacement[count / 2 + 1]]
```


`reset()` raises only the middle point by 0.6 metres and leaves every velocity at zero. This is our release condition. The museum exhibit instead applies a velocity pulse; both comparisons begin with a local disturbance, but they do not begin with the same state.

Read the force calculation as three contributions. Restoring force draws a point towards its resting height. Damping opposes its velocity. Each neighbour contributes `coupling * (displacement[j] - displacement[i])`. If the neighbour is higher, that contribution pulls upward. If their offsets agree, it contributes zero. This is a simplified vertical spring relation, not a full 3D elastic rod.

The indices `i - 1` and `i + 1` name the neighbours. The bounds check gives the end points one neighbour each. It does not connect the ends into a loop or hold them fixed. Each end still has its own restoring force and damping.

## Everyone reads the same moment

The two `duplicate()` calls create separate next-state arrays. Every force reads the old `displacement` and `velocity`. Only after all points have been calculated do we replace those arrays. Updating `displacement[i]` inside the loop would let later points read some already-updated neighbours. The array's traversal order would then become part of the model.

Within each point's next state, force divided by mass changes velocity; the **new** velocity changes displacement. This is the velocity-first Euler step used in the museum lattice. `_physics_process()` supplies the physics timestep. The given coefficients work at the project's normal 60 physics ticks per second; arbitrary large timesteps or spring strengths can make this numerical method unstable.

`draw_state()` gives the stored values bodies. The rods show the declared connections and disappear when coupling is zero. They do not exert force or collide. The force comes from `step()`, even with the drawing hidden.

## Predict, then compare

Before running, predict the first update. The raised centre begins to fall. Its two immediate neighbours begin to rise equally. The points beyond those neighbours do not move on this first step: their old neighbours were still at rest. Later steps carry the disturbance farther.

Run with `coupling = 0.0`, then restart with `12.0`. All other values and the initial raised point stay the same. Without coupling, only the centre moves. With it, neighbouring points respond. A crest passes through the row while each sphere keeps its horizontal address.

Now make an independent version with `count = 7`. Predict which index starts raised and which points should match across the centre. Change the initial displacement from `0.6` to `0.3` and rerun. At matching simulated times the offsets should be half as large: the rule is linear. The row remains symmetric, with one neighbour at each end. Explain those results before adding more points.

## Carried files

PointBody and LineSkin are unchanged from Unit Circle. Keep matching copies if you already have them. They supply the visible sphere and thin cylinder; the new work is the relation between stored states.

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


<!-- student-code:line_skin.gd -->

```gdscript
# Supplied renderer, adapted from commons/primitives/line/line.gd.
# This finite cylinder gives the segment a visible thickness. It is not a collider.
# Inputs share the parent station's local frame; that station has unit scale.
extends MeshInstance3D

func _init() -> void:
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.012
	cylinder.bottom_radius = 0.012
	cylinder.radial_segments = 16
	cylinder.rings = 0
	mesh = cylinder
	var finish := StandardMaterial3D.new()
	finish.albedo_color = Color(0.98, 0.70, 0.82)
	finish.roughness = 0.3
	material_override = finish
	visible = false

func show_segment(start: Vector3, displacement: Vector3, distance: float) -> void:
	# A zero-length segment has no direction. Do not normalize it.
	visible = distance > 0.0001
	if not visible:
		return
	(mesh as CylinderMesh).height = distance
	position = start + displacement * 0.5
	# CylinderMesh runs along local Y. This borrowed basis aligns it to the ends.
	var direction := displacement / distance
	var right := direction.cross(Vector3.UP).normalized()
	if right.length() < 0.001:
		right = Vector3.RIGHT
	var depth := right.cross(direction).normalized()
	basis = Basis(right, direction, depth)
```


Return to the museum lattice. It extends the relation over a two-dimensional array, including diagonal neighbours; our row has only left and right neighbours. The nearby tiled field uses a different mechanism: it calculates each tile's height from distance and time. A similar-looking wave does not establish the same connection between its parts. In Effect Sound, we will meet another relationship: one oscillation changes another's phase.


---

# Effect Sound — a phase you can hear

## Learning elements

- Phase modulation: one sine inside another.
- A hand position selecting one parameter.
- Retaining a reference for comparison.
- Supporting construction: a sampled note and its envelope.

At the two desks in the museum, press BASELINE and then HOLD. Keep the blue ball still. Lift the orange ball, let it settle, then press COMPARE. Listen through both notes. The instrument can change six values; begin with one: the depth of phase modulation.

Unit Circle gave an angle two coordinates. Propagation made one point respond to its neighbours. Here we prescribe a signal again. A second sine changes the first sine's phase. The result goes to the speaker instead of moving a body.

**Build:** use the carried point to change modulation depth and compare the result with a saved note. **Investigate:** explain why changing the frequency ratio has no effect at depth zero, then listen with modulation present. Keep the note length, envelopes and encoder fixed during this comparison.

## Carry the point; give it one job

Keep the same `point_body.gd` and `line_skin.gd`. The point is pickable again. Its height selects a phase depth from zero to four radians; its other two coordinates do nothing in this study. The line class draws a small view of the resulting signal.

In your museum working copy, attach `06_phase_note.gd` to an empty, unit-scale `Node3D` in the clear study bay beside the two-desk instrument. Place the root at hall-local `(7, 0, 10)` and turn it 180 degrees around Y to face the entrance. The hall's floor, light, player and XR pickup/trigger routing are supplied by Day Zero. This script creates its own point, display, audio player and sound data; it has no references to pre-existing meshes.

The complete three files are below. Only the first is new. Begin your close reading with `phase_depth()` and the first two lines of `sample_at()`: height selects an amount, and that amount changes phase. `make_note()` stores the resulting samples for playback. Its encoding is supplied support, explained after the experiment; you do not need to redesign it to make another sound. Put all three files together in one folder and keep the single `_ready()` shown.

<!-- student-code:06_phase_note.gd -->

```gdscript
extends Node3D

const PointBody = preload("point_body.gd")
const LineSkin = preload("line_skin.gd")
const SAMPLE_RATE := 44100
const DURATION := 0.6
const ATTACK := 0.01
@export var frequency := 440.0
@export var ratio := 2.0
var point: RigidBody3D
var label: Label3D
var player: AudioStreamPlayer3D
var reference: AudioStreamWAV
var rods: Array[MeshInstance3D] = []
var last_index := 0.0
var busy := false

func phase_depth() -> float:
    return 4.0 * clampf((point.position.y - 1.0) / 0.6, 0.0, 1.0)

func sample_at(t: float, depth: float) -> float:
    var modulator := depth * exp(-t / 0.25) * sin(TAU * frequency * ratio * t)
    var carrier := sin(TAU * frequency * t + modulator)
    var envelope := minf(t / ATTACK, 1.0) * exp(-maxf(t - ATTACK, 0.0) / 0.3)
    envelope *= clampf((DURATION - t) / 0.02, 0.0, 1.0)
    return 0.5 * tanh(0.8 * carrier * envelope)

func make_note(depth: float) -> AudioStreamWAV:
    var bytes := PackedByteArray()
    var count := int(SAMPLE_RATE * DURATION)
    bytes.resize(count * 2)
    for i in range(count):
        var t := float(i) / SAMPLE_RATE
        bytes.encode_s16(i * 2, int(sample_at(t, depth) * 32767.0))
    var note := AudioStreamWAV.new()
    note.format = AudioStreamWAV.FORMAT_16_BITS
    note.mix_rate = SAMPLE_RATE
    note.stereo = false
    note.data = bytes
    return note

func _ready() -> void:
    point = PointBody.new()
    point.position = Vector3(0, 1.0, 0)
    add_child(point)
    var ink := StandardMaterial3D.new()
    ink.albedo_color = Color(0.04, 0.04, 0.045)
    ink.roughness = 0.2
    point.get_child(0).material_override = ink
    point.action_pressed.connect(func(_body): play_pair())
    player = AudioStreamPlayer3D.new()
    player.position = Vector3(0, 1.2, 0)
    player.volume_db = -12.0
    player.max_distance = 7.0
    add_child(player)
    label = Label3D.new()
    label.position = Vector3(0, 2.05, 0)
    label.font_size = 30
    label.pixel_size = 0.004
    add_child(label)
    for i in range(96):
        var line := LineSkin.new()
        add_child(line)
        rods.append(line)
    reference = make_note(0.0)
    draw_state()

func _process(_delta: float) -> void:
    draw_state()

func graph_point(i: int, depth: float) -> Vector3:
    var fraction := float(i) / rods.size()
    var t := ATTACK + fraction * 2.0 / frequency
    return Vector3(-1.1 + 2.2 * fraction, 1.4 + 1.2 * sample_at(t, depth), -0.35)

func draw_state() -> void:
    var depth := phase_depth()
    for i in range(rods.size()):
        var a := graph_point(i, depth)
        var b := graph_point(i + 1, depth)
        rods[i].show_segment(a, b - a, a.distance_to(b))
    label.text = "Raise the point: phase depth %.2f rad\nHold + trigger: A, then B | last B %.2f\nScope: two carrier periods near the attack" % [depth, last_index]

func play_pair() -> void:
    if busy:
        return
    busy = true
    last_index = phase_depth()
    var changed := make_note(last_index)
    player.stream = reference
    player.play()
    await get_tree().create_timer(DURATION + 0.25).timeout
    player.stream = changed
    player.play()
    await get_tree().create_timer(DURATION).timeout
    busy = false
```


## Read the operation

Start with `sample_at`. `t` is seconds since the note began. Multiplying frequency by `TAU` changes cycles per second into radians per second. The carrier is 440 Hz. With ratio two, the modulator is 880 Hz.

The modulator is added **inside** the carrier's sine. At depth zero that term vanishes. Increasing it advances and delays the carrier's phase. Adding two completed sine outputs would mix two voices instead: that is a different operation. The museum artifact retains the name FM; the expression we are reading directly modulates phase.

The envelopes give the note its beginning and ending, and let the modulation fade within it. Keep them unchanged so you can hear the effect of depth and ratio. The zero-depth reference still passes through the same envelope and output shaping.

## Make a comparison

Hold the point at one metre above the study root and press the trigger. A and B should match. Raise it to 1.3 metres: predict depth two before reading the label. Press again. A is the stored zero-depth note; B is rendered from the depth at that press. A quarter-second gap separates them. Moving during the pair changes the display and the next choice, but cannot rewrite either captured note. The `busy` condition lets this pair finish before accepting another trigger.

We use the point's **local** height, learned in Coordinates. Rotating or translating the study root therefore carries its reference frame with it. The audio player stays at the study, so moving the control does not also move the sound source.

The scope shows two carrier periods starting at the attack time—about 4.5 milliseconds at 440 Hz. Its 96 segments draw a selected window, not all 26,460 audio samples and not a microphone recording. Let the full note finish before deciding what the picture leaves out.

## Make another relation

Change only `ratio` from `2.0` to `1.5`. Predict the modulator frequency: 660 Hz while the carrier stays at 440. First compare at depth zero, where the ratio cannot affect the note. Then raise the point and compare again. Explain why one edit is silent at zero depth and becomes audible when the modulation contributes. Keep a setting because you want to return to it, even if you cannot name its timbre.

The existing two-ball instrument remains a larger encounter: its blue ball also changes carrier frequency, attack and decay; its orange ball also changes ratio and modulation decay. Its HOLD button can preserve any chosen setting. Our smaller study keeps these fixed so the phase operation can be reconstructed and tested.

## How the note is kept

The supporting code makes a finite recording of the signal you selected. `make_note` brings back Trace's list and loop, now as a packed byte array. It evaluates 26,460 samples for a 0.6-second note. The time step is `1 / 44100` seconds; it is unrelated to the display's frame rate. Each signed 16-bit sample occupies two bytes, so sample `i` starts at byte `i * 2`. `AudioStreamWAV` receives those bytes and their sample rate. Keep this encoder for the later sound lessons.

The two envelopes have different jobs. `exp(-t / 0.25)` makes the modulation fade. The carrier envelope rises over 0.01 seconds and decays with a 0.3-second time constant. After one time constant an exponential retains about 37 percent of its initial value. It has not reached zero. A final 0.02-second fade closes our finite note; the larger museum instrument has a different buffer-ending rule. Both use `tanh` to shape the output.

Bernini returns to spatial composition. We will use angle to place successive profiles through height, then keep that form while a separate clock rotates it. Retain the sound functions too: Cage will reuse them to make a score, and Air Music will give each struck voice its own beginning.

## Carried code

`point_body.gd` — unchanged point, including the XR pickable behaviour already used in Coordinates.

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


`line_skin.gd` — unchanged finite cylinder between two positions.

<!-- student-code:line_skin.gd -->

```gdscript
# Supplied renderer, adapted from commons/primitives/line/line.gd.
# This finite cylinder gives the segment a visible thickness. It is not a collider.
# Inputs share the parent station's local frame; that station has unit scale.
extends MeshInstance3D

func _init() -> void:
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.012
	cylinder.bottom_radius = 0.012
	cylinder.radial_segments = 16
	cylinder.rings = 0
	mesh = cylinder
	var finish := StandardMaterial3D.new()
	finish.albedo_color = Color(0.98, 0.70, 0.82)
	finish.roughness = 0.3
	material_override = finish
	visible = false

func show_segment(start: Vector3, displacement: Vector3, distance: float) -> void:
	# A zero-length segment has no direction. Do not normalize it.
	visible = distance > 0.0001
	if not visible:
		return
	(mesh as CylinderMesh).height = distance
	position = start + displacement * 0.5
	# CylinderMesh runs along local Y. This borrowed basis aligns it to the ends.
	var direction := displacement / distance
	var right := direction.cross(Vector3.UP).normalized()
	if right.length() < 0.001:
		right = Vector3.RIGHT
	var depth := right.cross(direction).normalized()
	basis = Basis(right, direction, depth)
```


Implementation references: [Godot AudioStreamWAV](https://docs.godotengine.org/en/stable/classes/class_audiostreamwav.html) and [PackedByteArray](https://docs.godotengine.org/en/stable/classes/class_packedbytearray.html). The museum expression is in `algorithms/wavefunctions/mariocontrol/DualBallFMController.gd`; this study reduces its controls rather than reproducing its whole interface.


---

# Bernini — a turn through height

## Learning elements

- Sampling an oval profile in rings.
- Giving each ring an angle according to its height.
- Connecting neighbouring rings with triangle faces.
- Separating stored geometry from whole-object rotation.

Walk between the museum's columns. Follow one ridge upward. Then keep your gaze at one height while the shaft turns past it. You are following two changes: one through height, the other through time.

Effect Sound put one sine inside another's phase. Here we return to Unit Circle's coordinates and Primitives' connected faces. A rising sequence of angles becomes a shape. We will build a small shaft beside the existing installation, using an oval profile so its orientation is easy to see.

## Carry the point as a control

Keep `point_body.gd` and `line_skin.gd` unchanged. The same black sphere now selects the amount of twist. Its trigger starts or stops rotation of the finished shaft. The pink line follows the same numbered corner up through the rings.

In your prepared museum working copy, attach `07_twisted_shaft.gd` to an empty, unit-scale `Node3D` at hall-local `(5, 0, 10)`, yaw 180 degrees, in the entrance study bay. Keep the three files together. The museum supplies floor, camera, light, player and XR input routing. The script creates the shaft, its low base, control and label. The shaft and base are visual studies without collision; the carried sphere retains its pickup collider.

Start with the shaft still. Lower the sphere to local height 0.8 metres: the profiles line up. Raise it to 1.2 metres: they make half a turn over the shaft's height. At 1.6 metres they make one turn. Movement beyond those heights is clamped. Press the trigger while holding the sphere. Watch the whole shaft rotate, then press again. The twist remains when rotation stops.

## Complete program

Only the main script is new. The two carried files are printed below it and included in the download.

<!-- student-code:07_twisted_shaft.gd -->

```gdscript
extends Node3D

const PointBody = preload("point_body.gd")
const LineSkin = preload("line_skin.gd")
@export var height := 2.4
@export var sides := 8
@export var spans := 16
@export var radii := Vector2(0.40, 0.20)
@export var angular_speed := 0.4
var turns := 0.5
var running := false
var points: Array[Vector3] = []
var faces: Array[Vector3i] = []
var shaft := Node3D.new()
var surface := MeshInstance3D.new()
var point: PointBody
var label: Label3D
var witness: Array[MeshInstance3D] = []

func ring_position(row: int, corner: int) -> Vector3:
    var u := float(row) / spans
    var angle := TAU * corner / sides
    var profile := Vector3(radii.x * cos(angle), 0, radii.y * sin(angle))
    return profile.rotated(Vector3.UP, TAU * turns * u) + Vector3(0, 0.25 + height * u, 0)

func turns_from_height() -> float:
    return clampf((point.position.y - 0.8) / 0.8, 0.0, 1.0)

func _ready() -> void:
    add_child(shaft)
    shaft.add_child(surface)
    var ivory := StandardMaterial3D.new()
    ivory.albedo_color = Color(0.91, 0.89, 0.84)
    ivory.roughness = 0.55
    surface.material_override = ivory
    var base := MeshInstance3D.new()
    var cylinder := CylinderMesh.new()
    cylinder.top_radius = 0.55
    cylinder.bottom_radius = 0.55
    cylinder.height = 0.25
    base.mesh = cylinder
    base.position.y = 0.125
    base.material_override = ivory
    add_child(base)
    for row in range(spans):
        var line := LineSkin.new()
        shaft.add_child(line)
        witness.append(line)
    point = PointBody.new()
    point.position = Vector3(1.1, 1.2, 0.4)
    var black := StandardMaterial3D.new()
    black.albedo_color = Color(0.025, 0.025, 0.03)
    black.roughness = 0.18
    point.get_child(0).material_override = black
    add_child(point)
    point.action_pressed.connect(toggle_rotation)
    label = Label3D.new()
    label.position = Vector3(0.5, 3.0, 0)
    label.font_size = 28
    label.pixel_size = 0.004
    add_child(label)
    turns = turns_from_height()
    rebuild()
    draw_label()

func rebuild() -> void:
    points.clear()
    faces.clear()
    for row in range(spans + 1):
        for corner in range(sides):
            points.append(ring_position(row, corner))
    for row in range(spans):
        for corner in range(sides):
            var next := (corner + 1) % sides
            var a := row * sides + corner
            var b := row * sides + next
            var c := a + sides
            var d := b + sides
            faces.append(Vector3i(a, b, c))
            faces.append(Vector3i(b, d, c))
    var bottom := points.size()
    points.append(Vector3(0, 0.25, 0))
    var top := points.size()
    points.append(Vector3(0, 0.25 + height, 0))
    for corner in range(sides):
        var next := (corner + 1) % sides
        faces.append(Vector3i(bottom, next, corner))
        faces.append(Vector3i(top, spans * sides + corner, spans * sides + next))
    var builder := SurfaceTool.new()
    builder.begin(Mesh.PRIMITIVE_TRIANGLES)
    builder.set_smooth_group(-1)
    for face in faces:
        for index in [face.x, face.y, face.z]:
            builder.add_vertex(points[index])
    builder.generate_normals()
    surface.mesh = builder.commit()
    for row in range(spans):
        var a := points[row * sides]
        var b := points[(row + 1) * sides]
        witness[row].show_segment(a, b - a, a.distance_to(b))

func toggle_rotation(_held: Variant) -> void:
    running = not running
    draw_label()

func _process(delta: float) -> void:
    var selected := turns_from_height()
    if absf(selected - turns) > 0.002:
        turns = selected
        rebuild()
    if running:
        shaft.rotate_y(angular_speed * delta)
    draw_label()

func draw_label() -> void:
    label.text = "LIFT: %.2f turns through height\nTRIGGER: whole-object rotation %s" % [turns, "ON" if running else "OFF"]
```


## Read the shape

In `ring_position`, `corner` goes around one profile; `row` moves up the shaft. Dividing the row by `spans` gives `u`, from zero at the bottom to one at the top. The height is `0.25 + height * u`: the first quarter metre belongs to the base.

Cosine supplies X and sine supplies Z, as in Unit Circle, now on a horizontal plane. The unequal radii, 0.40 and 0.20 metres, make an oval. We rotate that profile around Y by `TAU * turns * u`. At half height, the angle is half the total turn. This multiplication has no clock in it. With the default half-turn, corner zero begins at `(0.40, 0.25, 0)`, passes through `(0, 1.45, -0.40)` and ends at `(-0.40, 2.65, 0)`.

A perfectly circular cross-section has no preferred orientation. Merely rotating such a section about its centre cannot give its ideal outline a visible twist. Our oval makes the operation legible. The larger museum columns also move their ring centres and vary their radius. This small study isolates one part of their construction; it does not reproduce every feature or an historical building.

## Connect the rings

Eight corners on each of seventeen rings give 136 positions. Sixteen *spans* are the spaces between those rings. The list still has one dimension: `row * sides + corner` gives an address, just as Grid used a row and column to find an entry.

For each span, `a` and `b` are neighbouring corners on its lower ring; `c` and `d` are the corresponding corners above. The triples `(a, b, c)` and `(b, d, c)` make two triangles. `% sides` wraps the last corner back to zero on the same ring. Without that wrap, the seam would connect the wrong entries. Two centre positions and triangle fans close the bottom and top. We end with 138 positions and 272 faces.

The renderer reads each face's three addresses, adds those positions and generates normals for lighting. The smoothing group of `-1` keeps each triangle flat, so the finite facets and cap edges remain visible. This is the face-list approach used in Polyhedra and Sine Space. The pink line is an added guide through corner zero, not an edge that the surface needs in order to exist.

## Stop the clock without losing the form

Lifting the sphere changes `turns`, so `rebuild` calculates new positions. The face relationships remain the same. Small hand changes below the stated 0.002-turn threshold are ignored to avoid needless rebuilds.

The trigger only changes `running`. While it is true, `rotate_y` changes the parent shaft's orientation by radians per second times `delta`. The stored positions and mesh resource stay unchanged. Stopping preserves the current pose; it does not straighten the shaft. The witness line is a child of the same shaft, so it turns with the surface. The control remains outside that rotating parent.

## Make another shaft

Change `height` from `2.4` to `3.6` and run again. Predict what happens at half height and at the top. The same half-turn is spread over a longer distance; the top's orientation stays the same. Then change `sides` from eight to twelve. The profile has more samples, while height and total turn remain fixed. Explain which edit changed spacing along the shaft and which changed sampling around it.

Keep a form you want to return to. Its list of positions remains when rotation stops. In John Cage, a list will keep sounds and their times instead. We return to the audio functions from Effect Sound and add the decisions about when to play them. The new subject is a score that can be performed again.

## Carried code

`point_body.gd` — the existing point and pickup behaviour.

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


`line_skin.gd` — the existing finite cylinder between two positions.

<!-- student-code:line_skin.gd -->

```gdscript
# Supplied renderer, adapted from commons/primitives/line/line.gd.
# This finite cylinder gives the segment a visible thickness. It is not a collider.
# Inputs share the parent station's local frame; that station has unit scale.
extends MeshInstance3D

func _init() -> void:
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.012
	cylinder.bottom_radius = 0.012
	cylinder.radial_segments = 16
	cylinder.rings = 0
	mesh = cylinder
	var finish := StandardMaterial3D.new()
	finish.albedo_color = Color(0.98, 0.70, 0.82)
	finish.roughness = 0.3
	material_override = finish
	visible = false

func show_segment(start: Vector3, displacement: Vector3, distance: float) -> void:
	# A zero-length segment has no direction. Do not normalize it.
	visible = distance > 0.0001
	if not visible:
		return
	(mesh as CylinderMesh).height = distance
	position = start + displacement * 0.5
	# CylinderMesh runs along local Y. This borrowed basis aligns it to the ends.
	var direction := displacement / distance
	var right := direction.cross(Vector3.UP).normalized()
	if right.length() < 0.001:
		right = Vector3.RIGHT
	var depth := right.cross(direction).normalized()
	basis = Basis(right, direction, depth)
```


Implementation reference: [Godot SurfaceTool](https://docs.godotengine.org/en/stable/classes/class_surfacetool.html). The larger museum generator is `algorithms/wavefunctions/berninicolumns/BerniniColumns.gd`. It constructs a mesh on the CPU; this lesson does not require a vertex shader or noise.


---

# John Cage — a score kept

## Learning elements

- Choosing from a finite sound vocabulary.
- Keeping an event's time and sound index in a dictionary.
- Reading an ordered event list with a clock and cursor.
- Replaying a record without drawing new choices.

Let the museum's soundscape finish loading. Hear the continuing background, then wait for a separate event. You do not know its next entrance. Its possible sounds have nevertheless been prepared.

Bernini separated a stored form from its movement. Here we separate a score from its performance. Build a six-event study beside the existing soundscape. Make the choices once, keep them, then listen to that record again.

The sounds use oscillators, but choosing when to play them is not itself oscillation. Chance interrupts the expectation of a regular return. We carry timing and a retained record into this different operation: what must a replay preserve? Two bounded random calls supply the choices; the lesson follows the resulting event list. Distributions, seeds and other ways of choosing belong to the later Randomness sequence.

## Carry the sound and the point

Keep `point_body.gd` and `line_skin.gd`. Copy the two sound-making functions from Effect Sound into `note_voice.gd`; their sample calculation is unchanged. Three modulation depths give us three short sounds at the same base pitch. Sound synthesis is carried material here. Choosing and scheduling those sounds is the new work.

In your prepared Endless Museum working copy, put all four files together. Attach `08_chance_score.gd` to an empty, unit-scale `Node3D` at hall-local `(16, 0, 10)`, yaw 180 degrees. This is the entrance study bay. The museum supplies the floor, camera, light, player and XR pickup/trigger routing. The script creates its point, score markers, labels and audio players. Only the point has a pickup collider; the score is a visual display.

Grab the black point. Hold it left of the study's centre and press the trigger to replay. Hold it on the right and press to make a new score and play it. The label names the selected action. Both actions restart the clock. Releasing the sphere keeps it where you leave it. Left and right use the study's **local X**, so turning the whole study does not reverse its own controls.

Read the score before playing. Horizontal position represents seconds from the start; the three rows are sound indices, zero to two. The small cubes are six events. Their labels give their times. The vertical guide moves across the record, and events turn pink as they are dispatched. All six notes sound from one position in the study; the display is a timeline, not an arrangement of six spatial sound sources.

## Complete program

<!-- student-code:08_chance_score.gd -->

```gdscript
extends Node3D

const PointBody = preload("point_body.gd")
const LineSkin = preload("line_skin.gd")
const NoteVoice = preload("note_voice.gd")
signal event_started(index: int)
var min_interval := 0.8
var max_interval := 1.6
var rng := RandomNumberGenerator.new()
var score: Array[Dictionary] = []
var notes: Array[AudioStreamWAV] = []
var players: Array[AudioStreamPlayer3D] = []
var markers: Array[MeshInstance3D] = []
var captions: Array[Label3D] = []
var point: RigidBody3D
var label: Label3D
var playhead: MeshInstance3D
var elapsed := 0.0
var cursor := 0
var playing := false

func text_at(words: String, at: Vector3, size: int = 26) -> Label3D:
    var text := Label3D.new()
    text.text = words
    text.position = at
    text.font_size = size
    text.pixel_size = 0.003
    add_child(text)
    return text

func _ready() -> void:
    rng.randomize()
    var voice := NoteVoice.new()
    for depth in [0.0, 1.0, 3.0]:
        notes.append(voice.make_note(depth))
    point = PointBody.new()
    point.position = Vector3(-0.65, 1.0, 1.0)
    add_child(point)
    var ink := StandardMaterial3D.new()
    ink.albedo_color = Color(0.04, 0.04, 0.045)
    ink.roughness = 0.2
    point.get_child(0).material_override = ink
    point.action_pressed.connect(func(_body): activate())
    text_at("REPLAY", Vector3(-0.65, 0.68, 1.0))
    text_at("NEW + PLAY", Vector3(0.65, 0.68, 1.0))
    label = text_at("", Vector3(0, 2.35, 0), 30)
    for lane in range(notes.size()):
        var line := LineSkin.new()
        add_child(line)
        line.show_segment(Vector3(-1.8, 0.95 + 0.4 * lane, 0), Vector3(3.8, 0, 0), 3.8)
        text_at("%d" % lane, Vector3(-2.0, 0.95 + 0.4 * lane, 0))
    playhead = LineSkin.new()
    add_child(playhead)
    for i in range(6):
        var marker := MeshInstance3D.new()
        var box := BoxMesh.new()
        box.size = Vector3(0.12, 0.12, 0.12)
        marker.mesh = box
        marker.material_override = StandardMaterial3D.new()
        add_child(marker)
        markers.append(marker)
        captions.append(text_at("", Vector3.ZERO, 20))
        var player := AudioStreamPlayer3D.new()
        player.position = Vector3(0, 1.2, 0)
        player.volume_db = -18.0
        player.max_distance = 7.0
        add_child(player)
        players.append(player)
    new_score()
    draw_state()

func new_score() -> void:
    score.clear()
    var at := 0.0
    for i in range(players.size()):
        at += rng.randf_range(min_interval, max_interval)
        var voice := rng.randi_range(0, notes.size() - 1)
        score.append({"at": at, "voice": voice})
        markers[i].position = Vector3(-1.8 + 0.35 * at, 0.95 + 0.4 * voice, 0)
        captions[i].position = markers[i].position + Vector3(0, 0.17, 0)
        captions[i].text = "%.2fs" % at

func replay() -> void:
    for player in players:
        player.stop()
    elapsed = 0.0
    cursor = 0
    playing = true
    draw_state()

func activate() -> void:
    if point.position.x >= 0.0:
        new_score()
    replay()

func _process(delta: float) -> void:
    if playing:
        elapsed += delta
        while cursor < score.size() and float(score[cursor].at) <= elapsed:
            players[cursor].stream = notes[int(score[cursor].voice)]
            players[cursor].play()
            event_started.emit(cursor)
            cursor += 1
        if elapsed >= float(score[-1].at) + NoteVoice.DURATION:
            playing = false
    draw_state()

func draw_state() -> void:
    var end := float(score[-1].at)
    var x := -1.8 + 0.35 * minf(elapsed, end)
    playhead.show_segment(Vector3(x, 0.8, 0.05), Vector3(0, 1.1, 0), 1.1)
    for i in range(markers.size()):
        markers[i].material_override.albedo_color = Color(1, 0.5, 0.7) if i < cursor else Color(0.06, 0.06, 0.07)
    var choice := "REPLAY" if point.position.x < 0.0 else "NEW + PLAY"
    label.text = "Six events kept | seconds across, voice up\nHold point + trigger: %s\n%.2f s | %d / 6" % [choice, elapsed, cursor]
```


## Choose once

`notes` holds three generated clips. `rng.randi_range(0, notes.size() - 1)` chooses a valid index, including both ends of that range. `randf_range` chooses the wait before an event. Both calls return a value within the limits we give them.

In `new_score`, `at` begins at zero and **accumulates** the waits. Waits of 1.0, 0.8 and 1.4 seconds produce event times 1.0, 1.8 and 3.2. They do not produce three unrelated delays measured from now. Every wait is positive, so the event list is already in time order.

Each dictionary keeps two named fields: `at` is a time in seconds; `voice` is an address in `notes`. The array keeps their order. This extends Trace's retained list: a record can carry several related values rather than only a position. Neither the row number nor the timestamp contains the sound itself.

The generator runs when the study starts and when you choose NEW. It does not run on every frame. A new draw can repeat an earlier choice; randomness does not promise novelty. The current score survives replay, but only while this study exists. We are not yet writing it to a file.

## Read the record

`replay` stops the players and resets the clock and `cursor`. It leaves `score` and the random generator untouched. `cursor` is the address of the next event, starting at zero. Every frame, `elapsed` grows by `delta`. When an event's stored time has arrived, its player receives the chosen clip and starts.

The `while` matters. A slow frame can cross more than one event time. The loop dispatches every overdue event in order and advances the cursor after each one. An `if` would dispatch only one per frame and could leave overdue events waiting. Six players allow overdue notes to overlap instead of replacing one another in a single player. `event_started` reports the dispatched index; the tests use that signal to inspect what happened.

This is a frame-timed sequencer. If a frame is very late, overdue notes start together. The saved choices and intended times remain the same; the heard timing is not sample-accurate. Effect Sound calculated samples at 44,100 per second. Starting playback from `_process` is a different clock, with frame and audio-buffer delays.

## Predict, replay, change

Read the first event's row and time aloud. Trigger REPLAY. Check its entrance and the moving guide. Replay again: every marker must remain in place, with the same row and timestamp. Then choose NEW. The displayed choices are replaced and the clock starts again. The larger museum soundscape continues independently; it does not share this replay command.

For your own variation, set both `min_interval` and `max_interval` to `1.0`. Predict all six timestamps before running. They should be 1, 2, 3, 4, 5 and 6 seconds, while the selected voices can still differ. Explain what became periodic and what still varies. The download includes this complete variation as `08_equal_intervals.gd`; attach it instead of the main script to compare.

Keep the distinction between selecting an event and starting it. In Air Music, your strike will supply the beginning. The sound can continue after your contact ends.

## Carried code

`note_voice.gd` — Effect Sound's unchanged sample and note functions, gathered into a small reusable helper. `make_note` returns a clip; it does not play it.

<!-- student-code:note_voice.gd -->

```gdscript
extends RefCounted

const SAMPLE_RATE := 44100
const DURATION := 0.6
const ATTACK := 0.01
var frequency := 440.0
var ratio := 2.0

func sample_at(t: float, depth: float) -> float:
    var modulator := depth * exp(-t / 0.25) * sin(TAU * frequency * ratio * t)
    var carrier := sin(TAU * frequency * t + modulator)
    var envelope := minf(t / ATTACK, 1.0) * exp(-maxf(t - ATTACK, 0.0) / 0.3)
    envelope *= clampf((DURATION - t) / 0.02, 0.0, 1.0)
    return 0.5 * tanh(0.8 * carrier * envelope)

func make_note(depth: float) -> AudioStreamWAV:
    var bytes := PackedByteArray()
    var count := int(SAMPLE_RATE * DURATION)
    bytes.resize(count * 2)
    for i in range(count):
        var t := float(i) / SAMPLE_RATE
        bytes.encode_s16(i * 2, int(sample_at(t, depth) * 32767.0))
    var note := AudioStreamWAV.new()
    note.format = AudioStreamWAV.FORMAT_16_BITS
    note.mix_rate = SAMPLE_RATE
    note.stereo = false
    note.data = bytes
    return note
```


`point_body.gd` — the point and its existing pickup behaviour.

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


`line_skin.gd` — the finite cylinder used for rows and playhead.

<!-- student-code:line_skin.gd -->

```gdscript
# Supplied renderer, adapted from commons/primitives/line/line.gd.
# This finite cylinder gives the segment a visible thickness. It is not a collider.
# Inputs share the parent station's local frame; that station has unit scale.
extends MeshInstance3D

func _init() -> void:
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.012
	cylinder.bottom_radius = 0.012
	cylinder.radial_segments = 16
	cylinder.rings = 0
	mesh = cylinder
	var finish := StandardMaterial3D.new()
	finish.albedo_color = Color(0.98, 0.70, 0.82)
	finish.roughness = 0.3
	material_override = finish
	visible = false

func show_segment(start: Vector3, displacement: Vector3, distance: float) -> void:
	# A zero-length segment has no direction. Do not normalize it.
	visible = distance > 0.0001
	if not visible:
		return
	(mesh as CylinderMesh).height = distance
	position = start + displacement * 0.5
	# CylinderMesh runs along local Y. This borrowed basis aligns it to the ends.
	var direction := displacement / distance
	var right := direction.cross(Vector3.UP).normalized()
	if right.length() < 0.001:
		right = Vector3.RIGHT
	var depth := right.cross(direction).normalized()
	basis = Basis(right, direction, depth)
```


Implementation references: [Godot RandomNumberGenerator](https://docs.godotengine.org/en/stable/classes/class_randomnumbergenerator.html) and [audio synchronisation](https://docs.godotengine.org/en/stable/tutorials/audio/sync_with_audio.html). The installed soundscape is `algorithms/wavefunctions/technoirgameaudio/john_cage_tech_noir.gd`. Its prepared vocabulary and live scheduling are richer and different from this six-event study. Neither this lesson nor that artifact records your breath or performs a particular Cage score.


---

# A note continues after contact

## Learning elements

- Contact as an onset event
- One audio player per voice
- Restarting one voice; overlapping two
- Playback age and decay
- Adding samples from independent voices

In the Cage hall, a kept score supplied the times. Here your hand supplies them. Strike a bar of the existing metallophone, lift the stick away, then strike another. Two notes can continue together. Strike the first again: its age starts over while the second keeps going.

Follow three things: when a voice begins, which voices continue, and how their samples add. The generated notes have decay; the study does not calculate the physical resonance of a metal bar.

We reconstruct that distinction with two touch bars and the black PointBody you already made. Move the point into one bar, withdraw it, then touch the other. The bars are sensors: they detect entry without blocking the sphere. The museum instrument has a physical stick, speed-sensitive strikes and eight bars. Our study keeps two voices at a fixed level so the new operation is clear.

## Continue inside the museum

Use your Day Zero Endless Museum working copy, with its camera, lighting, player and XR Tools pickup already running. Save the four scripts below together. Keep `point_body.gd` and `line_skin.gd` unchanged. Attach `09_contact_voices.gd` to an empty, unit-scale Node3D in the Air Music learner bay: hall-local position **(13, 0, 14)**, Y rotation **180 degrees**. Run that museum scene as before. Do not attach this study to the existing metallophone.

The script makes the point, two visible bars, contact volumes, players and readout. There are no named scene children to prepare. Grab with the established pickup control and move the point into a bar. No trigger press is needed. Desktop pickup uses the same point; the lesson does not install another player.

## Two voices, two beginnings

The arrays use one shared index: bar 0, player 0 and samples 0 belong together. `body_entered` supplies the contacting body; `bind(i)` adds the bar's index. We accept only this point. The collision mask includes both its normal layer and the layer XR Tools uses while it is held.

`players[index].play()` starts that player's clip from the beginning. Calling it again replaces that voice's current playback. We do not stop the other player. Remaining inside a bar causes no further entry event: leave and return to strike again.

<!-- student-code:09_contact_voices.gd -->

```gdscript
extends Node3D

const PointBody = preload("point_body.gd")
const LineSkin = preload("line_skin.gd")
const RingVoice = preload("ring_voice.gd")
signal struck(index: int)
var frequencies: Array[float] = [261.63, 392.0]
var voice := RingVoice.new()
var players: Array[AudioStreamPlayer3D] = []
var samples: Array[PackedByteArray] = []
var bars: Array[Area3D] = []
var captions: Array[Label3D] = []
var lines: Array[MeshInstance3D] = []
var point: RigidBody3D
var label: Label3D

func text_at(words: String, at: Vector3, size: int = 24) -> Label3D:
    var text := Label3D.new()
    text.text = words
    text.position = at
    text.font_size = size
    text.pixel_size = 0.002
    add_child(text)
    return text

func _ready() -> void:
    point = PointBody.new()
    point.position = Vector3(0, 1.05, 0.8)
    add_child(point)
    var ink := StandardMaterial3D.new()
    ink.albedo_color = Color(0.04, 0.04, 0.045)
    ink.roughness = 0.2
    point.get_child(0).material_override = ink
    label = text_at("", Vector3(0, 2.2, 0), 28)
    text_at("Touch with the point; lift away; touch another.", Vector3(0, 0.68, 0.3))
    for i in range(frequencies.size()):
        var bar := Area3D.new()
        bar.position = Vector3(-0.55 + 1.1 * i, 1.05, 0)
        bar.collision_layer = 0
        bar.collision_mask = point.collision_layer | point.picked_up_layer
        var boundary := CollisionShape3D.new()
        var shape := BoxShape3D.new()
        shape.size = Vector3(0.5, 0.14, 0.6)
        boundary.shape = shape
        bar.add_child(boundary)
        var surface := MeshInstance3D.new()
        var box := BoxMesh.new()
        box.size = shape.size
        surface.mesh = box
        var material := StandardMaterial3D.new()
        material.albedo_color = Color(0.85, 0.85, 0.82)
        surface.material_override = material
        bar.add_child(surface)
        bar.body_entered.connect(_on_contact.bind(i))
        add_child(bar)
        bars.append(bar)
        captions.append(text_at("", bar.position + Vector3(0, -0.2, 0.32), 21))
        var player := AudioStreamPlayer3D.new()
        player.position = bar.position
        player.max_distance = 7.0
        player.stream = voice.make_note(frequencies[i])
        samples.append(player.stream.data)
        add_child(player)
        players.append(player)
    for i in range(64):
        var line := LineSkin.new()
        add_child(line)
        lines.append(line)
    draw_state()

func _on_contact(body: Node3D, index: int) -> void:
    if body != point:
        return
    players[index].play()
    struck.emit(index)

func ages_now() -> PackedFloat64Array:
    var ages := PackedFloat64Array()
    for player in players:
        ages.append(player.get_playback_position() if player.playing else -1.0)
    return ages

func sum_at(ages: PackedFloat64Array, offset: float) -> float:
    var total := 0.0
    for i in range(players.size()):
        if ages[i] >= 0.0:
            total += voice.read_sample(samples[i], ages[i] + offset)
    return total

func _process(_delta: float) -> void:
    draw_state()

func draw_state() -> void:
    var ages := ages_now()
    var active := 0
    for i in range(players.size()):
        var state := "quiet"
        if ages[i] >= 0.0:
            active += 1
            state = "%.2f s" % ages[i]
        captions[i].text = "%.2f Hz | %s" % [frequencies[i], state]
    label.text = "%d voices | each has its own age\n12 ms of their stored samples added" % active
    var previous := Vector3(-1.0, 1.65 + 0.45 * sum_at(ages, 0.0), 0)
    for i in range(lines.size()):
        var u := float(i + 1) / lines.size()
        var next := Vector3(-1.0 + 2.0 * u, 1.65 + 0.45 * sum_at(ages, u * 0.012), 0)
        var delta := next - previous
        lines[i].show_segment(previous, delta, delta.length())
        previous = next
```


Each audio player owns its playback clock. `ages_now()` reads those clocks once for each drawing frame; `-1` means quiet. The visible study does not invent a second timer and try to keep it synchronized with sound. In conceptual terms, age is the time since this voice's onset. Godot gives us that age through `get_playback_position()`.

`sum_at()` reads each active voice at its own age plus the same small offset, then adds the values. A new strike changes one age, so it changes how the samples meet. The pink line shows 12 milliseconds across its width at a fixed vertical scale. It reads the generated data before spatial attenuation and the audio bus. Moving your head can change what you hear without changing this curve. Playback position is reported at audio-mix intervals; this is an inspectable display, not a sample-accurate oscilloscope.

## Let the note fade

Effect Sound already taught a sampled sine, an envelope and 16-bit encoding. `RingVoice` uses that construction with a longer, plain decaying sine. The previous phase-modulated `NoteVoice` remains available to Cage; we do not change its sound to write this lesson.

<!-- student-code:ring_voice.gd -->

```gdscript
extends RefCounted

const SAMPLE_RATE := 44100
const DURATION := 3.0
const DECAY := 0.8

func sample_at(age: float, frequency: float) -> float:
    if age < 0.0 or age >= DURATION:
        return 0.0
    var envelope := minf(age / 0.005, 1.0) * exp(-age / DECAY)
    envelope *= minf((DURATION - age) / 0.05, 1.0)
    return 0.25 * sin(TAU * frequency * age) * envelope

func make_note(frequency: float) -> AudioStreamWAV:
    var bytes := PackedByteArray()
    var count := int(SAMPLE_RATE * DURATION)
    bytes.resize(count * 2)
    for i in range(count):
        bytes.encode_s16(i * 2, int(sample_at(float(i) / SAMPLE_RATE, frequency) * 32767.0))
    var note := AudioStreamWAV.new()
    note.format = AudioStreamWAV.FORMAT_16_BITS
    note.mix_rate = SAMPLE_RATE
    note.stereo = false
    note.data = bytes
    return note

func read_sample(bytes: PackedByteArray, age: float) -> float:
    if age < 0.0:
        return 0.0
    var index := int(age * SAMPLE_RATE)
    if index * 2 >= bytes.size():
        return 0.0
    return float(bytes.decode_s16(index * 2)) / 32767.0
```


`exp(-age / DECAY)` falls as age grows. With `DECAY = 0.8`, its value is about 0.37 after 0.8 seconds. That number is a decay time constant, not the note's duration. The finite buffer lasts three seconds. A short attack and final fade soften its edges. The chosen frequency makes the sound; the box's size does not calculate a metal bar's resonance.

`encode_s16()` stores a signed integer for each sample. `read_sample()` reverses that conversion for the display, returning zero before or after the buffer. We cache the bytes once in `samples`, so drawing does not repeatedly fetch whole sound resources. Each voice is bounded by 0.25; two unscaled source voices cannot exceed 0.5 in magnitude. That leaves source headroom. The prepared audio output still determines the listening level.

## The two carried pieces

These are the same point body and finite cylinder renderer. Their complete files are included so this reconstruction has no missing dependency; the black finish is applied by the main script.

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


<!-- student-code:line_skin.gd -->

```gdscript
# Supplied renderer, adapted from commons/primitives/line/line.gd.
# This finite cylinder gives the segment a visible thickness. It is not a collider.
# Inputs share the parent station's local frame; that station has unit scale.
extends MeshInstance3D

func _init() -> void:
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.012
	cylinder.bottom_radius = 0.012
	cylinder.radial_segments = 16
	cylinder.rings = 0
	mesh = cylinder
	var finish := StandardMaterial3D.new()
	finish.albedo_color = Color(0.98, 0.70, 0.82)
	finish.roughness = 0.3
	material_override = finish
	visible = false

func show_segment(start: Vector3, displacement: Vector3, distance: float) -> void:
	# A zero-length segment has no direction. Do not normalize it.
	visible = distance > 0.0001
	if not visible:
		return
	(mesh as CylinderMesh).height = distance
	position = start + displacement * 0.5
	# CylinderMesh runs along local Y. This borrowed basis aligns it to the ends.
	var direction := displacement / distance
	var right := direction.cross(Vector3.UP).normalized()
	if right.length() < 0.001:
		right = Vector3.RIGHT
	var depth := right.cross(direction).normalized()
	basis = Basis(right, direction, depth)
```


## Test the distinction

1. Touch the left bar and withdraw. One age should keep increasing after contact ends.
2. Before it finishes, touch the right. There should be two ages. The first must not jump back to zero.
3. Leave the right bar and return to it. Only the right age restarts. Hold the point still inside: it must not keep restarting.
4. Withdraw and wait three seconds. Both labels should read quiet, and the sum should become a straight line.

Now change only the second frequency from `392.0` to `261.63`. Predict what stays separate. Run again, striking the bars with a gap. The two clips now contain the same samples, but their playback ages remain independent. Equal pitch does not require equal phase or simultaneous beginnings. The download includes the complete `09_same_pitch.gd` variation; attach it instead of the original, never alongside it in the same bay.

Native tests extract the exact printed scripts, move the actual sphere collider through both areas, test the held collision layer, reject an unrelated body, check independent restart and compare the displayed sum with stored samples. They also run the same-pitch variation and wait for playback to finish. These assertions check the reconstruction; they do not establish headset comfort or whether a reader can build it unaided.

The original eight-bar instrument remains in the hall. Return to it and try the same sequence with its stick. Keep the two independent voices and their sum for Beats. First, Sky Stairs returns to spatial composition: samples will place solid treads, and the cube will carry weight where a line only drew a path. We will come back to combining waves after that crossing.


---

# A place for a foot

## Learning elements

- Sampling an angle into positions
- Circular coordinates with a changing radius
- Turning each tread around Y
- Matching a mesh with collision
- Comparing centres, edges and support

Keep Air Music's voices for the next hall. Here we return to Bernini's spatial construction and Sine Space's contact surface. Samples place solid parts: the large stair turns twice while rising. Its height increases evenly; sine changes its radius. Follow its lower steps from the surrounding floor. Where do two neighbouring treads actually meet?

We return to the cube from Primitives and Transformation. Flatten it into a tread, place eleven copies along a quarter turn, and give each copy collision. The pink LineSkin from Lines joins their top centres. That line describes the sampled path; only the treads supply support.

## Continue inside Endless Museum

Keep your Day Zero museum working copy, camera, light and player. Save the two complete files below together. Attach `10_sampled_treads.gd` to an empty Node3D in the Sky Stairs learner bay: **hall-local (16, 0, 10), Y rotation 0, scale (1, 1, 1)**. Run the museum as before. The script constructs its own treads, collision shapes, labels and line. It does not replace the existing tall stair or require named scene children.

Start beside the lower end and inspect from the floor. This is a short construction study, not a completed stair controller. The prepared player determines stepping and jumping; collision alone does not teach that controller to climb.

## Place, then turn

For sample `i`, the angle is `i * angle_step`. The Unit Circle gave us cosine and sine as coordinates. Here they occupy X and Z, leaving Y for height. `index * rise` increases the top height by 0.11 metres per sample. There are ten intervals between eleven treads: the last top is 1.10 metres high.

`radius + amplitude * sin(2.0 * angle)` widens and narrows the path. Sine changes the distance from the centre, not the height. With these settings, sample 0 starts at radius 2.5 metres, sample 5 reaches 2.95, and sample 10 returns to 2.5.

<!-- student-code:10_sampled_treads.gd -->

```gdscript
extends Node3D

const LineSkin = preload("line_skin.gd")
var count := 11
var angle_step := TAU / 40.0
var radius := 2.5
var amplitude := 0.45
var rise := 0.11
var tread_size := Vector3(1.2, 0.12, 0.6)
var points: Array[Vector3] = []
var treads: Array[StaticBody3D] = []
var label: Label3D

func sample_position(index: int) -> Vector3:
    var angle := index * angle_step
    var r := radius + amplitude * sin(2.0 * angle)
    return Vector3(r * cos(angle), index * rise, r * sin(angle))

func text_at(words: String, at: Vector3, size: int = 24) -> Label3D:
    var text := Label3D.new()
    text.text = words
    text.position = at
    text.font_size = size
    text.pixel_size = 0.0025
    text.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    add_child(text)
    return text

func _ready() -> void:
    var finish := StandardMaterial3D.new()
    finish.albedo_color = Color(0.87, 0.86, 0.83)
    finish.roughness = 0.7
    for i in range(count):
        var top := sample_position(i)
        points.append(top)
        var tread := StaticBody3D.new()
        tread.position = top - Vector3.UP * tread_size.y * 0.5
        tread.rotation.y = -i * angle_step
        var surface := MeshInstance3D.new()
        var box := BoxMesh.new()
        box.size = tread_size
        surface.mesh = box
        surface.material_override = finish
        tread.add_child(surface)
        var boundary := CollisionShape3D.new()
        var shape := BoxShape3D.new()
        shape.size = tread_size
        boundary.shape = shape
        tread.add_child(boundary)
        add_child(tread)
        treads.append(tread)
        if i > 0:
            var line := LineSkin.new()
            add_child(line)
            var previous := points[i - 1] + Vector3.UP * 0.025
            var delta := top + Vector3.UP * 0.025 - previous
            line.show_segment(previous, delta, delta.length())
        if i in [0, 5, 10]:
            text_at("%d | top %.2f m" % [i, top.y], top + Vector3.UP * 0.28, 18)
    var inner := edge_distance(4, 5, -1.0)
    var outer := edge_distance(4, 5, 1.0)
    label = text_at("Same rise: %.2f m\n4 to 5: inner %.2f m | outer %.2f m\nDistances between side midpoints, not clear gaps" % [rise, inner, outer], Vector3(0, 1.6, 1.0))

func edge_position(index: int, side: float) -> Vector3:
    var tread := treads[index]
    var local := Vector3(side * tread_size.x * 0.5, tread_size.y * 0.5, 0)
    return tread.transform * local

func edge_distance(a: int, b: int, side: float) -> float:
    return edge_position(a, side).distance_to(edge_position(b, side))
```


The box's origin is its centre. Subtracting half its thickness puts its **top**, rather than its middle, on the sampled position. The collision box uses the same dimensions and the same parent as the visible box. Moving or turning that parent changes both together.

The tread's local X axis points outward from the centre. Godot's Y rotation needs `-angle` for that axis to align with `(cos(angle), 0, sin(angle))`. Local Z then runs around the turn. We use a radial orientation here; it is not the exact tangent of the changing-radius curve. The difference is another construction choice to inspect.

`edge_position()` transforms a point on a tread into the study's local frame. We compare the inner and outer side midpoints of treads 4 and 5. Those are distances between chosen points, **not measurements of an open gap**. Thickness, depth, turning and overlap determine the actual boundary. Stand at the outside of the turn, then look from the inside. A regular rise does not make those two edges equivalent.

## The carried line

This is the unchanged finite-cylinder renderer from earlier lessons. It gives the path a visible thickness. It has no collision and cannot fill a gap between treads.

<!-- student-code:line_skin.gd -->

```gdscript
# Supplied renderer, adapted from commons/primitives/line/line.gd.
# This finite cylinder gives the segment a visible thickness. It is not a collider.
# Inputs share the parent station's local frame; that station has unit scale.
extends MeshInstance3D

func _init() -> void:
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.012
	cylinder.bottom_radius = 0.012
	cylinder.radial_segments = 16
	cylinder.rings = 0
	mesh = cylinder
	var finish := StandardMaterial3D.new()
	finish.albedo_color = Color(0.98, 0.70, 0.82)
	finish.roughness = 0.3
	material_override = finish
	visible = false

func show_segment(start: Vector3, displacement: Vector3, distance: float) -> void:
	# A zero-length segment has no direction. Do not normalize it.
	visible = distance > 0.0001
	if not visible:
		return
	(mesh as CylinderMesh).height = distance
	position = start + displacement * 0.5
	# CylinderMesh runs along local Y. This borrowed basis aligns it to the ends.
	var direction := displacement / distance
	var right := direction.cross(Vector3.UP).normalized()
	if right.length() < 0.001:
		right = Vector3.RIGHT
	var depth := right.cross(direction).normalized()
	basis = Basis(right, direction, depth)
```


## Make a prediction, then check

1. Find labels 0, 5 and 10. Their top heights should be 0, 0.55 and 1.10 metres. Trace the pink path between them.
2. Compare the two reported side distances. The outer pair is farther apart even though the rise is the same. Look at the actual edges before calling that distance a gap.
3. Change only `amplitude` to `0.0` and run again. Predict what remains: eleven treads, the same heights and turns. Their centres now lie on a circle of constant radius. The download includes this complete variation as `10_constant_radius.gd`; attach it instead of the original.
4. Choose one pair of treads. Explain separately how their positions, orientation, width and depth affect the available support. Changing one number can alter more than the silhouette.

The native test extracts these exact code blocks. It checks the three labelled positions, radial orientation, matching collision, real physics ray contacts and a dropped test sphere coming to rest on a tread. It repeats the study in a translated, rotated parent and runs the constant-radius variation. Deliberate missing-collision, wrong-turn and wrong-height faults must fail. These are construction checks; they do not establish a comfortable full ascent or independent student understanding.

Return to the tall museum stair. Its own generator uses 80 treads, two turns, a 0.11-metre rise and changing radius. It also adds connecting membranes whose configured vertical offset is 0.30 metres. Our small study omits those membranes so you can inspect what the boxes alone provide. Neither a continuous-looking line nor a connector's presence proves an accessible route. Next, Trig Walking Path brings two slightly different cycles together and asks how their relation changes over time.


---

# A difference in time

## Learning elements

- Adding two signed signals
- Frequency difference and beat period
- A shared start and changing relative phase
- Keeping raw values separate from display gain

At the beat display, bring the two frequency controls close together. A and B move quickly. Their sum grows and shrinks more slowly. At a quiet moment in the lower row, the sources above it can still be moving.

Air Music kept two voices and their playback ages. Here we isolate their relationship: two unit-amplitude sines, started together, at slightly different frequencies. The black PointBody chooses B; the familiar LineSkin draws A, B and their sum. Sky Stairs gave samples solid support. These samples make a visual comparison again. They do not form a floor or produce sound.

## Continue inside the museum

Use the prepared Endless Museum project, with its player, XR pickup, lighting and camera. Save the three scripts below together. Keep `point_body.gd` and `line_skin.gd` unchanged. Attach `11_two_cycles.gd` to an empty Node3D in this hall's learner bay: **hall-local (23, 0, 12), Y rotation 180 degrees, unit scale**. Run the museum scene as before. The program creates its own point, lines and labels; no named scene children are required.

Grab the black point. Its local height previews B between 0.5 Hz below and 0.5 Hz above A. At 1.2 metres, B equals A. Press the held object's established trigger action to apply the preview and restart both waves together. Moving the point alone leaves the current pair running. This keeps the chosen frequency fixed during each observation.

## Two sources, one sum

`values_at()` returns three signed values: A, B and their raw sum. Negative values matter. A positive value and an equal negative value cancel; neither source has disappeared. With unit-amplitude inputs, the raw sum lies between −2 and +2.

<!-- student-code:11_two_cycles.gd -->

```gdscript
extends Node3D

const PointBody = preload("point_body.gd")
const LineSkin = preload("line_skin.gd")
var frequency_a := 4.0
var frequency_b := 4.5
var elapsed := 0.0
var segments := 64
var width := 3.2
var height_gain := 0.22
var row_heights := [2.35, 1.75, 1.15]
var rows: Array = []
var point: RigidBody3D
var label: Label3D
var values_label: Label3D

func text_at(words: String, at: Vector3, size: int = 24) -> Label3D:
    var text := Label3D.new()
    text.text = words
    text.position = at
    text.font_size = size
    text.pixel_size = 0.002
    add_child(text)
    return text

func _ready() -> void:
    point = PointBody.new()
    point.position = Vector3(-2.1, 1.7, 0.5)
    add_child(point)
    var ink := StandardMaterial3D.new()
    ink.albedo_color = Color(0.04, 0.04, 0.045)
    ink.roughness = 0.2
    point.get_child(0).material_override = ink
    point.action_pressed.connect(on_action)
    label = text_at("", Vector3(0, 2.95, 0), 26)
    values_label = text_at("", Vector3(0, 0.7, 0), 21)
    text_at("Raise point to choose B. Trigger starts both together.", Vector3(0, 0.43, 0), 21)
    var colours := [Color(0.55, 0.7, 1), Color(0.82, 0.88, 0.8), Color(0.98, 0.7, 0.82)]
    var names := ["A", "B", "(A+B) / 2"]
    for row in range(3):
        var lines: Array = []
        var finish := StandardMaterial3D.new()
        finish.albedo_color = colours[row]
        for i in range(segments):
            var line := LineSkin.new()
            line.material_override = finish
            add_child(line)
            lines.append(line)
        rows.append(lines)
        text_at(names[row], Vector3(-2.0, row_heights[row], 0), 20)
    restart_pair()

func candidate_frequency() -> float:
    return frequency_a + clampf(point.position.y - 1.2, -0.5, 0.5)

func on_action(_held: Variant) -> void:
    restart_pair()

func restart_pair() -> void:
    frequency_b = candidate_frequency()
    elapsed = 0.0
    draw_state()

func values_at(time: float, phase: float) -> Vector3:
    var a := sin(TAU * frequency_a * time + phase)
    var b := sin(TAU * frequency_b * time + phase)
    return Vector3(a, b, a + b)

func plot_position(row: int, u: float) -> Vector3:
    var values := values_at(elapsed, u * TAU * 2.0)
    var value: float = values[row]
    if row == 2:
        value *= 0.5
    return Vector3(-width * 0.5 + u * width, row_heights[row] + height_gain * value, 0)

func _process(delta: float) -> void:
    elapsed += delta
    draw_state()

func draw_state() -> void:
    for row in range(3):
        var previous := plot_position(row, 0.0)
        for i in range(segments):
            var next := plot_position(row, float(i + 1) / segments)
            var displacement := next - previous
            rows[row][i].show_segment(previous, displacement, displacement.length())
            previous = next
    var difference := absf(frequency_a - frequency_b)
    var beat_text := "equal frequencies: no drifting envelope"
    if difference > 0.00001:
        beat_text = "beat %.2f Hz | repeats every %.2f s" % [difference, 1.0 / difference]
    label.text = "A %.2f Hz | B %.2f Hz\n%s\nB preview %.2f Hz | trigger to apply" % [frequency_a, frequency_b, beat_text, candidate_frequency()]
    var values := values_at(elapsed, PI * 0.5)
    values_label.text = "At phase PI/2: A %+.2f | B %+.2f | raw sum %+.2f\nBottom row drawn at half the raw sum" % [values.x, values.y, values.z]
```


Both waves use the same elapsed time and the same added phase at each horizontal position. Two turns of that shared phase fill each row. This is a set of phase-shifted copies of the same comparison, not a simulation of a wave travelling through material. Follow one fixed horizontal position to compare the fast oscillation with its slower envelope.

`plot_position()` applies half gain only when drawing the bottom row. `values_at()` and the numeric readout retain the raw sum. If the bottom row reaches the same height as A, that does not mean their raw amplitudes are equal: the drawing scales differ. The label says `(A+B) / 2` for this reason.

The PointBody signal passes the held object to `on_action()`. We do not need that argument here; the callback simply starts a new comparison. Restarting resets the common clock as well as applying B. Equal frequencies therefore begin aligned in this study. Two equal-frequency sources started with different phases would retain that difference; equal frequency alone does not guarantee reinforcement.

## What changes slowly?

Begin with A = 4 Hz and B = 4.5 Hz. Their phase difference grows by half a turn each second. One second after the shared start, they oppose one another throughout the rows. After two seconds they align again. The large changes in amplitude repeat every two seconds: **0.5 beats per second**.

In general, the beat rate is `abs(A − B)` and the period is its reciprocal. The equal-frequency case needs a separate branch: there is no finite beat period to calculate. In the sum identity, a signed cosine factor changes sign; the visible amplitude follows its absolute size. Count successive loud-looking envelopes, not only positive peaks of that factor.

The existing museum exhibit updates its frequencies continuously as you move its sliders. Our trigger commits a pair and resets its start, making the predicted one-second cancellation easy to repeat. Both displays are visual. A later audible experiment would need an audio source; moving a visible sphere does not create sound.

## The carried pieces

These are the same grabbable sphere and finite-cylinder line renderer. Their full files are included so the reconstruction is complete. The main script applies the black finish and the three row colours.

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


<!-- student-code:line_skin.gd -->

```gdscript
# Supplied renderer, adapted from commons/primitives/line/line.gd.
# This finite cylinder gives the segment a visible thickness. It is not a collider.
# Inputs share the parent station's local frame; that station has unit scale.
extends MeshInstance3D

func _init() -> void:
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.012
	cylinder.bottom_radius = 0.012
	cylinder.radial_segments = 16
	cylinder.rings = 0
	mesh = cylinder
	var finish := StandardMaterial3D.new()
	finish.albedo_color = Color(0.98, 0.70, 0.82)
	finish.roughness = 0.3
	material_override = finish
	visible = false

func show_segment(start: Vector3, displacement: Vector3, distance: float) -> void:
	# A zero-length segment has no direction. Do not normalize it.
	visible = distance > 0.0001
	if not visible:
		return
	(mesh as CylinderMesh).height = distance
	position = start + displacement * 0.5
	# CylinderMesh runs along local Y. This borrowed basis aligns it to the ends.
	var direction := displacement / distance
	var right := direction.cross(Vector3.UP).normalized()
	if right.length() < 0.001:
		right = Vector3.RIGHT
	var depth := right.cross(direction).normalized()
	basis = Basis(right, direction, depth)
```


## Predict, change, return

1. Start the default pair. Follow one horizontal position through narrowing and widening. At the narrow moment, inspect both inputs and the raw sum readout.
2. Hold the point at local height 1.45 metres: B previews 4.25 Hz. Trigger. Predict the new period before watching: four seconds, with opposition after two.
3. Move the point to 0.95 metres and trigger. B is now 3.75 Hz. The absolute difference is still 0.25 Hz. The beat period stays four seconds although the faster source has changed.
4. Set the point to 1.2 metres and trigger. Both frequencies are 4 Hz. The sum keeps twice either source's raw value; half gain makes the lower row's excursion match the upper ones.

For an independent variation, set `frequency_a` to `5.0` and the point's initial Y to `1.45`. Before running, predict B = 5.25 Hz and the same four-second envelope period despite the faster sources. The complete `11_faster_pair.gd` variation is included; attach it instead of the original.

Native assertions run the exact printed files. They test the PointBody action callback, local-height mapping in a moved and rotated host, values at known phases, cancellation and reinforcement, the four-second variation, equal frequencies and display gain. Deliberate sign, gain and restart faults must fail. This verifies the program's behaviour, not a reader's understanding or headset comfort.

The red-and-blue paths remain a different comparison: sine and cosine distributed through finite circulating rows. The Lissajous figure gives separate coordinates to oscillations instead of adding them on one axis. Keep these constructions distinct. In Synthesis Lab, we will retain the signed sum and change how much several harmonic components contribute.


---

# Five amounts, one shape

## Learning elements

- Harmonic number and coefficient
- A weighted sum from a list and loop
- Holding phase while comparing recipes
- Copying a baseline without resetting the clock
- The limits of a finite representation

Find the dark synthesis bench in the museum. Press HOLD. Lower H2 through H5 one by one. The pale curve changes until only a sine remains. None of the five smooth component rows has the slope you first saw; the slope belonged to their sum.

In Beats, two nearby frequencies drifted in and out of alignment. Here the frequencies stay in integer ratios: one, two, three, four and five times a fundamental. We change their amounts. The unchanged PointBody returns five times as a hand control; LineSkin draws the five contributions and their sum. Arrays supplies the list, and Trace supplies the loop through stored entries.

## Build beside the existing bench

Use the prepared Endless Museum, with its player, XR Tools, camera and lighting. Save the three scripts below together. Attach `12_five_amounts.gd` to an empty Node3D at **hall-local (16, 0, 11), Y rotation 180 degrees, unit scale**. The script creates all five points, six rows and labels. Keep `point_body.gd` and `line_skin.gd` unchanged.

Raise a point to increase its harmonic's amount. Local Y = 0.8 metres means zero; 1.6 metres means one. Release it to keep that height. Horizontal movement does not change its coefficient. Each point keeps its harmonic identity even if you move it past another.

The display starts held. The **H1 point's trigger toggles HOLD/RUN**. The **H5 point's trigger restores BASELINE**, releasing any held controls and returning their heights. It preserves the phase and held state. These are the established PointBody actions; we are giving them new jobs.

## Multiply a contribution, then add it

`amounts[h]` is a coefficient. `h + 1` is the harmonic number because array indices begin at zero. The coefficient changes the amount; the harmonic number changes how many cycles fit in one fundamental cycle. A nonnegative coefficient can still contribute a negative value when its sine is below zero.

<!-- student-code:12_five_amounts.gd -->

```gdscript
extends Node3D

const PointBody = preload("point_body.gd")
const LineSkin = preload("line_skin.gd")
var baseline: Array[float] = [1.0, 0.5, 1.0 / 3.0, 0.25, 0.2]
var amounts: Array[float] = []
var points: Array = []
var rows: Array = []
var phase := 0.0
var held := true
var segments := 64
var width := 3.2
var gain := 0.16
var label: Label3D

func text_at(words: String, at: Vector3, size: int = 22) -> Label3D:
    var text := Label3D.new()
    text.text = words
    text.position = at
    text.font_size = size
    text.pixel_size = 0.002
    add_child(text)
    return text

func _ready() -> void:
    amounts = baseline.duplicate()
    var ink := StandardMaterial3D.new()
    ink.albedo_color = Color(0.04, 0.04, 0.045)
    ink.roughness = 0.2
    for h in range(amounts.size()):
        var point := PointBody.new()
        point.position = Vector3(-1.4 + h * 0.7, 0.8 + amounts[h] * 0.8, 0.75)
        point.get_child(0).material_override = ink
        add_child(point)
        points.append(point)
        text_at("H%d" % (h + 1), Vector3(point.position.x, 0.6, 0.75))
    points[0].action_pressed.connect(toggle_hold)
    points[4].action_pressed.connect(restore_baseline)
    label = text_at("", Vector3(0, 3.55, 0), 23)
    text_at("Raise each point: amount 0 to 1\nH1 trigger: HOLD / RUN     H5 trigger: BASELINE", Vector3(0, 0.34, 0.75), 20)
    for row in range(6):
        var lines: Array = []
        var finish := StandardMaterial3D.new()
        finish.albedo_color = Color(0.98, 0.7, 0.82) if row == 5 else Color.from_hsv(float(row) / 5.0, 0.4, 0.95)
        for i in range(segments):
            var line := LineSkin.new()
            line.material_override = finish
            add_child(line)
            lines.append(line)
        rows.append(lines)
        text_at("SUM" if row == 5 else "H%d" % (row + 1), Vector3(-1.9, row_height(row), 0), 20)
    draw_state()

func read_amounts() -> void:
    for h in range(points.size()):
        amounts[h] = clampf((points[h].position.y - 0.8) / 0.8, 0.0, 1.0)

func contribution(h: int, angle: float) -> float:
    return amounts[h] * sin((h + 1) * angle)

func sum_at(angle: float) -> float:
    var total := 0.0
    for h in range(amounts.size()):
        total += contribution(h, angle)
    return total

func row_height(row: int) -> float:
    return 2.95 if row == 5 else 2.4 - row * 0.29

func plot_position(row: int, u: float) -> Vector3:
    var angle := u * TAU + phase
    var value := sum_at(angle) if row == 5 else contribution(row, angle)
    return Vector3((u - 0.5) * width, row_height(row) + gain * value, 0)

func toggle_hold(_point: Variant = null) -> void:
    held = not held
    draw_state()

func restore_baseline(_point: Variant = null) -> void:
    amounts = baseline.duplicate()
    for h in range(points.size()):
        points[h].drop()
        points[h].position.y = 0.8 + amounts[h] * 0.8
    draw_state()

func _process(delta: float) -> void:
    read_amounts()
    if not held:
        phase = fposmod(phase + TAU * 0.2 * delta, TAU)
    draw_state()

func draw_state() -> void:
    for row in range(rows.size()):
        var previous := plot_position(row, 0.0)
        for i in range(segments):
            var next := plot_position(row, float(i + 1) / segments)
            var displacement := next - previous
            rows[row][i].show_segment(previous, displacement, displacement.length())
            previous = next
    var values := PackedStringArray()
    for h in range(amounts.size()):
        values.append("H%d %.3f" % [h + 1, amounts[h]])
    label.text = "%s | phase %.2f rad\n%s\nAll rows: %.2f m per signal unit" % ["HOLD" if held else "RUN", phase, "   ".join(values), gain]
```


`sum_at()` starts a new total for each angle. It does not add yesterday's curve to today's. Each pass through the loop adds one signed contribution at the same angle. This is the familiar sum extended from two named values to a list.

The baseline is copied with `duplicate()`. Editing the working list must not edit the recipe we hope to restore. `restore_baseline()` copies it again, moves the handles and leaves `phase` alone. The inherited `drop()` releases a held control before repositioning it; otherwise the hand would continue commanding its position.

## Hold one thing still

While held, move a point and inspect the resulting change at one fixed horizontal position. Only when RUN is selected does `_process()` advance the common phase, at 0.2 fundamental cycles per second. Multiplying that shared angle by each harmonic number keeps the ratios intact.

At phase zero, a quarter of the way across the rows is angle PI/2. H1 contributes +1; H3 contributes −1/3; H5 contributes +1/5. H2 and H4 are zero there. Predict the total: about 0.867. Now remove H3. The sum rises to 1.2 at that place. Removing something can increase the result because what you removed was negative.

All six rows use the **same gain: 0.16 metres per signal unit**. Their baselines are vertically separated, so add displacements from those baselines, not absolute screen heights. Unlike the last lesson, the sum has no extra half gain. It can extend farther than any component. The display does not normalize it when you change the recipe.

The program draws one fundamental cycle as 64 cylinder segments. Five harmonics do not make an exact sawtooth jump. The finite sum is smooth; the displayed polyline is a further sampling of it. These are two separate limits. This construction also supplies no negative coefficient, independent phase or constant offset. It does not express every periodic shape, and it produces no sound.

## The carried pieces

These are the earlier grabbable point and finite-cylinder renderer. Their complete files remain here so the example can be reconstructed.

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


<!-- student-code:line_skin.gd -->

```gdscript
# Supplied renderer, adapted from commons/primitives/line/line.gd.
# This finite cylinder gives the segment a visible thickness. It is not a collider.
# Inputs share the parent station's local frame; that station has unit scale.
extends MeshInstance3D

func _init() -> void:
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.012
	cylinder.bottom_radius = 0.012
	cylinder.radial_segments = 16
	cylinder.rings = 0
	mesh = cylinder
	var finish := StandardMaterial3D.new()
	finish.albedo_color = Color(0.98, 0.70, 0.82)
	finish.roughness = 0.3
	material_override = finish
	visible = false

func show_segment(start: Vector3, displacement: Vector3, distance: float) -> void:
	# A zero-length segment has no direction. Do not normalize it.
	visible = distance > 0.0001
	if not visible:
		return
	(mesh as CylinderMesh).height = distance
	position = start + displacement * 0.5
	# CylinderMesh runs along local Y. This borrowed basis aligns it to the ends.
	var direction := displacement / distance
	var right := direction.cross(Vector3.UP).normalized()
	if right.length() < 0.001:
		right = Vector3.RIGHT
	var depth := right.cross(direction).normalized()
	basis = Basis(right, direction, depth)
```


## Make a change you can explain

1. With the display held, remove H3. Predict the change at the quarter-cycle position, then inspect it. Restore BASELINE with H5's trigger.
2. Lower H2 through H5. Compare the sum with H1. Their displacement should agree because they use the same gain. Lower H1 too: all rows become flat.
3. Run the phase, then hold it. Change several amounts and restore BASELINE. The old shape returns at the held phase. Repeat while running: the recipe returns, but time keeps moving.
4. Build a second recipe: `[1.0, 0.0, 1.0 / 3.0, 0.0, 0.2]`. Before running it, predict what the second half of a cycle will do. With only odd harmonics, it is the negative of the first half. The complete `12_odd_recipe.gd` variation is included in the code download.

The museum bench uses the same weighted-sine principle with sliders, four visible cycles and finer sampling. Its component rows and sum have different drawing gains; its H3 baseline is rounded to 0.333. It hides component ribbons below 0.01 and assigns recipe names within a tolerance. Our reduced study keeps every component line and does not classify recipes. Those extra display decisions are useful to investigate in the exhibit without rebuilding them here.

Native checks execute the exact printed files, known signed contributions, both PointBody actions, baseline independence, phase preservation, displayed geometry and the odd-harmonic variation. Deliberately wrong indexing, unsigned contributions and a shared baseline must fail. Passing these checks establishes code behaviour; it does not establish a reader's understanding or headset comfort.

## What travels onward

The five-harmonic study completes this tutorial sequence. Use the independent recipe to show that you can predict a signed contribution, explain the sum, and distinguish restoring its amounts from restoring its phase. Room Memory is an optional artistic investigation; completing its recording experiment is not a prerequisite for Randomness.

In the separate Room Memory encounter, each filtered recording becomes the next input. This tutorial recalculates a curve from a recipe instead. Keep that difference. To recover the same curve at the same instant, we need both its amounts and its phase. Random Definition will ask what else must be retained when the next result is chosen rather than prescribed by this cycle.
