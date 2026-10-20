# Carry the work; show the change

16 October 2026. A reading proposal for Palle's request: keep the tutorial lineage, explain and evaluate the new code, and refer to unchanged full files in one line. [Open the comparison](index.html).

The existing Endless Museum remains the environment. This proof uses the current Reaction–Diffusion tutorial and its real source files. It changes no lesson program, hall, teaching selection or final.md. It is a proposed reading format, not a new print edition or a claim that the whole tutorial route passes.

## One lesson, two reading depths

The physical book should contain the encounter, a precise incoming state, the new operation and enough code to understand and apply it. Print a complete new function when that is the unit being changed. Identify its file and whether it replaces an existing function. Name an added variable and its location. Avoid scattered lines with ellipses and unexplained dependencies.

An unchanged file gets one line: filename, role, earlier lesson and edition reference. A changed file must be labelled changed even when most of its contents are familiar. A supplied helper needs a short contract: what it receives, does and returns, and where its complete version lives. First constructions still need their full small code; this approach must not hide a missing label, constructor or connection again.

The encyclopedia should open at the same focused reading and offer complete before/after files, dependencies, the working study, exercises and evidence underneath. The full files are part of the lesson, not a separate answer written independently. Use existing tutorial cards for the selected focus, the execution plan for dependencies and the Ghost Student mechanism for recoverable code states. Do not create another competing syllabus or verifier.

For now, keep the complete canonical tutorial and its extraction markers intact. This proof derives the focused view from that material. A later publishing pass can mark selected ranges and inherited references so the same maintained lesson produces the short book reading and expanded encyclopedia reading. If canonical storage changes, update the extraction check in that same pass; never make it silently accept incomplete source.

## What travels?

| Connection | Concrete example | What must be recorded |
| --- | --- | --- |
| Code reuse | Lines' PointBody returns in Trace | Exact file version and what this class supplies |
| Data continuity | A student's Trace drawing reaches Grid | Record, frame, units, save/load ownership, original preserved |
| Conceptual return | A field returns in CA and Reaction–Diffusion | The shared distinction and any changed discretization or parameters |
| Composition | Melencolia arranges earlier constructions | Available parts, new arrangement and what is deliberately supplied |

These connections need not follow the immediately preceding room. The walking route orders encounters; the tutorial also names its actual prerequisites. A class reused later is not proof that the same live node travelled there. Several object families can develop through the route; one universal class would conceal their different responsibilities.

## Reaction–Diffusion proof

The prior lesson is CA_SoftRules, **What a neighbour offers**. It already has the two U/V arrays, neighbour exchange, a supplied reaction and a two-table comparison. Here the reaction becomes the focus.

- **Retain:** grid indexing, initial patch, four-neighbour stencil, synchronous update and the current carried PointBody.
- **Edit:** add `local_terms` and replace `next_pair` in `field.gd`. The proof mechanically applies these two changes to the prior field and compares the result with the complete current file.
- **Use the updated host:** `reaction.gd`. It changes the comparison switch, the witness address and related readout from the earlier `exchange.gd`. It is not labelled unchanged. The full file is provided; its new switch restarts both fields and isolates local terms.
- **Predict:** at (15,15), initially U=0.5 and V=0.25, neighbour exchange is zero. With local terms enabled, the first step gives U=0.48725, V=0.257. With them disabled, that address stays unchanged on the first step; the boundary still exchanges.
- **Vary:** raise FEED from 0.037 to 0.050. Predict U=0.49375, V=0.25375 before running. Explain why more feed also removes more V.
- **Carry onward:** the PointBody and matched-comparison method. The next spatial-field lesson does not inherit these concentration arrays.

The eighteen saved gallery sculptures remain encounters. Their presence does not make eighteen renderer implementations part of this lesson. Nor do their images validate the compact learner's different numerical setup.

## Acceptance, at three levels

1. **Source:** the page identifies its starting state; its exact edits produce the downloadable result; named support is present. A reader does not have to guess where code belongs.
2. **Execution:** Godot runs that exact state and asserts the promised behaviour, relevant boundaries and the stated variation. A deliberately broken rule should fail the ordinary checks. Existing archived checks must retain their date and scope; changed inputs require rechecking.
3. **Learning:** a reader predicts, explains and makes another variation. Record assistance and confusion. Code tests and ghost rehearsals cannot establish this result on their own.

This proof performs source checks only. It links the existing 9 October native lesson evidence and records whether its printed files still match this snapshot. It does not rerun Godot or call the earlier museum-gallery tests tutorial tests.

## Print and encyclopedia versions

For a printed book, the one-line reference must identify the book's exact code bundle, not silently point at the newest development branch. Retain a readable lesson ID and short public address beside any QR code; include the same files in an offline edition bundle. The encyclopedia should offer **This book edition** and **Latest revision** with differences stated. A local report URL is not yet a public print destination.

This proof is labelled `RD-20261016-P1`. It includes copies of the current three scripts, the existing minimal study scene, the full tutorial and source hashes. The small ZIP belongs inside the existing prepared museum project; it does not contain Godot, the museum or XR Tools. It demonstrates a recoverable lesson snapshot, not a frozen whole-book edition.

## Compact instruction for the next writer

```text
SELECT one capability from the agreed hall focus.
NAME incoming object/data and exact files; distinguish carry from supplied.
PRINT new causal code in complete units; specify edit location.
REFERENCE unchanged files once; label changed support honestly.
EXPLAIN operation, limitation and one predicted consequence.
ASSEMBLE from the named predecessor; run and assert the resulting state.
TEST a variation and a relevant fault; retain evidence and its limits.
CARRY the usable result; name the next use without inventing continuity.
KEEP final.md's reflective task and the wider museum's freedom.
```

Next useful editorial trial: read this short version against the existing long lesson. If its new operation is clear and reconstructable, apply the format to one selected hall before extending it. The criterion is less repeated reading without a missing dependency, not an arbitrary line or word quota.

Sources: [reconstruction agreement](../../course/functional_text/RECONSTRUCTION.md), [execution plan](../../course/execution-plan/README.md), [book architecture](../../RECURSIVE_ARCHITECTURE.md), [two writing roles](../../course/WRITING_ROLES_AND_DECISIONS.md). `build.py` regenerates this proof and `verification.json` from explicitly named current files; it does not rewrite those sources.
