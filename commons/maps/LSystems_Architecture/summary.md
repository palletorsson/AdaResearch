# LSystems_Architecture — Summary

Replace one word and the world changes. The same production rules that grew trees now generate corridors, rooms, and city blocks. The grammar has not changed. The interpreter has. F stops meaning "draw a branch" and starts meaning "place a floor tile." The brackets stop saving branch state and start opening doorways.

The `lsystem_dungeon` artifact generates navigable floor plans from two rules — `F -> F+RF-FF-FR+F` and `R -> RFRFRF` — at 90-degree turns. At iteration 1, a simple L-shaped corridor with two rooms. At iteration 3, a labyrinth. Walls emerge from absence: any corridor tile with an unoccupied neighbor gets a wall on that edge. The grammar specifies positive space; the architecture defines itself around the gaps. The `CityGenerator` applies the same principle at urban scale, branching streets that enclose city blocks as negative space.

This is the pivot map in the sequence — the moment L-systems leave biology and enter designed environments. The key technical insight is the pluggable interpreter: the `derive` function is identical across trees, dungeons, and cities. Only the turtle changes. The grammar computes topology. The interpreter assigns domain. Any new domain — music, circuit layout, narrative — requires only a new interpretation function reading the same string.

The 8x10 map is structured as an urban grid with street-level paths at heights 1-2 and building blocks at 3-4. The learner walks through the proof that architecture is grammar with walls, then teleports into LSystems_Competition where multiple grammars will share a single world.
