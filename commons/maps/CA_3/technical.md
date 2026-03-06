# One dimension, 256 possible universes, and the entire spectrum from extinction to universal computation encoded in a single byte

CA_2 explored one rule in two dimensions. B3/S23 produced still lifes, oscillators, gliders, guns, Turing completeness — an entire ecology from four conditionals on a Moore neighborhood. The richness was staggering but the rule was fixed. How special is B3/S23? Is that complexity a property of one carefully chosen rule, or does it arise naturally across rule space? CA_3 answers by dropping a dimension and surveying the entire landscape. One-dimensional elementary cellular automata strip the machinery to its minimum — two states, three-cell neighborhoods, 256 total rules — and reveal that complexity is not rare. It clusters at a boundary between order and chaos, accessible by tuning a single integer.

## The Elementary Rule Space

An elementary cellular automaton operates on a 1D array of binary cells. Each cell examines itself and its two immediate neighbors — left, center, right. Three binary values produce 2^3 = 8 possible input configurations. A rule must assign an output (0 or 1) to each configuration. The number of distinct rules is 2^8 = 256. The complete space of elementary cellular automata fits in one byte.

```gdscript
const NUM_CONFIGS: int = 8    # 2^3 possible neighborhoods
const NUM_RULES: int = 256    # 2^8 possible output tables
const CELL_STATES: int = 2    # binary

var cells: Array[int] = []
var width: int = 128

func _ready() -> void:
    cells.resize(width)
    cells.fill(0)
    cells[width / 2] = 1  # single seed at center
```

A row of zeros with one central 1. The canonical initial condition. From this seed, the rule determines everything — symmetry, growth rate, periodicity, randomness, computational capacity. The initial condition is fixed. The rule is the only variable. One byte. 256 experiments.

The reduction from CA_2's setup is deliberate. By stripping the machinery to a flat array, two neighbors, and a lookup, any complexity in the output must come from the rule itself. There is nowhere else for it to hide.

## Rule Numbering: The Integer as Lookup Table

Wolfram's encoding is direct. The 8 possible three-cell neighborhoods are ordered from 111 (index 7) down to 000 (index 0). The rule number, expressed in binary, provides the output bit for each index. The rule is its own lookup table.

```gdscript
func wolfram_rule(rule_number: int, left: int, center: int, right: int) -> int:
    var index: int = (left << 2) | (center << 1) | right
    return (rule_number >> index) & 1
```

Three cells become a 3-bit index. The rule number's bit at that position is the output. No branching. No conditionals. A single bitwise extraction. Rule 30 in binary is `00011110`. Rule 110 is `01101110`. Rule 0 is `00000000` — every neighborhood maps to 0, the automaton dies instantly. Rule 255 is `11111111` — every neighborhood maps to 1, the grid fills and freezes.

The encoding collapses specification into arithmetic. The rule is not a program. It is a number. Change the number, change the universe. This is what makes the elementary CA space a laboratory: 256 universes, exhaustively enumerable, each derivable from a single integer by bit extraction.

```gdscript
func print_rule_table(rule_number: int) -> void:
    for index in range(7, -1, -1):
        var left: int = (index >> 2) & 1
        var center: int = (index >> 1) & 1
        var right: int = index & 1
        var output: int = (rule_number >> index) & 1
        print("%d%d%d -> %d" % [left, center, right, output])
```

Eight lines. The complete specification of a universe. Every elementary CA that has ever been studied — Rule 30, Rule 110, Rule 90, all of them — reduces to this table. The `structure_growth` artifact builds its evolution from exactly this function — a rule number fed into the bit-extraction lookup, applied across the row, generation after generation. The artifact does not hardcode behavior. It reads the rule number and the behavior follows.

The encoding invites a question the 2D case could not ask: what happens across all rules? Switching from Rule 30 to Rule 110 requires changing one integer. The entire parameter space is a single axis from 0 to 255. Sweepable. Searchable. Exhaustible.

## Evolving Generations: Rows Become History

In 2D automata, each generation overwrites the previous — the grid is a snapshot of the present. In 1D, a different visualization is natural. Each generation occupies one row. Time flows downward. The complete history of the automaton appears as a 2D image where the horizontal axis is space and the vertical axis is time.

