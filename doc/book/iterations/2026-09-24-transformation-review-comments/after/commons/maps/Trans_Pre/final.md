In Melencolia, the pyramids stayed still while your viewpoint changed. Here, stay a moment and let an object change in front of you. What survives its movement?

We bring the cube, the wedge and the grid with us. Begin with the cube. It can become a familiar game pickup by adding movement, one operation at a time. Watch for what each addition changes, and what lets you keep recognising it.

<!-- @pick_up_cube -->

The first cube holds still. Pause before approaching and watch a corner: nothing shifts. Then walk into it: even without an animation, it can be collected. Keep its shape in mind as you go to the next one.

This cube moves up and down. Follow it through a complete rise and fall. Its position changes while its size and facing stay the same. Moving an object from one position to another is **translation**. Here that movement follows the vertical Y direction.

The script chooses a height between two endpoints:

```gdscript
global_position.y = lerp(original_y - bob_height, original_y + bob_height, t)
```

`lerp` means **linear interpolation**: find a value between two values. Here the endpoints sit below and above the starting height. At `t = 0` the cube is at the lower end; at `t = 0.5` it is halfway; at `t = 1` it reaches the upper end. The animation runs `t` back and forth between zero and one, carrying the cube up and down at a steady speed on each leg.

The third cube keeps moving up and down. What has been added?

Follow a corner. The cube turns as well. Changing its orientation — which way it faces — is **rotation**. This line adds a small turn around the upright Y axis on each update:

```gdscript
rotate_y(rotation_speed * delta)
```

In the first room, the counter received `delta` without using it. Here that interval has a job: multiplying the turning speed by the elapsed seconds gives the turn to add now. A longer interval calls for a larger turn.

The cube can rise and turn at the same time. Both movements belong to the animation you are watching.

At the fourth cube, watch the edges move apart and come together. It grows and shrinks while it rises and turns. Changing size is **scale**.

```gdscript
var size_factor: float = lerp(1.0 - pulse_scale, 1.0 + pulse_scale, t)
_apply_pulse(size_factor)
```

The same `lerp` now chooses a size factor between 0.7 and 1.3. `_apply_pulse` multiplies the saved size by that factor. Below one, the cube becomes smaller; above one, larger. All three dimensions change together, so it keeps its cube shape.

Beside each moving example, a smaller marker isolates the operation just added: one moves up and down, one turns in place, one grows and shrinks. Look back along the four stations. The still cube has gone if you collected it; the three moving examples remain. Recall the sequence: still; up and down; add turning; add growing and shrinking. Can you spot all three movements in the last one?

Ahead, wedges lead onto a platform with four collectible cubes. Here the finished animation belongs to a small level made from forms we already know.

Walk up and approach one. You can collect these by walking into them. The three moving demonstrations behind you stay in place for another look.

A few lines of code have given a plain cube the movement of a game pickup: **translation changes position, rotation changes orientation, scale changes size.**

Translation kept its size and facing. Turning kept the distances between its corners. Multiplying all three dimensions by the same factor kept its proportions. Each operation has left something to recognise. The next hall asks which of these changes can give us somewhere to stand.

<!-- @ -->
