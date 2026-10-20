# Can the student make it?

## Reading direction — 16 October 2026

Palle asks for a continuing tutorial lineage with less repeated code: refer to unchanged complete files in one line, while explaining and evaluating the new operation. The [Reaction–Diffusion reading proof](../../iterations/2026-10-16-tutorial-lineage-and-editions/index.html) tries a focused book reading beside complete encyclopedia files. This is a presentation proposal; it has not shortened canonical lessons or changed their executable blocks.

For this next trial, distinguish **complete runnable state** from **code reprinted on each page**. First constructions still show their full small program. A continuation can show complete new functions and precisely located edits, provided the exact preceding state and named support are recoverable and those edits reconstruct the supplied result. Unchanged files get filename, role, earlier lesson and edition reference. Changed support must be labelled changed. Keep necessary initialization explicit; do not replace a missing construction with an unexplained link.

Retain the exact-code, behavioural and learning checks below. Keep existing extraction markers and full source intact while trying the reading view; a future change to canonical storage needs a corresponding verifier change. Print references must identify the book's code version, with later revisions separately available. Earlier full-program conventions below describe existing lessons and evidence, not a requirement to reprint every inherited helper in every future book chapter.

**Reading economy:** show the complete working example once. A small experiment can name the exact edit without repeating an unchanged function or script. Test the edited result as well as the original; keep the complete variant available to download.

5 October 2026. An addition to [functional text](FUNCTIONAL_TEXT.md), developed one selected lesson at a time. Current native evidence covers the built point, Coordinates, Lines and Trace. It does not certify the whole curriculum.

[The tutorial must run](../../iterations/2026-10-05-the-tutorial-must-run/index.html) explains the method for readers outside the project. The rules below guide the next lesson; the historical pilot remains linked as evidence of its earlier, narrower scope.

The object of a tutorial is a capability: **what can the student construct, change and explain?** An artifact is the encounter and the source. Its whole implementation is not automatically the lesson.

The earlier checker examines declarations, dependencies, language and code. It cannot decide whether we chose the right thing to teach. This gate starts with that choice and asks whether the lesson actually gives it.

## The short brief

Use six fields. Keep them short enough to read across a sequence. Keep source paths and detailed evidence in the attached contract.

```text
MAKE: one observable capability.
BRING: abilities already taught.
GIVEN: named environment and library support.
BUILD: the new code or edits the learner must understand and apply.
CHECK: action → predicted result → explanation; one new variation.
LATER: adjacent topics deliberately deferred.
```

For the point:

```text
MAKE: same point; grab, carry, release; read local/world positions.
BRING: tested Point One construction; sphere + matching boundary.
GIVEN: prepared museum XR hand; pickup library; collision settings.
BUILD: continue with pickable body; configure pickup; create readout.
CHECK: same geometry; hold/release; coordinates in changed frame.
LATER: grip alignment; trigger actions; distance (Lines).
```

This reflects the current complete Coordinates lesson. Its readout is created by the printed program; the harness must not supply it. See [built and carried](../../iterations/2026-10-05-points-built-and-carried/index.html).

## Write from the brief

Begin with the encountered action. State what changes in the learner's existing work. Name the incoming code state and its earlier lesson. Print the complete smallest resulting program in `tutorial.md`, including each small helper needed to run it. Explain new operations where they become necessary. Downloads supplement the visible code; they do not replace it.

**The chain and the printed example must both be complete.** Point Coordinates continues Point One's point. It should not rebuild the sphere, material and collider as if they had never been taught. Keep the earned construction in the resulting script and identify it as inherited. Explain the new pickup operation rather than repeating the sphere lesson. Earned code belongs in BRING; the prepared XR player belongs in GIVEN. They are different kinds of dependence.

Then ask for a prediction, a deliberate change and an explanation. Keep a sentence if it helps the learner build, observe, explain or transfer the selected operation. Let the reflective text and the wider museum do their other work.

**Minimum means no missing causal step.** A first construction needs its complete small example; a continuation needs the previous state, a precise change and the complete resulting small program visible on the page. Compress the AI brief more than the learner's explanation. Keep names and dependencies intact; avoid cryptic abbreviations.

