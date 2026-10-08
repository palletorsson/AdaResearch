# Keep several readings live

```gdscript
func classify(value: float, threshold: float) -> String:
    if value > threshold: return "present"
    if value < threshold * 0.5: return "absent"
    return "undecided"
```

Move the threshold slowly. Record where the field changes from present to undecided, then compare that boundary with a second rule. The exercise keeps a category tied to its test.

The next map, `SpeculativeComputation_Rhizome_Network`, replaces one centre with many connected paths.
