# Museum_AAA_Ground — why the room is this shape

Subject: `ground_layer`, a synthesis bench with two axes —
`priming` (white · ochre · bole · verdaccio) and `handling` (bare · glaze · body · sgraffito).
Twelve placements, every one of them carrying an explicit value on both axes.

## The architecture is the claim

The whole room is one solid block at height 4, and every space in it is a **cut**. Nothing is
built up. That is the argument in the structure layer, because a ground is not a thing standing
on a surface — it is a depth you go into.

Three cut depths, and they are the three layers of a painted panel:

| height | what it is | what stands there |
|---|---|---|
| 1 | the ground | every `bare` panel, in a trough across the floor |
| 2 | the walk | the visitor |
| 3 | the mark | every handled panel, on a shelf cut into the wall at chest height |
| 4 | the block | untouched stone |

So the visitor spends the entire walk **in the gap between the ground and what is on it**. The
grounds are a metre below the feet and the marks a metre above them, and neither is ever at the
same level as the body. That is what a ground is for: it is under.

The visitor also *starts* on the ground. Spawn is at (2,1) on a height-1 dais with
`white / bare` beside it — the family's shipped default, four colours and nothing on any of
them, standing at knee height with the visitor down at its own level. The first thing the room
asks anyone to do is climb off it.

## Why it is not a specimen row

No two grounds are ever visible at once. The gallery is a serpentine of three legs, each three
metres wide, separated by **two** rows of solid block, so a shelf cut into the south wall of one
leg cannot be seen over the wall from the leg below it. Each leg reverses direction, so the
visitor walks east, west, east. Within a leg the two marked panels sit on opposite walls and
three metres apart along the path, so they are met one at a time by turning the head, never
lined up facing front.

Every comparison this room makes is therefore carried in the body, not in the visual field.

## The three legs, and what the walk compares

**Leg 1 — bole, walking east.** Trough at column 6 (`bole / bare`); north shelf `bole / body`;
south shelf `bole / sgraffito`, right at the doorway so you turn past it. Sgraffito is bole's own
technique: the covering scratched back through in sixteen rays so the red clay reads as drawing.
On the bench this pair measures 29.1% focus, the loudest thing in the family.

**Leg 2 — verdaccio, walking west.** Trough (`verdaccio / bare`), then `verdaccio / body`, then
`verdaccio / glaze`. Body first is deliberate: you meet the rose alone, raw, and then meet the
same rose multiplied through green earth, which is the only ground in the set that pulls it back
toward neutral. That is why green went under flesh, and it is the half of this artifact the
luminance critic cannot see at all.

**Leg 3 — ochre, walking east.** *The same floor plan as leg 1, cell for cell* — trough at column
6, north shelf at column 9, south shelf at column 12, doorway at column 13. Only the ground has
changed. The visitor walks the identical room and finds that the technique that roared on bole
does almost nothing here (5.9% against 29.1%), because ochre's value is close to the tint's and a
scratch into a ground of the same lightness is not a drawing. The control is the architecture
repeating itself two corners and twenty metres away, where you cannot check by looking — only by
remembering.

## The designed null

The two placements are:

- **`ground_layer:54.5:0#priming:white#handling:glaze` at row 20, column 0** — a shelf in the
  far west wall at the end of the hall, facing east down its whole length.
- **`ground_layer:144.5:0#priming:white#handling:body` at row 22, column 12** — a shelf in the
  south wall at the foot of the entry corridor, facing north.

They are the same picture to the byte. `_glazed()` multiplies in linear light, and linear white
is 1.0 exactly, so over a white ground a transparent paint and an opaque one return the identical
colour. In the sweep table that is a row of zeroes. Here it is a room.

The hall is the largest and emptiest space in the map on purpose — white is the ground that isn't
a decision — and the two panels sit at opposite ends of it facing perpendicular directions, so
they can never both be in view. The visitor comes down the corridor, meets `white / body` in the
alcove at their feet, walks twelve metres west with it behind them, and meets `white / glaze`.
To notice, they have to do the one thing the previous three legs have been training them for:
carry a panel in memory across a room. And the finding is a negative one — *these two are the
same, and on bole, ochre and verdaccio they were not.* The distinction the whole vocabulary rests
on does not exist until the ground stops being white, which is the sentence a family that only
ever ships white can never say.

The exit is a hole in the floor at (21,1), immediately beside `white / glaze`. You leave from the
one place in the room where the axis has stopped meaning anything.

## Notes for the next hand

- Rotations are `144.5 / 324.5 / 54.5 / 234.5`, not cardinals. The artifact yaws its own board
  0.62 rad (35.5°) to meet `capture_config_sweep`'s standpoint, so a placement has to subtract
  that to face a visitor square. `324.5` faces +Z, `144.5` faces −Z, `54.5` faces +X, `234.5`
  faces −X.
- Every placement sets **both** axes explicitly. Nothing here relies on a default, so a future
  edit that breaks one value will show up as one wrong panel rather than as a silently correct-
  looking room.
- The troughs are crossed, not skirted: the ramp out is a `wp` on the two outer cells of each
  three-cell trough and the panel sits in the middle one, so the visitor steps down to the
  ground's own level to get past it.
- `map_pathfinder`'s wp rule lets a ramp climb any height, so its reachability count (332/345)
  includes the solid block. Under a stricter rule — climb exactly one level, only across a wp —
  the room is 171 cells, all twelve works stand at, the exit is reachable, and no reachable cell
  is a trap.
