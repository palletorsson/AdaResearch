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
