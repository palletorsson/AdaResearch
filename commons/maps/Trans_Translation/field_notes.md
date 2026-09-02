# Trans_Translation — field notes

> Field notes hold what the wall text cannot carry. `final.md` is for the
> visitor. This is for us.

## Exactness decisions

- **The gate counts the GameManager score, not this hall's cubes.**
  `pickup_gate.gd` connects `score_updated` and opens when the running score
  reaches `required_pickups` (7 here). Five `pick_up_cube` are placed
  (points_value 1 each); the other two come from earlier halls. The first draft
  said "seven cubes". The text now says the gate wants seven on the score you
  carry.
- **science_screen `mode:point`** is a real mode (`_set_explicit_mode`: point,
  line, trace/draw, triangle, net/cube): it tracks a grabbed point. The text
  says carry a cube in front of it.
- **synthesis_stand `#subject:pick_up_cube#mode:hero`**: the verdict file
  `commons/data/dna_synthesis.json` rules pick_up_cube a SERIES on axis `stock`
  (wire, steel, clay, crate, foam); a hero of a series-verdict subject pins the
  top evidence variant. The text names the five stocks.
- **Axes in this hall**: transport cubes `tc:3:z`, `tc:1:y:auto`, `tc:3:y`,
  `tc:2:y`, `tc:6:y`; the two axis cubes placed are z and y. "Nothing asks you
  to go sideways" is from the utilities.
- **transform_composition_workbench**: pair 2 (rotation × uniform scale)
  commutes, per its description and probe item 6.

## Continuity

player_trace from Point_Trace (the line as positions); the void as invitation
from the blurb.
