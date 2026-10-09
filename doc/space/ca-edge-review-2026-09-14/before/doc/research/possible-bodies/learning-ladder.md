# What can the next body do?

A pedagogical ladder for Ada Research, proposed from the existing collection on 13 September 2026. This is a plan for development and reading, not an applied route change. No artifacts are removed.

The red thread can be a sequence of capabilities the visitor can use again: locate, relate, repeat, transform, accumulate, sample, couple, update, construct, test. Each addition should answer a question the previous tools left open. It also opens a new limit to investigate. We should judge a rung by what a learner can predict, make or question afterwards, rather than by how spectacular its object looks.

The ladder has returns. A familiar rule can reappear as a wall, a garment, a path or an agent. Those are different applications and sometimes different mechanisms. The relation must be shown. A more complicated or organic body is not automatically more alive, more queer or more valuable.

## Six questions for every hall

1. What can the visitor already do, and which earlier encounter made that possible?
2. What specific relation or operation becomes available here?
3. What can the visitor predict, try and observe before we explain it?
4. Which actual state, code and physical behaviour explain the result?
5. What assumption can now be pressed, misused or made strange—and what happens when it fails?
6. What can the visitor carry into a different material or the next hall?

For each experiment, name what stays fixed and what changes. One central addition is a pacing preference, not a law: the structure-growth hall adds both a 3D neighbourhood and a third state, so let the visitor investigate those in two passes. One central question is also not a one-artifact quota. Keep works that demonstrate a consequence, a useful comparison or a different use of the capability. A teacher's direct route can coexist with a student's longer detours.

For implementation tracking, record: inherited capability; addition; primary encounter and supporting works; visitor action; observation; code source; critical opening; transfer question; current readiness; next concrete improvement. A sketch, working source, desktop test and headset encounter are different evidence levels. Track whether the carrier is an object, the surrounding world, the player or another agent.

## The important bridge: randomness → noise → cellular automata

Randomness asks which possibilities a process can draw, with which distribution, in which order, and with what consequences. A seed and generator state support a controlled return. A random walk already retains position and accumulated consequences. The Shannon meter shows why a frequency measure cannot by itself tell us where values stand next to one another.

The basic noise-field studies ask how values at addresses are related and what happens when a value becomes colour, displacement, occupancy or terrain. Noise does not guarantee walkability or concealment: frequency, amplitude, resolution, threshold and the player's movement capabilities matter. Nor is every use of noise memoryless; a sampled field can be coupled to stored state and feedback.

Cellular automata gives us a particular organisation of state and update: sites consult specified neighbourhoods and repeatedly produce new site states. Memory and feedback have appeared earlier in walks and forces. The new lesson is how they are distributed and coupled across this substrate. The sequence also contains hybrids, such as a continuously valued proximity-sensitive bridge; name what they actually implement.

Keep a matched opening comparison available: use recorded seeds, the same lattice and the same value-to-colour/height mapping to compare independent samples with a correlated field. Then freeze one of those fields as the starting state for local evolution. Changing the generator and changing the update mechanism are separate experiments. This is a proposed comparison bench, not an existing three-mode artifact. Make sampling and update timing visible; redrawing one display every frame would introduce another difference into the spatial comparison.

The organic noise filter can be beautiful and can signify a queer body. Its ease can also narrow the forms we think to ask for. The next capability should reopen the inquiry: what would require persistence, exchange, a new state, an interpreter, a constraint or a different purpose?

## Recommended Cellular Automata walk

I recommend moving the Rule 30 history bridge and the binary Life dish ahead of the 3D three-state builder. This is a pacing choice, not a mathematical necessity or a judgement against the builder we just made. Keep that completed work. The intended progression is row → history → plane → volume and lingering state → embodied feedback → richer coupling → controlled disturbance → comparison with recursive construction.

The current seven-hall museum order remains unchanged. CA_AgentsCircuits is present in the eight-map curriculum but absent from the active route. Its two retained works make a promising exit towards fractals. Restoring it at the end, along with the other proposed moves, requires updating the route, adjacent book passages and review navigation together.

Use accurate encounter titles while retaining stable map IDs. In particular, CA_GameOfLife's current primary is a Rule 30 bridge, CA_BeyondBinary's current primary is binary Conway Life, and CA_AgentsCircuits currently contains a row explorer and a recursive pyramid. Titles must not be used as evidence of mechanics that have not been built.


