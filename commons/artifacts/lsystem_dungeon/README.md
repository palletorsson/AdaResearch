# L-System Dungeon

A procedurally generated dungeon floor plan created using L-system grammar rules. Corridors and rooms emerge from string rewriting, demonstrating how formal grammars can generate complex spatial structures from simple production rules.

## How It Works

Starting from the axiom "F", the L-system applies production rules (F -> F+RF-FF-FR+F, R -> RFRFRF) over multiple iterations to produce a string. A turtle interpreter then walks the string on the XZ plane: "F" draws a corridor segment forward, "R" marks a room, "+" turns left 90 degrees, and "-" turns right 90 degrees. The resulting segments and room markers are scaled to fit within the display bounds and rendered as 3D geometry -- flat corridor slabs with walls on both sides and larger floor tiles for rooms.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `display_size` | float | 0.7 |
| `iterations` | int | 3 |
| `corridor_color` | Color | (0.35, 0.3, 0.28) |
| `room_color` | Color | (0.5, 0.4, 0.35) |
| `wall_color` | Color | (0.2, 0.18, 0.16) |

## Features

- L-system string rewriting with configurable iteration depth (1-5)
- Turtle interpretation on XZ plane with 90-degree turns
- 3D corridor slabs with walls on both sides
- Room markers rendered as larger floor tiles
- Automatic bounding-box scaling to fit display size
- Info label showing iteration count, corridor count, room count, and wall count
- Stack-based branching support via bracket symbols

## Files

- `lsystem_dungeon.gd` -- Main script
- `lsystem_dungeon.tscn` -- Scene file
