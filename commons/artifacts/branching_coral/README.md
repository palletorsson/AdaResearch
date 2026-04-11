# Branching Coral

A marine L-system coral colony that demonstrates how simple string rewriting rules and turtle graphics produce organic branching structures resembling real coral. Multiple shoots grow from a shared rock base, creating a bushy colony with natural variation.

## How It Works

Two L-system production rules ("F" and "G") are iterated 3-4 times to generate long instruction strings. A 3D turtle interpreter walks each string: "F"/"G" draw forward, "+"/"-" yaw left/right, ">"/"<" pitch forward/back, and "["/"]" push/pop state for branching. Each of 5 shoots starts with a slightly different direction and random tilt, producing an asymmetric colony. Branch segments use a two-stage color gradient -- deep purple-brown at the base through warm orange-coral at mid-depth to bright pink at the tips -- mimicking real coral pigmentation. Branch length decays by 0.7x at each depth level.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `display_size` | float | `0.7` |
| `base_color` | Color | `Color(0.35, 0.15, 0.25)` |
| `tip_color` | Color | `Color(0.95, 0.45, 0.55)` |
| `iterations` | int | `4` |
| `base_length` | float | `0.08` |
| `base_angle` | float | `35.0` |
| `length_decay` | float | `0.7` |
| `angle_variation` | float | `12.0` |
| `num_shoots` | int | `5` |

## Features

- Two L-system rules with 3D turtle interpretation (yaw, pitch, branch)
- Multiple shoots with varied axioms, iteration counts, and starting directions
- Two-stage color gradient (base to mid-color to tip)
- Automatic bounding box centering and scale-to-fit
- Rock base platform for natural display
- Grid configuration for iterations, angle, shoots, decay, size, and seed

## Files

- `branching_coral.gd` -- Main script
- `branching_coral.tscn` -- Scene file
