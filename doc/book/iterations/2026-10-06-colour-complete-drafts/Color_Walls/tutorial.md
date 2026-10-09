# Walls — a view through two colours

**Learning elements**

- Alpha and the material's transparency mode
- Independent palettes and materials
- Rendered appearance beside a persistent collider
- Position and rotation changing the overlap of coloured surfaces

Walk beside the museum's coloured partitions. Two panes overlap from one place, then separate as you move. A view changes without either wall moving. Try to pass through one: being able to see through it has not made a passage.

Transformation supplied position and rotation. Grid gave each Palette its own remembered index. Bring both back. We will give two panes independent colours and switch their appearance between translucent and opaque.

## Two surfaces, two choices

Keep `palette.gd` from Grid unchanged. Save it beside `lesson.gd`, `pane.gd` and `controls.gd` below. Attach `lesson.gd` to a Node3D at floor level in an open patch of your working Walls hall. Keep unit scale. Approach from positive local Z. The museum supplies the view, movement, light and surrounding architecture.

`Pane` makes one 2 by 2.5 metre sheet and one thin box collider. The two panes are offset and the second is turned by 15 degrees. Each has its own material and Palette. This reconstructs a small part of the installed office's larger composition.

## The complete continuation — lesson.gd

<!-- student-code:lesson.gd -->
```gdscript
extends Node3D

const Palette = preload("palette.gd")
const Pane = preload("pane.gd")
const Controls = preload("controls.gd")

var filter_mode := true
var opacity := 0.52
var positions: Array[Vector3] = [Vector3(-0.4, 1.25, 0), Vector3(0.4, 1.25, -0.8)]
var turns: Array[float] = [0.0, 15.0]
var palettes: Array = []
var panes: Array[StaticBody3D] = []

func _ready() -> void:
    palettes = [
        Palette.new([Color(0.2, 0.9, 0.9), Color(1, 0.8, 0.15)]),
        Palette.new([Color(0.8, 0.2, 0.6), Color(0.15, 0.55, 0.9)])
    ]
    for i in range(positions.size()):
        var pane := Pane.new()
        pane.position = positions[i]
        pane.rotation_degrees.y = turns[i]
        add_child(pane)
        panes.append(pane)
    add_child(Controls.new())
    apply_colours()

func surface_colour(colour: Color, filtered: bool) -> Color:
    colour.a = clampf(opacity, 0, 1) if filtered else 1.0
    return colour

func apply_colours() -> void:
    for i in range(panes.size()):
        var material: StandardMaterial3D = panes[i].surface
        material.albedo_color = surface_colour(palettes[i].current_colour(), filter_mode)
        material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA if filter_mode else BaseMaterial3D.TRANSPARENCY_DISABLED

func toggle_filter() -> void:
    filter_mode = not filter_mode
    apply_colours()

func change_first() -> void:
    palettes[0].next_colour()
    apply_colours()
```

Run. Press **F** to switch between filter and opaque modes. Press **C** to advance the first pane's palette. Move sideways to change which parts overlap. The second pane's colour should remain unchanged when you advance the first.

`surface_colour` takes a Color value and returns one with an assigned alpha. It preserves RGB. In filter mode it bounds `opacity` to 0–1; opaque mode uses one. Because Color is a value, this local change does not alter the stored palette entry.

The material also needs the matching transparency mode. Alpha alone is insufficient when the material is configured to render as opaque. `apply_colours` sets both properties. It never moves a pane, resizes its collider or changes collision layers.

## Separate what changes

Set `opacity` to 0.2 and run. More of the view behind the sheet contributes to the composite. Then try 1.0. Switch with F: at full alpha the visible difference may disappear even though the selected mode changes. In both cases the same collider remains.

Restore 0.52. Change only the second value in `turns` from 15 to 45 degrees. The overlap changes through geometry. Change only a palette entry: its colour changes through material state. These are different ways to compose with the same panes.

For your own continuation, arrange the two panes so one chosen view has a large overlap and a nearby view has none. Keep both palettes independently changeable. Explain which values you changed and why the route around the panes remains open while the panes themselves still block passage.

This is ordinary alpha compositing, not spectral transmission through glass. It depends on the colours and order of rendered surfaces and on the view behind them. It does not guarantee physically accurate mixing. The unshaded sheets make those assigned colours easier to inspect; they do not illuminate the room.

## Supplied pane — pane.gd

<!-- student-code:pane.gd -->
```gdscript
# Supplied pane: one rendered sheet, one persistent physical boundary.
extends StaticBody3D

var surface: StandardMaterial3D
var boundary: CollisionShape3D

func _ready() -> void:
    var view := MeshInstance3D.new()
    var sheet := QuadMesh.new()
    sheet.size = Vector2(2, 2.5)
    view.mesh = sheet
    surface = StandardMaterial3D.new()
    surface.cull_mode = BaseMaterial3D.CULL_DISABLED
    surface.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    view.material_override = surface
    add_child(view)
    boundary = CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = Vector3(2, 2.5, 0.04)
    boundary.shape = shape
    add_child(boundary)
```

The sheet and boundary are separate children of one body. The boundary's size stays `(2, 2.5, 0.04)` in both modes. Disabling it would be a different operation with a different effect on movement.

## Inherited palette — palette.gd

<!-- student-code:palette.gd -->
```gdscript
extends RefCounted

var colours: Array[Color] = []
var index := 0

func _init(choices: Array[Color]) -> void:
    assert(not choices.is_empty())
    colours.assign(choices)

func current_colour() -> Color:
    return colours[index]

func next_colour() -> Color:
    index = (index + 1) % colours.size()
    return current_colour()
```

## Supplied controls — controls.gd

<!-- student-code:controls.gd -->
```gdscript
# Supplied desktop test adapter; these methods can also receive museum buttons.
extends Node

func _unhandled_key_input(event: InputEvent) -> void:
    if not event is InputEventKey or not event.pressed or event.echo:
        return
    if event.keycode == KEY_F:
        get_parent().toggle_filter()
    elif event.keycode == KEY_C:
        get_parent().change_first()
```

Keep the distinction at the end of Colour: a choice can change a surface, a light, a stored address or the composite seen through several layers. State where the colour is held and which operation receives it. The same three channel values do not make those operations interchangeable.
