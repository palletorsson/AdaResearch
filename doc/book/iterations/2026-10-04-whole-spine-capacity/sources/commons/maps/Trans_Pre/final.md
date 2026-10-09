# What survives its movement?

In Melencolia, the pyramids stayed still while your viewpoint changed. Here, stay a moment and let an object change in front of you. What survives its movement?

Four cubes are spaced down the middle of the hall. Smaller markers stand beside the row. Beyond the cubes, wedges lead up to a raised path. Here we can follow how a game pickup gets its animation.

<!-- @pick_up_cube -->

The first cube holds still. Pause before approaching and watch a corner: nothing shifts. Then walk into it: even without an animation, it can be collected. Keep its shape in mind as you go to the next one.

This cube moves up and down. Follow it through a complete rise and fall. Its position changes while its size and facing stay the same. Moving an object from one position to another is **translation**. Here that movement follows the vertical Y direction.

The script chooses a height between two endpoints:

```gdscript
global_position.y = lerp(original_y - bob_height, original_y + bob_height, t)
```

The animation moves `t` back and forth between zero and one. `lerp`, short for **linear interpolation**, uses that number to choose a height between the lower and upper endpoints. At `t = 0.5`, the cube is halfway between them. Each rise and fall takes it through the same heights, at a steady speed on each leg.

The third cube keeps moving up and down. What has been added?

Follow a corner. The cube turns as well. Changing its orientation — which way it faces — is **rotation**. This line adds a small turn around the upright Y axis on each update:

```gdscript
rotate_y(rotation_speed * delta)
```

Point Zero's small counter example received `delta` without using it. Here `delta` is the time since the previous update. Multiplying the turning speed by those elapsed seconds gives the turn to add now. A longer interval calls for a larger turn.

The rise and the turn continue together. Follow the same corner once more: it travels around the upright axis as well as up and down.

At the fourth cube, watch the edges move apart and come together. It grows and shrinks while it rises and turns. Changing size is **scale**.

```gdscript
var size_factor: float = lerp(1.0 - pulse_scale, 1.0 + pulse_scale, t)
_apply_pulse(size_factor)
```

The same `lerp` now chooses a size factor between 0.7 and 1.3. `_apply_pulse` multiplies the cube's starting size by that factor. A factor of one leaves the size unchanged; below one it shrinks, above one it grows. All three dimensions change together, so it keeps its cube shape.

Beside each moving example, a smaller marker isolates the operation just added: one moves up and down, one turns in place, one grows and shrinks. They let us separate movements that the larger cubes combine.

Look back along the four stations. The still cube has gone if you collected it; the three moving examples remain.

Walk up the wedges. Four more cubes wait above the raised path, rising, turning and changing size. Pick one to approach. As you walk into it, it swells briefly and disappears with a pickup sound. The others keep moving.

The three moving demonstrations behind you stay in place for another look.

Translation kept its size and facing. Turning kept the distances between its corners. Multiplying all three dimensions by the same factor kept its proportions. Each operation has left something to recognise. The next hall asks which of these changes can give us somewhere to stand.

<!-- @ -->
