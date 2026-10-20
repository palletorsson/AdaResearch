# Swarms in nature games and art

The sphere point can become a fish, a drone or a pursuer while remaining recognisable. That gives the Swarm chapter a wider world to speak with. The useful question is **what each body can notice, what changes its movement, and what keeps the group present**.

This is a proposal beside the tested seven-hall sequence. Hall order, tutorial subjects, reflective texts and museum code are unchanged. The images show existing museum encounters; the extensions described below have not been built.

## What The Nature of Code gives us

Shiffman develops autonomous agents from the earlier moving body: limited perception, a desired velocity, a bounded steering response, then combined behaviours. Flow fields, path following and flocking provide different inputs to movement. Later, spatial subdivision addresses the cost of neighbour searches. This supports Ada's returning PointBody. [The Nature of Code, Autonomous Agents](https://natureofcode.com/autonomous-agents/)

Our sequence already teaches field lookup, bounded steering, neighbourhood selection, combined requests and explicit state. The most useful possible addition is a small **seek → flee → arrive** comparison using the carried point and one hand-held target. It would make chasing, escaping and stopping legible before their use in a larger encounter. Keep it optional until the code, explanation and tests are ready. Route construction remains in Graph Theory; the swarm can follow a route without teaching BFS again.

## Different kinds of swarm

| Example | What we can examine in Ada | Best existing hall | Important distinction |
| --- | --- | --- | --- |
| Fish school | Neighbour distance, competing steering requests, boundaries | Boids | A convincing school is not a verified biological explanation. |
| Drone group | Local avoidance, assigned destinations, sensing and communication | Flow Fields, Boids, ABM | Coordinated appearance does not identify whether control is local or centrally planned. |
| Zombie horde | Pursuit, hearing, state changes, blocked routes, crowd pressure | ABM, returning to Flow Fields | Individual behaviour, navigation and encounter scheduling are separate systems. |
| Swarm made of light | Make a local request visible as brightness or movement | Boids | Light can display a relation without depicting an animal. |
| Persistent insect world | Shared marks, foraging and external maintenance | Physarum, Ant Colony, Population Support | A sustained population need not be self-sustaining. |
| Conceptual swarm | Documents or images gather under a declared relation | PSO as comparison; Graph Theory atlas as destination | Spatial nearness is a designed representation, not proof of agreement or meaning. |

### Fish