Supplied support has a boundary. The XR toolkit can supply tracking and the grab driver. Earlier code can supply the sphere when the new lesson changes its interaction. Declare both explicitly. A material setting can be inherited without claiming to teach shading. A reference must name what creates it and what it points to. Do not replace an unexplained `$` with an unexplained `get_node()`.

## The assumed student state

Test only code printed in the lesson plus explicitly declared inherited code and supplied infrastructure. Never import the full museum artifact to fill a missing initialization. Extract the printed program without repairing it; check the behaviour and deliberately remove a necessary line to ensure the same test fails.

Keep an executable file for what the learner is assumed to have at each step. This is the **ghost code**: a test fixture, not a claim about a real student's work.

```text
incoming code + printed edits → assembled code → behaviour checks → next incoming code
```

Pin the incoming file and its source evidence. Apply ordered edits with exact, unique anchors. Stop on a missing or ambiguous match. Run the mechanically assembled result, never a separately repaired solution. Preserve that result for the next lesson.

Each incoming state has a provenance: actual learner work, previous tested output, or explicit assumption. The current Point One fixture runs the complete printed construction from scratch within the declared environment. Coordinates, Lines and Trace continue the saved preceding output. These are imagined learner states, not submissions by human students.

Use a deliberate fault to challenge the test. In the current Trace lesson, removing the distance condition stores unwanted positions during a pause; connecting the wrong neighbours makes the drawing disagree with the ordered record. The same normal behaviour checks reject these versions. A compilation check alone would miss both. The earlier point pilot's omitted `body.reparent(solid)` was another such control; it belongs to that historical implementation.

## Test different claims separately

| Gate | Evidence | What it can establish |
|---|---|---|
| Focus | Author checks MAKE and LATER | The selected capability belongs here. |
| Completeness | Apply printed edits to declared incoming code; review with a fresh reader | Missing objects, settings, references or steps become visible. |
| Code | Execute the assembled result; test the selected behaviour and a deliberate omission | The continuation works under the tested conditions and the test detects a chosen fault. |
| Explanation | Learner predicts a change, then explains the result | Evidence of the specific causal understanding. |
| Transfer | Learner makes a new variant, with assistance recorded | Evidence that the capability extends beyond copying. |

Keep `pass`, `fail` and `not tested` separate for each gate. No aggregate “perfect tutorial” score. A script running is not a learning result. A model rebuilding it is a dependency audit, not a substitute for a student. A synthetic grab tests library behaviour, not physical controller input or comfort.

## Rules for accepting the next lesson

1. **Focus:** the author's selected capability, incoming skills and deferred topics are explicit. The artifact's contents do not automatically set the syllabus.
2. **Continuity:** identify the actual preceding output. Declare exactly what is retained, removed or added. Keep museum infrastructure distinct from learner-made objects.
3. **Visible completeness:** print the full small program once and each required small helper. Initialise every lesson-owned object. Avoid hidden scene dependencies and repeated `_ready()` definitions. The prepared room and library are named prerequisites, not printed in every lesson.
4. **Exact execution:** the printed source, mechanically assembled continuation and saved learner output agree. Run that source in Godot without harness repairs or substituted production artifacts.
5. **Behaviour:** assertions follow the selected capability and observable consequences. Include applicable empty/minimum cases, reference frames, lifetime and interaction transitions. A compile or image alone does not establish these.
6. **Sensitivity:** a relevant deliberate fault must fail the ordinary contract. Report the expected failures separately from errors in the unmodified program.
7. **Variation:** test the exact exercise edit and retain the complete variant. Ask the learner to predict and explain the result, then attempt a new use. Automated variants do not establish human understanding.
8. **Evidence:** record source/dependency hashes, engine, runner, verifier, results and limitations. A changed relevant input makes the old evidence stale; retain its historical bytes. Review focus and prose separately from native checks.

Short AI core:

```text
SELECT capability. PIN predecessor. DECLARE given support.
PRINT complete small output once; explain new operations.
RUN printed source without repair. ASSERT promised behaviour.
BREAK one relevant rule; require failure. TEST exercise variants.
RETAIN source-bound evidence; mark stale on input change.
REVIEW prose/focus; leave human learning untested until observed.
CARRY actual output. Keep final.md reflective. One hall at a time.
```

## Current handoff: Trace → Grid

