# Classification — a group without a name

## Learning elements

- Observations versus cluster centres
- Squared distance and nearest-centre assignment
- An index is not a supplied class label
- A mean computed with a sum and a count
- Alternating assignment and centre updates
- Chosen K, starting positions, ties and empty groups
- Reusing PointBody in museum-local coordinates

## Keep the point; change its job

In Gradient Landscape you moved the familiar sphere to choose a line's slope and intercept. Here it selects one cluster centre. The little observations remain fixed while their group assignments change. We are still working inside Endless Museum. Start with the existing K-means exhibit: STEP assigns points and moves centres in one action. Our reconstruction separates those actions so you can predict each one.

The hall is called Classification. This particular construction is **unsupervised clustering**: the input contains positions, without correct class names. The SVM and forest elsewhere in the hall use supplied labels. They remain comparisons; we will construct a labelled network in the next lesson, then teach the sphere with our hands in Perception.

Carry `point_body.gd` unchanged from `doc/book/studies/ml-gradient/point_body.gd`. It already constructs the sphere, its collision shape, XR pickup and the desktop grab adapter. Do not paste another sphere constructor or retain Gradient's host. Create a new folder with that carried file and the two complete files below. There is one `_ready()` in the new host. The same PointBody instance survives all controls in this study; changing halls still creates a new scene instance.

**Supplied by Ada:** Godot 4.6, XR Tools, the museum/player rig and `res://commons/audio/rack_templates/RackTemplates.gd`. RackTemplates builds the familiar spatial buttons; their `InteractableAreaButton.button_pressed` signals are connected below. These are declared interface dependencies, not a hidden clustering model.

Run `res://doc/book/studies/ml-classification/Classification.tscn` to enter the actual hall with the study mounted on its clear floor. This supplied scene uses `classification_museum.gd` to open the museum and attach `cluster_study.gd`; the launcher contains no learning algorithm. If working in your own folder, attach your host to a Node3D in the supplied study position, or change the launcher's `LESSON` preload to your host. No camera, light or XR rig needs rebuilding. All observations and parameters here are session-only.

## Predict before pressing

Small pale dots are observations. C1…CK are centres; **CENTRE** makes the black carried sphere stand for another centre. Before ASSIGN, point to the closest centre for one observation. ASSIGN colours the observations and draws thin cylinders to their chosen centres. Positions do not move. Before MEAN, predict where one centre will move: sum the positions assigned to it and divide by their count. MEAN moves centres but keeps the last assignments visible. The next ASSIGN may change those assignments.

The two steps alternate. Pressing the wrong next step does nothing; the readout says which is due. RESET repeats the start for the current K and dataset. K 2, K 3 and K 4 choose a count and restart the centres without changing observations. DATA cycles twelve points in three authored blobs, two twelve-point rings, and a regular five-by-five grid. These are fixed teaching arrangements, not a fresh random draw or measured people.

For fixed centres, each observation chooses the smallest **squared** distance. Squaring a nonnegative distance keeps its ordering. For fixed assignments, the arithmetic mean minimizes the sum of squared distances in that group. This is why the two steps belong together. The readout shows **SSE**, the sum of squared errors for the assignments currently displayed. After MEAN those colours are deliberately retained until the next ASSIGN. Before any assignment there is no score; we display “unassigned,” not a perfect zero.

These operations reuse arrays, indices, loops and vectors from earlier halls. Unlike Gradient, there is no numerical derivative or learning-rate slider: the mean gives the centre update directly. K and initial centre positions still come from us. A settled arrangement can depend on its start; it is not guaranteed to be the best arrangement among all starts.

## 1. The complete clustering model

Save as `cluster_model.gd`. `data[i]` is an observation, `groups[i]` is the integer index of its centre, and `centres[j]` is that centre's current position. A missing assignment array means no grouping has yet been made. The model stores two coordinates; the view maps them to the table's x/z plane.

