# The whole spine as a capacity tree

Open [the living graph](http://localhost:3003/capacity-tree).

The global diagram covers the current 25 sequences. Enter a sequence to see
all its halls; select a hall for bring / learn / carry, its object, new operation,
proposed learning checks, source notes and saved code-test status. The topic
view follows introductions and returns. Building associations show possible
Void uses; they are explicitly proposals, not an inventory of tested prefabs.

Current source counts: **209 halls, 126 registered topics, 503 recorded hall
prerequisites**. These are calculated live. The topic register does not yet
name every subject in the hall plans. The original detailed Point → wedge +
cube → construction tree remains at `?scope=foundation`.

## The order question

Arrays already begin in Trace, then return in Grid. The complete Arrays
sequence currently brings material from Trans_Pre, Trans_Rotation and Trans_Pit.
The preview swap makes six prerequisite links point forward across four Array
halls. It does not save a reorder. A proposed earlier bridge is a static,
repeated wedge/cube construction using the list and loop already learned;
Transformation then changes those same pieces. That reusable construction
join remains to be implemented and tested.

## Known gaps retained

- Random_Entropies, Noise_Cellular and Noise_Box have no saved lesson plan.
- ISO_RhizomeBody has no tutorial file.
- Five registered topics are unplaced, including intentionally deferred topics.
- Twelve topics have placement questions. Some refer to old halls; one return
  precedes its recorded introduction. No placements were silently repaired.
- The live spine has 209 halls; the earlier saved overview counted 208.

## Sources and implementation

`commons/maps/curriculum_spine.json` and the sequence files determine order.
The existing execution plan supplies objects, checks, carry notes, topic
placements and dependencies. Hall cards supply chosen subjects. The authored
`commons/void/capacity-spine.json` contains only global visual arrangement,
curated conceptual branches and proposed building associations.

In the sibling encyclopedia, `src/lib/capacity-spine.ts` makes the read-only
projection and hypothetical order comparison; `src/app/capacity-tree/` renders
it. The graph is not another editable syllabus. Existing plan and hall-card
editors remain the editing interfaces. Tutorial text, reflective text, spine
order, museum logic and the Void layout were not changed.

## Verification

`node scripts/check-capacity-spine.cjs` in the encyclopedia checks the real
local plan endpoint against the model: live coverage and order, chosen
subjects, all topic placements, dependency completeness, the six swap links,
no input mutation, acyclic curated branches, source paths, and unchanged
hashes for the layout, spine, plan and hall cards.

Focused TypeScript compilation passed with zero diagnostics. Browser checks
covered the 25-sequence view, hall navigation, Trace → Grid, late QFEP halls,
topic search and an unplaced topic, 50 association nodes, prerequisite links,
SVG and JSON downloads, and the retained detailed opening tree. A hydration
warning from a split SVG title was fixed and the clean page was rechecked.
No new Godot or headset tests are claimed by this graph.

- `verification.json`: source hashes and data checks.
- `graph.json`: generated full data snapshot (not the editable source).
- `capacity-tree.svg`: actual browser SVG export.
- `whole-tree.png`: whole-spine browser view.
- `trace-lineage.png`: a selected hall and its connections.
- `arrays-order-preview.png`: the hypothetical ordering comparison.

![Whole spine](whole-tree.png)
![Trace and its carried object](trace-lineage.png)
![Array ordering comparison](arrays-order-preview.png)
