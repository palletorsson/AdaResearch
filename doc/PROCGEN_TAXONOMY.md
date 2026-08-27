# Procedural generation, taught in the order the engine needs it

> Thirteenth sequence through the recipe (2026-08-27). Cheat-code:
> **`PackedScene.instantiate()` + a seed — authorship at arm's length.**

Two rival files again (`procgen`, the bespoke builder's 20 real concepts and 213 tiles,
vs `proceduralgeneration`, a June map-name file whose sections include literal numbers —
"21", "Eight", "Five") — but the alias was already pointed at the good one. The fractals
bug was a one-off. Pure refine: four rungs inserted at source in
`tools/build_procgen_concept_map.py`, before the phenomena.

## The four inserted rungs

1. **The instance** — `PackedScene.instantiate()`: one authored thing, stamped a
   thousand times. The first procedural act is a copy, and the engine's only built-in
   help.
2. **The seed as authorship** — you do not author the world; you author a RULE and a
   seed, and the world is the consequence — a signature you can hand someone, from
   which the whole place unfolds again.
3. **The constraint** — generation is not "anything", it is anything that SATISFIES.
   Adjacency rules, sockets, budgets: the constraint is what makes output usable rather
   than merely novel.
4. **The contradiction** — generation can **FAIL**: the collapse with no legal tile, the
   maze with an unreachable room. The engine has no opinion about whether your world is
   playable; you must check, and be willing to throw the run away.

Then the inherited 20 follow: marching cubes, metaballs, SDF sculpting, WFC, BSP, space
colonization, genetic, agent walks, slime/DLA, reaction-diffusion, Voronoi, Poisson,
mazes, Markov grammars, mesh & shape grammars, higher-dimensional generation, generated
worlds, seed → world. Live at **localhost:3003/proceduralgeneration-concepts** — 222
tiles, 24 sections. Truth kept: *"A world doesn't need an author. Rules and randomness
are enough."*

## The super: the_absent_author

A workshop whose author left, and the work continued. An empty chair pushed back from an
empty desk; on the desk a card bearing only a **seed and a rule**, and everything in the
room unfolds from it: one authored chair-prefab stamped nine times (each instance nudged
by the seed); a tile strip collapsed under real adjacency rules; a maze dug by an actual
recursive-backtracker walker; a computed Voronoi claim map; a Poisson scatter reporting
how many of 22 candidates actually fit; a noise field thresholded into a ridge.

And the exhibit nobody makes: **THE FAILED RUN**, kept on the bench with its red mark —
a collapse that hit a contradiction. Because generation can fail, and the engine will
never tell you. 455 meshes, probe 0 broken, first try. Seated at The seed as authorship.
