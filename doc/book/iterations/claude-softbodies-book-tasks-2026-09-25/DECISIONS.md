# softbodies — the 24 Sept book tasks applied, 25 September 2026

Tasks `book_softbodies.001`–`.014` (the 24 Sept tasks; .015–.022 were the Nature of Code series, closed earlier today): thirteen applied and closed, one left open with a note. Walking the spine from its far end (forum 260925-tvljg).

| task | hall | what landed |
|---|---|---|
| .001 | Topology_Entropy_Morphogenesis | **code**: `_apply_level` in entropy_morphogenesis_vr.gd now writes `threshold_center = 0.0` for `minimal` once `_built` is true, so the desk's LEVEL cycle closes and the readout moves on every press; at build it still writes nothing, so a placement keeps its exported value. Compile-checked in one boot. The task's first option (the desk, soft_workshop.gd) was not taken because that file is untracked in git, another writer's uncommitted work |
| .002 | Cloth_Physics | the rail observed first (the map opens the bodies on the rail), then LANDING and the pan's two walls |
| .003 | Cloth_Physics | "the bodies hanging from it will know" |
| .004 | Playground_of_Joy | how a hand squeezes: put a hand in and hold the grip; SQUEEZE scales the push, its third setting turns it off |
| .005 | Obsticals | "Yet the floor that carries you through this hall does not deform" |
| .006 | Obsticals | STIFFNESS and RESET PHASE named |
| .007 | Reaction_Diffusion | `[^turing]`: Turing 1952, Gray and Scott 1984, Pearson 1993 (the presets are points on his map; the excerpt is his discretised form) |
| .009 | Soft_Body_Deformation | the previous sequence received: "selecting, branching, carving, sampling and copying" |
| .010 | Obsticals_Part2 | "Super Soft" for "Jelly" (Part 2 holds tests 13–24) |
| .011 | Topology_Entropy_Morphogenesis | "too narrow for your body" |
| .012 | Reaction_Diffusion | 100 STEPS named |
| .013 | Affect_Theory | `[^haeckel]`: the Radiolaria plates as a drawn vocabulary, not a measured organism |
| .014 | Playground_of_Joy | the wandering agent named for what it is, in a sentence true whether it wanders or stands |

Left open:

- .008 (Playground_of_Joy): a three-panel still of the vessel at 40 / 200 / 400 steps needs a capture sweep with a fixed camera; not run in this pass.

Verification: every replacement matched exactly once; footnotes defined; fences balanced; endings preserved per file (Cloth and Affect LF, the rest CRLF; no mixed files); the morphogenesis script compiles.

Disclosure: SoftBodies_Obsticals as found is an uncommitted rewrite from 15 September (55 lines against HEAD, never committed by anyone); it lands here whole: SoftBodies_Obsticals (55 lines). `before/` is the tree as found, so the diffs beside it are this pass alone.
