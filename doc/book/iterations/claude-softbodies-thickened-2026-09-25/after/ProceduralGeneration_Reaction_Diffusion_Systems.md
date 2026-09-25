# A pattern has a metabolism

<!-- @turing_pattern_generator -->

A patch interrupts the field. Twelve cells at the centre of a grid thirty-two across were given a little of the second substance; everywhere else has only the first. Before advancing it, predict where the next change should occur: everywhere at once, around the boundary, or only inside the patch? STEP performs one update; 100 STEPS performs a hundred, which makes the consequence easier to see while keeping the same rule.

At each address the program stores two concentrations, U and V. It reads the old arrays, calculates local changes and writes separate arrays for the next state. Only then are the buffers exchanged. The result does not depend on whether the display happened to draw the left edge first.

```gdscript
var uvv = u * v * v
var du = Du * lap_u - uvv + feed * (1.0 - u)
var dv = Dv * lap_v + uvv - (kill + feed) * v
```

Diffusion exchanges with neighbours; reaction, feed and removal change the local quantities. This is the Gray-Scott model, not a direct implementation of Turing's original chemical equations.[^turing] REGIME chooses another feed/removal preset and restarts the field. SEEDING changes the initial arrangement. Compare those interventions separately.

Press 100 STEPS, change REGIME, and press it again. After a hundred updates the six regimes still differ from one another in fewer than one cell in ten: the patch has grown a little and told you nothing about which law it is under. It takes about a thousand. By then, under Spots, the regime this hall opens in, the patch has stopped growing at three per cent of the field and stays one spot for as long as you care to press; under Stripes and Maze the same twelve cells have covered a third of the field and will cover most of it; under Mitosis they have split into four; under Coral they never move at all. The seed decides where, and whether. The two rates decide what.[^port]

The grid wraps at its edges. Concentrations are clamped to the interval zero to one. These choices are part of the experiment. A field that seems to continue beyond its frame has a particular way of returning through it.

<!-- @ -->

<!-- @reaction_diffusion -->

The second reaction–diffusion display remains a running comparison with its own implementation and settings. It is not a synchronized duplicate of the desk study. Look for recurring spatial features, then return to the controls before attributing a difference to one coefficient.

The soft-body samples, detailed bulge and Confessing Body theatre preserve further connections to the chapter. A chemical field can colour a wall, displace a surface or feed a growth rule, but each application needs an explicit mapping. Pattern formation alone has not made a solid that can bear your weight.

This matters to the red thread. New combinations become possible, and so do new confusions. A useful bridge should let us inspect the operation that carries a field into a form. The next artifact provides precisely such a mapping—and gives one of its controls an especially demanding name.

<!-- @ -->

[^turing]: Alan Turing, “The Chemical Basis of Morphogenesis”, *Philosophical Transactions of the Royal Society B* 237 (1952), 37–72. Peter Gray and Stephen Scott set out the autocatalytic scheme in *Chemical Engineering Science* 39 (1984); John Pearson, “Complex Patterns in a Simple System”, *Science* 261 (1993), 189–192, mapped its feed and kill plane, and the presets REGIME cycles are points on that map. The excerpt above is Pearson’s discretised form.

[^port]: Measured in a numpy port of the shipped update (the same 0.2 and 0.05 neighbour weights, the same clamp, the same twelve-cell stamp of U 0.5 and V 0.25) at the hall’s resolution of 32 and its centre seeding, coverage counted as cells where V exceeds a tenth, at 100, 300, 1,000, 2,000 and 4,000 updates: Spots 2, 3, 3, 3, 3 per cent in one blob; Stripes 3, 9, 37, 86, 91; Maze 4, 11, 42, 65, 65; Mitosis 3, 4, 7, 13, 34 in four then twelve blobs; Coral 1 throughout. The artifact’s own source records a matching measurement at resolution 40 with the five-disc seeding.
