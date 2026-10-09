# Astra receipt — Claude handoff, 23 September 2026

Read the handoff and both complete revised pilot chapters, their DECISIONS files, the relevant implementation and probes. Briefly checked the four earlier chapters and the word-key map placements. This is a source and manuscript assessment, not a new runtime or headset acceptance. No canonical manuscript, scene, map or original Claude delivery was changed during this receipt.

## What carries forward

Preserve the six current manuscripts rather than restoring older review-page copies over them. The Trace carry, retained carve, selectable cloth support and recurrent cell are useful new encounters. Keep their opt-in scope visible when writing about another placement of the same artifact. Continue to distinguish source, arithmetic, input wiring, bodily routes and headset experience.

EDGE_INVENTORY.md is a useful index for locating a specific condition in an artifact. Its sweep counts and verification descriptions remain reported provenance, not fresh independent validation here. Use it to discover a relevant encounter, not to require every chapter to end with refusal: a boundary can also support, shelter or make an operation possible.

## Findings that need attention

### 1. The two memory histories need the same starting state

The chapter asks the visitor to carry pale/dark, then dark/dark. It does not clear the retained state between these runs. The probe calls run_history(), which resets before each history; token polling calls recurrent_step(), which does not.

At f=i=o=0.5, fresh pale/dark gives h=-0.125 and fresh dark/dark gives h=-0.375, as written. Continuing directly with two dark tokens after the first history instead gives h=-0.40625. The reader’s described action therefore does not reproduce the numerical comparison.

The source already permits a reset through the rule: f=i=0 followed by one token makes c=h=0. There is no visitor RESET control shown by this implementation. The revision should teach that clearing gesture and restore the same gate settings before each trial, or build and verify an explicit reset encounter. Do not silently describe the probe-only run_history helper as an available action.

References: `algorithms/machinelearning/LSTMs/LSTMs_VR.gd:737`; `algorithms/machinelearning/LSTMs/LSTMs_VR.gd:552`; `algorithms/machinelearning/LSTMs/LSTMs_VR.gd:718`.

### 2. Name which difference is being measured

The prose says the gap between the histories is exactly twice forget times input. For the two specified two-step histories, from the same initial state and with fixed gates, that is the gap in c. The output gap is 2*o*f*i. With all three gates at 0.5, these are 0.5 and 0.25 respectively. The slab is driven by h, then converted to height by a 0.9 factor and clamped.

Suggested direction: “The two histories leave different amounts in the cell. The forget gate decides how much of that difference survives; the output gate decides how much reaches the slab.” Keep the exact arithmetic if useful, but identify c and h separately and state the comparison’s conditions. “To six decimals” belongs in evidence, not as a promise about a visitor’s hand-set experiment.

References: `commons/maps/ML_Sequence_Memory/final.md:26`; `algorithms/machinelearning/LSTMs/LSTMs_VR.gd:578`; `algorithms/machinelearning/LSTMs/LSTMs_VR.gd:718`.

### 3. Pin count does not settle re-hanging

The handoff correctly rejects “only REBUILD restores the full edge”: PINS can select two and then eight points after RELEASE. The canonical sentence is narrower/different: “REBUILD is the only control that hangs them again.” Restoring the pin set does not establish where those points are pinned after the cloth has fallen. The existing pin-count probe cannot decide that physical claim.

Do not replace it with “PINS hangs them again” on this evidence. A narrow safe wording is “REBUILD makes a fresh hanging rank.” If exclusivity matters, compare actual vertex positions after falling, re-pinning and rebuilding. Also keep the cloth’s ordinary settling distinct from any claim that changing a frame cannot affect its motion.

References: `commons/maps/SoftBodies_Cloth_Physics/final.md:37`; `commons/artifacts/timing_machines/soft_workshop.gd:127`. The hem-height question remains with the author’s other session; no revision or runtime conclusion here.

### 4. Gate height is a mapping, not a direct value

_gate_value() uses clamp((local_y - 1.0) / 2.0, 0, 1). Zero includes the whole region at or below local y=1, half is y=2 and one starts at y=3. The opening’s “height is its value” and the later “half height” should not be read as a literal floor-to-maximum linear mapping. “Height sets its value” is safer; demonstrate the reference range when this hall receives its embodied pass.

Reference: `algorithms/machinelearning/LSTMs/LSTMs_VR.gd:487`.

## Limits and next action

No full runtime validation of the six changed halls was performed here. Grabbable methods and emitted signals are not physical reach evidence. The recurrence probe checks the update by directly setting gate activations and calling methods; it does not establish the written hand-operated route. In particular, output values are not metres and negative slab positions require a visibility check in the actual placed hall.

The two pilots are promising development, not yet fully reconciled book/encounter deliveries. Leave Claude’s original notes intact and apply narrow corrections with before/after evidence when taking up these halls. Current active Colour pass remains complete through Color_Walls; next is Chamber_Color. This handoff does not require reopening mature Colour halls or reverting earlier work.

## Current manuscript identities

These hashes identify what was read, so later changes are not mistaken for the assessed versions.

- `commons/maps/Point_One/final.md` — `032f8ff69e4007f8404adb5a6c15ad9ab54a8a73fd810d1a445d7e5c74e295aa`
- `commons/maps/Point_Triangle_Context/final.md` — `6d932ef3d8873827c760d28b55cc54e3d17ccd1b02b9bd335dd2fcb4a8e1cef3`
- `commons/maps/Primitives_Melencolia/final.md` — `cf64c20ce8480490eb12ac72a1bf43b1a7a18683850b9cfae65d9c00337cd828`
- `commons/maps/Trans_Body/final.md` — `e0d025f8cd420bdbfa831c498020787fe6ec3d440e428d617f575f25912cad3c`
- `commons/maps/SoftBodies_Cloth_Physics/final.md` — `618df485a8a16c79996ae8ad413e5cf58fb5976cf96bdca41fe047e22bcdeb38`
- `commons/maps/ML_Sequence_Memory/final.md` — `3c202ddc4878534bbe048e05c0de5b62c6c766dd71b9ec308ab108a9c0d9b738`
