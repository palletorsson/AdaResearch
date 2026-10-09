# Wave Functions opening: preserve the return, repair the projection

19 September 2026. Scope: WaveFunctions_Intro, WaveFunctions_Pendulum, WaveFunctions_Sine_Space, WaveFunctions_Unit_Circle. This follows `doc/book/REVIEW_PRINCIPLES.md`: recover the encounter before cutting the argument, and match effort to the maturity of each hall.

## Decisions

| Hall | Judgment | What already works | Bounded action |
| --- | --- | --- | --- |
| Intro | Preserve manuscript and encounter; targeted source description repair | Two visits to the ring are distinguished by signed velocity; release supplies a new beginning without erasing the counter; hand velocity is projected into the permitted swing | Correct header claims that harder swinging means faster oscillation or that length alone fixes every period |
| Pendulum | Preserve | A retained position gets spatial depth through age; FINE/COARSE/STROBE expose different recording purposes and two retention limits | Update stale primary-learning metadata; retain secondary recorders and the existing source |
| Sine Space | Preserve encounters and main text; targeted transition repair | A colliding stationary tray and noncolliding moving walls give a periodic value different bodily consequences | Direct its final paragraph to Unit Circle; clarify the configured corridor in source identity/registry rather than describing script defaults as the installed scene |
| Unit Circle | Targeted encounter repair; preserve manuscript | Four positions and a graph prediction precede naming sine/cosine; the finite build and unverified route are explicitly acknowledged | Repair the rods' local/world coordinate error, then remove universalising claims from source identity and propose metadata that describes the actual projection |

All 42 authored placements remain: 21 Intro, 10 Pendulum, five Sine Space, six Unit Circle. Every token resolves to an existing, map-ready scene in the opening source chain. No promotion, removal, new artifact or map edit was made by this subagent. The intended sequence remains **returning state → retained history → periodic space → circle/projection reveal**. Experiencing Sine Space first is a deliberate strength, not a textbook-order mistake.

## The substantive repair: Unit Circle

The manuscript asks the visitor to follow the turning point and compare its projections. The scene supplied those rods, but `_update_line_node` mixed coordinate systems: it assigned a local midpoint, then passed local midpoint/end coordinates to the world-space `look_at_from_position` method. An artifact left at the world origin concealed the fault. Translation and rotation exposed it.

The initial isolated Godot probe passed all six identity-frame assertions but failed five of six checks under a translated, 90-degree-rotated parent. The radius, sine and cosine rod centres were about 11.6–12.1 m from their intended position in that deliberately small test fixture. Those distances describe the fixture, not a measurement of the production museum.

The repair preserves the local midpoint and assigns a local `Basis.looking_at` orientation. It retains the existing alternate up vector for vertical rods. This also makes the helper valid while constructing rods before they enter the scene tree. No graph sample count, animation speed, collision switch, scene placement or public control was changed.

A saved-original replay and repaired source then ran the same 102 checks: identity, translated/rotated and tilted/nonuniformly scaled parents; angles 0, π/2, π and 0.7; radius, both projections and both thinner caps. Collapsed zero-length projections get a centre check but not a meaningless axis check. The saved original fails 51 assertions; the repaired code passes all 102, with zero measured centre error. Nonzero rod directions agree with transformed endpoints. This restores an existing pedagogical promise instead of weakening the book to accommodate a broken drawing.

The isolated fixture uses eight samples and one cycle with bridge collision disabled to keep this geometry test small. It instantiates the real artifact script and exercises its real drawing helper. It is not a new actual-museum capture, route test or headset visit. The finite default scene still builds 400 steps across two allotted cycles, then stops. The manuscript's completed-graph fallback remains appropriate. Broader staging of that large construction remains outside this repair.

## Source findings and secondary ecology

### Intro

The primary integrates `-(g/L) * sin(angle)`, angular velocity, regime damping and angle on physics steps. In the placed free regime there is no drive. Grabbing suspends the integrator; dropping averages recent world-space motion, converts it into the artifact frame, and retains the tangent component as angular velocity. The plumb ring counts moving sign changes. The predicted six-second trace is integrated from the standard 0.3-radian start; it is not a measurement of the visitor's last release, and should not be called a linear small-angle prediction.

