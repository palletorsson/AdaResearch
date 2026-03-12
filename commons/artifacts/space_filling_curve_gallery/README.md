# Space-Filling Curve Gallery

A floor-mounted triptych displaying three space-filling curves -- Hilbert, Peano, and Moore -- generated via L-system rules and turtle graphics. Teaches how recursive string-rewriting systems produce curves that visit every point in a 2D region.

## How It Works

Each curve is defined as an L-system with an axiom string and production rules. The axiom is expanded through multiple iterations by replacing each character with its corresponding rule output. The resulting string is interpreted by a turtle graphics engine: "F" moves forward (recording the position), "+" and "-" turn by 90 degrees. The collected points are normalized into a panel-sized bounding box and drawn onto a CPU-generated Image using Bresenham line rasterization with configurable thickness. The three panels are composed side by side into a single wide texture applied to a floor-lying QuadMesh.

## Features

- Three classic space-filling curves: Hilbert (order 4), Peano (order 3), Moore (order 3)
- L-system string expansion with configurable iteration depth
- Turtle graphics interpreter for curve point generation
- CPU-side Bresenham line drawing with 3-pixel thickness
- Color-coded panels: cyan (Hilbert), magenta (Peano), yellow (Moore)
- Floor-mounted display with per-curve labels

## Files

- `space_filling_curve_gallery.gd` -- Main script
- `space_filling_curve_gallery.tscn` -- Scene file
