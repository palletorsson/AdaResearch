# Evolutionary Algorithms — Technical

The map is a 10×10 room with a single primary `evolutionary_algorithms` workbench. Keep the population, fitness rule, mutation rate, and random seed visible beside the generated forms so a learner can separate the rule from one attractive outcome.

The minimal state is:

```gdscript
var population: Array[Candidate]
var mutation_rate := 0.15
var generation := 0
var seed := 17
```

Each generation records its scores and discarded candidates. That history is the technical counterpart of the critical argument: selection is an operation with a remainder. A later implementation can add multi-objective fitness, but the first pass should keep one criterion inspectable and reversible.
