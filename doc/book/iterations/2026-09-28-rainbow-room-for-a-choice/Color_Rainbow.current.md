# More colour, another rainbow

<!-- @rainbow -->

Two offers wait by the entrance: a crystal in a wire case and a cube to collect. Neither is required to join the celebration.

The mushrooms are dressed for it. Pearl collars beneath candy-coloured caps; stars beyond the arch; a small staircase that seems to have wandered in from a platform game. There is also a level path. You can join the celebration without taking the steps.

Enter along the coloured centre path. Confetti opens above it. You have not solved a puzzle yet. Stay a moment with the possibility that the room is pleased you arrived.

Find a boundary between two colours in the rainbow. Follow it far enough to see its curve. At the control plinth, press RE-DIVIDE. Find that boundary again. Has it moved, disappeared, acquired a neighbour? Has the opening beneath the arch become any smaller?

Try the button again before deciding what kind of rainbow this is. The steps keep their height. The path remains where it was. Yet the colours have another arrangement, and the familiar outline is being asked to hold it. CELEBRATE gives you another burst whenever you want one. There is no correct partition to earn first.

In the salon, one selected colour reached the same hand at two scales. Here a list of colours reaches a series of curved strips. Each strip is made from vertices: points placed along an inner and an outer half-circle, joined into triangles. Its position in the list gives it a colour.

The button moves through four authored choices: six bands, seven, forty-eight, then two. The generator keeps their combined width fixed:

```gdscript
return (RAINBOW_THICKNESS * 7.0) / float(maxi(1, rainbow_colors.size()))
```

The code keeps a total band thickness of `7 × 0.8`, shared out again whenever the list changes. The arch is scaled down to fit this hall. More strips each receive less of the fixed total; fewer strips receive more. The familiar arch can survive a change in how we divide its colour.

![Six, seven, forty-eight and two bands on the same museum arch.](/book-review/doc/book/iterations/2026-09-23-rainbow-room-for-another/four-arrangements.png)

*Four arrangements, seen from the same place. The coloured steps change with the arch; their height and the opening beneath it remain.*

Look for the seams in the forty-eight-band version. The option is called `continuous`, but each strip still has its own colour.

For each strip, the code computes a hue. **HSV** names hue, saturation and value: a place around a colour circle, how far the colour is from grey at that value, and a level that reaches black at zero. Here saturation and value both stay at one. Only hue travels:

```gdscript
var t: float = float(i) / float(count - 1)
out.append(Color.from_hsv(t * 0.78, 1.0, 1.0, 1.0))
```

`t` runs from zero at the first strip to one at the last. A hue value of one would complete a turn around the circle; multiplying by `0.78` takes this sweep partway around instead.

A name can promise continuity while an implementation offers enough small divisions for some seams to become difficult to see. These are HSV values converted into RGB colours on a mesh. No droplets, sunlight or wavelength calculation produce this particular rainbow. Even its opaque appearance does not make the bands a climbing surface. The low steps have collision; the arch is a display.

Look for a colour you chose in the salon, first in the arch and then among the striped banners and mushrooms. There are pinks, pale blues, whites and dark colours that this sweep through saturated hues does not offer. They already share the room, even when the arch has no place for them. What would you have to change in the list, or in the rule that builds it, to give another colour a place in the arch?

After the fourth arrangement, RE-DIVIDE returns to the first. You can stay with a version you like. Or you might want a fifth: a pale band, a colour given more room, a border that wanders away from the curve. The next change would reach beyond this button, into the list or the rule that makes it.

Before leaving, choose the version you want to stand beneath. Let the confetti return. The same programmed event can be a reward for obedience or an invitation that asks nothing of you; here you can repeat it without passing a test.

<!-- @ -->

Carry the distinction between a colour rule and the places where it is sampled. In the next room, pillars stand at particular addresses in a colour field. What is between them, where the field has a value but no pillar has been given a body?