### 1. A neighbourhood makes the next row — CA_Introduction

**Bring:** Arrays, binary state, clocks and repeatable beginnings.

**Add:** One local rule reads an ordered neighbourhood; answers go into a separate next-state buffer.

**Existing material:** Begin with ca_rule_explorer. The rug and line network remain as further encounters with other mechanisms.

**Discover:** Predict one marked cell, STEP, then change the seed while keeping the rule. Inspect the wrapped edge.

**Critical opening:** Which distinctions survive the neighbourhood? A count loses information that ordered left/self/right bits can preserve.

**Carry forward:** Explain a new three-bit case and show why writing into the old row could change later answers.

**Readiness:** Source prepared; Introduction engine review pending.

**Next action:** Complete the prepared Introduction engine review. Treat the rug and network as returns after the row, so the first explanation does not have to teach three mechanisms at once.

Sources: `commons/artifacts/ca_rule_explorer/ca_rule_explorer.gd`, `commons/maps/CA_Introduction/final.md`.


### 2. Give the past a direction — CA_GameOfLife

**Bring:** The one-dimensional row and its local rule.

**Add:** Retain generations and map their order onto depth. Drawing history is distinct from adding spatial neighbours.

**Existing material:** ca_bridge with study:history: a desk, support tiles and ornamental lattice share one record. The four other works remain in the rear gallery.

**Discover:** Read the same Rule 30 generation on a flat record and on the bridge. Predict the next row before following the structure.

**Critical opening:** A visible neighbour may be an earlier moment. A drawn cube also needs collision before it can carry a body.

**Carry forward:** Identify which axis is time and which values belong to the same current state.

**Readiness:** Implemented: one 15-site, 24-row Rule 30 history, six controls, three mappings and full-size retained lab; real desktop checks and museum captures at ca-history-bridge.html.

**Next action:** The shared history and the following Life-dish application are implemented. Review these in a headset later; continue through the completed exchange study to CA_EdgeOfChaos.

Sources: `algorithms/cellularautomata/ca_bridge/ca_bridge.gd`, `commons/maps/CA_GameOfLife/final.md`.


### 3. A pattern travels; its cells stay — CA_BeyondBinary

**Bring:** A row, an update schedule and the distinction between state and its displayed history.

**Add:** A two-dimensional present with eight neighbours; collective patterns persist or travel through fixed addresses.

**Existing material:** game_of_life_petri with study:addresses: one present in a dish and floor, three fixed cell addresses driving three lamps. All five other works remain.

**Discover:** STEP a clean glider; follow A and the travelling figure separately. Compare BLINKER and MEET. Disconnect LINK while continuing the automaton.

**Critical opening:** What is the travelling body if none of its cell addresses travels with it? The state remains binary despite the room ID.

**Carry forward:** Distinguish an oscillator, a travelling pattern and a displaced drawing; predict a local B3/S23 update.

**Readiness:** 30 Godot desktop checks passed; fixed-address lamps, clean comparisons and revised final. All six works retained. Photographs and remote model at ca-life-addresses.html.

**Next action:** Primary implemented and desktop reviewed. Headset and retained secondary encounters remain. CA_ExpandingSpace is now desktop reviewed; the live field is now reviewed; continue to CA_EdgeOfChaos.

Sources: `commons/artifacts/game_of_life_petri/game_of_life_petri.gd`, `commons/maps/CA_BeyondBinary/final.md`.


### 4. A cell takes time to disappear — CA_ElementaryRules

**Bring:** A stored state, a neighbourhood and a recognisable pattern.

**Add:** A three-dimensional neighbourhood and a refractory state. These are two additions, so demonstrate them in two passes.

**Existing material:** The retained structure_growth study and its state/height finish comparison.

**Discover:** First locate face, edge and corner neighbours around one address. Then follow 1 → 2 → 0 and compare a fading cell with an empty cell under the same active-neighbour count.

**Critical opening:** Presence, participation and visibility differ. Changing the finish can conceal distinctions without changing the state.

**Carry forward:** Explain why an empty cell with seven active neighbours can be born while a fading cell must first become empty.