```gdscript
var history: Array[Array] = []
var generations: int = 100

func evolve(rule_number: int) -> void:
    history.clear()
    history.append(cells.duplicate())

    for gen in generations:
        var next: Array[int] = []
        next.resize(width)
        for i in width:
            var left: int = cells[posmod(i - 1, width)]
            var center: int = cells[i]
            var right: int = cells[posmod(i + 1, width)]
            next[i] = wolfram_rule(rule_number, left, center, right)
        cells = next
        history.append(cells.duplicate())
```

No double buffer needed — the entire next row is computed from the current row and then replaces it. The 1D case simplifies the synchronous update because new and old arrays are separate by construction. Each row in `history` is a frozen generation. Stack them and the spacetime diagram appears — the triangular cascade from a single seed, spreading outward at one cell per generation.

The `structure_growth` artifact renders this spacetime diagram directly. Each cell in the diagram encodes one state at one point in space and time. Black for 1, white for 0. The learner sees not just the current generation but the entire causal history — which cells produced which offspring, how patterns propagate, where structure appears and where it dissolves.

The spacetime diagram is the fundamental object of study for 1D automata. In 2D, each generation is a full image — too large to archive visually. In 1D, every generation is a single row. A hundred generations fit in a single screen. The eye traces lineages — which cell at generation 50 influenced which cell at generation 51. Causality becomes spatial.

## Wolfram's Four Classes

Not all 256 rules are distinct — many are equivalent under reflection, complement, or both. But the effective variety demands classification. Wolfram proposed four behavioral classes based on the long-term evolution from generic initial conditions.

**Class I: Homogeneity.** The automaton converges to a uniform state. Every cell reaches the same value and stays there. Rule 0, Rule 255, Rule 32. The spacetime diagram is a triangle of activity that collapses into a solid field. Information is destroyed. Entropy drops to zero.

**Class II: Periodicity.** The automaton settles into stable or periodic structures. Fixed blocks that persist, oscillators that repeat, but no long-range propagation. Rule 4, Rule 108, Rule 184. The spacetime diagram shows stripes, checkerboards, repeating tiles. Information is conserved locally but does not travel. These are the still lifes and blinkers of the 1D world.

**Class III: Chaos.** The automaton produces aperiodic, apparently random patterns that fill the available space. Rule 30, Rule 45, Rule 73. The spacetime diagram looks like static — no discernible structure at any scale. Statistical tests struggle to distinguish the output from genuine randomness. Information is generated continuously. Entropy is high and does not decrease.

**Class IV: Complexity.** The automaton produces localized structures that interact — propagating particles, collisions that produce new structures, long transients before settling. Rule 110, Rule 54, Rule 124. The spacetime diagram shows a background texture punctuated by coherent structures that move, collide, and transform. Neither order nor chaos. The boundary between them.

```gdscript
# Representative rules from each class
const CLASS_I: Array[int] = [0, 32, 160, 255]
const CLASS_II: Array[int] = [4, 108, 132, 184]
const CLASS_III: Array[int] = [30, 45, 73, 105]
const CLASS_IV: Array[int] = [54, 110, 124, 137]
```

The classification is empirical, not proven. No formal criterion separates Class III from Class IV in all cases. Wolfram defined them by observation. Langton's lambda parameter later provided a quantitative proxy — a single number measuring the fraction of output bits that are 1 — and the classes arrange along the lambda spectrum roughly in order: I, II, IV, III. Complexity concentrates near a critical lambda value. The edge of chaos is a region in parameter space.

## Rule 30: Order Collapsing Into Chaos

Rule 30 is the canonical Class III automaton. Binary: `00011110`. From a single central seed, it produces a spacetime diagram that is asymmetric, aperiodic, and statistically random on the left side while the right side displays nested triangular structure.

```gdscript
func demonstrate_rule_30() -> void:
    cells.fill(0)
    cells[width / 2] = 1
    evolve(30)
    # Left half: chaotic, passes NIST randomness tests
    # Right half: nested triangles, self-similar
    # Center column: no known period, conjectured aperiodic
```

The center column of Rule 30 has been studied for decades. No period has been found. It is conjectured aperiodic — a sequence of 0s and 1s that never repeats. Mathematica used Rule 30 as its default pseudorandom number generator for years. A deterministic process with a known rule, producing output that resists prediction.

The asymmetry is instructive. The rule treats left and right neighbors differently — `(left << 2)` weights the left neighbor more heavily than `right`. The single central seed is symmetric. The rule is not. Asymmetry in the output is inherited directly from asymmetry in the encoding. Swap left and right in the index computation and the mirror image appears.

