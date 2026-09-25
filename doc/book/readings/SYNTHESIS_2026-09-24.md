# Across the book — the spine read on 24 September 2026

24 sequences, 196 chapters, 162,872 words, read in spine order as a book whose reader is the headset visitor. One reader per sequence proposed improvements; a skeptic refuted or amended them. Eight sequences have been through the skeptic (primitives, transformation, array_tutorial, color, change, forces, formfinding, cellularautomata); the other sixteen carry their reader's proposals marked *not yet checked*, because the run was paused to save the usage window. Primitives was also read by hand and checked hall by hall.

**384 tasks**, by kind: prose 134 · encounter 64 · vr 49 · structure 41 · footnote 27 · handover 26 · code-claim 24 · figure 19. By effort: 267 one-sentence fixes, 95 paragraph or config edits, 22 that need code, a figure or a walk.

## What recurs

**1. The book still talks to a desktop.** 29 tasks. "On desktop it follows the walker" (Point_Lines, twice in Point_Line_Grid), desktop flight keys in Tutorial_3D, three figures that show the desktop HUD (Tutorial_Tiling_Walls), "the desktop body's collision capsule is sixty centimetres across" told to a headset body forty centimetres across (LSystems_Architecture), "the recorded desktop comparison" as the source of numbers (FormFinding), a desktop test harness in a closing paragraph (PG_Caves_Mazes). The rule now on record: VR is the primary goal, desktop is only for visual tests; these sentences move to the technical companions.

**2. Handovers that name a file, promise a future, or send off twice.** 17 tasks. Trans_Introduction and Trans_Translation hand forward by map ID ("In Trans_Rotation, the turn…"); CA_EdgeOfChaos names Fractal_Recursion as an identifier; Noise has a double send-off because Lab_Path is skipped by the museum. All seven swarmintelligence chapters and six of eight graphtheory chapters end on "a future experiment", so the last movement before each exit is a promise about a room that does not exist.

**3. Works standing in the hall that the chapter never mentions.** 15 tasks, and many more noted without a task. The forge machine is the first work past the door in FormFinding_Forge; four comparison works stand behind the Descent lab with no words; a cyan sphere wanders the Array hall removing cubes every few seconds in a chapter about what can happen at an address; a vowel board repeats "right here, right now" every three seconds in Wavefunctions_Bernini. Silence about furniture is fine; silence about a work that acts on the visitor is not.

**4. Numbers and excerpts that drifted from the code.** 24 code-claim tasks. Sixteen cubes "hold the intervening values" but include both endpoints (Color_Walls); "MEET empties by generation 24" empties at six (CA_BeyondBinary); Change_Intro says "Return to MID" but RULE cycles MID → RIGHT → LEFT; FormFinding_Relaxation invites you to walk through a vessel that now has a collider; a two-backtick code fence in Crisis_Synthesis turns the rest of the chapter, three footnotes included, into one monospace block.

**5. The museum's colonnade.** 5 tasks in three sequences: piers stamped into Random_Remove's apron and Random_Entropy's glass field, one enclosing the changed address in CA_EdgeOfChaos, two Boolean halls that should refuse the colonnade. `piers: false` is set in two maps and takes effect only when the plan is re-run.

**6. Directions the visitor cannot read.** "The eastern passage" (Trans_Pit), compass words in WaveFunctions_Sine_Space, an orientation cue for a hinged section (Tutorial_Tiling_Walls). The visitor has left, right, ahead and back, and what they can see.

**7. Chapters that change shape.** Tiling has no titles and no figures while Color before it and Change after it have both; Lab_Path opens without a heading, mid-thought; AdvancedLaboratory_Lab_Equipment_Simulation runs 1,677 words with five encounters and no heading; LSystems_Shape_Grammars is 40–75 % longer than its neighbours. Primitives' headings run from 0 to 7 per chapter.

**8. Cadences the reader learns to predict.** "It does not tell us where to stop / Geometry does not decide the use" a dozen times across primitives; the Forces halls close on the same limits paragraph (stall cap, sample count, frame exit) in the same order until it reads as a datasheet; the "future extension" endings above.

**9. Names withheld.** Rule 30/90/110 throughout Cellular Automata with no mention of Wolfram or how the 256 rules are numbered; Reynolds' three rules unattributed in Boids; the 1955 book of random digits unnamed in Random_Definition.

## Where the encounter work is

64 encounter tasks: randomness 12 (the handback's open items: the die's physics, the arena's piers, the ruin that does not wait, the console that may hide its plate), cellular automata 8 (a pier on the changed address, three works costing 5–8 ms a frame, a floor label facing the wrong way), boolean_surfaces 6, noise 5, swarmintelligence 4, machinelearning 4, isosurfaces 3, foundationscrisis 3, qfeplaboratory 3. Trans_Pit's "middle route" is nine fire cells. Portals' Achilles rail runs through the ring instrument.

## How to work it

- `/book-tasks/review` shows each chapter with its comments under the paragraph they quote: fix, comment, or skip with a note.
- `/book-tasks` lists everything with a *fix list* filter; each task links back to its paragraph.
- Decisions and notes are written into `doc/tasks/book_<sequence>.json`; `git diff doc/tasks` shows them.
- The sixteen unchecked sequences can be verified a few at a time by resuming the paused workflow (finished agents replay from cache, so only the missing skeptics run).
