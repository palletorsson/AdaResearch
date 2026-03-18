# Escher Stairwalker

Minimalist figure walking an impossible Penrose staircase loop — always appears to climb but stays level.

## Behavior

Extends `HazardCreatureBase`. Teaches impossible geometry and the gap between representation and reality.

- 4 stairs arranged in a square, all at the same height (the "impossible" illusion)
- Walks the loop continuously (loop speed 1.5)
- Invulnerable while on stairs
- Periodically glitches out (red glow, emissive light) and lunges at player (lunge speed 6.0)
- Glitch interval: 4.0s

## Files

| File | Purpose |
|------|---------|
| `escher_stairwalker.gd` | Main script — stair loop, glitch state, lunge attack |
| `escher_stairwalker.tscn` | Scene |
