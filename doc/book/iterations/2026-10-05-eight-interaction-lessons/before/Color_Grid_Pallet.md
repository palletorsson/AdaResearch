# Find the colour again

**Learning elements — proposed focus**

*The labels below set the revision focus; the existing lesson still needs alignment.*

- Classes
- Instance state
- Methods
- Palette indices
- Addressed assignment

1. Read the two-coordinate address on the console. Follow the outlined floor cell.
2. Press X +, then Z +. Notice which direction each changes. Each coordinate wraps through five positions.
3. Press COLOUR to assign an ink. Move away through five X steps and return. The edited colour stays at its address.
4. Walk to the edited square and stand on it. Return to the console and press RULE. The colour returns to the coordinate-based assignment; the same floor still supports you.
5. Press PALETTE. A different collection supplies the same assignment rule.

The selected coordinate maps to an actual room-floor instance. This room does not infer cell coordinates from a square instance count: stacked walls and gaps make that inference unreliable.

```gdscript
colorizer.multimesh.set_instance_color(cells[selected], INKS[ink_index])
```

That write changes one instance. The rule visits all mapped floor cells:

```gdscript
var colour_index: int = (address.x + address.y) % palette.size()
colorizer.multimesh.set_instance_color(cells[address], palette[colour_index])
```

In this Vector2i, y stands for room z. The remainder chooses the palette entry. Equal remainders give different cells the same colour.

Compare the scope of the two actions. You can edit twenty-five addresses; the rule reaches the interior floor. What would need to change to let your exception survive a rule pass?

Follow the current value into Color_Paint, where successive marks can accumulate on a surface.
