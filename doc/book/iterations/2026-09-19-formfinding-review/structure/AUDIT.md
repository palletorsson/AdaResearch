# Form Finding: Catenary and Equilibrium

2026-09-19. Source, encounter, and manuscript audit by the structure subagent. Root integrates the manuscripts, catalog, and sequence. This report records a first-pass repair, not a final verdict on the work.

## Decisions

| Hall | Judgment | Preserve | Repair now | Develop later |
| --- | --- | --- | --- | --- |
| FormFinding_Catenary | Targeted recovery and factual correction | Hand-drafted curve question; laundry/arch analogy; catenoid and helicoid comparison; boundary principle | Recover laundry from the catalog; complete its support rails and readable plaque; restore surface pickup detection; distinguish authored formulas from physical settling | A genuinely settling cable, load-sensitive hanging model, surface deformation/stability experiment, and compatible measurement interface |
| FormFinding_Equilibrium | Targeted honesty repairs; important encounter development remains | Mobile's recursive lever arithmetic; triangle and tower as existing comparison material; gravity as co-designer | State the mobile's mass model and omitted members; withdraw unmeasured tower strength claim; identify the triangle's prescribed scale animation | Visitor control of the mobile's existing alternatives; hinged triangle versus square under matched conditions; a specified load and measured response for the tower |

All placed artifacts remain. No map cells, primary roles, sequence order, or shared museum implementation were changed by this subagent. The different representation types make a useful ladder: draft a constraint, evaluate a formula, inspect a mesh, encode an ideal balance, and then encounter a finite solver elsewhere in the sequence. The chapters should name those differences rather than treating every rendered shape as physical evidence.

## Source findings

### Catenary

- `cable_builder` has four grabbable control beads. It redraws a curve with authored Bezier handles and per-span sag; it neither conserves rope length nor solves a hanging chain. The legacy `catenary` option remains for compatibility, with its meaning clarified in comments.
- `laundry_line_cathedral` samples three analytic cosh curves and their reflected arches. Clothes are decorative and do not load the lines. Its previously empty crossbar loop left the outer endpoints without visible supports. The new rails expose the chosen boundary without claiming a force solution.
- The laundry was present in the map but catalog-ineligible. A clean actual-museum headless baseline recorded its absence. Root subsequently restored eligibility in the registry. Rendered comparison pairs use that restored catalog for both versions, with the original artifact source replayed for the before image.
- The catenoid and helicoid already use the XRTools pickable base and collision shapes, but both scene roots retained default collision layer 1. The hand's layer-4 query missed them. Layer 4 now makes both discoverable; the actual museum probe verifies query hits and `can_pick_up`.
- The catenoid is an analytic minimal surface patch, not a universally stable or globally area-minimizing film for every ring boundary. The helicoid is ruled; the catenoid is not. Their local isometric associate-family relation does not identify arbitrary finite meshes or imply that this artifact animates between them.
- `science_screen` has no compatible live measurement of these examples. Its line scan requires an appropriate name and multiple descendant grabbable bodies; moving the laundry closer alone does not satisfy that contract. The actual museum initializes the screen in POINT DATA mode without a compatible source. It should remain a measurement-development task.

### Equilibrium

- The Calder-inspired sculpture recursively computes nominal leaf masses from disc area, 3 mm thickness, and a chosen aluminium density. Seed 4 produces 11 discs with a total modelled mass of about 9.29 kg. The default pivot positions make the two mass-distance products equal in a model with massless rods and wires. It is a frozen Node3D construction, not a rigid-body balance or wind simulation.
- Existing `solved`, `halved`, and `inverted` lever alternatives retain the same leaves and mass. Their tilted rods are authored residual diagrams, not computed equilibrium angles. These are useful existing comparisons to make accessible later; this pass did not add controls or extra placements.
- `tensegrity_triangle` writes sine-driven root scale directly. No applied load, hinge constraints, member forces, or tension cables are present. The visual squeeze is worth discussing, but it does not establish structural resistance. An actual hinged triangle/square comparison is a scoped future artifact task.
- `fractal_truss_tower` recursively subdivides height into braced storeys. Earlier thicker legs remain on the same lines as later thinner legs. The small sway is prescribed. Neither strength nor material efficiency is measured, so the plate now identifies recursive braced storeys and explicitly says there is no load test.
- The screen's generic scanner can classify a name containing “fractal” and count descendants, but those quantities are not load measurements. The current museum screen remains in POINT DATA mode without a source. The proposed text does not claim that a live radar measures this tower.
- Existing partitions and the screen obstruct some southern viewing positions. Accepted northern views make the repaired labels legible, but this pass has not solved the hall's wider staging or demonstrated complete visitor reachability.

