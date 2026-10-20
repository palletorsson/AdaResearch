# A tutorial small enough to see the assignment

15 October 2026. Palle asked to isolate a small piece of code rather than make the complete abacus implementation the introduction. Palle confirmed that the four examples should be visible together, reading the same stored value.

The [new tutorial](../../../../commons/maps/Random_Definition/tutorial.md), *Give a number somewhere to go*, teaches position, scale, rotation and hue as four assignments of one value. The single printed file has **26 nonblank lines**; the preceding lesson printed 528. Prose is 770 words. The geometrical scene, rectangular controls and optional recording helper are supplied separately and linked explicitly. The small program is complete for the documented scene tree.

Open [preview.tscn](../../studies/randomness-shelf/preview.tscn) in Godot and press F6 for the desktop study. [shelf.tscn](../../studies/randomness-shelf/shelf.tscn) is the editable scene for a practice space with an inherited museum player. It starts from seed 435 and retains eight values. NEXT reads the next value; REPLAY returns to the first without new draws. KEEP writes a fresh file; LOAD restores its exact retained values, index and X extent. Set Notebook's `load_path` to reopen an earlier file. Observation and next-change fields remain editable in the JSON; packed record fields should be preserved.

![The third retained value, directed into four properties](shelf-preview.png)

The image is a Godot render after two NEXT presses, not a headset observation. A marked cube face makes rotation visible. Each instance owns its colour material. The point jumps when NEXT is pressed; smooth interpolation and a time-based clock are potential later changes, not hidden parts of this lesson.

## What the learner changes

The baseline maps the unit interval into X from −0.4 to +0.4 m. Reducing only `x_extent` to 0.2 contracts the movement while keeping all eight samples and the other three mappings. Equal sample numbers make the comparison explicit. A new prediction can concern perceived movement, a different destination or the frequency with which a clock advances the sample. No sensation or conceptual payoff is asserted without observation.

KEEP and LOAD use the [optional notebook](../../studies/randomness-shelf/shelf_notebook.gd), outside the 26-line lesson. Its readable record is accompanied by exact packed state because the preceding abacus experiment found slight decimal changes in JSON parsing. The mapping version fixes scale 0.5–1.5, a full Y turn and hue at constant saturation/brightness. A code-level change to those mappings requires keeping that revised source/scene as a new recipe; changing the exposed X extent is recorded directly.

The full former tutorial is preserved as [abacus-reconstruction.md](../../../../commons/maps/Random_Definition/abacus-reconstruction.md), byte-identical to the immediately preceding canonical chapter. The abacus builder and verifier now target the extension. Its old evidence and full experiment loop remain available. The optional colour-grid lesson remains. Entropy's two opening inheritance paragraphs now describe the shelf's float-to-property mappings; its code is untouched.

The **48-value seed bench remains the first research pilot**. This shelf's eight values reduce the introductory learning task. No runtime artifact, registry, room placement, final chapter, writing-wall order or pilot record was replaced. The shelf is not yet installed in the museum. Any installation needs shared hall-seed binding, registration and a reviewed floor placement; the standalone learner scene deliberately keeps its own seed-435 recipe.

## Rebuild and verify

```text
python doc/book/iterations/2026-10-15-randomness-tutorial-shelf/build-scenes.py
node doc/book/iterations/2026-10-15-randomness-tutorial-shelf/build-tutorial.mjs
python -X utf8 doc/book/iterations/2026-10-15-randomness-tutorial-shelf/verify.py
```

Set `GODOT_EXE` for another machine. The verifier extracts the chapter's exact student-code block into `printed/`, compares it with the learner source, and attaches it to fresh scene instances. **39 checks pass in Godot 4.6**: fixed-seed reconstruction, eight-value wrap, all four mappings at known values, independent materials, an X-only intervention, actual control signals, fresh non-overwriting recordings, exact reopening and metadata, replay, invalid-record rejection and preview connections. [Machine-readable receipt](verification.json) and `verification.log` retain the result.

The graphical render initially exposed nonuniform scaling of inherited button physics. Uniform scaling fixed it; the final render exits successfully without engine errors. Ordinary inherited solver-bias warnings remain. `render.gd` renders the actual preview scene at 1400 × 900 using the compatibility renderer.

The [previous chapter](before/tutorial.md), [previous plan](before/tutorial-plan.md) and [previous Entropy tutorial](before/entropy-tutorial.md) preserve the transition. The [current plan](../../course/text-plans/Random_Definition/tutorial.md) records the pending learner and headset trials. Passing automated checks establishes the build and record behavior, not an independent human reconstruction, meaningful felt difference, whole-room performance or successful VR use.
