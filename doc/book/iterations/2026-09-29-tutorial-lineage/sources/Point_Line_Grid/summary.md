# Point_Line_Grid — map summary

The question is what a repeatable address makes possible. Build on Point_Trace's already sampled position list: name a place, return to it, replay a gesture, specify an arrangement. The next hall is Point_Triangle_Context, where a closed boundary and a rendered face are distinguished.

## Primary encounter order

| Artifact | Discover through action | Carry forward |
| --- | --- | --- |
| `grab_sphere_point_snap` | Move, release, compare retained metres with lattice indices | Five-centimetre world spacing makes repeatable positions with tolerance around each representative. |
| `player_trace` | Walk within one coarse address, cross its boundary, return | The one-metre local record keeps an order of visits; a chosen body point and direct segments shape what it describes. |
| `grid_lines` | Recognise a released Trace drawing in pink and compare green | A copied list can acquire another scale and use; source and display frames differ. |
| `plan_vitrine` | Find a cell by its two indices, leave and return | Twenty-five finite cells specify an arrangement; a separate collider supports walking across their edges. |

## Current layout

The portable map is 20 columns by 15 rows, with an eastern extension containing the numbered plan. Its declared basin is one metre deep, with museum-supplied walkable glass above the replay field. A zero in the source structure is therefore insufficient evidence of an unwalkable hole in the assembled museum.

All seven placements remain. The source grid coordinates below are column/row indices, not final museum world coordinates:

| Artifact | Column, row | Role |
| --- | --- | --- |
| `grab_sphere_point_snap` | 3, 10 | Primary |
| `player_trace` | 9, 1 | Primary |
| `grid_lines` | 5, 5 | Primary |
| `plan_vitrine` | 15, 7 | Primary |
| `room_grammar` | 7, 13 | Secondary |
| `floating_sphere_field` | 5, 10 | Secondary |
| `modulor_man_demo` | 2, 13 | Secondary |

The roles express teaching order, not a newly enforced walking route. The vitrine wraps `simulation_grid`; there is no separate eighth placement. Existing secondary encounters are described in [detours.md](detours.md).

## Reading and implementation

[final.md](final.md) is the first passage. [tutorial.md](tutorial.md) follows its actual program; [technical.md](technical.md) distinguishes the grids, frames, buffers and colliders. [critical.md](critical.md) asks what decisions are made from a shared address. The earlier texts and historical layout descriptions are preserved in the [editorial archive](../../../doc/space/point-grid-focus-2026-09-16/README.md).