Rule 30 demonstrates that chaos does not require complex rules. It requires asymmetry, nonlinearity (the XOR-like structure of the output table), and iteration. Three cells, one byte, unbounded apparent randomness. The information content of the output exceeds the information content of the input by any practical measure — the system is an entropy generator.

The contrast with CA_2 is sharp. Life's chaos required specific initial conditions — a random soup, a perturbed structure. Rule 30's chaos requires nothing but a single 1 in a field of zeros. The chaos is not in the input. It is in the rule. The rule manufactures entropy from order, generation after generation, without external stimulus.

## Rule 110: Complexity and Turing Completeness

Rule 110 is Class IV. Binary: `01101110`. Its spacetime diagram from a single seed shows a complex background texture — repeating triangular structures at multiple scales — punctuated by localized "particles" that propagate at different velocities and interact through collisions.

```gdscript
func demonstrate_rule_110() -> void:
    cells.fill(0)
    cells[width / 2] = 1
    evolve(110)
    # Background: periodic tiling, period 14 in time
    # Particles: glider-like structures moving left and right
    # Collisions: particles annihilate, reflect, or spawn new particles
```

Matthew Cook proved in 2004 that Rule 110 is Turing complete. The proof is constructive: it encodes any computation as an initial condition such that the automaton's evolution performs it. Particles serve as signals. Collisions implement logic gates. The periodic background provides the clock. A one-dimensional, two-state, nearest-neighbor automaton — the simplest nontrivial substrate — can simulate any algorithm.

The significance extends beyond Rule 110. Computational universality does not require complex machinery. No 2D grid. No Moore neighborhood. No multi-state cells. Three cells, two states, one rule. Universality is a property of the boundary between order and chaos — exactly where Class IV lives.

```gdscript
# Detecting glider-like structures in Rule 110 output
func find_particles(history: Array[Array], gen: int) -> Array[int]:
    var particles: Array[int] = []
    if gen < 2:
        return particles
    for i in range(1, width - 1):
        var current: int = history[gen][i]
        var above: int = history[gen - 1][i]
        var above_left: int = history[gen - 1][posmod(i - 1, width)]
        # A particle is a deviation from the periodic background
        # Background period is 14; deviations propagate
        if current != above and current != above_left:
            particles.append(i)
    return particles
```

The detection is heuristic — the periodic background has a known pattern, and anything that breaks periodicity is a candidate particle. In practice, Rule 110's particles are catalogued: there are a finite number of species, each with a known velocity and collision behavior. The particle taxonomy is Rule 110's equivalent of Life's still lifes, oscillators, and gliders — persistent structures that serve as the vocabulary of computation.

Where Life needed two dimensions and a Moore neighborhood to achieve universality, Rule 110 achieves it in one dimension with nearest neighbors. The computational overhead shifts to temporal depth — computations take vastly more generations. But the theoretical result is identical. Universality requires only enough structure to support persistent interacting signals. Class IV provides it. Class III destroys it with noise. Class II lacks it entirely.

## Lambda and the Edge of Chaos

Langton's lambda parameter provides a crude but useful measure of a rule's character. For an elementary CA, lambda is the fraction of the 8 output bits that are 1.

```gdscript
func compute_lambda(rule_number: int) -> float:
    var ones: int = 0
    for bit in 8:
        ones += (rule_number >> bit) & 1
    return float(ones) / 8.0
```

Lambda ranges from 0.0 (Rule 0, all outputs dead) to 1.0 (Rule 255, all outputs alive). The classes distribute along this axis. Class I rules cluster near the extremes — lambda near 0 or near 1. Class II rules occupy moderate lambda values. Class III rules appear at higher lambda. Class IV rules concentrate near a critical value, approximately 0.5 for binary automata, where the transition from periodic to chaotic behavior occurs.

The edge of chaos is this critical region. Below it, activity dies or freezes. Above it, activity overwhelms structure with noise. At the boundary, the tendencies balance. Structure persists long enough to interact but not so long that it freezes. Information propagates but does not dissipate. Computation becomes possible.

Rule 110 has lambda = 6/8 = 0.75. Rule 30 has lambda = 4/8 = 0.5. Lambda does not perfectly predict class — rules with identical lambda can belong to different classes. But the trend holds: sweep lambda from 0 to 1 and the characteristic sequence is I, II, IV, III, II, I. Complexity peaks at the phase transition. This parallels Kauffman's NK model in biology and the critical temperature in statistical physics.

