# Wave Functions: four middle halls

2026-09-19. Source-aware first-pass review under `doc/book/REVIEW_PRINCIPLES.md`. This is an encounter repair, not a uniform rewrite or a verdict on the final book. Manuscripts, roles, registry, routes and map integration belong to the root agent. This subtask edits three owned artifact scripts only.

## Decisions by hall

| Hall | Decision | Why |
| --- | --- | --- |
| `WaveFunctions_3D_Wave_Propagation` | Strengthen the existing primary with an opt-in comparison. Preserve all secondary works. | Its manuscript asks the visitor to infer a relation. The existing source has both coupling and two useful drive modes, but no visitor control. Same-state comparisons supply missing evidence without replacing the work. |
| `WaveFunctions_Effect_Sound` | Preserve the mature baseline/HOLD/COMPARE encounter and audio. Correct and enlarge its title. | The manuscript already correctly reads the actual phase-modulation formula. The artifact called it simply “FM Synth”; its original title was too small to read from the operating view. |
| `Wavefunctions_Bernini` | Preserve manuscript and artifact; correct description/objectives. | The text already distinguishes change through height from rotation through time. The CPU mesh source supports that. Metadata about vertex-shader/noise deformation describes something else. |
| `WaveFunctions_John_Cage` | Preserve manuscript and audio; qualify source identity and metadata. | The text already distinguishes uncertain scheduling from a finite prepared vocabulary, and does not claim physically spatialized sources or a performance of a Cage score. Metadata should catch up to that care. |

## Propagation: observe the default before changing it

The primary is a 12×12 lattice with fixed horizontal positions. Each node has its own restoring force and damping; displacement differences from up to eight neighbors contribute coupling forces. All forces are gathered before integration. Velocity is updated before displacement: symplectic Euler, not velocity Verlet. The finite grid has fewer neighbors at its boundary.

The shipped natural-frequency coefficient is 2 radians/second; the continuing centre drive is 2 hertz. They are not the same frequency. No retuning was done to manufacture a more spectacular result. An isolated run of the actual original scene, at 1/120-second steps for eight simulated seconds, measured:

| Drive | Coupling | Centre peak | Immediate-neighbor peak | Four cells away | Corner `(1,1)` |
| --- | --- | --- | --- | --- | --- |
| Sine | 1.5 | 504.6 mm | 24.0 mm | 8.1 mm | 2.4 mm |
| Sine | 0 | 501.2 mm | 0 | 0 | 0 |
| Pulse | 1.5 | 1251.0 mm | 352.2 mm | 229.6 mm | 31.9 mm |
| Pulse | 0 | 2480.3 mm | 0 | 0 | 0 |

These are numerical model measurements, not a headset judgement. The default sine response at neighboring nodes is real but visually subtle. The already implemented pulse offers a useful deliberate contrast. Source before/after measurement files are identical.

The opt-in panel has three existing push-button controls:

- **COUPLED / INDEPENDENT:** the original 1.5 coupling or zero.
- **SINE / PULSE:** the original continuing sine drive or the original single velocity impulse after 0.5 seconds.
- **RESET:** repeats the selected condition from the same still state.

Every control resets displacement, velocity, acceleration, drive clock and pulse flag. Switching coupling is therefore a comparison of restarts, not cutting links halfway through a wave. The panel reports the peak absolute displacement of one immediate neighbor since reset and the simulated elapsed time. The comparison uses fixed 1/120-second steps, capped catch-up after a stall; other placements keep their original frame-based simulation unless `comparison:true` is supplied. Existing fabric variants and force equations remain.

Root enabled `coupled_oscillator_lattice#comparison:true` at the existing `(8,13)` map cell. The source never rewrites that map.

### Placement finding

The adjacent secondary `WavePropagation3D` really has colliding moving tiles. The initial west-side panel looked legible, but three body-capsule approach checks intersected those tiles. That failed version is preserved in `propagation-after/` as a diagnostic. A bounded survey found clear standing positions on the east edge. The final panel is local `(2.9,0,1.2)`, facing east; body capsules at local `x=3.8`, `z=0.72/1.2/1.68` were clear in the actual museum. All three buttons remain at hand height.

No secondary artifact, floor, wedge or museum wall was removed. The room still places two representations close together: the primary force-coupled spheres and the secondary analytic tile field. A broader separation or explicit comparison between those models remains a future staging question, not a reason to delete either now.

The secondary's actual default falloff is `exp(-distance * wave_damping)`. Its optional “inverse_square” setting is `1/(1+d)^2` applied to displayed amplitude. Current metadata's universal inverse-square-energy account is unsupported for the default placement. Proposed metadata now distinguishes the analytic field from the neighbor-force model and avoids that claim.

## Sound: name what the code does

The actual output expression is `sin(2π * carrier_freq * t + modulator) * carrier_env`, followed by the existing shaping/gain. It is phase modulation. The title now reads **Phase modulation / FM-style synth**, at a readable scale. Identity comments no longer contain an incorrect carrier-times-sine formula or the universal claim that all timbral complexity is phase modulation.

