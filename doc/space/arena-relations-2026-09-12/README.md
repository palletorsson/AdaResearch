# What Makes an Encounter? — 12 September 2026

VFM_08_Arena gains arena_relation_lab at (13,8). All 21 original placements (20 identities, including two head crabs) shift sixteen cells in Z. New totals: 22 placements, 21 identities; map 26x20 -> 26x36. Primary book order is arena_relation_lab then collision_carts. Existing collision prose is preserved after the new creature passage. Original files and placement ledger are kept here.

The station uses lesson_crab.gd, a subclass of the existing head_crab script. It overrides candidate selection/fallback only: station food and nominated beacon/player, within 6 m, nearest visible, inherited ignored-candidate exclusions, no sight memory. Existing rig, steering, local avoidance, gait, eating and threshold code remain. Bite and path grid are disabled; patrol speed is zero. The subclass uses the existing 2 s feeding interval and roots at five completed meals. No branches or trained policy are added. Base crab and mushroom scripts are untouched.

lesson_food.gd subclasses native SporeMushroom and removes global bait membership after planting. Walking pickup is disabled. It retains native consumption/animation. One offered mushroom at a time prevents uncontrolled stacking; RESET removes it and replaces the scoped crab. Visitor/beacon, screen and reveal settings remain. RUN pauses crab updates, not unrelated mushroom tweens or the whole museum.

The screen is visible collision geometry; sides remain accessible. The gold frame is an observation cutoff, not a physical wall. Candidate lines and readouts share the scoped choice. Candidate distance is 3D but inherited sight rays flatten height to floor+0.20 m. These assumptions are named in tutorial and book.

45 actual-museum desktop checks pass: source controller enable/disable, sight/range, closer-candidate selection, unassisted travel and completed meal, timing/count, threshold/reset, nominated real player, scope isolation, stable display resources, observation exit, approaches and retained collision carts with independent analytic total checks. Captures of screen, feeding and carts inspected. Headset reach, legibility, comfort, sustained performance and comprehensive supporting-exhibit review remain pending. Existing unresolved UID and renderer shader-cache warnings are outside this change.

Two map tokens use existing label_depth:scene: brake_skid and tug_of_war. This corrects their text drawing through the new board. Existing supporting head crabs are classified secondary rather than decoration; no behaviour change. Historical note updated and archived.

Book lines, roles, core hashes, evidence fingerprints, museum indexes and the working route are aligned. Illustrated guide links backward to Legs and forward to Vectors_Act5_ForceAsPlace. No commits made.
