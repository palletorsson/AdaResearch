# A wait kept

**Learning elements**

- A fixed order of states with sampled waits
- Drawing once and retaining a deadline
- Updating a clock without redrawing the decision
- Separating a warning, a movement and collision support
- Replaying local state

At the crossing, watch one stone. It stands, leaves, stays below, then returns. The order repeats; the pauses vary. Look at the tablet: the current wait has already been drawn. The next wait is not yet stored. Turn CUE off. The ring disappears, but the stone keeps its appointment.

Random Space separated a value from the picture that disclosed it. Here we separate a scheduled event from its warning. Bring the cube's translation from Transformation, the clock from Point Zero, seeded draws and the carried PointBody. We rebuild one stone beside the existing crossing. The doors, removal floor and falling cubes remain other encounters in the hall.

## Keep a clock and a stone

In your local copy of the prepared museum, add a Node3D at hall-local **(3.5, 0, 10.5), Y rotation 90 degrees**, with unit scale. Place the three printed files together; attach `14_a_wait_kept.gd`. The museum already supplies its player, XR Tools, light and floor. The script makes its own stone, collider, display and PointBody. This is a small working model beside the crossing: stand on the museum floor to inspect it. The displayed cube and its travel are 60% of the installed stone's size. The backdrop and base are visual, without collision.

Hold the point over a label and press the trigger. REPLAY restores the current seed, clock, first wait, height and support, and pauses. RUN / STOP advances or holds the lesson's clock. CUE changes the advance ring. While paused, +0.25 s advances the clock by a quarter-second. Moving or dropping the point does not choose an action. The tablet stays readable when the ring is off.

There are two small programs. `wait_cycle.gd` stores the schedule without drawing geometry. The Node3D script gives that schedule a body. Keeping the clock separate lets us inspect an exact instant without waiting for it in a headset.

## The schedule: wait_cycle.gd

`replay()` initializes the generator and enters STANDS. `enter()` draws only when the stone begins a standing or hidden wait. It stores the phase's end in `until_ms`. `advance_to()` reads the time and crosses any boundaries already reached. It never draws merely because another frame arrived.

<!-- student-code:wait_cycle.gd -->
```gdscript
extends RefCounted

enum State { STANDS, LEAVES, GONE, RETURNS }
const NAMES := ["STANDS", "LEAVES", "GONE", "RETURNS"]
var run_seed := 42
var stand_band := Vector2(2.4, 4.6)
var gone_band := Vector2(1.1, 2.2)
var notice_ms := 1200
var cue_enabled := true
var rng := RandomNumberGenerator.new()
var state := State.STANDS
var now_ms := 0
var began_ms := 0
var until_ms := 0
var drawn_seconds := 0.0
var draws := 0

func replay() -> void:
    rng.seed = run_seed
    now_ms = 0
    draws = 0
    enter(State.STANDS, 0)

func enter(next_state: int, at_ms: int) -> void:
    state = next_state
    began_ms = at_ms
    var duration_ms := 700 if state == State.LEAVES else 400
    if state == State.STANDS or state == State.GONE:
        var band := stand_band if state == State.STANDS else gone_band
        var low := maxf(0.1, band.x)
        var high := maxf(low, band.y)
        drawn_seconds = low if is_equal_approx(low, high) else rng.randf_range(low, high)
        draws += 1
        duration_ms = int(round(drawn_seconds * 1000.0))
    until_ms = at_ms + duration_ms

func advance_to(target_ms: int) -> void:
    if target_ms < now_ms:
        return
    while target_ms >= until_ms:
        enter((state + 1) % 4, until_ms)
    now_ms = target_ms

func wait_left_ms() -> int:
    if state == State.STANDS or state == State.GONE:
        return maxi(0, until_ms - now_ms)
    return 0

func cue_visible() -> bool:
    return cue_enabled and state == State.STANDS and wait_left_ms() > 0 and wait_left_ms() <= notice_ms

func supports() -> bool:
    return state != State.GONE and (state != State.RETURNS or now_ms - began_ms >= 200)

func height() -> float:
    var elapsed := float(now_ms - began_ms)
    if state == State.LEAVES:
        var fraction := clampf(elapsed / 500.0, 0.0, 1.0)
        return -1.22 * (1.0 - cos(PI * fraction)) / 2.0
    if state == State.GONE:
        return -1.22
    if state == State.RETURNS:
        var fraction := clampf((elapsed - 200.0) / 200.0, 0.0, 1.0)
        return -1.22 * (1.0 + cos(PI * fraction)) / 2.0
    return 0.0
```

