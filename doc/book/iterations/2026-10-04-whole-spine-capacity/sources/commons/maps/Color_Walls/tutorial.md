# Three ways to pass

Begin with a chair seen through two coloured panes. Step sideways until only one pane covers it. The chair, its position and its material have stayed fixed. Follow the edge to a gap and walk around the pane. A view through a surface does not promise passage through it.

Return to the entrance and press FILTER / OPAQUE. Repeat your route. Inspect `toggle_office_glass()` in `algorithms/color/color_mixing/color_constellation_office.gd`: it changes the surface material and shadow setting, without rebuilding the collider. The twelve panes are positioned by `PANES` in `office_planes.gd`. Each row contains x, z, yaw, width, height and colour. The geometry uses transforms already introduced in Transformation and a repeated construction already introduced in Arrays.

The new decision is how the surface combines with the view behind it. Both states use `BLEND_MODE_MIX`. Filter mode enables alpha transparency with alpha 0.52; opaque mode disables transparency and sets alpha to 1.0. Start with one pane. Change only its colour, then compare the same chair with and without a second pane in front of it. Keep the supplied pale backing so dark surroundings do not obscure the furniture. This operation blends rendered RGB colours; it is not a model of spectral absorption. Transparent surfaces are sorted for rendering, so their order contributes to the result.

For a first alteration, change one row's yaw, rebuild, and find a new overlap by walking. Keep widths and gaps fixed until you have checked which routes remain possible. The furniture, support geometry and comparison button are supplied apparatus; rebuilding them is not the learning target here.

At the navigator, identify the RGB axes. Each displayed sample uses its three channels as coordinates relative to the model centre. Locate the same general colour region in the HSV cylinder. Hue is now an angle, saturation a radius, value a height. Compare up in each model: RGB increases green, while HSV increases value, returning to the vertical rule of the Pillar field. Each model shows 500 samples, not every colour. Inspect the black corner's deliberate brightness adjustment.

At the interpolator, leave the initial red and blue endpoints unchanged and switch RGB / HSV. Describe the middle before reading `_recalculate()` and `_lerp_hsv()` in `algorithms/color/gradient_interpolator/gradient_interpolator.gd`. RGB linearly interpolates channels. HSV chooses the shorter hue arc, then interpolates saturation and value. Use COLOUR A and COLOUR B to choose another pair and repeat.

Carry three distinctions into Pattern_Disco: a material can change a view, coordinates can organise values, and an interpolation rule can choose a path. Keep the floor arrangement while changing its palette, then keep the palette while changing the pattern. Compare what each change makes visible.


<!-- study-spine:colour_assembly -->

## Return: Room to gather

Shift the colour index by one without moving a panel. Begin with the supplied study in the museum and compare the two states from the same place. Name what remained fixed before inspecting the code.

This application reuses coordinates, transform, array, colour. The small edit belongs to the learner; the display, main player and physical controls are supplied. Its adapter is `commons/artifacts/spine_studies/station.gd` (`assembly`), which calls the study’s own setters. Change one parameter, predict the visible consequence, then test another value. Reconstructing every mesh is not a prerequisite for this encounter.

[Earlier study and making notes](/book-review/doc/book/iterations/2026-10-02-gillick-room-to-gather/index.html). Geometry controls wait until the exhibit is clear. RESET returns the original comparison.


<!-- study-spine:colour_wall_studies -->

## Return: Wall relations

Change the pitch of 24 rails without changing their count. Begin with the supplied study in the museum and compare the two states from the same place. Name what remained fixed before inspecting the code.

This application reuses line, coordinates, array, colour. The small edit belongs to the learner; the display, main player and physical controls are supplied. Its adapter is `commons/artifacts/spine_studies/station.gd` (`wall`), which calls the study’s own setters. Change one parameter, predict the visible consequence, then test another value. Reconstructing every mesh is not a prerequisite for this encounter.

[Earlier study and making notes](/book-review/doc/book/iterations/2026-10-02-gillick-wall-relations/index.html). Geometry controls wait until the exhibit is clear. RESET returns the original comparison.


<!-- study-edit:colour_assembly -->

### One source change: Room to gather

In colour_for(), replace the initial palette_index assignment with this line. In the alternating colour mode, each numbered panel gets the next colour; its transform stays fixed.

```gdscript
var palette_index := (index + 1) % PALETTE.size()
```

Source: `commons/artifacts/colour_assembly/colour_assembly.gd`. Use the prepared scene to run and compare.

<!-- study-edit:colour_wall_studies -->

### One source change: Wall relations

The installed SPACING control calls this setter. Try 0.18 as a third state inside station.gd’s wall branch. Twenty-four centres retain their order and count.

```gdscript
set_spacing(0.21)
```

Source: `commons/artifacts/colour_wall_studies/colour_wall_studies.gd`. Use the prepared scene to run and compare.
