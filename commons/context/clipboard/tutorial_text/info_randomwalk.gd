var text = '''[b]Random Walk[/b]
[i]Paths of Random Steps[/i]

A random walk is a mathematical object that describes a path consisting of a succession of random steps.

It's one of the fundamental concepts in probability theory with applications in physics, biology, economics, and computer science.

[hr]

[b]Fundamental Properties[/b]

- Each step is completely independent of previous steps
- Direction is chosen uniformly at random
- Step size can be constant or variable (Lévy flight)
- Long-term behavior is predictable despite short-term randomness
- Expected distance from origin grows as √N (N = number of steps)

[i]Historical Context:[/i]
First studied by Karl Pearson in 1905. Einstein's 1905 paper on Brownian motion used random walk theory to prove the existence of atoms.

[hr]

[b]Mathematical Foundation[/b]

Position at step n: P(n) = P(n-1) + Step(n)

[i]Displacement:[/i]
Expected displacement after N steps: E[|X_N|] ∝ √N

This square root relationship is fundamental - to get twice as far takes four times as many steps.

[i]Return Probabilities:[/i]
- 1D: 100% (guaranteed to return to origin)
- 2D: 100% (proved by Polya in 1921)
- 3D: ~34% (might never return!)
- 4D+: Even lower

[hr]

[b]Implementation[/b]

[code]
var position = Vector2.ZERO

func step():
    var direction = Vector2(
        randi_range(-1, 1),
        randi_range(-1, 1)
    )
    position += direction * step_size
[/code]

This creates movement in 8 possible directions (including diagonals).

[hr]

[b]Applications[/b]

[i]Procedural Generation:[/i]
- Dungeon layouts and cave systems
- Terrain features and river paths
- Maze generation algorithms

[i]AI & Behavior:[/i]
- NPC wandering behavior
- Particle system movements
- Exploration algorithms

[i]Simulations:[/i]
- Brownian motion (physics)
- Stock price models (finance)
- Diffusion processes

[hr]

[b]Variations[/b]

[i]Biased Random Walk:[/i]
Tendency to move in certain directions - used for directed exploration.

[i]Self-Avoiding Walk:[/i]
Cannot revisit previous positions - creates more spread-out patterns.

[i]Lévy Flight:[/i]
Occasional large jumps mixed with small steps - models foraging behavior in nature.

[i]Continuous Random Walk:[/i]
Smooth angles instead of discrete directions - more realistic movement.
'''
