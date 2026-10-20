# Can the two agents do the scouting job?

Reviewed 20 October 2026. Both desktop agents completed four-map reports. This assessment checks selected consequential claims against the exact source snapshot they received. It is not an exhaustive audit or a runtime test. Neither agent was asked to implement a floor.

**Yes, as scouts with review. Claude produced the stronger implementation brief. Antigravity contributed useful architectural proposals, but several descriptions and proposed tests contradict the supplied code. Do not hand either report straight to a builder as a verified specification.**

## Comparison

| Question | Claude Code | Antigravity / Argon |
|---|---|---|
| Preserves chosen tutorial focus | Stronger: separates the eight-value shelf from the wider reflective route; correctly identifies Noise One's signed-value remapping | Partial: expands the Randomness lesson toward the whole hall; Noise One describes different controls |
| Finds architectural uses | Cabinet as partition, digit page as cladding, weather walls as building partitions, terrain as an excavation | Weather partitions, suspended column head-frame, terrain basin and a contained moving-point encounter |
| Distinguishes visual and physical geometry | Explicitly defers a walkable terrain conversion | Recognizes collider differences but advances a walkable basin proposal without enough supporting checks |
| Understands loading order | Correctly flags pre-ready configuration for columns, seed apparatus and return apparatus | Incorrectly claims the columns re-stage after ready; overstates the basin's risk for the requested trial path |
| Proposes tests against real APIs | Better aligned; still requires fixture and timing corrections | Several named methods and signatures are absent or wrong |
| Supply line | Explicit that it currently has no power contract | Acknowledges this, but elsewhere describes the bus as carrying the seed and misclassifies the Geiger source |
| Can prove a finished floor works? | No: source scouting only | No: source scouting only |

## Checked findings

**1. Claude found a real integration blocker.** In `sources/commons/void/floor_content.gd:244–252`, configuration normally arrives after `add_child`; `configure_before_ready` selects the other route. `MeltingBerniniColumns.gd:140–155` decides whether to build the trio in `_ready()`. Its `apply_grid_config` at 717–728 only assigns values; it does not rebuild the scene. Claude identified this. Antigravity's claimed `_enter_stand()` rebuild is absent. A targeted catalog entry or adapter needs testing before this trio is placed.

**2. Antigravity used the wrong Noise One interaction.** It described “FLOW / SNAP” and “SMOOTH ↔ STEP.” The captured `noisetorus.gd:459–470` builds **FREEZE, SAMPLE, AMPLITUDE, FREQUENCY, REMAP**. Claude used these actual controls and kept the distinction between the field, relief and colour mapping. This matters pedagogically: a plausible alternative lesson is still the wrong lesson for the present artifact.

**3. Some Antigravity tests would fail before testing the proposal.** Its `compare_state()` and `set_requested_count()` calls are absent from captured `randompoints.gd`; the inspection method is `sampling_state()` at 675. Its two-argument `choose_layer(1, "...")` contradicts `noiselayers_stage.gd:67`, which accepts one integer. These are test sketches requiring correction, not runnable acceptance tests.

**4. The basin warning needs the actual loading path.** The basin reads `config_stand` in `_enter_tree`, and its later config method is empty. However, the requested trial loader stamps that metadata before adding the artifact (`floor_content.gd:237–248`). Claude recognizes that this path supports the basin. Antigravity correctly describes a failure if metadata arrives too late, but a late-metadata example does not establish that the requested trial is broken.

**5. Seed identity must remain exact.** Antigravity calls the Geiger artifact independent of the shared bus. The captured `geiger_counter.gd:43–45` binds to HallSeed and implements its seed callback. The cable is decorative; the software scope supplies the relationship. It also assigns Related Weather seed 435; the captured `related_weather.gd:12` defaults to 4321. These distinctions must survive the “alien technology” interpretation.

**6. Claude found a useful desktop input conflict.** The crank listens to Space and R (`prng_crank_machine.gd:291–297`), which the Void documentation assigns to jump/retry. That is a concrete integration risk worth an actual input test. It has not been reproduced in a running trial during this review.

## What to keep—and what to tighten

Keep the shared insight that **Related Weather can become a partition because its existing fixed glass already blocks bodies while its shutters alter sight**. That lets the building demonstrate the artifact's rule. Both agents understand this distinction.

Use Claude's **Random_Noise_Types first** recommendation as the smallest architectural trial. Its six records can preserve the existing encounter sequence, with the sampling bench teaching the chosen operation and the weather walls shaping the route. “Zero required adapters” remains a source-level expectation; model bounds, input, streaming/audio and editor roundtrip still need checking.

Retain Antigravity's suspended head-frame as an alternative for Noise Columns, after fixing loading order and dimensioning the frame. The columns' roughly 2.77 m tops do not meet the 4.8 m bus; the proposed lower frame needs an explicit elevation and support.

Claude still needs corrections before implementation:

- Freeze Noise One before testing REMAP invariance so elapsed field time cannot masquerade as a mapping change.
- Specify an idempotent `set_powered(on)` adapter. Repeated calls must not toggle the artifact unpredictably; preserve seed, recorded data and held phase.
- Replace placement estimates with measured scene bounds, route clearances and reachable controls.
- Treat the glassless terrain cut as a proposed assembly, not a proven walkable surface. Test collision rebuilding with a controlled probe first.

Both agents correctly noticed missing dependency files in our packet. That is also a limitation of our briefing: all 182 copies passed their hashes, but the packet was never a complete runnable dependency closure. Before implementation, provide the missing shelf adapter and the relevant player/streaming sources, rather than asking an agent to infer their behaviour.

## Decision

**Scouting test succeeded: both read the project and returned grounded proposals. Reliability differs: Claude is the preferred basis for the first trial; Antigravity's report needs factual repair before reuse. Implementation capability has not yet been tested.**

Keep the original final.md and tutorial.md unchanged until a trial's spatial changes are demonstrated. Then revise only the location-dependent passages and teach the actual new operation.

Evidence retained from the desktop UI:

- [Claude report — captured accessibility text](runs/claude-report-uia.txt)
- [Antigravity report — captured accessibility text](runs/antigravity-report-uia.txt)

These captures preserve the observed report sections; accessibility formatting includes nested duplicates. They are agent claims, not independently verified facts.
