extends Node

# Tutorial content file
# Edit using the Tutorial Text Editor plugin

var text = '''[center][font_size=28][b]Conway's Game of Life[/b][/font_size][/center]
[center][i]Four Rules, Infinite Emergence[/i][/center]

In 1970, mathematician John Conway invented **Life** - a 2D cellular automaton with four incredibly simple rules.

From these rules emerge:
- **Gliders** - patterns that move diagonally forever
- **Spaceships** - larger moving patterns
- **Guns** - patterns that spawn gliders periodically
- **Self-replicators** - patterns that copy themselves
- **Universal computers** - Turing-complete systems built from gliders

**Four rules. Infinite emergence. Computational universality.**

Life is proof that **complex behavior does not require complex rules**.

[hr]

[b]The Rules: Birth, Survival, Death[/b]

A 2D grid. Each cell is **alive** (1) or **dead** (0). Each cell looks at its **8 neighbors** (horizontal, vertical, diagonal).

[color=yellow][b]Conway's Four Rules:[/b][/color]
[code]
func next_state(cell_alive: bool, live_neighbors: int) -> bool:
    if cell_alive:
        # SURVIVAL
        if live_neighbors == 2 or live_neighbors == 3:
            return true  # Stays alive
        else:
            return false  # Dies (underpopulation or overcrowding)
    else:
        # BIRTH
        if live_neighbors == 3:
            return true  # Becomes alive (reproduction)
        else:
            return false  # Stays dead

# Summary:
# - Any live cell with 2-3 neighbors survives
# - Any dead cell with exactly 3 neighbors becomes alive
# - All other cells die or stay dead
[/code]

**That's it.** Four cases. Yet infinite complexity emerges.

[hr]

[b]Still Lifes: Stable Patterns[/b]

Some patterns never change - they are **stable** (equilibrium).

[color=yellow][b]Block (2×2):[/b][/color]
[code]
▓▓
▓▓

# Each cell has 3 live neighbors
# All survive forever (never die, no births)
# Simplest still life
[/code]

[color=yellow][b]Beehive:[/b][/color]
[code]
 ▓▓
▓  ▓
 ▓▓

# More complex still life
# Stable configuration
[/code]

**Still lifes = fixed points** - patterns where next generation = current generation.

Like equilibrium in physics, but **emergent** (not built-in, discovered through rules).

[hr]

[b]Oscillators: Periodic Patterns[/b]

Some patterns repeat with period 2, 3, or more.

[color=yellow][b]Blinker (Period 2):[/b][/color]
[code]
# Generation 0:
▓▓▓

# Generation 1:
 ▓
 ▓
 ▓

# Generation 2:
▓▓▓  (back to start)

# Oscillates between horizontal and vertical
[/code]

[color=yellow][b]Pulsar (Period 3):[/b][/color]
Large 13×13 pattern that cycles every 3 generations.

**Oscillators = periodic orbits** - temporal structure emerging from spatial rules.

[hr]

[b]Gliders: Moving Patterns[/b]

**This is where Life becomes profound:**

[color=yellow][b]The Glider:[/b][/color]
[code]
# Generation 0:
 ▓
  ▓
▓▓▓

# Generation 1:
▓ ▓
 ▓▓
 ▓

# Generation 2:
  ▓
▓ ▓
 ▓▓

# Generation 3:
 ▓
  ▓▓
 ▓▓

# Generation 4:
  ▓
   ▓
 ▓▓▓

# Pattern has MOVED diagonally (one cell down-right)
# Repeats every 4 generations, shifting position
[/code]

**The glider is a traveling wave** - 5 cells that move diagonally across the grid.

It **appears** to be a persistent object, but actually: every 4 generations, the pattern recreates itself one cell over.

**No object persists. Only pattern persists.**

[hr]

[b]Spaceships: Faster Travelers[/b]

**Lightweight spaceship (LWSS):**
Travels horizontally, period 4, moves 2 cells per cycle.

**Glider gun:**
Stationary pattern that **emits gliders** periodically (every 30 generations).

[color=yellow][b]Code Concept:[/b][/color]
[code]
# Glider gun creates infinite stream of gliders
# Gliders travel across grid
# Can collide with other patterns
# Can be used as signals

# This is the beginning of COMPUTATION
# Gliders = data
# Collisions = logic gates
[/code]

**Glider guns enable computation** - steady stream of moving patterns that can interact.

[hr]

[b]Computational Universality: Life Can Compute[/b]

**Proven (1982):** Life is **Turing-complete** - can simulate any computer.

How?
1. **Gliders = bits** (presence/absence of glider = 1/0)
2. **Collisions = logic gates** (AND, OR, NOT built from glider interactions)
3. **Streams = wires** (glider paths carry data)
4. **Patterns = memory** (stable configurations store state)

[color=yellow][b]Conceptual Computer in Life:[/b][/color]
[code]
# AND gate (simplified):
# Two glider streams intersect
# If both gliders present: collision creates output glider
# If one missing: no output
# This is logical AND

# NOT gate:
# Glider stream meets periodic oscillator
# Destroys glider = output is ABSENCE
# Inverts signal

# Combine gates → circuits → CPU → computer
# All from Life's four rules
[/code]

**Life can run Tetris, simulate itself, compute anything a computer can.**

No separate "computation layer" - computation **emerges** from the rules.

[hr]

[b]What Does This Mean?[/b]

Life proves:
1. **Simple rules ≠ simple behavior**
2. **Computation is emergent** (not designed, arises naturally)
3. **Objects are patterns** (glider is not thing, but process)
4. **No central control** (no CPU, no orchestrator - everything local)
5. **Universality is generic** (complex systems default to Turing-complete)

**Conway didn't design gliders.** He found four rules. Gliders **discovered themselves** through iteration.

**This is the core lesson:** **Complexity self-organizes from simple local interactions.**

[hr]

[b]Methuselahs: Small → Large[/b]

Some small patterns take thousands of generations to stabilize.

**Acorn (7 cells):**
Takes **5,206 generations** to stabilize into 633 cells.

[color=yellow][b]Code:[/b][/color]
[code]
# Initial: 7 cells
 ▓
   ▓
▓▓  ▓▓▓

# After 5206 generations:
# → Hundreds of gliders
# → Dozens of still lifes
# → Complex ecosystem

# Small input, enormous output
# Computational irreducibility - must simulate all 5206 steps
[/code]

**Cannot predict Acorn's final state without running simulation.**

This is **computational irreducibility** again - no shortcut, must iterate.

[hr]

[b]Life as Physics Simulator[/b]

Life can simulate:
- **Fluid dynamics** (glider streams behave like particles)
- **Wave propagation** (patterns spread like waves)
- **Crystal growth** (stable patterns accumulate)

**Is this metaphor or truth?**

If universe is cellular automaton, then:
- Particles = stable patterns (like gliders)
- Forces = pattern interactions (like collisions)
- Physical laws = CA rules

**Life suggests:** Physics might be **emergent** from discrete computational substrate, not fundamental.

[hr]

[b]Conway's Regret and Hope[/b]

John Conway later said he was frustrated Life became his most famous work - he considered it trivial recreation.

But Life revealed:
- **Emergence is unavoidable** (complexity appears without intent)
- **Computation is everywhere** (universal capability in simple systems)
- **Universes can be invented** (Life is self-contained cosmos)

**Life is not game. It is universe simulator.**

Every configuration = different universe timeline.
Every initial state = different history.

[hr]

[b]Self-Replication in Life[/b]

**Gemini spaceship:** Travels, leaves behind copy of itself.

**Universal constructor:** Pattern that can build any other pattern (including itself).

[color=yellow][b]Implication:[/b][/color]
If Life can support self-replication, and Life is Turing-complete, then **Life can evolve**.

- Random initial conditions
- Self-replicating patterns emerge
- Mutations (random bit flips)
- Selection (stable patterns persist)

**Life + randomness + time = potential for open-ended evolution.**

Has anyone created **evolving artificial life in Life?** Yes. Projects exist where Life patterns compete, replicate, mutate.

**Artificial life in artificial universe.**

[hr]

[b]What Game of Life Reveals[/b]

Conway's Life shows us:

1. **Four rules create infinity** (birth, survival, death, underpopulation/overcrowding)
2. **Gliders = persistent patterns** (objects are processes, not things)
3. **Computation emerges** (Turing-complete from local rules)
4. **No central control** (distributed, local, emergent)
5. **Small → enormous** (Acorn: 7 cells → 633 cells after 5206 generations)
6. **Self-replication possible** (patterns that copy themselves)
7. **Irreducibility** (must simulate, cannot predict analytically)

**Life is proof of concept:** **Complex universes can arise from simple rules.**

If Life (4 rules, 2D grid) creates gliders, computers, self-replicators - what does our universe (quantum mechanics, relativity, 3D+time) create?

**Maybe consciousness is just a very complex glider.**

[hr]

[color=cyan][b]Summary:[/b][/color]
Conway's Game of Life: 2D CA with four rules (survive with 2-3 neighbors, birth with exactly 3). Creates still lifes (stable), oscillators (periodic), gliders (moving patterns that persist). Computationally universal (Turing-complete) - can build logic gates, circuits, computers from glider collisions. Methuselahs (small patterns → huge outcomes after thousands of generations). Self-replication possible. Proof: simple local rules → emergent complexity, computation, potentially artificial life.

[hr]

[color=orange][b]Next:[/b] Computational Irreducibility[/color]
The paradox Wolfram discovered: **deterministic yet unpredictable**.
Some systems have no shortcut - must simulate to know outcome.
If universe is CA, this means: **future is unknowable even in deterministic cosmos**.
Science has limits. Reductionism fails. Must run the universe to see what happens.

'''
