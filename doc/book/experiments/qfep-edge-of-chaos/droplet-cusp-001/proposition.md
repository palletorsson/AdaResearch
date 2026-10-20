# One control that moves four coefficients

**Proposed. Nothing has run under this record; the artifact stands in QFEP_Edge_Of_Chaos as an uncommitted working-tree placement of 2026-10-13.** No observation, run or behavioural claim appears below; every forward statement is a prediction and says so. The hall texts predate the artifact and do not mention it. Bindings live in [the record](./experiment.json); the method is [the book architecture](../../../RECURSIVE_ARCHITECTURE.md); the executed model is the pilot [seed-bench-001](../../random-definition/seed-bench-001/proposition.md), which this record resembles in shape but not in state.

Two passages initiate, each with its own question. The [tutorial](../../../../../commons/maps/QFEP_Edge_Of_Chaos/tutorial.md) (`qfep-edge-of-chaos.bundled-control.v1`) says of LAMBDA: "Moving it changes four coefficients together. To isolate just feed would require a different control and comparison." Its question is constructive: build a bounded comparison around a control of exactly that shape — the `flesh` enum of [droplet_cusp.gd](../../../../../commons/artifacts/droplet_cusp/droplet_cusp.gd), whose `_flesh_recipe()` returns [constraint iterations, pressure, damping, grip] as one bundle — stating in advance what a verdict difference establishes (a response to the bundle) and what it cannot isolate (any single coefficient), with the verdict pair predicted on paper before anything runs.

The [final](../../../../../commons/maps/QFEP_Edge_Of_Chaos/final.md) (`qfep-edge-of-chaos.model-vs-calculation.v1`) asks: "Which changes belong to the model, and which belong to the way its calculation is run?" Its question is an encounter: meeting a drop that hangs in the waist, can a visitor sort what they see into model (the carved waist, the flesh bundle) and calculation (tick-denominated stillness, timeout, substeps) — and could the same experiment be renamed by running its calculation differently, without touching waist or flesh?

The proposition is conditional: **If one enum step on `flesh` changes the settled verdict word while everything else is held fixed, that difference is a response to the four-coefficient bundle and to nothing finer** — the tutorial's scruple about LAMBDA, applied to this artifact's own control. The selected mapping below is one reading of the two questions; two rivals are named rather than silently absorbed.

## Competing interpretations

**`droplet-cusp.interp.bundle-response`** (tutorial + final; selected). Hold `waist="tight"`; compare `flesh="firm"` against `flesh="jelly"`, ball_radius at its 0.075 export default, show_readout on. After `is_settled()` returns true, read `verdict_word()` as the outcome and `ball_top_m()` / `ball_bottom_m()` / `waist_radius_m()` as the pose record. A difference in verdict words establishes a response to the flesh bundle — `_flesh_recipe()` moves [constraint iterations 12->2, pressure 10.0->2.0, damping 0.94->0.985, grip 0.68->0.22] together — and establishes nothing finer. Assumes both conditions settle before TIMEOUT_TICKS=1200; that the artifact's own verlet shell is deterministic at a fixed tick rate (no seed exists to vary), so one run per condition is meaningful; that `verdict_word()` is a total function of the settled pose. Prediction, labelled as prediction: the grip difference (0.68 vs 0.22) in `_collide_point`'s `_prev` lerp is expected to let jelly slide where firm hangs — read off the code and its @identity header, not off any run. Excludes: which of the four coefficients carries any difference; the registry description's measured figures (hang depths, pass/fail table, 60-vs-90 Hz results — those belong to the build campaign); `waist="snug"` and `"scant"`, where the code comment predicts geometry outruns the material in both directions; any claim about 90 Hz.

