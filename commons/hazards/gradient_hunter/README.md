# Gradient Hunter

Predator that uses gradient descent to hunt the player — samples positions, evaluates loss, moves toward the minimum.

## Behavior

Extends `HazardCreatureBase`. 75 HP. Teaches gradient descent and local minima.

- Samples 6 positions around itself at radius 0.8
- Evaluates distance-to-player as loss function at each sample
- Moves toward the sample with lowest loss (learning rate 3.0)
- Gets stuck behind walls (local minima)
- After 3 seconds stuck, "anneals" by jumping to a random offset

## Files

| File | Purpose |
|------|---------|
| `gradient_hunter.gd` | Main script — sampling, loss evaluation, annealing |
| `gradient_hunter.tscn` | Scene |

## Visual

- Torus body mesh
- 6 sample spheres color-coded: best = green, worst = red
- Gradient arrow shows current descent direction
- 2 walking legs