<!-- student-code:cluster_model.gd -->
```gdscript
extends RefCounted
var data := PackedVector2Array()
var centres := PackedVector2Array()
var groups := PackedInt32Array()
var k := 3
var dataset := 0
var next_assignment := true
var rounds := 0
var status := "ASSIGN NEXT"

func _init() -> void:
    set_data(0)

func set_data(choice: int) -> void:
    dataset = posmod(choice, 3)
    data.clear()
    match dataset:
        0:
            for centre: Vector2 in [Vector2(-0.8,-0.6), Vector2(0.8,-0.6), Vector2(0,0.7)]:
                for offset: Vector2 in [Vector2(-0.1,0),Vector2(0.1,0),Vector2(0,-0.15),Vector2(0,0.15)]:
                    data.append(centre+offset)
        1:
            for radius: float in [0.35, 0.85]:
                for i in 12:
                    var angle := TAU*i/12.0
                    data.append(Vector2(cos(angle),sin(angle))*radius)
        2:
            for z in 5:
                for x in 5: data.append(Vector2(x-2,z-2)*0.4)
    reset(k)

func reset(count: int) -> void:
    k = clampi(count, 2, 4)
    var start := PackedVector2Array([Vector2(-0.6,-0.3), Vector2(0,0.1), Vector2(0.6,0.3), Vector2(0,-0.8)])
    centres = start.slice(0,k)
    invalidate()

func invalidate() -> void:
    groups.clear()
    next_assignment = true
    rounds = 0
    status = "ASSIGN NEXT"

func nearest(p: Vector2) -> int:
    var winner := 0
    var best := p.distance_squared_to(centres[0])
    for j in range(1,centres.size()):
        var distance := p.distance_squared_to(centres[j])
        if distance < best: # Equal distances retain the lower index.
            best = distance
            winner = j
    return winner

func assign() -> bool:
    if not next_assignment: return false
    groups.clear()
    for p in data: groups.append(nearest(p))
    next_assignment = false
    status = "ASSIGNED / MEAN NEXT"
    return true

func move_means() -> bool:
    if next_assignment: return false
    for j in centres.size():
        var sum := Vector2.ZERO
        var count := 0
        for i in data.size():
            if groups[i] == j:
                sum += data[i]
                count += 1
        if count > 0: centres[j] = sum/count
    rounds += 1
    next_assignment = true
    status = "MEANS MOVED / ASSIGN NEXT"
    return true

func score() -> float:
    var total := 0.0
    for i in groups.size():
        total += data[i].distance_squared_to(centres[groups[i]])
    return total

func move_centre(index: int, where: Vector2) -> void:
    centres[index] = Vector2(clampf(where.x,-1,1),clampf(where.y,-1,1))
    invalidate()
```

`nearest()` compares every centre and keeps the current winner. The strict `<` gives an exact tie to the earlier index. That tie policy is a choice, not evidence that a point belongs more strongly to that group. `move_means()` starts a fresh sum and count for each group. An empty group keeps its previous centre, avoiding division by zero. K counts available centres; it does not promise K occupied groups.

`assign()` changes only the indices. `move_means()` changes only centres. `score()` recomputes the current SSE from both arrays. In exact arithmetic, each alternating step cannot increase that score on fixed observations, K and assignments/centres as appropriate. Floating-point comparisons need a small tolerance. Moving a centre by hand, resetting, changing K or switching data interrupts that comparison. A lower SSE alone is also not a reason to prefer more groups: allowing one centre per point could drive it to zero without supplying a useful explanation.

## 2. Put that operation on the museum table

Save as `cluster_study.gd`. The host creates one carried PointBody. Other centre markers and observation dots are display meshes. The dark table and button surfaces use unlit materials so the comparison remains readable under the museum lights.

