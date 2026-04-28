# Dressing-Room Schema

> The mini-scene every artifact owns. The map composer places dressing
> rooms as inviolable units and routes paths between them. Authored once
> per artifact, reusable across every map the artifact appears in.

## Why

The map-composition problem keeps recurring: where in the grid does each
artifact go, what's under it, what surrounds it, what label sits next to
it? Hand-authoring this for every (artifact, map) pair doesn't scale.

The dressing room pushes that decision *down* to the artifact level
(authored once) and lets the composer pull *up* into a constraint
problem (place inviolable units + route paths between them).

Three properties:

1. **Reusable** — same room across all maps the artifact appears in.
2. **Self-staging** — the room knows its own footing, clearance, labels.
3. **Composable** — the composer routes around it, never inside it.

## File location

```
commons/artifacts/dressing_rooms/<lookup_name>.json
```

One file per artifact that has a defined dressing room. Artifacts without
a dressing-room file fall back to a 1×1 default room in the composer.

## Schema

```jsonc
{
  // Identity — must match the artifact's registry lookup_name.
  "lookup_name": "lambda_slider",

  // Physical footprint in grid cells, plus stand height. Mirrors the
  // registry's `footprint` field. (width, depth, height_in_cells)
  "footprint": [1, 1, 2.5],

  // Which rotations the composer is allowed to apply. The dressing room
  // is described in the "0" rotation; the composer picks one of these
  // when placing the room and rotates approach/exit/extras accordingly.
  // Values: "0", "90", "180", "270" — degrees clockwise looking down.
  "rotations": ["0", "90", "180", "270"],

  // Direction the player path enters the room, in the default ("0")
  // rotation. One of north / south / east / west. The composer rotates
  // this when picking an orientation.
  "approach": "south",

  // Direction the path leaves the room (or "stop" if this room is a
  // teaching dead-end the player must back-track from).
  "exit": "north",

  // Structure tiles under and around the artifact. The composer stamps
  // these into the map's structure layer when placing the room.
  //
  // anchor — which (row, col) inside the tiles array the artifact's
  //          interactables-layer cell sits on.
  // tiles  — 2D array of integer heights:
  //          0 = void  (passable hole — rare)
  //          1 = floor (walkable)
  //          2 = wall step (blocked, surrounding step)
  //          3 = plinth top (raised stand the artifact sits on)
  //          4 = wall (taller blocking)
  "footing": {
    "anchor": [1, 1],
    "tiles": [
      [1, 1, 1],
      [1, 3, 1],
      [1, 1, 1]
    ]
  },

  // Optional supporting elements the composer drops into the utilities
  // layer at fixed offsets relative to the room's anchor.
  //
  // type — utility kind:
  //   3t   3D-text label (the `text` field is required)
  //   tt   tutorial-text panel (the `key` references tutorial_text_library)
  //   el   emission light (the `params` field is the el params string)
  //   sub  sub-layer reference (rare)
  // offset — (delta_row, delta_col, delta_height) from the anchor cell.
  //          delta_height of 0 = same row in utilities; otherwise the
  //          composer places the extra on the indicated cell.
  // rotation — overrides automatic rotation if set; otherwise rotates
  //            with the room.
  "extras": [
    { "type": "3t",  "text": "λ",                 "offset": [0,  1, 0] },
    { "type": "tt",  "key":  "lambda_explainer",  "offset": [0, -1, 0] },
    { "type": "el",  "params": "3:1",             "offset": [0,  0, 0] }
  ],

  // Total volumetric envelope including extras (max width, max depth,
  // max height). Used by the composer for clearance checks before
  // placement is finalised.
  "clearance": [3, 3, 4]
}
```

## What "rotation" does to a dressing room

When the composer applies a non-zero rotation:

- `approach` and `exit` rotate by the same amount (e.g., `south` → `west`
  at 90° clockwise).
- The `tiles` array is rotated as a 2D matrix.
- `anchor` rotates with the tiles array.
- Each `extras[i].offset` (dr, dc, dh) is rotated in the (dr, dc)
  plane; `dh` is unchanged.
- `extras[i].rotation`, if set, *overrides* the automatic rotation —
  useful for pieces that should always face the player.

Rotation of 3t labels: text is rendered with rotation applied to the
text-direction in-world; the offset rotates as above.

## Defaults for artifacts without a dressing-room file

The composer falls back to:

```jsonc
{
  "footprint": [1, 1, 1],
  "rotations": ["0", "90", "180", "270"],
  "approach": "south",
  "exit": "north",
  "footing": { "anchor": [0, 0], "tiles": [[1]] },
  "extras": []
}
```

A 1×1 cell on a single floor tile, no extras, any rotation.

## Authoring guidance (for the editor)

Order to fill in:
1. **Footprint** first — pick width × depth × height in cells.
2. **Footing** — what's under it? A plinth (3) raises it; a flush floor
   (1) keeps it grounded; a void (0) is rare and theatrical.
3. **Approach/exit** — where does the player walk in from? Where do
   they leave? If both ends face the same direction, the room is a
   peninsula off the main path.
4. **Extras** — the label first. Most teaching artifacts want a 3t label
   announcing what they are, plus a tt panel for the longer reading. el
   lights are rare and only for hero stages.
5. **Rotations** — most rooms allow all four. Some have an "up" (e.g., a
   pendulum hanging from a wall) and only allow the rotations whose
   approach lines up with that wall.
6. **Clearance** — the bounding box that contains footing + extras. The
   composer adds a 1-cell safety margin around this when reserving
   non-path territory.

## Examples shipped today

- `lambda_slider.json` — a teaching dial on a plinth with a 3t label
- `russell_set_box.json` — a single set-theory cube with a tt panel
- `qfep_formula_3d.json` — a hero formula sitting elevated on a plinth
  with all four sides labelled

These are reference rooms the composer can use immediately.
