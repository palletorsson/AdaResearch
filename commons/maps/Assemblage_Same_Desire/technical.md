# Assemblage — sample, decision, representation

Primary: ten_print_textile, with lesson:true in Assemblage_Same_Desire. The opt-in AssemblageLesson creates a manually stepped 12×12 instance of the same class, with seed 1010 and weaving=false. The original 14×18 automatic textile remains behind it. Six full-size buttons occupy a 3×2 desk. The readout is small, tilted and transparent.

## Cell pipeline

Each cell draws sample=_rng.randf(), then tests sample<odds. A second draw supplies a slight tint variation. This two-draw sequence is retained from the original kernel. Each mesh stores sample and tint as metadata. Rows are stored bottom-first, oldest first. samples() and choices() expose the recorded values in that order.

reinterpret(alphabet,odds) replaces glyph geometry at the same positions using stored samples and tint values. It does not consume RNG state. At fixed odds, all three alphabets preserve the binary choices. At changed odds, the same raw samples can cross the threshold. Diagonals use +/-PI/4 rotations; orthogonals use 0 or PI/2. Blocks encode A/B as a large or small rectangle. Colors track the choice, not the alphabet. The finite-precision randf endpoint and strict less-than comparison are part of the implementation; the fixed review sheet has no sample equal to 1.

The .5 threshold selects each pseudo-random sample independently of neighbouring cells; it does not enforce a balanced count or check connectivity. ODDS cycles .5,.75,1,0,.25 and back. Higher thresholds monotonically admit samples at fixed state. The test checks the .5-to-.75 comparison and both extreme settings for the fixed sheet. Fairness is one useful comparison, not a prerequisite for a mixed pattern. Neither a finite generator nor a small alphabet promises that a pattern will never repeat.

SEED increments the positive seed and restarts the visible record. RESET restores 1010, diagonals and odds .5. HOLD duplicates the bolt geometry and records samples and choices; it replaces its prior witness. Later edits, STEP and RESET leave that held witness unchanged. Shared mesh/material resources are treated as immutable; reinterpretation constructs new resources.

## Rolling window repair

The original build appended top-to-bottom rows, but the scroll queue removed its first row as if it were the bottom. That could let the visible sheet drain before replacement. Build now queues bottom-to-top. step_row removes the oldest row, shifts survivors by row_h and appends one new row. The number of rows and meshes stays bounded: 12×12 in the study, 14×18 in the original. The process timer requests one step after .18 seconds and resets its accumulator; it does not guarantee wall-clock exact throughput under a slow frame. Manual STEP does one row without waiting for that timer.

## Surface and body

The floor drawing reuses the current glyph meshes and colors, mapping row/column addresses onto a .4 m grid. It creates no colliders. The underlying museum floor remains solid for diagonals, orthogonals and blocks. The test walks a DesktopPlayer capsule over two alphabets. Seeing or tracing a route is distinct from computing a connected graph and from physical navigability. No maze solver or procedural collision construction is claimed here.

## Museum restoration

The 19×38 m hall places the study in front of the original 16×14 layout translated by (1,20). The old side partitions open into the new outer aisles; front/back boundary segments remain. Six interior column markers that intersected the restored galleries are removed. The atlas, origin gallery, loom and formal-limit objects are spaced for separate approaches. The original coordinates remain in the archive. The textile token moves to the front study and carries its original automatic loom behind the controls. The Gödel plaque gains a reachable plinth. Museum utilities remain subject to the endless museum's own transport policy.

The baseline instantiated five of the nine authored tokens. Explicit map placement restores the declared collection; pattern_atlas_gallery and mamma_monster_gallery additionally lacked map_ready. Their existing scene paths are now marked ready in pattern_atlas.json. Nineteen atlas plates and six origin-gallery plates retain their maker credits. A BinaryGridWidget guard avoids connecting its cell_changed handler twice when setup has already run before _ready. The loom's spatial controls remain; its desktop demo InfoLabel is hidden only in this hall.

GridSubstrateRunner is retained, but the museum has no GridDataComponent for its ordinary grid-discovery path. Do not describe that token as a verified live floor transformation here. The primary's floor drawing is an explicit, separate surface application. The synthesis stand, dragon bench, formal-limit objects and panel bridge remain independent works.

This hall does not prove a theorem about formal systems, simulate actual woven fiber mechanics or reproduce a textile tradition completely through a shader. The earlier tutorial is archived so its sources and ambitions remain available while unsupported equivalences are corrected. Runtime and browser review are desktop evidence; headset reach, readability, comfort, secondary interactions and Quest timing remain deferred.