<!-- student-code:cluster_study.gd -->
```gdscript
extends Node3D
const Model = preload("cluster_model.gd")
const PointBody = preload("point_body.gd")
const Rack = preload("res://commons/audio/rack_templates/RackTemplates.gd")
const COLOURS = [Color("f2799d"),Color("62d8da"),Color("ffd56c"),Color("ad9cf2")]
const DATASETS = ["BLOBS", "RINGS", "GRID"]
var model := Model.new()
var point: PointBody
var selected := 0
var was_held := false
var drawing := Node3D.new()
var readout := Label3D.new()

func _ready() -> void:
    add_child(drawing)
    var backing := MeshInstance3D.new(); var slab := BoxMesh.new()
    slab.size = Vector3(2.7,0.06,2.7); backing.mesh = slab
    backing.position.y = 0.88; backing.material_override = material(Color("18202b")); add_child(backing)
    readout.position = Vector3(0,2.1,-1.45)
    readout.font_size = 27; readout.pixel_size = 0.0025; add_child(readout)
    var header := MeshInstance3D.new(); var plate := BoxMesh.new()
    plate.size = Vector3(3.2,0.65,0.04); header.mesh = plate
    header.position = Vector3(0,2.1,-1.5)
    header.material_override = material(Color("18202b")); add_child(header)
    point = PointBody.new(); add_child(point)
    var words := ["ASSIGN","MEAN","RESET","CENTRE","K 2","K 3","K 4","DATA"]
    var rows: Array = []
    for r in 2:
        var row: Array = []
        for c in 4: row.append({"type":"button","label":words[r*4+c]})
        rows.append(row)
    var panel := Rack.create_panel("K-MEANS",rows)
    panel.position = Vector3(0,1.05,1.7); panel.rotation_degrees.x = -30
    panel.scale = Vector3.ONE*2; add_child(panel)
    for mesh in panel.find_children("*","MeshInstance3D",true,false):
        var m := mesh.material_override as BaseMaterial3D
        if m != null:
            m = m.duplicate(); m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
            mesh.material_override = m
    for i in words.size():
        var button = panel.find_child("Btn_%d"%i,true,false).get_node("InteractableAreaButton")
        button.button_pressed.connect(func(_area):command(words[i]))
    redraw()

func material(colour: Color) -> StandardMaterial3D:
    var m := StandardMaterial3D.new(); m.albedo_color = colour
    m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    return m

func place(p: Vector2, height: float = 0.98) -> Vector3:
    return Vector3(p.x*1.25,height,p.y*1.25)

func dot(p: Vector3, radius: float, colour: Color) -> void:
    var mesh := SphereMesh.new(); mesh.radius = radius; mesh.height = radius*2
    mesh.radial_segments = 16; mesh.rings = 8
    var node := MeshInstance3D.new(); node.mesh = mesh; node.position = p
    node.material_override = material(colour); drawing.add_child(node)

func rod(a: Vector3, b: Vector3, colour: Color) -> void:
    var d := b-a
    if d.length() < 0.00001: return
    var mesh := CylinderMesh.new(); mesh.top_radius = 0.007; mesh.bottom_radius = 0.007
    mesh.height = d.length(); mesh.radial_segments = 8
    var node := MeshInstance3D.new(); node.mesh = mesh; node.position = (a+b)*0.5
    node.quaternion = Quaternion(Vector3.UP,d.normalized())
    node.material_override = material(colour); drawing.add_child(node)

func redraw() -> void:
    for child in drawing.get_children(): drawing.remove_child(child); child.queue_free()
    for i in model.data.size():
        var colour := Color("eeeeee")
        if not model.groups.is_empty():
            var j: int = model.groups[i]; colour = COLOURS[j]
            rod(place(model.data[i]),place(model.centres[j],1.12),colour.darkened(0.35))
        dot(place(model.data[i]),0.034,colour)
    for j in model.centres.size():
        var centre: Vector3 = place(model.centres[j],1.12)
        if j != selected: dot(centre,0.07,COLOURS[j])
        var label := Label3D.new(); label.text = "C%d"%(j+1)
        label.position = centre+Vector3(0,0.18,0)
        label.modulate = COLOURS[j]; label.font_size = 25; label.pixel_size = 0.002
        drawing.add_child(label)
    if not point.held(): point.global_position = to_global(place(model.centres[selected],1.12))
    var score := "unassigned"
    if not model.groups.is_empty(): score = "SSE %.4f"%model.score()
    readout.text = "%s / K %d / %d mean updates / %s\n%s\nBlack sphere = C%d. Grab to change its position.\nSmall dots stay fixed. Colour is an index, not a name." % [
        DATASETS[model.dataset],model.k,model.rounds,score,model.status,selected+1]

func command(word: String) -> void:
    if point.held(): return
    match word:
        "ASSIGN": model.assign()
        "MEAN": model.move_means()
        "RESET": model.reset(model.k)
        "CENTRE": selected = (selected+1)%model.k
        "K 2", "K 3", "K 4": model.reset(int(word.right(1))); selected = 0
        "DATA": model.set_data(model.dataset+1); selected = 0
    redraw()

func _physics_process(_delta: float) -> void:
    if not point.held():
        point.global_position = to_global(place(model.centres[selected],1.12))

func _process(_delta: float) -> void:
    if point.held():
        var hand := to_local(point.global_position)
        model.move_centre(selected,Vector2(hand.x,hand.z)/1.25)
        was_held = true; redraw()
    elif was_held:
        was_held = false; redraw()
```

