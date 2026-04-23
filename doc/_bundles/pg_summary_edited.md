<<<ADA_BUNDLE>>>
sequence: proceduralgeneration
file: summary.md
maps: 8
skipped_passing: 0
created: 2026-04-23T19:18:34
only_failing: false
diff_mode: false
with_context: true
<<</ADA_BUNDLE>>>

<<<MAP: PG_Genetic_Evolution>>>
# PG Genetic Evolution — Summary

PG_Genetic_Evolution opens the Procedural Generation sequence. It stages creature evolution as the sequence's first generative strategy: no designer, no explicit rules, only a population under selection pressure and the bodies that result.

A sunken arena takes up the centre of the room. Inside it, a small population of creatures is born with random body plans — random limb counts, random joint positions, random weighted behaviours. Most cannot move. A few flop forward. A few thrash sideways. A fitness function scores each creature on how far it travels from the spawn point within a short time window, and the top performers are selected to breed.

Breeding is visible on a side panel: two parents contribute genes, a small mutation is applied, and a new body plan is assembled. The next generation drops into the arena. Over many generations, the population improves, and the kinds of locomotion that win the fitness test settle into clear categories — rolling, hopping, shuffling — each reached by a different lineage.

Within the sequence, Genetic_Evolution argues that structure can arise from selection alone. L-Systems in the previous sequence required explicit grammar; this one requires only variation and culling. PG_Space_Colonization will next replace selection with spatial hunger.

<<<MAP: PG_Space_Colonization>>>
# PG Space Colonization — Summary

PG_Space_Colonization is the second map in the Procedural Generation sequence. It grows a tree without using a grammar. Instead, the space is seeded with scattered attractor points, a small seed is dropped at the base of the room, and branches reach outward toward whichever attractor is nearest.

The algorithm is visible as it runs. Each branch tip samples the attractors within a given radius and extends a short segment in the averaged direction of those attractors. When a segment gets close enough to an attractor, the attractor is consumed and removed from the field. New tips sprout from the growing branch and repeat the process, so the tree's shape is determined by where the attractors happened to be.

Three controls change the outcome. A density slider changes how many attractors are scattered. A kill-radius slider decides how close a branch must get before an attractor is consumed. A new-seed button re-scatters the attractors and re-runs the algorithm, so the learner can watch several different trees grow from the same rule under different spatial conditions.

Within the sequence, Space_Colonization extends the claim of the previous map: structure can come from the geometry of the environment rather than from an author. PG_Percolation_Network will next turn to connectivity.

<<<MAP: PG_Percolation_Network>>>
# PG Percolation Network — Summary

PG_Percolation_Network is the third map in the Procedural Generation sequence. It demonstrates percolation — the phase transition at which a random grid suddenly becomes connected from one side to the other. A large grid covers the floor; each cell fills with a probability set by a slider at the entrance.

At low probabilities, the grid is sparse. Occupied cells scatter in small clusters that touch no edge of the arena. Raising the probability thickens the clusters; they grow, merge, and eventually one of them spans the grid. The threshold at which that spanning event becomes likely — about 59.27 percent for a 2D square lattice — is marked on the slider, and crossing it produces a clear visual switch from disconnected islands to a continuous path.

A highlight mode colours the spanning cluster so the connected path is easy to follow. A side panel reports the largest-cluster size as a function of the fill probability, so the phase transition is legible as a curve as well as a visual effect.

Within the sequence, Percolation is the connectivity chapter. The previous two maps generated structure by growth; this one generates structure by threshold. PG_Branching_Growth will next put two growth paradigms side by side.

<<<MAP: PG_Branching_Growth>>>
# PG Branching Growth — Summary

PG_Branching_Growth is the fourth map in the Procedural Generation sequence. It places two branching strategies side by side in one room so the learner can compare them: explicit rule-based branching on one side, noise-driven organic growth on the other.

On the rule side, a seed grows upward through deterministic forking. At each step, the current tip splits into two shorter segments at a fixed angle, and the process recurses until the branches reach a minimum length. The result is legible and repeatable: given the same parameters, the tree grows the same way every time. A bench exposes the branching angle, the length scaling, and the recursion depth.

On the noise side, a field of 3D Perlin noise fills the space, and growth follows the field lines — each step moves in the direction of the steepest gradient within a tight radius, then samples again. The resulting branch pattern looks organic: bends, widenings, unexpected merges. A separate bench adjusts the noise frequency and the step size.

A panel between the two sides draws attention to the convergence. Different algorithms arrive at similar-looking structure, which suggests that branching is less a design choice than an attractor in the space of growth rules.

Within the sequence, Branching_Growth is the comparison map. PG_Caves_Mazes will next pivot from additive to subtractive generation.