**`droplet-cusp.interp.grip-isolated`** (tutorial; named and excluded). Reads the question as demanding isolation: attribute a verdict change to grip alone by comparing 0.68 against 0.22 with constraint iterations, pressure and damping pinned at firm's 12, 10.0, 0.94. The numbers are real — they live in `_flesh_recipe()` — but no export reaches them individually: `flesh` is an enum over FLESHES = ["firm", "pliant", "jelly", "balloon"], and `apply_grid_config()` accepts only whole names from WAISTS/FLESHES. Assumes grip is the load-bearing coefficient (the code's own comment claims low grip "lets it ooze" — here an unverified claim, not evidence) and that a single-coefficient bench variant would otherwise behave like the shipped artifact. Not executable through the real exports; excluded from the bounded comparison and carried as learning debt `droplet-cusp.debt.grip-isolation`.

**`droplet-cusp.interp.calculation-owned`** (final; named and deferred). Reads the question as: perhaps the verdict belongs to the calculation. The settle rule is tick-denominated — SETTLE_EPS=0.0001 m of bound movement, SETTLE_TICKS=45 consecutive quiet `_physics_process` calls, TIMEOUT_TICKS=1200 — so identical constants demand 0.75 s of stillness at 60 Hz but only 0.50 s at 90 Hz, and `_step_shell()` integrates delta/SUBSTEPS (SUBSTEPS=4), so trajectories are tick-rate-dependent in principle. Operationalized: run the SAME exports (waist="tight", flesh="firm") at 60 Hz and at 90 Hz and compare `verdict_word()`; a flip assigns the outcome to the way the calculation is run, not to the model. Assumes the harness can set the physics tick rate (the artifact exposes no export for it) and that `is_settled()` and `verdict_word()` suffice as readouts, `used_physics_bounds()` confirming the bounds come from the shell's own particles with no renderer or physics server in the loop to lie. Code comments say probe_droplet_fit gates both rates; that is a build-campaign claim this record does not inherit as evidence. Not this record's single changed condition; carried as learning debt `droplet-cusp.debt.tick-rate`.

## Bounded comparison

- **Baseline.** waist="tight", flesh="firm", ball_radius=0.075 (export default), show_readout=true, physics at 60 Hz; `verdict_word()` consulted only after `is_settled()` == true.
- **Single change.** flesh: "firm" -> "jelly" — one enum step on the flesh export (set via the inspector setter or `apply_grid_config({"flesh": "jelly"})`, which triggers `_rebuild()`); internally `_flesh_recipe()` moves [constraint iterations 12->2, pressure 10.0->2.0, damping 0.94->0.985, grip 0.68->0.22] together, and the comparison is honest only about the bundle.
- **Held fixed:**
  - waist="tight" (throat radius `_waist_r` = ball_radius * `_waist_factor()` = 0.075 * 0.86 = 0.0645 m); ball_radius = 0.075.
  - show_readout = true; block_color / ball_color / hang_color at export defaults.
  - carve geometry constants: flare sphere radius 0.105, bore cylinder radius 0.080, washer at WAIST_Y = -0.045 with WASHER_HALF = 0.008, TRAY_FLOOR = -0.23, TRAY_Y = -0.225.
  - settle discipline: SETTLE_EPS = 0.0001, SETTLE_TICKS = 45, TIMEOUT_TICKS = 1200, SUBSTEPS = 4.
  - physics tick rate 60 Hz — an engine setting, held by the harness, not exported by the artifact.
  - reading protocol: `is_settled()` gates the read; `verdict_word()` is the outcome; `ball_top_m()`, `ball_bottom_m()`, `waist_radius_m()` are the pose record.

## Invented arithmetic fixture

This fixture is an invented calculation, not output. Every number is hand-derived from constants in [droplet_cusp.gd](../../../../../commons/artifacts/droplet_cusp/droplet_cusp.gd) alone; the poses are round-number inputs to the `verdict_word()` decision tree, chosen for geometric plausibility, and appear in no registry description, measured block or probe report. The registry's measured figures (such as its hang depth) are deliberately avoided.