## The complete body: 14_a_wait_kept.gd

`_physics_process()` supplies elapsed time. `redraw()` asks the schedule for height, support and warning; it does not make another decision. Notice that the cube's collider is explicitly created alongside its BoxMesh. A visible body does not supply collision by itself.

<!-- student-code:14_a_wait_kept.gd -->
```gdscript
extends Node3D

const WaitCycle = preload("wait_cycle.gd")
const PointBody = preload("point_body.gd")
var cycle := WaitCycle.new()
var clock_ms := 0.0
var running := false
var point: XRToolsPickable
var stone: AnimatableBody3D
var collision: CollisionShape3D
var surface: MeshInstance3D
var crown: MeshInstance3D
var beacon: MeshInstance3D
var status: Label3D

func _ready() -> void:
    box(Vector3(3, 0.14, 1.8), Vector3(0, 0.07, 0), Color(0.12, 0.12, 0.14))
    box(Vector3(3, 2.5, 0.06), Vector3(0, 1.25, -0.8), Color(0.84, 0.82, 0.78))
    label("ONE STONE / ONE CLOCK", Vector3(0, 2.3, -0.75), 30)
    status = label("", Vector3(0, 1.96, -0.74), 21)
    stone = AnimatableBody3D.new()
    stone.sync_to_physics = false
    stone.collision_layer = 1
    stone.collision_mask = 0
    add_child(stone)
    surface = box(Vector3.ONE * 0.6, Vector3.ZERO, Color.WHITE)
    remove_child(surface)
    stone.add_child(surface)
    collision = CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = Vector3.ONE * 0.6
    collision.shape = shape
    stone.add_child(collision)
    crown = MeshInstance3D.new()
    var ring := TorusMesh.new()
    ring.inner_radius = 0.31
    ring.outer_radius = 0.37
    crown.mesh = ring
    crown.material_override = finish(Color(1, 0.78, 0.13))
    crown.position.y = 0.33
    stone.add_child(crown)
    beacon = MeshInstance3D.new()
    var bulb := SphereMesh.new()
    bulb.radius = 0.05
    bulb.height = 0.1
    beacon.mesh = bulb
    beacon.position.y = 0.43
    beacon.material_override = finish(Color.WHITE)
    stone.add_child(beacon)
    for i in range(4):
        label(["REPLAY", "RUN / STOP", "CUE", "+0.25 s"][i], Vector3((i - 1.5) * 0.7, 0.35, 0.91), 22)
    point = PointBody.new()
    point.position = Vector3(0, 0.6, 0.7)
    add_child(point)
    point.action_pressed.connect(use_point)
    replay()

func replay() -> void:
    running = false
    clock_ms = 0.0
    cycle.replay()
    redraw()

func _physics_process(delta: float) -> void:
    if running:
        clock_ms += delta * 1000.0
        cycle.advance_to(int(clock_ms))
    redraw()

func use_point(_held) -> void:
    var x := to_local(point.global_position).x
    if x < -0.7:
        replay()
    elif x < 0.0:
        running = not running
    elif x < 0.7:
        cycle.cue_enabled = not cycle.cue_enabled
    elif not running:
        clock_ms += 250.0
        cycle.advance_to(int(clock_ms))
    redraw()

func redraw() -> void:
    stone.position = Vector3(0, 1.35 + cycle.height() * 0.6, 0)
    collision.disabled = not cycle.supports()
    surface.material_override.albedo_color = [Color.CYAN, Color.CORAL, Color(0.15, 0.16, 0.2), Color.GREEN][cycle.state]
    crown.visible = cycle.cue_visible()
    beacon.visible = cycle.state == WaitCycle.State.LEAVES or cycle.state == WaitCycle.State.RETURNS
    status.text = "%s | %s | seed %d | draw %d\nwait %.3f s | left %.3f s | support %s\nclock %.3f s | phase ends %.3f s" % [
        WaitCycle.NAMES[cycle.state], "RUNNING" if running else "PAUSED", cycle.run_seed, cycle.draws,
        cycle.drawn_seconds, cycle.wait_left_ms() / 1000.0, "ON" if cycle.supports() else "OFF",
        cycle.now_ms / 1000.0, cycle.until_ms / 1000.0]

func finish(color: Color) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    return mat

func box(size: Vector3, at: Vector3, color: Color) -> MeshInstance3D:
    var view := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    view.mesh = mesh
    view.position = at
    view.material_override = finish(color)
    add_child(view)
    return view

func label(words: String, at: Vector3, font_size: int) -> Label3D:
    var view := Label3D.new()
    view.text = words
    view.position = at
    view.font_size = font_size
    view.pixel_size = 0.0025
    view.modulate = Color(0.02, 0.02, 0.02) if at.z < 0 else Color.WHITE
    view.outline_size = 0
    add_child(view)
    return view
```

