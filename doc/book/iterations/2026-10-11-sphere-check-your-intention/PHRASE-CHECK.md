# Check your intention

Stay beside the same sphere in the Endless Museum's **ML_Perception** hall. After teaching A and B, use **CHECK** to compare what you intended with what the model measured. A recognised result alone cannot tell us whether the model answered the question we meant to ask.

## Play

1. Teach and TRAIN both phrases as in [Two phrases](PHRASE-CHOICES.md). Press **CHECK** on the existing nearby console.
2. Choose **MEAN A**, **MEAN B** or **NEITHER** before recording. NEITHER means you intend a movement outside the two taught categories. It is not a third trained class.
3. Press **CAPTURE**. Prepare during the three-second count-in, then move both hands for eight beats. Your intention is locked for that take. BACK cancels an unfinished capture.
4. Read the result. The row is what you meant; the column is what the model returned: A, B, UNK (unknown) or AMB (ambiguous). One whole completed performance adds one count. The sphere remains still in CHECK, even when a class matches.
5. Choose an intention again for each new take. Try both familiar movements, a partial variation and a movement outside them. An interrupted or invalid take adds nothing. The board shows counts, not a score for your dance.
6. If the pattern of mistakes suggests a change, choose **BACK**, then A or B to teach new demonstrations. Press TRAIN and CHECK again. A changed model starts a new table; earlier records remain counted under EARLIER and available in EXPORT. Re-fitting unchanged examples returns the same model and therefore the same table.
7. **EXPORT** writes all kept checks, their intentions, measured takes, results and corresponding models to a local JSON file. **CLEAR** needs two presses and clears only the check journal in memory. It leaves teaching data, learned models and exported files intact.

The existing TEST remains an unlabelled inspection of a fresh take. TRY lets a recognised phrase activate the sphere. CHECK adds declared intent and a comparison table; its examples do not enter training automatically.

## Read the table

| You meant | Model A | Model B | Unknown | Ambiguous |
| --- | --- | --- | --- | --- |
| A | Agrees with intention | Another class selected | Neither template fits | Both fit too similarly |
| B | Another class selected | Agrees with intention | Neither template fits | Both fit too similarly |
| Neither | Accepted outside your intended categories | Accepted outside your intended categories | Withheld as intended | Both fit too similarly |

An ambiguous result remains its own outcome. The board does not quietly count it as correct. Unknown means neither learned prototype passes its limits; it does not mean the visitor has no intention. These rows describe your declarations for these particular takes, not independent ground truth.

## One-paragraph lesson

Carry the two timed prototypes and the same sphere. Before each complete test performance, declare A, B or neither. Keep that label out of prediction; compare it with the returned result afterward. Read the table by row and column, including unknown and ambiguous outcomes. Identify one repeated disagreement, return to teaching and revise the examples deliberately. Keep earlier evidence attached to its original model and test the revised model with new performances. Distinguish a learner's intention, a measurement and a model's decision.

## Code and records

`phrase_evaluation.gd` stores a journal separately from the existing `phrase_library.gd`. The core order is deliberate: validate the declaration and take, call `model.predict(take)` without the intention, then attach the intention to that result. Recording a check changes neither teaching examples, fitted parameters nor the earlier unlabelled test list.

The journal keeps complete timestamped takes and their returned distances. It refuses an exact copy of a teaching take and an exact duplicate already evaluated with the same model. This blocks accidental reuse in software tests; it cannot guarantee that repeated human performances are statistically independent. Validation and interruption handling still come from the existing phrase capture.

A content hash of the model snapshot identifies each version, including its demonstrations, learned paths, tolerances and policy. Revising the teaching produces a different record group. The table shows only the current group and reports how many earlier checks remain. The grouping is computed when entering CHECK or completing a check, not hashed every rendered frame.

EXPORT writes `user://ada_phrase_checks_v1.json`. Model snapshots are stored once per version, and each record refers to its model. Export is deliberate and local. Returning between lessons preserves the journal during the current session; restarting the application does not reload it. The file is available for external inspection, not imported as new training. Export again replaces the previous file. The journal is bounded at 120 checks; at the limit, export and clear before collecting more. No records are silently evicted.

`phrase_check.gd` supplies the nearby controls and twelve table cells. While capturing, it hides the table and restores the beat markers; afterward, the counts return. It restores the shared display on exit. The same sphere, pose/height datasets and one-phrase activity remain.

## What passed and what remains

Run `python tools/test_phrase_check.py`. Native Godot checks cover an independently expected confusion table, the same movement under different declared intentions, exact training/duplicate exclusions, unchanged models, separate version counts, preservation of mistakes, unknown/ambiguous outcomes, exported data, bounded storage, native buttons, intention locking, incomplete capture, tracking failure, panel restoration and the same sphere.

Run the earlier pose, height, phrase, two-phrase and dance test tools for regression checks. The single-phrase suite supplies real XR tracker nodes with synthetic positions. Museum rendering: `python tools/run_encounter_probe.py ML_Perception --sequence machinelearning --render --no-bridges --output-tag phrase_check --probe tools/probes/phrase_check_museum.gd`. Publish: `python tools/publish_phrase_check.py`.

These tests use controlled synthetic performances. Deliberate label/movement disagreements exercise the counting; they do not measure how often a human will be misunderstood. Human use, controller comfort and timing variation remain to be tried. Repeated personal checks may help you revise your examples, but after those checks guide changes they are no longer an untouched final evaluation set. Use fresh performances and, eventually, a separate final test when making a stronger accuracy claim.

## Reflection

You say what the movement was meant to be before the machine answers. Its answer may disagree. That disagreement does not establish which side owns the meaning: it shows that intention and the recorded relation are different things. The table makes a narrow question visible—what did this model return for these declared examples? Keeping the failed takes with the model that produced them prevents a later successful demonstration from erasing the history of that question.

## Compact instruction

Same sphere + A/B. CHECK: declare A/B/neither before capture; lock intent; predict without it; compare afterward. Whole takes, 3×4 counts. Unknown and ambiguous separate. Tests never train. Changed model gets own table; keep/export earlier takes + models. Human declarations, not universal truth or dance scores. Revise teaching, then collect fresh checks.
