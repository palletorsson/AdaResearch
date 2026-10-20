# Gradient Landscape — a line and a loss

## Learning elements

- Prediction from two parameters: slope and intercept.
- Residuals, mean squared error and Huber loss.
- A numerical gradient and a learning-rate step.
- Observation space versus parameter space.
- Controlled comparisons, overshoot and a declared display boundary.

## Carry the point into another kind of space

Evolution let the same point control a population living under an energy rule. Keep that PointBody class. Here we change its job: the point stands for **one candidate line**, described by two numbers. Its horizontal position selects a slope and an intercept. The height under it shows the loss assigned to that line. We already know positions, arrays, functions, meshes and seeded comparisons; now we make the score explicit and use its local slope to change a model.

The hall's Loss Function Comparator places three losses beside one dataset. We reconstruct its central question with five visible observations, one fitted line and two losses. The existing third, wavy surface and optimizer race remain supporting encounters. Learning Adam, momentum and a complete rendering system at once would obscure what a descent step actually does.

Create res://doc/book/studies/ml-gradient/. Copy point_body.gd unchanged from the previous lesson, res://doc/book/studies/ml-environment/. Add the two complete files below. Run the supplied Gradient.tscn: gradient_museum.gd mounts the study in the existing ML_Gradient_Landscape museum hall. Camera, lights, floor and XR rig are supplied. RackTemplates supplies the eight named buttons. The fitting mathematics and the view are printed here; they import no production fitting helper.

## Read the two spaces

On the left, five orange observations sit in an x/y diagram. The turquoise line predicts y = slope * x + intercept. Pink vertical rods join observations to their predictions. Each difference is a **residual**. We take its magnitude in this implementation because both chosen losses are symmetric about zero.

On the right, every place on the surface is another pair of slope/intercept values. Across changes slope; towards you changes intercept. A low place rates that candidate line favourably under the selected loss. These coordinates describe parameters, not the locations of the observations. A line with slope 0.5 and intercept 0.2 passes through all five clean observations.

The surface height uses one fixed linear scale: base 0.9 plus 0.025 times loss. We do not rescale each surface to fill the same height. The sphere's radius is added above the surface. This is calculated placement, not gravity or a rigid body finding a valley. The mesh samples the continuous function on a 24 by 24 grid; its triangles approximate that surface.

## Score a candidate and take one step

MSE averages the squared residuals. Huber with threshold 1 uses half the square for residuals up to 1, then grows linearly. The factor of one half means the two losses have different scales even where they prefer the same line. A smaller displayed number or faster descent is not a fair comparison of their usefulness.

To estimate the gradient, change one parameter by a small h in both directions and compare the losses. Repeat for the other parameter. Divide each difference by 2h. This is a central-difference estimate: four loss evaluations tell us two local rates of change. Subtract rate times that vector to propose the next parameters.

The parameter window is [-3,3] on both axes. Hand placement is bounded to it. An optimizer step outside it is refused and named; it is not silently clamped or accepted as convergence. A small gradient stops the automatic run. In this lesson's convex losses it helps locate a fit; it is not a general proof of a good model or a global optimum on every landscape.

<!-- student-code:line_fit.gd -->
```gdscript
extends RefCounted
## Parameter space: p.x is slope, p.y is intercept, not a physical location.
const START := Vector2(-1.0, 1.0)
const BOUND := 3.0
var data := PackedVector2Array([
    Vector2(-1, -0.3), Vector2(-0.5, -0.05), Vector2(0, 0.2),
    Vector2(0.5, 0.45), Vector2(1, 0.7)])
var p := START
var robust := false
var rate := 0.1
var steps := 0
var status := "PAUSED"

func prediction(q: Vector2, x: float) -> float:
    return q.x * x + q.y

func loss(q: Vector2) -> float:
    var total := 0.0
    for sample in data:
        var e := absf(prediction(q, sample.x) - sample.y)
        total += (0.5*e*e if e <= 1.0 else e-0.5) if robust else e*e
    return total / data.size()

func gradient(q: Vector2, h: float = 0.001) -> Vector2:
    var x := Vector2(h, 0); var y := Vector2(0, h)
    return Vector2(loss(q+x)-loss(q-x), loss(q+y)-loss(q-y)) / (2.0*h)

func reset() -> void:
    p = START; steps = 0; status = "PAUSED"

func set_outlier(enabled: bool) -> void:
    data[4] = Vector2(1, 4.7 if enabled else 0.7)
    reset()

func step() -> bool:
    var g := gradient(p)
    if g.length() < 0.0001:
        status = "SMALL GRADIENT"; return false
    var proposed := p - rate*g
    if not proposed.is_finite() or absf(proposed.x) > BOUND or absf(proposed.y) > BOUND:
        status = "STEP OUTSIDE WINDOW"; return false
    p = proposed; steps += 1; status = "STEPPED"
    return true
```

## Give the line, the loss and the hand one view

Create the point once. Grabbing it pauses descent and reads its position in the study's local frame, even when the museum has rotated the study. Hand height does not alter the parameters. On release the point settles to the calculated height. The other controls wait until you put it down. This is a new use of the same pickable class; its trigger is no longer the population's run/pause control.

