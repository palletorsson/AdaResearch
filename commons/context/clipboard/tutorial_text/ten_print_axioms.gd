extends Node

# Tutorial content file
# Edit using the Tutorial Text Editor plugin

var text = """[center][font_size=28][b]10 PRINT[/b][/font_size][/center]
[center][i]Complexity from Simplicity[/i][/center]

**10 PRINT CHR$(205.5+RND(1)); : GOTO 10**

This single line of BASIC code, written for the Commodore 64, generates the infinite maze you see before you.

[hr]

[b]The Algorithm[/b]

[color=yellow][b]How it works:[/b][/color]
[code]
1. Flip a coin (Random 0 or 1)
2. If 0: Print "/" (diagonal forward)
3. If 1: Print "\\" (diagonal backward)
4. Repeat forever
[/code]

It is trivial. A binary choice. A slash or a backslash.
Yet, when repeated, it creates:
- **Mazes**
- **Corridors**
- **Dead ends**
- **Islands**

**Emergence:** The structure is not programmed. It emerges from the accumulation of simple, random choices.

[hr]

[b]The Screen as Void[/b]

On the Commodore 64, the screen was a grid of 40x25 characters. The code fills this grid, line by line, scrolling infinitely.

This "maze" has no architecture. It has no walls, no floor, no physics. It is purely **surface**—a texture of characters floating in the digital void.

We have projected this 2D texture into 3D space, giving it height and collision. We have trapped an **Ant** inside it.

[color=yellow]Watch the Ant.[/color] It seeks an exit that doesn't exist, navigating a maze that was never designed to be solved, only to be seen.

[hr]

[b]Binary vs. Fluid[/b]

The fundamental atom of this world is a **binary switch**:
[color=cyan] /  vs  \\ [/color]

It is a rigid, either/or choice. But the **aggregate**—the maze itself—is fluid, organic, and complex.

**Queer Critique:**
Strict binary systems (gender, logic, walls), when iterated and accumulated, can produce **non-binary spaces**. The "maze" allows for movement, flow, and complexity that the individual binary components cannot predict.

We are trapped in binary choices, yet we weave them into complex lives.

[hr]

[b]The Glitch of Time[/b]

In this simulation, the walls are not static. **Every second, a wall rotates.**
The binary choice flips. `/` becomes `\\`.

The maze is not just infinite in space, but unstable in time. The path you see now will not exist in a moment.
**Memory is useless here.** You must navigate the flux.

[hr]

[color=cyan][b]Summary:[/b][/color]
10 PRINT demonstrates how complexity emerges from simple rules (Cellular Automata). A random binary choice (`/` or `\\`) creates emergent structures (mazes). It highlights the tension between rigid binary logic and fluid emergent space.

[hr]

[color=orange][b]Next:[/b] Noise[/color]
We leave discrete randomness behind. We enter the world of continuous, smooth chaos.
"""
