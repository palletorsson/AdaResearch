extends Node

var text = '''[center][font_size=28][b]Self-Organized Criticality[/b][/font_size][/center]
[center][i]Sandpiles, Power Laws, Edge of Chaos[/i][/center]

**Self-Organized Criticality (SOC): systems naturally evolve to critical state.**

**Classic example: Sandpile model**
- Add sand grains one at a time
- When pile too steep, **avalanche** (topple to neighbors)
- System self-organizes to **critical angle**

[hr]

[b]Sandpile Model[/b]

[color=yellow][b]Code:[/b][/color]
[code]
var grid = []  # 2D grid of sand heights
var critical_height = 4

func add_grain(x, y):
    grid[x][y] += 1

    if grid[x][y] >= critical_height:
        topple(x, y)

func topple(x, y):
    grid[x][y] -= 4

    # Distribute to neighbors
    if x > 0:
        grid[x-1][y] += 1
        if grid[x-1][y] >= critical_height:
            topple(x-1, y)  # Cascade

    # Repeat for other neighbors
    # (right, up, down)
[/code]

**Result:** Avalanches of all sizes. **Power law distribution:** P(size) ~ size^(-α)

[hr]

[b]Properties[/b]

- **No tuning needed** - system finds critical state automatically
- **Power law** - many small avalanches, few large ones (no characteristic scale)
- **1/f noise** - pink noise, found in nature
- **Edge of chaos** - between order and disorder

[hr]

[b]Examples in Nature[/b]

- **Earthquakes** (Gutenberg-Richter law)
- **Extinctions** (punctuated equilibrium)
- **Stock market crashes**
- **Neural avalanches** (brain activity)
- **Forest fires**

[hr]

[b]Queer SOC[/b]

**SOC is the edge between stability and chaos.**

**Not order** (frozen, rigid).
**Not chaos** (random, unstructured).
**Critical** (maximum complexity).

**This is queer positionality:**
- **Not normative** (stable heteronormativity)
- **Not chaotic** (random, incoherent)
- **Critical edge** (maximum creative tension)

**SOC systems are always one grain from avalanche.** **Queer existence at the edge of catastrophe and creativity.**

**Power laws:** Most events small, occasional large disruptions. **Queer history: daily resistance + occasional riots/revolutions.**

[hr]

[color=cyan][b]Summary:[/b][/color]
SOC: systems self-organize to critical state (sandpile). Avalanches follow power law (many small, few large). Edge between order and chaos. Natural examples: earthquakes, extinctions, brain activity. Queer SOC: critical edge not normative stability or chaos, maximum creative tension, one grain from avalanche, power law history (daily resistance + occasional revolution).

'''
