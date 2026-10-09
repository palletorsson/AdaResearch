The value has stayed. Has the colour?

The previous room let you hide forty-eight cells without erasing them. Here the question turns towards the visible ones. A value has reached a surface. What else has arrived with it?

<!-- @SimultaneousContrast -->

Begin with the two grey squares. One has dark neighbours, the other light. Look before touching the controls. Do they appear alike to you? There is no required answer to report; make a comparison you can return to.

Press **SWAP**. The backgrounds exchange places. The targets keep their numerical values. Does your judgement follow the square, its surroundings, or neither?

Press **SURROUNDS** to give both targets the same grey background. Then return to the unequal backgrounds and press **CONNECT**. A narrow bar joins the targets using their colour. Notice what becomes easier to compare, and what remains uncertain. **UNDO** returns to your previous arrangement; **RESET** restores the start.

The two targets and the connector are assigned `Color(0.5, 0.5, 0.5)`. This comparison draws them without lighting-dependent shading. The controls change the backgrounds and whether the connector is shown. Numerical equality is something we can inspect in the program. It does not oblige every viewer, display or viewing situation to produce the same experience.

<!-- @MetamerismLab -->

At the other station, the familiar bent mark covers a plane and a curved wall. Find its blue corner on both. The plane is four metres wide; the half-cylinder is four metres along its arc. Each begins with four horizontal repeats and two vertical repeats. Walk a little sideways. Equal distances along the surfaces need not occupy equal widths in your view.

Press **GRID** to mark the repeat boundaries. Follow one around the curve. Its width along the surface stays fixed while its visible width changes with your position. The two ends of this half-cylinder are edges, not a welded seam; this station has not tested a pattern closing around an entire body.

Turn the grid off and press **FLAT / SHADED**. Keep watching one pale part of the mark. Now press **LIGHT SIDE**. Where does it darken? Compare the plane with the curve before reading the explanation.

Both surfaces read one texture. Their difference enters through their normals: directions describing which way the surface faces. The plane keeps one direction across its face; the curve turns. This small shader multiplies the sampled colour by a directional factor:

```glsl
float gain = shaded
    ? 0.18 + 0.82 * max(dot(normalize(specimen_normal),
                            normalize(light_direction)), 0.0)
    : 1.0;
ALBEDO = ink * gain;
```

The dot product compares the two directions. The added 0.18 keeps the model's darker side from becoming completely black. These are choices in the experiment. **LIGHT SIDE** changes a direction inside this shader; it does not move the museum's sun. The calculation does not model cloth fibres, gloss or wavelengths. Keeping the model small lets us follow exactly where the difference enters.

Try **REPEAT SIZE**. It changes the horizontal repeat from one metre to fifty centimetres on both carriers. The vertical repeat remains one metre. Neither the source pixels nor the meshes change. **UNDO** recovers the earlier setting; **RESET** returns to flat colour and the initial spacing.

The archived name of this artifact is MetamerismLab. Its earlier wave display assigned the same RGB yellow to both results without computing spectra. This encounter instead gives us a difference we can inspect: shared source values, different surface directions, and a stated rule for producing appearance. The older name cannot do the work of an experiment.

<!-- @ -->

Imagine carrying this mark onto a sleeve. Which part would you call the pattern: the source array, its spacing along the cloth, or the appearance that reaches someone across the room? Keeping one of those fixed does not keep all of them fixed.

This is where dressing becomes a question for the program. A carrier contributes shape; a material contributes rules for appearance. Neither is a neutral delivery system for an untouched original. Yet their contributions can be separated enough to investigate: keep the recipe, change one condition, return, compare.

In **Ribbon_Patterns_03**, we follow these operations into the shader and fabric studio: what gets sampled, where an edge is drawn, how a surface responds, and what can be carried onto a body. The mark will travel again. We now have more than one place to look when it changes.
