# Grammar Systems

Algorithms that generate sequences from rules — Markov chains, n-grams, and probabilistic grammars.

## QFEP Connection

Grammars are **structured randomness**. A Markov chain has transition probabilities (F, rules) that govern what comes next, but the actual sequence is stochastic (E, chance). Over time, chains converge to stationary distributions — chaos becoming predictable statistics.

## Contents

### Markov Chains (`markov_chains/`)

Each state has probabilities of transitioning to other states:

```
     0.7
  ╭──────╮
  │      ▼
┌───┐  0.3  ┌───┐
│ A │──────▶│ B │
└───┘◀──────└───┘
       0.4    │
              │0.6
              ▼
            ┌───┐
            │ C │
            └───┘
```

Features:
- **Visual states**: 3D spheres representing chain states
- **Transition arrows**: Weighted by probability
- **Probability selector**: "Dice roll" animation
- **Frequency display**: Stationary distribution emergence

### Markov Chain Trees (`markov_chains_tree/`)

Hierarchical Markov structures with tree-based state spaces.

## Core Concepts

### Transition Matrix

```
       To:  A    B    C
From:
  A      [0.3, 0.7, 0.0]
  B      [0.4, 0.0, 0.6]
  C      [0.2, 0.3, 0.5]
```

Each row sums to 1.0 (must go somewhere).

### Stationary Distribution

After many steps, visit frequencies converge:
```gdscript
# Eventually stabilizes regardless of start state
lim P^n → [π_A, π_B, π_C]
```

### Entropy and Convergence

- **High entropy**: Uniform transition probabilities (unpredictable)
- **Low entropy**: Deterministic transitions (predictable)
- **Convergence rate**: How fast distribution stabilizes

## Parameters

| Variable | Default | Description |
|----------|---------|-------------|
| `state_count` | 5 | Number of states |
| `sequence_length` | 20 | Generated sequence length |
| `step_interval` | 1.5 | Seconds between transitions |

## Visualization Features

- **States**: Colored spheres in 3D space
- **Transitions**: Animated arrows with probability labels
- **Probability selector**: Shows the "random choice" process
- **Frequency bars**: Tracks visit distribution over time

## Files

| Folder | Contents |
|--------|----------|
| `markov_chains/` | Basic Markov chain visualization |
| `markov_chains_tree/` | Tree-structured chains |

## Usage

```gdscript
var markov = preload("res://algorithms/proceduralgeneration/grammar_systems/markov_chains/markov_chains.tscn").instantiate()
add_child(markov)
```

## Applications

Markov chains model:
- **Text generation**: Character or word sequences
- **Music**: Note progressions
- **Weather**: State transitions over time
- **Games**: NPC behavior patterns
- **Economics**: Market state transitions

## VR Experience

Watch the chain hop between states. The probability selector shows the "dice roll" — which edge will be taken? Over time, the frequency bars reveal the stationary distribution — some states get visited more often, regardless of where you started.

## See Also

- `lsystems/` — Deterministic grammar rewriting
- `randomness/` — Pure stochastic processes
- `wfc/` — Constraint-based generation
