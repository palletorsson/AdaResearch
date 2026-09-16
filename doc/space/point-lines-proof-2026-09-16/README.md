# Point_Lines — what counts as evidence?

Implemented from Palle's pasted review discussion on 16 September 2026. The review is a design contribution; behaviour claims were checked against the local scenes and the loaded museum.

## Editorial method carried forward

Separate the mathematical relationship, the program's test and the visitor's experience of acceptance. Start with an action and an observable difference; show the relevant instructions before generalising about the system. Ask: which operation does this, under which conditions, and what possibilities follow?

The other room texts retain questions that can drive artifact development. Matching prose to working code should not discard those questions. A proposal should be identifiable as a proposal, and an implemented interaction should be described as such.

## This pass

- Added `line_proof_pair` at map cell `(11,1)`: two adjacent PlusLinePuzzle derivatives with identical scattered stock and reference rings. A uses `relation`; B uses `invariant`. Both keep checking and keep their handles available after acceptance. Move-left/right preserves both segments while leaving the targets fixed; reset restores the starting stock.
- Capturing the actual museum exposed endpoint gravity after translation. The pair now retains released endpoints in space, including after move/reset. The default plus puzzle is unchanged. The regression probe waits through physics updates and tests release away from targets.
- Restored `two_point_ruler` at `(13,11)`, with its blocks on a 0.75 m bench and the pickable ruler at the front. This staging is an optional map configuration; existing placements keep their defaults. Measuring reads the pale subject and separately scales the blue witness. The registry, final.md and encounter reference now distinguish that authored side effect from a general claim about observation.
- Revised the book's paired experiment and ruler passages. Split the instruction/trace material into its own primary group so the tutorial order matches the revised prose. All 14 primary tokens are in final.md and on the map.
- Refreshed only the Point_Lines row in the authoring and shipped museum plans. All 50 prior map placements remain, with two added placements. Older plan snapshots were not used as evidence of the current floor.
- Retained prior intent notes under a historical heading. Added current implementation notes to technical.md and encounter-reference.md.

## Evidence

- `commons/testing/probe_line_proof_pair.gd`: 20 checks pass, including translated/rotated-parent behaviour, acceptance after physics updates, off-target release, reversible answers, degenerate and skew-segment rejection, and pointer-button reset.
- `commons/testing/probe_two_point_ruler.gd`: passes its existing action, refusal, re-arm, bounds, instance-isolation and scaled-reading checks. The probe now starts after autoload initialisation rather than compiling its dependent scenes in SceneTree's constructor.
- `commons/testing/capture_line_proof_pair.gd`: loads Point_Lines in the actual Endless Museum. All 52 map placements stamp without sliding or omission. The bench is at `(11.5,0,1.5)` and the ruler at `(13.5,0,11.5)`; the configured raised ruler answers `pickable.action()`. The translated proofs disagree in the live hall and remain different when the image is captured.
- Desktop OpenGL capture: `ada_run/line_proof_pair_museum.png`. Runtime logs: `ada_run/line_proof_pair_probe.log`, `ada_run/line_ruler_probe.log`, `ada_run/line_proof_museum.log`.
- Targeted JSON/role/book/plan comparisons and `git diff --check` pass. Existing engine startup UID/certificate warnings, material warnings and teardown leak warnings remain; these checks do not establish a warning-free project.

Headset reach, grabs and comfort still require a physical visit. The pointer tests exercise the button input route; they do not simulate a tracked hand.

## Next small experiments

1. Give a workshop camera a visitor-controlled second view of the same arrangement. Walking around the current flat monitor does not move its private camera.
2. Test the existing angle-only predicate with separated perpendicular directions. A projected crossing and a spatial intersection need distinct evidence.
3. Develop the relationship between Modulor, the sampled player trace and Klee's programmed walk without treating one as an unmediated body. Keep their different reductions visible.
4. Carry addressability forward into Trace and Grid, preserving their distinct questions instead of asking Lines to do the work of three halls.

