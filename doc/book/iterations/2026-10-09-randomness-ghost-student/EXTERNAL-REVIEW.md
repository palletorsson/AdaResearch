# Randomness — Critical assessment of the complete sequence

Ada Research · 14 halls · Tutorials, reflections and review package · 9 October 2026

I've examined the Randomness review package, including the fourteen-hall teaching structure, the reflective sequence, the revision notes and the validation evidence.

My judgment: Randomness is among the strongest sequences in the curriculum, particularly as artistic research. It is less tightly organized around one algorithm than Cellular Automata or Fractals, but it develops a more expansive understanding of uncertainty, representation, probability and agency.

Its most interesting accomplishment is that randomness gradually changes function. It begins as a source of numerical variation, becomes a means of constructing forms and trajectories, then becomes a condition affecting what the visitor knows and can do.

## 1. The fourteen-hall progression

| Hall                | Main learning operation                                   | Conceptual development                                 |
| ------------------- | --------------------------------------------------------- | ------------------------------------------------------ |
| 01. Definition      | Seeds and pseudorandom generators                         | A reproducible procedure produces variation            |
| 02. Entropy         | Frequency counts and Shannon entropy                      | Different arrangements can have the same entropy       |
| 03. Remove          | Eligible addresses and random selection                   | Chance acts within a predetermined set                 |
| 04. PRINT Algorithm | A randomized visual grammar                               | Fixed counts, different arrangements                   |
| 05. Cubes           | Conditional repeated draws                                | A random result can determine when a process stops     |
| 06. Rotate XYZ      | Store random transformations                              | Sampling and animation are separate operations         |
| 07. Walk            | Accumulate random steps                                   | A trajectory keeps a history of choices                |
| 08. Gaussian        | Sample and bin distributions                              | A distribution is reconstructed from finite evidence   |
| 09. Mushrooms       | Use sampled values as design parameters                   | Variation acquires bodies                              |
| 10. Space Geometry  | Compare independent draws and Perlin field samples        | Neighbouring values may become correlated              |
| 11. Examples        | Monte Carlo estimation                                    | Random samples can become evidence for a quantity      |
| 12. Pheromone       | Feed past visits into future choices                      | Randomness enters a feedback system                    |
| 13. Space           | Combine spatial fields                                    | Layering and normalization change what becomes visible |
| 14. Game            | Random timing, hidden decisions and physical consequences | Uncertainty becomes a condition of action              |

Unlike Fractals, this sequence is not primarily about building increasingly complicated objects. It moves toward increasingly complicated relationships between a procedure, its generated results, and the subject encountering them.

## 2. The strongest conceptual distinction: randomness is not one thing

The sequence demonstrates several operations that are frequently confused.

A random seed determines reproducibility. A distribution determines the probabilities of possible values. A selection rule determines what is eligible. A spatial noise field determines correlations between nearby values. A feedback process makes previous events influence subsequent choices.

These are not interchangeable forms of uncertainty.

The mushroom lesson is particularly effective because the student can retain exactly the same sampled data while changing how it is expressed as physical form. The Monte Carlo lesson makes a different move: samples are not used to create an appearance but to estimate an area.

The curriculum is teaching students to ask not just whether something is random, but where randomness enters a process and what it is allowed to influence.

That is an important computational skill.

## 3. The Entropy lesson is intellectually central

The revised lesson begins with a concrete comparison: keep symbol counts constant while changing the ordering of the symbols.

Shannon entropy remains unchanged because it measures the distribution of symbols, not their spatial arrangement.

This matters far beyond probability theory.

A grid with a striking pattern and another grid with a scattered arrangement may have identical symbol frequencies. Their difference is important to an observer but absent from that particular measure.

The reflection's title, What the gauge forgets, is appropriate. It turns a mathematical limitation into an investigative question.

I would preserve this chapter. Its revised division between the initial experiment and the more detailed entropy calculation is a good pedagogical decision.

## 4. Random Walk and Pheromone form an especially productive pair

