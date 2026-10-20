# The set before the choice

## Learning elements

- Eligibility: a condition defines the possible choices.
- Candidate lists: a list offset refers to a stored grid address.
- Sampling without replacement: remove the chosen address from the list.
- Empty-set guard: stop before requesting an invalid draw.
- Replay: restore both the candidates and the generator.

## Start in the museum

Find the eight-by-eight removal board. Sixteen cubes are amber and forty-eight are grey. Before pressing REMOVE ONE, point to a cube that cannot be chosen. Then empty the amber square. Its final outline was fixed before the first draw; the order was not visible yet.

We return to the cube grid from Random Definition and the array work from Random Entropy. There, sorting preserved every member. Here, a choice changes what can be chosen next. The PointBody is the same class used in those lessons. We reuse its construction and trigger action; we do not import the previous hall's sample or pretend that a new node is the object carried through a portal.

The student study is one small board. The hoppers and walkable removal floor remain other encounters in this hall. They do not require two more implementations in this lesson.

The installed crossing applies the same shrinking-list operation to 165 physical tiles, arranged 15 by 11. A coil above the selected tile charges during the red warning, then strikes as that tile's collision is disabled. The entrance panel has SLOWER / FASTER controls, from 0.5× to 8×, starting at 3×. At 1× the warning is 0.8 seconds, the walking interval is 0.6 metres, and a separate seeded timer waits 1.5–3 seconds between completed warnings while a visitor remains inside. Divide all three by the selected speed: at the default 3×, the warning is about 0.27 seconds, walking another 0.2 metres can request a removal, and waits are 0.5–1 second. Requests only act when the remover is free.

Changing speed does not draw another random value or change the tile order. It rescales the remaining wait; a warning already underway completes at its original duration, and subsequent warnings use the new speed. REPLAY restores the full set and both generators while retaining the selected speed. Compare 1× and 3× at the same seed: does the same sequence of losses become a different crossing? The timing generator and lightning drawing do not consume the tile-selection generator. The permanent banks are at the two ends; there is no side walkway around the field.

## Make the small version

Use your prepared Endless Museum project with XR Tools installed. Save `03_eligible_addresses.gd` beside the existing `point_body.gd`. Add an empty Node3D named `RemovalStudy` under the Random Remove hall and attach the first script. Use hall-local position `(13.2, 0, 8)` and Y rotation `-90` degrees. The museum supplies the floor, player, camera and light. The script builds every cube, slot, label and the familiar point; no prepared mesh children are needed.

This study hides display cubes immediately. Its visual plinth has no collider; the museum floor still supports the player. The installed board has a brief red warning, while the arena also removes collision. Those are additional behaviours, not hidden parts of this listing. Keep this reconstruction separate from the existing exhibits.

The board stays eight by eight here so the new subject is eligibility. Random Definition's resolution slider is not needed to explain removal. Hold the point above a label and press the trigger: left resets, middle removes one, right increments the seed and resets. The positions are local to the study, so turning the whole board does not exchange its controls. Only the point's local x position chooses the action.

### `03_eligible_addresses.gd`

Read `eligible()` and `remove_one()` first: one builds the available set; the other selects and removes a member.

