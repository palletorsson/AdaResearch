# Returning, choosing, inhabiting

A handoff plan for Fable 5.1, prepared 10 September 2026. **35 map plans; 19 active museum halls; 16 authored extension maps.** All 35 already have a final.md and matching source primary/book anchors. The work is to improve the encounters and revise the prose together. Fable has implemented the three pilots and W1 (Pendulum and Sine Space). Astra has reviewed and corrected their sources and texts; runtime acceptance is pending. [Current W1 review and next checks](w1-review.html); [earlier pilot review](pilot-review.html).

Open the guide: http://localhost:3003/research/waves-chance-noise/index.html

Give the implementing model [HANDOFF.md](HANDOFF.md), [NEXT_BATCH.md](NEXT_BATCH.md), this directory, and access to the repository. The working rhythm is to choose the primary encounter, improve what a visitor can do and observe, discover a consequence, write from the implementation, and carry that understanding into the next hall. W1 is now delivered and source reviewed. The next action is to run the three pilot probes followed by both W1 probes, inspect captures and check the headset interactions. Effect Sound is the next development hall; it has not started. Each map has a separate instruction card under `maps/`, and `all-maps.md` collects them for a single-file handoff. `plan.json` is the editable editorial source; `audit.json` records current placement, primary, book and direct scene-resource facts with source fingerprints.

## The red thread

**Waves:** a return becomes a rhythm; the rhythm leaves a record, shapes a passage, modifies a sound and joins other rhythms. The distinction between an integrated physical model and a prescribed periodic function matters throughout.

**Randomness:** a procedure chooses among possibilities already defined. Seeds, candidate sets, distributions, accumulated steps and state transitions specify different freedoms. Repetition of a procedure can produce the same surprise.

**Noise:** variation gains spatial relationships. Sampling and interpretation turn a field into colour, relief, occupancy or a world that can carry a body. Different representations and different algorithms must be compared under declared conditions.

These sequences have different ontological questions. A rhythm needs a rule and a reference for progression; a random procedure needs an outcome space and selection rule; a noise field needs a domain and a sampling/mapping contract. None of these supplies collision, a memory, life or intention by itself. Each new connection becomes a concrete research result when implemented and tested.

The current spine places Formfinding before Waves and Cellular Automata after Noise. Follow those actual neighbours in the main-route prose. The old sequence lists contain additional chapters whose final transitions sometimes still name other off-route rooms. Preserve useful text, but repair those handoffs when shipping the active route.

## Working order

**Structure prerequisite completed:** the Wavefunctions platform/wall distinction is restored in all twelve authored maps, without activating extensions or replacing current artifact arrangements. [Recovery report and images](recovery.html). The six active halls have fresh geometry evidence; sound-controller initialization remains an explicit follow-up for Fable.

**Three-sequence follow-up:** 17 maps corrected across Randomness, Noise and Cellular Automata, restoring 294 interior platform cells and preserving access with two spawn relocations and one exit landing. [Source diagrams and exact scope](structure-recovery.html). Source checks passed; the new physical probe remains unrun. Cellular Automata is included in this structure audit, without expanding Fable's current development assignment.

1. **Source baseline:** reconcile the 19 active halls with the 35 authored plans; preserve old map structure and uncommitted work.
2. **Three pilots:** WaveFunctions_Intro, Random_Definition and Noise_Perlin_Simplex, each as a complete space/text/evidence package.
3. **Astra review:** inspect the diffs and experiments, revise weak solutions, and select methods that deserve a second use.
4. **Active-route batches:** finish the remaining five Waves, six Randomness and five Noise halls, two or three at a time. Noise Columns and Voxel need particular care with their claimed drivers and links.
5. **Extension batches:** develop the other sixteen maps and their texts as standalone rooms. Decide later which earn space in the main walk; do not silently expand the route.
6. **Sequence reading:** read the final texts consecutively and walk the same order, checking that every new capability is introduced before it is needed and each closing question reaches the right room.

## Source findings that drive the plan

- The initial 35 finals were approximately 390–490 words each; revised pilot lengths now differ. Their presence and anchor agreement are useful scaffolding, not a verdict on voice or interaction quality.
- Sine Space's scene enables animation but disables collision. Its passage cannot be described as a changing physical barrier without further work.
- PendulumWave retains a finite trail; rendering cadence participates in how samples are recorded.
- Noise Columns has a sine-driven geometric melt cycle plus material shading. Its older Perlin-erosion and reversible-entropy descriptions are misleading.
- Noise Voxel's bench and receiver use different fields and mappings despite shared controls.
- Noise Inside Noise directly samples a field; a real domain-warp comparison remains to be built. An existing warp pair in `the_same_cloud` is a reuse candidate.
- The original Perlin/Simplex comparison used simplex-family bases on both sides. The corrected pilot now explicitly selects Perlin on one side and declares matching sampling/display settings; runtime verification remains pending.
- Several source artifacts already support useful variants, but configured options are not necessarily player-facing controls.

These are code and source-document findings. The subsequent platform recovery ran desktop museum geometry probes, documented separately in the recovery report. No headset verification has occurred. Fable must verify the configured interactions after changing them.

## Scope boundaries and coordination

Do not restore the explicitly deferred Chamber_Waves, Chamber_Random or Chamber_Noise. Noise_Blue, Noise_Functions and Noise_Volume are also outside the 35 authored maps covered here; leave them as future material. Keep all current map names, including the case in `Wavefunctions_Bernini` and `Wavefunctions_Sky_Stairs`.

The Nails control plinth and Rainbow celebration work is separate and still awaiting final documentation/publication. Its last recorded desktop reports contain 33 and 93 passing assertions respectively, but subsequent Rainbow visual adjustments have not been rechecked. This is coordination context, not fresh verification. Fable should leave those files and the colour-to-forces guide untouched.

To regenerate the source snapshot and rendered cards, run `python tools/build_waves_chance_noise_plan.py`. The tool writes only this plan directory and does not alter the museum, role data or book. It validates exact coverage, nonempty map instructions and existing proposed lead tokens. Publishing to the local encyclopedia requires copying the generated directory to its `public/research/waves-chance-noise/` folder. The URL is local to this machine, not an external deployment.

## Plan publication checks

The 35 cards, 19 active/16 extension classification, three pilots and all local Markdown/HTML links were checked. Forty-two published files returned HTTP 200 and matched their source bytes. All 705 recorded source fingerprints were current at verification. The guide's JavaScript passed its syntax check; browser testing confirmed sequence/workset/search filters, deep-link expansion and filter reset. One expanded desktop card was visually inspected. Evidence is in `verification.json` and `ada_run/waves_chance_noise_plan_check.json`. These checks concern the instruction guide, not completion of any proposed museum improvements.

The platform-recovery follow-up published 46 files, all returning HTTP 200 with exact source bytes. All 705 source fingerprints were checked again. The recovery page was inspected in the browser, and both Godot captures were visually reviewed. Publication evidence: `ada_run/wave_recovery_publication.json`.
