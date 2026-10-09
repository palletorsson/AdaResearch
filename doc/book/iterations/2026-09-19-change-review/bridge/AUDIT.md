# FTC bridge: preserve the cancellation encounter, delay the answer

Scope: targeted reveal and source-claim repair for the Change review, 2026-09-19. The received 2026-09-18 review and its frozen package are unchanged.

## Passage and purpose

`commons/maps/Change_Intro/final.md`, “Recover a difference,” asks: “Watch the pulse move along the arch. Predict the height difference left between its beginning and end.” The symmetric arch makes zero net change observable after a nonzero rise and fall. Preserve that mathematical and critical work; zero does not make this example empty.

## Evidence and limits

- TEXT: current manuscript already distinguishes its finite 512-interval trapezoid comparison from a proof, and states that recovering height from rate requires an initial value.
- SOURCE: the initial map token specifies `evidence:longhand`. The original `algorithms/change/ftc_bridge.gd` builds the longhand numerical comparison immediately. The snapshot in `before/algorithms/change/` preserves that implementation.
- SOURCE: the rate is estimated by small finite differences, with clamped endpoints. The 40 normalized display strips and the 512 quadrature intervals share the rate function but are separate constructions.
- SOURCE: no existing button supported delayed comparison. The project's canonical `InterfacePresets`/`ControlConsole`/`push_button` chain supplies a small local control without a new interaction framework.
- RUNTIME TEST / CAPTURE: final isolated artifact run passed 29/29 checks and exited 0. The actual museum run passed 11/11 checks and exited 0. Results are recorded in `runtime/verification.json` and `museum/verification.json`, with screenshots in the same folders. Headset reach, hand contact, in-headset readability, and learner understanding are not established by these probes.

## Missing layer and decision

The missing layer is reveal timing, with source descriptions that overstate the implemented evidence. The existing bridge already performs the needed cancellation comparison; replacing it or removing the passage would lose useful work.

Add opt-in `reveal_on_request:true` to a longhand placement. On entry the bridge keeps its pulse, arch, `a`/`b` endpoint labels, theorem title, and signed rate strips. The endpoint ticks/readings, difference bar, and numerical comparison are grouped and hidden. **COMPARE TOTALS** reveals them; pressing it again hides them. Reapplying identical configuration preserves the current reveal state; changing the curve or reveal/evidence mode rebuilds the encounter at its appropriate initial state. Bare/default and ordinary longhand placements retain their existing reveal behavior.

The narrow control stands beside the left pillar at local `(-2.7, 0, 0.45)` for the default 3m span, facing +Z. A central cabinet would hide the low signed strips. An initial closer position partially covered the rate label, so the final placement leaves an additional 0.45m gap. Equal endpoint readings share one `f(a) = f(b)` label, avoiding the original overlapping labels. The theorem title remains visible as the artifact's mathematical identity, following the review's sufficient intervention; only the numerical answer and endpoint comparison are delayed.

The comparison caption now identifies “rate sum ≈ …” rather than equating a finite sum to an exact integral. Source identity text names the net-change relationship and required initial value, preserves the symmetric arch as a cancellation experiment, and identifies its QFEP association as interpretation rather than a computed QFEP quantity.

## Substrate and boundaries

The pulse animation uses frame time only to mark successive positions; it does not make the rate plot a time derivative. The finite deck, strips, sampled slope, numerical integral, and rounded readout are different resolutions. Those inherited display choices remain part of this artifact. This repair changes when the aggregate account is shown, allowing the learner to first inspect the journey that account compresses.

The manuscript relation needs only the concrete action: after predicting from the arch and signed strips, press **COMPARE TOTALS** to reveal the endpoint comparison. Map staging, registry description, sequence relation, and final prose are owned by the main review task and its other agents.

## Reproduction

Run `python doc/book/iterations/2026-09-19-change-review/bridge/probes/run_bridge.py` from the repository root, then the same command with `museum` as its final argument. Both launch the specified Godot 4.6 executable hidden, with XR disabled, dummy audio, and explicit workspace logs. The old source is replayed from the before snapshot without replacing current production files. The museum probe uses the ordinary `endless_museum.tscn` Change_Intro placement and verifies the applied map flag, reveal/hide events, and a clear standing capsule in front of the button. Both probes exercise the canonical push-button signal; neither simulates physical hand contact or a desktop raycast.

## Final observed results

- The replayed before-source capture prints `+0.00` immediately. The final startup captures contain the arch, pulse, signed strips, endpoint `a`/`b`, and theorem title, with no numerical sum or endpoint comparison.
- Activating the canonical button reveals `rate sum ≈ +0.00` and `f(b) − f(a) = +0.00`; repeating it hides them. The museum close capture shows the button label and state readout clearly from its standing approach.
- All five curves agree between finite trapezoid sum and endpoint difference within the displayed two-decimal precision. Largest tested discrepancy is approximately `5.2e-8` for `step`; this agreement remains a finite numerical check, not proof.
- Bare/default placements retain their original geometry. Ordinary `longhand` placements still reveal immediately. Identical config preserves the revealed state; curve change restores prediction for opted-in instances.
- Final source SHA-256 is `b89c523cd2804ad94489e34141c2a64faa5879525ac9bf05908247a5cc4bfc58`. Both final runs record this same source hash before and after execution.
- `runtime-initial/` preserves the first probe attempt. Its 29 assertions passed, but immediate same-frame rebuilds left deferred control layout callbacks at shutdown and the process timed out. The probe now permits five frames after each simulated configuration change. The final isolated run exits in 7.2 seconds without those callback errors; no shared UI code was changed.
- Existing environment/museum diagnostics remain in logs: unknown resource UID, root certificate-store access, renderer capability warnings, empty extra registries, unrelated viewport/font messages, and ObjectDB shutdown leakage in the museum run. The final isolated run reports only the UID/certificate diagnostics. Neither final run reports a GDScript parse/runtime error.

Visual review used `runtime/after-predict.png`, `runtime/after-compared.png`, `museum/museum-predict.png`, `museum/museum-compared.png`, and `museum/museum-control.png`. Desktop captures establish these views and state changes, not headset discovery.
