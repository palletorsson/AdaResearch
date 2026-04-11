# Big Pipe System — Segments

Parametric pipe segment scenes and scripts. Each segment is a building block that can be connected to form complex pipe networks.

## Segment Types

- `pipe_straight.tscn` — Straight pipe section.
- `pipe_corner.tscn` — 90-degree corner joint.
- `pipe_t_junction.tscn` — T-junction splitter.
- `pipe_cross.tscn` — Four-way cross junction.
- `pipe_s_bend.tscn` — S-shaped bend.
- `pipe_end_cap.tscn` — Terminal end cap.
- `pipe_vertical_up.tscn` — Vertical rise segment.
- `pipe_vertical_down.tscn` — Vertical drop segment.

## Parametric Scripts

- `pipe_corner_parametric.gd` — Configurable corner radius and angle.
- `pipe_s_bend_parametric.gd` — Configurable S-bend curvature and offset.
- `pipe_vertical_parametric.gd` — Configurable vertical height and transition.

See the parent [Big Pipe System README](../README.md) for the full pipe network architecture.
