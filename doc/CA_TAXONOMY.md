# Cellular automata, taught in the order the engine needs it

> Tenth sequence through the recipe (2026-08-27). Cheat-code — and the first that is an
> **ABSENCE**: *Godot ships no cellular automaton.* No class, no node, no helper. The
> sequence's real first lesson is what you must BUILD before a rule can run.

June's 21-concept canon was the strongest inherited in the corpus — real concepts, real
truths, a queer-Wolfram reading already written in. It was missing only its foundation,
so this pass **inserted four rungs at source** (`tools/build_ca_concept_map.py`
CONCEPTS, the bespoke builder that owns the file — judgment stays at source):

1. **The grid** — an array of arrays, and the decision that space is countable.
2. **The neighbourhood** — which cells count as "near" is a CHOICE: four, eight, or six,
   and the same rule becomes a different universe.
3. **The rule** — a function from neighbourhood to next state; eight bits for the
   elementary case, small enough to hold and large enough to be a world.
4. **The double buffer** — **time is the part the engine will not give you.** Read the
   old grid, write a NEW one, then swap. Read and write the same array and every cell
   lies to its neighbour. *Every CA bug in history is this bug.*

Then June's phenomena follow, untouched: the 256 rules, 30, 90, 110, Life, Brian's
Brain, Wireworld, Langton, hex neighbourhoods, Lenia, reaction-diffusion, lattice gas,
the Wolfram classes, edge of chaos, 3D, dendrites, caves, stigmergy, textures,
morphogenesis. Live at **localhost:3003/cellularautomata-concepts** — 121 tiles, 25
sections. Truth kept: *"Local rules, global patterns."*

## The super: the_clockmaker_of_rules

A clockmaker's bench for worlds the engine refuses to supply. The four foundation
stations sit on it — a grid of empty pans, three brass neighbourhood stencils (von
Neumann, Moore, hex), a rule drum whose eight levers stand up for the 1-bits of rule
30, and the centrepiece: **two trays, read and write, with a swap crank between them.**

Around the bench, worlds that were genuinely COMPUTED here, not drawn: Rule 30 and Rule
90 each stepped 18 generations by their own bits (the swap performed in code, `cur =
nxt`); a Life glider run four generations so it has visibly travelled; Brian's Brain;
Langton's ant after 220 real steps, its highway emerging from the chaos; a Wireworld
diode with head and tail; a Lenia blob whose cells are fractions. 659 meshes, probe
0 broken. Seated at The double buffer.
