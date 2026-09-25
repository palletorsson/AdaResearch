# Who connected the controls?

<!-- @entropy_morphogenesis -->

The surface opens and folds around passages. It recalls the sine and noise spaces we walked earlier, now combined into a sampled field. Before touching S, choose one opening you can follow with your eyes. Keep track of it as the surface is reconstructed.

S changes several parameters together. The desk reports their values so that an impressive transformation does not hide its recipe.

```gdscript
current_frequency = lerpf(base_frequency, high_frequency, S)
current_noise_amp = lerpf(base_noise_amp, high_noise_amp, S)
current_threshold = threshold_center + threshold_wobble * (S - 0.5) * 2.0
```

The parameter is called entropy in the source. Here it is an authored control between settings, not an entropy value calculated from a distribution. Its name cannot establish a law connecting disorder and form. The mapping can nevertheless become a useful instrument if we expose what it does.

NOISE removes or restores the noise contribution. LEVEL moves the cut: minimal, thickened, pinched, broken, and back to minimal. RESOLUTION rebuilds the same surface from 24, 16 or 32 samples along each edge. Try them separately, then compare that experience with moving S. Which differences had been bundled into its single gesture?

Here is what the cut does, computed from the field without its noise. At the opening setting the surface divides the box almost in half, 52 per cent solid and 48 air, and each half is one connected labyrinth; the widest ball that fits in the air is about three and a half metres across. Thickened moves the cut down: the solid takes 72 per cent and the air is left in two separate pockets. Pinched leaves the solid a third, still one piece, drawn out into necks. Broken cuts it to a fifth, and the solid comes apart into islands. Now move S to one. The pattern’s period shrinks from five and a half metres to under four, the same four cuts apply, and the thickened pocket that admitted a three-metre ball now admits one of a metre and a half.[^gyroid]

![One slice through the field at the opening setting, cut at the four levels the desk offers](/book-review/doc/book/figures/softbodies/gyroid-four-levels.png)

*One slice through the same field, cut at the four levels. Dark is the solid side. Nothing in the field changed between the four panels; only the number the cut was made at.*

The generated collision belongs to the reconstructed surface. An opening that appears in a rendering may still be too narrow for your body. A change in geometric frequency is not automatically a change in connectivity, and neither alone certifies a traversable route. We can learn to ask each question at the scale where it has consequences.

Across these halls, a body has become a set of relations that can yield, remain attached, be driven, meet an obstruction, or be held as a sculpture. We have also seen appearances that imply mechanisms they do not contain. The point is not to exhaust desire by naming every rule. It is to gain enough purchase on a rule to change what it permits—and notice what the next construction still leaves out.

<!-- @ -->

[^gyroid]: Computed on the artifact’s own grid of forty samples across an eight-unit box from f = sin(kx)cos(ky) + sin(ky)cos(kz) + sin(kz)cos(kx), with k = 1.11 at S = 0.3 (the desk’s opening value) and 1.6 at S = 1, the thresholds the desk sets (0, −0.6, 0.6, 0.95, shifted by 0.15 × (2S − 1)), and the solid taken as the side above the threshold. The noise term, at most a fifth of the field’s range, is left out. Pieces are counted on the sample grid; the ball is the largest that fits in the air phase.
