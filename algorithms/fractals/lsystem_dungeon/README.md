# L-System Dungeon

## Overview
Procedural dungeon generator using Lindenmayer Systems (L-systems) - formal grammars that define recursive growth patterns, interpreted via turtle graphics.

## Spawn
```
lsystem_dungeon
lsystem_dungeon#preset:maze
```

## Parameters
| Parameter | Description | Example |
|-----------|-------------|---------|
| `preset` | Apply preset configuration | `#preset:branching` |

## Presets
| Preset | Axiom | Rule | Result |
|--------|-------|------|--------|
| `linear` | `F` | `F→FF` | Long corridor |
| `branching` | `F` | `F→F[+F]F[-F]F` | Tree-like branches |
| `maze` | `F` | `F→F+F-F-F+F` | Maze pattern |
| `organic` | `F` | `F→F[+F][-F]F[+F]` | Natural caves |
| `symmetric` | `F` | `F→F[+F][-F]` | Balanced branches |
| `dense` | `F` | `F→FF[+F][-F]FF` | Packed corridors |
| `spiral` | `F` | `F→F+F` | Spiraling path |

## L-System Grammar
### Symbols
| Symbol | Meaning |
|--------|---------|
| `F` | Move forward, create corridor |
| `+` | Turn right by `turn_angle` |
| `-` | Turn left by `turn_angle` |
| `[` | Push state (save position/direction) |
| `]` | Pop state (restore position/direction) |
| `R` | Create room |
| `L` | Create large room |

### Example
```
Axiom: F
Rule: F → F[+F]F[-F]F
Iterations: 3

Generation 0: F
Generation 1: F[+F]F[-F]F
Generation 2: F[+F]F[-F]F[+F[+F]F[-F]F]F[+F]F[-F]F[-F[+F]F[-F]F]F[+F]F[-F]F
```

## Turtle Graphics Interpretation
The generated string is interpreted by a "turtle" that:
1. Starts at origin facing +Z
2. Reads each symbol left-to-right
3. Executes corresponding action
4. Builds dungeon geometry as it moves

## Configuration
```gdscript
@export var axiom := "F"
@export var iterations := 3
@export var rules := {"F": "F[+F]F[-F]F"}
@export var room_size := 4.0
@export var corridor_length := 6.0
@export var turn_angle := 90.0
@export var branch_probability := 0.7
```

## Visual Options
- `use_csg_carving` - Use CSG boolean operations (slower, cleaner)
- `show_construction` - Animate step-by-step building
- `step_delay` - Animation speed

## API Methods
```gdscript
regenerate()              # Rebuild dungeon
apply_preset(name)        # Apply named preset
set_rule(symbol, rule)    # Modify grammar rule
```

## Algorithm Details
1. **String Generation**: Apply production rules `iterations` times
2. **Turtle Interpretation**: Walk through string, executing commands
3. **Geometry Creation**: Build rooms and corridors at turtle positions
4. **Collision Detection**: Optional overlap prevention

## Mathematical Background
L-systems were developed by biologist Aristid Lindenmayer to model plant growth. They're parallel rewriting systems where all symbols in a string are replaced simultaneously according to production rules.
