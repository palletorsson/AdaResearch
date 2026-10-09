# Forces middle halls — encounter audit

19 September 2026. Local source and museum checks of VFM_03_Motion, Vectors_Act3_FieldsAndMotion, Vectors_Act4a_KineticForces, Vectors_Act4b_Oscillation and Change_Choreography. Review interpreted through [the encounter-first principles](../../../REVIEW_PRINCIPLES.md). No learner or headset verification is claimed.

## Decision by hall

| Hall | Judgement | Encounter and manuscript | Action |
|---|---|---|---|
| VFM_03_Motion | Preserve | Finite pulse ends; velocity persists. The later ramp is deliberately a different scalar threshold model, including its abrupt velocity reset. | Keep both primaries and all 15 secondary artifacts. No prose or production edit. |
| Vectors_Act3_FieldsAndMotion | Targeted reveal | The book asks readers to watch cyan approach and pink cross before pressing RULE. The live wall and moving labels already say SET/ADD. | Use the existing RULE button to reveal the receiver semantics. Keep color identity, instructions, controls, boundaries and numerical model intact. |
| Vectors_Act4a_KineticForces | Targeted staging and recovery | Book and roles say drag → mower → ring. Actual museum positions say drag → ring → mower. Two authored secondary scenes also disappear at registry lookup. | Restage existing encounters; recover the two existing scenes through root-owned registry metadata. Preserve the manuscript's difference between applied force, nominal work annotation and required acceleration. |
| Vectors_Act4b_Oscillation | Preserve | The spring integrates displacement/velocity; the discarded hand velocity and sideways movement are real choices. Its return later as waveform material does new work. | Keep primary and 21 supporting/decorative works. No prose or production edit. |
| Change_Choreography | Preserve | A scripted rotor relation differs from the preceding spring dynamics. Conveyor recovery changes a rate while keeping the backlog. | Keep both primary machines, the secondary pendulum and four explicit future-artifact placeholders. No prose or production edit. |

## Missing layers and recovery

### Fields: reveal timing

The source `algorithms/vectors/10_vector_field_flow/field_receivers.gd` gave away the update rule through both moving nameplates and its default wall paragraph. This is narrower than a general ban on labels: the eight controls, CYAN/PINK identities, RUN/RESET instruction, current field, gain, sign and clock remain useful to beginners. Only the two receiver operations belong behind the existing RULE action. The primary manuscript already provides this timing; it needs no rewrite.

The ordinary compact VectorFieldFlow remains a separate encounter. Its existing velocity blend retains state; it is neither direct assignment nor the new acceleration integrator. Do not erase that difference under a blanket “memoryless field” description.

### Kinetic: placement and two omitted registry admissions

Before-state live global positions: drag `(15.5,0,8.5)`, ring `(9.5,0,24.5)`, mower `(8.5,0,37.5)`. The hall is an ordinary museum transplant, not a SimGrid. This confirms the review's ordering hypothesis using the assembled space.

The map has 8 tokens, but baseline runtime instantiates 6: `sisyphus_mower` and `prop_carousel` log “has no living scene — left behind”. Both `.tscn` files exist. Root traced the actual admission gate: their registry entries lack `map_ready`/`include_in_map_data`; the museum catalog defaults readiness to false. The missing `lookup_name` initially drew attention but is not the gate: the museum reads the dictionary key. Root repairs readiness and supplies lookup names for consistency. The root agent completed the scoped registry repair. These remain secondary: their prescribed motion and annotations can be compared with the primary models, without presenting them as additional rigid-body simulations.

The authored early `t:Vectors_Act4b_Oscillation` at `(15,18)` and Oscillation's older raw `t:` destination are reported to root's navigation audit. This agent makes no utility or shared museum edit.

## What is deliberately preserved

- Similar arrows acquire different consequences from their receivers and retained state.
- Motion's force request differs from measured acceleration after contact/damping.
- Friction-ramp STATIC zeros scalar velocity rather than gradually braking it.
- Fields' fixed-step paths and display-height offsets are identified as representations, not visitor forces.
- Drag's cube model and WALK locomotion mapping remain different implementations; physical room-scale walking is unaffected.
- The mower's unchanged grass and increasing path survive zero net nominal work.
- The ring reports acceleration required by a prescribed path; it does not dynamically pull a free body or visitor into orbit.
- The spring integrates rather than consulting a cosine; its observation-frame cutoff is not a collision.
- Choreography's phase offset, frequency drift and material backlog are different temporal structures, not redundant oscillation examples.

## Evidence and limits

[Before source hashes](before-sha256.json) identify the frozen local files. Reproducible probes and hidden-process runner are in [probes](probes/). They adapt existing project probes, isolate outputs into this audit folder, and disable XR/audio hardware. Actual museum probes instantiate `endless_museum.tscn`, including its real authored placements and registry resolution. Pointer tests use the actual `XRToolsPointerEvent` API; they are not tracked-hand tests.

