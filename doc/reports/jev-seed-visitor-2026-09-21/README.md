# Seed replay: the first test visitor

2026-09-21. **Two live tests: correct conclusions for the observations; incomplete coverage in both.**

Review page: http://localhost:3003/research/possible-bodies/jev-test-visitor.html

## What the test does

The runner loads the real seed replay scene in a disposable artifact fixture. It reads the current Random_Definition placement, including the replica panels, wall display, table and compact console. A fixed eye aims the production DesktopInteractionPointer at the three actual buttons and injects mouse press/release events. Commands are bounded and allowed actions are REPLAY, RANDOM, +1 DRAW, and finish.

The decision component receives public label text, six sampled RGB cells per panel, signatures of the full 64-cell material arrays, and action history. The signatures are exact instrumentation, not visual recognition. Labels are visible-in-tree; the test does not prove they are unoccluded. The source code, book, private RNG state and expected answers are excluded by an explicit allowlist.

The current instrument says SAME SEED TWICE and grids equal/differ. This is an interaction-planning test with those labels available, not a test of unaided discovery. The seed slider is outside the model's first action repertoire.

## First live Jev run

The user approved sending the public exhibit observations and action history to TypeSafe, up to 11 requests. This run used **5 requests**, answered by **jev-1.13.0** through the jev-latest alias: **16,890 input tokens and 303 output tokens**. No further calls were made.

The action sequence was **REPLAY -> RANDOM -> REPLAY -> FINISH**. RANDOM changed the seed from 42 to 878 and changed both grids. Both replay trials reproduced every sampled colour. Jev correctly reported replay as reproduced and a same-seed/different-arrangement counterexample as not observed. It did not claim the seed alone guarantees an arrangement.

Jev never tried **+1 DRAW**. The evaluator requires two extra-draw changes, so the runner returns exit 1 with `coverage_complete: false` and `passed: false`. Godot itself exited 0; all five observations, action dispatches, independent colour checks, readouts and post-visitor fixture diagnostics passed. No unexpected engine errors or script errors were recorded, and sources remained unchanged.

There is a task/evaluator mismatch: the prompt asks Jev to investigate reproduction and permits finishing with enough evidence; it does not state the coverage quota. This run demonstrates incomplete exploration under our rubric, not an incorrect conclusion. Its reported confidence for FINISH was 0.29; this is the model's confidence output, not an independently measured accuracy rate.

An independent read-only audit verified the exact requests against public history prefixes, model replies, usage, engine receipts, source fingerprints and conclusions. No private RNG/oracle fields were sent. Exhibit labels already explain “SAME SEED TWICE” and whether the grids agree, so this cannot establish unaided discovery.

This first run is retained unchanged. The second experiment below tests an explicitly stated coverage task against the same evaluator.

## Second live run: explicit control coverage

Following the user's request for another test, `--task coverage` states at least two REPLAY trials, one RANDOM trial and two +1 DRAW trials, with before/after comparisons. Jev chooses the order. The prompt supplies no expected outcomes. The artifact, action options, private checks and final interpretation questions are unchanged. The default `--task exploration` still reproduces the first run's initial request exactly.

**REPLAY -> RANDOM -> +1 DRAW -> +1 DRAW -> +1 DRAW -> FINISH.** The first +1 DRAW changed the right grid while keeping the seed and left grid unchanged. This control toggles the extra draw on and off; repeated presses do not accumulate three discarded draws. Jev correctly identified a same-seed/different-arrangement counterexample and correctly described the one observed replay as reproduced.

However, Jev finished at choice six of ten after only **one of the two explicitly required REPLAY trials**. There was no observed control failure, forced stop or exhausted budget. The run therefore remains `passed: false`, with incomplete coverage. FINISH had reported confidence 0.65 and probability 0.73; no explanation was returned, so the cause of the missed trial is unknown.

An independent read-only audit passed 18 receipt checks, including reconstruction of every public request from the raw observations. It confirmed that the later private diagnostic REPLAY is correctly excluded from the visitor trial count.

This run used **7 of at most 11 requests**, all answered by **jev-1.13.0**, with **31,013 input tokens and 406 output tokens**. Godot exited 0. All seven observations matched the independent colour checks; dispatches, displayed controls, post-visitor replay repair and slider diagnostics passed. Sources stayed unchanged. The inherited audio UID diagnostic remains recorded; there were no unexpected engine errors or script errors.

| Check | First: exploration | Second: explicit coverage |
| --- | --- | --- |
| REPLAY trials; at least 2 | 2 | 1 |
| RANDOM trials; at least 1 | 1 | 1 |
| Extra-draw changes; at least 2 | 0 | 3 |
| Conclusions agree with observations | Yes | Yes |
| Complete coverage | No | No |
| API requests | 5 | 7 |

The second task prompted the previously missed intervention in this trial, but did not reliably enforce the full checklist. The practical next design is to track remaining trials in code and validate completion independently; Jev can choose among useful actions and interpret observations. A constrained controller would be a new experiment, not evidence that Jev tracked the checklist unaided. No third live test was made, and two runs are insufficient to estimate general reliability or prove that the prompt change caused the different behavior.

