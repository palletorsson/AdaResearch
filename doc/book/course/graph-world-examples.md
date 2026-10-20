# Graphs with something at stake

Eleven native 3D companion examples for the eight Graph Theory halls. They are selectable in **Graph worlds**, permanently installed in **GT_Flow**. Earlier halls retain their existing installations. Each comparison gives a graph operation a concrete setting without adding another required tutorial algorithm.

The learner still carries the point and reusable code. A different setting must declare what its vertices, edges and quantities mean. A message can be copied; allocated crates are conserved; a contact only offers a possibility of transmission. These are different contracts.

## Route

| Hall | Concrete example | Action |
|---|---|---|
| GT_Foundations | A visitor makes the rounds | Visit each room once; follow the queue. |
| GT_Layout | An ant trail, drawn twice | Rearrange the drawing; keep every trail. |
| GT_Pathfinding | The closed footbridge | Close one bridge; find the fewest-crossings detour. |
| GT_Network_Analysis | The post that gets copied | Omit one recorded share; recount incoming events. |
| GT_Connectivity | An island with no return boat | Add a return crossing; compare the mutually reachable islands. |
| GT_Spanning_Trees | Water pipes between homes | Select cheap connections; break one; add a spare. |
| GT_Flow | Room for another delivery | Allocate two deliveries; notice the cancelled commitment. |
| GT_Matching | Two makers, two tools | Revise the first pairing so both people can work. |
| GT_Network_Analysis | A contact is not an infection | Advance one contact round; new infections wait until the next round. |
| GT_Foundations | Seven bridges, four shores | Count odd degrees before attempting to use every bridge once. |
| GT_Connectivity | A neighbourhood after the relay fails | Lose a central link; switch on the spare connection. |

## The examples

### A visitor makes the rounds

**GT_Foundations · Present / invented museum**

**What is represented:** Rooms; passages between them. Figures mark visits, not extra vertices.

**What changes:** Advance the breadth-first queue one room at a time. Separate visiting vertices from using every passage.

**Teaching purpose:** Human movement gives reachability a purpose. A queue orders inspection; it is not a claim that a visitor walks the displayed tree in that order.

**Boundary:** Vertices are rooms; links are passages. Visiting a room is not walking each passage once.

### An ant trail, drawn twice

**GT_Layout · Present / simplified animal habitat**

**What is represented:** Trail junctions; trail connections. Ant forms identify the setting.

**What changes:** Switch from one drawing to a circular drawing. All six links remain.

**Teaching purpose:** Moving a drawn junction need not alter the habitat model. Real foraging would require additional behaviour and environmental assumptions.

**Boundary:** Vertices are junctions, not individual ants. No pheromone or foraging behaviour is simulated.

