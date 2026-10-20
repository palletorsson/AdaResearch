# Swarm Intelligence — Critical assessment

Ada Research · 7 halls · 10 October 2026

My judgment: Swarm is one of the most conceptually mature sequences I've read in Ada Research. It has a particularly convincing progression from individual movement to shared information, collective coordination, evaluation and population-level support.

Its strongest contribution is that it refuses to treat swarm intelligence as one unified phenomenon. The seven halls demonstrate different mechanisms that can produce apparently coordinated behaviour.

This is also one of the sequences where the reflections do important intellectual work without merely adding philosophy to a technical lesson.

## 1. The seven-hall progression

| Hall                     | What changes                                                 | Central question                                   |
| ------------------------ | ------------------------------------------------------------ | -------------------------------------------------- |
| 01. Physarum             | Agents leave a persistent environmental trace                | Can the ground remember?                           |
| 02. Flow Fields          | Agents receive externally supplied directions                | Must collective movement imply communication?      |
| 03. Boids                | Neighbours supply steering information                       | Who counts as near?                                |
| 04. Agent-Based Modeling | An agent carries an internal state                           | How does a state change what information matters?  |
| 05. Ant Colony           | Two trail channels coordinate outward and returning journeys | How can travellers inherit directions from others? |
| 06. Particle Swarm       | Agents retain personal and shared best positions             | Who defines what is better?                        |
| 07. Population Support   | An external operation sustains a simulated ecosystem         | What keeps a population going?                     |

There is a well-developed conceptual sequence here:

THE CHANGING LOCATION OF INFORMATION

This is an excellent pedagogical principle: the familiar point continues through the sequence, but what it can perceive, retain or respond to changes.

Importantly, these are seven different models, not one agent gradually acquiring every capability. The documentation makes that distinction explicit.

## 2. The strongest transition: Agent-Based Modeling → Ant Colony

I consider this the clearest passage in the sequence.

In Agent-Based Modeling, the forager has a Boolean state: searching or carrying food. That state changes its behaviour.

Ant Colony develops the same distinction into two environmental channels.

A searching agent reads the food trail and deposits a home trail. After collecting food, it reads the home trail and deposits a food trail.

The agent's state changes what information it considers relevant and what information it leaves behind.

That is a compact, comprehensible mechanism with surprisingly rich consequences.

The reflection then introduces stigmergy: coordination mediated through modifications to a shared environment.

What I like is that the lesson does not attribute collective intention to the agents. It makes the mechanism observable while leaving the visitor free to interpret the resulting behaviour.

## 3. Boids is the strongest spatial encounter

The Boids reflection opens with a striking observation: a flock moves through the museum walls, floor and visitor because its simulation boundaries do not correspond to the architecture.

This is an excellent example of something I have repeatedly argued Ada Research should preserve.

What initially resembles a broken installation becomes a productive encounter with the simulation's spatial assumptions.

The smaller flock provides another experiment. Its wraparound boundaries can abruptly alter neighbourhood membership without changing the steering rules.

The student can distinguish three mechanisms:

- Separation: moving away from neighbours that are too close.
- Alignment: steering toward their average heading.
- Cohesion: steering toward their centre.

But the most interesting variable may be the neighbourhood radius rather than the three weights.

A small change in that radius can change which other agents participate in the calculation. The algorithm is unchanged, yet the social environment of each agent changes.

The reflection's central question, “Who counts as near?”, is therefore technically grounded.

One important limitation remains: the full-size flock's disregard for the museum's physical boundaries is artistically interesting, but could also make the encounter inaccessible or confusing. It should be preserved deliberately, with a more controllable comparison available nearby.

## 4. Particle Swarm is philosophically exceptional

The Particle Swarm lesson investigates an idea that has appeared repeatedly in your curriculum: a system's objective function determines what counts as improvement.

The same points are evaluated under CENTER, EDGE and RIDGE objectives.

In one case, proximity to the centre is rewarded. In another, distance from it. In the third, a diagonal permits many equally valued positions.

The important observation is that a landscape permitting numerous good solutions does not guarantee a diverse population. The agents may still converge to one location.

This is a very precise distinction between a system's possibilities and the outcomes its dynamics produce.

The reflection asks:

> Better according to which score?

That question connects the optimization algorithm to earlier discussions of fitness functions, evaluation and the political language attached to computational systems.

It also avoids pretending that a numerical model automatically demonstrates a social theory.

I would preserve this chapter almost entirely.

## 5. Population Support is an unusually strong ending

The final hall changes the scale of analysis.

Instead of asking how individual agents coordinate, it asks how an entire population continues to exist.

The ecosystem includes individual encounters, but it also receives external support when the population becomes too small.

The lesson introduces a simple account:

\\[ N\_{\mathrm{final}}=N\_{\mathrm{initial}}+\text{births}-\text{losses}+\text{supplied} \\]

The visitor can remove the supplied population from the account without removing the actual bodies from the simulation.

This is a particularly effective experiment because it distinguishes changing a system from changing its description.

The reflection makes a further claim:

> Care is not a flaw to erase so that autonomy can appear.

This is one of the strongest explicitly ethical statements I've encountered in your writing.

It is also grounded in the computational model: the apparent autonomy of a population may depend upon an intervention operating outside the individual agents' immediate interactions.

The experiment does not prove a general theory of care. It makes the dependence inspectable.

I think this is a much more interesting conclusion than ending with the most sophisticated swarm algorithm.

