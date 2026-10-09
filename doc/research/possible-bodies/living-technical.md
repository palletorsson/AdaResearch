# Living — genes, compilation and snapshots

Primary: genetic_tree_sculptor, with lesson:true only in LSystems_Living. It retains its original eight-slider rack, RANDOM and PLANT. Other placements keep their ordinary scene behavior. TreeMorphology.build gains an optional fifth render_seed argument; the default -1 retains per-instance randomness. The lesson fixes this seed at 481 so rebuilds can compare geometry without unrelated leaf/material/root random draws changing the result.

## Follow the data

The lesson starts with raw segments 4, symmetry 2, branch_angle 30, branch_decay .7, leaf_density 0, part_curve 0, part_twist 0, phyllotaxis .5. Scale 2, part_length 2 and part_width .3 make the bare branches legible; root_type and inflorescence are zero. The remainder comes from CritterDNA.random_kingdom(0,481). This is a chosen study specimen, not a new default for every sculptor.

GENE selects one of eight genes. LESS/MORE use a normalized .025 grid and the same set_gene_normalized method as the original slider input. Depth spans raw 2..10. Its first five increments are 4.2,4.4,4.6,4.8,5.0. The first four compile to two rewriting generations; the fifth compiles to three. Geometry is unchanged before this threshold. Edits debounce for .3 seconds; HOLD and PLANT flush a pending edit before taking a snapshot.

TreeMorphology maps generations=clampi(roundi(segments*.5),2,5) and fork_count=clampi(roundi(symmetry),2,5). branch_angle supplies turtle turn degrees. branch_decay controls radius taper and length_taper=branch_decay*.9+.05. part_curve*.3 lowers segment endpoints; this is a downward displacement, not environmental tropism sensing. Arrange selects three authored rotation recipes. Their roll counts still use branch_angle, so the names spiral/opposite/whorled must not be read as guarantees of exact botanical angles.

The axiom is F. F rewrites to S followed by fork_count bracketed rotated F branches. S rewrites to FF. F advances a full segment and tapers both radius and length; S advances .6 of the current length and reduces radius by .95. Brackets store/restore the turtle's state. A requested segment shorter than .001 m emits no branch mesh. The lesson readout counts F+S in the whole sentence and separately states the LOD2 budget of 200 drawing commands. This is not a mesh count: the interpreter breaks on that command budget, and tiny requested segments can produce no geometry. The entire sentence is generated before the budget is applied.

## Hold and place

HOLD duplicates the built preview geometry and deep-copies its DNA into one comparison slot. PLANT deep-copies the DNA resource into Engine metadata sculptor_tree_dna, emits another independent snapshot and copies the currently built geometry onto the local floor pad. Later editing cannot mutate those snapshots. Repeated HOLD or PLANT replaces its respective slot; RESET changes only the editing specimen. Geometry copies share immutable mesh/material resources; this lesson never mutates those resources in place. Preview rebuilding constructs new resources.

The local placed tree has visual branches without colliders. Plinths and the museum floor provide collision. It does not consume soil, reproduce or remodel the hall. The older branching_projectile consumer duplicates the exported DNA, mutates it, rescales it, builds at LOD1 and removes its tree after about thirty seconds. PLANT does not change catalyst mode or promise exact permanent copies anywhere in the museum.

The exported resource remains available when its sculptor or hall unloads. A static callback on the application root's tree_exiting signal removes the Engine metadata before script shutdown. Without that cleanup, the rendered review reproduced an engine crash on exit after export; explicit early release removed the crash. The fix belongs to the runtime, not a special test-only cleanup.

The optional pressure setting remains: a seeded greedy search mutates exposed genes and compares a weighted score. That score reads genes, not measured crown height, light, soil or collision. pressure:none is used by this lesson. RANDOM samples DNA; it is not itself a selection experiment.

## Space and retained studies

The museum is 19×36 m. The old 13×12 terrain survives at offset (3,20), including raised cells and voids; the old teleporter void is filled and the retained coral has support over its previous void address. The sculptor moves to (9,8). The five secondary placements retain their relative map coordinates: lsystem_tree, branching_coral, living_paper_fern, living_paper_tree, living_paper_dragon. The map floor is authored JSON. No runtime connection makes it grow from the sculptor's grammar.

The living-paper fern is an L-system drawing, despite an older Barnsley label; do not call it the affine IFS. Those paper cartridges and the coral/tree kernels are retained unchanged. Their existing interactions need separate headset review.

Runtime checks use the actual museum, DesktopPlayer pointer and collision capsule. Headset reach, readability, comfort and Quest performance remain unverified. Previous maps, sources and manuscripts are archived in doc/space/lsystems-living-2026-09-14/before.
