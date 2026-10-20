# Subject, encounter and writing: first research-loop scaffold

Palle's direction, 15 October 2026: build enough scaffolding for spatial and textual thinking to inform each other, so the relations among subjects, artifacts and texts can develop through use. The implementation below is a first scaffold, not evidence that the resulting room or prose already works.

## What the loop adds

The wall already keeps subjects, many-to-many artifact connections, tags, a walking order and two writing overlays. Connections alone do not explain why an arrangement should change. A research record now connects a question to an intervention, evidence, interpretation and revision.

The generic **Research loop** tab works on every map. Both text columns can initiate a loop, as can a selected artifact or subject. A loop contains:

1. Its originating medium, connected subjects/artifacts, question, baseline, one change and prediction.
2. An observation, evidence locations, replay and independent reconstruction reports, and an interpretation that can retain uncertainty.
3. Proposed room/apparatus, tutorial and final changes; the changes actually made or rejected; and a next question.

Creation preserves a snapshot of the current wall order, artifact positions, subjects, writing seeds and saved source texts. It does **not** capture the running Godot apparatus. Record the actual seed, sample, configuration, code version and relevant runtime state in the baseline and evidence fields.

**Add proposals to wall drafts** creates separate tutorial/final notes. They appear in the relevant text path when their artifact is tagged for that text, or among retained notes otherwise. A room proposal attaches to the first connected artifact's apparatus-proposal field. This is a one-time transfer per loop; the resulting notes remain editable. It does not enact a physical move or replace authored prose. Record those subsequent changes in the decision field. **Try the next question** creates a linked fresh experiment with blank observations, preserving the previous record.

Drafts use the existing Undo/Redo and Save wall mechanism. Saving retains history and rejects stale source versions. Export this loop produces a Markdown research receipt; Export wall JSON includes all loops. Historical artifact/subject names survive removal from the current wall. The data is optional in writing-wall/1, so older walls retain their previous shape.

## The first pilot

On Random Definition choose **Start the 48-value pilot**. It proposes comparing flat colour and height from the same stored values, holding the arrangement and viewpoint fixed. Bar bottoms stay fixed; record the amplification/range. Combined colour/height, size and rotation can become subsequent one-condition experiments.

The starter deliberately leaves observation, evidence and verification empty. Existing author requests about gaps, bar bases and amplification motivate the setup but do not establish the perceptual effect of this particular comparison.

Success is not simply that the bars move. Record a detectable difference, a meaningful question, an unhelpful difference, or a reason to rebuild the apparatus. Replay of a recorded outcome and acquisition of fresh physical randomness remain different operations.

## The editorial contract

The tutorial gives the reader a usable capacity: reconstruct, predict and alter an operation. The final is a literary passage in the museum's novel, with Palle's OOO orientation. Its object can open into history, exact definitions, desire or unintended use, returning attention to the encounter. They need different writing decisions even when drawing on the same experiment.

Space should make relations inspectable through scale, proximity, sequence, bodily movement or comparison. An attraction line is a planning relation, not proof that two artifacts belong next to each other. Record what spatialization reveals and hides. Leave room for an artifact to resist its assigned subject.

Walking order, conceptual connections and reading order are distinct. The existing side-by-side text preview remains aligned by room stops; this iteration has not implemented independent reading timelines in that preview. The authored texts and their existing content-tree/timeline plans can already diverge. A later change should bring those reading timelines into the wall without forcing the final or tutorial into the walking sequence.

## Next practical cycle

- Capture the bench's actual runtime receipt, run the single comparison and record an observation.
- Make one small tutorial revision and one literary passage from that evidence; test reconstruction and reading independently.
- Try the proposed room/apparatus change, document what was actually changed, then run a new loop.
- Assess whether the next question becomes more specific and whether either medium reveals a problem the other missed.
- Use this evidence to decide whether the interface needs fewer fields, an independent reading timeline, automatic apparatus receipt import, or explicit comparison of two layouts.

No observation, reader response or headset verification has been manufactured. Literary voice and embodied effect remain unassessed; an overall Ada alignment score would be premature.

## Verification and limits

Implementation lives in the sibling ada_encyclopedia repository. All 28 writing-wall tests pass, including new coverage for research persistence, historical references, blank evidence in proposed pilots, one-time proposal staging and malformed records. The focused TypeScript check passes. No live browser/VR interaction was verified in this iteration because the earlier browser inspection policy block remains in effect. No production wall data was saved by the agent; the pilot is an explicit draft action in the UI.

Artifact correctness, the visitor's experiment cycle and cross-hall transfer remain separate verification levels. Scene loading, runtime stability, performance and VR interaction also require their own checks. A filled form is not a completed research result.

## Optional entropy and information reading · later on 15 October

The [entropy observation card](../research/entropy/observation-card.md) adds a measurement contract when a question needs it: quantity/units, variable/distribution or ensemble, observation scale, intervention and limits. It maps into the fields already described above; it does not add a mandatory meter or a new UI schema. The [cross-map framework](../research/entropy/README.md) distinguishes changing a state, changing its record and changing the rules. Worked cards retain both current evidence and unresolved confounds. Human observations stay blank until collected.