**Readiness:** 21 desktop checks and real screenshots; full-volume performance and headset review pending.

**Next action:** Keep the completed study. Add a neighbourhood witness or slice if depth cannot be read; optimise its measured 144 ms full-volume update before headset acceptance.

Sources: `algorithms/cellularautomata/cellular_automata_3d/CellularAutomata3D_Flexible.gd`, `algorithms/cellularautomata/cellular_automata_3d/structure_study.gd`, `commons/maps/CA_ElementaryRules/final.md`.


### 5. The visitor enters the update — CA_ExpandingSpace

**Bring:** Persistence, disappearance, fields, thresholds and the player body from earlier chapters.

**Add:** A surface stores graded health; proximity affects it and a threshold changes collision. The observer becomes an input to the system.

**Existing material:** decaying_bridge, with the existing tree, crossway and chair retained as further architectural constructions.

**Discover:** Approach from a safe rim, wait, withdraw. Compare health, appearance and actual support. Hold distance while varying observation time.

**Critical opening:** The bridge responds to a tracked body origin, not measured weight. SYNC and SCAN expose whether a newly recovered neighbour is available during this pass or the next.

**Carry forward:** Tell whether a change came from proximity, elapsed time, neighbours or the collision threshold.

**Readiness:** 36 real Godot checks, including tracked-body falling and ramp recovery. Witness, matched schedule comparison and shared health frieze built; photographs and remote model at ca-proximity.html.

**Next action:** Primary implemented: revisit in a headset later and review the retained gallery. The live field in CA_SoftRules is now desktop reviewed; continue to CA_EdgeOfChaos.

Sources: `algorithms/cellularautomata/living_architecture/decaying_bridge.gd`, `commons/maps/CA_ExpandingSpace/final.md`.


### 6. What can one cell exchange? — CA_SoftRules

**Bring:** Graded health, synchronous arrays and display mappings.

**Add:** Two concentrations and a five-point exchange term; local reaction, feed and removal continue when exchange is disabled.

**Existing material:** rd_artifact: a held matched Gray–Scott study with table fields and curved wall coatings. The clockmaker remains a second primary diagram; all six authored works now load.

**Discover:** Follow W outside the seed: STEP with B exchange OFF, then toggle it ON and compare matching beginnings. Change VIEW and COAT without advancing the state.

**Critical opening:** Fractional values still occupy a finite periodic lattice; an 8-bit colour mapping can hide their differences. A static fractional ring is not a running Lenia field.

**Carry forward:** Distinguish neighbourhood exchange, local reaction, an intervention and the projection of a field onto architecture.

**Readiness:** 37 Godot checks: first-step arithmetic, legacy-solver agreement, full-field equality, GPU texture mapping, eight real controls and physical walking. Photographs, remote model and two book passages at ca-soft-rules.html.

**Next action:** Primary study implemented and desktop reviewed. Next inspect CA_EdgeOfChaos for a matched intervention comparison; headset and retained-secondary reviews remain.

Sources: `commons/artifacts/rd_artifact/live_field.gd`, `commons/artifacts/rd_artifact/exchange_study.gd`, `commons/maps/CA_SoftRules/final.md`.


### 7. Does a difference spread? — CA_EdgeOfChaos

**Bring:** Neighbour coupling, chance, replay and the distinction between an observation and a claim.

**Add:** An experiment on sensitivity: compare matched runs, change one cell, measure the difference over a stated duration.

**Existing material:** self_organization_ca; retain the screen, disease, crack and fog works as differently specified systems.

**Discover:** Use the same starting state and random stream in two runs. Perturb one cell in one run. Display changed-cell count and where the difference reaches.

**Critical opening:** The current lambda control couples neighbour influence and disturbance. Integer states 0–9 are not a continuous field. A label saying critical does not establish a critical regime.

**Carry forward:** Distinguish a stationary pattern, an observation-budget stop, a repeating cycle and a growing difference; state which measure supports the claim.

**Readiness:** Mechanism and limitations described in source/text; matched-run experiment proposed.

**Next action:** Add paired seeded runs and a difference view; separate coupling from disturbance. Preserve odd outcomes rather than searching only for a picturesque middle setting.