## Changes and manuscript handoff

Eight owned source/scene files changed; all were copied into `before/` before editing. `before-sha256.json` records the initial snapshot. `changes.json` records exact before/after hashes and diffs; `source-changes.diff` is the combined readable diff.

1. Laundry: two support rails, a relocated standing plaque, short accurate label, and corrected source claims. Existing curves, clothes, mirrored arches, and random seed remain.
2. Calder: accurate static-model plaque and source comments. Geometry and mass calculation remain.
3. Truss: honest display label and source comments. Geometry and sway remain.
4. Triangle: comments only, identifying the existing direct transform animation.
5. Cable: comments only, identifying authored Bezier sag.
6. Catenoid script: header comment only, separating minimality from stability and global minimization.
7. Catenoid scene: pickup collision layer changed to 4.
8. Helicoid scene: pickup collision layer changed to 4.

Complete narrow manuscript proposals are preserved in `Catenary.proposed.md` and `Equilibrium.proposed.md`. Root owns their integration and adjusted encounter order: the hand encounter precedes the film formula, and a prediction precedes the mobile calculation. Root also corrects the impossible table's sequence reference. A terminal pair of discs on the same arm is the appropriate initial comparison, rather than an arbitrary pair drawn from different mobile subtrees. Poetry and the questions about boundaries, gravity, and permitted change are retained; false descriptions of implemented physics are replaced.

## Verification

`verification.json` is the machine-readable summary. All six accepted runs returned 0, passed their assertions, kept their tracked sources stable during execution, and reported no script errors:

| Run | Checks passed | Purpose |
| --- | ---: | --- |
| museum-baseline-final-FormFinding_Catenary | 16 | Actual museum before catalog recovery; original surface query failure |
| headless-after-FormFinding_Catenary | 25 | Isolated artifact behavior and changed interaction |
| capture-before-accepted-FormFinding_Catenary | 28 | Saved-original source replay in the actual museum |
| capture-after-verified-FormFinding_Catenary | 22 | Repaired museum artifacts and accepted images |
| capture-before-verified-FormFinding_Equilibrium | 25 | Saved-original source replay in the actual museum |
| capture-after-verified-FormFinding_Equilibrium | 19 | Repaired museum artifacts and accepted images |

The checks cover support rails and analytic endpoints, surface pickup query behavior, cable response to a moved control bead, mobile mass/leaf invariance across all three lever alternatives, truss labeling, and the triangle's actual prescribed scale pulse. Checks are scoped and may repeat between before/after runs; the counts are not a measure of independent feature coverage.

### Accepted paired images

Before and after use identical camera records, shared source hashes, selected map, registry, and render settings. Camera equality and shared-source equality are recorded in `verification.json`.