Accepted results and paired captures are indexed in [verification.json](verification.json); [verify.py](verify.py) passes 45 independent integrity assertions, including all five `final.md` files byte unchanged and untouched model/control functions. Baseline diagnostic failures remain saved rather than overwritten: the initial launcher inadvertently omitted XR-off and was terminated, while the first staging inventory exposed the two real catalog omissions. They are not successful verification runs.

The changes are intended to support an existing manuscript. They do not establish learner discovery, headset reach/comfort, sustained Quest performance or every supporting artifact's correctness.

## Completed changes

Only two production files were edited by this agent:

1. [field_receivers.gd](../../../../../algorithms/vectors/10_vector_field_flow/field_receivers.gd): moving labels begin CYAN/PINK, then become SET v/ADD to v under RULE. The opening wall invites comparison; the same RULE exposes code and units. Turning RULE off returns to identities. It changes no positions, velocities, local clock, field samples or controls. [Exact diff](field_receivers.diff).
2. [Kinetic map](../../../../../commons/maps/Vectors_Act4a_KineticForces/map_data.json): mower `(8,37) → (9,24)`, ring `(9,24) → (8,37)`, secondary Sisyphus mower `(9,40) → (21,37)` to leave the ring's rear approach open. Four JSON cells changed; all eight full artifact tokens and every structure/utility cell are retained. [Exact diff](map_data.diff).

Root separately repaired map readiness for the two existing secondary scenes, corrected source-aware metadata/objectives and classified the existing parametric pendulum as secondary. Those integration changes belong to the enclosing report; no primary manuscript was rewritten here.

## Verification results

| Probe | Accepted assertions | Scope |
|---|---:|---|
| Motion |34/34| Real museum, pointer controls, force pulse, coast/brake, mass response, damping, rebound, frame, trail, friction-ramp threshold, standing approaches, legacy scene. |
| Fields before / after |47/47 and 48/48| Saved original lesson replay/current lesson in the actual museum; fixed-step sink/swirl/uniform comparisons, units, reverse/gain/reset, labels/reveal, unchanged state under RULE, all eight controls, frame/history, legacy, approaches and actual capture-camera ownership. |
| Kinetic staging before / after |18/18 and 19/19| Actual baseline map/current map; baseline records six loaded plus two omitted, final loads all eight. Final drag→mower→ring order and standing approaches including SPEED console. |
| Kinetic mechanics after |45/45| Physical drag, mass comparison, actual desktop WALK path, constructed XR movement-provider path, ring speed/phase, mower signed return/path/irreversible cut, approaches. |
| Oscillation |48/48| Real museum, analytical tolerance, fixed-step partitions, free/light/critical/heavy damping, grab/release, model frame, controls/route/legacy. |
| Choreography |24/24| Real museum, rod phase/frequency, pointer controls, reach/route, actual rigid-body parcels and receiver. Matched: 6 parcels; backlog: 17; recovered: 6. Admitted minus collected remains the number of bodies. |

Each accepted subprocess exited 0. Watched source hashes remained stable during every accepted run. The selected pairs use identical shared museum source hashes and camera records; Field pairs also have identical computed positions/velocities at four model seconds. Five manuscripts remain byte-for-byte unchanged. All 67 authored artifacts across these five halls are now present in the museum: 17 Motion, 13 Fields, 8 Kinetic, 22 Oscillation, 7 Choreography, with 9 book primaries. This is a presence check, not a comprehensive functional endorsement of every supporting artifact.

## Paired images

- Kinetic [before](before-runtime/kinetic-plan.png) / [after](after-runtime/kinetic-plan.png): actual map before/after, same elevated overview. The main lawn comes before the ring. The two newly admitted secondary scenes also render in the rear part of the hall.
- Kinetic [before approach](before-runtime/kinetic-approach.png) / [after approach](after-runtime/kinetic-approach.png): same standing viewpoint at the approach to the second primary.
- Fields [before](before-field-final/field-observe.png) / [after](after-field-final/field-observe.png): the saved original lesson is replayed in the same current museum, then the changed lesson. Both show the same four-second model state from a 1.7 m camera. Labels identify bodies before disclosing the receiver operation.
- Fields [RULE revealed](after-field-final/field-rule.png): the operation is still available on request through the existing control.

All chosen images were viewed locally. Other museum objects run their own clocks; background phases and transient physics objects need not match. No screenshot is presented as headset evidence. Initial field images had inconsistent camera ownership despite matching intended-camera records; they are retained under `before-runtime`/`after-runtime` for diagnosis and excluded from the accepted Field pair. The revised probe freezes process-driven competitors and asserts that the viewport renders its explicit camera.

## Remaining limits

The map-ready recovery exposed Godot renderer/RID/ObjectDB cleanup warnings at process exit; they are retained in logs. Accepted probes contain no GDScript parse/runtime errors. Startup certificate, registry and cached-resource warnings also remain. The tests do not establish Quest performance, learner discovery, tracked-hand reach, comfort, or absence of every possible collision. The constructed XR provider verifies the movement-adapter code path without an HMD.

No editorial cut is proposed. The only source wording follow-up proposed to root was correcting the ring registry's force/ridden-loop/angular-speed descriptions to match its prescribed path and required acceleration. The chapter already made that distinction accurately.
