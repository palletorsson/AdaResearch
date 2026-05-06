# Nature of Code Chapter 7: Cellular Automata

VR visualization of elementary cellular automata — 1D binary rules that generate complex patterns from simple local interactions.

## QFEP Connection

Elementary CA embody **maximal emergence from minimal rules**. Rule 30 produces chaos from a single black cell; Rule 110 is Turing complete. With only 256 possible rules (8-bit), the range from order (F) to chaos (E) is fully mappable. The `rule_number` parameter literally selects position on the F↔E spectrum.

## How It Works

```
Rule 30 (binary: 00011110)
Pattern:  111 110 101 100 011 010 001 000
Output:    0   0   0   1   1   1   1   0

Generation 0:  ...........█...........
Generation 1:  ..........███..........
Generation 2:  .........██..█.........
Generation 3:  ........██.████........
                    (chaos emerges)
```

Each cell's next state depends on itself and its two neighbors (3 cells = 8 patterns = 8-bit rule).

## Parameters

| Export | Default | Description |
|--------|---------|-------------|
| `rule_number` | 30 | Wolfram rule (0-255) |
| `rows_visible` | 36 | Generations shown |
| `update_interval` | 0.2 | Seconds per generation |

## Famous Rules

| Rule | Behavior | Class |
|------|----------|-------|
| 0 | All cells die | Trivial (I) |
| 30 | Chaotic | Complex (III) |
| 90 | Sierpinski triangle | Fractal (II) |
| 110 | Turing complete | Edge of chaos (IV) |
| 184 | Traffic flow | Simple (II) |
| 255 | All cells live | Trivial (I) |

## Wolfram Classes

| Class | Behavior | Examples |
|-------|----------|----------|
| I | Homogeneous | 0, 255 |
| II | Periodic/Static | 90, 184 |
| III | Chaotic | 30, 45 |
| IV | Complex | 110 |

## Files

| File | Purpose |
|------|---------|
| `cellular_automata_1d.gd` | Rule simulation |
| `*.tscn` | VR scene |

## Usage

```gdscript
var ca = preload("res://algorithms/cellularautomata/noc_ch07/ca.tscn").instantiate()
ca.rule_number = 110  # Edge of chaos
ca.update_interval = 0.1  # Faster
add_child(ca)
```

## VR Experience

Watch the automaton grow downward row by row. Use the dial to change rules in real-time — watch chaos give way to order or vice versa. Rule 30 famously appears on the shell of the cone snail *Conus textile*.

## Source

Translation from:
- **The Nature of Code** by Daniel Shiffman
- Original: Processing/p5.js
- License: CC BY-NC-SA 3.0

## Historical Note

Stephen Wolfram's "A New Kind of Science" (2002) explored these rules exhaustively, arguing that simple programs can produce complex behavior — a theme central to QFEP.

## See Also

- `cellularautomata/game_of_life/` — 2D cellular automata
- `sierpinski_pyramid/` — 3D Rule 90 analog
- `emergentsystems/` — Complex behavior from simple rules