| Subject | Before | After |
| --- | --- | --- |
| Laundry supports and standing plate | `capture-before-accepted-FormFinding_Catenary/laundry-standing.png` | `capture-after-verified-FormFinding_Catenary/laundry-standing.png` |
| Laundry text | `capture-before-accepted-FormFinding_Catenary/laundry-plaque.png` | `capture-after-verified-FormFinding_Catenary/laundry-plaque.png` |
| Mobile in the hall | `capture-before-verified-FormFinding_Equilibrium/calder-standing.png` | `capture-after-verified-FormFinding_Equilibrium/calder-standing.png` |
| Mobile's mass-model plate | `capture-before-verified-FormFinding_Equilibrium/calder-plaque.png` | `capture-after-verified-FormFinding_Equilibrium/calder-plaque.png` |
| Tower and label | `capture-before-verified-FormFinding_Equilibrium/truss-standing.png` | `capture-after-verified-FormFinding_Equilibrium/truss-standing.png` |

The final after images were visually inspected: the laundry's four short lines, the mobile's model/omission statement, and the tower's replacement label are readable. The laundry pair demonstrates source repairs after catalog recovery; the separate headless baseline documents its earlier absence.

The harness instantiates `commons/scenes/endless_museum.tscn` with a frozen compiling shared loader snapshot, `frozen-museum.gd` (SHA-256 `3d2977729d506a672583f88932d81c77e330cf77acecfd8f69c623196d7f5c4d`). It asserts that the actual instantiated scene uses those script bytes. Original artifact scripts and the two original packed scenes are replayed through resource-path takeover for before captures. The production shared loader is untouched. Both render pairs also happen to have matching live shared-source hashes.

The museum camera contains a periodic timer which can reclaim the active camera even when processing is disabled. The final harness stops those camera-child timers, then asserts the requested camera is active both before and after `frame_post_draw`. Earlier images taken before this guard, or with walls/screens blocking the chosen viewpoint, are retained as diagnostics and are not the accepted comparisons. One earlier after plaque also clipped its longer wording; it was shortened and rendered again.

All launches used hidden processes, XR off, and Dummy audio. No editor/import was run. Earlier diagnostics include an eager XR base-class compilation failure; the final probe inspects the inherited script dynamically and the accepted runs compile cleanly. Existing unrelated warnings remain in the raw logs. No headset wear, tracked grip/release, full visitor walkthrough, physical load proof, or performance benchmark is claimed. The pickup repair is verified by the actual layer query and `can_pick_up`, not by a human VR trial.

## Mathematical and historical grounding

- Danny Calegari, [Minimal Surfaces, §1.4](https://math.uchicago.edu/~dannyc/courses/minimal_surfaces_2014/minimal_surfaces_notes.pdf): full notes inspected; the conjugate/associate family and local isometric relation support the restrained catenoid–helicoid discussion.
- Gareth P. Alexander and Thomas Machon, [A Björling Representation for Jacobi Fields on Minimal Surfaces and Soap Film Instabilities](https://arxiv.org/abs/1912.13009), published 2020: primary arXiv record inspected. It treats stability questions beyond merely naming a surface minimal. The linked full PMC page was inaccessible during this audit; no claim of having read that entire page is made. These are the two authors; an early draft's erroneous longer author list was corrected before handoff.
- Santiago Huerta, [Structural design in the work of Gaudí](https://oa.upm.es/703/) (2006): institutional record and indexed abstract identify hanging models, graphical methods, and equilibrium design. Direct full-text access was unavailable. The chapter uses the conditional hanging-model principle, not a new numerical or historical claim drawn from an unread paper.
- The [Sagrada Família educational resources](https://educa.sagradafamilia.org/es/recursos-i-materials?p_r_p_categoryId=1487058) identify inverted models with strings and weights for the Colònia Güell. The architectural reference concerns a physical method; our sampled laundry curves do not implement it.

## Next useful work

1. Expose the mobile's existing lever alternatives and one controlled mass change, with the two products available for inspection.
2. Build a hinged triangle and square under the same stated conditions. Keep the current triangle's animation available as a comparison rather than silently relabeling it as physics.
3. Give the cable an explicit choice between hand-drafted sag and a finite settling model, preserving both representations.
4. Add compatible measurements before moving or promoting the generic science screen as evidence of balance.
5. Review the partition/screen obstruction with a walking camera or headset. The present paired images establish source and label changes, not a complete spatial redesign.
