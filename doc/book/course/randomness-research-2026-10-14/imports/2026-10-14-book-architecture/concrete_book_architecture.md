# The concrete architecture of the Ada Research book

I would define the book as a versioned literary and computational research apparatus. It has two simultaneous forms: a readable book and an experimental environment in which selected passages can be simulated, reconstructed, tested and rewritten.

The crucial distinction is that the book is not an instruction manual for the game, nor is the game merely an illustration of the book. Both participate in producing the work.

A passage can propose something that does not yet exist. The proposal can be text-simulated, interpreted as a computational model, and built in Godot. What happens can then change the writing, the code, or the direction of the research.

## 1. What already exists, and what needs to be added

I checked the current repository's book architecture. Ada already has most of the foundations.

| Existing component               | Current role                                           |
| -------------------------------- | ------------------------------------------------------ |
| `final.md`                       | Literary and critical encounter associated with a hall |
| `tutorial.md`                    | Reconstructable programming lesson                     |
| `map_data.json`                  | Spatial structure, artifacts and utilities             |
| Godot scenes and scripts         | The operational world                                  |
| Field notes and observations     | Evidence from encounters and development               |
| Course manifests and book frame  | Reading order, prerequisites and publication structure |
| Git history and research records | Version history and research provenance                |

The existing design also makes an important distinction: the student constructs a growing study within the Endless Museum, while the museum provides the environment, player, lighting and existing artifacts. Small studies can run separately, but return to the museum encounter. This is established in the repository's [Course World](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/doc/book/course/COURSE_WORLD.md) document.

What's missing is an explicit connection between a particular passage, its possible computational interpretations, its simulations, its observations, and subsequent revisions of that passage.

I would build that connection rather than replace the current book system.

## 2. The proposed architecture: six connected components

The recursive book apparatus

