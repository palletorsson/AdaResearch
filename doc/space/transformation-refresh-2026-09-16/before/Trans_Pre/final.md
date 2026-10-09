We leave Primitives with a cube, a wedge and a grid. Now we can make a familiar game object: a Mario-style pickup cube.

Watch how its movement is built up, one addition at a time.

<!-- @pick_up_cube -->

The first cube holds still. Keep its shape in mind as you go to the next one.

This cube moves up and down. Follow it through a complete rise and fall. Its position changes while its size and facing stay the same. Moving an object from one position to another is **translation**. Here that movement follows the vertical Y direction.

The script chooses a height between two endpoints:

```gdscript
global_position.y = lerp(original_y - bob_height, original_y + bob_height, t)
```

`lerp` means **linear interpolation**: find a value between two values. Here the endpoints sit below and above the starting height. At `t = 0` the cube is at the lower end; at `t = 0.5` it is halfway; at `t = 1` it reaches the upper end. The animation runs `t` back and forth between zero and one, carrying the cube up and down at a steady speed on each leg.

The third cube keeps moving up and down. What has been added?

Follow a corner. The cube turns as well. Changing its facing is **rotation**. This line adds a small turn around the upright Y axis on each update:

```gdscript
rotate_y(rotation_speed * delta)
```

The cube can rise and turn at the same time. Both movements belong to the animation you are watching.

At the fourth cube, watch the edges move apart and come together. It grows and shrinks while it rises and turns. Changing size is **scale**.

```gdscript
var size_factor: float = lerp(1.0 - pulse_scale, 1.0 + pulse_scale, t)
_apply_pulse(size_factor)
```

The same `lerp` now chooses a size factor between 0.7 and 1.3. `_apply_pulse` multiplies the saved size by that factor. Below one, the cube becomes smaller; above one, larger. All three dimensions change together, so it keeps its cube shape.

The small markers beside the examples help you recognise each operation. Look back along the four cubes: still; up and down; add turning; add growing and shrinking. Can you spot all three movements in the last one?

Ahead, wedges lead onto a platform with four collectible cubes. Here the finished animation belongs to a small level made from forms we already know.

Walk up and approach one. You can collect these by walking into them. The four demonstrations behind you stay in place for another look.

A few lines of code have given a plain cube the movement of a game pickup: **translation changes position, rotation changes facing, scale changes size.** We will use these three operations throughout the next halls.

<!-- @ -->