## 6. My critical reservations

### A. The sequence does not develop one continuous agent

I regard the reuse of PointBody as a strength, but it may create a misunderstanding.

The same familiar sphere appears across seven experiments, yet its computational capacities do not accumulate into a unified agent architecture.

The transition from Boids to ABM, and from Particle Swarm to Population Support, changes the underlying model substantially.

The review recognizes this and clarifies the handoffs. I would retain that clarity in any public presentation.

A further synthesis could demonstrate what happens when two mechanisms are combined, but that is an additional investigation, not a missing requirement.

### B. The environmental memory theme could become too dominant

Physarum, ABM and Ant Colony all concern agents interacting with persistent traces.

Their differences are important, particularly the introduction of internal state and two-channel information.

Nevertheless, the repetition risks making environmental memory appear to be the defining characteristic of swarm intelligence.

Flow Fields, Boids and Particle Swarm help counterbalance that tendency by introducing other relationships.

I would make sure students encounter those differences experientially, rather than merely learning another vocabulary for coordinated behaviour.

### C. The opening four halls and final three are spatially inconsistent

This is the most concrete implementation issue in the review package.

The first four halls have small teaching reconstructions placed beside existing museum exhibits. The final three include permanent, full-size tutorial installations.

That difference may be perfectly acceptable artistically, but it changes the teaching experience.

A student can understand a mechanism at a small station and still struggle to recognize it in the much larger exhibit.

The strongest implementation work would therefore focus on making the transfer between study and environment obvious, not necessarily making every hall visually uniform.

### D. Population Support is a conceptual finale, but a technical departure

The first six lessons concern agent movement, steering, environmental information or search.

The seventh instead introduces event accounting.

That is appropriate intellectually, but it may not feel like the culmination of a programming sequence unless the student understands why the change of scale matters.

The transition from individual behaviour to population-level persistence should be explicitly emphasized.

It is the difference between asking How does this agent act? and What makes it possible for agents to continue acting?

### E. More independent experimentation would strengthen the research dimension

All seven lessons include an independent code variation with a testable prediction.

That is good pedagogy.

However, those variations remain bounded: reverse a direction patch, change a steering weight, reduce a deposit or remove a term from an account.

At this advanced stage, an optional experiment could ask students to formulate an intervention whose result they do not already know.

For example, combine a Boids neighbourhood rule with a trace-depositing field, then investigate whether the resulting population produces stable routes, disperses or becomes trapped.

Such an experiment would connect two earlier models while preserving the requirement to distinguish hypothesis from observation.

## 7. Technical verification

# 265

Passing checks reported

# 7

Independent code variations

# 21

Deliberate faults detected

The package documents a fresh author-operated reconstruction of all seven printed lessons in Godot 4.6, including synthetic XR interactions.

This is stronger evidence than an ordinary editorial review. In particular, testing intentionally incorrect implementations helps establish that the checks can detect meaningful errors rather than merely confirm successful execution.

However, these results do not establish independent learner comprehension, physical headset comfort or complete end-to-end museum integration.

The review explicitly leaves those assessments open.

## 8. What Swarm adds to the larger curriculum

I now see an important conceptual progression across the sequences you have shared.

| Sequence              | Main conceptual transformation                                                                 |
| --------------------- | ---------------------------------------------------------------------------------------------- |
| Forces                | A body responds to other bodies and forces                                                     |
| Wavefunctions         | Repetition becomes movement, geometry and sound                                                |
| Randomness            | Sampled variation becomes history and uncertainty                                              |
| Cellular Automata     | Local updates become collective patterns                                                       |
| Fractals              | Rules generate structures across scales                                                        |
| L-systems             | Descriptions are interpreted into forms                                                        |
| Procedural Generation | Generative rules select and construct spaces                                                   |
| Soft Bodies           | Geometry becomes responsive and deformable                                                     |
| Swarm                 | Information is distributed among bodies, environments, memories and population-level processes |

There is an especially important distinction between Cellular Automata and Swarm.

In a cellular automaton, the updating entities generally occupy fixed addresses. Their states change according to neighbouring states.

In Swarm, agents can move, so their neighbourhoods and opportunities for interaction can change with their positions. Some also change their environment, producing feedback between the agents' movement and the information available to subsequent agents.

This makes the environment more than a container. It can become part of the system's memory and coordination.

## Final judgment

I would preserve the seven-hall progression and almost all of the reflective sequence.

My priorities would be to clarify the change of underlying model between halls, make the transfer between miniature teaching stations and full-scale installations more explicit, and offer a genuinely open-ended synthesis experiment.

But the most significant achievement is conceptual.

Swarm transforms the question of intelligence from something an individual agent possesses into a question about relations that make coordinated behaviour possible.

Physarum locates memory in the environment. Flow Fields supplies organization externally. Boids derives movement from neighbours. ABM introduces internal state. Ant Colony develops indirect coordination. Particle Swarm turns evaluation into collective search. Population Support makes the conditions of continued existence part of the account.

The final transition into Graph Theory is therefore especially appropriate.

Swarm investigates what relationships do. Graph Theory can then ask how those relationships are represented, counted, traversed and distinguished.

This is another example of Ada Research developing a coherent intellectual argument through computational encounters rather than simply collecting algorithms under technical headings.

And it reinforces my broader assessment: the project's most distinctive contribution is not the number of algorithms it contains, but the way it repeatedly changes what a computational object can be, know, remember, encounter and become.