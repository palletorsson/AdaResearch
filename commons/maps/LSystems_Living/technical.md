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


## Reconstructed tutorial — 9 October 2026

Four complete files: design.gd, living.gd and byte-unchanged PointBody/line_skin from Competition. The parallel rewrite is unchanged; its explicitly larger 32,768-symbol budget permits the bounded recipe before a separate 200-command reader cap. The source's opposite-branch subset uses three raw genes: Depth 2..10, Forks 1..8, Angle 15..90. Depth halves then rounds/clamps 2..5; Forks rounds/clamps 2..5. F produces S and bracketed branches; S produces FF. The full bare 3D reader includes roll, saved frame/length, 1.2m initial steps and .68 length taper. No tropism, leaf/root/twist generator or tapered bark is implied by this reduction. Its reader accepts internally generated sentences, not arbitrary unvalidated input.

The familiar black point changes the selected gene across 40 horizontal detents; first pickup latches the current position without editing. Trigger keeps a recipe. Keyboard G/arrows/H/P/R gives the same study operations. Independent editing/held/planted dictionaries rebuild all visible specimens. Those records live only in the running scene. The original artifact instead retains geometry plus DNA and PLANT also exports an independent Engine metadata resource for another consumer. The tutorial states this boundary.

Production addition: LivingHand at the existing console's front rail, local y1.18, z2.55, across .8m. It delegates to set_gene_normalized and HOLD, retaining the source's.3s debounce and flush-before-keep. All eight original genes, six buttons, six authored works and both portals remain. Core sculptor, TreeMorphology, map and sequence hashes match the captured baseline.

25 native printed-program checks pass: 108 production parameter/full-sentence comparisons, threshold 4.8/5.0, snapshot independence, bounded commands, exact turtle examples, supplied XRTools poses under a translated/rotated host. The full student change START.angle 30->45 executes and changes endpoints without changing its sentence. Aliased snapshots and flooring instead of rounding are deliberately detected. These checks do not establish full production mesh equality across the whole parameter space.

33 native museum checks pass, including eight capture-camera checks, six desktop pointer effects, supplied hand pickup/movement/action/release, identical source geometry below the threshold and changed geometry at 5.0, kept specimens/export independent of later edits, 365 supported outer-route samples and valid entry/exit records. The first room probe grabbed immediately after RESET, before the next physics tick had parked the point, and therefore supplied no actual movement. Its three rejected assertions and probe are preserved; waiting for the parked state fixes the test, without changing production logic. A rear camera initially faced the dividing wall; the final capture moves inside the existing rear room.

Four baseline and eight final native images are supplied. The learner program is photographed temporarily at the source host, with the original primary hidden and restored afterwards; its plinths/console disappear visually but retain collision. The diagram keeps the source display heights and is not a second installed artifact. The front comparison and side bypass are clear. Rear terrain dominates the small companion works, paper panels appear blank in this capture, and elevated fixtures obscure parts of the oblique view. Retained scene nodes do not establish visual acceptance of that older collection; it needs a separate visibility pass. Native logs retain pre-existing UID/renderer diagnostics but no SCRIPT ERROR/Parse Error. No physical-headset, Quest-performance, full-portal-traversal or independent ghost-student claim.

Review: doc/book/iterations/2026-10-09-living-a-design-kept/index.html. Six of eight L-systems halls reconstructed; Shape Grammars next.
