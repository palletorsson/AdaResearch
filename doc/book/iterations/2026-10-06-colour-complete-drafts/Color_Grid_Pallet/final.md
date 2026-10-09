# Find the colour again

<!-- @gridcolorizer -->

Choose a square before you choose a colour. The white outline marks one piece of the floor. On the console, two numbers give its address. X + moves the outline across the floor; Z + moves it along the other direction. Choose a place you will recognise when you come back.

At the pillars, moving the sampler changed its colour. Here you can leave a colour behind.

Press COLOUR. The outlined square turns pink. Another press gives it another of four inks. Stop at one you want to leave here.

Move the outline away. Your colour stays behind, now one square among the others. Each coordinate cycles through five positions. Keep going until the outline comes back to the place you chose. The colour is still waiting.

The white outline has travelled. Your exception has not followed it.

![A pink edit stays at address (10,10) through selection changes and is replaced when RULE runs.](/book-review/doc/book/iterations/2026-09-28-grid-a-colour-left/an-address-keeps-colour.png)

*Write, leave, return, rewrite. The pink square keeps its colour while the white outline moves. RULE replaces that value; the same cube still supports you.*

```gdscript
colorizer.multimesh.set_instance_color(cells[selected], INKS[ink_index])
```

Godot draws these cubes together in a `multimesh`, but each cube has its own colour entry. `selected` holds the two coordinates you chose; `cells[selected]` finds the corresponding cube. This line changes that cube's colour. Moving the outline reads another entry and leaves the previous one alone.

Look from the small swatch beside the controls to the floor. Both receive the stored value. Their size, angle, light and neighbours differ. A matching number does not settle how the colour will meet you. The room where colour needed company has followed us here.

Walk over to your square. You can stand on a value you have just changed.

Return to the console and press RULE.

Your exception gives way to the floor's repeating assignment. The address remains. Walk back to the place you changed: the same cube still supports you. Its colour has been replaced; the ground has not given way.

```gdscript
var colour_index: int = (address.x + address.y) % palette.size()
colorizer.multimesh.set_instance_color(cells[address], palette[colour_index])
```

In this two-coordinate address, `address.y` names the room's z direction. Add the coordinates. `%` keeps the remainder after division by the number of colours in the palette. Another cell can have the same remainder and receive the same colour. Compare addresses (8, 9) and (9, 8) after applying the rule: both sums are seventeen. The diagonal relationships were already inside that addition.

Try PALETTE. The collection changes; the assignment keeps its form. The floor finds another appearance without learning another way to stand.

We could mistake this regularity for a requirement of the grid. Yet you have just made an exception. The cube held it perfectly well. The rule did not return because the exception was impossible. It returned because you pressed a button that wrote across the floor again.

Try to choose a square farther away. X + and Z + bring you back through the same twenty-five addresses. RULE reaches beyond that region, across the interior floor. You can walk to a square whose colour the program can change and whose address the console will not let you choose. The floor carries you beyond the reach of your edits. Why should the program's reach exceed yours?

Each address keeps only its current colour. An edit remains while you look elsewhere, but RULE replaces it and reloading the room starts again. To remember more would require another place to keep what has been overwritten.

<!-- @ -->

Ahead, a spray can is already moving across a canvas. We leave the address with its current value and approach a surface on which marks accumulate. What will that surface keep of a movement after the body has passed?
