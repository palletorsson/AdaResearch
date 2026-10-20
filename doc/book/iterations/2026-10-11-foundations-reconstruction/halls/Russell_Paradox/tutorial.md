# A demand with no Boolean answer

**Learning elements**

- Membership predicates
- Boolean case analysis
- finite domains
- record versus demand

We leave the surface comparison with a useful habit: state the conditions before trusting the reading. At the existing Russell workbench, use IN and OUT in cell 5, then compare cell 6. Its membership controls are already installed. Our working copy uses the earlier PointBody as the candidate answer. Put it left for OUT, right for IN; release to test the choice. The sphere remains one object. It does not become an actual set containing itself.

The unrestricted demand is `p = not p`. Exhaust its two Boolean inputs. This is a two-case argument, not a search waiting for enough time. Then define the finite ordinal U = n = {0,...,n−1}. The set represented by each x contains precisely the smaller ordinals. None contains itself; filtering all x in U therefore returns U. U is not a member of U. In this restricted example the demand becomes `p = (result is in U) and not p`, with that domain test false. OUT now agrees. This is a finite example of separation, not an implementation of arbitrary set theory.

`members` builds a new array; it is a snapshot. `test` returns the assumption, required answer and agreement separately. No status is silently promoted into a mathematical object. SIZE cycles 1–6; the model also handles the empty ordinal 0, exercised below. DOMAIN preserves the chosen answer so that the rule, rather than the answer, changes in the comparison.

## Continue inside the museum

Use the existing AdaResearch project with Godot 4.6 and its installed XR Tools. Save these files together under `res://doc/book/studies/foundations-lineage/`. Carry `point_body.gd` and `line_skin.gd` unchanged from Euclid / Non-Euclidean Spaces. Their class construction and pickup were already printed there.

Run the supplied `russell.tscn` in that folder with F6. Its `russell_museum.gd` launcher opens **Russell_Paradox** with the existing museum player, room and lighting, then adds your working copy beside the original exhibits. The launcher, `commons/interactables/push_button.tscn` and XR setup are declared infrastructure. No autoload, label, camera or other node is assumed inside your new script: the printed bench creates its own nodes and connects the buttons. This is a session study; it does not replace an installed artifact or carry a live node across hall loads.

The bench synchronizes an unheld frozen sphere on physics ticks. All model positions are local to the unit-scale bench unless a world transform is explicitly passed. Its slab and thin-cylinder lines are visual guides, not a new walkable floor. Use the museum's existing locomotion and pointer/grab controls.

## Complete new files

Read the rule first, then its museum display. There is one `_ready` per script; inherited `start` constructs the bench once. Save each block as the filename above it.

### `membership.gd`

<!-- student-code:membership.gd -->
```gdscript
extends RefCounted
# n represents the finite ordinal {0,...,n-1}. This is not a universal set.
func members(n: int) -> Array[int]:
    var result: Array[int] = []
    for x in range(maxi(0, n)):
        if not range(x).has(x): result.append(x)
    return result

func test(assumed: bool, restricted: bool, n: int = 4) -> Dictionary:
    if n < 0 or n > 6: return {"valid":false}
    var selected := members(n)
    # Every ordinal below n survives. The result equals ordinal n, outside n.
    var in_domain := range(n).has(n) if restricted else true
    var required := in_domain and not assumed
    return {"valid":true, "assumed":assumed, "required":required,
        "agrees":assumed==required, "members":selected,
        "domain_contains_result":in_domain, "restricted":restricted}
```

### `bench.gd`

