Where forces cancel, a form can hold still. That stillness can conceal opposition, exactly matched. But a still image can also be made without calculating any forces. How would you tell?

The preceding halls gave us steps, drawn curves and a mesh left in the pose where its computation stopped. Here the question becomes structural: which relations make a shape hold, and which relations have only been drawn? Start with a balance whose arithmetic you can inspect.

## Balanced by arithmetic

<!-- @calder_mobile -->

A curtain of painted aluminium discs on hair-thin wires, nearly six metres wide and three and a half tall, filling the north half of the room. Each disc carries a small dark nameplate reading its modelled mass in grams, which is the room telling you what to check.

Find one arm with a disc hanging from each end, and compare their nameplates. Which has the larger mass? Which is nearer its pivot? Follow that relation up one branch before reading the calculation.

```gdscript
var wl: float = left["mass"]
var wr: float = right["mass"]
var total: float = wl + wr
var arm: float = span * (0.7 + 0.35 * float(d)) * _rng.randf_range(0.85, 1.15)
var dl: float = arm * wr / total
var dr: float = arm * wl / total
```

Read the crossover. The left-hand distance is computed from the right-hand mass, and the right-hand distance from the left. Multiply out and the two mass-distance products agree, apart from numerical rounding. Gravity would multiply both by the same factor. The heavier child rides the shorter arm because the arithmetic gives it no choice.

For each disc, the source multiplies its area by three millimetres of sheet and the density assigned to aluminium. Then it builds every rod from the bottom up: add the two children's masses, place the pivot where their moments cancel, report the total upward. The rods and wires have no mass in this calculation. That omission lets the visible masses and distances satisfy a clean lever model; it does not establish how the sculpture would behave if we built it from the materials it resembles.

And it does not move. There is no process loop anywhere in it: for all the wire and the counterweighting, this is frozen sculpture, and the room's own older notes claiming it turns on a breath are describing something else. What hangs here is the solution to a chosen system of equations, held still because it was never going to do anything else.

<!-- @tensegrity_triangle -->

Three struts and three orange joints, with a rhythmic squeeze arriving every few seconds. Watch the width as the height contracts. The whole object is being scaled: the source writes a sine-driven change directly into its transform. It looks as though a load arrives and is refused, but no load has been applied and no member force is calculated.

There is a structural question worth keeping inside that appearance. An ideal hinged triangle with fixed side lengths cannot rack in its plane as an unbraced four-bar frame can. A side-by-side load experiment could let you test that difference. This animated triangle has not done that experiment for us.

One correction the name will not make for you. It promises a tensegrity, but the three struts meet at their joints and there is not a tension cable in the object. Keep the distinction between an attractive pose and the force relations needed to sustain it. In the next hall, an apparently impossible table will ask for that distinction again, with an unbothered teacup on top.

<!-- @fractal_truss_tower -->

A steel tower three and a half metres tall standing on a seven-metre plate, four fat corner legs and four stacked panels of cross-bracing, an orange beacon at the top. Its board now says RECURSIVE BRACED STOREYS / NO LOAD TEST. The old promise of maximum strength for minimum material remains an interesting aim. This construction has not measured either quantity.

The recursion halves the tower vertically and braces each half again, so what recurses is the storey and not the strut, and the finer legs it adds lie along the same corner lines as the coarse ones, hidden inside them. A beam made of beams is the idea. Stacked bracing, three deep, is the building. Its slight sway is prescribed too; the tower is not responding to a wind or testing a failure threshold.

<!-- @science_screen -->

The screen has no live load measurement from these objects. Its generic scanner can classify a tower by the word “fractal” and count children, but neither quantity establishes a balance. For the mobile, we need the two mass-distance products at each joint; for the tower, a stated load and a measured response. The nameplates are a beginning. A picture of structure is not yet an instrument for its strength.

<!-- @ -->

## Gravity as co-designer

Gaudí's hanging models offered another way to approach this problem: set up weights and supports, allow a physical relation to appear, and study its inversion as a possible compression structure. The load and the boundary matter as much as the curve. The model is a way to reason with gravity, not a certificate that every shape it suggests will stand.[^hanging-model]

Our three objects make different parts of that reasoning available. The mobile exposes a balance encoded in its mass model. The triangle lets us catch an animation passing for resistance. The truss makes repetition and bracing visible while leaving strength untested. Their differences give us the next experiments: change a mass, compare a hinged square, put a specified load on the tower. Those encounters are still to be built.

One thing to carry out. Before asking whether a form has reached the bottom, ask what was allowed to move and what counted as success. The next hall asks whether the bottom is where you want to be.

Next: how to leave a hole you have already fallen into, and why you might not want the deepest one.

[^hanging-model]: Santiago Huerta, [“Structural design in the work of Gaudí”](https://oa.upm.es/703/) (2006). The physical equilibrium method is a reference for these digital models, not a claim that their rendered members currently solve it.