[Randomness and Randomization > Random walks](https://images.openai.com/static-rsc-4/fpa1gyLNDz2tj4sC4b5eieiHGkSz_tPyfWrGWPjcAPT9gn6fA_gS-gtLNVOTaAu_9aAwBK3zO3MAJ-hrAR5msyNWXsZYkz31PAWI7KodFGkLxENw5t6txwmCJsUTSz6Pkdqiu6NyVw06ZjnxcjVJYVp9TVbzZHIfZdsN74FQyJQ?purpose=inline)

Random Walk

Each new movement is sampled and added to the current position. The accumulated trail records previous decisions, but it does not influence the rule choosing the next step.

[Biology Simulations | Simulations4All](https://images.openai.com/static-rsc-4/kAPy2KI-gdZx1YnXkqe0upbrLuOoXi6cDaFiHUxA4wDBbNb5oRWWX9a10jHdkcvHS3vt8dQPbgO37MPvChNVfpeStuDTA8EsFmC5pAJ3v6b5kjWsQjT7uk-k0JtpO0Crgq29fzvYv-HC4-mLOmEJRcjMa6MTHgferqiEHZm8gvk?purpose=inline)

Pheromone

Previous visits modify a spatial field. That field influences subsequent choices, making earlier movement consequential for later movement.

This is a substantial conceptual progression.

In Random Walk, history is retained as a record. In Pheromone, history becomes part of the mechanism generating the future.

The updated tutorial makes the Pheromone update sequence particularly clear: fade, deposit, count, choose, move.

The distinction between twenty visits and twenty-one recorded positions after twenty updates is small but important. It makes the timing of the update explicit.

I regard this as one of the best transitions in the fourteen lessons.

## 5. Random Game is the strongest artistic conclusion

The final reflection, Told, or finding out, is especially successful.

The hall compares three situations:

- A choice is determined and disclosed before the visitor acts.
- A choice is determined after the visitor commits.
- A choice is predetermined but concealed until after the visitor commits.

The physical possibilities can be identical in all three cases. What changes is the visitor's relationship to the decision.

That is a much richer investigation than simply making a door open at random.

The distinction between an undetermined future and an already determined but unknown outcome is philosophically substantial, yet the museum makes it accessible through a small walking decision.

The timed stones provide another good experiment. A randomly chosen delay determines when a platform will disappear, while a separate warning system determines how much advance notice the visitor receives.

This distinguishes the event itself from the information made available about it.

I particularly like the underlying question: before judging a visitor's decision as badly timed, we should examine what information the environment supplied.

The reflection also observes that a replay can reproduce a random sequence but cannot return the visitor to their earlier state of ignorance.

That is a strong culmination of the recurring concern with computational state and human memory.

## 6. My main criticisms

### A. Fourteen halls may be more than the conceptual argument needs

This is the longest sequence among those reviewed so far.

The breadth is justified, but there is a risk of cumulative fatigue, especially through the middle of the sequence.

Remove, PRINT Algorithm, Cubes, Rotate XYZ and Walk all demonstrate variations on how sampled values influence an operation.

Their mechanisms differ, but students might experience them as several consecutive lessons on drawing random values and applying them to objects.

I would not automatically remove any hall. Instead, I would make their distinct purposes particularly explicit:

Selection, conditional continuation, transformation and accumulated movement are different uses of randomness.

The revised tutorial introductions move in this direction.

### B. Entropy arrives before students encounter several contrasting distributions

This ordering is defensible because students already have substantial experience with arrays, colour and sampling.

Nevertheless, Shannon entropy is relatively abstract compared with the surrounding operations.

The revised approach—beginning with sorting and counting before introducing the formula—largely resolves this.

I would judge its success by whether a student can explain why sorting changes neighbouring relations without changing Shannon entropy. Deriving the formula is a secondary goal.

### C. Randomness and Noise need an especially clear boundary

Hall 10 introduces Perlin noise, and Hall 13 builds layered spatial fields. The next major sequence is Noise.

This is not necessarily duplication. Randomness benefits from demonstrating that nearby draws may be independent or correlated.

But I would make the handoff explicit:

Randomness asks how sampled variation is produced, distributed, selected and used.

Noise can investigate the spatial and temporal structure of correlated variation, including frequency, octaves, domains and field transformations.

The Randomness text already establishes this distinction; I would make sure the following Noise sequence honours it.

### D. The reflections remain extensive

The revised reflections are stronger because repeated operational instructions have been removed.

However, fourteen long reflective encounters place a substantial reading demand on the student.

I would distinguish between the complete book and what a visitor is expected to read during a museum session.

The museum can sustain more encounters than either text describes. The book can sustain more interpretation than the visitor needs while actively experimenting.

Maintaining that separation is a strength, not a defect.

## 7. Programming pedagogy and technical evidence

The fourteen examples reuse earlier constructions and supply complete source code. The sequence becomes more independent conceptually as it progresses, especially when students must preserve records, compare invariants or explain what an altered parameter actually changes.

The review reports 420 passing assertions across fourteen baseline Godot 4.6 examples. The archive also includes test logs and extracted learner files. These are meaningful implementation checks, although they do not establish that an unfamiliar student can complete each lesson independently or that every museum interaction works comfortably in VR.&#x20;



Two previously recorded entrance issues in Random Space and Random Game remain outside this editorial revision. They should be treated as actual outstanding integration concerns, rather than assumed resolved.&#x20;



## 8. How Randomness compares with the other sequences

| Sequence          | Distinctive learning contribution                                                    |
| ----------------- | ------------------------------------------------------------------------------------ |
| Forces            | Physical causality and consequences of interaction                                   |
| Wavefunctions     | Periodic functions across movement, geometry and sound                               |
| Randomness        | Uncertainty, distributions, sampling, feedback and information available to an agent |
| Cellular Automata | Local state updates and collective behaviour                                         |
| Fractals          | Recursive generation and replacement across scales                                   |
| L-systems         | Instructions, interpreters and constructed forms                                     |

Randomness has a particularly important position after Wavefunctions.

Wavefunctions shows how regular procedures create repetition and how their timing can be measured. Randomness then asks what changes when the next value, position, transformation or event is selected from a distribution.

It is a shift from prescribed repetition toward structured uncertainty.

But Randomness also prepares several later ideas: noisy fields, probabilistic cellular rules, stochastic branching and procedural variation.

## Final judgment

I would preserve the fourteen-hall structure for now, rather than compressing it before testing the learning experience.

The strongest part of the sequence is its gradual movement from numerical uncertainty toward situated uncertainty: what a body can know, when it can know it, and what consequences follow from acting without complete information.

That is an unusually strong combination of computational pedagogy and artistic inquiry.

My main recommendation would be to protect the distinction between three increasingly sophisticated operations:

Sampling a value → accumulating a history → allowing that history to influence future choices.

The Random Walk, Pheromone and Random Game chapters make this progression tangible.

Across the larger Ada Research curriculum, Randomness contributes something especially valuable: the realization that unpredictability is not simply a property of a system. It also depends on what has been selected, what is retained, what can be observed, and when an observer is allowed to know the result.

That insight is both technically teachable and artistically productive.