## Offline validation

- Final rendered baseline: passed, engine exit 0; eight commands, nine observations, four replay trials, one random trial, two extra-draw changes.
- Each observation's 128 material colours matched a separate Godot RNG reconstruction. This checks the artifact's draw assignment using the same engine RNG, not the statistical quality of that RNG.
- A separate post-finish diagnostic corrupts one material in the disposable fixture, then presses REPLAY through the real pointer. The normal artifact repairs it. With only its REPLAY callback disconnected, the test fails (engine exit 5), even though the ordinary before/after replay samples look unchanged.
- A second post-finish diagnostic drives the slider through its normal move_slider / slider_moved path: 42 -> 137 -> 42 -> the previous seed. It checks the artifact seed, handle position, displayed text, and all colours. This is a control-signal test, not a mouse-drag or tracked-hand test.
- 32 Python regression tests (including preservation of the exploration task and coverage payload boundaries) cover observation isolation, malformed model replies, trace completeness, RGB validity, action dispatch, and independent interpretation checks.
- Relevant source fingerprints remained unchanged during the final runs. Existing unrelated edits were preserved.

## A real bug found and repaired

The compact console reparents Panel under ReachConsole. The artifact's seed-change and slider-sync handlers still looked for Panel/Param_0 at the old root path. RANDOM repainted the panels while the slider stayed at 42, and moving the slider failed to change the artifact seed.

The regression run reproduced both failures. Both handlers now locate the live Param_0 descendant. The final rendered run and signal diagnostic pass. The prior working-tree source is retained as seed_replay_before.txt; slider-fix.diff contains only this task's production change.

## Evidence

- [Summary](summary.json)
- [Final rendered baseline](../../../ada_run/jev_seed_visitor/20260921-fixed-slider-04/report.json)
- [Before the slider fix](../../../ada_run/jev_seed_visitor/20260921-stale-slider-before-03/report.json)
- [Disconnected REPLAY negative control](../../../ada_run/jev_seed_visitor/20260921-negative-final-05/report.json)
- [Second live report](../../../ada_run/jev_seed_visitor/20260921-jev-coverage-02/report.json)
- [Second task request](../../../ada_run/jev_seed_visitor/20260921-jev-coverage-02/request_000.json)
- [First live report](../../../ada_run/jev_seed_visitor/20260921-jev-live-01/report.json)
- [Exact first live request](../../../ada_run/jev_seed_visitor/20260921-jev-live-01/request_000.json)
- [Live action history](../../../ada_run/jev_seed_visitor/20260921-jev-live-01/history.json)
- [Production change](slider-fix.diff)

Earlier runs 01/02 are retained. They checked replay/RNG behavior before the slider-readout regression was added; their pass is not a claim that the old slider worked.

The existing project emits one audio startup error, `Unrecognized UID: "uid://rwex60pqapc"`, from its default bus setting. Original engine logs retain it. The runner separately classifies only that exact inherited diagnostic; audio is outside this experiment. Other engine errors, GDScript errors, failed fixture checks or changed source invalidate a passing result. This is not a clean-project-log claim.

## Running it

From the repository root:

```powershell
python tools/seed_replay_visitor.py --mode scripted --render
python tools/seed_replay_visitor.py --mode scripted --disable-replay
python -m unittest tools.test_seed_replay_visitor -q
```

The negative-control command must return nonzero. Each run creates a fresh directory under ada_run/jev_seed_visitor. Existing nonempty output directories are refused.

For an authorized live run with TYPESAFE_API_KEY configured locally:

```powershell
python tools/seed_replay_visitor.py --mode jev --task exploration --render
python tools/seed_replay_visitor.py --mode jev --task coverage --render
# Or give the path of a local environment file containing TYPESAFE_API_KEY:
python tools/seed_replay_visitor.py --mode jev --env-file PATH_TO_LOCAL_ENV_FILE
```

No credential is printed or saved in the requests. No automatic fallback substitutes scripted actions for Jev. Default limits are ten action decisions plus one final interpretation request, 20 seconds per API call, no automatic retries, and a maximum request size of 80,000 characters. The bridge and watchdog bound engine execution. Live results preserve requested/returned model names, distributions, confidence, token usage and exact observations. Final model interpretations must agree with independently evaluated observations; a forced stop or incomplete action coverage does not pass.

An earlier attempt was blocked before launch pending explicit transfer approval. That approval was subsequently provided, the configured key authenticated successfully, and both authorized runs above completed (twelve calls total across two separate limits). Credentials are absent from the saved payloads and report.

## What remains open

Reliable completion control with explicit remaining-trial state; repeated trials before generalizing model reliability; actual museum navigation/occlusion; human discovery, headset reach and comfort. The fixed-eye pointer fixture and instrumented colour samples cannot establish those outcomes.