Practical geometry: target membership uses the scene's 8 cm tolerance, coincident centres use 5 cm, and perpendicular directions use an absolute normalized dot-product threshold of 0.26. These are approximate acceptance rules, not exact mathematical equalities.

## Second editorial pass — 16 September 2026

Palle supplied a further review asking for subtraction and a firmer relation between proof, image and record. The workshop passage is reduced from 731 to 491 whitespace-separated words, counting its heading, artifact marker and code consistently. The longer version is retained in `workshop-extended.md` for later rooms. The chapter as a whole is reduced from 2,788 to 2,434 words by the same count.

The paired proof remains central. Displacement is named consistently, path is distinguished from timing, and the ruler recalls the barrier's authored consequence. Transitions link recognition by a program, inference from an image and what a movement record preserves. The closing detour no longer pauses for a recap.

The held rod stays primary for its fixed span; its coordinate jitter receives a short acknowledgement. The exploding sphere stays in the museum as a secondary pointer experiment. Its former primary group is replaced by the measuring laser directly, preserving the saved card position. The current book and tutorial now have **13 primary tokens**, in identical order and all present on the map. The 14-token figures above describe the initial implementation before this editorial decision. All 52 map placements remain.

This pass changes prose and curation only. JSON parsing, exact book/tutorial order, primary-to-floor coverage and targeted diff whitespace checks pass. The preceding runtime checks remain the evidence for unchanged artifact behaviour; they were not rerun for these editorial changes.

## Third editorial pass — two points and a way out

Palle clarified that the room must teach two points making a line and allow the visitor to leave without pursuing every association. The prior revisions had made each useful experiment a further required lesson. The book now follows three encounters: connect two points and open the barrier; vary the endpoints; compare a straight instruction with the recorded walk. The final question concerns the journey that endpoint subtraction does not retain, giving a reason to enter Trace.

The chapter is reduced from 2,434 to 878 whitespace-separated words, including artifact markers and code. The complete preceding chapter is retained byte for byte in [chapter-before-focused-path.md](chapter-before-focused-path.md). Its markers describe the earlier version. The new prose allows a brief glimpse of the other studies and makes limited attention part of the journey from Point_One.

The current primary set has five tokens in book order: `line_demo`, `do_not_cross_barrier`, `line`, `walk_this_line_marking`, `player_trace`. The paired proof, red division, workshop, held rod, ruler, bead, laser and parallels become secondary. Their experiments remain on the floor, and their saved card positions move with their roles. The associative note also moves to secondary. `line_collection` now has an explicit secondary role; previously it inherited primary by default and was missed by checks restricted to explicitly assigned roles. The earlier 13-token report therefore described explicit assignments, not the complete effective primary set.

All 52 physical placements remain, with map_data.json unchanged during this pass. Further work on spatial guidance can use this shorter reading as its route; the present change does not establish that the physical arrangement makes that route obvious.

Validation: JSON parsing, the effective primary set including default roles, and the exact book-marker order all pass. Calling the actual necklace `artifact_roles.room("Point_Lines")` resolver returns those same five primary cards in order and 24 secondary cards. The archive matches the preceding chapter byte for byte. Other rooms' curation data is unchanged. Targeted `git diff --check` passes. No runtime changes were made or new headset verification claimed.

## Commit checkpoint — 16 September 2026

The final wording clarifies the finite segment and the chosen direction from A to B, and shortens the passage about attention. The chapter now has 875 words by the same count. The five primary tokens and the exit into Trace are unchanged.

Before committing, the barrier connection, paired-plus, ruler and elapsed-speed probes were rerun successfully in the current workspace. The commit includes the Line hall's artifact dependencies, optional workshop, scoped registry entries and only the Point_Lines entries in shared curation and museum-plan data. Unrelated rooms' pending changes are retained in the working tree. These probes validate the current workspace; they are not a clean-checkout or headset test.
