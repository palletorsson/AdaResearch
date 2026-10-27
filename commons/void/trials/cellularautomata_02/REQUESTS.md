# cellularautomata_02: shared-code requests (Claude worker D, batch 25)

**No shared change is required before native.** Static reading of all six placements:

| placement | where its config is read | in the Void |
|---|---|---|
| `ca_bridge` | `_ready` reads `config_study`; `history_study._ready` reads `config_follow` | works after `_ready`: metadata is stamped before `add_child`, and the later `apply_grid_config` finds `HistoryStudy` and returns |
| `lab_room` | `_ready` reads every `config_*` | the later `apply_grid_config` compares a signature and does not rebuild |
| `film_cellular_history`, `dark_sphere` | no config read | — |
| `ca_columns` | `apply_grid_config` is `pass` | — |
| `mirrored_cellular_automata` | wrapper reads only `stencil` / `pattern_seed` | neither is in the token |

Standalone cameras, suns and environments (bridge, columns) are already handled by
`floor_content`'s `museum_import` branch; the bridge's history study also removes its own.
No `_unhandled_input`, no `CanvasLayer`, no `"player"` group in any of the six.

## Questions, not requests

**Q1. Negative token heights.** `ca_columns:0:-0.5:0.2` and
`mirrored_cellular_automata:0:-0.5` both carry y = −0.5. The museum plan has the same offset
(`em_plan.json` row 93). `rooms.schema.json` sets `height.minimum = 0`, so both stand at 0.

- **Columns.** The source sinks the lowest 0.5 m (about 11 generations at scale 0.2) below
  the hall floor; here it shows.
- **Mirrored automaton.** It is a 0.8 m flat plate drawn at y 0.01. At −0.5 it would sit
  0.49 m under the floor, invisible in the museum (static inference; the museum hall was not
  looked at). Here it lies visible on the slab.

To transfer the exact heights, the schema would need a negative minimum. `floor_content`
already uses `float(item.height)` unchanged. That is Codex's and Palle's call; I have not
asked for it.

**Q2. The floor-1 basin.**
- **What it is.** An open basin, 0.72 m deep, no glass; the rect is 7.2 x 10.2 m. It
  reproduces the source hole (structure 0, 7 x 10 cells) under the bridge.
- **Why the bridge needs it.** The bridge's history study builds its own collecting floor at
  −0.60 and two ramps for that hole ("Only occupied recorded cells offer support. The basin
  is lower down."). Without a cut in the slab, its gaps would support the visitor like every
  other cell.
- **Fall and exit.** A fall is 0.6 m, and the study's ramps lead out. The probe walks both.
- **Why 0.1 m wider per side.** `basin.gd` stands its 0.1 m walls inside the rect. Inside the
  hole, they would leave a 5 cm lip at the top of each ramp.
- **To remove it,** delete the `basin` key. The bridge then stands on solid slab.
