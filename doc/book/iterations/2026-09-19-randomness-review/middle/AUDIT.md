# Randomness: middle four halls, 19 September 2026

This pass follows `doc/book/REVIEW_PRINCIPLES.md`: retain mature writing, recover the encounters carrying it, and fix verified gaps. It does not treat the frozen primary-only package as the entire artwork. Source and desktop Godot evidence are distinguished below from headset experience.

## Decisions by hall

| Hall | Judgement | Decision |
| --- | --- | --- |
| Random_Rotate_Random_XYZ | Targeted implementation and staging repair | Keep the short manuscript. Make TOGGLE resume its existing clock; fit the two complete stacks to their hall without shrinking the controls. |
| Random_Walk | Targeted naming and handoff repair | Keep the substantial walk, history, terrain and held-point argument. Rename the misleading visitor label LONG STEP, preserving the exact sampler and legacy enum. Correct the preceding-hall sentence. |
| Random_Gaussian | Preserve | No source or manuscript rewrite. Existing procedures, finite counts, clipped draws and rebinning already carry the argument. |
| Random_Mushrooms | Recover and clarify the three encounters | Promote bed, arrivals and couture together; add the two missing book markers and put arrivals after the bed. Retain the repertoire/permission questions and the eating passage. |

## Changing stacks: a control and spatial mismatch, not a weak argument

The text asks the visitor to “Resume briefly and pause again.” Both the VR TOGGLE and keyboard action used to reset `_decay_elapsed` whenever resumed. A source replay reached 12 seconds, paused without changing state, and then resumed for one second: the clock read 1, still inside the four-second onset delay, and no geometry state advanced. The repaired control reads 13 and advances immediately. RESET still clears the clock and restores the initial arrangement; it does not reseed the random generator. Both input paths share the same small helper.

The actual museum revealed a further problem which the prose alone could not establish. The 20-cube stack occupied segment-local x −0.16…5.16; the 120-prism stack occupied x 3.08…16.32, in a twelve-metre-wide hall. Both began half a metre below floor level. The source forces the nominal “1dm” prisms to the same one-metre unit as the cubes, while retaining twelve columns and ten rows. The two displays overlapped and extended through walls.

The map-local `stack_fit:10` option applies a common geometry scale of approximately 0.506466 to the two MultiMesh nodes, separates their initial bounds by 0.6m and lifts their initial lowest faces to the floor. It retains every instance, all simulation coordinates and both configured rates. The initial fitted display spans ten metres. The console keeps its scale and 0.85m hand height; for the fitted placement it faces the entrance at z −1.2. Other placements without `stack_fit` retain their original display arrangement. Subsequent drifting, turning and sinking remain part of the authored model; the fit is not a collision simulation.

The source identity and proposed registry description now distinguish authored bounded perturbation from a thermodynamic entropy measurement. The manuscript already makes this distinction and already warns that the two rates prevent attributing the contrast to shape alone. No demand to expand or simplify that text follows from these repairs.

## Walk: make the label as precise as the writing

The actual formula is `0.015 * (u + 0.01)^(-0.5)`, capped at ten times the base step, with reflected endpoints inside the glass. The manuscript already discloses its offset, exponent, cap, omitted wall contacts, trail lag, finite history, retained program state and capped catch-up time. Those are valuable particulars, not excess explanation.

The visible LEVY label is now LONG STEP on the keypad, statistics and logbook. The saved numeric mode 2, `LEVY_FLIGHT`, all constants and random draws remain compatible. Frozen-before/current comparisons produced identical 10,000 proposed vectors in each of three modes and identical retained positions after 300 steps per mode. The tested long-step sample ranged from 0.014925869m to 0.149993226m. This is evidence for unchanged behavior, not a claim that finite samples prove a probability distribution.

The accepted compact keypad uses the plain label LONG STEP. An initial newline joined the words in baked rendering, so the final capture verifies the space. The proposed prose changes two names and corrects the transition: Remove was earlier; the immediately preceding hall accumulates perturbation in stacks. The retained companions are `random_walk_128` (actually a 32×32 ten-metre lattice) and `random_draw_dot`, alongside collection/leash/pixel-cloud secondaries. The held point is an actual private seeded offset process while carried; it is not simply a poetic promise of agency.

Earlier evidence remains relevant: `doc/research/possible-bodies/random-walk-check.json` contains the previous 129-check pass. Those are previous results, not counted again in this pass.

## Gaussian: leave a mature encounter intact

The source supports the chapter's sequence of stopping new samples, letting in-flight markers finish, clearing, issuing a batch and changing bins without drawing new values. It uses the guarded Box–Muller transform, clamps values to the display interval and records clipping. Expected counts and empirical counts remain distinct. The sources for the Galton board, splatter and comparator remain present as secondary possibilities; none needs promotion merely to increase the count.

