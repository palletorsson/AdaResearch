# catalyst_lab — sequence-binding test ring

Six 12×10 arenas testing the catalyst's **sequence-binding** logic — the
relation between the catalyst and its counterpart (the foe), both keyed
to the same sequence name via
`commons/hazards/catalyst_sequence_binding.gd`. The mode roster itself
(10 projectile modes vs. one foe) is covered by `catalyst_test`; this
ring covers **who knows what sequence, and what that knowledge arms**.

Maps loop 01 → 02 → … → 06 → 01.

| Map | Tests | Expected |
|---|---|---|
| `CatalystLab_01_Home` | `sequence:auto` on both sides while an **unbound** sequence (catalyst_lab) runs | Negative test. Catalyst logs home sequence, arms nothing. Vent logs "no binding", brood stays GOO. A map without binding data must behave exactly as before. |
| `CatalystLab_02_Pair_Primitives` | Both sides pinned `sequence:primitives` | Bracelet starts on the primitives stone without `start_mode`/`active_mode` config. Goo brood. First FRIEND grants **Shield**. |
| `CatalystLab_03_Pair_Transform` | `sequence:transformation` | Purple beam native; transport brood — friends shove peers away. **Porter** power. |
| `CatalystLab_04_Pair_Waveform` | `sequence:wavefunctions` | Waveform native; wave brood — friends slow-pulse. **Calmer** power. |
| `CatalystLab_05_Mismatch` | Catalyst pinned `color` (chromatic), vents pinned `cellularautomata` (drainfriend) | **Who names whom.** Vent A's raw foes: first chromatic hit re-locks lineage → chromatic friends. Vent B's `curious` creatures are past "foe" → they keep the drainfriend lineage. The catalyst names only the unformed. |
| `CatalystLab_06_Chain` | `sequence:swarmintelligence`, one vent, wave 10 | Convert one foe; escort lineage propagates peer-to-peer; flock forms the shield-wall around the player. |

## Token grammar exercised

```
becoming_catalyst#sequence:<name|auto>          — pin/auto-bind the crystal; arms its native mode
catalyst_vent:0:0#sequence:<name|auto>#...      — brood kind resolved from the same table
catalyst_vent:0:0#foe_mode:auto                 — same as sequence:auto (matches e:R:W:D:auto)
```

Regenerate: `python tools/generate_catalyst_lab_maps.py` then
`python tools/compact_map_json.py commons/maps/CatalystLab_*/map_data.json`.

Smoke: `commons/testing/smoke_catalyst_sequence_binding.gd`.