`place()` applies one scale to both coordinate axes: one model unit occupies 1.25 metres. Distance is computed in the two model coordinates, not from a controller's height. During pickup, `to_local()` removes the hall's translation and rotation before x/z are read. We bound hand-chosen centres to the displayed square, [-1, 1] on each axis. Upon release the sphere returns to the centre's display height. `_physics_process()` keeps the unheld rigid body synchronized to its current centre on physics ticks; a one-off visual move could otherwise be overwritten by the physics state. While held, the hand retains control. The table is a diagram, not a cloth or physics simulation.

Moving a centre clears assignments and resets the round counter. We do not leave stale colours pretending to answer a changed question. Put the sphere down, then ASSIGN. Controls are ignored while it is held. CENTRE changes which parameter the existing sphere controls; it does not destroy and recreate the point. No trigger action is added in this lesson.

## Build, then investigate

1. With BLOBS and K 3, alternate ASSIGN and MEAN. Note SSE after each action. Watch a fixed observation near a boundary; explain a colour change using the moving centres.
2. RESET and move C1 before assigning. Keep the same observations and K. Follow the different steps rather than assuming the final colouring must differ. Compare groups as sets of positions: an index or colour can be renamed without changing a partition.
3. Choose RINGS. Follow either ring, then inspect which centres claim its points. Nearest-centre regions need not follow a curved ring. Choose GRID: grouping continues even though you supplied no separated blobs.
4. Change K. State what changed in the question. Return to the same K and DATA to repeat its fixed start; there is no hidden reseeding.
5. Independently check a smaller case in the model: observations `(-0.8, 0), (0, 0), (0.8, 0)` and centres `(-0.8, 0), (0.8, 0)`. ASSIGN gives `[0, 0, 1]`, because the middle point ties. SSE is 0.64. MEAN puts the first centre at `(-0.4, 0)` and retains the second at `(0.8, 0)`; SSE becomes 0.32. Explain both numbers before running it. Then move the middle observation to `(0.2, 0)` and predict the new assignment and means. To display your own fixture, keep its coordinates inside the square and preserve the model's array/index relationship.

**Reconstruction check.** `python tools/test_ml_classification_lesson.py` extracts these two printed blocks, adds only the declared carried PointBody and runs assertions in native Godot. The checks include an independently calculated fixture, the changed middle observation, ties, empty groups, alternating steps, unchanged data, squared-distance descent, real button signals and pickup in a rotated/translated host. The museum probe mounts those extracted files in ML_Classification and checks placement and controls. Synthetic checks cannot establish human headset reach or whether the explanation is clear to a new reader.

## What travels onward

Carry the distinction between observations, parameters, the measure and the update procedure. Keep PointBody as a reusable construction. The indices here have no supplied meanings. In Neural Networks we will fit weights against labelled examples; in Perception you will decide what A, B and C mean for a two-hand pose. Neither a shorter distance nor a smaller training error settles what those names ought to mean.

Algorithm reference: the [scikit-learn clustering guide](https://scikit-learn.org/stable/modules/clustering.html#k-means) describes the squared-distance objective, alternating mean updates and sensitivity to initialization. We implement that small process directly here, without importing scikit-learn. The original museum exhibit has a different readout: it accumulates ordinary distances before moving its centres. Its “Total distance” must not be mistaken for this study's current SSE.

AI-short: Carry Gradient PointBody. Fixed 2D observations; sphere controls selected centre. ASSIGN nearest squared distance → MEAN by sum/count; alternate. Tie lower index; empty centre retained. Hand edit invalidates groups. K 2/3/4; fixed blobs/rings/grid. SSE current displayed assignments; original exhibit reports pre-update unsquared distance. Groups lack supplied names. Print model+host; declare XR/Rack/museum. Test fixture+mutation+controls+native placement. Next learned weights.
