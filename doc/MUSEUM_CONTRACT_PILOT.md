# Endless Museum contract pilot

This pilot makes the museum layers independently responsible and lets them negotiate through explicit offers. It covers twelve representative artifacts and compiles to `Museum_Contract_Pilot`.

## The rule set

1. **Artifact owns truth about itself.** Its config declares body and sweep envelopes, directional clearances, required interaction sides, permitted postures, viewing distance, lineage, and DNA.
2. **Order owns the main spine.** Main indices are unique. A lineage relation must point backward, so related and DNA artifacts can branch from a readable sequence.
3. **Floorplan owns safe circulation.** The module uses one-metre cells, preserves a three-metre through-route, and can expand rather than silently reduce an artifact envelope.
4. **Props own the wall margins.** The centre 60% is reserved for map text and painting-like monitors. Support props use the outer rails; interactive controls remain between 0.75 m and 1.35 m.
5. **Museum owns release confidence.** A module is publishable only when every hard gate passes and its entry and exit align with the route.
6. **Book owns the visitor account.** Chapters follow the artifact order and appear on the reserved monitors without replacing physical interaction space.

Negotiation priority is: safety → reachability → route continuity → lineage order → view quality → compactness.

## Generate and validate

```powershell
python tools/museum_contract_pilot.py --check
python tools/museum_contract_pilot.py --web-root ..\ada_encyclopedia\public
python tools/map_pathfinder.py check Museum_Contract_Pilot --verbose
```

The compiler writes:

- `commons/maps/Museum_Contract_Pilot/map_data.json` — playable one-metre Godot map
- `ada_run/museum_contract_pilot/report.json` — every placement gate and negotiation decision
- `ada_run/museum_contract_pilot/floor_plan.svg` — top-down body, footprint, and route proof
- `ada_run/museum_contract_pilot/wall_elevation.svg` — feature field, rails, and height proof

The working browser presentation is `/museum-contract-pilot` in the encyclopedia dev server.
