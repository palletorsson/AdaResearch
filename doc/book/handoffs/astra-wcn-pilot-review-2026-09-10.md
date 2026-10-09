# Astra review: Waves, Randomness and Noise pilots

10 September 2026. **Source corrections complete; runtime acceptance pending.** No commits made. This review supersedes the open decisions and source status in Fable's original handback; that handback remains a record of what was delivered.

**Subsequent instruction from Palle:** make progress through the next halls in the same manner as the earlier work. The [new W1 handoff](http://localhost:3003/research/waves-chance-noise/NEXT_BATCH.md) permits independent development of WaveFunctions_Pendulum and WaveFunctions_Sine_Space while the pilot runtime checks remain open. It supersedes the waiting order below, without changing any evidence or acceptance status recorded in this review.

## What is worth building on

The three encounters form a useful thread through repeatability:

- **WaveFunctions_Intro:** returning to one position does not mean returning to one state. The two directions through the centre become legible in signed angular velocity.
- **Random_Definition:** a surprising picture can be reconstructed. A seed, draw order and colour mapping together account for its return; discarding one draw changes the channel grouping.
- **Noise_Perlin_Simplex:** repeatability makes comparison possible. Sampling and display settings must be held steady before a visible difference can be attributed to a generator.

The finals now invite an action before explaining it, quote consequential lines of the actual code, and leave a specific question open. The criticism is strongest where the mechanism exposes its own reduction: a hand becomes a projected velocity; a stream becomes colour triples; a field becomes a finite set of cubes. These are promising experiments, not yet accepted museum installations.

## Corrections made

| Area | Problem found | Correction |
|---|---|---|
| Pendulum release | The tangent had the opposite sign from the bob's position formula; a throw could launch the opposite way. World velocity was used as local velocity. | Corrected tangent and transformed hand velocity into the pendulum frame; bob placement now respects the root transform. |
| Seed replay | The museum configures artifacts before adding them to the tree. The demo discarded that configuration until it was built. | Retain seed/comparison settings before readiness; rebuild only once built. |
| Noise coordinates | Creation and update used different row widths and swapped spatial addresses. | Update each cube from its actual local x/z; probe checks the rendered sample against that address. |
| Noise settings | The Simplex scene's 2D gain slider supplied 0.1 while Perlin used 0.5. Appearance also differed in reflective finish. | Both placements explicitly declare frequency 1, amplitude 0.8, gain 0.5, four octaves. Shared ramp also uses matching finish. |
| Noise observation | One readout coordinate was outside the visible field; labels were not consistently reading the generator. | Both use (-1,0.5) and (1,-1), inside the fields. Both readouts and panel headings use the actual generator. |
| Noise return | Restoring only the seed did not restore a comparison after changing sliders. | REPLAY restores the declared frequency and octaves as well as the seed and handle positions. |
| Museum placement | Fable's global authored-map exemption would re-layout six other randomness halls without review. | Only the three pilots opt into `museum.artifact_placement: "map"`. Other halls retain the prior hand lookup. |
| Registers | Removed terrain still had a role/book entry; pendulum's primary note described a prescribed sine. | Removed the stale terrain references, corrected the pendulum note, and declared its reference DNA axis. |

The Noise hall's floored basin, removed conversion piers and retained small terrain remain as Fable arranged them. I did not restore the 100-metre terrain. Its previous configurations remain archived.

The noise technical chapter now describes this installation rather than promising perfect isotropy or unmeasured speed advantages. Godot's `TYPE_SIMPLEX` is OpenSimplex2; the original simplex corner-count argument is not a benchmark of this implementation. [Godot 4.6 FastNoiseLite documentation](https://docs.godotengine.org/en/4.6/classes/class_fastnoiselite.html).

The pendulum critical addendum distinguishes state-dependent integration from prescribed motion without claiming that either establishes or refutes a philosophical account. Earlier critical notes remain historical material requiring further editorial review; they are not validated by this source check.

## Evidence obtained

- Ten changed GDScripts parse with gdtoolkit. The changed museum section parses separately. A full-file gdtoolkit scan stops at an unchanged multiline label at line 4072, also present in the before-copy; this is not an engine compilation result.
- All three maps pass pathfinding: Intro 133/286 cells, Random 218/286, Noise 149/195. These counts do not establish hand reach or collision-free artifact installations.
- All 41 artifact placements resolve to source scenes. The four primary tokens exactly match the four book anchors, with no stale pilot tags.
- Each nonempty line of the six final code excerpts occurs verbatim in its cited script after removing indentation. Reduced excerpts are labelled.
- The sampled book citations resolve. The pendulum note now cites the corrected addendum.
- The persistent wave geometry check passes: 12 maps, 193 interior platforms and 137 explicit perimeter walls. The checker allows encounter edits and never regenerates plans. `--snapshot` is available for checking the original complete recovery state.
- The corpus tag check still reports four unrelated stale tags: Point_Line_Grid/simulation_grid, Point_One/folding_past, Trans_AxisDecomposition/mario_cube and Tutorial_Single/pick_up_cube. They were left outside this review.

Machine-readable source evidence: `ada_run/waves_chance_noise/astra-source-checks.json` and `ada_run/wave_platform_contract_checks.json`.

**No corrected pilot has been run in Godot or walked in a headset during this review.** Earlier platform-recovery captures are evidence for the recovered structure, not for these new encounters.

## The next actionable improvement

Run the three museum probes serially once the existing Godot process has closed. Inspect failures before changing placements; inspect the resulting pictures before accepting the batch. The probes now test pre-arrival crossing counts, release direction, noise spatial addresses, shared gain and finish, and the REPLAY button after moving both noise sliders.

Use `--headless` without `--capture` for logic-only runs. For pictures use a rendered window with `--rendering-method gl_compatibility`; the probes now reject headless capture rather than hanging on a render event. Updated commands are in `ada_run/waves_chance_noise/2026-09-10-pilots-batch.md`. Automated windows should be hidden. Every run must use the watchdog and finish before the next starts.

The project rule in `CLAUDE.md` says “never run two Godot instances at once”. PID 2780 was still running at the final process check. It was left untouched because its ownership and current work were not established.

After runtime review, a headset pass must assess grip, panel reach, readability, swing clearance and passage. A programmatically emitted interaction signal does not establish tracked-hand usability.

Then Fable can continue with the neighbouring active halls in batches of two or three. The first candidates for reuse are a recoverable comparison state, a readout tied to the actual calculation, and a preserved platform/wall contract. Keep these as methods to test in a second context before extracting a shared framework.

## Changed sources and preservation

Before-copies and SHA256 manifest: `doc/space/wcn-pilot-review-2026-09-10/`. The pendulum before-copy was reconstructed by reversing the three review changes and matches the SHA256 prefix reported by Fable after restoring its original LF line endings.

Changes are limited to the three pilot maps/texts; pendulum, seed replay and four noise scripts; their three probes; the grid config whitelist; the museum placement opt-in; related role/book/registry entries; the wave recovery checker; and this review/guide. Existing unrelated working-tree edits were preserved. Fable's earlier corpus-wide derived ordering rewrite was not reverted or extended.