The complete `_generate_fm_sound` function is byte-for-byte unchanged after newline normalization. No DSP, voice scheduling, mapper, audition controls, scope or desk layout changed. Actual museum images show the original and revised title from the same camera. Background procedural dressing and runtime synthesis-duration numbers may differ; this is not a performance comparison or an audio audition claim.

## Bernini: two coordinates, no new mechanism needed

The source builds rings on the CPU. Sine/cosine offset the ring centre through height; further sine terms modulate radius and centre position, and angular phase shifts vertices around each ring. The rotating shaft/capital is distinct from the fixed base. The repeated arrangement supplies architectural intervals; the generated audio is accompaniment, not a touch response.

The current manuscript already makes the useful distinction between reading a profile through height and watching rotation through time. Its history qualification should stay. No source or prose rewrite is proposed. Metadata corrections replace shader/noise assertions with the actual mesh construction.

## Cage: chance inside a vocabulary

Two continuous layers and a prepared collection of effect variations are played through non-spatial `AudioStreamPlayer` nodes. Luminous forms report activity; their spatial arrangement does not make the sound players positional. The playback code samples a new random elapsed-time threshold each frame. It is not a timer chosen once uniformly from 3–15 seconds. No scheduler change was needed for the manuscript, which carefully avoids that claim.

Only two source identity lines changed: “stochastic timers” becomes the actual per-frame-threshold scheduling, and a promise of “non-repeating” music becomes varied arrangements where recurrence remains possible. The current book's listening experiment, finite-vocabulary argument, proposed visitor-recording extension and careful Cage reference should remain. Metadata about performing 4′33″, physiological noise or a noise-driven wandering parameter is not evidence for this implementation.

## Verification and evidence

- `measures/measurements.json`: original source numerical response at the actual exported settings.
- `after-measures/measurements.json`: identical response after edits.
- `controls/controls.json`: **17/17** focused checks: exact legacy reproduction, pre-tree configuration without duplicate builds, three actual button signals, repeatable resets, independent nodes remaining still, coupled pulse transmission, fixed-step batching, readout and hand-height bounds.
- `propagation-final-after/museum-checks.json`: **14/14**, actual museum loading, one panel, three clear body-capsule approaches, current-camera assertions for all captures.
- `propagation-replay-before/museum-checks.json`: **4/4**, frozen original artifact replayed at its actual museum placement for the accepted paired camera.
- `sound-before/` and `sound-after/`: **4/4 each**, same actual hall and camera; inspected title legibility.
- `integrity-checks.json`: audio generator unchanged; old/new numerical measurements identical; Bernini source unchanged.

All accepted renderer processes exited with code0 and stable watched hashes within each run. XR was disabled and audio used Dummy. Camera-reclaim timers were stopped and the capture camera asserted immediately before and after rendering. No editor/import, headset session, audio listening test, FPS claim or whole-museum validation was performed. Signals exercise the interaction wiring; they do not replace tracked-hand testing.

Accepted images:

- **Propagation before:** `propagation-replay-before/lattice.png` — exact frozen original artifact source, current restored museum room/route, same location and camera.
- **Propagation after:** `propagation-final-after/lattice.png` — same Sine state at2.50 simulated seconds, new panel.
- **Causal comparison:** `propagation-final-after/pulse-coupled.png` and `pulse-independent.png` — both at1.40 simulated seconds after reset, only coupling differs.
- **Sound before/after:** `sound-before/instrument.png`, `sound-after/instrument.png`.

The original `propagation-before/lattice.png` looked into the rear wall because the requested camera was beyond it; it is a diagnostic, not accepted visual evidence. `propagation-before-side/` is a valid earlier viewpoint but is superseded by the matched east-edge replay. The failed west-console capture remains diagnostic and must not be described as the final staging.

In the independent-pulse image the isolated centre sphere has risen above the grid, near the top of the frame; it has not been removed. Its large response contrasts with the coupled neighbors receiving motion. `pair-provenance.json` confirms identical camera records for each pair and identical watched source hashes across the accepted propagation replay/after pair. The Sound pair differs only in this subtask's owned scripts and the root's propagation comparison token among the watched files; the museum loader remains the same.

## Integration handoff

`manuscript-proposals.json` contains four exact old/new replacements for root review: observation-first control instructions and the bounded propagation comparison, plus the Sound method name. It does not duplicate root's transition to Bernini. `metadata-proposals.json` contains eight exact map field replacements. `registry-proposals.json` contains grounded descriptions and the Sound display name. These are proposals rather than hidden edits to shared data.

`source.diff` is against the frozen local baseline, not against an unrelated dirty Git index. `before-sha256.json` records32 frozen files. `MANIFEST.json` records accepted evidence and final owned-source hashes. No Git mutation was performed.
