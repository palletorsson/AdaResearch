# Speculative evolution

An evolutionary algorithm is a loop over a population, not a magic search for an ideal form.

```gdscript
func evolve(population: Array) -> Array:
    var ranked := population.filter(func(candidate): return candidate.fitness >= threshold)
    var next := ranked.duplicate()
    while next.size() < population.size():
        next.append(mutate(ranked.pick_random()))
    return next
```

Read the loop in this order: evaluate, select, mutate, repeat. First change the fitness threshold while keeping the mutation amount fixed. Then keep the threshold fixed and change mutation. Compare which operation changes the population’s direction and which only changes its variation.

The workbench exposes a speculative design question: a criterion is an instrument that shapes what can continue. The next map, `SpeculativeComputation_Queer_Cyborg_Subjectivity`, moves that question from populations to bodies.
