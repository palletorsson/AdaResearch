# Claude: finish Effect Sound and return the encounter

Current assignment from Astra, 11 September 2026, after reading the W1 second-pass and W2 handoffs and revising six finals with Palle's discovery voice.

**Deliver a usable, evidenced Effect Sound room and its matching prose.** Complete the specifically missing Pendulum capture. Keep the useful W1 work. The next new hall is AirMusic; this assignment closes W2 so that we can carry a working sound comparison into it.

Repository: `C:/Users/palle/Documents/GitHub/AdaResearch_46`.

## Read these current sources

- `doc/book/handoffs/fable-waves-chance-noise-w2.md` and `ada_run/waves_chance_noise/2026-09-10-w2-batch.md`: implemented sound encounter and outstanding evidence.
- The **second runtime pass** in `doc/book/handoffs/fable-waves-chance-noise-w1.md` and `ada_run/waves_chance_noise/2026-09-10-w1-batch.md`. Earlier first-pass findings are history; do not redo their repairs without a current failure.
- `doc/book/handoffs/fable-final-discovery-voice.md` and the current `commons/maps/WaveFunctions_Effect_Sound/final.md`. [Read the voice trial](http://localhost:3003/research/waves-chance-noise/book-voice.html) and [writing brief](http://localhost:3003/research/waves-chance-noise/BOOK_VOICE.md).

The incoming second pass reports Intro's real bob and a release exercised through signals; this does not establish a desktop or tracked-hand pickup. It also reports a restaged Random primary, actual desktop controls and a placement-key regression. Astra's review of that second-pass evidence remains outstanding. This assignment does not mark those rooms accepted.

## 1. Complete the missing Pendulum view

When the project is free, run `bash tools/run_wcn_probe.sh pendulum live` using the current probe sources. Inspect the corrected rig captures, `captures.readout.is_ours` and `desktop_input.south_walkway_meshes`. Establish that the image is the intended view and that the readout and walkway can be judged from it. Fix an observed defect locally and rerun the affected check.

For Intro, Random, Noise and Sine Space, compare current probe and production-source fingerprints with the second-pass evidence. Refresh runs whose source changed or whose required evidence is missing. Record why each rerun is needed; keep still-valid evidence. Regenerate a live port after changing its source probe.

## 2. Run Effect Sound and improve what the attempt reveals

Run serially:

```bash
bash tools/run_wcn_probe.sh effect
bash tools/run_wcn_probe.sh effect live
```

Read both engine logs as well as the JSON; a green count with a compile error or skipped required interaction is incomplete. Exercise BASELINE, HOLD, PLAY and COMPARE through the actual available control path. Keep probe-driven ball movement distinct from a player's grab and release.

- Confirm HOLD retains the rendered A note while changes affect B; COMPARE must play the intended two notes and gap. Check the `differs` readout against the values actually changed.
- Verify one-variable comparisons, both mapper paths, modulator decay, sample duration/peaks and the scope's relation to the rendered samples. A plotted difference does not establish an audible one.
- Measure synthesis cost and repeated-drag responsiveness. Keep explicit audition if it is useful; choose `drag_note_cap` from the evidence and intended interaction, without enabling repeated sound merely because a fast run permits it.
- Inspect approach, balls, panel, readout and scope together. Check desk support, collision, reach and exit. Supply the five requested views: primary, readout, scope, overview and desktop front.
- Exercise leaving and rebuilding the room. Verify local audio players, signals and voices clean up and return correctly. Check the two shared initialization-order repairs on affected existing uses when their changes justify it.

Choose materials, spacing, feedback and local repairs that make the comparison clearer. Preserve the recovered platforms, perimeter walls, useful secondary instruments and museum route. Make the room work; return observed improvements rather than another source-only audit if runtime is available.

## 3. Carry the corrected encounter into the text

Preserve Astra's six revised finals as the current editorial baseline. Change the Sound final where a verified behavior requires it, and improve a passage when the encounter yields a better discovery. Keep the movement between listening, the consequential code and another possible use. Do not turn final.md into the test report or restore the old technical exposition.

Reconcile supporting texts with actual controls and the revised final. The baseline is **unmodulated**, with envelope and tanh shaping still present; do not call it an unprocessed pure origin. A small lift is not guaranteed to give index 4. Let a listener describe a change before prescribing its quality.

The Sound book hero and primary line already point to `DualBallFMController`; Random's hero is already `seed_replay_demo`. Retain those alignments. These are completed editorial changes, not outstanding requests for Palle. Preserve the existing primary anchors and verify quoted code after any implementation change.

A listener and a headset walk are separate evidence. If unavailable, leave them explicitly pending in field notes and handback. Save reproducible A/B audio when feasible for later listening; do not claim that sample statistics prove what a person hears or that a player count proves quietness.

## 4. Return one completion report

Write `ada_run/waves_chance_noise/2026-09-11-w2-completion.md`, linking updated room reports and captures. Include what became easier to encounter, one discovery from making it, changed files, exact runs and source fingerprints, failures/skips, and remaining listener/headset observations. Update W2's status and the local guide. Keep historical evidence dated and distinguish Claude's measurements from Astra's acceptance.

Suggest one reusable improvement and its conditions, such as held A/B audition or a cased difference readout. Return W2 for Astra to check before spreading new shared behavior into other rooms. No commit or forum message is requested.

## If Godot is occupied

Inspect the current process condition rather than inheriting a PID from a dated report. Leave existing sessions untouched. A failed inventory query must block a launch; low memory and process age alone do not establish that another process holds no lock. Resolve that gap in the runner before relying on it. Use the existing serial watchdog workflow and keep automated helper windows hidden.

Continue independent source corrections and text reconciliation within W2. You can also inspect AirMusic's existing striker, bars and synthesis and record its current encounter and likely improvement beside its field notes. Keep that preparation provisional; do not build a new batch while the present evidence is unresolved.

## What comes next: AirMusic

Read `doc/research/waves-chance-noise/maps/WaveFunctions_AirMusic.md`. Carry this thread: **one oscillation changes another sound; a strike then sets a response continuing after the hand leaves; two decays can overlap.** The primary is `resonating_metallophone`. Make one strike, two isolated notes, and the same pair overlapping readable before adding tuning comparisons. This leads into the additive sum in Synthesis Lab. AirMusic is the next development handoff after this return, not another name for W2's remaining verification.
