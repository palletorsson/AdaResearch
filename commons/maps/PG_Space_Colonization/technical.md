# Space Colonization — assignment, eligibility and support

The existing space_colonization_algorithm is the sole primary. The opt-in museum token is `space_colonization_algorithm:180#lesson:true`. colonization_museum.gd installs colonization_lesson.gd and hides/disables the old UI and its collision shapes. Ordinary placements keep the existing programmatic 3D UI and the original TIPS policy. The old Control attachment was replaced with Node3D to match SpaceColonizationUI.gd; the UI script itself is unchanged.

## Reusable kernel and explicit policy

SpaceColonizationAlgorithm.gd retains the original grow_iteration body as _grow_tips_iteration. Each attraction point chooses its nearest eligible leaf strictly inside influence_distance. A point at or inside kill_distance is removed from the active list. Other assigned points contribute unit directions. Each influenced leaf adds one successor in the normalized sum direction and is replaced by that successor. With one root this cannot fork. The legacy kernel can produce a zero-length successor when opposing requests cancel completely; it is preserved for comparison rather than represented as a universal growth model.

The new decision_snapshot exposes eligible sites, target assignments, accumulated directions and reached indices without advancing the state. Under NETWORK, all earlier nodes remain eligible. _grow_network_iteration reads one unchanged generation, removes reached points, then adds at most one child per eligible site. Zero sums and already occupied proposed positions are skipped. Every child has one parent; no joining operation creates cycles. Older sites can produce another child on a later generation, so forks become possible. The name NETWORK does not certify a looped network.

The wrapper grow_iteration reports a budget or a no-growth reason. Ordinary placements have node_budget 0 (no additional node cap) and retain the original iteration setting. The museum study uses node_budget 192, max_iterations 60, segment_length .5 m, influence_distance 8 m and kill_distance .32 m. One-root TIPS advances one node per step; NETWORK enforces the node cap during additions. Parent/child reference cycles are broken when discarded and on exit.

## Fixed fields and controls

The three fields contain 3, 8 and 96 deterministic positions. The opening positions are (-2,3,0), (2,3,0), (0,5,0); with root zero the first step is (0,.5,0). The second field is an explicit asymmetric eight-point array. The third uses four heights, three rings and eight points per ring, with declared sine offsets to break rotational balance. No shared random seed is changed by the lesson.

STEP performs one generation. FIELD cycles fields and restarts the origin while preserving the policy. POLICY toggles TIPS/NETWORK and restarts the same field. HOLD copies node positions, parent indices and depths into a separate witness, displayed at .45 scale and retained across resets. A later HOLD replaces it. RESET restores field zero and TIPS, leaving the witness. RULE toggles the explanation card. The six physical controls share one compact 3×2 console and a small inclined translucent readout.

Rendering shows the actual node/parent record as constant-width cyan segments, so branch thickness is a display choice here. Unreached points are pink; reached points remain small/dark. One eligible site's assignments are shown at a time to keep the canopy legible. Gold unit-direction lines, fine pink target connections and the white normalized half-metre resultant preview the next decision. This is a preview, not a stored historical explanation. The original model is hidden; its cylinder builder is reused. Generated branches and points have no colliders.

## Floor ownership

The earlier 8×14 structure remains at offset (4,18) in a 19×36 surround. Its four numeric height-3 cells are two-metre decks under wall_height 4. All 43 raw zeros remain zeros: 42 former specimen-void cells plus one old teleporter hole. Explicit map_info.museum.floor_cells supply museum support because the relocated specimen supplies none. This decision does not redefine zeros in other halls.

A closed convex ramp rises two metres over x=1..4, z=23..25. The eastern aisle and rear rows provide an independent exit. Source placement is explicit, and both portable plans carry the same hall. Prior files and historical grid are archived in doc/space/space-colonization-2026-09-14.

Desktop verification must exercise the pointer controls, half-metre prediction, actual fork records, independent canopy calculation, witness retention, budgets, all covers/decks, ramp and museum exit. Headset reach/readability/comfort, audio and Quest performance remain pending. The next hall is PG_Branching_Growth.


## Reconstructed tutorial — 9 October 2026

Three full printed files: growth.gd, colony.gd and byte-identical PointBody from Genetic Evolution. The new lesson is unit-direction accumulation and eligibility; the complete nearest-site search is supporting code. Three/eight field positions exactly match the installed study. Nodes store position/parent index. Assignments read one generation, then removals and additions are applied. TIPS eligible set is childless nodes; NETWORK keeps all sites, rejects already occupied/proposed endpoints. Strict influence <8, inclusive kill <=0.32; step0.5, limits192 nodes/60generations. Ties retain first listed site. No physics attraction or branch collision.

Declared reconstruction edge: zero-sum TIPS adds no child here; installed TIPS can append a coincident child. NETWORK already guards zero sums. Tests explicitly expose the difference. Both models agree for 15 steps on each of the three/eight-point fields under both policies (60 comparisons of positions, parents and active requests). Rooted tree, not cyclic graph. Held copy contains geometry only, not field/policy/RNG or continuation state. Miniature display scale0.4 outside data; held scale0.24. Live redraw uses ordinary eight-sided CylinderMesh rods; it does not reproduce the production six-sided open mesh exactly.

Full student variant removes only per-request normalization, keeping final normalization. Eight-point raw sum(-1.5,29.5,0.9) gives child(-0.02537915,0.49912325,0.01522749); baseline(-0.04951403,0.49738270,0.01260222). Both steps0.5. Symmetric opening hides the difference. Gold vectors then mean weighted contributions, not unit directions. Complete edited program executed in headless tests and museum.

30 exact-printed native checks PASS; 60 source-step comparisons; missing-final-normalization, always-eligible-TIPS and shallow-witness mutants rejected by their specific oracles. Complete code extracted from canonical tutorial, byte-equal to study and rendered HTML. Supplied XRTools poses tested under translated/rotated host; movement alone does not advance, trigger advances once, release parks locally. Keyboard field switch checked. Model limits, tie, removal boundary, parent topology and copy independence covered.

31 museum checks PASS, including nine capture cameras, six actual desktop pointer buttons, fifteen-step strand/fork comparison, held persistence, 96-point canopy bounds, 13 ramp support samples and 194 clear supported capsule samples along eastern floor route. Temporary learner placed hall-local(9.5,0,17), yaw180; approach(9.5,0,15.4). Same inherited point, code and edited variant exercised in actual isolated museum. No full portal traversal, physical headset/Quest performance or independent learner acceptance claimed. Side film artifact remains an existing encounter, not newly tested curriculum.

Baseline and final native images retained. Close learner caption is small from the wide camera; witness and distinct branches are visible. Existing rear structure appears sparse; this pass did not rebuild it. Existing UID/renderer diagnostics remain; accepted logs have no SCRIPT ERROR or Parse Error. Canonical production algorithm/wrapper/lesson/scene/map/sequence and target runtime row unchanged. Reflection retains its argument; code excerpts and operational explanation moved into tutorial. Review doc/book/iterations/2026-10-09-colonization-who-can-answer/index.html. Second of seven procedural-generation halls; Branching Growth next. Static report checks do not establish browser layout acceptance.