<!-- student-code:bench.gd -->
```gdscript
extends Node3D
const PointBody = preload("point_body.gd")
const LineSkin = preload("line_skin.gd")
const PushButton = preload("res://commons/interactables/push_button.tscn")
var drawing := Node3D.new()
var point
var point_home := Vector3(0, 1.1, 0)
var readout: Label3D
var buttons: Array = []

func start(title: String, words: Array, actions: Array) -> void:
    block(self, Vector3(0, 0.94, 0), Vector3(2.8, 0.08, 1.9), Color("d3ccc1"))
    block(self, Vector3(0, 1.94, -0.85), Vector3(2.9, 0.72, 0.04), Color("182330"))
    label(self, title, Vector3(0, 2.17, -0.8), 27)
    readout = label(self, "", Vector3(0, 1.9, -0.8), 22)
    add_child(drawing)
    point = PointBody.new()
    point.name = "CarriedPoint"
    point.tint = Color("e8c18c")
    add_child(point)
    for i in words.size():
        var button = PushButton.instantiate()
        button.name = "Action%d" % i
        button.position = Vector3((i-(words.size()-1)*0.5)*0.48, 1.02, 0.77)
        add_child(button)
        button.pressed.connect(actions[i])
        buttons.append(button)
        label(self, words[i], button.position+Vector3(0, 0.12, 0), 18)

func _physics_process(_delta: float) -> void:
    if point != null and not point.held(): point.position = point_home

func clear_drawing() -> void:
    for child in drawing.get_children(): child.free()

func block(parent: Node, at: Vector3, size: Vector3, colour: Color) -> MeshInstance3D:
    var body := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = size
    body.mesh = box
    var material := StandardMaterial3D.new()
    material.albedo_color = colour
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    body.material_override = material
    body.position = at
    parent.add_child(body)
    return body

func label(parent: Node, words: String, at: Vector3, size: int = 22) -> Label3D:
    var text := Label3D.new()
    text.text = words
    text.position = at
    text.font_size = size
    text.pixel_size = 0.0018
    text.outline_size = 5
    text.outline_modulate = Color("182330")
    parent.add_child(text)
    return text

func segment(a: Vector3, b: Vector3) -> void:
    var line := LineSkin.new()
    drawing.add_child(line)
    line.show_segment(a, b-a, a.distance_to(b))
```

### `russell_study.gd`

<!-- student-code:russell_study.gd -->
```gdscript
extends "bench.gd"
const Membership = preload("membership.gd")
var model := Membership.new()
var restricted := false
var size := 4
var assumed := false
var was_held := false
var held_x := 0.0
var result: Dictionary = {}

func _ready() -> void:
    start("RUSSELL / TEST THE DEMAND", ["OUT", "IN", "DOMAIN", "SIZE"],
        [choose.bind(false), choose.bind(true), domain, next_size])
    refresh()

func choose(value: bool) -> void:
    if point.held(): return
    assumed = value
    refresh()

func domain() -> void:
    if point.held(): return
    restricted = not restricted
    refresh()

func next_size() -> void:
    if point.held(): return
    size = size % 6 + 1
    refresh()

func _process(_delta: float) -> void:
    if point.held():
        was_held = true
        held_x = to_local(point.global_position).x
    elif was_held:
        was_held = false
        choose(held_x >= 0)

func refresh() -> void:
    result = model.test(assumed, restricted, size)
    point_home = Vector3(0.65 if assumed else -0.65, 1.23, 0.25)
    clear_drawing()
    for i in 2:
        var x := -0.65 if i==0 else 0.65
        block(drawing, Vector3(x, 1.01, 0.25), Vector3(0.75, 0.04, 0.42), Color("30465b"))
        label(drawing, "OUT" if i==0 else "IN", Vector3(x, 1.08, 0.48))
    if restricted:
        for x in result.members:
            var at := Vector3((x-(size-1)*0.5)*0.3, 1.04, -0.38)
            block(drawing, at, Vector3.ONE*0.12, Color("99bbc7"))
            label(drawing, str(x), at+Vector3.UP*0.18)
    readout.text = "%s\nChoose %s; rule requires %s. %s\n%s" % [
        "WITHIN U = %s"%str(result.members) if restricted else "UNRESTRICTED: p = not p",
        "IN" if assumed else "OUT", "IN" if result.required else "OUT",
        "AGREES" if result.agrees else "DISAGREES",
        "Result = %d; it is outside U."%size if restricted else "Test both Booleans. No fixed answer."]
```

## Predict, build, check

Predict all four cases before running: unrestricted IN and OUT both disagree; restricted IN disagrees and OUT agrees. Set n to 2, then 6: the displayed members change, but the result remains outside its domain. Test n = 0 in code: empty U gives empty result, still not a member of itself. Explain why this is not a repair that makes the original unrestricted condition true.

For the hand test, rotate and translate the study node. Right/left are measured in its local frame using `to_local`. The last held coordinate is retained before release, avoiding a physics tick returning the body to its old slot before the choice is read. While held, buttons refuse edits. The inherited frozen PointBody supplies pickup/release; the new lesson supplies the membership rule.

Carry the distinction between an inconsistent demand and a calculation that has not returned. Gödel's lesson will need it.

The automated reconstruction tests extract the printed files, add only these declared carried dependencies and run native Godot assertions. They use synthetic interaction. They do not establish human learning or headset reach.