## The same point: point_body.gd

This is the unchanged control from the earlier rooms. Its code is included so the example has every script it needs; the existing XR Tools installation supplies `XRToolsPickable`.

<details>
<summary>Complete inherited PointBody — keep this file beside the lesson</summary>

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

</details>

## Follow one cycle

`State` names four integers. Adding one and taking `% 4` moves through their fixed order. A random draw chooses a duration within the standing band, 2.4–4.6 seconds, or the hidden band, 1.1–2.2 seconds. These are endpoints, not a minimum plus a width. With equal endpoints the duration is fixed and no random number is consumed. The readout's draw count counts assigned waits, including fixed ones.

The deadline is **phase start + duration**. It is stored once. During a wait, subtracting the current clock gives time left. LEAVES and RETURNS use fixed durations; the tablet keeps the preceding drawn wait and shows zero wait remaining. The phase-end value still tells you when the movement phase finishes.

| State | Height | Collision support | Duration |
|---|---|---|---|
| STANDS | At the top | On | One sampled wait |
| LEAVES | Sinks for 0.5 s, then stays down for 0.2 s | On throughout | 0.7 s |
| GONE | Down | Off | One sampled wait |
| RETURNS | Stays down for 0.2 s, then rises for 0.2 s | Off for the first 0.2 s, then on | 0.4 s |

The cosine expressions reproduce the installed stone's smooth sine easing. They control travel, not the wait distribution. The colour marks the state; the white beacon marks either movement phase. The gold ring appears only during the last 1.2 seconds of STANDS, while the stone can still support a body. At the exact deadline the state becomes LEAVES and that ring is off.

The museum crossing uses asynchronous timers and tweens, with a ticket that invalidates an old loop on replay. This reconstruction uses one explicit clock instead. Replay replaces that clock and state, so no old timer or tween survives to move the stone later. Waits are rounded to milliseconds, matching the installed deadline display; production timers use the original fractional seconds. We are reproducing the draw rule and phase structure, not claiming frame-identical synchronization with the live crossing. The lesson's pause is local too: the museum around it keeps running.

`advance_to()` handles a frame that crosses more than one boundary. The next phase begins at the previous deadline, rather than at the late frame's arrival. Splitting the same elapsed time into smaller updates therefore keeps the same schedule. A long stall can skip displaying intermediate poses; physics cannot retroactively reproduce contacts that were never simulated. Replay is the only operation here that moves the clock backward.

## Change the notice, keep the event

Replay, then use +0.25 s until the ring appears. Record the deadline. Toggle CUE twice. The deadline, drawn duration and generator state stay the same. The number on the tablet still gives notice even when the stone does not.

Now change `notice_ms := 1200` to `notice_ms := 300` in the schedule and replay the same seed. Predict which will change: the first drawn duration, the moment of sinking, or the warning's duration. The ring now offers only 0.3 seconds of notice. The scheduled states remain identical. Explain where the player would have to look to compensate.

For a second variation, change `stand_band` to `Vector2(3.0, 3.0)`. Every standing wait becomes three seconds. The hidden waits still vary, so the whole cycle is not yet periodic. Because the fixed standing wait consumes no random value, the next hidden wait reads an earlier value from the seeded stream. Fixed and variable waits cannot be swapped while assuming every later duration will stay unchanged.

Finally change `run_seed` from 42 to 43. The order of states stays; the waits change. That number seeds this one learner stone. The full crossing has a separate seed that supplies different seeds to its three stones.

## What this room adds

You can now point to the moment when a decision enters the world, the state that keeps it, the view that reveals it, and the consequence attached to it. A random future can contain an already determined next event. A warning can change what a visitor knows without changing that event.

This closes the fourteen teaching halls of Randomness. Noise now returns to the relation between neighbouring samples. Keep this question available: which part is sampled, which part is retained, and which part is only being shown?