<!-- student-code:03_eligible_addresses.gd -->
```gdscript
extends Node3D

const PointBody = preload("point_body.gd")
const AMBER := Color(1.0, 0.68, 0.18)
const GREY := Color(0.28, 0.35, 0.42)
@export var side := 8
@export var seed_value := 42
var rng := RandomNumberGenerator.new()
var candidates: Array[int] = []
var history: Array[int] = []
var cubes: Array[MeshInstance3D] = []
var slots: Array[MeshInstance3D] = []
var point: RigidBody3D
var status: Label3D
var last_offset := -1
var last_address := -1

func text_at(words: String, at: Vector3, size: int = 26) -> Label3D:
    var text := Label3D.new()
    text.text = words
    text.position = at
    text.font_size = size
    text.pixel_size = 0.0025
    add_child(text)
    return text

func box_at(at: Vector3, size: Vector3, colour: Color) -> MeshInstance3D:
    var cube := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    cube.mesh = mesh
    var material := StandardMaterial3D.new()
    material.albedo_color = colour
    cube.material_override = material
    cube.position = at
    add_child(cube)
    return cube

func _ready() -> void:
    assert(side >= 2 and side <= 16)
    var pitch := 2.0 / side
    for row in range(side):
        for column in range(side):
            var at := Vector3((column + 0.5) * pitch - 1.0, 0.976 + pitch * 0.36,
                (row + 0.5) * pitch - 1.0)
            cubes.append(box_at(at, Vector3.ONE * pitch * 0.72, GREY))
            slots.append(box_at(Vector3(at.x, 0.96, at.z),
                Vector3(pitch * 0.88, 0.015, pitch * 0.88), Color(0.65, 0.65, 0.65)))
    for i in range(side):
        var across := (i + 0.5) * pitch - 1.0
        var column_label := text_at(str(i), Vector3(across, 0.99, 1.12), 20)
        column_label.rotation_degrees.x = -90
        var row_label := text_at(str(i), Vector3(-1.12, 0.99, across), 20)
        row_label.rotation_degrees.x = -90
    box_at(Vector3(0, 0.47, 0), Vector3(2.4, 0.93, 2.4), Color(0.09, 0.1, 0.12))
    status = text_at("", Vector3(0, 1.9, -1.0), 26)
    point = PointBody.new()
    point.position = Vector3(0, 1.1, 1.45)
    add_child(point)
    var ink := StandardMaterial3D.new()
    ink.albedo_color = Color(0.04, 0.04, 0.045)
    ink.roughness = 0.2
    point.get_child(0).material_override = ink
    point.action_pressed.connect(activate)
    text_at("RESET", Vector3(-0.9, 0.65, 1.45))
    text_at("REMOVE ONE", Vector3(0, 0.65, 1.45))
    text_at("NEXT SEED", Vector3(0.9, 0.65, 1.45))
    text_at("Hold point above a label; press trigger", Vector3(0, 0.38, 1.45), 22)
    reset_run()

func eligible(column: int, row: int) -> bool:
    return column >= 2 and column <= 5 and row >= 2 and row <= 5

func reset_run() -> void:
    rng.seed = seed_value
    candidates.clear()
    history.clear()
    last_offset = -1
    last_address = -1
    for address in range(cubes.size()):
        var column := address % side
        var row := floori(float(address) / side)
        var allowed := eligible(column, row)
        cubes[address].visible = true
        cubes[address].material_override.albedo_color = AMBER if allowed else GREY
        if allowed:
            candidates.append(address)
    show_status()

func remove_one() -> int:
    if candidates.is_empty():
        return -1
    last_offset = rng.randi_range(0, candidates.size() - 1)
    last_address = candidates[last_offset]
    cubes[last_address].visible = false
    candidates.remove_at(last_offset)
    history.append(last_address)
    show_status()
    return last_address

func show_status() -> void:
    status.text = "Seed %d | eligible at start %d\nRemaining %d | removed %d" % [
        seed_value, candidates.size() + history.size(), candidates.size(), history.size()]
    if last_address >= 0:
        status.text += "\nOffset %d chose address %d (column %d, row %d)" % [
            last_offset, last_address, last_address % side, floori(float(last_address) / side)]
    if candidates.is_empty():
        status.text += "\nNo eligible cubes remain. RESET restores the set."

func activate(_body: Variant = null) -> void:
    if point.position.x > 0.4:
        seed_value += 1
        reset_run()
    elif point.position.x >= -0.4:
        remove_one()
    else:
        reset_run()
```

### `point_body.gd` — unchanged

Keep your existing file if you have it. This is the complete dependency for a reader joining here; its geometry and pickup behaviour are not another task to rebuild.

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

## Follow one removal

`eligible()` is a question with a Boolean answer. It admits columns 2–5 and rows 2–5, including both ends. This is where you decide the set. Moving the pedestal does not change the column and row stored for a cube.

The nested construction loops store the cubes row by row. A cell's address is `row * side + column`. With eight columns, column 2 in row 2 has address 18. `address % side` recovers its column; division rounded down recovers its row. This is the grid addressing learned earlier, now used to keep track of an absence.

`reset_run()` visits all 64 addresses and collects the sixteen allowed ones. The candidate list begins `[18, 19, 20, 21, 26, …]`. **Offset 0 in that list means address 18 in the cube array.** These are two different indices. After a removal, list offsets shift; grid addresses keep their meanings.

`remove_one()` first checks whether the list is empty. If so, it returns `-1` without requesting randomness. Otherwise it draws an offset into the current list, looks up the address, hides that cube, and removes the offset from the candidate list. The return value is the removed address; `-1` means that no removal happened.

We leave `cubes` and `slots` intact. Hiding a cube changes its visibility, not its array address, and the slot remains visible underneath. `history` appends the removed addresses in order. Removing from `candidates` is what makes this sampling **without replacement**. Merely hiding a cube would still allow it to be chosen again.

The next draw is uniform over the remaining candidate offsets. No grey cube can be drawn. The condition governs eligibility; the random request chooses within it. In the previous hall a measurement ignored the arrangement. Here, counting sixteen candidates alone does not tell us which sixteen positions they occupy.

## Predict, change, check

First predict the original version: sixteen successful removals, no repeated address, forty-eight grey cubes still visible. A seventeenth press must do nothing. Save the first few addresses on paper, reset, and compare them. The same seed, candidate order and requests reproduce the order; waiting between presses makes no requests.

Now change only the return line in `eligible()` to `return (column + row) % 2 == 0`. Predict the count before running: half of an eight-by-eight board, thirty-two cubes. Remove them all. Every removed address must belong to that checkerboard, and no excluded cube should disappear. This changes the eligible shape without changing the selection algorithm.

Next use `return row == 3`, then `return column == 3`. Each offers eight choices. Keep the same seed and compare the complete orders. A draw at column 5, row 3 in the first becomes column 3, row 5 in the second: equal list lengths and ordering give corresponding offsets. The spatial meanings differ.

Finally use `return false`. The board must open with no eligible cubes, show that it is empty, and accept repeated trigger presses without an error. RESET should preserve that empty rule. An empty selection is a valid outcome; it is not permission to select from all cubes instead.

Restore the range rule when finished. Change `seed_value` or use NEXT SEED to compare orders, but do not require two seeds to produce different results. Replay is a claim you can test; guaranteed novelty is not.

## What travels onward

Keep the grid, the local generator and the distinction between a rule and a draw. The next hall, 10 PRINT, gives each cell two possible diagonals. Here a draw withdrew a member; there it will assign a mark whose neighbours help make a pattern.
