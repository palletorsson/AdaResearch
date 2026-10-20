# Where the height returns

**Learning elements**

- Ordered positions
- world-frame measurement
- open and closed paths
- accumulated differences
- invariants

At the existing staircase, STEP follows measured tread centres; FORM offers five arrangements. Our smaller construction isolates one question using four familiar cube treads, the carried LineSkin cylinders and one PointBody marker. No faces of the cube are transformed individually. The player stays on the museum floor; the marker travels the model.

The four centres rise by 0.2 metres three times. Closing the route requires a −0.6-metre move. `step` measures actual centre heights after applying the chosen transform, accumulating positive changes in up and negative magnitudes in down. On return, up minus down is zero within numerical tolerance. `closure` calculates every edge difference independently of the visitor's partial journey. Each height appears once with each sign. This algebraic cancellation explains the general closed-route invariant; the program checks finite instances.

OPEN removes the closing connection and refuses movement past the last centre. It does not wrap through an invisible drop. TILT rotates the entire arrangement by 0.35 radians and starts a new measurement, so no journey mixes coordinate frames. The displayed treads and measured centres use the same transform. Individual signs may change when up changes relative to the model, but a closed route still cancels. RESET keeps the selected arrangement and tilt.

Walk around the installation's separate perspective work. Apparent contact in an image and coincidence in three-dimensional coordinates require different evidence. Our working copy does not fabricate an impossible staircase or prove a result about formal arithmetic.

## Continue inside the museum

Use the existing AdaResearch project with Godot 4.6 and its installed XR Tools. Save these files together under `res://doc/book/studies/foundations-lineage/`. Carry `point_body.gd` and `line_skin.gd` unchanged from Euclid / Non-Euclidean Spaces. Their class construction and pickup were already printed there. Carry `bench.gd` unchanged from Russell. It supplies only geometry, labels, the visible sphere and button wiring; the rule below remains new.

Run the supplied `escher.tscn` in that folder with F6. Its `escher_museum.gd` launcher opens **Escher_Impossible** with the existing museum player, room and lighting, then adds your working copy beside the original exhibits. The launcher, `commons/interactables/push_button.tscn` and XR setup are declared infrastructure. No autoload, label, camera or other node is assumed inside your new script: the printed bench creates its own nodes and connects the buttons. This is a session study; it does not replace an installed artifact or carry a live node across hall loads.

The bench synchronizes an unheld frozen sphere on physics ticks. All model positions are local to the unit-scale bench unless a world transform is explicitly passed. Its slab and thin-cylinder lines are visual guides, not a new walkable floor. Use the museum's existing locomotion and pointer/grab controls.

## Complete new files

Read the rule first, then its museum display. There is one `_ready` per script; inherited `start` constructs the bench once. Save each block as the filename above it.

### `height_route.gd`

<!-- student-code:height_route.gd -->
```gdscript
extends RefCounted
var points: Array[Vector3] = [Vector3(-0.7,0,-0.5), Vector3(0.7,0.2,-0.5),
    Vector3(0.7,0.4,0.5), Vector3(-0.7,0.6,0.5)]
var closed := true
var index := 0
var up := 0.0
var down := 0.0
var last := 0.0

func reset() -> void:
    index=0
    up=0
    down=0
    last=0

func step(frame: Transform3D = Transform3D.IDENTITY) -> bool:
    if points.is_empty() or (not closed and index==points.size()-1): return false
    var next := (index+1)%points.size()
    last = (frame*points[next]).y - (frame*points[index]).y
    up += maxf(last,0)
    down += maxf(-last,0)
    index=next
    return true

func closure(frame: Transform3D = Transform3D.IDENTITY) -> float:
    var total := 0.0
    for i in points.size():
        total += (frame*points[(i+1)%points.size()]).y - (frame*points[i]).y
    return total
```

### `escher_study.gd`

<!-- student-code:escher_study.gd -->
```gdscript
extends "bench.gd"
const HeightRoute = preload("height_route.gd")
var model := HeightRoute.new()
var tilted := false

func _ready() -> void:
    start("ESCHER / WHERE THE RISE RETURNS", ["STEP", "OPEN", "TILT", "RESET"],
        [advance, open_route, tilt, reset])
    refresh()

func frame() -> Transform3D:
    return global_transform*Transform3D(Basis(Vector3.FORWARD, 0.35 if tilted else 0), Vector3.UP*1.05)

func advance() -> void:
    if point.held(): return
    model.step(frame())
    refresh()

func open_route() -> void:
    if point.held(): return
    model.closed = not model.closed
    reset()

func tilt() -> void:
    if point.held(): return
    tilted = not tilted
    reset()

func reset() -> void:
    if point.held(): return
    model.reset()
    refresh()

func refresh() -> void:
    clear_drawing()
    var t := global_transform.affine_inverse()*frame()
    for i in model.points.size():
        var at: Vector3 = t*model.points[i]
        block(drawing, at, Vector3(0.25,0.07,0.25), Color("9eadb9"))
        label(drawing,str(i),at+Vector3(0,0.12,0),18)
        if i<model.points.size()-1 or model.closed:
            segment(at,t*model.points[(i+1)%model.points.size()])
    point_home = t*model.points[model.index]+Vector3.UP*0.16
    readout.text = "%s | step %d\nLast %+.3f m; up %.3f / down %.3f\n%s" % [
        "CLOSED" if model.closed else "OPEN", model.index, model.last, model.up, model.down,
        "Closing differences sum to %.5f"%model.closure(frame()) if model.closed else "The open end does not wrap."]
```

## Predict, build, check

Predict the fourth change before pressing it: −0.6 metres in the unrotated study. Assert four steps return the marker to index 0 and equal ascent/descent. Open the route: after three moves, the next attempt must fail and retain index 3. Tilt the whole study around another axis in code; calculate each world height and predict the return difference. Keep that frame fixed during a run.

Try changing only one tread's drawn angle while leaving its centre fixed. The centre measure will miss that surface slope; name the limitation rather than calling the reading wrong. The next hall asks what a produced object can witness.

The automated reconstruction tests extract the printed files, add only these declared carried dependencies and run native Godot assertions. They use synthetic interaction. They do not establish human learning or headset reach.
