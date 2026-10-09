# Colour at a receiving surface

This is the second Colour room. It follows Color_Context_Placed and prepares Color_Nails. Keep two variables distinct: the light's colour and the receiving material's base colour.

## Repeat the comparison

Hold a coloured lamp, aim it away from the board, then bring it back across another beam. Release it; the pickable is configured to remain frozen in place when released. Compare separate pools with their overlap. White begins aimed aside so it does not obscure the first RGB comparison. Bring it onto the board as another contribution.

There is no on/off control or hue picker in this encounter. Moving and aiming the lamps are the controls. Other museum illumination remains present.

## Trace the implementation

The map places this token at grid (9,9):

```text
flashlight_demo:180:0:1#plinth:0#mount:standing#receiver_sides:7
```

The registry resolves `flashlight_demo` to `res://algorithms/postprocessing/flashlight_demo/flashlight_demo.tscn`. That scene instances `flashlight.tscn` four times. Each copy inherits XRTools' pickable scene and contains a spotlight and a `ColorSetter` child running `flashlight_color.gd`.

The colour assignment is actual source:

```gdscript
var spot = _find_spot_light(target_root)
if spot:
    spot.light_color = light_color
```

Red, green, blue and white instances supply `Color(1,0,0,1)`, `Color(0,1,0,1)`, `Color(0,0,1,1)` and `Color(1,1,1,1)`. Lens tint and emission are set separately so the handle's lens identifies the beam. They do not recolour the board.

The receiving `Canvas` is a 6 × 4 × 0.1 metre CSG box. Its material has albedo `(0.95, 0.95, 0.95, 1)` and roughness `0.9`. The lamps have a 25-degree spotlight angle, range 20 metres and shadows enabled. Direction, distance, material and other scene lighting contribute to the rendered result; pixel values should not be equated directly with the exported RGB value.

## Standing installation

The optional `mount:standing` metadata is read by `flashlight_demo.gd` before it stages the receiving surface. It places the board centre at local y=2, enables board collision, and puts each handle at y=1.1. Lamp energy is 2.5 in this installation; white begins turned 60 degrees aside. The map places the root at museum floor level. Legacy placements retain their previous mounting.

The separate `ground` authoring option supports `white`, `swatch`, `relief`, `mirror` and `none`. This room uses `white`. These are authoring configurations, not controls offered to the visitor. In particular, the option called `mirror` changes material properties; it does not install the project's player-reflection system.

## What has been checked

`commons/testing/probe_flashlight_lesson.gd` loads the actual endless museum, checks placement, floor and lamp heights, exercises XRTools pickup/release using a supplied moving grabber, and compares rendered light contributions against an unchanged receiving material. Its lamp-visibility toggles are test isolation only. A separate test aims a held lamp aside and back, matching the book's gesture.

See `field_notes.md` for the recorded run. Tracked controllers, headset comfort and frame-rate performance are not established by this desktop test.

Carry the distinction into Color_Nails: a change of illumination differs from assigning colour to the material of a preview or tracked hand.

## Faceted receiver — 23 September 2026

The standing installation can opt into `receiver_sides:5` or `receiver_sides:7`; the default zero adds nothing. Color_Flashlight selects seven. The numeric key is registered in `GridInteractablesComponent.CONFIG_PARAM_NAMES` so it cannot be misread as a tutorial rotation. The root retains its authored 180-degree yaw.

The new receiver is at local (-5.6, 0, -1), opposite the existing cube. A 0.65-metre pedestal carries a sphere of radius 0.85 metres, centred 1.5 metres above the floor. It uses Godot SphereMesh with seven radial divisions and three rings, converted to flat-shaded triangles. Degenerate pole triangles are omitted; the final mesh has 42 triangles. Seven is not its total face count. A triangle-mesh static collider follows the visible surface. Both board and sphere use the same near-white matte, nonemissive material; no emissive wire overlay masks the lamp response.

The focused probe and native captures are in `doc/book/iterations/2026-09-23-flashlight-faceted-sphere/`. Forty-three checks pass in the isolated production museum: authored placement/yaw, outward flat normals, collider, supporting floor and three standing-body clearances, pickup/movement/release of all four lamps, and changed rendered red contribution on the unchanged sphere when a held lamp moves sides. All four lights remain on; no lamp toggle is introduced. Five-division authoring and legacy mounting are also checked. The book figure crops and labels two native renders from the same camera.

These supplied-grabber desktop checks do not establish tracked-controller reach, headset comfort, a complete walk around the pedestal or Quest performance.
