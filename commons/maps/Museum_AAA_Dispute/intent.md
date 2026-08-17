# Museum_AAA_Dispute — why the room is this shape

13 x 26 cells. Eight placements of `constant_dispute`, no other artifact. The room hangs one
family and nothing else, so that anything the visitor notices is a fact about that family.

## The floor is the plate, and the plate is not equal

`lambda_slider.gd:826-841` draws the `dispute` calibration by bisecting between adjacent
marks and letting the outer territories run to the plate's ends. A comment at :823-825 says
the plate shows "three territories at equal strength". Lambda's marks 0.30 / 0.40 / 0.50 give
edges at 0, 0.35, 0.45 and 1.0, so the shares are **35% / 10% / 55%** — and the 10% belongs to
0.40, which is the value `lambda_slider.gd:83` ships as the default.

That is what this floor is. The scale runs 20 cells along Z — `constant_dispute.gd:197`
sets `CELLS := 20`, so one cell is one metre and one t-step of 0.05 — from row 4 (t = 0.00)
to row 23 (t = 0.95). Both dispute edges land on integer cells: 0.35 x 20 = 7 and
0.45 x 20 = 9. The territories are therefore **7 cells, 2 cells and 11 cells**, exactly, with
no rounding anywhere:

| rows | t | school | cells | share |
|---|---|---|---|---|
| 4–10 | 0.00–0.35 | 0.30 | 7 | 35% |
| 11–12 | 0.35–0.45 | 0.40 — **the shipped default** | 2 | 10% |
| 13–23 | 0.45–1.00 | 0.50 | 11 | 55% |

The visitor reads `EQUAL STRENGTH` at the door — the comment, quoted — then walks seven
paces, squeezes through two, and crosses eleven. Nothing else in the room has to argue the
point. The room does not lay its works out evenly, because its subject is a partition that
claims to be even and is not.

Rows 11–12, cols 5–7 are height-2 wall: territory B is mostly barrier. That is the one
dramatisation, and it is honest about what a 10% territory two cells wide mostly consists of.
You cannot stand in the middle of the middle school. You go round it, west or east.

## Where each board stands: a rule, not an arrangement

**A board stands on the cell where its claim raises its first boundary.** `_claim_spans()`
gives the set, `_lit_cells()` gives the cell — `int(floor(t * 20))` — and that is the row.

| claim | first boundary | source | cell | row | territory |
|---|---|---|---|---|---|
| `interval` | 0.30 | `lambda_slider.gd:110`, `is_at_edge()` lower bound | 6 | 10 | A, 35% |
| `rival` | 0.35 | apex − SCHOOL_HALF, lambda's own half-spacing | 7 | 11 | B, 10% |
| `point` | 0.40 | `LAMBDA_APEX`, the shipped default | 8 | 12 | B, 10% |
| `threshold` | 0.60 | `phi_slider.gd:82`, `has_queer_signature()` | 12 | 16 | C, 55% |
| `absent` | none | — | — | — | **the vestibule** |

`absent` raises no boundary, so the rule gives it no cell, so it never enters the scale. Its
two boards wait in front of the gate. An instrument that recommends nothing has no territory
on a plate that divides territory between recommendations — and it still has 270 trials, which
is what the second of the two vestibule boards is for.

The rule also produces the room's shape without anyone choosing it. **Two of the five claims —
`rival` and `point` — begin inside the two cells of the 10% territory, and a third, `interval`,
begins on the cell immediately before it; the 55% territory holds eleven cells, one board, and
seven empty cells behind it.** The largest school on the plate is the emptiest room in the
museum. That was not arranged; it fell out of putting each claim where its claim actually
starts.

`rival` sits on top of the barrier at (11,6), h=2, because it is the only claim with two
components and no arbiter: its first component is territory B and its second is inside C. It
stands on the wall dividing the two, two metres up, where no visitor can go.

`threshold` stands at (16,6) facing back down the hall, and the eight cells behind it — 0.60 to
the door — are its claim. Its far boundary is not on the board; it is the teleporter at row
24, t = 1.0, the end of the rail. That is `lambda_slider.gd:817` built at full size: a bracket
at the end of the instrument, drawn exactly like a bracket that marks a fact.

## The boards are turned off the grid, and that is a finding

`constant_dispute.gd:192` yaws the board 0.62 rad (35.52°) inside the artifact, because
`capture_config_sweep.gd:69` puts its camera at yaw 0.62. Every board in this family was built
facing a camera. To face a body, every token here has to take that back out, so no rotation in
this map is a multiple of 90: the face-north tokens carry 144.48, face-south 324.48, east
54.48, west 234.48, and the two vestibule boards 72.91 and 216.04 to aim at the spawn. The
room is full of objects that had to be turned to be looked at by a person.

