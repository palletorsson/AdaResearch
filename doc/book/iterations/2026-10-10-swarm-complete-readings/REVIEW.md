# Swarm — where coordination lives

The seven-hall sequence holds. Each lesson changes the information available to a recognisable point: trace, supplied direction, neighbours, internal state, two traces, scored memory, then a population account. It builds capacity by returning to earlier tools for a different purpose. It does not need another algorithm to fill a gap.

The strongest continuous passage is ABM → Ant Colony: the carry flag changes which field is read and written. The largest changes are Boids → ABM and PSO → Population Support. These are deliberate changes of model. The revised handoffs now say what is kept and what is set aside.

## Response to the external reading

The latest [feedback response](feedback.html) adds seven short passages across five tutorials: the changing model behind PointBody, concrete returns to the first four exhibits, the population-level change of question, and an optional investigation with the existing Particle Swarm model. All seven reflections and every printed code block remain unchanged in that pass. The checks below were rerun against these current texts. Room-integration issues remain open.

## Existing artifacts or new ones?

Both. The first four halls retain their existing exhibits and add smaller teaching reconstructions. Ant Colony and PSO introduce new permanent tutorial artifacts. Population Support adds a new display and account around the existing ecosystem algorithm, which remains unchanged. The exact status is stated on every hall card below.

The same PointBody file is reused throughout; that does not mean that every original artifact’s simulation code is reused. The 265 fresh checks execute the printed reconstructions. They are not a claim that every existing exhibit was reconstructed by the student or retested in this pass.

## Earlier handoff corrections

Six short prose corrections: the opening now returns to the actual Soft Bodies ending; Boids no longer implies that its neighbour selector runs in ABM; Ant Colony explicitly gives way to scored memories; both PSO texts point to the population account; the closing release description respects paused playback. Three editable plan handoffs are updated. Printed GDScript, museum geometry, algorithms, plan decisions and baseline records are unchanged.

## What the student brings

This sequence follows the earlier museum work. PointBody, pickup, local coordinates, vectors, velocity integration, arrays, loops, conditions, state, signals and seeded comparisons are available tools. The old/next update distinction returns from Cellular Automata. Keep the prepared museum and named XRTools/button dependencies; these files do not form an empty-project starter.

## Seven lesson summaries

### 1. Physarum — A trace outside the body

Start beside the existing colony. Bring the familiar point and addressed grid; add a scalar trace that survives the body that deposited it. Predict the three sensor readings, move a point and leave a mark, then compare retention from the same start. The tutorial makes read, fade and deposit executable. The reflection asks how an abandoned route remains available. Carry the body and field lookup onward; the next field will contain directions supplied from outside.

**Artifact and code:** Existing Physarum colony retained. New small teaching model: trail.gd; it omits the exhibit’s diffusion and anchors.

![Physarum: existing native museum capture](review/assets/1-encounter.png)

*Temporary learner study beside the existing exhibit. Photograph from the recorded hall run; no new room render in this review.*

### 2. Flow Fields — A direction supplied to the body

Keep the point and grid address, replace the scalar trail with a vector, and use the velocity integration learned in Forces. Desired minus current velocity gives a bounded correction. Change one cell and let two points read it; their passage must leave it unchanged. Reverse the patch and predict the first turn. The reflection distinguishes received organisation from collective agreement. Carry steering onward; neighbours will provide its input next.

**Artifact and code:** Existing FlowFieldMain retained. New small teaching model: field.gd; prepared direction patches replace the exhibit’s route-building scenarios.

![Flow Fields: existing native museum capture](review/assets/2-encounter.png)

*Temporary learner study beside the existing exhibit. Photograph from the recorded hall run; no new room render in this review.*

### 3. Boids — Nearby bodies as a reference

Keep bounded steering but remove the direction grid. Select neighbours, exclude self, and calculate separation, alignment and cohesion from one shared snapshot. Move a point across a radius, then halve one weight and predict the next velocity. The reflection follows conflicting requests and different boundaries, including the flock beyond the museum walls. Keep these tools available; the next study retains the body and update discipline while setting the flocking requests aside.

**Artifact and code:** Existing open flock, aquarium and controls retained. New small teaching model: flock.gd; its shared snapshot, bounds and formulas are declared choices.

![Boids: existing native museum capture](review/assets/3-encounter.png)

*Temporary learner study beside the existing exhibit. Photograph from the recorded hall run; no new room render in this review.*

### 4. Agent-Based Modeling — A state carried by the body

Return to Physarum’s shared trace with the same point class. Add one Boolean: searching or carrying food. Contact changes which information the point uses, and a carried green cube makes that state visible. Compare replacing the agents with clearing their environment; test a slower return from a stated starting state. The reflection stays with inherited traces and the difference between a response and an intention. The navigator companion is optional. Carry the state and trace into two-channel coordination.

**Artifact and code:** Existing colony retained. New small teaching model: foragers.gd; finite food and recruitment are omitted to isolate state transitions.

![Agent-Based Modeling: existing native museum capture](review/assets/4-encounter.png)

*Temporary learner study beside the existing exhibit. Photograph from the recorded hall run; no new room render in this review.*

### 5. Ant Colony — Two channels in the ground

Walk among the enlarged points. Keep the carry flag and three sensors; split the ground into home and food fields. A searcher reads food and writes home; a returner does the reverse. Replace bodies while preserving their marks, and independently halve a deposit. The tutorial exposes indirect coordination; the reflection asks what a traveller inherits and which visitor actions the field ignores. No shortest-route result is claimed. Next, replace the trails with scored memories while keeping PointBody.

