# A delivery with an inside

Model B · first-floor research · 20 October 2026  
**Editorial experiment. No scene or canonical chapter has been replaced.**

The opening already has something worth keeping: a number that began before the visitor arrived. Model B does not need that encounter to discover counting, consciousness or care. It might want a particular relation with the number: to frame it, obstruct its view, keep someone company beside it, or leave it counting. The delivery crate can make those possibilities spatial before a narrator explains the tower.

This is a reading of the existing apparatus, followed by proposals. “First floor” here means the **first encountered level, roof / index 0 / Point Zero**, with **Point One on index 1, six metres below**, inspected as the immediate continuation. This preserves the current sequence. Starting inside a crate on Point One instead would be a separate routing decision.

## Working authority

The author's message and the supplied [Model B handover v3](model-b-handover-v3.md) govern this experiment. The attachment is retained verbatim. Its character premise is the working specification; its example passages, equipment and local events remain proposals. The author's additional instruction is decisive: **the player is not Model B** and begins inside a wooden delivery crate marked **CARE UNIT — MODEL B**. That label does not establish who or what is inside.

Model B already has general intellect and inherent care. Its knowledge is extensive; its local access is situated. It knows it was misdelivered and need not return immediately. Purpose and desire concern what it enters into, composes, refuses or leaves. Neither new intelligence nor better morality is a reward for descending.

There is no new narrative database, character progression system or purpose meter in this work. The existing map files, trial layouts, editorial iterations, source inspections and evidence records are sufficient for this first investigation.

The supplied *Design the Void Game* PDF is the nine-page architectural proposal dated by the supplied file to 18 October. It is background, not a description of everything now implemented. The supplied *Residue* edition has 68 PDF pages. Reading here concentrates on its preface, opening, drafter and nurse chapters, and closing exchanges; this is not a claim to have audited every chapter or its separate production repository.

## The established apparatus

Ada already has functioning algorithmic artifacts, Godot scenes, map and registry structures, input adapters, technical tutorials, literary `final.md` readings, research notes and experimental tools. These have different histories and different degrees of verification. They are the material for a new encounter.

