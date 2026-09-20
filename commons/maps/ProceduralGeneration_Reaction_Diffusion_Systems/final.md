# A pattern has a metabolism

<!-- @turing_pattern_generator -->

A patch interrupts the field. Before advancing it, predict where the next change should occur: everywhere at once, around the boundary, or only inside the patch? STEP performs one update. A hundred updates make the consequence easier to see while keeping the same rule.

At each address the program stores two concentrations, U and V. It reads the old arrays, calculates local changes and writes separate arrays for the next state. Only then are the buffers exchanged. The result does not depend on whether the display happened to draw the left edge first.

```gdscript
var uvv = u * v * v
var du = Du * lap_u - uvv + feed * (1.0 - u)
var dv = Dv * lap_v + uvv - (kill + feed) * v
```

Diffusion exchanges with neighbours; reaction, feed and removal change the local quantities. This is the Gray-Scott model, not a direct implementation of Turing's original chemical equations. REGIME chooses another feed/removal preset and restarts the field. SEEDING changes the initial arrangement. Compare those interventions separately.

The grid wraps at its edges. Concentrations are clamped to the interval zero to one. These choices are part of the experiment. A field that seems to continue beyond its frame has a particular way of returning through it.

<!-- @ -->

<!-- @reaction_diffusion -->

The second reaction–diffusion display remains a running comparison with its own implementation and settings. It is not a synchronized duplicate of the desk study. Look for recurring spatial features, then return to the controls before attributing a difference to one coefficient.

The soft-body samples, detailed bulge and Confessing Body theatre preserve further connections to the chapter. A chemical field can colour a wall, displace a surface or feed a growth rule, but each application needs an explicit mapping. Pattern formation alone has not made a solid that can bear your weight.

This matters to the red thread. New combinations become possible, and so do new confusions. A useful bridge should let us inspect the operation that carries a field into a form. The next artifact provides precisely such a mapping—and gives one of its controls an especially demanding name.

<!-- @ -->
