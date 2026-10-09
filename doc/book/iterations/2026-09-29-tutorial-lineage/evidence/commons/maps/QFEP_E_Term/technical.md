# Count the endings before weighting them

The previous hall varied a binary source probability while preserving its two possible symbols. Here the entropy fan varies the number of available endings.

Four levels, each offering b continuations, produce b^4 leaves: 1, 16 or 81 for b=1, 2 or 3. The running CYCLE visits those three branching factors. ONE holds a single continuous stem. OPEN holds the full ternary tree. PRUNE uses the existing pruned prospect: at the third level, each of nine parents retains one child instead of three. Eighteen amber branch caps remain visible; their removed subtrees would have contributed fifty-four leaves. Twenty-seven leaves survive.

The implementation counts leaf meshes as it builds them. Its readout then uses:

```gdscript
var s_val: float = log(float(futures))
```

This is H=ln(N), the Shannon entropy of a uniform distribution over N leaves, in nats. It is not a measured distribution of visits. For 1, 16, 81 and 27 leaves the readings are approximately 0, 2.77, 4.39 and 3.30 nats. Unequal probabilities would require a different calculation, -sum(p*ln(p)). The display now states its equal-weight assumption and distinguishes branch closures from missing leaf outcomes.

This map enables visitor_control:on. Four canonical physical buttons select CYCLE, ONE, OPEN and PRUNE. The console remains alive while the diagram rebuilds, so pressing a button does not free the node emitting its signal. The fan and adjacent readout are raised on a stand; the control surface is at 0.95 m above the map floor. Placements without the option retain automatic cycling and no console. Existing prospect and emissive configurations remain supported.

The fourteen-by-fourteen hall has a level floor and clear side passages. Seven placed works remain. Counter, cloud, particles, cubes and the independent lambda rail are secondary comparisons; none supplies the fan with probabilities. The legacy tt text token remains in the map but does not currently instantiate as a museum artifact. Lambda's ignored value:1.0 configuration and the dissolution caption are removed. Its rail remains movable with no preferred-band marking here.

OPEN restores an authored diagram. It does not model ecological repair or give the visitor authority to invent another branching rule. That difference is the chapter's next research question, connected to QFEP's revisable terms in the project documents.