Trace saves both its ordered local positions and the segment drawing already built from them when the point is released. Grid runs in the next museum hall and loads that sculpture. It creates no new point and asks for no repeated gesture. The original stays pink; only a separately owned green copy is placed at rounded grid addresses. The file, source values and original geometry stay intact. The prepared archive is printed support; the new lessons remain recording, traversal and interpreting a retained record.

The transport uses the same Godot project's `user://ada_student_trace.scn`, PointStudy-local metres and no timestamps. A later valid release replaces the file. An empty save leaves the previous record alone; an absent file makes Grid ask for Trace. The archive packs static meshes so loading does not rerun a constructor that could alter their dimensions.

[Current evidence](../../iterations/2026-10-06-trace-saved-to-grid/index.html): Trace 134 and Grid 53 native assertions, with 10 shared producer assertions (177 distinct); four faults detected. Separate engine processes also save and receive the same file inside the actual museum halls. Temporary placement and synthetic hand input are declared. Physical headset use and learner understanding remain untested.

Completed 6 October: Point_Triangle_Context now selects three positions from this original source. The previous same-running-station Grid proposal is superseded.

## Current continuation: Triangle → Melencolia

[Nine completed lessons](../../iterations/2026-10-06-primitives-tutorial-lineage/index.html) print their exact main scripts and every local code dependency, name supplied engine/add-on support, and explain the new operation. The route develops face indices, a reusable cube, generated positions, held resolution, profile/height/sides, glyph openings, finite stopping and composition. New study roots are declared; shared classes and retained data provide continuity without pretending that one runtime node travels everywhere.

The native checker extracts and byte-compares the printed source, executes it with the real Trace recorder and XR Tools, checks independent variations, and rejects ten deliberate faults. There are 122 passing assertions across the nine programs, including repeated producer/archive checks. Source-bound evidence appears in nine new Ghost Student states. Real-hall mounting and images are separate integration evidence. Neither proves physical-headset comfort or that a learner understands the explanation. final.md remains reflective and unchanged by this pass.

## What the small checker does

`reconstruction.py` checks the six-field brief, declared sources and explicit action/result checks. A construction can match a complete printed code block. A continuation instead declares an incoming file and ordered replacement/insertion operations: the lesson must print their exact fragments, and the executable must equal their mechanical composition. No silent repair is allowed.

For the continuation pilot, runtime evidence is bound to incoming code, printed lesson, contract, generated output, checker, verifier, runner and copied XR dependencies. Missing, empty, failed or stale evidence cannot produce a native pass. This is a reproducible local check, not tamper-proof certification. The checker cannot judge whether an explanation is sufficient or a learner understands it.

The native runner belongs to each lesson because useful behavioural assertions depend on its object. Do not make a generic screenshot or compilation pass stand in for those assertions. Current evidence is [Point One / Coordinates](../../iterations/2026-10-05-points-built-and-carried/index.html), [Lines](../../iterations/2026-10-05-lines-from-the-carried-point/index.html) and [Trace](../../iterations/2026-10-05-trace-the-carried-point/index.html). The earlier [continuation pilot](../../iterations/2026-10-05-lesson-state-chain/index.html) and [full reconstruction](../../iterations/2026-10-05-reconstruct-the-interaction/index.html) remain historical. Their narrower evidence must not be treated as proof that every current lesson or the full visible-code requirement passes.

Continue one interaction at a time: name the incoming state; agree the compressed brief; write the necessary change; assemble and test; read it with a learner; revise. Keep the map's wider subjects visible while testing one part.

## Primitives feedback refinement — 6 October

The author approved relevant feedback in both text tracks. Grid names representation change while retaining a sampled source; Triangle names indexed connectivity after Lines; Ignorance locates the decision in a generating rule and its input. Godot concentrates on resolution with supplied held-time mechanics. Profiles returns to Columns' section/route relation. Portals declares its sampler supplied so finite tolerance and budget remain the lesson. Melencolia adds an independent arrangement using already learned constructions; no new collision requirement or hidden worked answer.

Seven tutorial texts and four reflective texts changed. All printed executable blocks and museum maps are unchanged. Native evidence was refreshed (Trace 134, Grid 53 including 10 shared producer checks; later Primitives 122; 14 deliberate faults rejected). These are behavioural checks, not evidence that a learner understands the text. Current facing pages, lesson summaries, labels and Ghost Student states are synchronized. The independent closing task has no new tested solution. [Review](../../iterations/2026-10-06-primitives-feedback/index.html).

