# Grammar Markov

Floating creature with 4 colored face-states driven by a Markov chain transition matrix.

## Behavior

Extends `HazardCreatureBase`. 80 HP. Teaches Markov chains and probabilistic state transitions.

- 4 faces on cardinal directions, each a state: RED (lunge), BLUE (sweep), GREEN (projectile), GOLD (shield)
- Current face determines attack behavior
- Transitions follow a 4×4 probability matrix every 2.0s
- After 3 full cycles, the transition matrix mutates slightly

## Files

| File | Purpose |
|------|---------|
| `grammar_markov.gd` | Main script — Markov state machine, attack patterns |
| `grammar_markov.tscn` | Scene |

## Key Parameters

| Parameter | Value |
|-----------|-------|
| `transition_interval` | 2.0s |
| `lunge_speed` | 6.0 |
| `sweep_speed` | 4.0 |
| `projectile_speed` | 8.0 |
| `shield_heal` | 5.0 |