Boids is the direct entry: the aquarium and open flock already let us compare three requests and several boundaries. Actual fish complicate the neat formula. Katz and colleagues inferred interactions from golden shiners and found important speed regulation and three-body effects; they did not find explicit matching of body orientation in their data. That makes an excellent limit beside our model, rather than a reason to discard it. [Katz et al., 2011](https://pubmed.ncbi.nlm.nih.gov/21795604/)

**Proposed encounter:** keep the selected sphere and its three arrows inside a larger school. Move a boundary or introduce a visible moving disturbance, then watch the selected body's response before interpreting the whole school. The current open flock does not sense the player's hand; hand response would be a new, named term. A fish-shaped display can be optional while the sphere remains the tutorial object.

### Drones

Zhou and colleagues' miniature drones combine onboard sensing, trajectory planning, obstacle avoidance and coordination in cluttered environments. Their work is a useful reminder that real flight requires more than a pretty flocking pattern. It is not evidence that our three-rule model implements their planner. [Zhou et al., 2022](https://pubmed.ncbi.nlm.nih.gov/35507682/)

**Proposed encounter:** two small flights start from the same positions. One heads for assigned formation slots; the other responds to nearby bodies. Move a gate and expose the active guidance arrows. Label the actual controller in each case. Later, ABM could add a low-energy return state. Use these as simulated exhibits; the lesson's frozen pickables are not a real quadrotor flight controller.

### Games and zombies

*Days Gone* makes the horde an encounter with terrain, migration and changing activity. Its creators describe feeding, resting and drinking locations, and a sleeping group responding to noise. Those are useful references for a room that changes when the player acts. They do not establish that the game uses our Boids implementation. [Bend Studio on its hordes](https://blog.playstation.com/2019/04/25/fighting-the-overwhelming-hordes-of-days-gone/)

Valve's published *Left 4 Dead* material describes a Director that regulates dramatic intensity by varying threats. This gives us another layer: the system deciding when bodies appear is distinct from each body's movement rule. [Michael Booth, The AI Systems of Left 4 Dead](https://steamcdn-a.akamaihd.net/apps/valve/2009/ai_systems_of_l4d_mike_booth.pdf)

**Proposed encounter:** resting points hear a pulse from the catalyst sphere, investigate its last recorded location, then return to rest. A narrow passage makes the group's movement consequential. Add separation and route following only as explicitly inherited or newly supplied components. An optional visible Director adds arrivals in waves; Population Support can account for those arrivals. No infection model is required to teach this state change.

For Ada, the interesting play is to redirect, distract, shelter from or release the group. Shooting can be one action, but the swarm can also help carry, protect or gather. A label such as enemy should not silently replace the rule the student is meant to understand.

## Art connections that do specific work

**DRIFT, Franchise Freedom.** A flying sculpture inspired by starling movement; the Central Park presentation used a thousand drones. It belongs beside our distinction between a visible collective and the conditions that arrange it. The artist's account supports that connection, not a claim that our code reproduces the work. [DRIFT](https://studiodrift.com/franchise-freedom-at-new-york-central-park/)

**Random International, Swarm Study III.** Its light formations respond to visitors' paths. This is a close reference for making the visitor one input to an artificial collective and for rendering behaviour through light. [Random International](https://www.random-international.com/swarm-study-/-iii)

**Theo Triantafyllidis, BugSim (Pheromone Spa).** An insect world framed through a managed terrarium and its continuing environmental regulation. This is the strongest connection to the closing population account: what sustains the appearance of an autonomous world? [Artist's account](https://slimetech.org/works/bugsim)

**Theo Triantafyllidis, Radicalization Pipeline.** Its continuously renewed battling hordes connect game behaviours to a political imaginary. The artist discusses characters dying and respawning without a resolving end. This belongs beside a proposed horde encounter and the visible accounting of replacement. It is an artistic interpretation, not a validated model of human radicalisation. [Artist interview](https://slimetech.org/news/vral-28-radicalization-pipeline)

These references could enter final.md in one or two sentences attached to something the visitor actually sees. A new unbuilt behaviour cannot yet be narrated as an encounter.

## The seven halls retain their subjects

| Hall | Keep the tutorial focused on | Possible extension or reference | A useful question for the reflection |
| --- | --- | --- | --- |
| Physarum | Read, retain and deposit a shared trace | Let visitors leave a trace that later bodies encounter | What remains available after its maker leaves? |
| Flow Fields | Read a supplied direction and steer | A crowd through a fork; compare visible and hidden guidance | Did the bodies agree, or receive the same instruction? |
| Boids | Select neighbours and combine three requests | Existing fish tank; local drone group; responsive light | What makes a collective look free, disciplined or threatening? |
| ABM | State changes which information is used | Catalyst pulse wakes a resting horde; later a drone return state | What did we give this body the capacity to notice? |
| Ant Colony | State selects which channel is read and written | Foragers leaving distinct outward and homeward marks; BugSim comparison | Who inherits a route, and who maintains it? |
| Particle Swarm | Keep evaluated positions as personal and shared records | Search under two scoring rules; compare it with autonomous navigation | Who chooses what counts as a good place? |
| Population Support | Distinguish births, losses and supplied arrivals | Visible horde replenishment or managed terrarium | What must keep happening for the world to look self-sustaining? |

One primary artifact still carries each tutorial. The other examples can be playable comparisons, references or simply part of the museum. The existing ghost-student results apply to the current lessons, not to these extensions.

## Conceptual swarms and the next sequence

We could release thumbnails of Ada's halls into an atlas and let them gather by a declared relation: shared code, reused object, cited source or an editor's association. Change one relation at a time. A sphere, a trace and a returning memory might gather across distant parts of the spine; selecting one should expose the records responsible for that connection.

This is our proposed representation. It should show its evidence and distinguish manually assigned associations from measured similarities. A force layout or an optimizer can position the records, but neither establishes that the resulting cluster is true. Graph Theory is the natural place to unfold the relations; Swarm can introduce the experience of a grouping that changes when the relation changes.

There is also a smaller comparison worth trying: keep trajectories identical and change only the bodies' appearance and sound. Then keep appearance fixed and change the rule. The first asks what representation contributes; the second asks what the controller contributes. My reading is that a school, a light sculpture and a horde can make similar motion feel very different. That interpretation should remain open to a visitor's response.

## A focused next experiment

Start with the existing Boids hall and the same PointBody. Make the selected body's neighbours and requests readable at full size. Add one clearly labelled disturbance for a fish-school comparison. Only then try an optional seek, flee and arrive study with the catalyst as a target, followed by the ABM state change for the horde. Drone choreography, maintenance and conceptual relations can remain comparison stations until their own learning need is clear.

Each extension needs a declared observation and prediction: changing the display must leave the recorded trajectory unchanged; adding a stimulus must affect only the states that can sense it; disabling neighbour influence must remove that contribution; a supplied arrival must remain visible in the account. These are future acceptance criteria, not passing tests reported today.

Short memory: PointBody persists; controllers differ. Fish→neighbours. Drone→sensing/planning/coordination. Horde→state+navigation+optionalDirector. Art→appearance, spectatorship, maintenance. Concept swarm→declaredrelations, thenGT. One primary lesson/hall; othercases optional. Proposed, not implemented.
