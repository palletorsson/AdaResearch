# Swarm — where coordination lives

One point returns in seven different relations. The order is retained. **Physarum is implemented and tested here; the other six paragraphs are plans for the next lessons.** Existing drafts remain available but are not certified by this review.

## 1. A trace outside the point

**Hall:** SwarmIntelligence_PhysarumColony  
**Encounter:** PhysarumColony  
**Learning elements:** Sense → turn → move → deposit; retain a fraction of the field.

In PhysarumColony, watch a trace remain after a point moves away. Carry the familiar PointBody into a six-agent study: sample left, ahead and right, turn toward a strictly stronger side, then move and deposit into an addressed field. Everyone reads the old field before its decay and the new deposits. Compare 92% and 55% retention from the same start; move one starting point and predict its first three samples. Test that a second point responds after the depositing point has left. Carry the body and field lookup into FlowFields; the record now lives outside the body.

## 2. Directions supplied

**Hall:** SwarmIntelligence_FlowFields  
**Encounter:** FlowFieldMain  
**Learning elements:** Read a vector at an address; desired velocity and bounded steering.

Meet the existing flow field with the same point and addressed space. Replace scalar trace strength with a direction vector at each cell; show the vector sampled by one point before releasing the small population. Reuse velocity integration and introduce desired minus current velocity as a bounded steering change. Edit one region, predict the first turn and test the zero-vector case. These points read the field without depositing into it. Keep obstacle pathfinding as context for the later graph search lessons. Carry bounded steering into a neighbourhood of moving points.

## 3. Neighbours become the field

**Hall:** SwarmIntelligence_Boids_Algorithm  
**Encounter:** boids_aquarium / film_boid_neighbour  
**Learning elements:** Neighbourhood → separation / alignment / cohesion → weighted steering.

Follow one point in the aquarium and make its chosen neighbours visible. Carry the steering calculation from FlowFields, but obtain desired motion from nearby bodies: first separation, then alignment, then cohesion. Read all positions and velocities from one snapshot, exclude the point itself, handle coincident positions and no neighbours, then commit next states together. Vary one weight and predict a local change before looking at the flock. Test that reversing iteration order does not change the result. Carry a distinction between an individual rule and a collective pattern.

## 4. The traveller changes state

**Hall:** SwarmIntelligence_Agent_Based_Modeling_ABM  
**Encounter:** ant_colony_optimization / stigmergy_grid  
**Learning elements:** State and event; replace agents versus clear their environment.

Return to a small foraging population in the existing colony display. Reuse sensing and movement; add an explicit outward/returning state whose destination event changes what a point does next. Keep one trace channel for this first state lesson. Predict the transition, replace the agents while retaining their field, then perform a full reset that clears both. Test those two operations separately. The lesson concerns accountable state and reset scope, not a generic simulation of society. Carry the returning flag and shared field into the two-channel colony.

## 5. Directions for the return

**Hall:** SwarmIntelligence_Ant_Colony_Optimization  
**Encounter:** AntColonyV2  
**Learning elements:** Two trace channels; read one, write the other; destination transition.

Watch outward and returning traffic in AntColonyV2. Keep the state transition from ABM and give the shared field separate home and food channels. An outward point reads food and leaves home information; a returning point reverses that relationship. Show one destination event and predict the next read and deposit before running many agents. Test that the other channel is untouched and that reset clears both. This is demonstrated foraging coordination; the hall title does not establish a shortest-tour guarantee. Carry the question of where useful information is stored into particle memory.

## 6. Remembered positions, chosen scores

**Hall:** SwarmIntelligence_Particle_Swarm_Optimization  
**Encounter:** fitness_landscape_politics  
**Learning elements:** Position + score; inertia / personal best / shared best; objective.

Keep the sphere and weighted motion, now as a candidate on the existing fitness landscape. Evaluate a small repeatable population before its first move, storing each best position beside its score and the objective that produced it. Add inertia, a pull toward personal best and a pull toward shared best in separate passes. Predict and test a one-step update; change the objective and re-evaluate or explicitly restart the remembered records. Treat the novelty archive as a later comparison, not part of the first formula. Carry an account of what the system calls improvement, without promising a global optimum.

## 7. What keeps a population going

**Hall:** SwarmIntelligence_Swarm_Intelligence_Algorithms  
**Encounter:** ecosystem_simulation  
**Learning elements:** Birth / loss / supplied replenishment; event accounting and limits.

Observe an apparent recovery in the ecosystem display. Reuse agent states and event arrays to keep births, losses and supplied replenishment separate. Reconstruct the population count from a short declared event stream before interpreting a moving crowd; predict what one missing support event would change. Bind that stream to the actual exhibit before claiming a live explanation. This closing lesson composes earlier tools rather than surveying more algorithms. Carry into Graph Theory the question of which relations are recorded and which conditions keep them possible; Machine Learning follows the graph sequence.

## Keep the divisions useful

ABM introduces an individual state and reset scope; Ant adds a second trace channel. Boids divides its three forces into successive passes. PSO begins with a fixed objective before discussing a changing novelty archive. Ecology closes with a small event account. These boundaries prevent every hall from becoming another complete swarm framework.

The seven paragraphs are editable in `doc/book/course/execution-plan/plan.json` and visible through the tutorial-plan interface. The sequence does not need reordering to make this progression. Artifact membership does not imply that every exhibit must be taught.
