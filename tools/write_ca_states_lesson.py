"""Assemble the complete printed lesson from its maintained executable files."""
from pathlib import Path
R=Path(__file__).resolve().parents[1]
S=R/'doc/book/studies/cellular-automata-through-the-hands/CA_ElementaryRules'
M=R/'commons/maps/CA_ElementaryRules'
opening='''# A state that lingers

## Learning elements

- Three cell states: empty, active, fading.
- A three-dimensional address stored in one array.
- A neighbourhood of 26 positions; count only active cells.
- A transition function: the current state changes which answer is possible.
- A synchronous update and an empty outer boundary.
- State, visible surface and colour as separate decisions.

## Follow the cell

We are still in Endless Museum. The small volume and the enlarged neighbourhood show the same running calculation. Gold marks one address. Pick up the black point beside the console; its trigger advances one generation. You can carry the control while walking around a cube that hides another. The console's STEP does the same job.

Press REPLAY. The gold-framed centre begins active, with eleven active neighbours. STEP makes it green: fading. Now it has seven active neighbours. Predict its next state before stepping again. Does enough company make it active, or does its present state prevent that?

## What we carry

The last hall read an old row and wrote a separate next row. We keep that agreement, along with arrays, loops and the PointBody class. An integer now replaces each Boolean: `0` means empty, `1` active, `2` fading. One address still holds one value. A visible green cell holds a value that the active-neighbour count excludes.

The point now carries the step action. Moving it does not edit the cells or select a different address. We keep watching one centre, so its history can be followed without moving the question.

Continue on the existing `PointStudy` node in the museum, saving the row script as a previous working version. Put the two files below together and attach `volume.gd`. Keep the node at unit scale on level floor, with clear space around it; face its positive Z side. The museum already supplies camera, light, player and XR Tools. This construction supplies its own geometry, label and pickable point. No authored scene children are assumed.

Our study is a **7 × 7 × 7 volume with twelve deliberately placed active cells**. The installed work is a 50 × 50 × 50 seeded volume. They share the three-state rule and empty outer shell, but their beginnings and resulting shapes differ. We reconstruct the operation, then return to the larger encounter.

## Give a volume addresses

`index(p)` stores X positions next to each other. Moving one step in Y skips `SIZE` entries; one step in Z skips `SIZE * SIZE`. This is still one array. `Vector3i` keeps the address integer-valued; the drawn position uses metres separately.

The three nested loops in `active_neighbours` visit offsets −1, 0 and 1 on each axis: 27 combinations. Excluding `(0, 0, 0)` leaves 26 neighbours. Face, edge and corner neighbours each count once. Only entries equal to `1` count. This function is called for interior addresses, whose whole neighbourhood fits inside the array.

## One function chooses the next state

| Current state | Active neighbours | Next state |
|---|---|---|
| Empty, 0 | 6, 7 or 8 | Active, 1 |
| Empty, 0 | Any other count | Empty, 0 |
| Active, 1 | 6, 7 or 8 | Active, 1 |
| Active, 1 | Any other count | Fading, 2 |
| Fading, 2 | Any count | Empty, 0 |

`next_state` checks fading first. That is why a green cell with seven active neighbours empties. Moving the neighbour-count branch ahead of the fading branch would change the rule. The function assumes the three valid states listed above and a count from zero through twenty-six.

`evolve` creates a fresh, empty array and fills only its interior. It reads every answer from `old`, then `step` replaces `current`. The outer shell remains zero. Unlike the previous row, these edges do not wrap. Traversing the interior backwards should produce the same result.

## The complete construction — volume.gd

The update functions are the lesson. `make_display` builds its viewing apparatus; `redraw` reads the state without changing it. A gold frame holds the central address. Empty cells are hidden; pink and green cells remain visible. This small version draws all occupied cells, without the installed work's hidden-interior optimisation.

'''
ending='''
## Carry the point — point_body.gd

This is the same small PointBody from the previous hall, unchanged. It contains the sphere and its pickup boundary. The new volume connects its existing action signal to `step`. Release returns the point to its resting place. With a keyboard, Enter steps and R replays the twelve-cell beginning.

'''
tasks='''
## Try a change you can account for

Before running the script, predict the central cell's first two states. The twelve-cell beginning gives it eleven active neighbours at generation zero. Record your prediction, the observed states and the line that explains any difference. The readout always reports the current generation's neighbours, not the count used to produce that generation.

Then replace the twelve-cell beginning with just two adjacent active cells: the centre and one face neighbour. Predict two generations for the whole volume before running it. Keep the rule unchanged. Explain why a visible fading cell does not keep the other one active. This is your own seed, not a change to the museum installation.

Finally, ask the transition function for the next state of an empty cell with seven active neighbours and a fading cell with seven. Their counts match. Explain why their answers differ. A good test checks both cases; a successful screenshot alone does not establish that distinction.

## Return to the larger work

REPLAY returns the installed volume to its own seed. The chosen address `(26, 22, 24)` goes from active with eleven active neighbours, to fading with seven, to empty with five. Its surrounding cells keep evolving too. The gold frame keeps the question at the same address.

VIEW changes the colours without advancing a generation. DRAWN can be smaller than ACTIVE plus FADING because the installed renderer hides occupied cells enclosed on all six faces. That is a drawing decision; the state array still includes them. The six-face visibility test and the twenty-six-neighbour update answer different questions.

RUN, the twenty-step budget and the height-colour view belong to the installed observation apparatus. Our reconstruction needs only a step and a replay. Keep them distinct from the rule you have just written.

Carry onward a transition function that distinguishes presence from participation, and an update that gives every cell the same old world. In **CA_GameOfLife**, a retained generation will become a layer of a structure. Here we replace the array; there we will also keep a history we can approach.
'''
text=opening+'```gdscript\n'+(S/'volume.gd').read_text(encoding='utf-8').rstrip()+'\n```\n'+ending+'```gdscript\n'+(S/'point_body.gd').read_text(encoding='utf-8').rstrip()+'\n```\n'+tasks
(M/'tutorial.md').write_bytes(text.encode('utf-8'))
print('Full lesson assembled with exact source blocks.')