MSE and HUBER keep the candidate parameters while changing the score and surface. RESET keeps the current data, loss and rate but returns to (-1,1). OUTLIER toggles only the last observation between (1,0.7) and (1,4.7), then resets the candidate. Nothing is randomly redrawn. SLOW selects rate 0.1; LARGE selects 1.5. STEP pauses and attempts one update. RUN toggles repeated updates, one every 0.15 seconds. That interval controls how quickly we watch; the learning rate controls the parameter change.

A dark backing and unlit control materials keep the diagrams readable under the museum lights. The line and residual rods are redrawn when parameters change; the terrain is rebuilt only when the data or loss changes. While the point is not held, `_physics_process` keeps its position on the calculated surface, including after a paused button edit. This prevents the frozen pickable body's physics state from restoring an older position. PointBody keeps its identity through every operation. The study is session-only: no fit or observations are saved between visits.

<!-- student-code:gradient_study.gd -->
```gdscript
extends Node3D
const Fit = preload("line_fit.gd")
const PointBody = preload("point_body.gd")
const Rack = preload("res://commons/audio/rack_templates/RackTemplates.gd")
var fit := Fit.new()
var point: PointBody
var running := false
var clock := 0.0
var outlier := false
var was_held := false
var terrain := MeshInstance3D.new()
var plot := Node3D.new()
var readout := Label3D.new()

func _ready() -> void:
    add_child(terrain); add_child(plot)
    readout.position = Vector3(0.1, 2.95, -0.7)
    readout.font_size = 28; readout.pixel_size = 0.0025
    add_child(readout)
    var backing := MeshInstance3D.new(); var slab := BoxMesh.new()
    slab.size = Vector3(1.95, 2.4, 0.04); backing.mesh = slab
    backing.position = Vector3(-1.35, 1.65, -0.85)
    backing.material_override = material(Color("161d2b")); add_child(backing)
    label("OBSERVATIONS / x and y", Vector3(-1.35, 2.6, -0.79))
    label("PARAMETERS / slope across, intercept towards you\nHeight = 0.025 x loss; no gravity", Vector3(0.95, 0.65, 0.5))
    point = PointBody.new(); add_child(point)
    var words := ["STEP", "RUN", "RESET", "MSE", "HUBER", "OUTLIER", "SLOW", "LARGE"]
    var rows: Array = []
    for r in 2:
        var row: Array = []
        for c in 4: row.append({"type":"button", "label":words[r*4+c]})
        rows.append(row)
    var panel := Rack.create_panel("FIT ONE LINE", rows)
    panel.position = Vector3(0, 1.05, 1.3); panel.rotation_degrees.x = -30
    panel.scale = Vector3.ONE*2; add_child(panel)
    for mesh in panel.find_children("*", "MeshInstance3D", true, false):
        var m := mesh.material_override as BaseMaterial3D
        if m != null:
            m = m.duplicate(); m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
            mesh.material_override = m
    for i in words.size():
        var button = panel.find_child("Btn_%d" % i, true, false).get_node("InteractableAreaButton")
        button.button_pressed.connect(func(_area):command(words[i]))
    rebuild_surface(); redraw()

func label(text: String, where: Vector3) -> void:
    var node := Label3D.new(); node.text = text; node.position = where
    node.font_size = 22; node.pixel_size = 0.002; add_child(node)

func surface_position(q: Vector2) -> Vector3:
    return Vector3(0.95+q.x*0.26, 0.9+fit.loss(q)*0.025, q.y*0.26)

func plot_position(sample: Vector2) -> Vector3:
    return Vector3(-1.35+sample.x*0.8, 1.65+sample.y*0.18, -0.8)

func material(colour: Color) -> StandardMaterial3D:
    var m := StandardMaterial3D.new(); m.albedo_color = colour
    m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    m.cull_mode = BaseMaterial3D.CULL_DISABLED
    return m

func rod(a: Vector3, b: Vector3, colour: Color, radius: float = 0.009) -> void:
    var d := b-a
    if d.length() < 0.00001: return
    var mesh := CylinderMesh.new(); mesh.top_radius = radius; mesh.bottom_radius = radius
    mesh.height = d.length(); mesh.radial_segments = 8
    var node := MeshInstance3D.new(); node.mesh = mesh; node.position = (a+b)*0.5
    node.quaternion = Quaternion(Vector3.UP, d.normalized())
    node.material_override = material(colour); plot.add_child(node)

func rebuild_surface() -> void:
    var st := SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for z in 24:
        for x in 24:
            for offset: Vector2 in [Vector2(0,0),Vector2(1,0),Vector2(1,1),Vector2(0,0),Vector2(1,1),Vector2(0,1)]:
                var q := Vector2(-3+(x+offset.x)*0.25, -3+(z+offset.y)*0.25)
                st.set_color(Color("57bbc8") if (x+z)%2==0 else Color("326979"))
                st.add_vertex(surface_position(q))
    st.generate_normals(); terrain.mesh = st.commit()
    var m := material(Color.WHITE); m.vertex_color_use_as_albedo = true
    terrain.material_override = m

func redraw() -> void:
    for child in plot.get_children(): plot.remove_child(child); child.queue_free()
    rod(plot_position(Vector2(-1.1,0)), plot_position(Vector2(1.1,0)), Color.GRAY)
    rod(plot_position(Vector2(0,-6)), plot_position(Vector2(0,6)), Color.GRAY)
    rod(plot_position(Vector2(-1,fit.prediction(fit.p,-1))), plot_position(Vector2(1,fit.prediction(fit.p,1))), Color("60e3df"), 0.015)
    for sample in fit.data:
        var mesh := SphereMesh.new(); mesh.radius = 0.028; mesh.height = 0.056
        var node := MeshInstance3D.new(); node.mesh = mesh; node.position = plot_position(sample)
        node.material_override = material(Color("ffbc68")); plot.add_child(node)
        rod(node.position, plot_position(Vector2(sample.x,fit.prediction(fit.p,sample.x))), Color("e26ba2"), 0.006)
    if not point.held(): point.global_position = to_global(surface_position(fit.p)+Vector3.UP*0.085)
    readout.text = "%s / outlier %s / rate %.2f / steps %d\nslope %.3f / intercept %.3f / loss %.4f\n%s" % [
        "HUBER delta 1" if fit.robust else "MSE", outlier, fit.rate, fit.steps,
        fit.p.x, fit.p.y, fit.loss(fit.p), "RUNNING" if running else fit.status]

func command(word: String) -> void:
    if point.held(): return # Put the parameter point down before starting descent.
    var was_running := running
    running = false; clock = 0.0
    match word:
        "STEP": fit.step()
        "RUN": running = not was_running
        "RESET": fit.reset()
        "MSE": fit.robust = false; fit.steps = 0; fit.status = "SAME PARAMETERS"; rebuild_surface()
        "HUBER": fit.robust = true; fit.steps = 0; fit.status = "SAME PARAMETERS"; rebuild_surface()
        "OUTLIER": outlier = not outlier; fit.set_outlier(outlier); rebuild_surface()
        "SLOW": fit.rate = 0.1; fit.status = "RATE CHANGED"
        "LARGE": fit.rate = 1.5; fit.status = "RATE CHANGED"
    redraw()

func _physics_process(_delta: float) -> void:
    if not point.held():
        point.global_position = to_global(surface_position(fit.p)+Vector3.UP*0.085)

func _process(delta: float) -> void:
    if point.held():
        running = false; clock = 0.0; was_held = true
        var hand := to_local(point.global_position)
        fit.p = Vector2(clampf((hand.x-0.95)/0.26,-3,3), clampf(hand.z/0.26,-3,3))
        fit.steps = 0; fit.status = "HAND CHOOSES PARAMETERS"; redraw()
    elif was_held:
        was_held = false; redraw()
    elif running:
        clock += delta
        while clock >= 0.15 and running:
            clock -= 0.15
            running = fit.step()
        redraw()
```