- Throat radii at ball_radius 0.075: snug 0.075 * 1.12 = 0.0840 m; tight 0.075 * 0.86 = 0.0645 m; narrow 0.075 * 0.74 = 0.0555 m; scant 0.075 * 0.56 = 0.0420 m. Tight radial interference: 0.075 - 0.0645 = 0.0105 m.
- Verdict thresholds: PASSED needs `_last_top` < WAIST_Y - 0.01 = -0.055 with `_last_rho` < 0.09; PROUD needs `_last_bottom` > WAIST_Y - 0.006 = -0.051; ESCAPED if `_last_bottom` < -0.6, or below the washer with `_last_rho` >= 0.09.
- Pose (top -0.080, bottom -0.230, rho 0.000) -> PASSED: bottom -0.230 = TRAY_FLOOR; top - bottom = 0.150 = one rest diameter (2 * ball_radius).
- Pose (top +0.113, bottom -0.037, rho 0.000) -> PROUD: bottom sits on the washer top, WAIST_Y + WASHER_HALF = -0.045 + 0.008 = -0.037; top = -0.037 + 0.150 = +0.113.
- Pose (top +0.030, bottom -0.130, rho 0.000) -> HANGS: not past -0.055, not above -0.051; an elongated drop of length 0.160 > rest diameter 0.150.
- Pose (top -0.550, bottom -0.700, rho 0.000) -> ESCAPED: bottom -0.700 < -0.6, through the tray and gone.
- Pose (top -0.080, bottom -0.230, rho 0.120) -> ESCAPED: below the washer yet 0.120 >= 0.09 off-axis — it fell beside the funnel.
- Settle clock: SETTLE_TICKS / rate = 45/60 = 0.75 s and 45/90 = 0.50 s of required stillness; TIMEOUT_TICKS / rate = 1200/60 = 20.0 s and 1200/90 = 13.33 s. The 60 and 90 Hz rates are assumed harness tick rates, not .gd constants; the same constants name different durations under different tick rates — the final passage's question in arithmetic form.

## What could change the work

- Either condition reaches TIMEOUT_TICKS (the verdict carries "(still moving at timeout)"): a timed-out pose is not a settled verdict; redesign the comparison — longer budget, or ooze named as its own outcome — before any reading counts.
- `verdict_word()` returns UNSTABLE or ESCAPED in either condition: the apparatus is answering instead of the question; repair solver or collision before interpreting anything.
- firm and jelly produce the SAME verdict word at waist="tight" AND at waist="narrow": flesh does not argue at either middle waist for this ball_radius, the @identity claim that softness is purchasing power needs reexamination, and the passage binding may belong to the waist axis instead.
- Repeat runs at a fixed tick rate give different settled poses: the determinism-without-a-seed premise in the code is wrong, and every single-run verdict needs replication statistics before the bounded comparison means anything.
- The hall texts are revised before the pilot runs (both are dirty in the working tree): if either bound excerpt no longer exists as exact bytes, rebind the passages before executing.

## Planned cycle (future work — none of it has happened)

1. Instance the baseline on a bench at 60 Hz; record settle tick count, verdict word and pose record; the changed condition's verdict pair stands predicted on paper first (prediction: firm HANGS, jelly PASSED).
2. Switch only flesh to "jelly" through `apply_grid_config()`; no other export, constant or engine setting moves.
3. Compare the two settled verdict words and pose records; a difference is a bundle response and nothing finer.
4. Keep receipts: per-run tick counts, verdict words, pose readouts, and the exact source bytes of both hall passages at run time.
5. Replay each condition at the same tick rate; divergence breaks the determinism premise and voids single-run verdicts.
6. Independent reconstruction: a reader rebuilds the comparison from this proposition alone; record what assistance was needed.
7. Review tutorial and final separately — revise, retain with reasons, or hold an open question — and let the observed result select the next experiment; the three learning debts (tick-rate, grip-isolation, placement-untested) are candidates, not defaults.

## Open

- Execution: no bench or museum-lane run exists under this record's identity.
- Observation: [the log](observations.md) is empty.
- Both text reviews: tutorial and final each [pending](revision.md), decisions deliberately absent.
- Human encounter: no visitor has met the drop through this record.
- Independent reconstruction: nobody has rebuilt the comparison from this prose.
