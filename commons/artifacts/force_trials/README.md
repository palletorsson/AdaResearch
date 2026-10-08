# Forces: ten more trials

An optional review route inside the existing Endless Museum. Run `commons/scenes/force_trials_museum.tscn`. It supplies its own plan and artifact order; the thirteen-hall Forces spine is unchanged. Each scene in this folder is separately registered and can be placed in a later curated hall.

| Scene | What the visitor does | What actually computes the result |
|---|---|---|
| `mass.tscn` | Give 1, 2 and 4 kg points the same one-second push | Rigid-body integration of a 2 N force, horizontal constraints, no gravity/damping |
| `vortex.tscn` | Compare radial force with a sideways component | Spring-like radial field plus tangent and linear drag; engine integration |
| `roll.tscn` | Release two balls and a cube on equal slopes | Contact/friction, one ball's rotation locked, the other's rotation free |
| `pipe.tscn` | Launch the point through the open transparent bend | Segmented collision channel; initial velocity only, then contacts and gravity |
| `conveyor.tscn` | Feed twelve boxes, open or close the receiver | Static belt surface velocity moves boxes by contact; the receiver parks arriving boxes in a frozen display |
| `attractor.tscn` | Widen the selection from the wanted point to the doorstop | Distance-dependent force; a real hinged door receives a closing torque |
| `threebody.tscn` | Compare trios differing by 0.03 m/s | Pairwise equal/opposite softened attraction; planar constraint, no collisions, no scripted divergence |
| `support.tscn` | Settle the table, pull a loaded corner support | Gravity and contacts; an impulse removes the foot |
| `bowling.tscn` | Compare a free launch cart with a braced cart | Equal/opposite impulses; collisions topple the blocks |
| `catapult.tscn` | Release a point using a lever | HingeJoint3D and a 0.35-second torque pulse; arm contact launches the point |

The black point extends the earlier `ignorance_gallery/point_body.gd` through the capability court's physical-release subclass. The cubes use the existing GrabCube. Controls use the existing museum push button. These are trial artifacts, not newly approved tutorial chapters.

Misses remain while the hall is resident. RESET restores the initial transforms and refuses while a body is held. Bodies farther than 35 m or below -8 m are recovered, visibly reported. This is bounded experimentation, not permanent cross-hall state storage. Three-body trails retain at most 600 samples. The belt has twelve boxes, not an unbounded spawner.

## Evidence and selection

`doc/book/iterations/2026-10-07-forces-ten-more/` contains 86 passing physical/control checks, 61 passing portal-route checks, before/after museum captures, source hashes and the inventory. The ten scenes were photographed in the same museum bay to make their comparisons readable. Headset comfort, tracked hand reach and Quest performance remain to be tested in VR.

Open `http://localhost:3003/research/forces-review/index.html` for the interactive gallery. It includes 206 existing scene records (202 with content and four empty placeholders, explicitly flagged), with the six XL/laser delegate variants recorded under their source scenes, plus these ten new trials. Search by subject or hall; choose Keep / Rework / Leave out; add a note; export the decisions as JSON. These choices remain browser-local until exported and do not automatically change the spine. Older saved captures show appearance, not renewed interaction validation.

The readable book-review HTML also contains a static image inventory. Its HTTP route deliberately disables scripts; the interactive controls are served from the encyclopedia's public research directory.

```powershell
python tools/build_force_trials.py
python tools/run_encounter_probe.py Force_Review_01_Mass --sequence forces_review --render --probe tools/probes/force_trials.gd
python tools/publish_force_review.py
python tools/run_encounter_probe.py Force_Review_01_Mass --sequence forces_review --probe tools/probes/force_trial_route.gd
```

Run publishing before the navigation probe: the generic probe runner replaces its temporary `report.json`. The published physical evidence remains separate from `navigation-checks.json`.

The collection supports an artistic question: what remains when a sensible operation meets another sensible operation? The numeric and collision tests establish particular mechanisms; they cannot decide which encounter is worth keeping.
