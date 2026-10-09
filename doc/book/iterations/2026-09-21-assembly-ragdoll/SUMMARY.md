# Assembly: a body with weight

Implemented beside the existing automatic catalogue and gold coordinate/graph workshop in AdvancedLaboratory_Lab_Equipment_Simulation. The opt-in `body_ragdoll` reuses VRBody's thirteen named points, with ten rigid parts and nine freely rotating pin joints. Its ten physical bodies remain unfrozen while a held coral ring supplies a bounded spring-force target. Non-adjacent parts collide; anatomical angular limits are not implemented. The two hip attachments are separated to keep the legs distinct. No new scene token, primary filter change or catalogue-wide behavior was needed.

First grab releases the head support. Any limb can be pulled, including two at once with XRTools controllers. Releasing removes the hand force; the puppet falls and settles on the floor. A visible elastic tether makes the held target's lag legible. HANG AGAIN resets and supports it; reset refuses while held. This study does not write a pose. The gold workshop and its Synthesis return are preserved.

## Evidence

- 24 runtime/interaction checks pass, including actual desktop ray selection and carrying, synthetic two-controller XRTools pickup/release, force transmission, release/fall, reset, opt-in isolation and unchanged gold/save state.
- 5 continuous selected walking segments pass, from entrance through the central lane to the mat approach and exit.
- Measured controlled pull: hand moved 0.744 m; elbow moved 0.490 m; maximum sampled constraint-anchor separation at the checked drag state was 0.0492 m.
- After release the highest part centre was 0.226 m above the study floor. This is a centre measurement, not maximum mesh height. Reset head-position error was 0.0023 m.
- Godot exits 0, no script errors. An existing unrelated unrecognized UID warning and museum environment/dressing warnings remain in the saved log.
- Four actual rendered views inspected. They show states of the new implementation, not a human session or a before/after implementation comparison.

Creation and reset originally exposed stale physics attachment transforms. Synchronizing body transforms before joint creation/reset fixes both the misplaced initial hand and head reset. The final repeat passes all checks. The grab spring was then made firmer and its elastic gap drawn explicitly; this final implementation is the one captured and measured here.

The chapter preserves its entire earlier encounter before the new addition. The extension moves from a hand that lengthens a visual relation to one that pulls its neighbours, then asks how support and constraint contribute to a perceived gesture. Exact text/source diffs, baseline copies, source manifest and current input hashes are beside this report.

## Scope

Headset reach, physical feel, haptics, comfort, Quest performance and learner understanding remain open. Free pin joints make this a stylized ragdoll rather than an anatomical model. The live game was not restarted; no live museum bake or visitor pose was replaced. No commit was made. The full-book export for Claude remains frozen.

Collective Knowledge restoration remains separately parked; see ../2026-09-21-commons-restoration/PENDING.md before resuming it.