The current prose already makes those distinctions. Its equations follow the two observed crossings, and its tangent equation follows a second hand experiment. Multiple beginnings are necessary to the argument: engine time, retained count, prediction and release.

The secondary collection is not redundant. The Y cube prescribes a sine from time; the rotating demonstration accumulates an angle; the controlled cube listens to the pendulum signal; the Mario time trace records its own prescribed-motion child rather than the pendulum. Pick-up and transformation variants preserve the prior chapter's bodies. Spherical harmonics and the science screen remain supporting material. No evidence warrants removing these works to enforce a primary quota.

One inherited secondary implementation detail is recorded rather than silently fixed: `oscillation_controlled_cube` uses `get_process_delta_time()` while accumulating heading in the pendulum's physics-step signal callback. Its present manuscript makes no quantitative clock-invariance claim. A controlled render-rate comparison and time-base repair, if needed, would be separate work. No such test is claimed here.

### Pendulum

`PendulumWave` retains `(x,y,sample_time)` and maps age to depth at 0.6 m/s. It samples at most once per physics tick; the current bounded remainder prevents a backlog when the target interval is shorter than a tick. FINE requests 25 ms, COARSE 200 ms and STROBE a measured full period. The two retention rules remain 300 marks and ten seconds. RESET resets this experiment, not the museum.

The 60 Hz timing in the chapter is supported by the historical runtime measurement: actual FINE gaps are 16.7–33.3 ms. It must not be advertised as independent of the configured physics tick rate. The scene itself reports that rate.

Secondary sources offer other representations: a drum rotates beneath a needle; the Foucault rig accumulates a rosette under an exaggerated precession rate; WavePaintings includes double-pendulum canvases; the time-domain drawing point gives a related recorder. The lab table, glass rack, pipe and monitor retain the laboratory setting. The primary chapter does not need to teach every one of those works now. Proposed learning-objective metadata describes the present record experiment without claiming that the secondary double pendulums do not exist.

### Sine Space

The tray releases 32 equal-mass spheres. SIZE changes radius between trials; RELIEF rescales one fixed sine-product sample arrangement. A collision mesh supplies contacts. A twelve-second deadline freezes remaining bodies; exited bodies are parked in rows and removed from collisions. Neither the code nor the current prose equates STILL IN with permanent trapping. The one-variable comparisons and the observation window should remain.

The corridor's shipped scene overrides its script defaults: length 7 m, width 2 m, height 4 m, eight rows, base frequency 4.5, amplitude 0.2, equal wall multipliers, animation speed 0.35 and wall collision disabled. Its thin floor slab supplies support. PHASE changes the relative offset, not the animation clock. With a half-turn offset every term changes sign and the measured local-X gap stays two metres; this is not a theorem about shortest body clearance. The book correctly distinguishes frozen walking from advancing a multilayer phase.

The explanation case and the existing sphere floor remain. They receive related rules in different forms; the tray did not displace those encounters. Earlier reports explicitly retained the corridor when adding the forecourt.

The only required prose change is its final handoff, which still followed a shortened route to Effect Sound. The exact old/new paragraph is in `manuscript-proposals.json`. It now invites following a circular point and predicting the adjacent graph, without prematurely explaining the projection.

The 13 September corridor report also records per-frame wall rebuilding cost on one desktop. It is useful development evidence, not a fresh Quest benchmark. This pass does not change a shared performance characteristic across its other placements or claim headset comfort.

### Unit Circle

The default scene shows both projection rods while unfolding the sine coordinate. Alternate correspondence configurations exist, but the scene has no visitor speed/reset panel. The graph is sampled and finite; its collision boxes do not establish a usable route through the hall. The text already describes observation and a completed-build fallback rather than promising those controls or a verified bridge walk.

The supporting oscillating bridge and oscillation curve are retained, along with the cube and colour balls. They are potential later comparisons between a plotted value and a moving carrier. They do not make every wave a disguised physical rotation. The source identity and proposed metadata now state a particular coordinate construction.

## Production changes and proposals

Three owned scripts changed:

