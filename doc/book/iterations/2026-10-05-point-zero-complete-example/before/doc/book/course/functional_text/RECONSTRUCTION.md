# Can the student make it?

5 October 2026. An addition to [functional text](FUNCTIONAL_TEXT.md), tested on one interaction before revising more lessons.

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
MAKE: existing point; grab, carry, release in place.
BRING: Point One state; sphere surface + matching static boundary.
GIVEN: museum XR hand; pickup library; collision settings.
BUILD: swap body class; configure pickup; parent existing surface.
CHECK: same shape/place; surface and boundary follow; release stays.
LATER: grip pose; trigger action; labels; coordinate readouts.
```

This selects the first interaction in Coordinates. It does not remove local/world positions from the map's agreed teaching. They need their own complete connection to the point when that part is rewritten.

## Write from the brief

Begin with the encountered action. State what changes in the learner's existing work. Name the incoming code state and its earlier lesson. Print only the edits needed for the new capability. Explain new operations where they become necessary. Keep the full incoming and outgoing files available as references, outside the reading flow.

**The chain must be complete; every lesson need not reprint it.** Point Coordinates continues Point One's point. It should not rebuild the sphere, material and collider as if they had never been taught. Earned code belongs in BRING; the prepared XR player belongs in GIVEN. They are different kinds of dependence.

Then ask for a prediction, a deliberate change and an explanation. Keep a sentence if it helps the learner build, observe, explain or transfer the selected operation. Let the reflective text and the wider museum do their other work.

**Minimum means no missing causal step.** A first construction needs its complete small example; a continuation needs its complete small change. Compress the AI brief more than the learner's explanation. Keep names and dependencies intact; avoid cryptic abbreviations.

Supplied support has a boundary. The XR toolkit can supply tracking and the grab driver. Earlier code can supply the sphere when the new lesson changes its interaction. Declare both explicitly. A material setting can be inherited without claiming to teach shading. A reference must name what creates it and what it points to. Do not replace an unexplained `$` with an unexplained `get_node()`.

## The assumed student state

Keep an executable file for what the learner is assumed to have at each step. This is the **ghost code**: a test fixture, not a claim about a real student's work.

```text
incoming code + printed edits → assembled code → behaviour checks → next incoming code
```

Pin the incoming file and its source evidence. Apply ordered edits with exact, unique anchors. Stop on a missing or ambiguous match. Run the mechanically assembled result, never a separately repaired solution. Preserve that result for the next lesson.

Each incoming state has a provenance: actual learner work, previous tested output, or explicit assumption. The first Point One fixture is an assumption assembled from the current lesson and source. Point One currently edits an existing museum script, so this pilot does not yet prove that its standalone incoming file can be produced from that lesson alone.

Use a deliberate omission to challenge the test. Here, leaving out `body.reparent(solid)` lets the collider move while the sphere's visible surface remains behind. The same behaviour checks must reject that version. A compilation check alone would miss it.

## Test different claims separately

| Gate | Evidence | What it can establish |
|---|---|---|
| Focus | Author checks MAKE and LATER | The selected capability belongs here. |
| Completeness | Apply printed edits to declared incoming code; review with a fresh reader | Missing objects, settings, references or steps become visible. |
| Code | Execute the assembled result; test the selected behaviour and a deliberate omission | The continuation works under the tested conditions and the test detects a chosen fault. |
| Explanation | Learner predicts a change, then explains the result | Evidence of the specific causal understanding. |
| Transfer | Learner makes a new variant, with assistance recorded | Evidence that the capability extends beyond copying. |

Keep `pass`, `fail` and `not tested` separate for each gate. No aggregate “perfect tutorial” score. A script running is not a learning result. A model rebuilding it is a dependency audit, not a substitute for a student. A synthetic grab tests library behaviour, not physical controller input or comfort.

## What the small checker does

`reconstruction.py` checks the six-field brief, declared sources and explicit action/result checks. A construction can match a complete printed code block. A continuation instead declares an incoming file and ordered replacement/insertion operations: the lesson must print their exact fragments, and the executable must equal their mechanical composition. No silent repair is allowed.

For the continuation pilot, runtime evidence is bound to incoming code, printed lesson, contract, generated output, checker, verifier, runner and copied XR dependencies. Missing, empty, failed or stale evidence cannot produce a native pass. This is a reproducible local check, not tamper-proof certification. The checker cannot judge whether an explanation is sufficient or a learner understands it.

The native runner belongs to each pilot because useful behavioural assertions depend on its object. Do not make a generic screenshot or compilation pass stand in for those assertions. The current pilot is [Continue with the point](../../iterations/2026-10-05-lesson-state-chain/index.html). The earlier [full reconstruction](../../iterations/2026-10-05-reconstruct-the-interaction/index.html) remains a comparison; its demand for a complete printed script is not the rule for continuation lessons.

Continue one interaction at a time: name the incoming state; agree the compressed brief; write the necessary change; assemble and test; read it with a learner; revise. Keep the map's wider subjects visible while testing one part.
