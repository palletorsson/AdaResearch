# Technical notes

The site is generated from two independent contracts:

- `ada_run/dedicated_world_register.json` derives the need for a dedicated site from the measured 50 x 32 x 4.9 m body.
- `site_contract.json` records the authored response: `perimeter_observation_court`, 56 x 38 m, one-metre grid, three-metre apron, full-scale body, continuous route.

The map JSON owns address space, spawn, exit, and one placement of `konigsberg_observation_court`. Its three 56 x 38 layers are deliberately explicit but formatted as compact single-line rows. `tools/konigsberg_dedicated_map.py --check` prevents the large empty grid from drifting.

The court artifact owns geometry. It renders 528 one-metre tiles through one `MultiMesh`, uses four box colliders for the observation ring, and builds parapets, inner guards, and two access tongues from bounded box primitives. The original `konigsberg3d.tscn` is instantiated once at `Vector3.ONE`; its camera, screen overlay, and demo light are disabled when embedded. The artifact's parity parameter remains available without changing scale or footprint.

The two access tongues widen the tangent where the north and south circular landmasses meet the apron. Their dark metal finish and the floor legend state that they are museum circulation, not edges in Euler's graph. No edge is added to the artifact's adjacency table.

Validation:

```powershell
python tools/konigsberg_dedicated_map.py --check
python scripts/validate_map.py --map World_Konigsberg_Bridge --json
godot --headless --path . --xr-mode off --script res://commons/testing/test_konigsberg_observation_court.gd
```
