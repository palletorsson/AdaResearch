# Find the colour again

<!-- @gridcolorizer -->

Choose a square before you choose a colour. The white outline marks one piece of the floor. On the console, two numbers give its address. Press X +. The outline moves across. Press Z +. It moves along the other direction. The floor stays where it was.

At the pillars, a position supplied a sample. Here you can write something back.

Press COLOUR. One cell receives pink. Press again and it receives another of the four available inks. Find a colour you want to leave there. Move the outline away. Keep going until the address returns: each direction cycles through five positions. The colour is still waiting at the address you left.

The white outline has travelled. Your exception has not followed it.

```gdscript
colorizer.multimesh.set_instance_color(cells[selected], INKS[ink_index])
```

One line writes to one instance. `selected` holds the two coordinates you chose; `cells` connects that address to a cube in the room's drawing buffer. Moving the selection changes what the console reads. It does not carry the stored colour from cube to cube.

Look from the small swatch beside the controls to the floor. Both receive the stored value. Their size, angle, light and neighbours differ. A matching number does not settle how the colour will meet you. The room where colour needed company has followed us here.

Now press RULE.

Your exception gives way to the floor's repeating assignment. The address remains. Walk toward the place you changed: the cube still supports your body. There has been no new geometry, no hole, no repair of the route. What changed was which colour that position received.

```gdscript
var colour_index: int = (address.x + address.y) % palette.size()
colorizer.multimesh.set_instance_color(cells[address], palette[colour_index])
```

In this two-coordinate address, `address.y` names the room's z direction. Add the coordinates. `%` keeps the remainder after division by the number of colours in the palette. Another cell can have the same remainder and receive the same colour. Compare addresses (8, 9) and (9, 8) after applying the rule: both sums are seventeen. The diagonal relationships were already inside that addition.

Try PALETTE. The collection changes; the assignment keeps its form. The floor finds another appearance without learning another way to stand.

We could mistake this regularity for a requirement of the grid. Yet you have just made an exception. The cube held it perfectly well. The rule did not return because the exception was impossible. It returned because you pressed a button that wrote across the floor again.

The apparatus has its own narrow permissions. Five positions in each direction can be selected here. Four inks can be assigned. The rule reaches farther, across the interior floor. Why should its reach exceed yours? These limits are choices in this lesson's code; the experiment makes them available to question. A later version could let an exception travel, protect it from a rewrite, or change the rule itself. None of those possibilities happens merely because we can name it.

There is no history stack behind this console. An edit remains while you look elsewhere, but RULE replaces it and reloading the room starts again. To remember more would require another place to keep what has been overwritten.

<!-- @ -->

Ahead, a coloured ball is already moving across a canvas. We leave the address with its current value and approach a surface on which marks accumulate. What will that surface keep of a movement after the body has passed?