\#chatgpt-mermaid-\_r_1ai\_{font-family:-apple-system-body,ui-sans-serif,-apple-system,system-ui,"Segoe UI",Helvetica,"Apple Color Emoji",Arial,sans-serif,"Segoe UI Emoji","Segoe UI Symbol";font-size:16px;fill:rgb(13, 13, 13);}@keyframes edge-animation-frame{from{stroke-dashoffset:0;}}@keyframes dash{to{stroke-dashoffset:0;}}#chatgpt-mermaid-\_r_1ai\_ .edge-animation-slow{stroke-dasharray:9,5!important;stroke-dashoffset:900;animation:dash 50s linear infinite;stroke-linecap:round;}#chatgpt-mermaid-\_r_1ai\_ .edge-animation-fast{stroke-dasharray:9,5!important;stroke-dashoffset:900;animation:dash 20s linear infinite;stroke-linecap:round;}#chatgpt-mermaid-\_r_1ai\_ .error-icon{fill:rgb(243, 243, 243);}#chatgpt-mermaid-\_r_1ai\_ .error-text{fill:rgb(13, 13, 13);stroke:rgb(13, 13, 13);}#chatgpt-mermaid-\_r_1ai\_ .edge-thickness-normal{stroke-width:1px;}#chatgpt-mermaid-\_r_1ai\_ .edge-thickness-thick{stroke-width:3.5px;}#chatgpt-mermaid-\_r_1ai\_ .edge-pattern-solid{stroke-dasharray:0;}#chatgpt-mermaid-\_r_1ai\_ .edge-thickness-invisible{stroke-width:0;fill:none;}#chatgpt-mermaid-\_r_1ai\_ .edge-pattern-dashed{stroke-dasharray:3;}#chatgpt-mermaid-\_r_1ai\_ .edge-pattern-dotted{stroke-dasharray:2;}#chatgpt-mermaid-\_r_1ai\_ .marker{fill:rgb(143, 143, 143);stroke:rgb(143, 143, 143);}#chatgpt-mermaid-\_r_1ai\_ .marker.cross{stroke:rgb(143, 143, 143);}#chatgpt-mermaid-\_r_1ai\_ svg{font-family:-apple-system-body,ui-sans-serif,-apple-system,system-ui,"Segoe UI",Helvetica,"Apple Color Emoji",Arial,sans-serif,"Segoe UI Emoji","Segoe UI Symbol";font-size:16px;}#chatgpt-mermaid-\_r_1ai\_ p{margin:0;}#chatgpt-mermaid-\_r_1ai\_ .label{font-family:-apple-system-body,ui-sans-serif,-apple-system,system-ui,"Segoe UI",Helvetica,"Apple Color Emoji",Arial,sans-serif,"Segoe UI Emoji","Segoe UI Symbol";color:rgb(13, 13, 13);}#chatgpt-mermaid-\_r_1ai\_ .cluster-label text{fill:rgb(13, 13, 13);}#chatgpt-mermaid-\_r_1ai\_ .cluster-label span{color:rgb(13, 13, 13);}#chatgpt-mermaid-\_r_1ai\_ .cluster-label span p{background-color:transparent;}#chatgpt-mermaid-\_r_1ai\_ .label text,#chatgpt-mermaid-\_r_1ai\_ span{fill:rgb(13, 13, 13);color:rgb(13, 13, 13);}#chatgpt-mermaid-\_r_1ai\_ .node rect,#chatgpt-mermaid-\_r_1ai\_ .node circle,#chatgpt-mermaid-\_r_1ai\_ .node ellipse,#chatgpt-mermaid-\_r_1ai\_ .node polygon,#chatgpt-mermaid-\_r_1ai\_ .node path{fill:rgb(222, 234, 251);stroke:rgb(83, 154, 248);stroke-width:1px;}#chatgpt-mermaid-\_r_1ai\_ .rough-node .label text,#chatgpt-mermaid-\_r_1ai\_ .node .label text,#chatgpt-mermaid-\_r_1ai\_ .image-shape .label,#chatgpt-mermaid-\_r_1ai\_ .icon-shape .label{text-anchor:middle;}#chatgpt-mermaid-\_r_1ai\_ .node .katex path{fill:#000;stroke:#000;stroke-width:1px;}#chatgpt-mermaid-\_r_1ai\_ .rough-node .label,#chatgpt-mermaid-\_r_1ai\_ .node .label,#chatgpt-mermaid-\_r_1ai\_ .image-shape .label,#chatgpt-mermaid-\_r_1ai\_ .icon-shape .label{text-align:center;}#chatgpt-mermaid-\_r_1ai\_ .node.clickable{cursor:pointer;}#chatgpt-mermaid-\_r_1ai\_ .root .anchor path{fill:rgb(143, 143, 143)!important;stroke-width:0;stroke:rgb(143, 143, 143);}#chatgpt-mermaid-\_r_1ai\_ .arrowheadPath{fill:rgb(143, 143, 143);}#chatgpt-mermaid-\_r_1ai\_ .edgePath .path{stroke:rgb(143, 143, 143);stroke-width:1px;}#chatgpt-mermaid-\_r_1ai\_ .flowchart-link{stroke:rgb(143, 143, 143);fill:none;}#chatgpt-mermaid-\_r_1ai\_ .edgeLabel{background-color:rgb(252, 252, 252);text-align:center;}#chatgpt-mermaid-\_r_1ai\_ .edgeLabel p{background-color:rgb(252, 252, 252);}#chatgpt-mermaid-\_r_1ai\_ .edgeLabel rect{opacity:0.5;background-color:rgb(252, 252, 252);fill:rgb(252, 252, 252);}#chatgpt-mermaid-\_r_1ai\_ .labelBkg{background-color:rgba(252, 252, 252, 0.5);}#chatgpt-mermaid-\_r_1ai\_ .cluster rect{fill:rgb(243, 243, 243);stroke:rgba(0, 0, 0, 0.1);stroke-width:1px;}#chatgpt-mermaid-\_r_1ai\_ .cluster text{fill:rgb(13, 13, 13);}#chatgpt-mermaid-\_r_1ai\_ .cluster span{color:rgb(13, 13, 13);}#chatgpt-mermaid-\_r_1ai\_ div.mermaidTooltip{position:absolute;text-align:center;max-width:200px;padding:2px;font-family:-apple-system-body,ui-sans-serif,-apple-system,system-ui,"Segoe UI",Helvetica,"Apple Color Emoji",Arial,sans-serif,"Segoe UI Emoji","Segoe UI Symbol";font-size:12px;background:rgb(243, 243, 243);border:1px solid rgba(0, 0, 0, 0.1);border-radius:2px;pointer-events:none;z-index:100;}#chatgpt-mermaid-\_r_1ai\_ .flowchartTitleText{text-anchor:middle;font-size:18px;fill:rgb(13, 13, 13);}#chatgpt-mermaid-\_r_1ai\_ rect.text{fill:none;stroke-width:0;}#chatgpt-mermaid-\_r_1ai\_ .icon-shape,#chatgpt-mermaid-\_r_1ai\_ .image-shape{background-color:rgb(252, 252, 252);text-align:center;}#chatgpt-mermaid-\_r_1ai\_ .icon-shape p,#chatgpt-mermaid-\_r_1ai\_ .image-shape p{background-color:rgb(252, 252, 252);padding:2px;}#chatgpt-mermaid-\_r_1ai\_ .icon-shape .label rect,#chatgpt-mermaid-\_r_1ai\_ .image-shape .label rect{opacity:0.5;background-color:rgb(252, 252, 252);fill:rgb(252, 252, 252);}#chatgpt-mermaid-\_r_1ai\_ .label-icon{display:inline-block;height:1em;overflow:visible;vertical-align:-0.125em;}#chatgpt-mermaid-\_r_1ai\_ .node .label-icon path{fill:currentColor;stroke:revert;stroke-width:revert;}#chatgpt-mermaid-\_r_1ai\_ .node .neo-node{stroke:rgb(83, 154, 248);}#chatgpt-mermaid-\_r_1ai\_ [data-look="neo"].node rect,#chatgpt-mermaid-\_r_1ai\_ [data-look="neo"].cluster rect,#chatgpt-mermaid-\_r_1ai\_ [data-look="neo"].node polygon{stroke:url(#chatgpt-mermaid-\_r_1ai\_-gradient);filter:drop-shadow( 1px 2px 2px rgba(185,185,185,1));}#chatgpt-mermaid-\_r_1ai\_ [data-look="neo"].swimlane.cluster rect{filter:none;}#chatgpt-mermaid-\_r_1ai\_ [data-look="neo"].node path{stroke:url(#chatgpt-mermaid-\_r_1ai\_-gradient);stroke-width:1px;}#chatgpt-mermaid-\_r_1ai\_ [data-look="neo"].node .outer-path{filter:drop-shadow( 1px 2px 2px rgba(185,185,185,1));}#chatgpt-mermaid-\_r_1ai\_ [data-look="neo"].node .neo-line path{stroke:rgb(83, 154, 248);filter:none;}#chatgpt-mermaid-\_r_1ai\_ [data-look="neo"].node circle{stroke:url(#chatgpt-mermaid-\_r_1ai\_-gradient);filter:drop-shadow( 1px 2px 2px rgba(185,185,185,1));}#chatgpt-mermaid-\_r_1ai\_ [data-look="neo"].node circle .state-start{fill:#000000;}#chatgpt-mermaid-\_r_1ai\_ [data-look="neo"].icon-shape .icon{fill:url(#chatgpt-mermaid-\_r_1ai\_-gradient);filter:drop-shadow( 1px 2px 2px rgba(185,185,185,1));}#chatgpt-mermaid-\_r_1ai\_ [data-look="neo"].icon-shape .icon-neo path{stroke:url(#chatgpt-mermaid-\_r_1ai\_-gradient);filter:drop-shadow( 1px 2px 2px rgba(185,185,185,1));}#chatgpt-mermaid-\_r_1ai\_ .node text{font-size:14px;font-weight:600;letter-spacing:normal;fill:rgb(65, 65, 65);}#chatgpt-mermaid-\_r_1ai\_ .edgeLabels text{font-size:13px;font-weight:600;letter-spacing:-0.08px;fill:rgb(65, 65, 65);}#chatgpt-mermaid-\_r_1ai\_ .node tspan[font-weight="normal"],#chatgpt-mermaid-\_r_1ai\_ .edgeLabels tspan[font-weight="normal"]{font-weight:600;}#chatgpt-mermaid-\_r_1ai\_ .edgeLabel .label rect{opacity:1;rx:13px;ry:13px;fill:rgb(252, 252, 252);stroke:rgb(219, 219, 219);stroke-width:1px;}#chatgpt-mermaid-\_r_1ai\_ .node rect,#chatgpt-mermaid-\_r_1ai\_ .node circle,#chatgpt-mermaid-\_r_1ai\_ .node ellipse,#chatgpt-mermaid-\_r_1ai\_ .node polygon,#chatgpt-mermaid-\_r_1ai\_ .node path{fill:rgb(243, 243, 243);stroke:rgba(0, 0, 0, 0.1);stroke-width:1px;}#chatgpt-mermaid-\_r_1ai\_ .node rect{rx:16px;ry:16px;}#chatgpt-mermaid-\_r_1ai\_ .node.mermaid-decision .label-container{fill:rgb(249, 249, 249);stroke:rgb(219, 219, 219);stroke-dasharray:2,2;}#chatgpt-mermaid-\_r_1ai\_ .edgePaths .flowchart-link{stroke:rgb(143, 143, 143);stroke-width:1px;stroke-linecap:round;stroke-linejoin:round;}#chatgpt-mermaid-\_r_1ai\_ .marker{fill:rgb(143, 143, 143);stroke:rgb(143, 143, 143);}#chatgpt-mermaid-\_r_1ai\_ :root{--mermaid-font-family:-apple-system-body,ui-sans-serif,-apple-system,system-ui,"Segoe UI",Helvetica,"Apple Color Emoji",Arial,sans-serif,"Segoe UI Emoji","Segoe UI Symbol";}#chatgpt-mermaid-\_r_1ai\_ .primary rect{fill:rgb(220, 239, 235)!important;stroke:rgb(57, 123, 112)!important;color:rgb(24, 60, 54)!important;}#chatgpt-mermaid-\_r_1ai\_ .primary polygon{fill:rgb(220, 239, 235)!important;stroke:rgb(57, 123, 112)!important;color:rgb(24, 60, 54)!important;}#chatgpt-mermaid-\_r_1ai\_ .primary ellipse{fill:rgb(220, 239, 235)!important;stroke:rgb(57, 123, 112)!important;color:rgb(24, 60, 54)!important;}#chatgpt-mermaid-\_r_1ai\_ .primary circle{fill:rgb(220, 239, 235)!important;stroke:rgb(57, 123, 112)!important;color:rgb(24, 60, 54)!important;}#chatgpt-mermaid-\_r_1ai\_ .primary path{fill:rgb(220, 239, 235)!important;stroke:rgb(57, 123, 112)!important;color:rgb(24, 60, 54)!important;}#chatgpt-mermaid-\_r_1ai\_ .primary tspan{fill:rgb(24, 60, 54)!important;}#chatgpt-mermaid-\_r_1ai\_ .secondary rect{fill:rgb(231, 232, 239)!important;stroke:rgb(119, 124, 149)!important;color:rgb(48, 52, 77)!important;}#chatgpt-mermaid-\_r_1ai\_ .secondary polygon{fill:rgb(231, 232, 239)!important;stroke:rgb(119, 124, 149)!important;color:rgb(48, 52, 77)!important;}#chatgpt-mermaid-\_r_1ai\_ .secondary ellipse{fill:rgb(231, 232, 239)!important;stroke:rgb(119, 124, 149)!important;color:rgb(48, 52, 77)!important;}#chatgpt-mermaid-\_r_1ai\_ .secondary circle{fill:rgb(231, 232, 239)!important;stroke:rgb(119, 124, 149)!important;color:rgb(48, 52, 77)!important;}#chatgpt-mermaid-\_r_1ai\_ .secondary path{fill:rgb(231, 232, 239)!important;stroke:rgb(119, 124, 149)!important;color:rgb(48, 52, 77)!important;}#chatgpt-mermaid-\_r_1ai\_ .secondary tspan{fill:rgb(48, 52, 77)!important;}Literary passageSimulation propositionText simulationGodot experimentObservation and evidenceRevision / learning debtVersioned reading editionReconstructable tutorial

