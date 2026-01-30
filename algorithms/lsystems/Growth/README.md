# Animated L-System Tree

Watch a tree grow step-by-step — each generation adds more branches according to L-System rewriting rules.

## QFEP Connection

L-Systems are **grammar-based growth** — a simple axiom and rules generate infinite complexity. The order (F) comes from the deterministic grammar; the apparent chaos (E) emerges from recursive application. This animation makes visible the generation process usually hidden in instant rendering.

## How It Works

```
Generation 0:  |        (axiom: just a trunk)
               
Generation 1:  |
              /|\
                    
Generation 2:  |
             / | \
            /| | |\
           
Generation N: Full tree
```

The L-System used is a "Fractal Plant" variant:

```
Axiom: X
Rules:
  X → F+[[X]-X]-F[-FX]+X
  F → FF
```

Where:
- `F` = move forward, draw branch
- `+` = turn right
- `-` = turn left
- `[` = push state (start branch)
- `]` = pop state (end branch)
- `X` = growth point (replaced by complex pattern)

## Parameters

| Export | Default | Description |
|--------|---------|-------------|
| `max_iterations` | 5 | Final generation count |
| `step_length` | 0.3 | Branch segment length |
| `base_angle` | 25.0 | Branching angle (degrees) |
| `growth_delay` | 1.5 | Seconds between generations |
| `initial_thickness` | 0.08 | Trunk thickness |

## Components

- **LSystem**: String rewriting engine
- **Turtle3D**: 3D turtle graphics interpreter
- **UI Labels**: Show current generation and instructions

## Visual Style

- **Brown branches** transitioning to thinner twigs
- **Green leaves** at branch tips
- **Thickness decay** as branches subdivide

## Files

| File | Purpose |
|------|---------|
| `AnimatedTree.tscn` | Scene root |
| `AnimatedTree.gd` | Growth animation logic |

## Usage

```gdscript
var tree = preload("res://algorithms/lsystems/Growth/AnimatedTree.tscn").instantiate()
tree.max_iterations = 6  # More detail
tree.growth_delay = 0.5  # Faster growth
add_child(tree)
```

## VR Experience

Watch the tree grow from a single stem to a full branching structure. The delay between generations lets you see each level of complexity build on the last. Position yourself at different distances to appreciate both the whole tree and individual branch patterns.

## Educational Value

L-Systems demonstrate:
- **Formal grammars**: Simple rules, complex output
- **Recursion**: Self-similar structures at every scale
- **Botanical modeling**: Real plants follow similar growth rules
- **Determinism vs complexity**: Same rules always produce same tree

## See Also

- `lsystems/Architecture/` — Buildings grown from grammars
- `lsystems/Ecosystem/` — Plants in environmental context
- `fractals/` — Other self-similar structures
