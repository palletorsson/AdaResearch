# Fractal_Recursion — walked

> R-021/R-028: considered critical tutorial, ghost-drafted from the working map;
> Palle rules the voice. The walk (tutorial) woven with the turn (critical).

## The cast

cube_staircase · cube_subdivision · recursive_chair · recursive_table · fibonacci_pagoda · recursion circles

## The walk

One rule, applied to its own output. The `cube_subdivision` shows you the whole engine in a single object: take a cube, divide it into eight sub-cubes, then do it *again* — to the sub-cubes. That "again" is the entire chapter. A recursive function has just two parts: the rule (divide) and the base case (stop at depth *n*), and everything you will meet for the next nine maps is those two parts wearing different clothes. Walk the `cube_staircase` and count the depths as you climb; watch complexity grow exponentially while the rule stays five lines long. Then meet the furniture. The `recursive_chair` and `recursive_table` are ordinary objects fed back into themselves — chairs whose legs are chairs, a table whose surface breaks into tables — and the `fibonacci_pagoda` stacks a different recursion, F(n) = F(n−1) + F(n−2), where each floor is built from the two below it. The lesson is in your hands before it is in your head: nothing here was drawn. Everything was *generated*.

## The turn (critical)

The recursive chair is the map's real argument, and it is an uncanny one: self-reference does not decorate the familiar object, it **estranges** it. A chair is the most domesticated shape in the curriculum — you know what it is for, your body knows how to approach it — and the moment its parts are chairs it stops being furniture and becomes a *process caught mid-run*. That shift is the chapter's thesis in miniature: complexity is not designed, it is generated, and the generating rule is almost embarrassingly small. Which quietly removes a figure the whole history of design assumed — the author who drew the complicated thing. No one drew the depth-4 staircase; no human *could*, not reliably; a five-line function did, by taking its own output as input. The walker who arrived at Point_One into a frame already counting now meets the same structure spatially: the map contains the map, the rule was already running inside the rule. Recursion is thrownness made geometric — you never stand outside the structure, because every level of it is another copy of where you already are.

## Room for improvement

*(Palle: "self-reference estranges the familiar — the chair becomes a process
caught mid-run" is the turn. Note whether depth-counting on the staircase makes
the exponential growth felt, or whether the depth comparator gap still bites.)*
