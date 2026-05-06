# Balance Puzzle

> Stack freely. Reach the height. Watch it walk away.

## Concept

The Balance Puzzle embodies QFEP (Queer Feminist Energy Principle): **truth emerges from physics, not prescription**.

No ghost guides. No target configuration. No single "correct" answer. Multiple stable configurations satisfy the constraints. The form finds itself.

## Mechanics

1. **Platform** - A small building surface
2. **Pieces** - Cubes and pyramids spawn nearby (grabbable)
3. **Height Threshold** - Stack must reach 0.4m above platform
4. **Stability Check** - All pieces must be at rest (low velocity)
5. **Transformation** - When stable at height, pieces reorganize into a walking creature

## The Sublime

When conditions are met:
- Pieces freeze
- Dramatic pause
- Pieces animate toward center of mass
- Reorganize into bipedal form (legs, body, head)
- Walker bobs, sways, steps forward
- Walks away into the distance

The creation exceeds the creator. The made thing has agency.

## Configuration

| Property | Default | Description |
|----------|---------|-------------|
| `height_threshold` | 0.4 | Required height in meters |
| `stability_time` | 1.5 | Seconds stable before transform |
| `stability_velocity_threshold` | 0.05 | Max velocity to count as stable |
| `piece_count` | 6 | Number of pieces to spawn |
| `cube_ratio` | 0.7 | Ratio of cubes to pyramids (0-1) |
| `piece_scale` | 0.08 | Size of pieces |
| `walker_speed` | 0.15 | How fast the walker moves |
| `walker_step_frequency` | 3.0 | Walking animation speed |

## Signals

- `height_changed(current_height, threshold)` - Height updates
- `stability_progress(progress)` - 0-1 progress toward stable
- `transformation_started()` - Transform sequence begins
- `transformation_complete()` - Walker is ready
- `walker_created(walker)` - Reference to the walker node

## Usage

```json
{
  "balance_puzzle": {
    "scene": "res://commons/primitives/balance/balance_puzzle.tscn"
  }
}
```

In map_data.json:
```
"balance_puzzle:0:-0.5"
```

## Ontological Note

This puzzle asks: **What is form?**

- Not prescription (the ghost guide says "be this shape")
- Not function (the chair must support a body)
- But **emergence** (what stable configurations exist in this physics?)

The forms that persist are the forms that work. Your tower that stands is true. Your walker that walks is alive.