1. `commons/artifacts/control_pendulum/control_pendulum.gd`: comments only. Qualify the small-angle period, identify nonlinear/damped/optionally driven behavior, and remove “swing harder = faster”.
2. `algorithms/wavefunctions/sine_wall/SineWallCorridor.gd`: two identity comments only. State the configured seven-metre noncolliding scene and the actual phase-update/rebuild mechanism.
3. `algorithms/wavefunctions/unit_circle/UnitCircle.gd`: restrained identity comments plus the two local orientation assignments described above.

Exact original bytes and SHA-256 values are in `before-source/` and `before-sha256.json`. The intermediate comment-only Unit Circle script was also saved before its executable repair in `before-executable/`. `source-changes.json` and `source-changes.diff` record complete original-to-final diffs. An executable-line comparison confirms the other two scripts are comment-only changes.

Root owns manuscript and metadata integration. `manuscript-proposals.json` contains one exact paragraph replacement. `metadata-proposals.json` contains precise old/new fields for the opening objectives, stale Unit Circle map descriptions/tokens, registry descriptions, Intro's incorrect “constant rotation, no return”, and Pendulum's target-sampling wording. These are proposals, not a claim that this subagent applied those files.

## Earlier evidence recovered and its limits

`historical-evidence.json` records report hashes, dated-manifest comparisons and frozen-review source matches. Five current primary scripts matched the 18 September review package byte-for-byte before this pass: control pendulum, PendulumWave, corridor, Unit Circle and tray. The reviewer therefore inspected the relevant current implementation, but could not execute it.

The local archive contains later evidence than some old summary files suggest:

| Historical report | Checks / failures | What it exercised |
| --- | --- | --- |
| Intro live, described in the 13 September field note | 58 / 0 | Actual desktop right-click pickup/carry/drop from both sides, separate signal-driven model lane, signed crossings and clearance |
| Pendulum live, 13 September field note | 81 / 0 | All four desktop buttons, two render caps with the same physics-step record, eviction and the bounded slow-step sampler |
| Corridor live, 13 September field note | 84 / 0 | Actual desktop sliders/buttons, a 720-state clearance calculation and the player's collision body through the passage |
| Sine tray report preserved as `report_2026-09-12.json` | 41 / 0 | Actual museum placement, route casts, synthetic desktop controls, SIZE invariance and finite full-trial accounting |

These are historical reports, not tests rerun today. The stronger Intro/Pendulum/corridor reports do not embed a complete tested-artifact hash manifest. Their notes explain subsequent repairs, but they cannot establish that all current shared museum/interaction dependencies are unchanged. The older 10 September source fingerprints differ from the present scripts and should not be silently presented as current proof.

The tray has stronger direct provenance: its script, scene, registry entry and probe still match the 12 September SHA-256 manifest exactly. Its pre-pass final/tutorial/critical text also matches. The room JSON and technical chapter no longer match that older manifest, so that agreement does not certify the entire present room. The root pass separately audits the repaired twelve-hall route.

The earliest Intro script-only report skipped its required grab path and is not accepted as interaction evidence. Later live reports explicitly correct that omission. All retained reports state that headset testing is still pending. Older raw captures can be inspected as dated evidence; none is relabeled as a new before/after image for this pass.

## New verification

`verification.json` inventories the new runs:

- First tiny probe: native startup crash while rotating the shared `user://logs` file; no assertion result. Preserved as a harness diagnostic. Subsequent runs use an explicit unique `--log-file`.
- Initial transform baseline: 12 assertions, five expected failures, clean script compilation and exit 1.
- Saved-original replay: 102 assertions, 51 expected failures, exit 1.
- Repaired source: 102 assertions passed, exit 0; maximum rod-centre error 0 m.

All completed assertion runs keep source hashes stable. The replay and final run use the same probe. They use hidden headless Godot processes with XR off and Dummy audio; no editor/import and no shared museum edits. Existing UID/certificate/autoload warnings are recorded in the raw logs and are distinct from a script error. No new GPU, actual-museum or headset run was made for these opening halls.

## Stop condition and next work

This bounded opening pass is complete when root integrates the transition and chosen metadata fields. Do not rewrite the three mature experiments simply to match the effort needed by later halls. Their remaining human questions—ring legibility, remembered versus moving marks, bodily response to noncolliding folds and projection readability at museum scale—remain valuable headset observations. The substantive source repair restores a relation the Unit Circle chapter already asks the learner to discover.
