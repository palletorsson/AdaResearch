# The colour lands

<!-- @becoming_catalyst -->

A small instrument faces a crate in a frame. The aim is already chosen. What remains for you to choose is when.

Press **FIRE COLOUR** once. Follow the bright sphere, then look at the crate. Stay with the place where it landed a little longer. Has only the crate changed?

Around its feet, some grid cubes have taken colour too. Their edges no longer quite agree with the grid. Small cubes spring away and disappear. Wait until the flash has passed before deciding what the shot left behind.

The instrument uses the catalyst's chromatic mode. Each launch chooses a hue:

```gdscript
var hue := randf()
proj.color_primary = Color.from_hsv(hue, 0.85, 1.0)
```

You did not select a pigment from the tray this time. The machine chose from an interval. During flight, its glow cycles through further hues, while the stored colour travels unchanged. The appearance that caught your eye on the way need not be the value delivered at the end.

The target receives that stored value and uses it to tint its materials. Nearby grid cubes receive another calculation. Their distance from the impact shifts the hue:

```gdscript
var hue_shift := dist * 0.15
var paint_color := Color.from_hsv(
    fmod(color_primary.h + hue_shift, 1.0), 0.8, 0.95
)
mm.set_instance_color(i, paint_color)
```

Only cube centres within 1.5 metres participate. This is a neighbourhood chosen by a distance test, not wet paint spreading over a surface. A cube just outside the radius stays as it was. Look for that boundary. The splash can look generous while its admission rule is exact.

Press again. The chosen hue changes; the aim stays fixed. The code also shrinks, turns and slightly displaces the affected grid visuals. Colour did not cause those changes by itself. The programmer put several operations behind one contact. We can separate them in the source even when the eye receives them together.

Approach the changed floor. Those smaller, tilted cubes still have their original collision bodies. The visual gaps have not all become gaps your feet can enter. Walls let a view pass through a body-blocking pane. Here the disagreement has moved underfoot: the image changes shape, while another account of the floor continues to hold you.

This is a remainder we can work with. We might choose to rebuild the collision and discover a new walk. We might preserve the disagreement and ask how you learn to trust a floor. The present implementation has made the second condition available; it has not completed the first.

On the third hit, the crate disappears. The frame stays. Wait. After four seconds the target begins to return, and you can start another three-hit cycle. Its counter starts again; the nearby grid has not been restored with it. A return can reset one part of an encounter while leaving another part altered.

The bench gives the visitor a mounted operation. It does not put a bracelet on your wrist or promise that these edits will survive reloading the hall. That larger question of what can travel with a body remains open.

<!-- @ -->

Across Colour, a value has needed a lamp, a nail, a neighbour, an address, a surface, a view. Now it arrives as a message, and the receiver decides what to do with it. What bodies are possible depends on those receiving rules as much as on the value we send.

Carry the coloured cube forward in thought. In Patterns, we will give a repeated element an arrangement. What can repetition make possible that one changed cube could not?