<<<MAP: PG_Caves_Mazes>>>
# PG Caves Mazes — Summary

PG_Caves_Mazes is the fifth map in the Procedural Generation sequence. It turns to subtractive generation — carving navigable interiors out of solid mass — and stages two strategies on either side of a central wall.

The left side carves a cave. A random walker starts at a single point and staggers through the block, removing cells as it moves. Each step is independent; the walker has no plan. Over time, the removed cells form a meandering passage with uneven widths and occasional dead ends. The cave feels natural because it was not designed; it was eroded.

The right side builds a maze. A deterministic algorithm partitions the block into a grid, selects a spanning tree over that grid, and opens the cells connected by tree edges while leaving the rest as walls. The result is a corridor network that always has exactly one path between any two points, because a spanning tree is acyclic. The maze feels engineered because it was.

Sliders on each side expose the parameters: walk length and step size on the cave side, grid resolution and branch bias on the maze side. A comparison panel between the two sides notes the shared feature — both produce navigable voids in solid mass — and the divergent character that the choice of algorithm enforces.

Within the sequence, Caves_Mazes is the subtractive chapter. PG_Sculpted_Forms will next return to additive strategies by stacking rather than branching.

<<<MAP: PG_Sculpted_Forms>>>
# PG Sculpted Forms — Summary

PG_Sculpted_Forms is the sixth map in the Procedural Generation sequence. It stages accumulation as a generative strategy: piled cubes, arced domes, and laminated membranes, each built from simple repeated operations rather than from branching or carving.

A mound of cubes rises in one corner. Each cube arrives from above and settles on the existing pile, finding whatever support is locally available. No plan chooses the pile's final shape; it emerges from the stacking rule and the order of arrival. Shifting the drop point changes the mound's slope. Removing a single cube near the base can collapse the upper structure in a visible chain.

A dome in the next corner is drawn with a different rule: each segment is placed at a small angular step from the last, and the curvature of the rule determines the dome's radius. Raising the angular step tightens the dome; lowering it flattens it. A small gallery of alternate rules shows barrel vaults, pointed arches, and shallow caps derived from the same principle.

A third station layers membranes. Thin curved surfaces fold over one another, each new layer offset from the one below. The layering rule is an additive geometric operation, and stacking enough of them produces a thick, curved volume.

Within the sequence, Sculpted_Forms is the architectural chapter. PG_Mirrored_Patterns will next finish the sequence with symmetry and rhizomatic growth.

<<<MAP: PG_Mirrored_Patterns>>>
# PG Mirrored Patterns — Summary

PG_Mirrored_Patterns is the seventh and final map in the Procedural Generation sequence. It combines three threads from earlier sequences — cellular automata, symmetry operations, and non-hierarchical branching — into a synthesis room that treats pattern as a generative phenomenon in its own right.

On one side, a cellular automaton is reflected across a vertical axis every generation. Each time the rule fires, the left half of the new row is computed by the rule, and the right half is a mirrored copy. The output becomes kaleidoscopic: ordinary CA texture on the left, its mirror on the right, and together a symmetric pattern that neither half would produce alone.

On the other side, a rhizomatic maze spreads across the floor. Rather than a tree with a root, the maze branches in every direction without a centre. Any cell can spawn a new passage; any passage can merge with another. The result is a labyrinth with no primary direction, no canonical route, and no clear boundary between interior and exterior.

A panel between the two sides puts both claims in one sentence. The first half argues that local rules plus symmetry produce global ornament; the second argues that growth without hierarchy produces navigable space without authorship. Within the sequence, Mirrored_Patterns closes the generative arc and hands the learner back to the Lab.

<<<MAP: Chamber_ProcGen>>>
# Chamber ProcGen — Summary

Chamber_ProcGen is the catalyst chamber for the Procedural Generation sequence. It runs the sequence's central claim — that structure can arise from rules rather than design — through the player-creature relationship. The creature is a bricoleur golem, and it rebuilds itself from whatever is nearby.

The chamber is small and cluttered. Loose geometry lies scattered across the floor: blocks, rods, broken pieces of older artifacts. The golem moves through the clutter, picks up fragments, and attaches them to its body. When the learner strikes the golem, pieces fall off — and moments later, the golem retrieves them and re-attaches them in a slightly different configuration. The golem cannot be destroyed in the ordinary sense; each strike produces a new body.

The science screen on the wall labels this behaviour as bricolage. It shows the golem's current body as a small graph of connected parts and tracks how the graph mutates with each strike. A second panel tracks the learner's strikes as training signal: which parts are targeted shape which parts the golem prioritises in the next rebuild.

Within the sequence, Chamber_ProcGen turns destruction into reconstruction. The chamber hands the learner back to the Lab with the procedural-generation posture intact: no finished form, only ongoing composition.
