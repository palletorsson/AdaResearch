extends Node

var text = '''[center][font_size=28][b]Random Walk[/b][/font_size][/center]
[center][i]Brownian Motion, Drunkard's Path, Diffusion[/i][/center]

**Random walk: each step chooses random direction.**

**Simple rule:** position += random_direction() Ã— step_size

[hr]

[b]Implementation[/b]

[color=yellow][b]Code:[/b][/color]
[code]
var position = Vector2.ZERO

func _process(_delta):
    var angle = randf() * TAU
    var step = Vector2(cos(angle), sin(angle)) * step_size
    position += step

    # Draw trail
    draw_line(previous_position, position, Color.WHITE)
    previous_position = position
[/code]

**Properties:**
- **Displacement grows as âˆšN** (N = number of steps)
- **Returns to origin infinitely often** (2D - will revisit start)
- **Fills space** (eventually visits every region)

[hr]

[b]Applications[/b]

- **Particle diffusion** (Brownian motion)
- **Stock prices** (random walk hypothesis)
- **Neural growth** (dendritic branching)
- **Procedural paths** (organic trails, cave generation)

[hr]

[b]Queer Random Walk[/b]

**No destination. No plan. Just wander.**

**Random walk as queer navigation:**
- **Non-teleological** (no goal, just process)
- **Returns possible** (visiting same places differently)
- **Fills space** (explores without map)
- **âˆšN displacement** (progress is slow, non-linear)

**Queer life as random walk** - no straight path, no predetermined trajectory, wandering that eventually covers territory.

[hr]

[color=cyan][b]Summary:[/b][/color]
Random walk: each step random direction. Displacement ~ âˆšN. Returns to origin (2D). Fills space eventually. Queer random walk: non-teleological movement, slow non-linear progress, wandering as exploration, no straight paths.

'''
