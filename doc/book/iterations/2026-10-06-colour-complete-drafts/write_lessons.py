"""Authoring source for the five review drafts; inserts the exact local scripts."""
from pathlib import Path

HERE = Path(__file__).resolve().parent

LESSONS = {
'Color_Rainbow': '''# Rainbow — keep the opening

**Learning elements**

- A palette as an ordered list of colours
- An index connecting a colour to a band
- Dividing a fixed extent among a changing number of parts

Walk through the museum's arches. Their arrangements differ, but each leaves an opening for a body. In Nails you chose a colour with a point. Here a colour joins a list, and the list changes the division of an arch.

This is a short, optional making lesson. The celebration, pickups and banner belong to the installed encounter. We will make one small arch to examine how its parts share an extent.

## Bring a chosen colour

Copy the RGB value you recorded in Nails into the first entry of `palette`. The starting example uses `Color(0.8, 0.2, 0.6)`. This is a deliberate transfer of a recorded value; the script does not retrieve it from the preceding hall.

Save `lesson.gd` and the supplied `arc_strip.gd` together. Attach `lesson.gd` to a Node3D in your working copy of the Rainbow hall, with its origin at the centre of an open display surface. Keep unit scale. The museum supplies the camera, light and player. This small arch stands in the local XY plane and has no collider.

`ArcStrip` builds one coloured semicircular band between two radii. Its complete implementation is printed below. Mesh construction returns from Primitives; the new decision here is how many bands share the available thickness.

## The complete study — lesson.gd

{lesson.gd}

Run it. Three bands surround the same opening. The innermost radius is 0.7 metres; the outermost radius is 1.3 metres. `TOTAL_THICKNESS` is the radial thickness of all the bands together, not the diameter of the whole arch.

`palette.size()` is the number of entries. Dividing 0.6 by three gives each band a width of 0.2. The loop visits each index `i`: it advances that band's inner radius by `i * width`, then uses `palette[i]` for its colour. Each outer radius meets the next inner radius.

The assertion requires a nonempty palette. We cannot divide the thickness among zero bands. Every nonempty palette keeps the same inner and outer boundaries; only their internal division changes.

## Change the division

Replace the three-entry palette with `[Color(0.8, 0.2, 0.6), Color.WHITE]`. Predict the width, then run. Each band is 0.3 metres thick. Restore the original palette and append `Color.BLACK`: four bands now share the same 0.6 metres, each taking 0.15.

Change one colour without adding or removing an entry. The geometry should stay still. Band count and colour assignment are separate decisions. This example couples them by making one band per palette entry. Another arrangement could repeat two colours across six bands; the number of available colours would then differ from the number of parts, as it did in the opening Colour lesson.

Choose your own nonempty palette. Before running, state how many bands will appear, their individual width, and the outer radius. As a boundary case, use one colour: it occupies the full thickness without closing the opening.

The museum's arches are larger and use their own palettes and arrangement. This study retains their fixed-extent construction. Its colours are assigned surface values; it does not simulate wavelengths or the optics of a rainbow.

## Supplied band builder — arc_strip.gd

{arc_strip.gd}

The builder samples a semicircle, storing an inner and an outer vertex at each angle. Two triangles join each neighbouring pair. The material is independent for each band and unshaded so the palette remains easy to compare. Changing the palette does not change this renderer.

Keep the chosen list. Pillar will ask how a function can produce colours between selected values, instead of choosing only among entries.
''',
'Color_Pillar': '''# Pillar — colour has a height

**Learning elements**

- Hue, saturation and value as a coordinate model
- A function returning a colour from a position
- Mapping a reachable height to a taller field
- Distinguishing a colour value from illumination

Stand among the museum's columns. Colour rises towards the ceiling; near their tops, a column and its surrounding colour can become hard to separate. The dark floor gives that ascent a beginning.

Return to the point from Nails. Its position still supplies three numbers, but the numbers now control hue, saturation and value. Y becomes a way to move from dark to light while X and Z stay still.

## Continue with PointBody

Keep the unchanged `point_body.gd` from Lines, Coordinates and Nails. Save `lesson.gd` beside it. Attach the script to a Node3D in your working copy of the Pillar hall. Its local origin is the floor-level corner of a 12.8 by 19.2 metre colour field, with X across and Z along the field. Keep the study and its parents at unit scale. These extents match the museum's colour rule; they are not inferred from room walls.

The point starts halfway across that field, 1.25 metres above its floor. The small preview and readout travel with it. Walk to it and grip it using the prepared XR hands. On desktop, change `start` and run again. The existing columns and ceiling remain the large illustration; this study adds a sampler and does not rebuild them or attach itself to their materials.

## The complete continuation — lesson.gd

{lesson.gd}

At the start, expect `HSV 0.425 0.625 0.500` and approximately `RGB 0.188 0.500 0.359`. The displayed RGB numbers are rounded; their unrounded values are `(0.1875, 0.5, 0.359375)`.

## Two mappings, two scales

`to_local(point.global_position)` expresses the carried point in this study's frame. `hand_to_field` then maps reachable hand heights from 0.65 to 1.85 metres onto field heights from 0.46 to 4.6 metres. You can inspect the whole vertical colour range without reaching the ceiling. `clampf` stops the returned fraction at zero and one; it does not stop your hand.

`hsv_at` gives each field coordinate a role. X chooses hue from 0 to 0.85. Z chooses saturation from 0.25 to 1. Y chooses value from 0 to 1. These ranges are authored decisions, including the omitted end of the hue cycle and the absence of zero saturation.

`colour_at` passes those three values to `Color.from_hsv` and returns a Color. The receiving material needs RGB channels; Godot performs the conversion. `hsv_at` also returns the original parameters for the readout, so a hue remains visible as a number even when value is zero and the swatch is black.

In Nails, moving up changed green. Here it changes value. The axis has acquired a different function. Neither coordinate arrangement is inherent in colour.

## Hold two coordinates still

1. Keep X = 6.4 and Z = 9.6. Set the starting Y to 0.65. Value reaches zero and the preview is black.
2. Set Y to 1.85. Value reaches one. Hue and saturation keep their previous values; all three RGB channels are twice their middle-height values.
3. Set Y to 2.5. The point is above the mapped hand range, but value stays at one.

Restore the starting height. Choose another X or Z and predict which HSV parameter will change. Then choose two different positions with the same Y. Their colours can differ while their value parameter stays equal.

The preview uses an unshaded material for comparison. Raising value does not add a light, and equal value does not guarantee equal perceived brightness for different hues. The columns' lighting and the ceiling's apparent fog belong to the larger encounter.

Write down one RGB result with enough precision to use again. Grid begins with the middle sample above as an entry in a palette. That record is the handoff; no automatic save between these study scripts is assumed.

## Inherited point — point_body.gd

The exact earlier class is included for a complete runnable folder. Its sphere, collider and pickup behaviour remain unchanged.

{point_body.gd}
''',
'Color_Grid_Pallet': '''# Grid — a colour left at an address

**Learning elements**

- An address selecting stored instance colour
- A small class holding a palette and its current index
- Independent instances of the same class
- A local edit beside a rule over the whole grid

In the museum's grid, select a place and leave a colour there. Move to another place. The first choice remains. An address keeps the colour after your attention has moved on.

Arrays gave us indexed parts. Nails and Pillar returned a colour from a position. Now one of those returned colours becomes stored data. The new class keeps an ordered palette and remembers which entry comes next.

## Make two palettes

Save the four files printed here together. Attach `lesson.gd` to a Node3D on a clear display surface in your working copy of the Grid hall. The museum supplies your view and movement. This compact 5 by 5 model reconstructs the addressed colour operation; the installed floor and its interaction console remain in place.

`GridSurface` supplies 25 visible tiles and a dictionary connecting each `Vector2i(x, z)` address to a MultiMesh instance. Its `read`, `write` and `mark` methods are printed below. The second component of a Vector2i is called `y` in code; here we use it for the floor's Z address.

## The complete continuation — lesson.gd

{lesson.gd}

## The state we keep — palette.gd

{palette.gd}

`Palette.new(choices)` creates an instance. Its `_init` copies the chosen list with `assign`, so changing the caller's list later will not quietly change this palette. Colour values are copied; this is not a general deep-copy rule for objects.

`current_colour` returns the entry at `index`. `next_colour` advances the index, wraps it with `%`, and returns the new current entry. `paint_selected` first writes the current colour, then advances. The next press therefore uses the next entry. An empty palette violates the constructor's assertion.

We already used a PointBody class. This class has no mesh or position: its useful behaviour is remembering an ordered choice. The two instances have separate lists and indices. Advancing the first cannot advance the second.

The first palette includes the RGB sample recorded in Pillar. The second includes our earlier Nails choice. Those are explicit recorded values, not an automatic connection to either previous hall.

## Leave one mark

Run. Press **X** or **Z** to advance the selected address along that axis, wrapping after four. Press **C** to write the active palette's current colour there. Move the selection: the colour remains at the old address. Press **P** to select the other palette; this alone changes no tile. Press **C** again to use it.

Selection and painting are separate functions. `select_address` first checks that the address exists, then moves the marker. `paint_selected` changes the stored instance colour. Neither operation changes tile positions.

Press **R**. `apply_rule` visits every address and chooses `(x + z) % colours.size()` from the active palette. The sum advances along either axis, producing diagonal repetition. This replaces individual edits in the study's 25 tiles. A local memory can be overwritten by a later rule.

## Check what remains independent

Paint twice with the first palette. Switch to the second and paint once. Switch back: the first should continue at its third entry. Selecting another tile should neither consume an entry nor recolour it.

Try a one-entry first palette: replace its choices with `[sample]`. Every index wraps to zero. Then try four entries, `[sample, Color.WHITE, Color.BLACK, Color(0.8, 0.2, 0.6)]`. Predict how the diagonals change when you press R. The address dictionary and tile geometry stay unchanged.

For your own continuation, choose a new palette and make a small arrangement by painting selected addresses. Record one address and its colour. Predict which entry the rule will put there, then press R and compare. Explain the difference between the address, the instance index and the palette index.

## Supplied display — grid_surface.gd

{grid_surface.gd}

`use_colors` is enabled before the instance count is assigned. The shared mesh material reads each instance's colour through `vertex_color_use_as_albedo`. The tiles share a material; they do not require 25 separate materials. The dictionary declares the address-to-index connection rather than assuming that every museum floor uses the same ordering.

## Supplied desktop adapter — controls.gd

{controls.gd}

These keys call the same named operations as a console could. The installed museum console and larger, irregularly addressed floor remain supplied infrastructure. The small study has no walking-floor collider or VR console of its own.

Keep `Palette`. Walls will give two surfaces their own instances. Paint first changes the scale of the stored mark: from one tile to a region of a surface.
''',
'Color_Paint': '''# Paint — a mark stays on the surface

**Learning elements**

- Held, active and valid-hit states
- A named action carried from input to an operation
- A ray selecting the first surface it meets
- A world hit converted to a surface address
- Repeated marks accumulating in one image

Take a spray can in the museum. Colour arrives where the nozzle meets a surface; it remains when you turn away. Grid kept one colour at a cell address. Paint keeps many small deposits in a surface image.

We return to PointBody as a small study brush. Its pickup behaviour is already built. The lesson adds the path from a held object and an action to a retained mark. The museum's can shell, mist, wetness, elongated deposits and paint runs are richer than this study's circular soft stamps.

The first goal is one mark you can account for: **hold → request spray → aim → accepted hit → surface address → retained colour**. Keep `automatic` set to `false`. The automatic caller is included in the complete script for an optional continuation after your own brush works.

## Continue with the point

Save the four files below together. Keep the exact `point_body.gd` from Lines and Coordinates. Attach `lesson.gd` to a Node3D in an open part of your working museum hall. Keep unit scale throughout. Its local origin is on the floor; the white canvas is centred at Y = 1.5, faces positive Z and measures 4 by 2.5 metres. The point begins 1.5 metres in front of it. The museum supplies the camera, player and configured XR Tools.

Grip the point in VR. Its forward direction is local negative Z, indicated by the small stem. The prepared pickup driver calls its action methods when you press and release the controller trigger. In this study we name that action `spray`. On desktop, press **H** to attach the study brush to the mouse ray, then hold the left mouse button to paint. Press H again to put it down. This adapter is included; it is not a new input-map setup lesson.

## The complete continuation — lesson.gd

{lesson.gd}

Run and aim at the canvas. **READY** means the manual brush is not active. **SPRAY / MISS** means it is active but has no accepted canvas hit. **MARK** means the current step reached the receiver and deposited colour. These are state readouts; the reduced study has no particle mist.

## Permission, aim, address

Picking up the point sets `held`. An action press can set `active` only while held. Releasing the action clears it; dropping the point clears it too. Calling `set_action` with another name does nothing. Those conditions decide whether `manual_step` may attempt a mark.

The ray begins at the point and travels along its forward axis, up to `max_distance`. It excludes the point's own physics body. `collide_with_areas` lets it find the canvas receiver, which is an Area3D. The first hit must be that receiver. A miss or another object in front of the canvas leaves the image unchanged.

The hit position belongs to the world. The canvas converts it with `to_local`, then divides local X and Z by its width and height to obtain a UV address between zero and one. The canvas was turned upright as a whole; its local drawing plane is still XZ. This lets the same address calculation work when the study is moved or turned.

`draw_spray` blends the ink into existing pixels near that address. Closer pixels receive more. The amount `1 - exp(-7 * delta)` describes an accumulation rate: with a stationary brush and the same soft weight, shorter time steps approach the colour in smaller increments. Rasterisation and pixel rounding still affect the result. This is a simple deposit model, not a physical aerosol simulation.

## Make and keep a mark

1. Paint briefly at the centre. Hold still longer: the same region grows closer to the ink colour. Move away and release. The earlier mark remains.
2. Change `radius` from 0.06 to 0.12. The physical radius doubles. Width and height are converted separately, so the 4 by 2.5 metre canvas does not stretch a circular stamp into an oval.
3. Restore the radius. Set `max_distance` to 1.0. At the initial point position the surface is out of reach; pressing produces no mark. Restore 3.0 and it is reachable again.

Choose another ink colour and use it over an existing mark while the study is running, through the inspector's Remote view. `@export` exposes `ink` there: select the running study node and edit its Ink property. The image keeps its previous contents and the new deposits blend into them. Restarting this study creates a fresh white image; saving it across sessions is not part of this lesson.

## Know when the manual lesson works

With the automatic caller still off, choose a new ink colour and a clear part of the canvas. Before pressing, predict where the mark will appear. Aim away while holding the action: the readout should become **SPRAY / MISS** and deposits should stop. Aim back: **MARK** returns. Release the action or put down the point: **READY** returns and the earlier marks remain.

You have completed the core lesson when you can make that mark, interrupt it, and explain where its colour is kept. The image holds the accumulated result. The point supplies an aim and a request; it does not keep the painted marks.

## Supplied receiver — canvas.gd

{canvas.gd}

The receiver rejects invalid radii, empty deposits, outside addresses and rays facing away or too obliquely. It allocates the image once, blends into its pixels, then updates the texture shown by the material. Its support code is visible so the mark has no hidden implementation. The lesson's focus is connecting the known body and action to this surface operation; GPU feedback, wet-paint chemistry and drip motion remain outside this reduced model.

## Supplied desktop adapter — controls.gd

{controls.gd}

## Inherited body — point_body.gd

{point_body.gd}

## Optional continuation — another caller, the same receiver

Continue here after the manual lesson works. You can also leave the automatic painter as an encounter in the museum and proceed to Walls.

Set `automatic` to true and run. `automatic_step` supplies a moving UV address through two sine functions, maps it back to the canvas and calls the same `draw_spray` method. It does not require the manual brush to be held. Manual and automatic callers accumulate in the same image. The addition demonstrates reuse of the receiver; it is not required to complete the manual painting lesson.

Change the second sine rate from 1.3 to 2.0. Predict how its repeated path differs. Keep the manual controls working while the path runs. The canvas should not need a second renderer for another source of marks.

Paint leaves state on a surface. Walls next asks what happens when a surface changes the view through it while its physical boundary stays put.
''',
'Color_Walls': '''# Walls — a view through two colours

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

{lesson.gd}

Run. Press **F** to switch between filter and opaque modes. Press **C** to advance the first pane's palette. Move sideways to change which parts overlap. The second pane's colour should remain unchanged when you advance the first.

`surface_colour` takes a Color value and returns one with an assigned alpha. It preserves RGB. In filter mode it bounds `opacity` to 0–1; opaque mode uses one. Because Color is a value, this local change does not alter the stored palette entry.

The material also needs the matching transparency mode. Alpha alone is insufficient when the material is configured to render as opaque. `apply_colours` sets both properties. It never moves a pane, resizes its collider or changes collision layers.

## Separate what changes

Set `opacity` to 0.2 and run. More of the view behind the sheet contributes to the composite. Then try 1.0. Switch with F: at full alpha the visible difference may disappear even though the selected mode changes. In both cases the same collider remains.

Restore 0.52. Change only the second value in `turns` from 15 to 45 degrees. The overlap changes through geometry. Change only a palette entry: its colour changes through material state. These are different ways to compose with the same panes.

For your own continuation, arrange the two panes so one chosen view has a large overlap and a nearby view has none. Keep both palettes independently changeable. Explain which values you changed and why the route around the panes remains open while the panes themselves still block passage.

This is ordinary alpha compositing, not spectral transmission through glass. It depends on the colours and order of rendered surfaces and on the view behind them. It does not guarantee physically accurate mixing. The unshaded sheets make those assigned colours easier to inspect; they do not illuminate the room.

## Supplied pane — pane.gd

{pane.gd}

The sheet and boundary are separate children of one body. The boundary's size stays `(2, 2.5, 0.04)` in both modes. Disabling it would be a different operation with a different effect on movement.

## Inherited palette — palette.gd

{palette.gd}

## Supplied controls — controls.gd

{controls.gd}

Keep the distinction at the end of Colour: a choice can change a surface, a light, a stored address or the composite seen through several layers. State where the colour is held and which operation receives it. The same three channel values do not make those operations interchangeable.
'''
}

def main():
    for hall, template in LESSONS.items():
        for path in sorted((HERE / hall).glob('*.gd')):
            marker = '{' + path.name + '}'
            if marker in template:
                block = '<!-- student-code:' + path.name + ' -->\n```gdscript\n' + path.read_text(encoding='utf-8').rstrip() + '\n```'
                template = template.replace(marker, block)
        (HERE / hall / 'tutorial.md').write_text(template, encoding='utf-8')

if __name__ == '__main__':
    main()
