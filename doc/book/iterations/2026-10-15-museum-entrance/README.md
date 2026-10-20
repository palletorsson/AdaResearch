# An entrance and a closed back wall

2026-10-15. Palle: “add en entrance and close the exit we now have teleporters.”

Random Definition now has an enclosed arrival room leading through the front
wall toward Random Touch. The old physical exit opening is closed. The existing
pink teleporter remains inside the hall and leads to Random Entropy.

## Authored changes

- Open front cells `(5,0)`, `(6,0)`, `(7,0)` and put `s` at `(6,0)`. Enable the
  existing `portal_entry.cage` entrance room. Arrival is at map-space
  `(6.5, 0.05, -1.35)`, on the supported entrance floor.
- Set `museum.gate = false`: the redundant sliding gate is no longer built in
  this entrance. Its collision was rejecting the previous authored arrival.
- Keep the complete back row, row 38, as wall. Set
  `museum.passage = {"kind":"none", "carve_exit":false}` so teleporter mode
  does not cut a corridor opening through it again.
- Move `t` from `(6,27)`, which was inside an interior wall, to `(6,36)`, the
  usable location where navigation was already placing its fallback teleporter.
  The authored teleporter now loads without fallback at `(6.5,0.05,36.5)`.
- Keep the quiet-wall choice and artifact placements.

The entrance uses the existing supported portal-entry room: 1.12 m clear inner
doorway, enclosed landing, roof and a link into the hall. The new passage option
only affects teleporter mode. Maps that omit it keep their previous behavior;
the continuous-corridor mode still creates its required exit opening.

## Verification

`museum_probe.gd` in the actual isolated museum: **27/27 checks passed**. Native
views were inspected. The test walks the real CharacterBody through the new
entrance, attempts to walk through the closed back wall and confirms it stops,
then uses the production teleporter proximity detector. Random Entropy loads
and its destination arrival is supported.

The checks also cover the full back row, wall collision at three points across
the former opening, floor and body clearance through the entry, saved spawn and
teleporter markers without fallback, unchanged behavior for undeclared maps and
continuous corridors, and no mutation of the input tile by passage construction.

The authored-grid pathfinder finds a route from `(6,0)` to `(6,36)` (45 cells in
its output, including endpoints). Runtime traversal of the entire artifact
sequence and headset comfort are not claimed.

Earlier diagnostic runs caught two probe issues: reading floor height at an
assumed value, and a vertical ray exactly on a tiled box edge returning that
box's vertical side normal. Final samples use measured floor heights and avoid
exact edges; the actual walker crosses the joins. The actual transition test
also resumes the museum loader tick before requesting a new hall.

Final evidence: `report.json`, `engine.log`, `entrance.png`,
`entrance-from-hall.png`, `closed-exit.png`. Full isolated run and source hashes:
`ada_run/encounter_pilot/Random_Definition/entrance-and-closed-exit/`.

Reload the museum hall to see the change. No commit or push was requested.
