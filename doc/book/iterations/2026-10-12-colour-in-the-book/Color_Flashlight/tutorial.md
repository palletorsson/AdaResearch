# Flashlight — keep the surface

**Learning elements**

- Light colour and material colour
- A spotlight's position, direction and cone
- A local target used by `look_at`
- Comparing separate and overlapping contributions

Take one of the coloured lamps in the museum. Aim it across the pale board, then turn it aside. The patch leaves. The board has kept its material.

In the previous hall, we assigned colours to independent surfaces. Here we keep one surface colour and change a light. The room's handles already let you do this by hand. Our small program reconstructs the light-to-surface relation; we use source edits to hold and compare particular states.

## A familiar box receives light

Work in the existing `Color_Flashlight` hall. Attach this complete `lesson.gd` to an empty `Node3D` named `LightStudy` on clear floor, with unit scale and local Y upright. Allow about five metres across X and three metres along positive Z. Stand on the positive-Z side of the board. The museum supplies your camera, movement, room and existing illumination.

The board is the `BoxMesh` we already know, made wide and shallow. Its material construction returns from the first Colour lesson. The new objects are two `SpotLight3D` nodes, each aimed at a point on the board. They have no visible handles or pickup bodies in this reduced study; the installed lamps provide that wider interaction. No child nodes, scene paths or helper files are required by this script.

<!-- student-code:lesson.gd -->
```gdscript
# Keep the board's material; change one light's colour or aim.
extends Node3D

var beam_colour := Color(1, 0, 0)
var first_target := Vector3(-1, 1.5, 0)
var board: MeshInstance3D
var surface: StandardMaterial3D
var first_light: SpotLight3D
var second_light: SpotLight3D

func _ready() -> void:
    board = MeshInstance3D.new()
    var shape := BoxMesh.new()
    shape.size = Vector3(4.4, 2.4, 0.12)
    board.mesh = shape
    board.position = Vector3(0, 1.5, 0)
    surface = StandardMaterial3D.new()
    surface.albedo_color = Color(0.9, 0.9, 0.9)
    surface.roughness = 1.0
    board.material_override = surface
    add_child(board)

    first_light = make_light(beam_colour, Vector3(-1, 1.5, 2.5), first_target)
    second_light = make_light(Color(0, 1, 0), Vector3(1, 1.5, 2.5), Vector3(1, 1.5, 0))

func make_light(colour: Color, at: Vector3, target: Vector3) -> SpotLight3D:
    var lamp := SpotLight3D.new()
    lamp.light_color = colour
    lamp.light_energy = 2.5
    lamp.spot_range = 6.0
    lamp.spot_angle = 18.0
    lamp.shadow_enabled = true
    lamp.position = at
    add_child(lamp)
    lamp.look_at(to_global(target))
    return lamp
```

## Which object receives the value?

Run the study. The first lamp makes a red pool on the left; the second makes a green pool on the right. Their positions, ranges and angles are fixed. The board receives both lights wherever their cones reach it.

Last time, `material.albedo_color` changed a surface's base colour. Here, `lamp.light_color` changes a light's RGB contribution. Both accept a `Color`, but they belong to different objects and affect the scene differently. Our surface keeps `Color(0.9, 0.9, 0.9)` throughout this lesson.

Change `beam_colour` to `Color(0, 0, 1)` and run again. The left pool becomes blue. The right lamp stays green, and the board's stored material is unchanged. Keep your viewpoint while comparing the two runs.

Other museum lights still contribute. The pool's edge may make the change easier to see than its brightest centre. The assigned RGB value is not a promise that every receiving pixel will display those same three numbers.

## Aim is a transformation

Restore `beam_colour` to `Color(1, 0, 0)`. Change `first_target` to `Vector3(1, 1.5, 0)` and run again. The first lamp now points towards the second lamp's target. Look where red and green meet. Their contributions can produce a yellow region on this pale surface. Neither lamp has been assigned yellow, and no yellow has been written into the board's material.

`make_light` creates a light, adds it to the study and returns its reference. The two variables keep different lights. Their `light_energy`, `spot_range` and `spot_angle` are held fixed so that colour and aim are the choices we compare. Range limits how far the light reaches; angle sets the cone's spread.

A spotlight shines along its local negative-Z direction. `look_at` turns that direction towards a world-space target. Our target is written in the study's local coordinates, so `to_global(target)` converts it before the call. This is the local/world distinction from Point Coordinates doing another job. Placing the study elsewhere in the museum should not make its light aim at an unrelated world origin.

The lamp must already be in the scene tree for this global aiming operation. That is why `add_child(lamp)` comes before `look_at`. This call turns the lamp; it does not move the lamp to the target. In the installed exhibit, turning the grabbable handle turns its child light instead.

## Withdraw one contribution

Keep the first lamp red. Change `first_target` to `Vector3(-1, 1.5, 5)` and run again. This target is behind the lamp, on the positive-Z side. The red cone points away from the board. The green pool remains. The board may still be visible under the room's other lights.

We have not switched off the first lamp: its colour, energy and position remain the same. We have changed where it points. Separating colour from aim lets us name which condition changed.

## Make another comparison

Choose another target on the board: keep X between -2 and 2, Y between 0.4 and 2.6, and Z at zero. Predict which way the first light must turn. Keep its colour and the second lamp fixed, then run your choice. Find what changed without attributing it to a new surface colour.

Keep the references `first_light` and `surface`, and the distinction between their colour properties. Our edits are applied in `_ready`; later controls could write to those same objects while the scene runs. This lesson does not add a colour picker to the museum's handles.

Back at the installed exhibit, carry a beam across the coarse sphere. Its faces meet the light in different directions. The side rooms then hold their lamps still while colour changes with time. Those encounters develop the comparison further. We have reconstructed its smallest working relation: a known surface, a light, and an aim.

In Nails, a hand position will choose a colour for a surface again. Keep asking where the value is written, and what else participates in its appearance.