Proposed architecture. The arrows describe editorial and experimental processes, not an existing automated pipeline.

| Component                 | Function                                                                                       |
| ------------------------- | ---------------------------------------------------------------------------------------------- |
| 1. Literary passage       | The free-form prose, including observations, speculation, history and unresolved questions     |
| 2. Simulation proposition | A selected passage translated into actors, rules, conditions, interventions and open questions |
| 3. Text simulation        | One or several provisional accounts of what might happen when those rules operate              |
| 4. Godot experiment       | An executable interpretation that can produce observable behaviour                             |
| 5. Research record        | Screenshots, states, failures, observations, provenance and learning debt                      |
| 6. Revision and edition   | New versions of the passage, code or proposed experiment, retaining their predecessors         |

The six components need not correspond one-to-one. One paragraph can generate multiple simulations. One simulation can contradict several paragraphs. A failed experiment may remain an unresolved branch rather than joining the published text.

## 3. How text simulation actually works

Consider the sentence:

> A corner of the grid might lengthen into a sleeve.

It is not source code. It is a literary proposition with considerable ambiguity.

An AI system can begin by making its assumptions explicit. What is the grid made of? Which cells remain connected? Is the sleeve physically simulated, or does it merely follow the hand's position?

Then it can produce a provisional sequence:

Hypothetical text simulation

Not executed in Godot

STATE 0   Sixteen connected cubes form a fixed grid. ACTION    The visitor grasps one corner. STATE 1   The corner detaches from its fixed position. ACTION    The hand moves outward by 0.3 metres. STATE 2   Neighbouring cubes follow through their links. ACTION    The hand rotates. STATE 3   The structure twists around the wrist. QUESTION  Which connections must persist for it           to remain wearable?

This may lead to several candidate implementations. One uses rigid connected bodies. Another uses deformable constraints. A third treats the sleeve as a purely visual transformation.

These are different readings of the sentence.

The text simulation helps expose their differences before committing to a more expensive implementation. But an AI-written sequence is a hypothesis about possible behaviour, not evidence that a physical or computational simulation would behave that way.

Once one interpretation is built in Godot, its actual behaviour can be compared with the proposed sequence.

Perhaps it cannot twist. Perhaps it falls through the floor. Perhaps the constraints become unstable. Each result can generate new technical work and new writing.

This is the precise point where literary description becomes an experimental method.

## 4. The data architecture

I would retain each hall's existing `final.md`, `tutorial.md` and `map_data.json`, with Godot scenes remaining in their established locations.

Add a small experiment directory that references these sources instead of duplicating them.

For example, a proposed structure could be:

```

commons/maps/Random_Definition/
    final.md
    tutorial.md
    map_data.json

doc/book/experiments/
    random-definition/
        sleeve-001/
            proposition.md
            experiment.json
            text-simulation.md
            observations.md
            revision.md
            captures/

```

The companion `experiment.json` might contain:

```

{
  "id": "sleeve-001",
  "source": {
    "file": "commons/maps/Random_Definition/final.md",
    "passage_id": "grid-to-sleeve",
    "revision": "recorded_git_commit"
  },
  "proposition": "A grid corner becomes wearable",
  "status": "proposed",
  "interpretations": [
    "rigid_connections",
    "deformable_links"
  ],
  "simulation": {
    "text": "text-simulation.md",
    "godot_scene": null
  },
  "learning_debt": [
    "Connection stability under wrist rotation",
    "Collision and hand-following behaviour"
  ],
  "observations": [],
  "revision": "revision.md"
}

```

This is a proposed schema, not something I found already implemented.

The important design choice is that the passage keeps its literary form while acquiring an experimental history.

The prose should not be forced to become a software specification. Only a selected proposition is translated into testable conditions.

## 5. What the reader encounters

I imagine three ways of entering the same material.

Read

A coherent literary edition with chapters, images, arguments and encounters. It remains readable without installing Godot or inspecting implementation details.