## Equivalences and Symmetries

Many of the 256 rules are related by symmetry. Reflecting a rule — swapping left and right in every configuration — produces the mirror rule. Complementing — swapping 0 and 1 in both inputs and outputs — produces the complement. Applying both produces the reflected complement.

```gdscript
func reflect_rule(rule_number: int) -> int:
    var reflected: int = 0
    for index in 8:
        var left: int = (index >> 2) & 1
        var center: int = (index >> 1) & 1
        var right: int = index & 1
        # Swap left and right to get reflected index
        var reflected_index: int = (right << 2) | (center << 1) | left
        var output: int = (rule_number >> index) & 1
        reflected |= (output << reflected_index)
    return reflected

func complement_rule(rule_number: int) -> int:
    var complemented: int = 0
    for index in 8:
        var comp_index: int = 7 - index  # flip all input bits
        var output: int = (rule_number >> index) & 1
        var comp_output: int = 1 - output  # flip output bit
        complemented |= (comp_output << comp_index)
    return complemented
```

Rule 30's reflection is Rule 86 — the same spacetime diagram mirrored horizontally. Rule 30's complement is Rule 135. Rule 110's reflection is Rule 124, itself a Class IV rule. The four-member equivalence group {110, 124, 137, 193} all produce the same dynamical behavior up to spatial and chromatic inversion.

These equivalences reduce 256 rules to 88 essentially distinct behaviors. The reduction matters for the survey: instead of running 256 experiments, 88 suffice. The `structure_growth` artifact could cycle through all 88 equivalence classes and display a representative from each, compressing the full landscape into a manageable gallery.

## From 1D to the Sequence

The reduction from 2D to 1D is not a retreat. It is a controlled experiment. CA_2's Life operates in a rule space too large to survey — 2D totalistic rules with Moore neighborhood exceed practical enumeration. Elementary CA collapses that space to 256 members. Small enough to enumerate. Rich enough to contain all four behavioral classes. Sharp enough to isolate the transitions between them.

The progression across the sequence is now clear. CA_1 introduced the grid, the neighborhood, the synchronous update — the infrastructure. CA_2 applied one rule and found an ecology. CA_3 surveys all rules in the minimal case and discovers that the ecology is not accidental. Complexity is a structural feature of the rule space, concentrated at the edge of chaos. CA_4 will generalize — totalistic rules, larger neighborhoods, more states — and the question becomes whether the four-class structure persists as the parameter space expands.

The `structure_growth` artifact anchors this map. It renders the spacetime evolution of an elementary CA, generation by generation, revealing how pattern complexity develops over time. The learner selects a rule number — or sweeps through them — and watches the cascade: extinction, periodicity, chaos, complexity. Four classes, one mechanism, 256 variations. The full landscape visible from a single vantage point.

## Possible Artifacts

**rule_comparison_wall** — A grid displaying the spacetime diagrams of all 88 equivalence classes simultaneously, tiled in lambda order. Each diagram runs from the canonical single-seed initial condition for 64 generations. The wall makes the class structure visible at a glance — dead zones at the margins, periodic stripes in the middle, chaotic static and complex particles near the critical region. Selecting any diagram expands it and displays the rule number, binary encoding, lookup table, and lambda value.

**particle_tracker** — A Rule 110 spacetime viewer with particle detection overlay. The periodic background is rendered in muted tones. Deviations from periodicity — the propagating particles — are highlighted in contrasting color with velocity vectors drawn alongside. Collisions flash at the intersection point, and the resulting particle species is labeled. The learner sees computation happening: signals meeting, transforming, propagating.

**lambda_sweep** — An animated transition through rule space ordered by lambda. A single spacetime diagram updates in real-time as lambda increases from 0 to 1, interpolating between representative rules at each value. The phase transition from Class I through II, IV, III and back becomes a continuous visual experience — the moment when frozen stripes shatter into living complexity, then dissolve into noise.

**seed_sensitivity_comparator** — Two side-by-side spacetime diagrams running the same rule from initial conditions that differ by a single cell. A difference overlay highlights diverging cells generation by generation. For Class I and II rules, divergence is local and bounded. For Class III rules, divergence is global and exponential. For Class IV rules, divergence propagates along particle trajectories — the intermediate case where sensitivity is structured rather than uniform.
