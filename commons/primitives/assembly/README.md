# Assembly Line Puzzle

> Build houses from cubes and pyramids on a production line.

## Concept

The Assembly Line Puzzle introduces **sequence** to composition. Forms emerge not from static assembly but from flow:

- Cube arrives → position → pyramid arrives → position → house emerges
- The body learns rhythm, timing, anticipation
- Production becomes dance

## Mechanics

1. **Input Conveyor** - Shapes move toward the production station
2. **Production Station** - Ghost target shows where to place shapes
3. **Composite Forms** - Multiple slots per product (cube + pyramid = house)
4. **Output Conveyor** - Completed products move to container
5. **Reward** - Grabbable house spawns on completion

## Puzzle Types

### Type 0: Houses (default)
- **House** - 1 cube + 1 pyramid
- **House** - 1 cube + 1 pyramid
- **Tall House** - 2 cubes + 1 pyramid

### Type 1: Lab Equipment (Half-Life inspired)
- **Health Station** - 2 cubes stacked
- **Security Camera** - 1 cube + 1 pyramid (rotated)
- **Specimen Jar** - 3 cubes stacked

### Type 2: Scientific Equipment (Real Lab Models)
- **Microscope** - 2 cubes + 1 pyramid → spawns actual microscope model
- **Electronic Scales** - 2 cubes → spawns actual scales model
- **Multimeter** - 2 cubes + 1 pyramid → spawns actual multimeter model

The reward for this type loads the actual detailed lab equipment scene from `commons/lab/` rather than a procedural mesh.

## Configuration

| Property | Default | Description |
|----------|---------|-------------|
| `puzzle_type` | 0 | 0=Houses, 1=Lab Equipment, 2=Scientific Equipment |
| `input_speed` | 0.08 | Conveyor input speed |
| `output_speed` | 0.12 | Conveyor output speed |
| `shape_scale` | 0.07 | Size of shapes |
| `slot_match_distance` | 0.08 | Snap distance for placement |
| `snap_duration` | 0.25 | Animation time for snapping |
| `conveyor_color` | White | Color of conveyor belts |
| `ghost_color` | Cyan | Color of ghost targets |

## Signals

- `shape_spawned(shape, type)` - New shape on conveyor
- `shape_placed(shape, slot_index)` - Shape matched to slot
- `product_complete(product_index)` - All slots filled
- `sequence_complete()` - All products built
- `reward_spawned(reward)` - Grabbable reward created

## Usage

In furniture.json:
```json
{
  "assembly_line_puzzle": {
    "scene": "res://commons/primitives/assembly/assembly_line_puzzle.tscn"
  },
  "lab_assembly_puzzle": {
    "scene": "res://commons/primitives/assembly/assembly_line_puzzle.tscn",
    "config": {
      "puzzle_type": 1
    }
  },
  "scientific_assembly_puzzle": {
    "scene": "res://commons/primitives/assembly/assembly_line_puzzle.tscn",
    "config": {
      "puzzle_type": 2
    }
  }
}
```

In map_data.json:
```
"assembly_line_puzzle:0:-0.7:0"
```

## Rewards

### House Reward
- Cream-colored cube body
- Terracotta pyramid roof
- Grabbable (XRToolsPickable)

### Lab Equipment Reward
- Half-Life style Health Charger
- Green/teal color scheme
- Procedurally generated mesh

### Scientific Equipment Reward
- **Microscope** - Full interactive microscope from `commons/lab/microscope/`
- **Electronic Scales** - Precision balance from `commons/lab/electronicscales/`
- **Multimeter** - Digital multimeter from `commons/lab/multimeter/`
- Actual scene files loaded and scaled to reward size (0.3x)
- Grabbable (XRToolsPickable)

## Design Philosophy

> "Form follows function follows form."

The conveyor belt is time made visible. The ghost target is the should-be haunting the is. The reward is the completion made tangible—something you can hold, examine, take with you.

Modern Times meets VR meets IKEA.
