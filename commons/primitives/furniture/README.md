# Furniture & Relief Puzzles

> A chair is just rectangles. Scale, rotate, position. The grammar of making.

## Concept

Inspired by Donald Judd's furniture: complex forms emerge from systematic combination of simple elements. The puzzles teach transform composition through hands-on assembly.

---

## Chair Assembly Puzzle

Assemble a Judd-inspired chair from 6 scalable cubes.

### Pieces
- **Seat** - wide, flat (0.5 × 0.05 × 0.5)
- **4 Legs** - tall, thin (0.05 × 0.4 × 0.05)
- **Back** - tall rectangle (0.5 × 0.5 × 0.05)

### Interaction
1. Grab cube from workbench
2. Scale with two-handed grip (VR) or scroll wheel (desktop)
3. Rotate by twisting
4. Position to match ghost guide
5. When all pieces match → chair grows to real size

### Variants
| Type | Description |
|------|-------------|
| `chair_assembly_puzzle` | Full chair (6 pieces) |
| `stool_assembly_puzzle` | Seat + 4 legs (5 pieces) |
| `table_assembly_puzzle` | Top + 4 legs (5 pieces) |
| `shelf_assembly_puzzle` | 2 supports + 3 shelves |

---

## Relief Assembly Puzzles

Constructivist/De Stijl relief compositions. Arrange colored bars at varying depths on a backing.

### Types

#### Biederman Relief (default)
- Charles Biederman inspired
- Horizontal and vertical bars
- Mixed depths (0.06 - 0.14)
- Warm palette: red, yellow, orange, green, blue, magenta

#### Mondrian Relief
- Piet Mondrian / De Stijl
- Grid-based arrangement
- Primary colors (red, yellow, blue) + black lines
- Strict orthogonal composition

#### Albers Relief
- Josef Albers "Homage to the Square"
- Nested squares exploring color interaction
- Subtle color relationships
- Centered, symmetrical

#### Constructivist Relief
- Soviet Constructivism inspired
- Dynamic diagonals
- Bold red and black
- Visual tension and movement

### Configuration

```json
{
  "biederman_relief": { "scene": "...biederman_relief_puzzle.tscn" },
  "mondrian_relief": { "scene": "...", "config": { "relief_type": 1 } },
  "albers_relief": { "scene": "...", "config": { "relief_type": 2 } },
  "constructivist_relief": { "scene": "...", "config": { "relief_type": 3 } }
}
```

---

## Base Classes

### TransformPuzzleBase
Base class for all transform verification puzzles.

**Features:**
- Ghost guides showing targets
- Position + rotation + scale verification
- Flexible matching (any axis order)
- Proximity-based color feedback
- Snap-to-target with hold time
- Tag system integration for rewards

### Key Properties
| Property | Description |
|----------|-------------|
| `position_tolerance` | Distance threshold (default 0.08m) |
| `rotation_tolerance` | Angle threshold (default 15°) |
| `scale_tolerance` | Scale difference threshold (default 15%) |
| `snap_hold_time` | Seconds at target before snap (default 1.0) |

---

## Design Philosophy

> "Modernity for many, functionalism reduces the form to enable form for the people."

The minimal chair is democratic furniture. These puzzles ask: **what is the minimum transformation set that produces a chair?**

Answer: 6 rectangles × (scale + position) = chair.

The queer potential: a chair made "wrong" (legs rotated, back inverted) is still mathematically valid. What would a queer chair look like?
