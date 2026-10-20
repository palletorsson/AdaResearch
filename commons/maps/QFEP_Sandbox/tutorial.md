# Where the value arrives

**Learning elements**

- A named receiver and an explicit signal route
- Offered values and received values as separate state
- Connecting, cutting and delivering the current value
- An input freeze versus an animation restart
- Testing cause by changing one input at a time

We are inside Endless Museum's Sandbox. Find the two handles, the reactor and CONNECT / CUT. Move LAMBDA while the route is cut. Its number changes; the reactor's used value does not. The orb still moves. Cut input is not stopped time.

Edge of Chaos asked what happened after an update reached a field. Here we step back: did the value reach the intended object at all? Carry the same PointBody, LineSkin and initialized Bench. Bring back the moving cube from Transformation as a small receiver. Its motion makes a held input visible without needing to rebuild the installed reactor's particles and jitter.

## What is carried and supplied

Work in `res://doc/book/studies/qfep-lineage/` in the prepared Ada project. Keep `point_body.gd`, `line_skin.gd` and `bench.gd` unchanged. Their complete printed sources are in [Euclid](../Euclid_Parallel/tutorial.md#carried-files-complete) and [Russell](../Russell_Paradox/tutorial.md). Bench creates the labels, sphere and buttons; its `block` helper makes a BoxMesh as before. The supplied museum provides the player, XRTools and `res://commons/interactables/push_button.tscn`.

The original reactor and its two rails remain. Our working copy reconstructs their delivery rule and two response mappings: lambda selects colour and a speed value; phi lightens or darkens that colour. In the installed reactor, the speed is the maximum launch speed of particles. In our miniature, the same number moves one cube along a one-metre track. This is a deliberately smaller receiver, not an identical particle simulation. It lets us see a connection, retained inputs and continuing motion separately.

## Give the receiver its own state

Create `routed_receiver.gd`:

<!-- student-code:routed_receiver.gd -->
```gdscript
extends RefCounted
var values: Array[float] = [0.4,0.0]
var elapsed := 0.0
var distance := 0.0

func set_value(term: int, value: float) -> bool:
    if term < 0 or term > 1 or not is_finite(value): return false
    values[term] = clampf(value,0.0 if term == 0 else -1.0,1.0)
    return true

func speed() -> float:
    return 0.1+0.4*values[0]

func colour() -> Color:
    var blue := Color(0.2,0.4,1.0)
    var green := Color(0.2,1.0,0.5)
    var red := Color(1.0,0.3,0.2)
    var l := values[0]
    var base := blue.lerp(green,l/0.3) if l < 0.3 else green
    if l >= 0.5: base = green.lerp(red,(l-0.5)/0.5)
    var p := values[1]
    return base.lightened(p*0.3) if p > 0 else base.darkened(-p*0.3)

func advance(delta: float) -> bool:
    if not is_finite(delta) or delta < 0: return false
    elapsed += delta
    distance = fposmod(distance+speed()*delta,1.0)
    return true

func repeat() -> void:
    elapsed = 0.0
    distance = 0.0
```

`values[0]` is received lambda, between zero and one. `values[1]` is received phi, between minus one and one. They belong to this receiver. The sphere will have another pair of values; those two pairs are the point of the lesson.

The colour branches reproduce this reactor's authored mapping. Lambda moves blue toward green below 0.3, keeps green until 0.5, then moves toward red. Phi changes lightness. These cutoffs are choices in the artwork, not measured boundaries of life or chaos. `speed` returns 0.1 + 0.4 × received lambda. At lambda 0.85 it is 0.44 metres per second. Phi leaves that speed alone.

`advance` applies the familiar distance = speed × elapsed-time relation. `fposmod` returns the cube to the start whenever its distance reaches one metre. That wrap is an authored display convention, not a collision or force. `repeat` clears time and distance but preserves the received inputs. Even lambda zero gives speed 0.1; zero is not a stop switch in this mapping.

## Make the route explicit

Create `input_route.gd`:

<!-- student-code:input_route.gd -->
```gdscript
extends RefCounted
const Receiver = preload("routed_receiver.gd")
signal value_offered(term: int, value: float)
var offered: Array[float] = [0.4,0.0]
var receiver: Receiver
var connected := false
var kept: Dictionary = {}

func _init(target: Receiver) -> void:
    receiver = target
    value_offered.connect(_deliver)

func set_value(term: int, value: float) -> bool:
    if term < 0 or term > 1 or not is_finite(value): return false
    offered[term] = clampf(value,0.0 if term == 0 else -1.0,1.0)
    value_offered.emit(term,offered[term])
    return true

func _deliver(term: int, value: float) -> void:
    if connected: receiver.set_value(term,value)

func toggle() -> void:
    connected = not connected
    if connected:
        for term in 2: _deliver(term,offered[term])

func reading() -> Dictionary:
    return {"offered":offered.duplicate(),"used":receiver.values.duplicate(),
        "connected":connected,"speed":receiver.speed(),"colour":receiver.colour(),
        "elapsed":receiver.elapsed,"distance":receiver.distance}

func keep() -> void:
    kept = reading()
```

The constructor receives one particular Receiver instance. There is no global lookup and no search for a similarly named object. Creating another receiver elsewhere does not connect it.

`set_value` stores an offered value and emits `value_offered(term, value)`. The signal calls `_deliver`. Its `if connected` is the gate: while cut, the offered value still changes but the receiver gets no update. The signal subscription itself remains in place. CONNECT / CUT names delivery through this route, not whether the interface can hear its own input.

Connecting immediately delivers both current offered values. Otherwise, a control moved while cut would remain stale at the receiver until the next gesture. Cutting changes only the gate. It does not restore defaults, clear the received pair, stop the receiver's clock or replay missed gestures. Reconnecting sends the current pair, not a queue of earlier movements.

`reading` reads the receiver's actual state. It does not relabel the offered pair as “used”. `duplicate` gives KEEP independent copies of both arrays. This snapshot includes connection state, speed, colour, time and distance. It lasts for this run and is not a complete event history or a disk save.

## Put the same sphere at the source

Create `sandbox_study.gd`:

<!-- student-code:sandbox_study.gd -->
```gdscript
extends "bench.gd"
const Receiver = preload("routed_receiver.gd")
const Route = preload("input_route.gd")
const LOW := 1.12
const TRAVEL := 0.48
var receiver := Receiver.new()
var model := Route.new(receiver)
var selected := 0
var cube: MeshInstance3D
var wire: MeshInstance3D
var offered_label: Label3D
var used_label: Label3D

func _ready() -> void:
    start("OFFERED / RECEIVED",["LAMBDA","PHI","CONNECT / CUT","REPEAT","KEEP"],
        [select.bind(0),select.bind(1),toggle,repeat_response,keep])
    block(self,Vector3(-1.17,LOW+TRAVEL/2,0.05),Vector3(0.018,TRAVEL,0.018),Color("526071"))
    segment(Vector3(-0.2,1.12,0),Vector3(0.8,1.12,0))
    cube = block(self,Vector3(-0.2,1.24,0),Vector3.ONE*0.2,Color.WHITE)
    wire = block(self,Vector3(-0.69,1.02,0.22),Vector3(0.7,0.015,0.025),Color.WHITE)
    offered_label = label(self,"",Vector3(-0.91,1.70,0.18),20)
    used_label = label(self,"",Vector3(0.36,1.57,0),20)
    label(self,"1 metre / return at end",Vector3(0.3,1.02,0.36),17)
    redraw()

func _process(delta: float) -> void:
    if point == null: return
    if point.held():
        var fraction := clampf((to_local(point.global_position).y-LOW)/TRAVEL,0.0,1.0)
        model.set_value(selected,fraction if selected == 0 else 2.0*fraction-1.0)
    receiver.advance(delta)
    redraw()

func select(term: int) -> void:
    if point.held(): return
    selected = term
    redraw()

func toggle() -> void:
    if point.held(): return
    model.toggle()
    redraw()

func repeat_response() -> void:
    if point.held(): return
    receiver.repeat()
    redraw()

func keep() -> void:
    if point.held(): return
    model.keep()
    redraw()

func redraw() -> void:
    var r := model.reading()
    cube.position.x = -0.2+r.distance
    cube.material_override.albedo_color = r.colour
    wire.material_override.albedo_color = Color("43d7dc") if r.connected else Color("42484b")
    var fraction: float = r.offered[0] if selected == 0 else (r.offered[1]+1.0)*0.5
    point_home = Vector3(-1.17,LOW+fraction*TRAVEL,0.22)
    offered_label.text = "OFFER %.2f / %+.2f" % r.offered
    used_label.text = "USED %.2f / %+.2f" % r.used
    var kept := "KEEP: no comparison yet"
    if not model.kept.is_empty():
        kept = "Kept offer %.2f / %+.2f; used %.2f / %+.2f" % [
            model.kept.offered[0],model.kept.offered[1],model.kept.used[0],model.kept.used[1]]
    readout.text = "%s / hand edits %s\nSpeed %.2f m/s / time %.1f / distance %.2f\n%s" % [
        "CONNECTED" if r.connected else "CUT: inputs held","LAMBDA" if selected == 0 else "PHI",
        r.speed,r.elapsed,r.distance,kept]
```

The same hand-held sphere edits one offered value at a time. LAMBDA selects the unsigned range; PHI maps the same local height to a signed range. Release before selecting another term or pressing a button. The inherited bench returns the sphere to the selected value's height.

The readout separates OFFER from USED. The coloured strip is a diagram of the connection; the signal and conditional delivery implement it. The cube's material reads received values, and its position reads received distance. Neither reads the hand directly. Both the cube and sphere are built once and retained through the experiment.

`_process` first handles any offered input, then advances the receiver, then redraws. Notice that `receiver.advance(delta)` is outside the connection condition. The cube continues moving while cut. REPEAT resets its track clock using its last received speed; it leaves the route and both input pairs intact. No timer, global parameter manager or hidden scene node is required.

## Build and investigate

Open `res://doc/book/studies/qfep-lineage/sandbox.tscn` and press F6. The supplied `sandbox_museum.gd` adapter loads the existing hall and mounts this working bench in a checked location.

1. Start CUT. Select LAMBDA and lift the sphere to about 0.85. Select PHI and set about +0.70. OFFER changes, while USED remains 0.40 / 0.00. Predict the cube's speed: 0.26 m/s. KEEP this disagreement.
2. Press CONNECT / CUT once. USED immediately takes both current values. At lambda 0.85, expect 0.44 m/s. Choose a part of the track and watch the cube return through it.
3. Leave lambda steady. Change phi from +0.70 to −0.70. The cube darkens; speed stays the same. This isolates one mapping instead of assigning every visible difference to the whole pair.
4. CUT. Change the offered pair to 0.15 / +0.60. The cube keeps using its previous pair. Press REPEAT: the cube returns to the track's start, then continues at the held speed. A restart is not an undo of the earlier delivery.
5. CONNECT again. The present pair arrives immediately. Speed becomes 0.16 m/s. REPEAT and watch again. KEEP still holds the earlier offer/used disagreement until you explicitly replace it.
6. Independent task: leave OFFER at 0.90 / +0.50 while USED is 0.25 / −0.50. Do this through the controls, without changing an initializer. Predict speed 0.20 m/s, then explain which connection state makes this possible. What changes immediately if you reconnect?

Return to the installed reactor. Make the same connect/cut comparison with its real rails and read its actual particle maximum speed. REPEAT there restarts the CPU pulse and seeded jitter and restarts GPU emission; it does not promise identical histories for every GPU particle. The neighbouring particle field remains independent. Similar movement in one room is not evidence that both objects received your gesture.

The production study also has a discovery problem our small example avoids: it requires exactly one LambdaSlider and one PhiSlider under the same hall parent and refuses ambiguous or missing sources. Our constructor already names one receiver. These are two ways to make the intended route explicit; neither makes all controls global.

## Test the printed construction

Create `route_checks.gd`:

<!-- student-code:route_checks.gd -->
```gdscript
extends RefCounted
const Receiver = preload("routed_receiver.gd")
const Route = preload("input_route.gd")

func run() -> void:
    var receiver := Receiver.new()
    var untouched := Receiver.new()
    var route := Route.new(receiver)
    assert(not route.connected and receiver.values==[0.4,0.0])
    assert(is_equal_approx(receiver.speed(),0.26))
    route.set_value(0,0.85)
    route.set_value(1,0.7)
    assert(route.offered==[0.85,0.7] and receiver.values==[0.4,0.0])
    route.keep()
    route.toggle()
    assert(route.connected and receiver.values==[0.85,0.7])
    assert(is_equal_approx(receiver.speed(),0.44))
    assert(untouched.values==[0.4,0.0])
    var light := receiver.colour()
    route.set_value(1,-0.7)
    var dark := receiver.colour()
    assert(dark.r<light.r and dark.g<light.g and dark.b<light.b)
    assert(is_equal_approx(receiver.speed(),0.44))
    route.toggle()
    route.set_value(0,0.15)
    route.set_value(1,0.6)
    assert(receiver.values==[0.85,-0.7] and route.offered==[0.15,0.6])
    receiver.advance(1.0)
    assert(is_equal_approx(receiver.distance,0.44))
    assert(receiver.elapsed==1.0 and not route.connected)
    receiver.repeat()
    assert(receiver.distance==0.0 and receiver.elapsed==0.0)
    assert(receiver.values==[0.85,-0.7] and route.offered==[0.15,0.6] and not route.connected)
    route.toggle()
    assert(receiver.values==[0.15,0.6])
    receiver.advance(2.0)
    assert(is_equal_approx(receiver.distance,0.32))
    receiver.repeat()
    for i in 20:receiver.advance(0.1)
    assert(is_equal_approx(receiver.distance,0.32) and is_equal_approx(receiver.elapsed,2.0))
    assert(route.kept.offered==[0.85,0.7] and route.kept.used==[0.4,0.0])
    var copy := route.reading()
    copy.used[0]=1.0
    assert(receiver.values[0]==0.15)
    assert(not route.set_value(2,0.5) and not route.set_value(-1,0.5))
    assert(not route.set_value(0,NAN) and not receiver.set_value(1,INF))
    assert(not receiver.advance(-1.0) and not receiver.advance(NAN))
    route.set_value(0,5.0)
    route.set_value(1,-5.0)
    assert(route.offered==[1.0,-1.0] and receiver.values==route.offered)
    receiver.repeat()
    receiver.advance(2.5)
    assert(is_equal_approx(receiver.distance,0.25))
    assert(is_equal_approx(receiver.speed(),0.5))
    route.set_value(0,0.0)
    route.set_value(1,0.0)
    assert(receiver.colour().is_equal_approx(Color(0.2,0.4,1.0)))
    assert(is_equal_approx(receiver.speed(),0.1))
```

Run `python tools/test_qfep_sandbox.py`. The supplied harness extracts the four new files above and the three carried files from their printed sources. It runs these assertions, synthetic sphere/button actions under a rotated and translated parent, and the independent task. It compares the colour and speed mappings against the installed reactor at several settings. Its controlled animation steps distinguish numerical agreement from screenshots taken at arbitrary wall-clock times.

A rendered probe loads the real hall, uses the actual rail/button signals, checks that the independent field retains its inputs, and mounts the freshly extracted working copy. These are author-operated synthetic tests, not evidence of independent learner understanding or headset comfort.

## Carry onward

We now have a control, a named receiver and an observable connection between them. Keep offered inputs, used inputs and running state distinguishable. In Synthesis the receiver will be a deformable body: inspect which values actually reach its mechanics before interpreting the resulting movement.

**Short instruction:** Carry PointBody + Bench + LineSkin; reuse BoxMesh receiver. Explicit Receiver reference; signal offers L/P; delivery gate starts CUT. Offered pair separate from received pair. Connect sends current pair; cut retains used values; motion continues. L maps colour/speed, P lightness; cube track is a reduced receiver, not particle reconstruction. REPEAT resets clock/distance only. KEEP copies both pairs. Assert isolation, immediate delivery, continued motion, snapshot independence, transformed hand mapping, and installed colour/speed agreement. Next: local controls reaching a deformable body.