## The designed null, and how a visitor meets it

**`constant_dispute:144.48#claim:point#record:count` at (12,2)** and
**`constant_dispute:324.48#claim:point#record:spread` at (12,10)** — both in territory B, both
on row 12, the cell of t = 0.40.

At `claim=point` no random draw is taken: all 270 trials are assigned `LAMBDA_APEX`, land in
bin 8, and `count` and `spread` build the same 27 slots through the same `_mark()` helper with
the same shared mesh. The registry predicts 0.00%. The two boards are the same picture.

They face **opposite ways across the barrier**. `count` faces −Z, back into territory A;
`spread` faces +Z, into territory C. Measured over every walkable cell in the map with a
line-of-sight test that accounts for facing:

```
point/count vs point/spread     standpoints seeing BOTH faces:   0
interval/bare vs interval/count standpoints seeing BOTH faces:  45   closest joint view 3.0 m at (10,6)
absent/bare  vs absent/drift     standpoints seeing BOTH faces:  15   closest joint view 3.0 m at (2,6)
```

So the room hands over the two record pairs that **differ** — you stand at (2,6) with the two
`absent` boards three metres either side, and at (10,6) with the two `interval` boards three
metres either side — and withholds the pair that is **identical**. There is nowhere to stand
that holds both point boards. To notice, a visitor has to meet `count` on the way in, cross
the barrier, and meet `spread` on the way out, and remember. `blurb.md` tells them there are
two ways through and to take both; the room will not do it for them.

The turn is not left to luck. `threshold` at (16,6) faces −Z, so reading it puts the visitor
in territory C facing north — and that is the standpoint from which `spread` is looking
straight back at them.

## What is compared, and by what movement

- **(2,6), between the two `absent` boards.** Same empty claim strip. One shows nothing
  underneath; the other shows 270 trials spread flat across all twenty bins. The registry
  calls `absent` the loudest record column in the sheet, and it is the first thing in the room.
- **(10,6), between the two `interval` boards.** Lambda's own recommendation, at the cell where
  it starts. Left: as `lambda_slider` draws it — a claim with nothing under it. Right: the same
  claim with its measurements drawn. Neither source file draws that second board; this is the
  only place in the museum where lambda's evidence exists.
- **The barrier crossing.** `rival` overhead, `count` behind, `spread` ahead, and the same
  picture at both ends.
- **The eleven cells of the 55% territory.** One board at the sixth of them, seven empty cells
  behind it, then the door.

## What I could not do

- **No capture.** Godot runs are serialised by the orchestrator this wave, so nothing here has
  been photographed or loaded. Every geometric claim above is computed from `map_data.json` and
  the artifact's own constants, and the sight-line figures are from a rasterised line test over
  the structure layer, not from a render.
- **The 0-standpoints result is a floor-plan fact, not an eye-height fact.** It follows from
  the two boards facing opposite half-planes, which no viewpoint can defeat; but a very tall
  view over the 2 m barrier would still see both *backs*.
- **`gap` is not in the room** because it is not in the axis — the registry declines it, and
  correctly: it is a claim about the instrument, not about the recommended set.
- **The scale's resolution is fixed at 20.** The registry's own `declines` note calls a
  resolution axis the honest third one, and this room would have been the place to walk it —
  a floor of 10 cells and a floor of 40 cells, side by side, arguing about how thin a point
  claim is. It does not exist as an axis, so it is not here.

## Validation

```
python tools/map_pathfinder.py check Museum_AAA_Dispute --verbose
OK    Museum_AAA_Dispute  (192/266 reachable, 8 artifacts, 1 teleport(s))
=== 1 maps checked: 1 OK, 0 FAIL (0 issues) ===
```

Every `#axis:value` in this map was re-read from the finished file and asserted against three
independent sources — the registry's `dna.axes`, the `@export_enum` literals in
`constant_dispute.gd`, and the allow-lists inside `apply_grid_config()` — because a misspelled
value does not error, it falls back to the default in silence, and a room of eight identical
boards would look exactly like this one from the JSON. All three agree; both properties are
typed `String`, so `cabinet_sweep.coerce()` has nothing to numericise and the `tier_terrarium`
failure cannot occur here. 8 placements, 16 assignments, 8 distinct cells of the sheet's 20,
all five `claim` values and all four `record` values used.