Sources: `algorithms/cellularautomata/ca_showcase/self_organization_ca.gd`, `commons/maps/CA_EdgeOfChaos/final.md`.


### 8. The same resemblance, another construction — CA_AgentsCircuits

**Bring:** Repeated local updates, visible history and controlled comparison.

**Add:** Compare local evolution with explicit recursive copying; establish the hinge into the fractals chapter.

**Existing material:** The existing ca_rule_explorer and sierpinski_pyramid. Keep the historical ID while giving the encounter an accurate public title.

**Discover:** Name one relation among gaps in Rule 90 history, then test that relation in the recursive pyramid. Change the row seed and see which resemblance survives.

**Critical opening:** Related silhouettes need not share a procedure. The pyramid and the flat history need not match in every relation; neither proves a circuit or computational universality.

**Carry forward:** Explain one construction using neighbour updates and the other using smaller copies and a stopping condition.

**Readiness:** Two existing placements; absent from active route. Restoration proposed, not applied.

**Next action:** Review and restore this omitted map at the CA exit when its spatial and textual links are ready. It currently exists in the curriculum but not in the seven-hall active museum route.

Sources: `commons/maps/CA_AgentsCircuits/map_data.json`, `commons/maps/CA_AgentsCircuits/final.md`.


## Randomness: a ladder within the current order

| Hall | Capability | Test before explanation |
|---|---|---|
| Random_Definition — A draw has a beginning | Seed and draw order | Repeat the same beginning; discard one draw and inspect which neighbours change. |
| Random_Entropy — A measure keeps only some differences | Frequency versus arrangement | Sort the same multiset: identify what the entropy reading retains and what spatial relations it loses. |
| Random_Remove — Chance acts inside a permitted set | Selection without replacement / eligibility | Name a cube outside the selectable set; inspect how the set changes after removal. |
| Random_Walk — A choice accumulates into a path | Position, increment and displayed trail | Distinguish the state used by the next step from the longer trail shown to the visitor. |
| Random_Gaussian — Sampling makes a distribution visible | Distribution and histogram bins | Keep the samples and change the bins before attributing a changed picture to a changed generator. |
| Random_Mushrooms — A distribution becomes a body | Mapping draws to constrained parameters | Ask which stem/cap combinations the recipe cannot produce; vary one mapping, not only the seed. |
| Random_Game — Chance changes what an action affords | Timing, support and consequence | Predict a crossing from known timing, then identify which sampled wait changed the outcome. |


## Noise: a ladder within the current order

| Hall | Capability | Test before explanation |
|---|---|---|
| Random_Noise_Types — Which changes remain possible? | Address, domain and relation among samples | Follow point constraints into independent versus related samples. Give nearby addresses comparable spacing. |
| Noise_Columns — Where does change enter the body? | Coordinate, time and displacement | Compare the columns without assuming every moving surface uses the same process. |
| Noise_One — A value can become different attributes | Sample versus mapping to colour or form | Give the same values two outputs; locate what changed in the mapping. |
| Noise_Voxel — A value becomes occupied space | Threshold and classification | Keep field and seed fixed; change the threshold and inspect a named empty as well as occupied address. |
| Noise_6_Wall — A composed field dresses a room | Layering and a shared spatial application | Trace which part of the sum reaches walls and objects; keep floor support separate from its appearance. |
| Noise_Inside_Noise — Where is the field being read? | Local/world coordinates and enclosure | Stand inside the sphere and compare an attached address with an address shared with the surrounding space. |
| Noise_Space_10 — The field carries a body | Sampling scale, relief and traversal | Keep player and route fixed; compare effort, access and concealment across different terrain settings. |
| Noise_Perlin_Simplex — What makes a comparison fair? | Matched samples and the limits of the organic filter | Match coordinates and mapping before naming a difference; ask which desired behaviour requires more than a sampled field. |


## Before these chapters: what the visitor brings

