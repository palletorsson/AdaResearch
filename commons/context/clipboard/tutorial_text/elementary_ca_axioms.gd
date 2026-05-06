extends Node

# Tutorial content file
# Edit using the Tutorial Text Editor plugin

var text = '''[center][font_size=28][b]Elementary Cellular Automata[/b][/font_size][/center]
[center][i]Wolfram's Rules: Simple → Complex[/i][/center]

In 1983, Stephen Wolfram began systematically studying the simplest possible cellular automata: **1D grids where each cell looks only at itself and its two neighbors**.

There are exactly **256 possible rules** (2^8 combinations of three-cell neighborhoods).

From these simple rules, **astonishing complexity emerges**:
- **Rule 30** generates randomness from order (chaotic)
- **Rule 110** is **computationally universal** (can simulate any computation)
- **Rule 184** simulates traffic flow

**Simple local rules → complex global behavior.**

This is Wolfram's thesis: **Complexity is not rare. It is generic.** Even the simplest systems produce it.

[hr]

[b]The Structure: 1D Grid, Local Rules[/b]

An elementary CA is a line of cells, each either **0** (dead/white) or **1** (alive/black).

[color=yellow][b]Code: The Grid[/b][/color]
[code]
# Generation 0 (initial state)
var cells = [0, 0, 0, 0, 1, 0, 0, 0, 0]
#                         ↑
#                   Single alive cell

# Each generation, apply rule to compute next generation
# Cell's new state depends on:
# - Left neighbor
# - Self
# - Right neighbor
[/code]

**Rule = lookup table** mapping each 3-cell neighborhood to next state.

[hr]

[b]Rule Encoding: Binary Numbers as Instructions[/b]

A rule is encoded as **8-bit binary number** (0-255).

[color=yellow][b]Example: Rule 30[/b][/color]
[code]
# Rule 30 in binary: 00011110

# Neighborhoods (left, center, right):
# 111 → 0  (binary position 7)
# 110 → 0  (position 6)
# 101 → 0  (position 5)
# 100 → 1  (position 4)  ← Rule 30 has '1' here
# 011 → 1  (position 3)
# 010 → 1  (position 2)
# 001 → 1  (position 1)
# 000 → 0  (position 0)

# Function to apply rule 30:
func apply_rule_30(left: int, center: int, right: int) -> int:
    var pattern = left * 4 + center * 2 + right  # 0-7
    var rule_30 = 0b00011110  # Binary: 30
    return (rule_30 >> pattern) & 1  # Extract bit at position

# Simple lookup, yet creates chaos
[/code]

**The rule number encodes all behavior.** Rule 30 ≠ Rule 110 ≠ Rule 184.

Eight bits determine universe.

[hr]

[b]Rule 30: Chaos from Order[/b]

Start with single alive cell. Apply Rule 30.

[color=yellow][b]Result:[/b][/color]
[code]
# Generation 0:              ▓
# Generation 1:             ▓▓▓
# Generation 2:            ▓▓  ▓
# Generation 3:           ▓▓ ▓▓▓▓
# Generation 4:          ▓▓  ▓   ▓
# Generation 5:         ▓▓ ▓▓▓▓ ▓▓▓
# ...
# After 30 generations: chaotic triangle pattern

# Looks RANDOM (passes statistical randomness tests)
# But completely DETERMINISTIC (same initial state → same pattern)
[/code]

**Rule 30 generates pseudo-randomness.**

Wolfram used it to create random number generators. The leftmost column produces statistically random bit sequence.

**Deterministic chaos** - like PRNG, but spatially distributed instead of temporally sequential.

[hr]

[b]Rule 110: Computational Universality[/b]

Rule 110 is **Turing-complete** - it can simulate any computation.

[color=yellow][b]What This Means:[/b][/color]
[code]
# Rule 110 can:
# - Perform arithmetic (addition, multiplication)
# - Implement logic gates (AND, OR, NOT)
# - Store and retrieve memory
# - Simulate any other computer program

# ALL from three-cell neighborhood lookup table

# Proven by Matthew Cook (1998)
# Rule 110 is as powerful as any general-purpose computer
[/code]

**This is shocking:**
- The simplest possible system (1D CA)
- The simplest possible rule (8-bit lookup)
- Yet **computationally universal** (can do anything a computer can)

**Computation is not rare.** Even trivial systems can be universal.

[hr]

[b]The Four Classes (Wolfram Classification)[/b]

Wolfram categorized all 256 elementary CA rules into **four classes**:

**Class 1: Uniform**
- Evolves to homogeneous state (all 0 or all 1)
- Boring, predictable
- Example: Rule 0 (always outputs 0)

**Class 2: Periodic**
- Creates repeating patterns
- Stable structures
- Example: Rule 4 (vertical stripes)

**Class 3: Chaotic**
- Random-looking, no structure
- Like Rule 30 (pseudo-random)
- Example: Rule 30, Rule 45

**Class 4: Complex**
- **Edge of chaos**
- Mix of order and randomness
- Can support computation
- Example: **Rule 110**, Rule 54

**Class 4 is special** - not too ordered, not too chaotic. **This is where computation happens.**

[hr]

[b]Computational Irreducibility: The Core Paradox[/b]

For Rule 110 (and most Class 4 rules), **you cannot predict the outcome without running the simulation**.

[color=yellow][b]The Paradox:[/b][/color]
[code]
# Question: What is state of cell 500 at generation 1000?

# Attempted shortcut:
# - Analyze rule mathematically
# - Find closed-form equation
# - Calculate directly

# Wolfram's claim: IMPOSSIBLE

# Only way to know: RUN THE SIMULATION
for generation in range(1000):
    cells = apply_rule(cells)  # Must iterate all 1000 steps

# Cannot skip ahead
# Cannot predict analytically
# Computation is IRREDUCIBLE
[/code]

**This is computational irreducibility:**
- Some systems have no shortcut
- Simulation is the fastest way to know outcome
- Even though deterministic, effectively unpredictable

**Determinism ≠ Predictability**

[hr]

[b]Why Irreducibility Matters[/b]

If universe is computationally irreducible:
- **Science has limits** - Some phenomena cannot be reduced to simple equations
- **Must simulate** - Cannot derive outcome analytically (like weather prediction)
- **Future is unknowable** - Even in deterministic universe, must "run" time to see what happens

[color=yellow][b]Philosophical Implication:[/b][/color]
[code]
# Traditional physics: find equation, predict future
F = ma  # Simple law → predict particle trajectory

# Irreducible systems: no simple equation exists
# Must simulate step-by-step
# No analytical solution
# Future emerges through iteration, not calculation
[/code]

**Reductionism fails** for computationally irreducible systems.

You cannot compress Rule 110's behavior into simpler form. **The rule IS the simplest description.**

[hr]

[b]Equivalence Principle: Almost Everything Is Universal[/b]

Wolfram's **Principle of Computational Equivalence**:

**"Almost all processes that are not obviously simple can be viewed as computations of equivalent sophistication."**

[color=yellow][b]What This Means:[/b][/color]
- Rule 110 (simple CA) = **Turing-complete**
- Game of Life (2D CA) = **Turing-complete**
- Tag systems, cyclic tag systems = **Turing-complete**
- Probably: fluid dynamics, quantum mechanics, brain = **computationally equivalent**

**Computation is not special property of brains or computers. It is generic property of complex systems.**

[hr]

[b]Is the Universe a Cellular Automaton?[/b]

Wolfram's controversial thesis (*A New Kind of Science*, 2002):

**The universe might BE a cellular automaton** - discrete space-time grid running simple local rules.

[color=yellow][b]Evidence For:[/b][/color]
- **Quantum mechanics** suggests discrete (Planck length, Planck time)
- **Local interactions** - no action at distance (relativity)
- **Simple laws** - physics equations remarkably compact
- **Emergent complexity** - universe creates galaxies, life, consciousness from simple rules

[color=yellow][b]Evidence Against:[/b][/color]
- **Continuous symmetries** - Lorentz invariance, gauge symmetries seem continuous
- **Non-locality** - Quantum entanglement (though CA can simulate)
- **No grid found** - No experimental evidence for discrete space grid yet

[color=yellow][b]Code: Universe as CA (Speculative)[/b][/color]
[code]
# If universe is CA:
var space_time_grid = [[[...]]]  # 3D spatial + 1D time grid
var rule = UNKNOWN_SIMPLE_RULE   # Physics = lookup table?

func advance_universe():
    # Each Planck time step
    for x in range(UNIVERSE_WIDTH):
        for y in range(UNIVERSE_HEIGHT):
            for z in range(UNIVERSE_DEPTH):
                # Local rule determines next state
                space_time_grid[x][y][z] = rule(neighborhood(x,y,z))

# All physics emerges from this iteration
# Particles, forces, consciousness = patterns in CA
[/code]

**If true:** Universe is giant computer running itself. No external time, no external space. Just iteration.

[hr]

[b]What Elementary CA Reveals[/b]

Elementary cellular automata show us:

1. **Simple rules → complex behavior** (Rule 30 chaos from 8 bits)
2. **Computation is generic** (Rule 110 Turing-complete)
3. **Four classes** (uniform, periodic, chaotic, complex)
4. **Class 4 = edge of chaos** (where computation happens)
5. **Computational irreducibility** (must simulate, cannot predict analytically)
6. **Equivalence principle** (almost all complex systems computationally equivalent)
7. **Universe as CA?** (discrete space-time, local rules, emergent complexity)

**Wolfram's insight:** **Complexity is not rare, expensive, or special. It emerges from the simplest possible rules.**

You don't need evolution, natural selection, intelligent design. **Just iterate local rules. Complexity appears.**

[hr]

[color=cyan][b]Summary:[/b][/color]
Elementary CA: 1D grid, each cell looks at self + two neighbors, applies rule (8-bit lookup table). 256 possible rules. Rule 30 generates chaos (pseudo-random). Rule 110 is Turing-complete (computationally universal). Four classes: uniform, periodic, chaotic, complex (Class 4 = edge of chaos). Computational irreducibility: must simulate to know outcome, no analytical shortcut. Wolfram's thesis: universe might be cellular automaton - discrete space-time running simple local rules.

[hr]

[color=orange][b]Next:[/b] Game of Life - 2D Emergence[/color]
If 1D CA create chaos and universality,
2D CA create **gliders, spaceships, self-replicators**.
Conway's Life: four simple rules, infinite emergent complexity.
Patterns that move, reproduce, compute.

'''
