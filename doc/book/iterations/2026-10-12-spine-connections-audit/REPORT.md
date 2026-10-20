# What the whole spine keeps — and where it breaks

12 October 2026 · Source-based editorial audit · 25 sequences / 206 halls

**The order largely holds. The main weakness is uneven continuity between the book's making track and the existing museum. Improve the early Transformation → Arrays → Colour passage first, using the substantial drafts already written.** Two later tutorials also contain concrete outdated accounts that deserve small, immediate corrections: QFEP Introduction and PostCrisis Synthesis.

This report used [Museum Memory](http://localhost:3003/museum-memory?scope=project&view=overview) to keep the whole route visible, then unfolded the sources. Its 25 sequence summaries are an editorial reading, not 25 certifications. The review inventoried the tutorial, final and map-data files for all 206 live halls; read the 24 sequence boundaries; and closely compared selected weak or disputed tutorials with reflections, map placements, implementation and existing verification reports. It did not closely read every paragraph of all 412 possible manuscripts, rerun Godot, or walk the whole museum in a headset. Code-block counts helped locate gaps; they did not decide quality.

## What is working

The overall progression is intelligible: a body becomes something we can place and change; copies become arrangements; attributes and rules become fields; fields and local decisions produce patterns, growth and collective behaviour; representations and learning lead into questions about evidence and foundations. The ending can return an actual changed body, rather than merely announce that the visitor has learned something.

Several transitions already have specific reasons. Tiling prepares a rule applied across addresses; Change asks what differs between samples. Waves prepares return before Randomness complicates predictability. Shaders lets the learner author previously supplied surface rules, and Cellular Automata turns attention to local state across updates. Fractals, L-systems and procedural generation distinguish repetition, rewriting and selection. Graph Theory makes kinds of relation explicit before Machine Learning asks how observations and criteria produce an answer.

The reflective writing often carries these transitions more clearly than the canonical tutorial files. Preserve that writing. Melencolia, Rainbow and the walk through the Rhizome can have room for composition, celebration and reflection. Their value does not depend on adding another programming exercise.

## What to improve first

### 1. Close the first practical break: Transformation → Arrays → Colour

This is the highest-leverage teaching pass because everything later assumes this capacity. Primitives provides complete constructions, but six canonical Transformation tutorials still largely present excerpts. Most importantly, `commons/maps/Array/tutorial.md` is absent. Later Arrays lessons are short encounter guides. The Floor tutorial explicitly sends the reader to `final.md` for its step-by-step reading, blurring the two texts' jobs.

Much of the work is already available. The [Transformation review](../2026-10-06-transformation-tutorial-drafts/REVIEW.md) has seven complete lesson drafts; [Array — a slot kept](../2026-10-06-array-a-slot-kept/tutorial.md) builds on the whole cube and overlap collection; the [Colour review](../2026-10-06-colour-complete-drafts/REVIEW.md) contains eight complete drafts. These packages explicitly preserve canonical files and remain review drafts. Their existence must not be confused with incorporation into the book.

**First bounded delivery:** compare the current Trans_Pre lesson with its reviewed continuation; recover the Array lesson; then make the five-hall Arrays route complete before treating its skills as prerequisites for Colour. Keep transformation central: whole-object movement, rotation, scale, reference frames and overlap. Arrays then uses familiar bodies to teach address, membership, traversal and retained slots. Colour changes the attributes of those arranged bodies.

Completion means a reader can find one designated current lesson per hall, reconstruct its selected operation from its printed code and declared support, make an independent variation, and identify what carries onward. Re-run the relevant exact-code and variation checks when promoting or changing drafts. Do not infer that dated verification applies to newly assembled files.

### 2. Correct two accounts that contradict the current museum

**QFEP Introduction.** Its [tutorial](../../../../commons/maps/QFEP_Introduction/tutorial.md) describes a four-sphere formula and loads `res://commons/artifacts/qfep/term_sphere.tscn`, which is missing. Its [final text](../../../../commons/maps/QFEP_Introduction/final.md), [map](../../../../commons/maps/QFEP_Introduction/map_data.json) and [workbench](../../../../commons/artifacts/qfep_balance_workbench/qfep_balance_workbench.gd) instead support a precise encounter: four inputs, `F - lambda * E + phi * 0.3`, and KEEP retaining an input arrangement. Some term objects remain in the hall, but they do not make that printed construction executable. Focus the tutorial on the actual arithmetic and retained tuple. Keep the distinction between a fixed demonstration value and a measured rate.

**PostCrisis Synthesis.** Its [tutorial](../../../../commons/maps/PostCrisis_Synthesis/tutorial.md) says the ledger consists of timed, prewritten entries and records no visitor decisions. The [map](../../../../commons/maps/PostCrisis_Synthesis/map_data.json) enables `visitor_record:true` and places `assembly_return`; the [ledger implementation](../../../../commons/artifacts/accountability_ledger/accountability_ledger.gd) reads a real saved Assembly pose. The [final text](../../../../commons/maps/PostCrisis_Synthesis/final.md) already describes this well: thirteen joints, twelve connections, a latest released pose, and a count of actual edits. Bring the tutorial into that encounter. Preserve the honest limits: latest pose rather than gesture history, empty space before a record exists, no inferred visitor identity.

These are confirmed source contradictions, not requests for new rooms. They can be corrected independently of the larger early-chapter work.

### 3. Make the field and search bridges reconstructible

[Flow Field](../../../../commons/maps/Flow_Field/tutorial.md) accurately distinguishes arrows, moving particles and the shared directional field, but supplies no runnable learner construction. [Form Finding: Descent](../../../../commons/maps/FormFinding_Descent/tutorial.md) explains the installed gradient procedure without giving the student a complete small program. These are important transitions from a value at one place to a rule over places, and from motion to a search directed by a criterion.

Start with one familiar point and one visible update. For Flow: sample direction, advance a position, distinguish field time from particle position. For Descent: evaluate a cost, estimate a slope, take a step, inspect stopping. Show the particular thing held constant when a parameter changes. Keep the existing technical distinctions; do not turn the learning rate into physical speed or assume every field is a force. Complete Change and Form Finding before adding more illustrative algorithms.

### 4. Continue the Noise construction past its opening

The first two Noise tutorials contain substantial complete code. The following seven mostly return to descriptions and fragments. The [torus-and-sphere encounter](../../../../commons/maps/Noise_One/tutorial.md), for example, makes useful distinctions about gain, frequency, clipping and interpretation, but does not yet carry a printed learner implementation onward.

Preserve a familiar receiver and sampling rule while changing the use of a value: position, height, displacement, surface. The student should predict and produce one difference. This makes Noise → Shaders an earned change of execution context rather than a leap between descriptions. The full shader studies already make many of their earlier dependencies explicit.

### 5. Repair field → surface → solid composition

The start of [Isosurfaces](../../../../commons/maps/ISO_Introduction/tutorial.md) describes the controls and threshold well, but its tutorial often does the same job as the reflective walkthrough. [Boolean Verbs](../../../../commons/maps/Boolean_Verbs/tutorial.md) gives operation assignments without the complete small construction they require.

Teach one cell's sampled values and boundary before expanding the field. Then use two declared solids to compare union, intersection and difference with controlled operands. Separate appearance, generated mesh and collision. The installed comparison bays have other geometric differences; a minimal study can isolate the operation while naming that reduction.

`ISO_RhizomeBody/tutorial.md` is absent, but that alone is not a defect: its final text supports a reflective walk and explicitly says a plan beside the route is not installed. Decide whether it is a reflective capstone before commissioning code. Do not silently turn a proposed Trace → Rhizome connection into a working data handoff.

## All 25 sequences, in the live order

“Hold” means retain the direction based on this reading, not certify every exhibit or lesson. “Reconstruct” identifies a gap in the making track, not a request to rebuild the museum.

| Sequence | Reading across the three tracks | Next useful move |
| --- | --- | --- |
| Primitives · 15 | Clear progression from point to relation, record, face, body and limits; complete learner constructions are present. | Hold. Preserve which class or record returns; keep literal persistence distinct from reuse. |
| Transformation · 7 | Spatial subject is clear; the canonical tutorial route lags behind the complete seven-hall review. | Reconcile drafts and canonical lessons. Keep the familiar whole cube. |
| Arrays · 5 | Strong address and repetition encounters; first canonical tutorial missing, later making steps uneven. | First construction priority: a complete small five-hall route. |
| Colour · 8 | Reflection and artifacts extend attribute, context and choice; eight full drafts exist separately. | Review and incorporate deliberately after confirming the Arrays prerequisites. |
| Tiling · 9 | Complete studies develop source, rule and repeated surface into composition and wearing. | Hold. Distinguish rule changes from changes in material, placement and appearance. |
| Change · 2 | The move from sample to rate to field is well motivated; canonical making instructions are incomplete. | Reconstruct one time-dependent value and one field-driven point. |
| Forces · 11 | Complete source studies make vectors and updates usable; the receiver complicates physical response. | Hold. Keep force, velocity, displayed arrow and visitor response distinct at exits. |
| Form Finding · 6 | Search and chosen criteria fit here; tutorials describe more than they let the reader reconstruct. | Complete one descent before broadening to competing procedures. |
| Waves · 12 | Return and oscillation extend earlier time and motion; complete studies are present. | Hold. Keep phase, frequency and response attached to observable differences. |
| Randomness · 14 | Deepens a brief earlier use into seeds, distributions, trajectories and consequences. | Hold. Retain controlled comparisons and distinguish a new draw from replay. |
| Noise · 9 | Strong initial constructions; later encounter prose interrupts the practical lineage. | Continue the same sample/receiver through the remaining seven halls. |
| Shaders · 6 | Earlier supplied surfaces become authored parallel operations; complete lessons and review evidence exist. | Hold. Keep the main shader operation visible among host and support files. |
| Cellular Automata · 8 | Local rule and completed state build directly on arrays, grids and updates. | Hold. Preserve state-before/state-after distinctions and independent variations. |
| Fractals · 7 | Repetition becomes recursive construction; complete studies are present. | Hold. Make depth, termination and scale visible rather than add another catalogue. |
| L-systems · 8 | Stored symbols and a reader give recursion another mechanism; later assemblage complicates uniform rules. | Hold. Distinguish rewriting a sentence from interpreting it. |
| Procedural Generation · 7 | Generation and evaluation extend grammar and selection; full constructions are present. | Hold. Keep candidate, score and aesthetic choice separate. |
| Soft Bodies · 9 | Existing bodies acquire deformation and constraints; complete studies carry the conceptual work. | Hold. State which topology stays fixed when positions change. |
| Isosurfaces · 13 | A strong threshold/boundary inquiry; much of the tutorial is still an encounter guide. | Reconstruct a small field-to-boundary example; let the final walk remain a possible reflective capstone. |
| Boolean Surfaces · 3 | Spatial composition follows boundaries well; the learner's smallest complete construction is missing. | Two solids, one controlled change of operation, visible result and declared collision. |
| Swarm Intelligence · 7 | Local relations return as collective behaviour; complete studies are present. | Hold. Preserve distinctions between a simulation update, its display and a claim about social life. |
| Graph Theory · 8 | Relations become explicit data and procedures; the transition to learning is legible. | Hold. Keep connection, dependency, path and matching as different relations. |
| Machine Learning · 8 | Now has complete printed lessons, declared sphere revisions and a tested saved-data branch. Older planning notes understate this. | Update memory's dated assessment. Pace Sequence Memory as its declared two visits. |
| Foundations Crisis · 8 | Can carry the difference between a working result and grounds for claiming it; current complete lessons are present. | Hold the new reconstruction work. Deepen the specific return to Ada's AI production without making small learners stand for an LLM. |
| QFEP Laboratory · 8 | Reflective introduction is more exact than its obsolete tutorial. Several making lessons remain fragmentary. | Correct Introduction first; build from actual inputs, calculation, retained record and explicit limits. |
| Post-foundations · 8 | The ending now returns a real visitor-altered body; its tutorial still describes an older simulated ledger. | Correct Synthesis, then separate reflective encounters from selected reconstruction tasks. |

## Three connections worth making unmistakable

**Record → reconstruction → loss.** Trace keeps selected positions; Grid redisplays a kept record; ML Sequence Memory retains timed performances; Assembly's ending keeps a released pose and connections. These records are not the same format or automatically one file travelling through the museum. The recurring question is exact: what can this record reconstruct, and which question has its selection made impossible? The ending already gives this thread a bodily return.

**Representation → permission to act.** An invisible point, a mesh, a collider, a doorway, a painted surface and an extracted boundary make different promises. What can I see, touch, carry, cross or change? This connects the reflective and programming tracks through actual museum consequences. It prevents appearance from being mistaken for collision or a drawing from being mistaken for the whole coordinate system.

**Rule → criterion → authority.** A tiling rule arranges; an update changes; a search criterion selects; a learning objective fits; the QFEP console compresses several inputs into a result. These are different operations. At each return, locate the choice the student can change, then let final.md ask what that choice permits, privileges or excludes. Avoid a generic claim that every rule expresses the same politics.

These three threads give the wider cross-domain argument a spine without requiring each hall to repeat a theory paragraph or every exhibit to become a lesson.

## What the memory system learned

The compression was useful for finding the route, but unfolding changed the diagnosis. [An older ML brief](../../course/storyboards/AI_CRITICAL_THREAD.md) still calls the tutorials fragmentary. The [11 October whole-route review](../2026-10-11-ml-whole-route/REVIEW.md) and current manuscripts instead document complete constructions and saved-data handoffs. Its reported checks were read, not rerun here. An unchanged old brief can be obsolete when the implementation advances elsewhere; hashing that brief alone cannot detect this.

Keep a short sequence memory with four distinctions: intended carry; current book source versus review draft; observed museum behaviour versus a supplied or proposed study; unresolved discrepancy with an inspection date. Attach claims to the canonical sources that could falsify them. Preserve old decisions as history, not unlabelled present instructions.

The main findings from this pass are recorded as **proposals** in Project Memory, with source receipts and related scopes. They do not approve a reorder or overwrite tutorials, reflections or Godot code. The project note links this report so that a future whole-spine packet can recover the audit before repeating it.

## The next pass

Start with **Array — a slot kept**, alongside the current Trans_Pre source and the existing Arrays reflections. Establish the reviewed tutorial as the designated learner text, run its exact printed program and an independent variation, then continue through the remaining four Arrays halls. Keep the early book's reflective writing intact unless a specific encounter conflicts with it.

In parallel as an editorial queue—not an automatic implementation—retain the two precise QFEP and Synthesis corrections. After the early bridge, complete Change and Form Finding, then the latter Noise lessons, then Isosurfaces and Booleans. Do not reorder the spine to conceal unfinished tutorial work.

The artifact accompanying this report includes `inventory.json` with paths, presence checks and source hashes for all live halls. It is an audit snapshot, not a runtime or educational score. Dated verification reports support what their named runs checked; they do not establish headset comfort or human learning. Those remain the next kind of evidence after the text and executable route agree.