| Sequence | Capability to carry | A question that can return later |
|---|---|---|
| Primitives | Address, relation, sample and bounded representation | What did the line or surface omit? |
| Transformation | Change position, orientation or scale relative to a frame | What was preserved, and what became traversable? |
| Arrays | Store and address many elements | Is an address the same thing as a body's identity? |
| Colour | Map a value to an appearance and compare context | What can a finish reveal or conceal? |
| Patterns and shaders | Repeat/compose rules and map them onto surfaces | Did the pattern change the body, its appearance or both? |
| Change | Rates and accumulation over a chosen interval | What does the current value retain of its past? |
| Vectors and forces | Couple changes in motion to specified influences | Which relationships cause motion, and which merely prescribe it? |
| Form finding | Let constraints and an objective shape a configuration | Downhill according to what quantity, and towards which possible resting state? |
| Wavefunctions | Period, phase and superposition | Can a small phase difference reorganise a shared rhythm? |

These are proposed transfer questions, not a claim that every current hall has already passed a learner assessment. They make later encounters refer back to specific tools rather than repeatedly starting a new vocabulary.

## Beyond CA: keep distinguishing construction from resemblance

**Fractals:** compare the locally evolved pattern with explicit recursive subdivision. Existing recursion, tree and Cantor works give material for a rule, its smaller inputs and a stopping condition. Self-similar appearance does not establish a shared generating process. Finite rendered detail is not an actual infinite object.

**L-systems:** distinguish a generated sentence from its interpretation. LSystems_Grammar_Lab already asks whether ANGLE can change the drawing while GEN stays fixed. A later interpreter can make an instruction place a wall, turn a body or leave a sound. A different interpretation may require new code; do not promise controls that the current editor lacks.

**Procedural generation:** combine the earlier operations with constraints, targets or selection. Its current texts include a scored candidate, local growth, percolation, a carving walk and a captured pile. Ask what a score can recognise and preserve a visitor's reason for keeping a rejected form. A useful bridge here is that the old random walk can now make a route by removing material.

**Soft bodies, isosurfaces and Boolean surfaces:** carry state and constraints into deforming bodies; convert fields into surfaces; then inspect what union, subtraction and intersection preserve or remove. A surface threshold revisits Noise_Voxel with new geometric machinery. Rendering, collision and physical support must remain separately inspectable.

**Swarms and learning:** distribute decisions among moving agents, then ask how adjustment or selection changes behaviour according to a specified objective. Do not make all learning into gradient descent. The earlier descent landscape gives one recurring test: downhill in which space, measured by which objective, accessible to which body?

**Graphs, foundations and QFEP:** return to the representation, assumptions and measures that made each earlier experiment possible. Ask which relations the model could express, which differences its measure discarded and what must change to investigate a remainder. This is a research connection to be developed, not evidence that one display has proved a universal critical threshold.

## Make the ladder manageable

Start with one complete transfer: the row explorer → the history bridge → the Life dish. Keep an address marker, replay/step convention and compact source/readout consistent across them. Reuse these controls where they match the real mechanism; do not force every machine into a synchronous update contract.

The CA_GameOfLife transfer is implemented: one history appears on the desk, in support tiles and in an ornamental lattice, with real desktop evidence and revised book text at ca-history-bridge.html. The next concrete hall job is CA_BeyondBinary: review the Life dish, mark a fixed address and consider an explicit event that lets a travelling pattern affect another museum object.

Then review the Life dish; keep the working structure-growth study; give its two additions separate attention. Soft Rules needs its missing live experiment. Edge of Chaos needs a matched perturbation comparison rather than stronger claims about its current picture. Review the dormant two-work comparison and restore it as a hinge to fractals when ready.

A rung is useful when someone can make a prediction, locate why it was wrong, and transfer the relation to another material. A wrong prediction is material for the next explanation. The critical opening belongs in that encounter, rather than being an essay attached after the lesson has ended.

## Inspection limits

This proposal follows current active orders and placements, primary-role data, existing final.md texts and the named code sources. Source inspection found that the clockmaker's Lenia patch is a radial static drawing and its read/write trays are illustrative; rd_artifact requires config_path and produces a batch-generated mesh rather than an exposed live field. The current bare placement supplies no such config. The decaying bridge stores float health and updates it in place, with proximity input and a collision threshold. These are concrete preparation tasks, not recommendations to remove the objects.

The randomness/noise tables build on their existing book passages and earlier reviews; they are not new comprehensive runtime audits of all those rooms. Later chapter links are conceptual recommendations grounded in their existing passages where named. No route, map placement, artifact role or book passage is changed by this proposal.
