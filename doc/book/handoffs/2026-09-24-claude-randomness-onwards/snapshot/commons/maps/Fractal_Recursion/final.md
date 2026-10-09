How many times can *again* happen?

<!-- @fractal_recursion_2 -->

A square waits above the first desk. Press MORE. Another square appears inside it, half as wide. Ask again. The instruction is brief enough to hold in your head; the shrinking squares soon become harder to hold in your eyes.

Before opening RULE, try LAYOUT. The squares spread into a descending row. Nothing has been added. What looked like an interior can be arranged as a succession. COLLAPSE presses all the drawn squares down to the smallest term, leaving the outer frame where it was. The count does not fall with their visibility.

Here is the self-call from the artifact:

```gdscript
var new_size: float = size * size_reduction
_draw_recursive_pattern(center, new_size, d - 1)
```

The function has just drawn a square. It now calls itself with a smaller size and one less level to spend. At the beginning of each call, this condition can return it to the caller:

```gdscript
if d <= 0 or size < TERM_MIN_SIZE:
    return
```

`TERM_MIN_SIZE` is one centimetre. This desk also caps the requested depth at seven. Those are different limits: a chosen number of calls and a chosen minimum size. Neither is the same as the smallest detail your eye can distinguish in the helmet.

Seven levels produce seven squares. One call makes one further call. We could also write this particular descent as a loop. Seeing a square inside another square does not tell us which program made it. We had to look behind the image.

<!-- @example_8_3_recursion_circles_vr -->

The other desk begins with one ring. Predict the count after MORE. Five. Once more: twenty-one. The footprint remains roughly the same while the number of things occupying it changes quickly.

Each call draws its ring, then makes four smaller calls, shifting their centres right, left, up and down. Four levels leave `1 + 4 + 16 + 64` rings: eighty-five. The fifth leaves three hundred and forty-one. “One more” has acquired a different cost.

Return to depth four and try PACKING. The child radius changes; the number of rings stays. At depth five, DUST loses a whole level: its smallest requested radius falls below the source's one-centimetre cutoff. A depth allowance does not guarantee that every call will draw. Some overlap, some meet, some separate. TURN releases their planes into the artifact's rotating motion. Stop it to return to the frontal comparison. An apparent tangle can come from placement and pose as well as from adding more things.

The room can accommodate three hundred and forty-one rings. That does not mean it has made three hundred and forty-one distinctions easy to read. We already met this gap at the trace: what is stored, what is drawn, and what becomes available to a body do not have identical resolutions.

<!-- @cube_subdivision -->

Now a cube waits on a plinth. Press SPLIT. Eight smaller cubes take its place. Press again. Fifteen, not sixty-four. This machine divides one selected cell at a time.

Choose DRILL and spend the twelve splits. Then choose SPREAD and spend the same allowance. Both end with eighty-five cells. DRILL follows one corner into smaller and smaller scales; SPREAD chooses a cell from the shallowest remaining level. The readout reaches depth twelve in one case and depth three in the other. Equal counts have bought different bodies.

LOTS draws from the remaining population. Its seed is fixed here. BEGIN lets you repeat the same choices and inspect something you missed. Repetition becomes a way of paying attention.

The source sets a child's scale like this:

```gdscript
var new_scale = cube_scale * 0.5 * 0.9
```

Half, then a little smaller. The gaps that make the division legible are authored too. And the tiny cell that DRILL keeps choosing still costs something even after its difference becomes difficult to see. More work need not yield more experience. Where would you spend the next split?

<!-- @recursive_chair -->

At the last desk, NEXT starts to make a chair. After the first cut, press GHOST. Eleven pale cells return around the sixteen that were kept. SCAR marks the discarded centres; GONE hides those witnesses again. The choice of what to keep has become visible beside its result.

Something else moved. The first stage lifts the divided lattice; subsequent stages flatten the seat, extend legs and back, then add armrests. The chair was not simply waiting inside the original cube. Parts are selected, translated, stretched and added according to an intention about chairs.

This artifact carries “recursive” in its name, but its construction runs through five authored stages. There is no self-call in that sequence. Its presence beside the squares is useful precisely because a familiar appearance can conceal a different procedure.

<!-- @ -->

The table, staircase, pagoda and other works remain beyond the desks, a collection to return to with these distinctions in hand. We do not have to make every object evidence for the same claim.

A rule, a stopping condition, a choice of where to continue: we can now separate them. In the next hall the call branches. What does a tree inherit from the branch before it, and where can it differ?
