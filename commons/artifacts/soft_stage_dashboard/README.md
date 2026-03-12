# Soft Stage Dashboard

A wall-mounted read-only panel that displays live state from three game managers: EcosystemManager, HazardManager, and CatalystCapabilityManager. Teaches system observability by surfacing the internal state of the game's progression systems in a unified three-column dashboard with a rolling signal log.

## How It Works

The dashboard connects to signals emitted by the three singleton managers at `/root/`. When any manager advances its stage, updates hazard types, changes capabilities, or modifies ecosystem flags, the dashboard refreshes the corresponding column and appends a timestamped entry to the signal log. The left column shows ecosystem state (terrain mode, ambient preset, vegetation density, allowed kingdoms, flags). The center column shows hazard state (spawner behavior, max concurrent, types, personalities). The right column shows capability state (capacity level, hand verbs, movement abilities, catalyst modes). All data is read-only, queried directly from manager APIs.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `panel_size` | Vector2 | (1.2, 0.9) |

## Features

- Three-column layout: Ecosystem, Hazards, Capability
- Real-time signal-driven updates from game managers
- Rolling signal log with timestamps at the bottom
- Column dividers and frame edges for visual structure
- Auto-wrapping text within column bounds

## Files

- `soft_stage_dashboard.gd` -- Main script
- `soft_stage_dashboard.tscn` -- Scene file
