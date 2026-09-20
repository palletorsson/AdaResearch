# Who gets the first turn?

<!-- @ForestCompetition -->

Two stems wait above a tiled field. One is amber, one blue. Both begin with F, the same diameter and the same rule. Their colours let us follow them; colour gives neither a different appetite.

Let A take a turn. A small branch appears, and a square patch of soil drops. Now let B take its turn. Both have reached generation one. Look at what they took: A received 2.250, B 1.980. These are the model's resource values. We have not measured grams of food.

Is something wrong with B's instructions?

Press ORDER to begin the comparison again with B first. The same soil returns; the same two starting stems return. Take two turns. B now receives the larger amount. Nothing in the branching sentence had to change.

Architecture separated the line from the boundary that lets a body pass. Here we separate a rewriting rule from the conditions that let it run. The familiar brackets still save and restore a turtle's state. Both specimens use this replacement:

```text
F → F[+F]F[-F][F]
```

The forest does something before applying it. It reads the soil around the selected root, subtracts a portion from each cell, and adds those portions to the tree's uptake. The comparison gives both trees a growth multiplier of one. This excerpt is the subtraction inside that cell loop:

```gdscript
var take := minf(_nutrient_grid[cy][cx] * 0.15 * tree.growth_rate_mult, _nutrient_grid[cy][cx])
_nutrient_grid[cy][cx] -= take
uptake += take
```

Each initial sampling square contains twenty-five cells. The squares overlap in twenty cells. The first tree takes fifteen percent of each cell's current value. The second arrives at a patch partly used by the first. Its rule is intact; its starting world is already different.

The two root markers are close together on the field. The branching displays stand apart, enlarged four times so that we can inspect them. Their display positions do not move the roots. Follow the coloured squares back to the soil before mistaking the distance between the exhibits for the distance in the calculation.

Try SEASON. This also begins a fresh comparison, now holding winter steady. Take two turns. The patch sinks, and the uptake readings change. The stems do not branch.

The consumption happened before this test:

```gdscript
if nutrients > 0.05 and _current_season != Season.WINTER:
    tree.lsystem.generate()
    tree.generation += 1
```

Winter refuses the rewrite. It also stops the separate diameter increment. It does not undo the earlier subtraction. A body can remain visibly still while changing the conditions around it. To discover that here, we needed the field as well as the tree. A picture of the crown alone would have concealed the operation.

Press SOIL. For one simulated second, nearby cell values diffuse and replenishment draws them towards the supplied level. No tree takes a turn; the chosen season stays fixed. In winter replenishment is slower. The desk separates these operations so we can follow them. Behind it, the original forest runs them together over time, with five different grammar strategies and the earlier controls.

Return to spring and let the pair reach three generations. Further turns report a generation limit. The limit belongs to this study. It does not tell us that the trees have matured, exhausted their world or found an ideal form. Soil can still change. Even an ending needs its condition read.

We can now ask something more specific of the forest. Which differences came from instructions, which from resources, and which from whose turn came first? The order is a small piece of code, easy to overlook among the branches. It helps distribute a possibility of growth.

There are other schedules we could write: rotate the first turn after each round, or calculate everyone's request before changing the shared field. Neither is supplied by these buttons yet. Each would give us a different experiment. Calling the first arrangement natural would close that opening too soon.

<!-- @ -->

Stay with the retained coral for a moment. Its branching form has another recipe; it is not drawing food from this soil. Similar-looking bodies need not inhabit the same relations. In Living, we turn towards the controls that let us author a body, and ask which possible changes those controls have made available.