Contextual reading: [source](https://arxiv.org/abs/1103.1612). The geometry and datasets here are our own schematic examples.

### The closed footbridge

**GT_Pathfinding · Present / invented riverside town**

**What is represented:** Places in a fictional town; equally costly crossings.

**What changes:** Close1→3 in both directions; the route changes to the other branch.

**Teaching purpose:** Reuse BFS before adding travel time, slopes or access requirements. Fewest edges is the declared objective.

**Boundary:** Passages have equal cost. A shortest graph route need not be the fastest or most accessible walk.

### The post that gets copied

**GT_Network_Analysis · Present / invented social network**

**What is represented:** Accounts; recorded directed share events. Parallel events remain countable.

**What changes:** Omit one0→1 share. Incoming count at1 drops from2 to1.

**Teaching purpose:** The count changes because the included evidence changes. A share is not evidence of agreement, exposure or influence.

**Boundary:** Vertices are accounts. Arrows are recorded shares, not friendships, impressions, agreement or trust.

Contextual reading: [source](https://bsky.social/about/blog/7-27-2023-custom-feeds). The geometry and datasets here are our own schematic examples.

### An island with no return boat

**GT_Connectivity · Present / invented ferry service**

**What is represented:** Six islands; one-way service connections.

**What changes:** Add3→2 to the existing2→3 crossing. Two three-island return groups become one.

**Teaching purpose:** A way out and a way back are distinct. Timetable details would change what a usable journey means.

**Boundary:** A directed link is a scheduled service in this simplified model. Timetables and missed boats are omitted.

### Water pipes between homes

**GT_Spanning_Trees · Present / invented village plan**

**What is represented:** Seven homes; candidate undirected pipe links with assigned build costs.

**What changes:** Eight steps build cost21; ninth breaks0–1; tenth adds spare4–5 and restores reachability.

**Teaching purpose:** This applies the exact preceding tree model. The pipe analogy introduces a practical motive for a spare, while pressure remains outside the model.

**Boundary:** Weights are assigned construction costs. This is connectivity planning, not water pressure or hydraulic flow.

### Room for another delivery

**GT_Flow · Present / invented harbour plan**

**What is represented:** Stock, depots, yards, dock, destination; directed crate-slot capacities.

**What changes:** First allocation uses yard3. Second cancels1→3, reroutes the first through4, and reaches total2.

**Teaching purpose:** The tutorial focus is revision of an allocation. Buildings make the roles visible; flow remains a plan, not a physical shipment simulator.

**Boundary:** Capacities count crate slots in one interval. Reverse residual steps revise the plan before dispatch.

Contextual reading: [source](https://networkx.org/documentation/stable/reference/algorithms/generated/networkx.algorithms.flow.maximum_flow.html). The geometry and datasets here are our own schematic examples.

### Two makers, two tools

**GT_Matching · Present / invented shared workshop**

**What is represented:** Two makers and two tools; declared task-compatible pairings.

**What changes:** First maker takes the tool the second needs. Reassign the first to the other tool; both can work.

**Teaching purpose:** A concrete preview of Matching. This small declared case does not implement a general matching solver or an account of fair allocation.

**Boundary:** Links encode declared task compatibility. One tool per person; preferences, skill and fairness are not computed.

### A contact is not an infection

**GT_Network_Analysis · Present / fictional contact experiment**

**What is represented:** People; assumed potentially infectious contacts.

**What changes:** Advance synchronous seeded rounds. Newly infected people can transmit only in later rounds.

**Teaching purpose:** A contact graph alone does not spread disease. The explicitly additional probability and update rule produce a toy SI process.

**Boundary:** Toy SI process: probability0.35 per infectious-susceptible edge per round; no recovery, duration or biology. Not an epidemic forecast.

Contextual reading: [source](https://www.nature.com/articles/s41586-021-03694-x). The geometry and datasets here are our own schematic examples.

### Seven bridges, four shores

**GT_Foundations · Historical / topological reconstruction**

**What is represented:** Four shores; seven distinct bridges, including parallel pairs.

**What changes:** Reveal degrees5,3,3,3. Four odd-degree vertices rule out a walk using every bridge exactly once.

**Teaching purpose:** This historical problem asks about edges, unlike the opening vertex-visit lesson. The 3D town is a schematic setting, not old Königsberg reconstructed.

**Boundary:** The seven-edge multigraph follows Euler's bridge problem. This is not a geographical reconstruction or the hall's vertex-visit lesson.

Contextual reading: [source](https://eulerarchive.maa.org/). The geometry and datasets here are our own schematic examples.

### A neighbourhood after the relay fails

**GT_Connectivity · Future / invented scenario, not a forecast**

**What is represented:** Neighbourhood communication relays; permitted bidirectional connections.

**What changes:** Lose3–5, then add4–5. The source-to-destination route disappears and returns.

**Teaching purpose:** An invented future gives the existing reachability operation a new purpose. The model tests a particular failure; it does not predict social resilience.

**Boundary:** Links are permitted communication paths, not guaranteed power, bandwidth, safety or equitable access.

## Research and attribution

- [Ant foraging and minimal paths in simple graphs](https://arxiv.org/abs/1103.1612) studies a foraging model with reinforcement. It is context for the animal comparison, not evidence that our static ants implement that behaviour.
- [Thinking clearly about social aspects of infectious disease transmission](https://www.nature.com/articles/s41586-021-03694-x) helps distinguish contact structure and transmission assumptions. Our probability0.35 is arbitrary and uncalibrated.
- [Bluesky custom feeds](https://bsky.social/about/blog/7-27-2023-custom-feeds) offers a current-platform example of selection affecting what is shown. Our gallery counts fictional share records, not a real platform's reach or algorithm.
- [NetworkX maximum-flow documentation](https://networkx.org/documentation/stable/reference/algorithms/generated/networkx.algorithms.flow.maximum_flow.html) is a reference for the residual-network conventions. The learner implementation is GDScript with no NetworkX dependency.
- [The Euler Archive](https://eulerarchive.maa.org/) provides primary historical works. Our bridge graph preserves the usual four-vertex, seven-edge problem; the buildings are illustrative.

## How to revise this collection

Edit commons/artifacts/graph_worlds/cases.json for the title, declared era, action and boundary. These appear in the native gallery. Its graph_worlds.gd contains the separate small case operations and geometry. Cases share a display but do not share an invented universal social meaning. The editable guide is doc/book/course/graph-world-examples.md. Reports are generated by tools/publish_graph_flow.py.

Short instruction: Concrete setting per operation. Declare node/edge/quantity/action/omissions. Preserve carried code. Historical topology≠physical reconstruction. Fictional future≠forecast. Contact≠infection. Shares≠trust. Crates conserved, messages copied. One required learner object per principle; other contexts remain companions. Test the represented change.