## Tested continuation format — 16 October

Use **file + named function or unique statement + exact edit + expected effect**. Line numbers are convenient links to a pinned incoming edition; they are not the durable instruction. Print complete new functions or the complete replacement fragment. Cite an unchanged file once with its role, origin and edition. Keep a complete runnable result online.

[Primitives → Pre → Introduction](../../iterations/2026-10-16-transformation-handoff/index.html) exercises this format: eleven printed edits produce a movement checkpoint, pickup and crossing comparison from the actual Melencolia script. BoxBody is introduced once and carried unchanged. The change from face-list cube to centred BoxMesh is explicit. The completed Pre pickup remains a separate branch for Arrays.

Native result: 68 assertions, eight variants and four detected behaviour faults. Sixteen missing/ambiguous anchors are rejected. Complete student-code markers remain in collapsed online references for existing extraction tools; the compact book renderer omits those repeated full listings. Test the assembled output, not a separately repaired answer. Human learning remains a separate observation.

Next: repair Introduction → Translation against this edition’s two files. Do not silently regenerate the whole sequence or change museum runtime to fit a tutorial.

## Continuation reached Rotation — 16 October

[Translation](../../iterations/2026-10-16-translation-carried-body/index.html) now continues the tested Introduction files; [Rotation](../../iterations/2026-10-16-rotation-carried-body/index.html) continues that exact Translation output. Rotation retains `box_body.gd`, `box()` and `_process()` unchanged. Four printed edits (19 code lines) introduce the pivot, local-preserving reparenting, axis-angle orientation and an attached face mark. The resulting files pass 253 native assertions, three exercise variants and an additional axis-length case; five behavioural faults and eight bad anchors are rejected. These results supersede the pending next step immediately above, not the historical receipts.

The next repair is Rotation → Scale. Start from Rotation's `complete/` files. Keep the book's continuation focused on new code, with complete first constructions and useful full-code checkpoints. Every lesson also has a dated, downloadable complete state so the reader can recover their place and work offline in the prepared museum. Line numbers supplement named function/statement anchors. Code evidence does not establish that a human learner understands the explanation.

## Continuation reached Scale — 16 October

[Scale](../../iterations/2026-10-16-scale-carried-frame/index.html) now continues Rotation's exact output. Five printed instructions include two explicit removals and three replacement fragments (22 code lines). BoxBody, box() and the pivot declaration remain unchanged; the doorway children use the inherited local-preserving reparenting. The clock is removed, and apply_pose explicitly changes its argument from a float time fraction to Vector3 scale factors. The new sphere is constructed visibly because the incoming script does not contain one.

Native evidence: 131 passing assertions; uniform, width-only and XY exercises plus a depth-only case; four behavioural faults and ten bad anchors rejected. Assertions measure transformed geometry and the fixed reference, while distinguishing nominal sphere dimensions from its tessellated bounds. The next repair is Scale → Trans_Body, starting from Scale's `complete/` files. This supersedes the pending next step above; it does not certify the still-unrevised Body lesson.

## Continuation reached Body — 17 October

[Trans_Body](../../iterations/2026-10-17-body-carried-opening/index.html) continues the exact Scale files with three insertions (16 nonblank new code lines). BoxBody, box(), apply_pose(), the doorway construction and fixed sphere remain. The active camera supplies world position each frame; its horizontal distance becomes a bounded fraction and then a uniform scale factor. The text explicitly distinguishes the viewpoint from the physical collision body and enlargement of a frame from shrinking blocks to open gaps.

Native evidence: 123 assertions, three exact exercise variants, five detected behavioural faults and six rejected missing/ambiguous anchors. The engine executes the preceding Scale scene and the reconstructed Body scene; tests cover live callbacks, actual Camera3D/XRCamera3D nodes with deterministic test positions, different parent frames, horizontal projection and camera lifetime. This is not a physical-headset or human-learning result. Complete dated files, edit locations and a ZIP accompany the printed changes.

Next: Body → Trans_Pit. Start from this edition's complete files; declare the additions needed for a timed, combined and solid opening. The previous Pit manuscript remains pending and is not certified by this receipt. Reflection and museum runtime were unchanged in this pass.