The focused regression issued a paused BATCH100, retained all 100 exact landed values through 60, 10 and 30 bins, and verified that CLEAR remains empty while paused. No rewrite is proposed. The earlier live record `ada_run/gaussian-review-2026-09-12/Random_Gaussian/probe_gaussian_live.json` contains 156 checks; this pass neither repeats all of them nor relabels them as fresh tests.

## Mushrooms: the missing evidence was partly a primary-filter problem

All three source-backed encounters exist in the actual room:

1. The bed copies six construction templates. SHOW identifies copies; SIZE suppresses only use of the already-drawn scale value. KIND separates scattered accepted/rejected positions, rings and clusters. These routines do not negotiate ecological space. Edible mushrooms come from a different interaction scene.
2. `silhouette_arrivals` fills six authored slots by seeded sampling without replacement. DRESS changes sampled clothes. FORMS switches the rule adding branches, retaining the dress number. Neither touches the arrival generator or slot history. The figures remain flat billboards without new locomotion.
3. `couture_comparison` begins at seeds 41/42/43 with hare/sheath. GARMENT keeps those seeds while changing construction; NEXT SEED advances to 44/45/46; RESET restores the original geometry.

The focused runtime checks support these distinctions: six-slot exhaustion, exact arrival replay, unchanged arrival RNG/history under DRESS and FORMS, restored image data when switching FORMS back, changed couture geometry under GARMENT and exact geometry restoration after RESET. Rebuilds use `queue_free`, so the harness lets a frame complete before comparing current meshes. An initial immediate-frame comparison saw still-pending old geometry; that diagnostic was retained and corrected in the test, not misreported as an artifact defect.

The old package omitted important source chains because the arrival and couture works were secondary. This pass freezes their complete chains, including `silhouette_sprite.gd` and the couture builder. The argument deserves its two missing `@artifact` book markers and three primary roles; it does not need cutting to fit the former single-primary view.

Before the move, standing positions were z6.28 for arrivals, z9.83 for the bed, and z22.23 for couture. All three standing capsule queries were clear, but the spatial reveal put the wardrobe before the population. Root moved the existing arrival token from cell (13,4) to (13,17), retaining its controls and six slots. The proposed closing preserves the question about other permissions and follows the actual next spaces: the cage interlude, then independent/correlated spatial values in Random Space Geometry.

The previous mushroom-bed live record has 117 checks at `ada_run/mushrooms-review-2026-09-12/Random_Mushrooms/probe_mushrooms_live.json`. The present pass adds evidence for the previously omitted two encounters. It does not claim fresh headset eating or comfort tests.

## Files, verification and remaining limits

`before-source/` and `before-sha256.json` freeze 170 source/context files before owned edits. `artifact-source-index.json` resolves nineteen placed artifact scenes. Production source changes are restricted to the terrarium and decay scripts. Root owns map tokens, route restoration, roles, registry descriptions, metadata and all `final.md` integration.

Guarded proposals live in `proposed/root-text.json`, `root-metadata.json` and `root-registry.json`; each preserves the exact old string/value for root to check before applying. `owned-source.diff` records the two source changes against this pass's snapshot.

`focused-accepted/behavior-checks.json` records 49 passing checks. Its runner exited normally with XR disabled and Dummy audio. `focused/`, `focused-fixed/` and `focused-final/` preserve earlier diagnostics; only the accepted run includes the final fitted-console staging. The subsequent label-only space correction is verified by the final actual-museum render. The baseline museum runs and final accepted runs record process exit, source hashes, camera poses and active-camera assertions.

Accepted pairs are `walk-before/instrument.png` → `walk-accepted/instrument.png` (6/6 each), `rotate-before/stacks.png` → `rotate-after/stacks.png` (4/4 before,11/11 after), and `mushroom-before/hall-plan.png` → `mushroom-after/hall-plan.png` (18/18 before,20/20 after). The arrival closeups are an additional matched relative-view pair. All six accepted renderer processes exited0 with stable watched sources and the same shared-loader hash. `evidence-manifest.json` records image hashes and scope, including the unseeded background terrain in the Walk image. `owned-after-sha256.json` records the final two production source hashes.

The final Rotate image still shows `dark_sphere` visually overlapping the prism array. Its control approach passed the capsule query, and the fitted stacks are readable as two complete displays. Retaining or relocating that decoration is a later curatorial decision, not grounds to prune it in this bounded repair. The dark Walk keypad has low contrast under this hall's current lighting; no global material or shared control change was made in this pass.

These checks establish current source behavior, sampled controller signals, measured room placement and desktop rendering. They do not establish headset reach/comfort, audible experience, player interpretation, or learner understanding. No artifact was removed, no global geometry defaults changed, and no prose was cut to force a smaller argument.
