# Three ways to pass

Begin with the office. Look through a pane toward a chair, then use the doorway to enter. From beside the chair, look back towards the aisle and notice that the view is reciprocal. Return to the entrance console and press GLASS / OPAQUE. Repeat the route. Compare what became hidden with what became impassable before explaining either.

The button changes transparency and alpha; it never rebuilds a collision shape. Inspect `toggle_office_glass()` in `algorithms/color/color_mixing/color_constellation_office.gd`. Ask which part of the implementation the eye encounters and which part the body encounters. Move until panes overlap; this view is produced by rendering several transparent materials.

At the navigator, identify the RGB axes. Each displayed sample uses its three channels as coordinates relative to the model centre. Locate the same general colour region in the HSV cylinder. Hue is now an angle, saturation a radius, value a height. Compare up in each model: RGB increases green, while HSV increases value, returning to the vertical rule of the Pillar field. Each model shows 500 samples, not every colour. Inspect the black corner's deliberate brightness adjustment.

At the interpolator, leave the initial red and blue endpoints unchanged and switch RGB / HSV. Describe the middle before reading `_recalculate()` and `_lerp_hsv()` in `algorithms/color/gradient_interpolator/gradient_interpolator.gd`. RGB linearly interpolates channels. HSV chooses the shorter hue arc, then interpolates saturation and value. Use COLOUR A and COLOUR B to choose another pair and repeat.

Carry three distinctions into Pattern_Disco: a material can change a view, coordinates can organise values, and an interpolation rule can choose a path. Keep the floor arrangement while changing its palette, then keep the palette while changing the pattern. Compare what each change makes visible.