## Predict, run, change one thing

With clean data, MSE and SLOW, RESET and STEP. The initial loss is 1.765. The gradient is approximately (-1.5,1.6), so the next parameters should be (-0.85,0.84). The line should change and its loss decrease. These numbers give you a check independent of whether the animation looks plausible. RUN should approach slope 0.5 and intercept 0.2.

Switch to HUBER without moving the sphere. The line remains the same and its score changes. RESET before comparing two full descents. Add the fixed outlier, then fit each loss from that same start at the slow rate. The least-squares solution is slope 2.1 and intercept 1.0. The Huber fit should lie near slope 1.5 and intercept 0.7. Inspect the residuals: neither result establishes why the unusual observation is present or whether it should count less. These are fits to this small teaching dataset, not evidence of performance on new observations.

For an independent experiment, restore clean data and MSE, select LARGE, RESET and STEP. Predict whether going downhill locally guarantees a better next score. The first large step stays inside the window but increases loss. The next would leave the window and is refused. Lower the rate and reset. A step that is too long and an objective that answers the wrong question are different problems.

Finally move the last observation in code to another x position. Re-run both fits and explain why changing where the residual occurs can change the slope as well as the intercept. Keep the data change separate from a change of loss or rate.

## Return to the surrounding hall

The original comparator uses twenty observations and adds a third rule, sin(3e) + 0.5e². Its label says adversarial; it is not a trained adversarial network. Its surfaces are each normalized for display, while its markers use a separate approximate normalization. Their apparent heights therefore cannot serve as a shared numerical loss scale. The tutorial uses one height formula for the mesh and point instead. The old comparator also uses forward differences and clamps steps; our central differences and refused boundary are declared changes for this reconstruction.

An optimizer race asks how to move under a chosen score. This table first asks what was scored. Evolution made survival depend on resources; here the loss evaluates a prediction and directs a parameter update. Classification next will group observations by distance. Carry the habit of distinguishing observations, parameters, the measure and the procedure that changes them.
