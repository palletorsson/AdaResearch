# Wireworld Circuit

Implements the Wireworld cellular automaton, a four-state system designed for simulating digital logic circuits. Teaches how simple local transition rules can produce complex computation, including signal propagation, clock generation, and logic gates.

## How It Works

Each cell in the grid is in one of four states: Empty (background), Wire (conductor), Electron Head (active signal front), or Electron Tail (signal wake). The transition rules are: Empty stays Empty; Head becomes Tail; Tail becomes Wire; Wire becomes Head if exactly 1 or 2 of its 8 neighbors are Heads, otherwise stays Wire. The artifact pre-builds an OR gate circuit with two clock loops that generate periodic electron signals feeding into a junction, with the output routed to a display loop. The grid state is rendered to an Image texture each step, with emissive colors (blue for Head, red for Tail, orange for Wire) applied to a floor-facing QuadMesh.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `display_size` | float | 0.8 |
| `grid_resolution` | int | 32 |
| `steps_per_frame` | int | 1 |
| `step_interval` | float | 0.15 |

## Features

- Four-state cellular automaton with Wireworld transition rules
- Pre-built OR gate circuit with two independent clock signal generators
- Animated electron propagation visible as blue (Head) and red (Tail) pulses
- Emissive texture rendering for visibility in VR environments
- Configurable simulation speed via step interval and steps-per-frame
- Double-buffered grid for correct simultaneous state updates

## Files

- `wireworld_circuit.gd` -- Main script
- `wireworld_circuit.tscn` -- Scene file