**Artifact and code:** New permanent ant_colony_walk artifact replaces the AntColonyV2 placement here. Its colony.gd is a teaching model; the original artifact source is preserved.

![Ant Colony: existing native museum capture](review/assets/5-encounter.png)

*Permanent full-size tutorial installation. Photograph from the recorded hall run; no new room render in this review.*

### 6. Particle Swarm — A position remembered for its score

Keep the sphere, position, velocity and weighted vector operations. Replace colony state with personal and shared best-position records. Score the starting population before moving, then change the objective while keeping current bodies and resetting their memories. Remove the social pull and predict the changed displacement. The reflection asks what “best” permits and excludes. Keep record inspection for the final hall; that hall supplies another model rather than extending this optimizer.

**Artifact and code:** New permanent particle_swarm_walk tutorial artifact. Existing fitness and self-organization displays remain as comparisons. swarm.gd is new teaching code.

![Particle Swarm: existing native museum capture](review/assets/6-encounter.png)

*Permanent full-size tutorial installation. Photograph from the recorded hall run; no new room render in this review.*

### 7. Population Support — An account of what sustains the population

Enter the supplied ecosystem with the same PointBody representation. The new work is a short account: initial population plus births, minus losses, plus supplied bodies. Store copied events and reconcile the result with the visible population. Omit supply from the calculation and predict the gap while the gold-ringed bodies remain. The reflection makes support visible without treating dependence as failure. This is the sequence’s accounting capstone; the distinction between kinds of relation carries into Graph Theory.

**Artifact and code:** New population_account_walk display and observer around the existing ecosystem.gd simulation. The ecosystem algorithm is reused unchanged; account.gd is the new learning operation.

![Population Support: existing native museum capture](review/assets/7-encounter.png)

*Permanent full-size tutorial installation. Photograph from the recorded hall run; no new room render in this review.*

## Density and remaining work

The short models range from 28 to 112 lines; their complete hosts add 125–210 lines. Focus comes from separating the new operation from the carried body and supplied display. A learner should first predict one change in the model, then use the complete host to inspect it. Passing the checks does not establish that those explanations are easy for a first-time reader.

The final hall is an accounting capstone. Reconstructing its entire ecosystem would introduce feeding, reproduction and support at once and overload the lesson. Keep that source explicitly supplied, with the observer and its limits available to inspect. Likewise, keep the ABM navigator as a separate optional study.

Spatial consistency remains uneven. The first four learner reconstructions are small comparison studies beside existing exhibits; the last three run as permanent full-size installations. Boids has its separate full-size flock and observation balcony. Making all four earlier lesson hosts permanent is a further implementation task, not something this review claims to have done.

The reflections hold a distinct line: what persists, who supplies direction, who counts as near, what a state can explain, what is inherited, who defines better, and what support makes continuation possible. They need no extra code. The tutorial tests make the corresponding operations inspectable; they cannot settle the reflective questions for the reader.

## Fresh verification

All seven printed tutorials were reconstructed and executed in Godot 4.6 in spine order: **265 checks passed**. Every hall includes an independent code variation and three deliberately faulty versions that the checks detect: 7 variations and 21 faulty versions. PointBody is byte-identical across the seven lessons. Prose changes leave every printed GDScript block unchanged.

This is an author-operated reconstruction, not a second independent AI or a physical headset session. The runs test numerical predictions, model invariants and synthetic XR interactions. Existing native room photographs and room-test reports are retained as earlier evidence; this run did not traverse every portal or recapture the museum. Existing UID/Jolt warnings remain; no script or parse errors occurred in these seven runs.

The next useful review is to give an independent reader the complete tutorial and reflection, ask them to make each stated variation, and record the first assumption they cannot reconstruct. Physical headset comfort, reach and readability need a separate player pass. Keep the order provisional while those observations arrive.

## Short instruction for the next reader

Museum supplied. PointBody unchanged. Read→predict→run→vary. Trace→direction→neighbours→state→two trails→scored memory→population account. Name kept/replaced/supplied/new. No universal agent accumulating all behaviours. Tutorial executable; reflection encounter-led. 265 author-run checks; 7 variations; 21 detected faults. Native photos are earlier evidence. Headset + independent-reader review open. Graph Theory follows, then ML.

## Transfer checks by hall

| Hall | New operation | Independent change | Fresh checks |
| --- | --- | --- | --- |
| 1. Physarum | A trace outside the body | Move one starting position; predict its three sampled cells. | 33 |
| 2. Flow Fields | A direction supplied to the body | Reverse the direction patch; predict the sign of the first turn. | 35 |
| 3. Boids | Nearby bodies as a reference | Halve alignment’s weight; predict velocity (0.95, 0.1). | 40 |
| 4. Agent-Based Modeling | A state carried by the body | Halve return speed; predict position (7.9925, 8). | 42 |
| 5. Ant Colony | Two channels in the ground | Halve deposit; distinguish 0.25 directly from 0.249375 on a tick. | 42 |
| 6. Particle Swarm | A position remembered for its score | Remove social pull; predict (0.185, 0.1) in the stated fixture. | 39 |
| 7. Population Support | An account of what sustains the population | Omit supplied bodies; predict gap 5 in the account fixture. | 34 |
