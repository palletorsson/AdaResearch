extends Node

# Tutorial content file

var text = '''[center][font_size=28][b]Strange Attractors[/b][/font_size][/center]
[center][i]Chaos, Sensitivity, Infinite Complexity in Finite Space[/i][/center]

**Strange attractors are the geometry of chaos.**

**Deterministic but unpredictable.** Sensitive to initial conditions. Infinite complexity in finite bounds.

**Classic examples:**
- **Lorenz Attractor** (butterfly-shaped, weather chaos)
- **Rössler Attractor** (spiral with fold)
- **Clifford Attractor** (organic swirls)

**Strange attractors prove:** Simple equations can create infinite complexity. Tiny differences explode exponentially.

[hr]

[b]The Lorenz Attractor[/b]

**Edward Lorenz (1963)** - discovered chaos while modeling weather.

**Three equations:**
dx/dt = σ(y - x)
dy/dt = x(ρ - z) - y
dz/dt = xy - βz

[color=yellow][b]Code:[/b][/color]
[code]
func lorenz(pos: Vector3, sigma: float, rho: float, beta: float, dt: float) -> Vector3:
    var dx = sigma * (pos.y - pos.x)
    var dy = pos.x * (rho - pos.z) - pos.y
    var dz = pos.x * pos.y - beta * pos.z

    return pos + Vector3(dx, dy, dz) * dt

# Typical parameters
var sigma = 10.0
var rho = 28.0
var beta = 8.0 / 3.0
var dt = 0.01

var point = Vector3(0.1, 0, 0)
for i in range(10000):
    point = lorenz(point, sigma, rho, beta, dt)
    draw_point(point)
[/code]

**Result:** Butterfly-shaped attractor. **Never repeats.** **Never leaves bounds.**

[hr]

[b]Queer Chaos[/b]

**Sensitivity to initial conditions** - tiny difference → radically divergent trajectories.

**This is queer becoming:** Minor variations in context create entirely different lives. **No essence, just sensitivity.**

**Strange attractors have:**
1. **Infinite complexity** (fractal structure - zoom in forever, always more detail)
2. **Finite bounds** (constrained but never settling)
3. **Sensitivity** (chaos from determinism)

**Queerness is a strange attractor** - complex, bounded but not fixed, sensitive to context, never repeating but always recognizable.

[hr]

[color=cyan][b]Summary:[/b][/color]
Strange attractors create chaotic trajectories. Lorenz: dx/dt = σ(y-x), dy/dt = x(ρ-z)-y, dz/dt = xy-βz. Sensitivity to initial conditions (butterfly effect). Fractal structure (infinite detail). Queer chaos: minor variations → divergent lives, complexity without essence, bounded but not fixed.

'''