Reconstruct

A tutorial showing how to build a selected mechanism with clearly identified prerequisites, working code and experimental comparisons.

Investigate

Access competing simulations, variations, unresolved questions, source material and previous versions. Readers can propose interpretations and contribute observations under an explicit review process.

These are different modes of engaging with the work, not necessarily three separate publications.

The readable book is a curated route through a much larger research graph. The experimental edition exposes some of that graph, and the playable museum makes selected relationships spatial and operational.

I would keep frozen, identifiable editions even though the underlying project continues to change. A published chapter should not silently change merely because an AI model or game script has been updated.

A new edition can include the consequences of those updates and show how it differs from an earlier one.

## 6. Authorship and learning debt become part of the structure

Each significant experiment can preserve not only its technical state but also its intellectual history.

Who proposed the sentence? Which AI model suggested the implementation? Which assumptions were supplied? What did the running experiment show? What remains uncertain? Which changes were accepted, rejected or left open?

This need not become an intrusive attribution attached to every sentence. It can be a research record accessible behind the reading.

Most importantly, learning debt becomes a navigable part of the book.

A passage might contain an unfamiliar algorithm, an incomplete interpretation or a proposal awaiting implementation. Its record can identify what is not yet understood and how it could be investigated.

Months later, an artist, reader or AI collaborator might return to that open question with different capabilities.

That produces a book whose intellectual development is not confined to the period in which its sentences were first composed.

## 7. The smallest experiment to build first

I would begin with the existing 4×4 seed bench rather than the full sleeve.

Keep the same 48 random values, but allow them to be interpreted in two different ways: as RGB colours and as cube heights.

The text proposes the comparison. A text simulation predicts its consequences. A Godot implementation tests the mapping. An observation identifies what changed and what stayed fixed. A revised paragraph can then describe the actual encounter.

This is small enough to verify technically, but substantial enough to demonstrate the entire recursive method.

The sleeve can follow as a more ambitious investigation of changing not just the interpretation of values but the possible relationships between objects.

## 8. A concrete formulation for the blog

### The architecture of a book that can simulate itself

The book is organized as a collection of passages connected to computational artifacts, programming tutorials, simulations and records of observation. Each hall in Ada Research has a literary text, a reconstructable technical lesson and an existing or proposed implementation in the virtual museum.

Selected passages can also become experimental propositions. A sentence describing an unfamiliar behaviour may be interpreted by AI as a set of possible rules, simulated in text, and subsequently reconstructed as an executable scene in Godot. The text simulation exposes assumptions and possible consequences; the running scene tests one particular interpretation.

What happens returns to the book. Observations, failures, screenshots, code revisions and unanswered questions are preserved alongside the passage that initiated the experiment. A new version of the text can emerge from these encounters without erasing its predecessors.

The book therefore has two temporal structures. As a published edition, it offers a particular route through the research, with a beginning, development and conclusion. As a computational research apparatus, it remains open to further interpretation and reconstruction. Different versions, unfinished experiments and competing explanations can continue to exist beyond the published sequence.

This also changes authorship. The people and AI systems participating in the work may contribute knowledge at different moments, sometimes before the initiating artist fully understands its implications. Rather than concealing this condition, the apparatus can preserve it as learning debt: a record of what has entered the work, what remains uncertain and what further investigation might make understandable.

The book is consequently not only an account of experiments performed elsewhere. Its sentences can initiate experiments, its existing claims can be tested against the world, and its future writing can be transformed by consequences no author had anticipated.

It is both a literary work and an instrument for producing knowledge that does not yet exist.

The key architectural principle is preserve the differences between proposition, simulation, execution, observation and interpretation while allowing each to transform the others.

If those distinctions disappear, the book risks becoming an automated generator of plausible stories about software. If they remain visible, the book can become a genuine experimental apparatus—one capable of remembering not only what was written, but how its writing changed what could be built.