| Existing part | What this investigation can draw from |
| --- | --- |
| [Void layout](../../../../commons/void/layout.json), [rooms](../../../../commons/void/rooms.json), [architecture](../../../../commons/void/architecture.gd) and [floor content](../../../../commons/void/floor_content.gd) | A 42 × 18 m slab, two 5 × 6 m shafts centred at x = −10 and +10, columns, six-metre storeys, optional partitions, supply geometry and placed artifacts. |
| [Room source](../../../../commons/void/room_source.gd) | Separate trial layouts and the existing `--void-draft=` override. A reviewed crate prototype can use this mechanism without overwriting the curated tower. |
| [Lab editor](http://localhost:3003/lab-editor?mode=void&floor=0) | The shared arrangement of artifacts and props. A future crate should remain an independently placeable object in this same arrangement. |
| [Shipping crate](../../../../commons/artifacts/crate/crate.gd) | Procedural plank faces, corner strips, X-bracing, dimensions and a configurable stamped label. Existing construction material, not yet an inhabitable arrival scene. |
| [Architectural interfaces](../2026-10-20-architectural-interfaces/index.html) | Five housing mounts; existing button operations and readouts can be carried into an architectural housing. The first adapter supports selected Noise artifacts, not every artifact automatically. |
| `tutorial.md`, `final.md`, `technical.md`, encounter references and `walked.md` | Distinct kinds and editions of writing. Dates and source configurations matter; a confident older reference can be stale. |
| [Discovery and remainders](../../DISCOVERY_AND_REMAINDERS.md), [voice study](../../VOICE_STUDY.md), [voice decision](../../course/VOICE_DECISION.md) | Existing authorial corrections, rejected trials, close-reading criteria and the requirement to check the actual map before revising prose. |
| Existing native probes, screenshot reports and editor checks | Tests can establish a specific operation or arrangement. They cannot certify the literary force of a passage, a visitor's understanding or Model B's desire. |

The 2023 [application](../../../VR_VR_PT_2023.md) already situates the research within algorithmic margins, spatial transformation, and care and repair. This provides continuity for the inquiry. It does not establish a fictional machine's circuitry or grant it access to the engine.

## Encounter dossier: what is here

**Evidence boundary:** the observations below are verified against the current saved placement data and source branches. No new playtest or headset observation was performed for this dossier. A prior [39-check native report](../2026-10-19-triangles-roof-and-points/checks.json) covers, among other things, the enlarged counter, roof lettering, rod lamps and switch. That dated result is supporting history, not a fresh certification of today's entire layout.

### Roof / Point Zero

The saved roof places the original frame counter at x/z `(0.25, −7.25)`, height 2, scale 3.5; the floor inscription at `(−0.25, −4)`; and the large extruded **ADA RESEARCH** lettering at `(0, −7.8)`. The source also builds the origin marker at world zero and retains “THE ENDLESS MUSEUM / always another room.” Ordinary play starts on the roof at `(-6, 0.06, 4.5)`, unless a trial or start-floor argument overrides it.

The counter uses `Engine.get_process_frames()` with its default boot epoch. It counts process frames, not elapsed seconds, previous software versions or the building's construction history. Its running total can exceed the visitor's first observed value without recording that visitor at all.

**A lost configuration:** the museum's Point Zero map explicitly sets `you_are_here` to `peel:loose`. The Void roof does not supply that setting. Its scene defaults to `peel = "fixed"`, so the roof currently constructs fixed text, not the `StruckWord` pickable body described in the literary chapter. The pickup capacity already exists. Restoring it would be a small instance configuration change, proposed here rather than silently applied.

Folding Past belongs to the original museum's configured lobby. It is not placed in this roof record or constructed by its inspected floor builder. The tower therefore does not currently support the chapter's instruction to look through that entrance window.

### Floor 1 / Point One

The three small stations stand at x = −3, 0 and +3, z = 2.5. All three explicitly disable their study plinths. The absent station creates no sphere; the visible station creates a sphere of radius 0.14 m; the solid station adds a separate fixed spherical collision boundary. Their local reference height is 1.12 m. The large sphere at `(0, −4.3)` is 1.3 m across, black and glossy, on its retained large pedestal.

The floor includes the container, scaffold and tarp, unfinished wall, work lights, partition walls, a fence panel and an imported corridor door. This is an arranged construction site, not the original narrow corridor.

The switch reuses the museum control but its Void adapter removes the local sun and fill. It toggles the floor's `void_point_rod_light` group. The pink feeds end in small downward spotlights; the sky and global sun are not switched off. This distinction changes a particular passage without invalidating the separation between visibility and collision.

### The supply line

The tower builds risers, overhead branches, four sockets and pink connections to artifacts. On the roof, service masts support the overhead arrangement; there is no upper floor slab to hang from. These are modeled connections. They do not currently solve an electrical circuit or gate artifact operation through voltage, continuity or available power.

The new interface terminal forwards button signals to the original artifact and mirrors its readout. Its visible service feed is not the signal transport mechanism. A narrator may trace a cable with a hand; an author may inspect a callback. Those are different kinds of access.

### The crate

The existing crate builds six closed faces and external reinforcement. Its configurable label makes **CARE UNIT — MODEL B** a plausible adaptation of a present capacity. Enlarging that asset alone does not establish a usable interior, an opening, collision clearance, a safe spawn or a panel the player can release. Those are the bounded additions a later prototype would need.

No Model B body, sensor interface or crate arrival is established by these opening-floor sources. The fiction below declares those additions rather than passing them off as observed gameplay.

## Close reading: preserve, relocate, revise

The full current passages are preserved here as [Point Zero](Point_Zero-existing.md) and [Point One](Point_One-existing.md). Their originals remain unchanged.

| Existing writing | What works | What the tower changes |
| --- | --- | --- |
| Point Zero: “Its first number for you is not its first number.” | A concise relation between an observed beginning and a process already underway. It does not require a novice narrator. | The crate can delay the view of that process. It should not reset the counter to make the fiction convenient. |
| Point Zero's unread code and inherited work | The apparatus exceeds any one visit. Choosing where to begin has a cost without making incompleteness a defect. | Model B can understand counting and still lack this machine's history, code access or complete state. The human learner's tutorial remains separate. |
| Arrival shaft, Folding Past window, next corridor | These are materially specific, rather than generic atmosphere. | They describe the museum edition. A crate on the roof would need a different arrival and a descent handoff. Do not rename the tower a corridor merely to preserve the sentences. |
| The removable “you” | The text's address becomes something another body can handle. It offers a strong relationship without requiring a verdict about identity. | The roof has lost the enabling configuration. Choose whether to restore that operation in a trial before promising it in a Void reading. |
| Point One's label, surface and collision comparison | “The difference was invisible until you tried to cross it” is an encounter with a specific construction. It deserves to remain. | A changed route can make it shelter, obstruction or a misleadingly visible boundary. Model B's competence does not settle what it would want from that boundary. |
| “You have removed their sun” and the large white sphere | These give the original light experiment and size comparison their material terms. | The present switch controls rod lamps, and the large sphere is black. These are justified edition-specific repairs; they are not grounds for re-voicing the whole chapter. |

There is another documentation seam. The October 3 additions in both `technical.md` files describe tutorials that edit existing museum scripts. The current `tutorial.md` files instead provide a complete learner counter and point constructed from scratch. Point One's `encounter-reference.md` also describes an older three-script companion. The current tutorial code should remain the reproducible learner route; the older technical accounts need dated reconciliation if we publish a new edition. Model B should not be used to hide this discrepancy.

My recommendation is to retain the current literary chapters as museum readings and place this experiment alongside them. A future approved Void edition needs a small spatial/behavioural repair even if we reject both voice studies.

## Sa-i in this opening

Here Sa-i names the incomplete translations already available for investigation:

* The engine total becomes a displayed number. A body sees that number from somewhere; the counter has no corresponding entry for who saw it.
* A label classifies a consignment. A body occupies the container. Their co-location does not prove identity, ownership or obligation.
* A position acquires a visible surface; a separate collision shape constrains movement. Light helps locate either without supplying the boundary.
* A cable makes a connection visible while callbacks enact a different connection. A useful architectural sign can promise more than the program implements.
* A loose word can cross a room while the rest of its sentence remains attached to the floor. The script need not register what the newly arranged sentence is taken to mean.

These are Ada's working relations, not a claim about a scholarly consensus or a theory that every gap must demonstrate. An encounter can remain comic, inconvenient or uninteresting.

## Three assemblages to try

These are alternatives, not stages or unlocks.

### A. A room for looking — recommended first spatial trial

Reuse the crate's timber and bracing to make an interior with one already open face. Place a **proposed** 3.2 × 2.8 m outer footprint around x/z `(−3, 4.4)` on the roof, 2.6 m high, with the opening toward negative Z. This preliminary rectangle avoids the two shaft rectangles and the listed columns; it is not a collision or sightline test. A trial spawn would move inside it. The current saved spawn would stay untouched.

The player meets wood, an opening and a partial view before the full roof. The label is outside: discovering it requires leaving and looking back. Model B, provisionally embodied outside, wants to use the packing interior as a place from which to watch the counter. It can yield the exit to the player without deciding the player is its patient.

**Literary form:** sustained first-person attention, interrupted by the other body's movement. **Possible cost:** B's preferred viewpoint competes with an exit. **Risk of distortion:** patient observation could become another tasteful contemplative booth. Keep the possibility of walking straight past it.

### B. An address that travels

Use the same crate and restore the museum's existing `peel:loose` setting on the trial's roof inscription. The player can carry **YOU** back to the crate, elsewhere, or nowhere useful. Model B wants to see whether the word can be made to address the label without supplying a new name for either body.

**Literary form:** short comic exchange; the player can answer through placement rather than prescribed dialogue. **Possible cost:** moving the word changes what the next visitor finds. **Risk of distortion:** the scene could announce “the player is Model B” as a puzzle solution. It must not do that. No score or recognition trigger should certify a correct arrangement.

### C. A good place to keep a bad view

Keep the roof inscription fixed. Reuse a packing panel as a proposed small movable screen. Model B tries to conceal some counter digits while leaving the rest visible, making a private composition that serves no maintenance purpose. The other person can prefer the unobstructed number. Neither must persuade the other.

**Literary form:** comic direct action with little explanation. **Possible cost:** loss of a shared view; a panel can obstruct circulation. **Risk of distortion:** moving the panel must only occlude the display. It must not alter the count or smuggle in code-editing powers.

A new playable panel and a movable Model B body would require review and implementation. Their wood, material vocabulary, pickup conventions and testing methods already have homes in the project.

## What we take from Residue

In the supplied edition, the folded pass on page 9 alters one repetition through a small material change. On page 19, a full-size sprig sits in a 1:500 architectural model without being corrected into conformity. On page 25, an occupied bed puts a maintenance schedule in conflict with a body. On pages 65–66, earlier marks become legible together through an existing registry.

These offer methods: establish an affordance before a consequential act; let another body change the use of a familiar operation; let a mark recur under different conditions; make procedural precision affect what can happen. The application of those methods here is our interpretation.

We need not borrow the serial timestamps, repeated protocol sentences, signature endings, clipped negations, or missing-recipient plot. Ada's September voice study records that an earlier restrained trial was rejected. Its authorial correction asks for oscillation between anomaly, desire, technical inquiry and further discovery. Nor should we copy the novella's moments of changed ethical recognition into an arc where Model B acquires care.

## Voice experiments

Read [the two passages](voice-studies.md) on their own before returning to their evidence notes. Both use **first-person Model B**, distinct from the person leaving the crate. In both, ordinary embodied sight and movement are explicitly proposed; neither narrator reads the repository, knows another mind or controls an artifact by thinking at it.

**Study A** gives the crate a possible life after delivery. It adds sustained desire without a useful task. It risks making every delay seem profound; a shorter version may prove better aloud.

**Study B** makes two labels socially awkward through direct action. It adds humor and disagreement, but depends on restoring the loose word and could become a tidy identity metaphor. Keep the person free to take the word somewhere the author did not intend.

Neither passage is a candidate replacement merely because it is new. Their strongest test is whether we want to return to an image or action after removing these research notes.

## A bounded next experiment

After spatial review, use the existing separate-trial or draft-layout mechanism for A. Reuse the crate generator's surfaces and braces; supply a real hollow interior and opening. Save its editable placement using the current layout system. Do not replace the roof, the first descent or the saved player rig.

Use the current native test/capture approach to check:

1. The proposed spawn fits inside; both seated/standing views and desktop passage can reach the opening without intersecting panels. A visually missing face must not leave a solid cuboid collider.
2. The way out reaches solid roof, with shafts and intended descent routes still available. Check actual sightlines to the counter instead of relying on the plan.
3. The counter continues while hidden and is not reset by leaving the crate. A panel's occlusion changes visibility only.
4. If B is tried, the original loose-word constructor creates one pickable first word; the remaining words stay fixed. Exercise the actual desktop and XR pickup pathways.
5. The label remains a label. No interaction identifies the player as Model B, assigns the player as its patient, or grants intelligence/care points.
6. Keep an event/capture record separate from the narrator's interpretation. A route check cannot establish that the scene is compelling.

For the literary review, read each passage without headings or evidence notes. Ask where attention persists, where a sentence explains away its object, whether B wants anything particular, and whether the player's silence has been turned into consent. An unused possibility may remain unused.

## Sources and preservation

The linked source files above were inspected in this checkout. The current chapters are included verbatim for comparison. [Preservation results](preservation-checks.json) record hashes of the untouched chapters, tutorials, layouts and opening runtime files.

Additional supplied sources: `C:/Users/palle/Downloads/Design the Void Game.pdf`; `C:/Users/palle/Documents/GitHub/AdaResearch_46/doc/residue-book-one_Ada.pdf`; `C:/Users/palle/Downloads/ada_research_model_b_care_unit_handover_v3.md`. The copied handover is a source record, not a replacement for future authorial decisions.

No new crate, Model B actor, care mechanic, narrative progression, or electrical simulation has been installed. The useful result of this pass is a specific proposed encounter, two voices to judge, and a clearer account of what the existing work already permits.
