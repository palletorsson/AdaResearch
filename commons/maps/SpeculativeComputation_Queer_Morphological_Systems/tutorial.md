# Local rule, changing body

```gdscript
func step(cell, neighbours):
    var contact := neighbours.count(func(n): return n.active)
    return contact >= 2 and contact <= 4
```

Run one step, inspect the changed cells, and repeat. Keep the seed fixed while changing the threshold. Then reset and change only the seed. Record which differences belong to the rule and which belong to the starting arrangement.

The next map, `SpeculativeComputation_Ontological_Uncertainty`, asks what remains knowable when the evolving body cannot be reduced to one reading.
