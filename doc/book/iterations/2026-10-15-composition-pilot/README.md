# A small composition instrument

15 October 2026 · Random Definition · [Open the pilot](index.html) · [Writing wall](http://localhost:3003/long-museum/writing-wall?map=Random_Definition&view=literary)

An artifact's literary operation is a hypothesis about attention. Its material facts are supported separately. The map composes relationships among these hypotheses; the book can retain what they make possible without requiring every hall to repeat the same shape.

**Later reading, 15 October:** the [supplied criticism and follow-up](../2026-10-15-composition-consequences/README.md) prefer the reference for economy and enacted repetition. Patient and inquiry are set aside as replacements. The [review record](review.json) binds that preference to edition `3d57b4bf8da95a931c90`; it does not adopt the chapter. The next comparison tests repetition, montage and recurrence with separate artifact and map tests. The descriptions below document this first pilot; its immutable editions remain available.

This pilot implements the supplied proposal at the scale of the current five encounters. It adds hall-scoped artifact contracts, a map composition, a directed relationship graph, a proposed development of the shared voice, two Geiger alternatives, complete chapter assemblies and a reproducible edition record. It preserves the current complete trial as the reference reading. No candidate has been adopted.

## The records

The editable source contracts live in [the hall's composition folder](../../../../commons/maps/Random_Definition/composition/map.json). Each artifact has a material fact, implementation status, evidence with file and locator, proposed primary operation, counter-operation, refusals, registers and motifs. Geiger has two competing hypotheses. Evidence distinguishes implementation from visible interaction; neither is an independently observed participant response.

The map owns the five-stop order, form, trajectory, recurring elements, ending and advisory variation rules. Its narrator proposal preserves “we”; it permits an account to become narrower or to revise an earlier encounter. The relationships file owns directed meanings independently of the route. Each edge says whether it is a thematic relation or a supported data transfer. RANDOM TOUCH → MOVE / KEEP is an inversion, not a data pipe.

The Literary tab uses the live wall draft's Final tags and sequence, including unsaved order changes. It shows the proposed operations, counterpoints and refusals; the relation graph distinguishes connection from walking order. Moving an encounter changes adjacency notices and the order preview. Prepared prose remains attached to its frozen route. Other maps can use the same format; they start without invented assignments.

## One comparison

The reference is the 926-word witness trial. Two alternatives change only the Geiger opening: **patient** stays with repeated sounds; **inquiry** uses recurrence to ask what the sound and display can establish. The seed definition, receipt and later transition remain verbatim. Every version is presented as a complete chapter and in a focused middle comparison. Generated counts use the same narrative-only method as the earlier trial.

The [instructions](instructions.md) and exact candidate files are retained. These are original passages using selectable operations, not imitations of authors. The [author toolbox](../2026-10-15-situated-voice/strategies.html) supplies source provenance and the limitations of each association. The supplied proposal's historical/theoretical qualifications remain relevant; no simulated Geiger establishes quantum ontology, and sensor loss is not equivalent to the violence constituting archives of slavery.

## Review and edition discipline

The audit reports structural observations, never literary quality: runs of a declared operation, repeated paragraph beginnings, question endings and repeated sentences. A repeated word is not proof of a repeated operation; absence of a warning is not success. A human check separately asks whether interpretation follows every action, whether each passage begins with another spatial inventory, and whether recurrence has a purpose. The initial exact recurrence is intentional; compare its effect rather than suppressing it.

Read without first explaining the intended distinction. Record what stays with the reader, what the clicks and displayed seed mean to them, and what they want next. Ask about the need for the definition separately from preference for the rhythm. A response can reject both candidates or prefer the reference. Preserve the exact words and reading context; distinguish Palle's editorial judgement, independent reader response and headset experience.

`review.json` is the writable decision record. Its initial status is pending. A future adoption must name the edition ID and variant, retain the reader's words and describe any revision. Adoption is an explicit editorial act; building or opening a candidate never adopts it. An adopted edition remains immutable; new work receives a new input digest and folder.

## Build and replay

Run `python doc/book/iterations/2026-10-15-composition-pilot/build.py`. The builder validates artifact references, source locators, relationship endpoints, common room/final order and candidate boundaries. It snapshots the metadata, source code, source texts, exact instructions, candidate wording and builder. A SHA-256 digest identifies the complete input set. Markdown and HTML outputs, counts and advisory audit have their own hashes. An existing edition is verified, never overwritten. Only the landing page and the wall's current pilot pointer change on a later build.

Run `python doc/book/iterations/2026-10-15-composition-pilot/build.py --replay EDITION_DIRECTORY` to assemble from the retained inputs and verify the output hashes. This reproduces the assembly of authored passages; it does not promise deterministic LLM generation. Python and Markdown versions are recorded. The build manifest does not claim a clean Git tree or use a commit ID as a substitute for source hashes.

The 48-value bench remains the first runtime research pilot. No scene, runtime control, canonical chapter, tutorial, physical placement, wall tag or saved walking order is changed by this composition experiment. The optional clock-resolution and gesture-collision experiments remain unperformed here.

## Verification and a placement finding

Edition `3d57b4bf8da95a931c90` retains 35 inputs and produces reference/patient/inquiry chapters of 926/950/967 words. It supersedes the first assembly only to rebase source-note links in the saved Markdown; the narrative is identical. Both editions remain preserved. Replaying the retained inputs matched every output hash. Five boundary tests pass: only the Geiger opening changes, unknown relationship endpoints are rejected, changed room/Final order cannot silently rewrite prose, missing code locators are rejected, and corruption of a retained output is detected. Run `python doc/book/iterations/2026-10-15-composition-pilot/test_pilot.py`.

The Literary view, its read-only API and all six edition pages were checked live. Selecting Geiger exposes its evidence and literary hypothesis separately. Moving it after MOVE / KEEP changed the route notice and forward/backward relationship descriptions; Undo restored the original route without saving. The canonical chapter still matches its preserved baseline. A scoped TypeScript check reports no diagnostics in the four touched TypeScript files; the full website check remains failing on other repository errors, and the scoped dependency graph reports seven diagnostics outside these files.

The current editor reports MOVE / KEEP as retained in the writing wall but absent from its placed-artifact list. The Literary view now surfaces that mismatch. Source implementation is available, but this pilot does not establish the presence of all five encounters in the current room. Resolve placement or linked-part discovery before treating a walk through this edition as verified. Other missing/duplicate optional-artifact notices belong to the existing room state and were not repaired in this writing pass.

At initial assembly, reader judgement, headset experience and independent reconstruction were uncollected. The later supplied criticism above now provides an editorial comparison; independent participant and headset evidence remain uncollected.
