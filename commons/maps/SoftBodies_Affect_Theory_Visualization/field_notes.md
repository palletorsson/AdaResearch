# SoftBodies_Affect_Theory_Visualization — field notes

> Field notes hold what the wall text cannot carry. `final.md` is for the
> visitor. This is for us.

## Read before written

Written 2026-09-02 from an agent's reading of every placed script and scene,
with a skeptic pass behind it. Nothing in the text predates the sheet.

- **"A single specimen in a display case" is nine specimens and no case.** The
  map description, blurb, intent, summary, technical and walked all say one.
  `radiolaria.gd` builds a 3x3 grid of nine, six types chosen after an unseeded
  randomize, so the exhibit re-rolls every load. Roughly 7.4 m of bodies on a 7 m
  floor; the outer ones overhang.
- **You spawn inside it**, about a metre from the nearest body.
- **No collider of any kind** — you walk through every one.
- **The artifact brings its own light**: three directional lights and a procedural
  sky arrive with it and overrule the map's lighting block, which nothing reads
  anyway (`get_lighting_settings` has no callers).
- **The exit is at the bottom of a hole**, `t` on a void cell.
- `an:softbodies` is parsed as a rotation, so the annotation board never gets its
  sequence name; its trigger is doubly dead besides.
- 450 particles, 50 per body.

The text keeps the discrepancy rather than papering over it: a room about the
capacity to be affected in which nothing registers a visitor.

## Open

- This room is one artifact and its own docs describe a different exhibit. Either the case gets built or the docs get rewritten; the text names the gap.
